#include "dj_engine.h"
#include <vector>
#include <cmath>
#include <algorithm>
#include <atomic>

class Deck {
public:
    Deck() : is_playing_(false),
             is_touching_(false),
             cue_position_frames_(0),
             current_frame_(0.0),
             rate_multiplier_(1.0f),
             scratch_velocity_(0.0f),
             scratch_inertia_(0.0f),
             gain_(1.0f),
             vu_level_(0.0f),
             sample_rate_(44100.0f) {
        // Generate 30 seconds of synthetic test tone (kick drum + rhythmic loop) for instant testing
        generateSyntheticTrack();
    }

    void setSampleRate(float sample_rate) {
        sample_rate_ = sample_rate;
    }

    void play() { is_playing_ = true; }
    void pause() { is_playing_ = false; }
    
    void cue() {
        if (is_playing_) {
            is_playing_ = false;
            current_frame_ = cue_position_frames_;
        } else {
            cue_position_frames_ = static_cast<int64_t>(current_frame_);
        }
    }

    void seek(float seconds) {
        current_frame_ = std::clamp(static_cast<double>(seconds * sample_rate_), 0.0, static_cast<double>(total_frames_));
    }

    void setRate(float rate) {
        // e.g. -0.16 to +0.16 (+/- 16% pitch range)
        rate_multiplier_ = 1.0f + rate;
    }

    void setGain(float gain) {
        gain_ = std::max(0.0f, gain);
    }

    void touchDown() {
        is_touching_ = true;
        scratch_velocity_ = 0.0f;
        scratch_inertia_ = 0.0f;
    }

    void touchMove(float delta_angle_radians) {
        // 1 full revolution (2*PI) corresponds to ~1.8 seconds of audio at 33.3 RPM
        // Velocity (frames per second delta)
        const float frames_per_radian = (sample_rate_ * 1.8f) / (2.0f * 3.14159265f);
        scratch_velocity_ = (delta_angle_radians * frames_per_radian) / (sample_rate_ / 60.0f); // Normalize by frame rate
    }

    void touchUp() {
        is_touching_ = false;
        scratch_inertia_ = scratch_velocity_; // Hand over to inertia
    }

    float getPosition() const {
        return static_cast<float>(current_frame_ / sample_rate_);
    }

    float getVuLevel() const {
        return vu_level_;
    }

    // Real-Time Audio Process (called inside audio thread)
    void render(float* out_l, float* out_r, int32_t num_frames) {
        float peak = 0.0f;

        for (int32_t i = 0; i < num_frames; ++i) {
            float speed = 0.0f;

            if (is_touching_) {
                speed = scratch_velocity_;
                scratch_velocity_ *= 0.95f; // Friction while held still
            } else {
                if (std::abs(scratch_inertia_) > 0.01f) {
                    speed = scratch_inertia_;
                    scratch_inertia_ *= 0.92f; // Turntable platter friction decay
                } else if (is_playing_) {
                    speed = rate_multiplier_;
                }
            }

            // Read sample with cubic Hermite interpolation
            float sample_l = 0.0f;
            float sample_r = 0.0f;
            readSampleInterpolated(current_frame_, sample_l, sample_r);

            // Apply gain
            sample_l *= gain_;
            sample_r *= gain_;

            out_l[i] = sample_l;
            out_r[i] = sample_r;

            // VU meter peak tracking
            peak = std::max(peak, std::max(std::abs(sample_l), std::abs(sample_r)));

            // Advance playhead
            current_frame_ += speed;
            if (current_frame_ >= total_frames_) {
                current_frame_ = 0.0; // Loop or stop
            } else if (current_frame_ < 0.0) {
                current_frame_ = 0.0;
            }
        }

        vu_level_ = peak;
    }

private:
    void readSampleInterpolated(double frame_pos, float& out_l, float& out_r) {
        if (pcm_left_.empty()) {
            out_l = out_r = 0.0f;
            return;
        }

        int64_t i1 = static_cast<int64_t>(frame_pos);
        int64_t i0 = std::max<int64_t>(0, i1 - 1);
        int64_t i2 = std::min<int64_t>(total_frames_ - 1, i1 + 1);
        int64_t i3 = std::min<int64_t>(total_frames_ - 1, i1 + 2);

        float frac = static_cast<float>(frame_pos - i1);

        // 4-point Hermite cubic spline interpolation
        out_l = hermite(pcm_left_[i0], pcm_left_[i1], pcm_left_[i2], pcm_left_[i3], frac);
        out_r = hermite(pcm_right_[i0], pcm_right_[i1], pcm_right_[i2], pcm_right_[i3], frac);
    }

    static inline float hermite(float y0, float y1, float y2, float y3, float mu) {
        float a = (3.0f * (y1 - y2) - y0 + y3) * 0.5f;
        float b = 2.0f * y2 + y0 - (5.0f * y1 + y3) * 0.5f;
        float c = (y2 - y0) * 0.5f;
        return (((a * mu) + b) * mu + c) * mu + y1;
    }

    void generateSyntheticTrack() {
        total_frames_ = static_cast<int64_t>(sample_rate_ * 30.0f); // 30s
        pcm_left_.resize(total_frames_);
        pcm_right_.resize(total_frames_);

        // Synthesize standard 128 BPM 4-on-the-floor beat with hi-hats
        float beat_interval_frames = (sample_rate_ * 60.0f) / 128.0f;

        for (int64_t f = 0; f < total_frames_; ++f) {
            float phase_in_beat = std::fmod(static_cast<float>(f), beat_interval_frames);
            float t = phase_in_beat / sample_rate_;

            // Kick drum: 150Hz decaying sine wave
            float kick = 0.0f;
            if (t < 0.2f) {
                float freq = 150.0f * std::exp(-t * 25.0f) + 40.0f;
                kick = std::sin(2.0f * 3.14159f * freq * t) * std::exp(-t * 15.0f) * 0.8f;
            }

            // Off-beat Hi-Hat
            float hihat = 0.0f;
            float offbeat_phase = std::fmod(static_cast<float>(f) + beat_interval_frames * 0.5f, beat_interval_frames);
            float t_hat = offbeat_phase / sample_rate_;
            if (t_hat < 0.08f) {
                float white_noise = (static_cast<float>(rand()) / static_cast<float>(RAND_MAX)) * 2.0f - 1.0f;
                hihat = white_noise * std::exp(-t_hat * 40.0f) * 0.3f;
            }

            pcm_left_[f] = kick + hihat;
            pcm_right_[f] = kick + hihat;
        }
    }

    bool is_playing_;
    bool is_touching_;
    int64_t cue_position_frames_;
    double current_frame_;
    float rate_multiplier_;
    float scratch_velocity_;
    float scratch_inertia_;
    float gain_;
    float vu_level_;
    float sample_rate_;

    int64_t total_frames_;
    std::vector<float> pcm_left_;
    std::vector<float> pcm_right_;
};

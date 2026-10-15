#include "dj_engine.h"
#include <memory>
#include <atomic>
#include <cmath>
#include <algorithm>
#include <vector>

// Forward include / internal modules
#include "deck.cpp"
#include "biquad_eq.cpp"
#include "crossfader.cpp"

class DjAudioEngine {
public:
    DjAudioEngine(int32_t sample_rate, int32_t buffer_size)
        : sample_rate_(sample_rate),
          buffer_size_(buffer_size),
          is_running_(false),
          master_volume_(1.0f),
          split_cue_(false),
          master_vu_(0.0f) {
        decks_[DECK_A].setSampleRate(static_cast<float>(sample_rate_));
        decks_[DECK_B].setSampleRate(static_cast<float>(sample_rate_));
        eqs_[DECK_A].init(static_cast<float>(sample_rate_));
        eqs_[DECK_B].init(static_cast<float>(sample_rate_));

        temp_a_l_.resize(buffer_size);
        temp_a_r_.resize(buffer_size);
        temp_b_l_.resize(buffer_size);
        temp_b_r_.resize(buffer_size);
    }

    void start() { is_running_ = true; }
    void stop() { is_running_ = false; }

    Deck& getDeck(DeckId id) { return decks_[id]; }
    DjIsolatorEQ& getEq(DeckId id) { return eqs_[id]; }
    Crossfader& getCrossfader() { return crossfader_; }

    void setMasterVolume(float vol) { master_volume_ = std::max(0.0f, vol); }
    void setSplitCue(bool enabled) { split_cue_ = enabled; }
    float getMasterVu() const { return master_vu_; }

    // Audio callback executed on real-time priority thread
    void processAudio(float* output_stereo, int32_t num_frames) {
        if (!is_running_) {
            std::fill(output_stereo, output_stereo + (num_frames * 2), 0.0f);
            return;
        }

        // 1. Render Deck A & Deck B into temporary scratch buffers
        decks_[DECK_A].render(temp_a_l_.data(), temp_a_r_.data(), num_frames);
        decks_[DECK_B].render(temp_b_l_.data(), temp_b_r_.data(), num_frames);

        // 2. Compute crossfader gains
        float gain_a = 1.0f;
        float gain_b = 1.0f;
        crossfader_.calculateGains(gain_a, gain_b);

        float peak_master = 0.0f;

        // 3. Process EQ, apply crossfader, and sum to master
        for (int32_t i = 0; i < num_frames; ++i) {
            float a_eq_l, a_eq_r, b_eq_l, b_eq_r;
            eqs_[DECK_A].process(temp_a_l_[i], temp_a_r_[i], a_eq_l, a_eq_r);
            eqs_[DECK_B].process(temp_b_l_[i], temp_b_r_[i], b_eq_l, b_eq_r);

            float out_l = 0.0f;
            float out_r = 0.0f;

            if (split_cue_) {
                // Mono Split Mode for DJ splitter cable:
                // Left channel = Master Out (Deck A + Deck B weighted by crossfader)
                // Right channel = Headphone Monitor (Cued deck, e.g. Deck B)
                float master_mono = ((a_eq_l + a_eq_r) * 0.5f * gain_a) + ((b_eq_l + b_eq_r) * 0.5f * gain_b);
                float cue_mono = (b_eq_l + b_eq_r) * 0.5f;

                out_l = master_mono * master_volume_;
                out_r = cue_mono;
            } else {
                // Standard Stereo Master Out
                out_l = (a_eq_l * gain_a + b_eq_l * gain_b) * master_volume_;
                out_r = (a_eq_r * gain_a + b_eq_r * gain_b) * master_volume_;
            }

            // Soft-Clipping Limiter (tanh saturation to prevent harsh digital clipping)
            out_l = std::tanh(out_l);
            out_r = std::tanh(out_r);

            output_stereo[i * 2] = out_l;
            output_stereo[i * 2 + 1] = out_r;

            peak_master = std::max(peak_master, std::max(std::abs(out_l), std::abs(out_r)));
        }

        master_vu_ = peak_master;
    }

private:
    int32_t sample_rate_;
    int32_t buffer_size_;
    bool is_running_;
    float master_volume_;
    bool split_cue_;
    float master_vu_;

    Deck decks_[DECK_COUNT];
    DjIsolatorEQ eqs_[DECK_COUNT];
    Crossfader crossfader_;

    std::vector<float> temp_a_l_;
    std::vector<float> temp_a_r_;
    std::vector<float> temp_b_l_;
    std::vector<float> temp_b_r_;
};

static std::unique_ptr<DjAudioEngine> g_engine = nullptr;

// C-Linkage Export Implementations
extern "C" {

bool dj_engine_init(int32_t sample_rate, int32_t buffer_size) {
    g_engine = std::make_unique<DjAudioEngine>(sample_rate, buffer_size);
    return g_engine != nullptr;
}

void dj_engine_shutdown(void) {
    if (g_engine) {
        g_engine->stop();
        g_engine.reset();
    }
}

bool dj_engine_start(void) {
    if (g_engine) {
        g_engine->start();
        return true;
    }
    return false;
}

bool dj_engine_stop(void) {
    if (g_engine) {
        g_engine->stop();
        return true;
    }
    return false;
}

void dj_deck_play(DeckId deck) {
    if (g_engine && deck < DECK_COUNT) g_engine->getDeck(deck).play();
}

void dj_deck_pause(DeckId deck) {
    if (g_engine && deck < DECK_COUNT) g_engine->getDeck(deck).pause();
}

void dj_deck_cue(DeckId deck) {
    if (g_engine && deck < DECK_COUNT) g_engine->getDeck(deck).cue();
}

void dj_deck_seek(DeckId deck, float position_seconds) {
    if (g_engine && deck < DECK_COUNT) g_engine->getDeck(deck).seek(position_seconds);
}

void dj_deck_set_rate(DeckId deck, float rate_multiplier) {
    if (g_engine && deck < DECK_COUNT) g_engine->getDeck(deck).setRate(rate_multiplier);
}

void dj_deck_touch_down(DeckId deck) {
    if (g_engine && deck < DECK_COUNT) g_engine->getDeck(deck).touchDown();
}

void dj_deck_touch_move(DeckId deck, float delta_angle_radians) {
    if (g_engine && deck < DECK_COUNT) g_engine->getDeck(deck).touchMove(delta_angle_radians);
}

void dj_deck_touch_up(DeckId deck) {
    if (g_engine && deck < DECK_COUNT) g_engine->getDeck(deck).touchUp();
}

void dj_deck_set_eq_low(DeckId deck, float gain_db) {
    if (g_engine && deck < DECK_COUNT) g_engine->getEq(deck).setLow(gain_db);
}

void dj_deck_set_eq_mid(DeckId deck, float gain_db) {
    if (g_engine && deck < DECK_COUNT) g_engine->getEq(deck).setMid(gain_db);
}

void dj_deck_set_eq_high(DeckId deck, float gain_db) {
    if (g_engine && deck < DECK_COUNT) g_engine->getEq(deck).setHigh(gain_db);
}

void dj_deck_set_kill_low(DeckId deck, bool kill) {
    if (g_engine && deck < DECK_COUNT) g_engine->getEq(deck).setKillLow(kill);
}

void dj_deck_set_kill_mid(DeckId deck, bool kill) {
    if (g_engine && deck < DECK_COUNT) g_engine->getEq(deck).setKillMid(kill);
}

void dj_deck_set_kill_high(DeckId deck, bool kill) {
    if (g_engine && deck < DECK_COUNT) g_engine->getEq(deck).setKillHigh(kill);
}

void dj_deck_set_gain(DeckId deck, float gain_linear) {
    if (g_engine && deck < DECK_COUNT) g_engine->getDeck(deck).setGain(gain_linear);
}

void dj_mixer_set_crossfader(float position) {
    if (g_engine) g_engine->getCrossfader().setPosition(position);
}

void dj_mixer_set_crossfader_curve(CrossfaderCurve curve) {
    if (g_engine) g_engine->getCrossfader().setCurve(curve);
}

void dj_mixer_set_master_volume(float volume) {
    if (g_engine) g_engine->setMasterVolume(volume);
}

void dj_mixer_set_split_cue(bool enabled) {
    if (g_engine) g_engine->setSplitCue(enabled);
}

float dj_deck_get_position(DeckId deck) {
    if (g_engine && deck < DECK_COUNT) return g_engine->getDeck(deck).getPosition();
    return 0.0f;
}

float dj_deck_get_vu_level(DeckId deck) {
    if (g_engine && deck < DECK_COUNT) return g_engine->getDeck(deck).getVuLevel();
    return 0.0f;
}

float dj_mixer_get_master_vu_level(void) {
    if (g_engine) return g_engine->getMasterVu();
    return 0.0f;
}

} // extern "C"

#include <cmath>
#include <algorithm>

class BiquadFilter {
public:
    BiquadFilter() : a0(1.0f), a1(0.0f), a2(0.0f), b1(0.0f), b2(0.0f),
                     z1_l(0.0f), z2_l(0.0f), z1_r(0.0f), z2_r(0.0f) {}

    void setLowShelf(float sample_rate, float cutoff, float gain_db) {
        float A = std::pow(10.0f, gain_db / 40.0f);
        float w0 = 2.0f * 3.14159265358979323846f * cutoff / sample_rate;
        float cos_w0 = std::cos(w0);
        float sin_w0 = std::sin(w0);
        float alpha = sin_w0 / 2.0f * std::sqrt(2.0f);

        float a0_raw = (A + 1.0f) + (A - 1.0f) * cos_w0 + 2.0f * std::sqrt(A) * alpha;
        a0 = (A * ((A + 1.0f) - (A - 1.0f) * cos_w0 + 2.0f * std::sqrt(A) * alpha)) / a0_raw;
        a1 = (2.0f * A * ((A - 1.0f) - (A + 1.0f) * cos_w0)) / a0_raw;
        a2 = (A * ((A + 1.0f) - (A - 1.0f) * cos_w0 - 2.0f * std::sqrt(A) * alpha)) / a0_raw;
        b1 = (-2.0f * ((A - 1.0f) + (A + 1.0f) * cos_w0)) / a0_raw;
        b2 = ((A + 1.0f) + (A - 1.0f) * cos_w0 - 2.0f * std::sqrt(A) * alpha) / a0_raw;
    }

    void setPeaking(float sample_rate, float center_freq, float Q, float gain_db) {
        float A = std::pow(10.0f, gain_db / 40.0f);
        float w0 = 2.0f * 3.14159265358979323846f * center_freq / sample_rate;
        float cos_w0 = std::cos(w0);
        float sin_w0 = std::sin(w0);
        float alpha = sin_w0 / (2.0f * Q);

        float a0_raw = 1.0f + alpha / A;
        a0 = (1.0f + alpha * A) / a0_raw;
        a1 = (-2.0f * cos_w0) / a0_raw;
        a2 = (1.0f - alpha * A) / a0_raw;
        b1 = (-2.0f * cos_w0) / a0_raw;
        b2 = (1.0f - alpha / A) / a0_raw;
    }

    void setHighShelf(float sample_rate, float cutoff, float gain_db) {
        float A = std::pow(10.0f, gain_db / 40.0f);
        float w0 = 2.0f * 3.14159265358979323846f * cutoff / sample_rate;
        float cos_w0 = std::cos(w0);
        float sin_w0 = std::sin(w0);
        float alpha = sin_w0 / 2.0f * std::sqrt(2.0f);

        float a0_raw = (A + 1.0f) - (A - 1.0f) * cos_w0 + 2.0f * std::sqrt(A) * alpha;
        a0 = (A * ((A + 1.0f) + (A - 1.0f) * cos_w0 + 2.0f * std::sqrt(A) * alpha)) / a0_raw;
        a1 = (-2.0f * A * ((A - 1.0f) + (A + 1.0f) * cos_w0)) / a0_raw;
        a2 = (A * ((A + 1.0f) + (A - 1.0f) * cos_w0 - 2.0f * std::sqrt(A) * alpha)) / a0_raw;
        b1 = (2.0f * ((A - 1.0f) - (A + 1.0f) * cos_w0)) / a0_raw;
        b2 = ((A + 1.0f) - (A - 1.0f) * cos_w0 - 2.0f * std::sqrt(A) * alpha) / a0_raw;
    }

    void processStereo(float in_l, float in_r, float& out_l, float& out_r) {
        // Direct Form II Transposed for numerical stability
        out_l = a0 * in_l + z1_l;
        z1_l = a1 * in_l - b1 * out_l + z2_l;
        z2_l = a2 * in_l - b2 * out_l;

        out_r = a0 * in_r + z1_r;
        z1_r = a1 * in_r - b1 * out_r + z2_r;
        z2_r = a2 * in_r - b2 * out_r;
    }

    void reset() {
        z1_l = z2_l = z1_r = z2_r = 0.0f;
    }

private:
    float a0, a1, a2, b1, b2;
    float z1_l, z2_l, z1_r, z2_r;
};

class DjIsolatorEQ {
public:
    DjIsolatorEQ() : sample_rate_(44100.0f),
                     low_db_(0.0f), mid_db_(0.0f), high_db_(0.0f),
                     kill_low_(false), kill_mid_(false), kill_high_(false) {}

    void init(float sample_rate) {
        sample_rate_ = sample_rate;
        updateFilters();
    }

    void setLow(float db) { low_db_ = db; updateFilters(); }
    void setMid(float db) { mid_db_ = db; updateFilters(); }
    void setHigh(float db) { high_db_ = db; updateFilters(); }

    void setKillLow(bool kill) { kill_low_ = kill; }
    void setKillMid(bool kill) { kill_mid_ = kill; }
    void setKillHigh(bool kill) { kill_high_ = kill; }

    void process(float in_l, float in_r, float& out_l, float& out_r) {
        float l1, r1, l2, r2, l3, r3;

        // Cascade 3 isolator bands
        low_filter_.processStereo(in_l, in_r, l1, r1);
        mid_filter_.processStereo(l1, r1, l2, r2);
        high_filter_.processStereo(l2, r2, l3, r3);

        float gain_low = kill_low_ ? 0.0f : 1.0f;
        float gain_mid = kill_mid_ ? 0.0f : 1.0f;
        float gain_high = kill_high_ ? 0.0f : 1.0f;

        // Band separation & summation with kill attenuation
        out_l = l3 * (gain_low * gain_mid * gain_high);
        out_r = r3 * (gain_low * gain_mid * gain_high);
    }

private:
    void updateFilters() {
        low_filter_.setLowShelf(sample_rate_, 300.0f, low_db_);
        mid_filter_.setPeaking(sample_rate_, 1200.0f, 1.0f, mid_db_);
        high_filter_.setHighShelf(sample_rate_, 3200.0f, high_db_);
    }

    float sample_rate_;
    float low_db_, mid_db_, high_db_;
    bool kill_low_, kill_mid_, kill_high_;
    BiquadFilter low_filter_;
    BiquadFilter mid_filter_;
    BiquadFilter high_filter_;
};

#include "dj_engine.h"
#include <cmath>
#include <algorithm>

class Crossfader {
public:
    Crossfader() : position_(0.0f), curve_(CROSSFADER_CURVE_SMOOTH) {}

    void setPosition(float pos) {
        position_ = std::clamp(pos, -1.0f, 1.0f);
    }

    void setCurve(CrossfaderCurve curve) {
        curve_ = curve;
    }

    void calculateGains(float& gain_a, float& gain_b) const {
        // Map [-1.0, 1.0] to [0.0, 1.0] where 0.0 = 100% Deck A, 1.0 = 100% Deck B
        float t = (position_ + 1.0f) * 0.5f;
        t = std::clamp(t, 0.0f, 1.0f);

        switch (curve_) {
            case CROSSFADER_CURVE_LINEAR:
                gain_a = 1.0f - t;
                gain_b = t;
                break;

            case CROSSFADER_CURVE_SMOOTH: {
                // Equal Power / Constant Energy: cos^2 + sin^2 = 1.0
                float angle = t * 1.5707963267948966f; // t * (PI / 2)
                gain_a = std::cos(angle);
                gain_b = std::sin(angle);
                break;
            }

            case CROSSFADER_CURVE_SCRATCH_CUT: {
                // Steep scratch cut: 100% volume almost immediately upon leaving edge
                const float cut_threshold = 0.05f; // 5% cut-in lag
                if (t >= (1.0f - cut_threshold)) {
                    gain_a = (1.0f - t) / cut_threshold;
                } else {
                    gain_a = 1.0f;
                }

                if (t <= cut_threshold) {
                    gain_b = t / cut_threshold;
                } else {
                    gain_b = 1.0f;
                }
                break;
            }
        }

        gain_a = std::clamp(gain_a, 0.0f, 1.0f);
        gain_b = std::clamp(gain_b, 0.0f, 1.0f);
    }

private:
    float position_;
    CrossfaderCurve curve_;
};

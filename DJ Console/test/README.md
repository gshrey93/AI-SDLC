# DJ Console Mobile: Test Suite & Verification Matrix

This directory contains the automated test suites for the DJ Console Mobile application, covering digital signal processing (DSP) mathematics, audio state machines, and UI components.

---

## Test Inventory & Mapping

| Test ID | Category | Test Target | Assertion / Verification Goal | Test File |
| :--- | :--- | :--- | :--- | :--- |
| **TC-XF-01** | DSP Math | Crossfader Linear Curve | Left ($t=0 \to G_A=1, G_B=0$), Center ($t=0.5 \to G_A=0.5, G_B=0.5$), Right ($t=1 \to G_A=0, G_B=1$) | `test/dsp_math_test.js` & `test/dsp_math_test.dart` |
| **TC-XF-02** | DSP Math | Constant Power Smooth | Preserves flat $0\text{ dB}$ energy sum ($G_A^2 + G_B^2 = 1.0$) across full sweep | `test/dsp_math_test.js` & `test/dsp_math_test.dart` |
| **TC-XF-03** | DSP Math | Sharp Scratch Cut Curve | Cut-in lag $<5\%$ of fader travel, reaching $100\%$ volume immediately | `test/dsp_math_test.js` & `test/dsp_math_test.dart` |
| **TC-INT-01** | Interpolation | Hermite Cubic Spline | Exact boundary convergence at $\mu=0$ and $\mu=1$ | `test/dsp_math_test.js` & `test/dsp_math_test.dart` |
| **TC-INT-02** | Interpolation | Spline Monotonicity | Midpoint values remain bounded and smooth without overshoot | `test/dsp_math_test.js` & `test/dsp_math_test.dart` |
| **TC-EQ-01** | DSP Filter | 3-Band Biquad Isolator | Kill switches produce true zero-bleed attenuation ($-\infty\text{ dB}$) | `test/dsp_math_test.js` |
| **TC-SCR-01** | Scratch Physics | Turntable Inertia | Exponential friction decay monotonicity ($\text{velocity} \times 0.92$) | `test/dsp_math_test.js` |
| **TC-ST-01** | State | Initialization | 2 decks initialized with demo tracks loaded, transport stopped | `test/audio_state_test.dart` |
| **TC-ST-02** | State | Play / Pause | Deck toggles playing state and triggers audio engine render calls | `test/audio_state_test.dart` |
| **TC-ST-03** | State | Cue Functionality | Cue stops deck and rewinds playhead frame position to 0 | `test/audio_state_test.dart` |
| **TC-ST-04** | State | Pitch Clamping | Pitch fader strictly bounded to $[-16\%, +16\%]$ | `test/audio_state_test.dart` |
| **TC-ST-05** | State | 3-Band EQ & Kills | Gains set correctly and kill flags toggle with state notification | `test/audio_state_test.dart` |
| **TC-ST-06** | State | Crossfader Range | Position clamped to $[-1.0, +1.0]$ and curve mode persists | `test/audio_state_test.dart` |
| **TC-ST-07** | State | Split-Cue Toggle | Toggles mono-split cue routing for DJ headphone splitter | `test/audio_state_test.dart` |
| **TC-UI-01** | Widget UI | ConsoleScreen | Dual decks, transport buttons, scrolling waveforms, and crossfader render cleanly | `test/widget_test.dart` |

---

## How to Execute the Tests

### 1. Instant DSP Math Verification (No mobile toolchain required)
```bash
node test/dsp_math_test.js
```

### 2. Native C++ Audio Engine Compiler Check
```bash
clang++ -std=c++17 -c native/src/dj_engine.cpp -I native/include -o /dev/null
```

### 3. Flutter & Dart Unit/Widget Tests (When Flutter SDK is installed)
```bash
flutter test test/dsp_math_test.dart
flutter test test/audio_state_test.dart
flutter test test/widget_test.dart
```

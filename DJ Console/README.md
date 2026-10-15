# DJ Console Mobile (Cross-Platform / Flutter + C++ Core)

A high-performance, low-latency 2-Deck Mobile DJ Console engineered for iOS and Android, targeting release on the Apple App Store and Google Play Store.

---

## Architecture Overview

Building a professional DJ application requires strict separation between the **UI rendering layer** and the **real-time audio processing pipeline**:

```
┌────────────────────────────────────────────────────────┐
│               FLUTTER FRONTEND LAYER                   │
│  - 60/120 FPS Frequency-Colored Waveforms              │
│  - Interactive Jogwheel / Vinyl Scratch Gestures       │
│  - 3-Band Rotary EQ, Kill Buttons, Pitch Sliders       │
│  - Crossfader (Smooth, Linear, Scratch Cut Curves)     │
└──────────────────────────┬─────────────────────────────┘
                           │ Dart FFI / Lock-Free Atomics
┌──────────────────────────▼─────────────────────────────┐
│                 NATIVE C/C++ AUDIO ENGINE              │
│  - Real-Time Priority Audio Thread (<10ms latency)     │
│  - Dual-Deck Audio Decoders (PCM streaming)            │
│  - Inertial Vinyl Scratch Physics & Interpolation      │
│  - 3-Band Biquad Isolator Filters with Zero Bleed      │
│  - Master Summing Bus with Soft-Clipping Limiter       │
└──────────────────────────┬─────────────────────────────┘
                           │
             ┌─────────────┴─────────────┐
             ▼                           ▼
    iOS: CoreAudio / AudioUnit   Android: Google Oboe (AAudio)
```

### Key Technical Specs

| Component | Specification |
| :--- | :--- |
| **Audio Core** | C++17 real-time DSP bus with zero memory allocations in the audio callback |
| **Target Latency** | Touch-to-sound latency < 15ms |
| **Audio Drivers** | Android: Google Oboe (AAudio + OpenSL ES fallback); iOS: CoreAudio Render Callback |
| **EQ Architecture** | 3-Band Biquad Isolator (Low Shelf @ 300Hz, Peaking Mid @ 1.2kHz, High Shelf @ 3.2kHz) with -inf dB Kill switches |
| **Crossfader Curves** | Linear blend, Exponential smooth mix, and Steep Scratch Cut (<5% cut-in point) |
| **Waveform Engine** | 3-Band RGB Frequency Spectrum (Red: Bass <250Hz, Green: Mids 250Hz-3kHz, Blue: Highs >3kHz) |
| **Pre-Cueing Support** | Mono-Split Mode (Channel L = Master Out, Channel R = Headphone Monitor) for DJ splitter cables |

---

## Directory Structure

```
dj_console_app/
├── README.md                      # Project documentation & architecture
├── AUDIT.md                       # Quality, latency, and DSP mathematical audits
├── SESSIONHANDOFF.md              # Current milestone state & maintenance plan
├── pubspec.yaml                   # Flutter package dependencies
├── lib/
│   ├── main.dart                  # Flutter application entrypoint
│   ├── core/
│   │   ├── audio_engine_ffi.dart  # Dart FFI bindings to native C++ engine
│   │   ├── dsp_math.dart          # DSP math & curve models (Dart mirror)
│   │   ├── audio_state.dart       # Reactive 2-deck state management
│   │   └── track_model.dart       # Audio track metadata & waveform peak models
│   └── ui/
│       ├── console_screen.dart    # Main DJ Console UI layout
│       └── widgets/
│           ├── deck_widget.dart       # Deck container (A & B)
│           ├── jogwheel_widget.dart   # Interactive scratch jogwheel
│           ├── waveform_widget.dart   # RGB frequency scrolling waveform
│           ├── eq_strip_widget.dart   # 3-Band EQ & Gain knobs + Kill switches
│           └── crossfader_widget.dart # Crossfader slider with curve selector
├── native/
│   ├── CMakeLists.txt             # Android NDK / Desktop C++ build configuration
│   ├── include/
│   │   └── dj_engine.h            # C-linkage API exported to Dart FFI
│   └── src/
│       ├── dj_engine.cpp          # Engine lifecycle, mixing bus, and audio callback
│       ├── deck.cpp               # Audio playback, seek, and scratch interpolation
│       ├── biquad_eq.cpp          # 3-band isolator biquad filters
│       └── crossfader.cpp         # Crossfader curve calculations
├── test/
│   └── dsp_math_test.js           # Automated test suite for DSP math and curves
├── web_preview/
│   └── index.html                 # Interactive in-browser 2-Deck DJ testbed
├── fastlane/
│   └── Fastfile                   # Mobile build & release automation
└── .github/
    └── workflows/
        └── ci_cd.yml              # GitHub Actions CI/CD pipeline
```

---

## Multi-Agent Operating Model

This project is maintained by 4 specialized autonomous agents:
* **Planning & Architecture Agent (`dj_arch_agent`)**: System design, DSP algorithms, and ADRs.
* **Development Agent (`dj_dev_agent`)**: Flutter UI widgets, C++ audio engine, and FFI integration.
* **Test & QA Agent (`dj_qa_agent`)**: DSP mathematical verification, latency profiling, and updating `AUDIT.md`.
* **Pipeline Release Agent (`dj_release_agent`)**: CI/CD, store release compliance, and updating `SESSIONHANDOFF.md`.

---

## Quick Start & Verification

### 1. Interactive In-Browser Testbed
To test the turntable scratching, dual-deck playback, 3-band EQ filters, and crossfader immediately without requiring mobile device compilation:
```bash
# Open web_preview/index.html in your browser or run a simple static server:
npx serve web_preview
```

### 2. Run DSP Math & Curve Tests
```bash
node test/dsp_math_test.js
```

### 3. Build Flutter Mobile App (When Flutter SDK is installed)
```bash
flutter pub get
flutter run
```

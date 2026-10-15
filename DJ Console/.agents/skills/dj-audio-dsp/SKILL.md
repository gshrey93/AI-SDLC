---
name: dj-audio-dsp
description: Architecture rules, low-latency DSP guidelines, biquad filter calculations, and thread-safety requirements for the C++ audio engine.
---

# DJ Audio DSP & Native Engine Skill

Use this skill when modifying, profiling, or implementing digital signal processing (DSP) features in the DJ Console audio core.

## Real-Time Audio Callback Constraints
1. **Never allocate memory:** Calls to `malloc`, `new`, `std::vector::push_back`, or string operations inside `audioCallback` cause audio dropouts and pops.
2. **Never acquire blocking locks:** Never use `std::mutex::lock()` in the render loop. Use lock-free atomics (`std::atomic<float>`) or single-producer single-consumer (SPSC) ring buffers.
3. **Soft-Clipping:** Always pass the summed output through a saturating limiter (such as `std::tanh` or a cubic soft-clipper) to prevent harsh digital wrapping at full scale (0 dBFS).

## Biquad Filter Specifications
* **Low Shelf:** 300 Hz cutoff frequency, shelf slope = 1.0.
* **Mid Peaking:** 1200 Hz center frequency, Q = 1.0.
* **High Shelf:** 3200 Hz cutoff frequency, shelf slope = 1.0.
* **Kill Switch:** Multiplier is hard-zeroed (`0.0f`) to achieve true $-\infty\text{ dB}$ attenuation without phase bleed.

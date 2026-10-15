---
name: dj-scratch-physics
description: Touch gesture tracking, vinyl platter rotational physics, cubic Hermite interpolation, and inertia decay mechanics.
---

# Vinyl Scratch Physics Skill

Use this skill when refining jogwheel touch response, platter drag behavior, and audio scrubbing quality.

## Touch to Angular Displacement
* 1 full turntable revolution ($2\pi$ radians) corresponds to 1.8 seconds of audio at standard 33.3 RPM playback.
* When touch moves, compute angular delta $\Delta\theta = \text{atan2}(y_2 - c_y, x_2 - c_x) - \text{atan2}(y_1 - c_y, x_1 - c_x)$.
* Wrap $\Delta\theta$ symmetrically around $[-\pi, \pi]$ to eliminate boundary flipping.

## Platter Inertia & Friction
* While touching: Playback speed follows touch velocity directly.
* On release: The platter preserves angular momentum with an exponential friction decay:
  $$\text{velocity}_{t+1} = \text{velocity}_t \times 0.92$$
* When $|\text{velocity}| < 0.02$, inertia terminates and playback returns to the pitch fader's tempo.

## Hermite Cubic Spline Interpolation
When scrubbing audio buffers at non-integer playback rates, standard linear interpolation causes audible high-frequency aliasing. Use 4-point Hermite cubic splines:
```cpp
float hermite(float y0, float y1, float y2, float y3, float mu) {
    float a = (3.0f * (y1 - y2) - y0 + y3) * 0.5f;
    float b = 2.0f * y2 + y0 - (5.0f * y1 + y3) * 0.5f;
    float c = (y2 - y0) * 0.5f;
    return (((a * mu) + b) * mu + c) * mu + y1;
}
```

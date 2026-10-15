#pragma once

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

#if defined(_WIN32)
#define DJ_EXPORT __declspec(dllexport)
#else
#define DJ_EXPORT __attribute__((visibility("default")))
#endif

// Crossfader Curve Types
typedef enum {
    CROSSFADER_CURVE_LINEAR = 0,
    CROSSFADER_CURVE_SMOOTH = 1,      // Constant power (equal loudness)
    CROSSFADER_CURVE_SCRATCH_CUT = 2   // Sharp cut for fast scratching
} CrossfaderCurve;

// Deck Identifiers
typedef enum {
    DECK_A = 0,
    DECK_B = 1,
    DECK_COUNT = 2
} DeckId;

// Audio Engine API Exported to Dart FFI
DJ_EXPORT bool dj_engine_init(int32_t sample_rate, int32_t buffer_size);
DJ_EXPORT void dj_engine_shutdown(void);
DJ_EXPORT bool dj_engine_start(void);
DJ_EXPORT bool dj_engine_stop(void);

// Deck Playback Controls
DJ_EXPORT void dj_deck_play(DeckId deck);
DJ_EXPORT void dj_deck_pause(DeckId deck);
DJ_EXPORT void dj_deck_cue(DeckId deck);
DJ_EXPORT void dj_deck_seek(DeckId deck, float position_seconds);
DJ_EXPORT void dj_deck_set_rate(DeckId deck, float rate_multiplier); // Pitch fader (-0.16 to +0.16)

// Vinyl Scratch & Touch Controls
DJ_EXPORT void dj_deck_touch_down(DeckId deck);
DJ_EXPORT void dj_deck_touch_move(DeckId deck, float delta_angle_radians);
DJ_EXPORT void dj_deck_touch_up(DeckId deck);

// 3-Band Isolator EQ & Gain
DJ_EXPORT void dj_deck_set_eq_low(DeckId deck, float gain_db);
DJ_EXPORT void dj_deck_set_eq_mid(DeckId deck, float gain_db);
DJ_EXPORT void dj_deck_set_eq_high(DeckId deck, float gain_db);
DJ_EXPORT void dj_deck_set_kill_low(DeckId deck, bool kill);
DJ_EXPORT void dj_deck_set_kill_mid(DeckId deck, bool kill);
DJ_EXPORT void dj_deck_set_kill_high(DeckId deck, bool kill);
DJ_EXPORT void dj_deck_set_gain(DeckId deck, float gain_linear);

// Mixer & Master Bus
DJ_EXPORT void dj_mixer_set_crossfader(float position); // -1.0 (Full A) to +1.0 (Full B)
DJ_EXPORT void dj_mixer_set_crossfader_curve(CrossfaderCurve curve);
DJ_EXPORT void dj_mixer_set_master_volume(float volume);
DJ_EXPORT void dj_mixer_set_split_cue(bool enabled); // Split Left: Master, Right: Cue

// Telemetry & State (Polling from UI)
DJ_EXPORT float dj_deck_get_position(DeckId deck);
DJ_EXPORT float dj_deck_get_vu_level(DeckId deck);
DJ_EXPORT float dj_mixer_get_master_vu_level(void);

#ifdef __cplusplus
}
#endif

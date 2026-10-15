import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// C Function Signatures
typedef DjEngineInitC = Bool Function(Int32 sampleRate, Int32 bufferSize);
typedef DjEngineInitDart = bool Function(int sampleRate, int bufferSize);

typedef DjDeckActionC = Void Function(Int32 deck);
typedef DjDeckActionDart = void Function(int deck);

typedef DjDeckFloatC = Void Function(Int32 deck, Float value);
typedef DjDeckFloatDart = void Function(int deck, double value);

typedef DjDeckKillC = Void Function(Int32 deck, Bool kill);
typedef DjDeckKillDart = void Function(int deck, bool kill);

typedef DjFloatGetterC = Float Function(Int32 deck);
typedef DjFloatGetterDart = double Function(int deck);

typedef DjMixerFloatC = Void Function(Float value);
typedef DjMixerFloatDart = void Function(double value);

/// Dart FFI Bridge to Native C++ DJ Audio Engine
class AudioEngineFFI {
  static final AudioEngineFFI instance = AudioEngineFFI._internal();
  AudioEngineFFI._internal();

  DynamicLibrary? _dylib;
  bool _isAvailable = false;

  bool get isAvailable => _isAvailable;

  void initialize({int sampleRate = 44100, int bufferSize = 512}) {
    try {
      if (Platform.isAndroid) {
        _dylib = DynamicLibrary.open('libdj_engine.so');
      } else if (Platform.isIOS || Platform.isMacOS) {
        _dylib = DynamicLibrary.process();
      } else if (Platform.isWindows) {
        _dylib = DynamicLibrary.open('dj_engine.dll');
      } else if (Platform.isLinux) {
        _dylib = DynamicLibrary.open('libdj_engine.so');
      }

      if (_dylib != null) {
        final initFunc = _dylib!.lookupFunction<DjEngineInitC, DjEngineInitDart>('dj_engine_init');
        _isAvailable = initFunc(sampleRate, bufferSize);
      }
    } catch (e) {
      // Graceful fallback to pure-Dart simulation during development
      _isAvailable = false;
    }
  }

  // Playback
  void play(int deck) => _invokeDeckAction('dj_deck_play', deck);
  void pause(int deck) => _invokeDeckAction('dj_deck_pause', deck);
  void cue(int deck) => _invokeDeckAction('dj_deck_cue', deck);
  void seek(int deck, double positionSec) => _invokeDeckFloat('dj_deck_seek', deck, positionSec);
  void setRate(int deck, double rate) => _invokeDeckFloat('dj_deck_set_rate', deck, rate);

  // Scratch
  void touchDown(int deck) => _invokeDeckAction('dj_deck_touch_down', deck);
  void touchMove(int deck, double deltaRadians) => _invokeDeckFloat('dj_deck_touch_move', deck, deltaRadians);
  void touchUp(int deck) => _invokeDeckAction('dj_deck_touch_up', deck);

  // EQ & Gain
  void setEqLow(int deck, double db) => _invokeDeckFloat('dj_deck_set_eq_low', deck, db);
  void setEqMid(int deck, double db) => _invokeDeckFloat('dj_deck_set_eq_mid', deck, db);
  void setEqHigh(int deck, double db) => _invokeDeckFloat('dj_deck_set_eq_high', deck, db);
  void setKillLow(int deck, bool kill) => _invokeDeckKill('dj_deck_set_kill_low', deck, kill);
  void setKillMid(int deck, bool kill) => _invokeDeckKill('dj_deck_set_kill_mid', deck, kill);
  void setKillHigh(int deck, bool kill) => _invokeDeckKill('dj_deck_set_kill_high', deck, kill);
  void setGain(int deck, double gain) => _invokeDeckFloat('dj_deck_set_gain', deck, gain);

  // Mixer
  void setCrossfader(double pos) {
    if (!_isAvailable || _dylib == null) return;
    try {
      final func = _dylib!.lookupFunction<DjMixerFloatC, DjMixerFloatDart>('dj_mixer_set_crossfader');
      func(pos);
    } catch (_) {}
  }

  void _invokeDeckAction(String name, int deck) {
    if (!_isAvailable || _dylib == null) return;
    try {
      final func = _dylib!.lookupFunction<DjDeckActionC, DjDeckActionDart>(name);
      func(deck);
    } catch (_) {}
  }

  void _invokeDeckFloat(String name, int deck, double val) {
    if (!_isAvailable || _dylib == null) return;
    try {
      final func = _dylib!.lookupFunction<DjDeckFloatC, DjDeckFloatDart>(name);
      func(deck, val);
    } catch (_) {}
  }

  void _invokeDeckKill(String name, int deck, bool kill) {
    if (!_isAvailable || _dylib == null) return;
    try {
      final func = _dylib!.lookupFunction<DjDeckKillC, DjDeckKillDart>(name);
      func(deck, kill);
    } catch (_) {}
  }
}

import 'package:flutter/foundation.dart';
import 'audio_engine_ffi.dart';
import 'dsp_math.dart';
import 'track_model.dart';

class DeckState {
  final int id;
  bool isPlaying = false;
  double rate = 0.0; // -0.16 to +0.16
  double positionSec = 0.0;
  double vuLevel = 0.0;
  
  // 3-Band EQ
  double eqLow = 0.0; // -24 to +6 dB
  double eqMid = 0.0;
  double eqHigh = 0.0;
  bool killLow = false;
  bool killMid = false;
  bool killHigh = false;

  TrackModel? track;

  DeckState({required this.id});
}

class AudioState extends ChangeNotifier {
  final DeckState deckA = DeckState(id: 0);
  final DeckState deckB = DeckState(id: 1);

  double crossfaderPosition = 0.0; // -1.0 (Deck A) to +1.0 (Deck B)
  CrossfaderCurve crossfaderCurve = CrossfaderCurve.smooth;
  double masterVolume = 1.0;
  bool splitCueEnabled = false;

  final AudioEngineFFI _ffi = AudioEngineFFI.instance;

  AudioState() {
    _ffi.initialize();
    // Load initial demo tracks
    deckA.track = TrackModel.syntheticDemo(id: 'trk_1', title: 'Cosmic Resonance', artist: 'Antigravity Sound');
    deckB.track = TrackModel.syntheticDemo(id: 'trk_2', title: 'Solar Flares (VIP)', artist: 'Antigravity Sound');
  }

  void togglePlay(int deckId) {
    final deck = deckId == 0 ? deckA : deckB;
    deck.isPlaying = !deck.isPlaying;
    if (deck.isPlaying) {
      _ffi.play(deckId);
    } else {
      _ffi.pause(deckId);
    }
    notifyListeners();
  }

  void cue(int deckId) {
    final deck = deckId == 0 ? deckA : deckB;
    deck.isPlaying = false;
    deck.positionSec = 0.0;
    _ffi.cue(deckId);
    notifyListeners();
  }

  void setRate(int deckId, double rate) {
    final deck = deckId == 0 ? deckA : deckB;
    deck.rate = rate.clamp(-0.16, 0.16);
    _ffi.setRate(deckId, rate);
    notifyListeners();
  }

  void touchDown(int deckId) => _ffi.touchDown(deckId);
  void touchMove(int deckId, double deltaRad) => _ffi.touchMove(deckId, deltaRad);
  void touchUp(int deckId) => _ffi.touchUp(deckId);

  // EQ Adjustments
  void setEqLow(int deckId, double db) {
    final deck = deckId == 0 ? deckA : deckB;
    deck.eqLow = db;
    _ffi.setEqLow(deckId, db);
    notifyListeners();
  }

  void setEqMid(int deckId, double db) {
    final deck = deckId == 0 ? deckA : deckB;
    deck.eqMid = db;
    _ffi.setEqMid(deckId, db);
    notifyListeners();
  }

  void setEqHigh(int deckId, double db) {
    final deck = deckId == 0 ? deckA : deckB;
    deck.eqHigh = db;
    _ffi.setEqHigh(deckId, db);
    notifyListeners();
  }

  void toggleKillLow(int deckId) {
    final deck = deckId == 0 ? deckA : deckB;
    deck.killLow = !deck.killLow;
    _ffi.setKillLow(deckId, deck.killLow);
    notifyListeners();
  }

  void toggleKillMid(int deckId) {
    final deck = deckId == 0 ? deckA : deckB;
    deck.killMid = !deck.killMid;
    _ffi.setKillMid(deckId, deck.killMid);
    notifyListeners();
  }

  void toggleKillHigh(int deckId) {
    final deck = deckId == 0 ? deckA : deckB;
    deck.killHigh = !deck.killHigh;
    _ffi.setKillHigh(deckId, deck.killHigh);
    notifyListeners();
  }

  // Crossfader
  void setCrossfader(double pos) {
    crossfaderPosition = pos.clamp(-1.0, 1.0);
    _ffi.setCrossfader(crossfaderPosition);
    notifyListeners();
  }

  void setCrossfaderCurve(CrossfaderCurve curve) {
    crossfaderCurve = curve;
    notifyListeners();
  }

  void toggleSplitCue() {
    splitCueEnabled = !splitCueEnabled;
    notifyListeners();
  }
}

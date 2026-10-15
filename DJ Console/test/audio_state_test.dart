import 'package:flutter_test/flutter_test.dart';
import '../lib/core/audio_state.dart';
import '../lib/core/dsp_math.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioState Management Tests', () {
    late AudioState audioState;

    setUp(() {
      audioState = AudioState();
    });

    test('TC-ST-01: Initial state has 2 demo decks with synthetic tracks loaded', () {
      expect(audioState.deckA.id, equals(0));
      expect(audioState.deckB.id, equals(1));
      expect(audioState.deckA.track, isNotNull);
      expect(audioState.deckB.track, isNotNull);
      expect(audioState.deckA.isPlaying, isFalse);
      expect(audioState.deckB.isPlaying, isFalse);
      expect(audioState.crossfaderPosition, equals(0.0));
    });

    test('TC-ST-02: Play and pause toggle states correctly', () {
      audioState.togglePlay(0);
      expect(audioState.deckA.isPlaying, isTrue);

      audioState.togglePlay(0);
      expect(audioState.deckA.isPlaying, isFalse);
    });

    test('TC-ST-03: Cue stops playback and resets playhead to start', () {
      audioState.togglePlay(1);
      audioState.deckB.positionSec = 45.2;

      audioState.cue(1);
      expect(audioState.deckB.isPlaying, isFalse);
      expect(audioState.deckB.positionSec, equals(0.0));
    });

    test('TC-ST-04: Pitch rate clamps securely between -16% and +16%', () {
      audioState.setRate(0, 0.08);
      expect(audioState.deckA.rate, closeTo(0.08, 1e-4));

      // Overdrive test: value beyond +16%
      audioState.setRate(0, 0.50);
      expect(audioState.deckA.rate, closeTo(0.16, 1e-4));

      // Underdrive test: value below -16%
      audioState.setRate(0, -0.40);
      expect(audioState.deckA.rate, closeTo(-0.16, 1e-4));
    });

    test('TC-ST-05: 3-Band EQ and Kill switch toggles modify state and notify listeners', () {
      audioState.setEqLow(0, -12.0);
      audioState.setEqMid(0, 3.0);
      audioState.setEqHigh(0, 5.0);

      expect(audioState.deckA.eqLow, equals(-12.0));
      expect(audioState.deckA.eqMid, equals(3.0));
      expect(audioState.deckA.eqHigh, equals(5.0));

      expect(audioState.deckA.killLow, isFalse);
      audioState.toggleKillLow(0);
      expect(audioState.deckA.killLow, isTrue);

      audioState.toggleKillLow(0);
      expect(audioState.deckA.killLow, isFalse);
    });

    test('TC-ST-06: Crossfader position and curve mode adjustments', () {
      audioState.setCrossfader(0.75);
      expect(audioState.crossfaderPosition, equals(0.75));

      audioState.setCrossfader(2.5); // Bound clamping test
      expect(audioState.crossfaderPosition, equals(1.0));

      audioState.setCrossfaderCurve(CrossfaderCurve.scratchCut);
      expect(audioState.crossfaderCurve, equals(CrossfaderCurve.scratchCut));
    });

    test('TC-ST-07: Split-cue monitoring toggle', () {
      expect(audioState.splitCueEnabled, isFalse);
      audioState.toggleSplitCue();
      expect(audioState.splitCueEnabled, isTrue);
    });
  });
}

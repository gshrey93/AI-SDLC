import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import '../lib/core/dsp_math.dart';

void main() {
  group('Crossfader Curve Mathematical Tests', () {
    test('TC-XF-01: Linear curve endpoints and 50/50 center balance', () {
      final left = DspMath.calculateCrossfaderGains(-1.0, CrossfaderCurve.linear);
      expect(left['gainA'], closeTo(1.0, 1e-5));
      expect(left['gainB'], closeTo(0.0, 1e-5));

      final center = DspMath.calculateCrossfaderGains(0.0, CrossfaderCurve.linear);
      expect(center['gainA'], closeTo(0.5, 1e-5));
      expect(center['gainB'], closeTo(0.5, 1e-5));

      final right = DspMath.calculateCrossfaderGains(1.0, CrossfaderCurve.linear);
      expect(right['gainA'], closeTo(0.0, 1e-5));
      expect(right['gainB'], closeTo(1.0, 1e-5));
    });

    test('TC-XF-02: Constant Power (Smooth) preserves flat 0dB energy sum across full sweep', () {
      for (double pos = -1.0; pos <= 1.0; pos += 0.1) {
        final gains = DspMath.calculateCrossfaderGains(pos, CrossfaderCurve.smooth);
        final gA = gains['gainA']!;
        final gB = gains['gainB']!;
        final energySum = (gA * gA) + (gB * gB);
        expect(energySum, closeTo(1.0, 1e-4), reason: 'Energy sum violated at position $pos');
      }

      final center = DspMath.calculateCrossfaderGains(0.0, CrossfaderCurve.smooth);
      expect(center['gainA'], closeTo(math.sqrt1_2, 1e-4));
      expect(center['gainB'], closeTo(math.sqrt1_2, 1e-4));
    });

    test('TC-XF-03: Sharp Scratch Cut has <5% cut-in lag and full travel open', () {
      final edge = DspMath.calculateCrossfaderGains(-1.0, CrossfaderCurve.scratchCut);
      expect(edge['gainA'], closeTo(1.0, 1e-5));
      expect(edge['gainB'], closeTo(0.0, 1e-5));

      // 6% travel into fader (position = -0.88 -> t = 0.06)
      final pastCutIn = DspMath.calculateCrossfaderGains(-0.88, CrossfaderCurve.scratchCut);
      expect(pastCutIn['gainA'], closeTo(1.0, 1e-5));
      expect(pastCutIn['gainB'], closeTo(1.0, 1e-5)); // Full volume cut-in achieved
    });
  });

  group('Hermite Spline Cubic Interpolation Tests', () {
    test('TC-INT-01: Hermite spline exact boundary convergence', () {
      const y0 = 0.2;
      const y1 = 0.5;
      const y2 = 0.8;
      const y3 = 0.9;

      final at0 = DspMath.hermite(y0, y1, y2, y3, 0.0);
      expect(at0, closeTo(y1, 1e-6));

      final at1 = DspMath.hermite(y0, y1, y2, y3, 1.0);
      expect(at1, closeTo(y2, 1e-6));
    });

    test('TC-INT-02: Hermite midpoint smoothness and monotonic bounding', () {
      const y0 = 0.1;
      const y1 = 0.4;
      const y2 = 0.7;
      const y3 = 0.95;

      final mid = DspMath.hermite(y0, y1, y2, y3, 0.5);
      expect(mid, greaterThanOrEqualTo(y1));
      expect(mid, lessThanOrEqualTo(y2));
    });
  });
}

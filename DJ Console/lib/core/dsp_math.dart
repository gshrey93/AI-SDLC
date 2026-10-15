import 'dart:math' as math;

/// Crossfader Curve Types matching native C++ engine
enum CrossfaderCurve {
  linear,
  smooth,      // Constant power (equal loudness)
  scratchCut,  // Sharp cut for fast scratching
}

/// Helper class encapsulating DSP curve calculations and audio math
class DspMath {
  /// Calculates crossfader gains (gainA, gainB) from normalized position [-1.0, 1.0]
  static Map<String, double> calculateCrossfaderGains(double position, CrossfaderCurve curve) {
    // Map position [-1.0, 1.0] to t in [0.0, 1.0] where 0 = 100% Deck A, 1 = 100% Deck B
    final double t = ((position + 1.0) * 0.5).clamp(0.0, 1.0);

    double gainA = 0.0;
    double gainB = 0.0;

    switch (curve) {
      case CrossfaderCurve.linear:
        gainA = 1.0 - t;
        gainB = t;
        break;

      case CrossfaderCurve.smooth:
        // Constant Energy / Equal Power: cos^2(theta) + sin^2(theta) = 1.0
        final double angle = t * (math.pi / 2.0);
        gainA = math.cos(angle);
        gainB = math.sin(angle);
        break;

      case CrossfaderCurve.scratchCut:
        const double cutThreshold = 0.05; // 5% cut-in travel
        gainA = (t >= (1.0 - cutThreshold)) ? (1.0 - t) / cutThreshold : 1.0;
        gainB = (t <= cutThreshold) ? t / cutThreshold : 1.0;
        break;
    }

    return {
      'gainA': gainA.clamp(0.0, 1.0),
      'gainB': gainB.clamp(0.0, 1.0),
    };
  }

  /// 4-point Hermite cubic spline interpolation for sample scrubbing
  static double hermite(double y0, double y1, double y2, double y3, double mu) {
    final double a = (3.0 * (y1 - y2) - y0 + y3) * 0.5;
    final double b = 2.0 * y2 + y0 - (5.0 * y1 + y3) * 0.5;
    final double c = (y2 - y0) * 0.5;
    return (((a * mu) + b) * mu + c) * mu + y1;
  }
}

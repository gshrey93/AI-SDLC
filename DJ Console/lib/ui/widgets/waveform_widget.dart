import 'package:flutter/material.dart';
import '../../core/track_model.dart';

/// 60/120 FPS Frequency-Colored Scrolling Waveform Widget
class WaveformWidget extends StatelessWidget {
  final TrackModel? track;
  final double playbackPositionSec;
  final Color deckColor;

  const WaveformWidget({
    Key? key,
    required this.track,
    required this.playbackPositionSec,
    required this.deckColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CustomPaint(
          painter: _WaveformPainter(
            peaks: track?.peaks ?? [],
            positionSec: playbackPositionSec,
            deckColor: deckColor,
          ),
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<WaveformPeak> peaks;
  final double positionSec;
  final Color deckColor;

  _WaveformPainter({
    required this.peaks,
    required this.positionSec,
    required this.deckColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (peaks.isEmpty) {
      // Empty waveform placeholder line
      final linePaint = Paint()
        ..color = Colors.white12
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), linePaint);
      return;
    }

    final double midY = size.height / 2;
    const double barWidth = 3.0;
    final int visibleBars = (size.width / barWidth).ceil();

    // Compute playhead center offset
    final double scrollOffset = (positionSec * 15.0) % peaks.length;

    for (int i = 0; i < visibleBars; i++) {
      final double x = i * barWidth;
      final int peakIndex = ((i + scrollOffset.toInt()) % peaks.length).abs();
      final peak = peaks[peakIndex];

      // Frequency RGB mixture: Bass (Red), Mid (Green), High (Blue)
      final Color barColor = Color.fromARGB(
        255,
        (peak.bass * 255).toInt().clamp(0, 255),
        (peak.mid * 220).toInt().clamp(0, 255),
        (peak.high * 255).toInt().clamp(0, 255),
      );

      final double amplitude = peak.maxAmplitude * (midY - 4);

      final barPaint = Paint()
        ..color = barColor
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(x, midY - amplitude, barWidth - 1, amplitude * 2),
        barPaint,
      );
    }

    // Playhead Line (Center of the screen)
    final playheadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      playheadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) => true;
}

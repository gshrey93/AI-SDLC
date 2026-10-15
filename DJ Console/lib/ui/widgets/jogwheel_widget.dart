import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Interactive Vinyl Scratch Jogwheel Widget with rotational gesture tracking
class JogwheelWidget extends StatefulWidget {
  final int deckId;
  final Color deckColor;
  final bool isPlaying;
  final double playbackRate;
  final ValueChanged<double> onScratchMove;
  final VoidCallback onTouchDown;
  final VoidCallback onTouchUp;

  const JogwheelWidget({
    Key? key,
    required this.deckId,
    required this.deckColor,
    required this.isPlaying,
    required this.playbackRate,
    required this.onScratchMove,
    required this.onTouchDown,
    required this.onTouchUp,
  }) : super(key: key);

  @override
  State<JogwheelWidget> createState() => _JogwheelWidgetState();
}

class _JogwheelWidgetState extends State<JogwheelWidget> with SingleTickerProviderStateMixin {
  double _currentAngle = 0.0;
  double? _lastTouchAngle;
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800), // ~33.3 RPM
    )..addListener(() {
      if (widget.isPlaying && _lastTouchAngle == null) {
        setState(() {
          _currentAngle += 0.035 * (1.0 + widget.playbackRate);
        });
      }
    });

    if (widget.isPlaying) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(JogwheelWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  double _calculateAngle(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    return math.atan2(localPosition.dy - center.dy, localPosition.dx - center.dx);
  }

  void _onPanStart(DragStartDetails details, Size size) {
    widget.onTouchDown();
    _lastTouchAngle = _calculateAngle(details.localPosition, size);
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    final currentAngle = _calculateAngle(details.localPosition, size);
    if (_lastTouchAngle != null) {
      double delta = currentAngle - _lastTouchAngle!;
      // Handle +/- PI boundary wrap-around
      if (delta > math.pi) delta -= 2 * math.pi;
      if (delta < -math.pi) delta += 2 * math.pi;

      setState(() {
        _currentAngle += delta;
      });
      widget.onScratchMove(delta);
    }
    _lastTouchAngle = currentAngle;
  }

  void _onPanEnd(DragEndDetails details) {
    _lastTouchAngle = null;
    widget.onTouchUp();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double size = math.min(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          onPanStart: (details) => _onPanStart(details, Size(size, size)),
          onPanUpdate: (details) => _onPanUpdate(details, Size(size, size)),
          onPanEnd: _onPanEnd,
          child: SizedBox(
            width: size,
            height: size,
            child: Transform.rotate(
              angle: _currentAngle,
              child: CustomPaint(
                painter: _PlatterPainter(deckColor: widget.deckColor, deckId: widget.deckId),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PlatterPainter extends CustomPainter {
  final Color deckColor;
  final int deckId;

  _PlatterPainter({required this.deckColor, required this.deckId});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Platter Outer Rim
    final rimPaint = Paint()
      ..color = const Color(0xFF22272E)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, rimPaint);

    // Vinyl Body with Radial Grooves
    final vinylPaint = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFF2D333B), Color(0xFF161B22), Color(0xFF0D1117)],
      ).createShader(Rect.fromCircle(center: center, radius: radius - 6));
    canvas.drawCircle(center, radius - 6, vinylPaint);

    // Groove rings
    final groovePaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    for (double r = radius * 0.45; r < radius - 12; r += 6.0) {
      canvas.drawCircle(center, r, groovePaint);
    }

    // Center Label
    final labelPaint = Paint()..color = deckColor;
    canvas.drawCircle(center, radius * 0.32, labelPaint);

    final spindlePaint = Paint()..color = const Color(0xFF0D1117);
    canvas.drawCircle(center, radius * 0.08, spindlePaint);

    // Strobe / Position Marker
    final markerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx, center.dy - radius + 8),
      Offset(center.dx, center.dy - radius * 0.45),
      markerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PlatterPainter oldDelegate) =>
      oldDelegate.deckColor != deckColor || oldDelegate.deckId != deckId;
}

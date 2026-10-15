import 'package:flutter/material.dart';
import '../../core/dsp_math.dart';

/// Crossfader Slider Widget with Curve Selector
class CrossfaderWidget extends StatelessWidget {
  final double position; // -1.0 to +1.0
  final CrossfaderCurve curve;
  final ValueChanged<double> onPositionChanged;
  final ValueChanged<CrossfaderCurve> onCurveChanged;

  const CrossfaderWidget({
    Key? key,
    required this.position,
    required this.curve,
    required this.onPositionChanged,
    required this.onCurveChanged,
  }) : super(key: key);

  String get _positionLabel {
    if (position < -0.05) return 'DECK A (${((1.0 - (position + 1) * 0.5) * 100).toInt()}%)';
    if (position > 0.05) return 'DECK B (${(((position + 1) * 0.5) * 100).toInt()}%)';
    return 'CENTER (50/50)';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CROSSFADER',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF8B949E)),
              ),
              Text(
                _positionLabel,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF58A6FF)),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: const Color(0xFF58A6FF),
              inactiveTrackColor: const Color(0xFF21262D),
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: position,
              min: -1.0,
              max: 1.0,
              onChanged: onPositionChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Curve:', style: TextStyle(fontSize: 10, color: Color(0xFF8B949E))),
              DropdownButton<CrossfaderCurve>(
                value: curve,
                dropdownColor: const Color(0xFF21262D),
                isDense: true,
                style: const TextStyle(fontSize: 10, color: Colors.white),
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: CrossfaderCurve.smooth, child: Text('Equal Power (Smooth)')),
                  DropdownMenuItem(value: CrossfaderCurve.linear, child: Text('Linear Mix')),
                  DropdownMenuItem(value: CrossfaderCurve.scratchCut, child: Text('Sharp Scratch Cut')),
                ],
                onChanged: (newCurve) {
                  if (newCurve != null) onCurveChanged(newCurve);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

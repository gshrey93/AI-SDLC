import 'package:flutter/material.dart';

/// 3-Band Isolator EQ & Gain Strip Widget with Kill Buttons
class EqStripWidget extends StatelessWidget {
  final String label;
  final double eqHigh;
  final double eqMid;
  final double eqLow;
  final bool killHigh;
  final bool killMid;
  final bool killLow;
  final ValueChanged<double> onHighChanged;
  final ValueChanged<double> onMidChanged;
  final ValueChanged<double> onLowChanged;
  final VoidCallback onToggleKillHigh;
  final VoidCallback onToggleKillMid;
  final VoidCallback onToggleKillLow;

  const EqStripWidget({
    Key? key,
    required this.label,
    required this.eqHigh,
    required this.eqMid,
    required this.eqLow,
    required this.killHigh,
    required this.killMid,
    required this.killLow,
    required this.onHighChanged,
    required this.onMidChanged,
    required this.onLowChanged,
    required this.onToggleKillHigh,
    required this.onToggleKillMid,
    required this.onToggleKillLow,
  }) : super(key: key);

  Widget _buildBandRow({
    required BuildContext context,
    required String bandName,
    required double value,
    required bool isKilled,
    required ValueChanged<double> onChanged,
    required VoidCallback onToggleKill,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                bandName,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8B949E)),
              ),
              InkWell(
                onTap: onToggleKill,
                borderRadius: BorderRadius.circular(3),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isKilled ? const Color(0xFFDA3633) : const Color(0xFF21262D),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: isKilled ? const Color(0xFFF85149) : const Color(0xFF30363D)),
                  ),
                  child: Text(
                    'KILL',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: isKilled ? Colors.white : const Color(0xFF8B949E),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
              activeTrackColor: const Color(0xFF58A6FF),
              inactiveTrackColor: const Color(0xFF21262D),
              thumbColor: Colors.white,
            ),
            child: Slider(
              value: value,
              min: -24.0,
              max: 6.0,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          _buildBandRow(
            context: context,
            bandName: 'HI (3.2k)',
            value: eqHigh,
            isKilled: killHigh,
            onChanged: onHighChanged,
            onToggleKill: onToggleKillHigh,
          ),
          _buildBandRow(
            context: context,
            bandName: 'MID (1.2k)',
            value: eqMid,
            isKilled: killMid,
            onChanged: onMidChanged,
            onToggleKill: onToggleKillMid,
          ),
          _buildBandRow(
            context: context,
            bandName: 'LOW (300Hz)',
            value: eqLow,
            isKilled: killLow,
            onChanged: onLowChanged,
            onToggleKill: onToggleKillLow,
          ),
        ],
      ),
    );
  }
}

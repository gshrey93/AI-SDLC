import 'package:flutter/material.dart';
import '../../core/audio_state.dart';
import 'jogwheel_widget.dart';
import 'waveform_widget.dart';
import 'eq_strip_widget.dart';

/// Complete Deck Panel Widget (Deck A or Deck B)
class DeckWidget extends StatelessWidget {
  final DeckState deck;
  final Color deckColor;
  final String deckName;
  final AudioState audioState;

  const DeckWidget({
    Key? key,
    required this.deck,
    required this.deckColor,
    required this.deckName,
    required this.audioState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Track Title & Deck Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: deckColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  deckName,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deck.track?.title ?? 'No Track Loaded',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        deck.track?.artist ?? 'Unknown Artist',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF8B949E)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                '${deck.track?.bpm.toStringAsFixed(1) ?? '128.0'} BPM',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF58A6FF)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Scrolling Frequency-Colored Waveform
          WaveformWidget(
            track: deck.track,
            playbackPositionSec: deck.positionSec,
            deckColor: deckColor,
          ),
          const SizedBox(height: 12),

          // Center: Jogwheel and EQ side-by-side
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: JogwheelWidget(
                    deckId: deck.id,
                    deckColor: deckColor,
                    isPlaying: deck.isPlaying,
                    playbackRate: deck.rate,
                    onTouchDown: () => audioState.touchDown(deck.id),
                    onScratchMove: (delta) => audioState.touchMove(deck.id, delta),
                    onTouchUp: () => audioState.touchUp(deck.id),
                  ),
                ),
                const SizedBox(width: 8),
                EqStripWidget(
                  label: '$deckName EQ',
                  eqHigh: deck.eqHigh,
                  eqMid: deck.eqMid,
                  eqLow: deck.eqLow,
                  killHigh: deck.killHigh,
                  killMid: deck.killMid,
                  killLow: deck.killLow,
                  onHighChanged: (v) => audioState.setEqHigh(deck.id, v),
                  onMidChanged: (v) => audioState.setEqMid(deck.id, v),
                  onLowChanged: (v) => audioState.setEqLow(deck.id, v),
                  onToggleKillHigh: () => audioState.toggleKillHigh(deck.id),
                  onToggleKillMid: () => audioState.toggleKillMid(deck.id),
                  onToggleKillLow: () => audioState.toggleKillLow(deck.id),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Transport Buttons (CUE and PLAY)
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD29922),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () => audioState.cue(deck.id),
                  child: const Text('CUE', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: deck.isPlaying ? const Color(0xFFDA3633) : const Color(0xFF238636),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () => audioState.togglePlay(deck.id),
                  child: Text(
                    deck.isPlaying ? 'PAUSE' : 'PLAY',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

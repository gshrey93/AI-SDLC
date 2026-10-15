import 'package:flutter/material.dart';
import '../core/audio_state.dart';
import 'widgets/deck_widget.dart';
import 'widgets/crossfader_widget.dart';

/// Main DJ Console Mobile Screen Layout
class ConsoleScreen extends StatelessWidget {
  final AudioState audioState;

  const ConsoleScreen({Key? key, required this.audioState}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: audioState,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF0D1117),
          appBar: AppBar(
            backgroundColor: const Color(0xFF161B22),
            elevation: 0,
            title: Row(
              children: [
                const Text(
                  'DJ CONSOLE PRO',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF238636),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('CORE ENGINE ACTIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            actions: [
              // Split-Cue Toggle
              IconButton(
                tooltip: 'Split Cue (Mono Master / Cue Splitter)',
                icon: Icon(
                  Icons.headphones,
                  color: audioState.splitCueEnabled ? const Color(0xFF58A6FF) : const Color(0xFF8B949E),
                ),
                onPressed: audioState.toggleSplitCue,
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  // Twin-Deck Layout (Deck A and Deck B)
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Deck A
                        Expanded(
                          child: DeckWidget(
                            deck: audioState.deckA,
                            deckColor: const Color(0xFF00E5FF),
                            deckName: 'DECK A',
                            audioState: audioState,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Deck B
                        Expanded(
                          child: DeckWidget(
                            deck: audioState.deckB,
                            deckColor: const Color(0xFFFF0055),
                            deckName: 'DECK B',
                            audioState: audioState,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Bottom Master Crossfader
                  CrossfaderWidget(
                    position: audioState.crossfaderPosition,
                    curve: audioState.crossfaderCurve,
                    onPositionChanged: audioState.setCrossfader,
                    onCurveChanged: audioState.setCrossfaderCurve,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

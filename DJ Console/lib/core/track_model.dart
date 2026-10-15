/// Model representing an audio track loaded into a DJ deck
class TrackModel {
  final String id;
  final String title;
  final String artist;
  final double bpm;
  final Duration duration;
  final List<WaveformPeak> peaks;

  const TrackModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.bpm,
    required this.duration,
    required this.peaks,
  });

  /// Generates a synthetic demo track with frequency-separated peaks for testing
  factory TrackModel.syntheticDemo({required String id, required String title, required String artist, double bpm = 128.0}) {
    const int sampleCount = 400;
    final List<WaveformPeak> generatedPeaks = [];

    for (int i = 0; i < sampleCount; i++) {
      final double phase = (i % 32) / 32.0;
      // Kick drum peak every 8 bars
      final double bass = (i % 8 == 0) ? 0.95 : (0.2 + (i % 4 == 0 ? 0.4 : 0.0));
      final double mid = 0.3 + 0.5 * ((i % 16) / 16.0);
      final double high = (i % 4 == 2) ? 0.8 : 0.25;

      generatedPeaks.add(WaveformPeak(
        bass: bass.clamp(0.0, 1.0),
        mid: mid.clamp(0.0, 1.0),
        high: high.clamp(0.0, 1.0),
      ));
    }

    return TrackModel(
      id: id,
      title: title,
      artist: artist,
      bpm: bpm,
      duration: const Duration(minutes: 4, seconds: 15),
      peaks: generatedPeaks,
    );
  }
}

/// Represents frequency-separated peak values for a single waveform slice
class WaveformPeak {
  final double bass; // Lows: 20Hz - 250Hz (Red)
  final double mid;  // Mids: 250Hz - 3kHz (Green)
  final double high; // Highs: 3kHz - 20kHz (Blue)

  const WaveformPeak({
    required this.bass,
    required this.mid,
    required this.high,
  });

  double get maxAmplitude => [bass, mid, high].reduce((a, b) => a > b ? a : b);
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/core/audio_state.dart';
import '../lib/ui/console_screen.dart';

void main() {
  testWidgets('TC-UI-01: ConsoleScreen renders Deck A, Deck B, and Crossfader', (WidgetTester tester) async {
    final audioState = AudioState();

    // Set viewport to landscape orientation typical for mobile DJ console
    tester.binding.window.physicalSizeTestValue = const Size(1920, 1080);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

    await tester.pumpWidget(
      MaterialApp(
        home: ConsoleScreen(audioState: audioState),
      ),
    );

    // Verify main screen branding
    expect(find.text('DJ CONSOLE PRO'), findsOneWidget);
    expect(find.text('CORE ENGINE ACTIVE'), findsOneWidget);

    // Verify Deck A elements
    expect(find.text('DECK A'), findsOneWidget);
    expect(find.text('Cosmic Resonance'), findsOneWidget);

    // Verify Deck B elements
    expect(find.text('DECK B'), findsOneWidget);
    expect(find.text('Solar Flares (VIP)'), findsOneWidget);

    // Verify Transport buttons
    expect(find.text('PLAY'), findsNWidgets(2));
    expect(find.text('CUE'), findsNWidgets(2));

    // Verify Crossfader
    expect(find.text('CROSSFADER'), findsOneWidget);
  });
}

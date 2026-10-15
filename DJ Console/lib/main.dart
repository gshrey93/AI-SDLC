import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/audio_state.dart';
import 'ui/console_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Force landscape orientation for real-world dual-deck DJ console experience
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final audioState = AudioState();

  runApp(DjConsoleApp(audioState: audioState));
}

class DjConsoleApp extends StatelessWidget {
  final AudioState audioState;

  const DjConsoleApp({Key? key, required this.audioState}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DJ Console Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        primaryColor: const Color(0xFF58A6FF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF58A6FF),
          secondary: Color(0xFF00E5FF),
          surface: Color(0xFF161B22),
          background: Color(0xFF0D1117),
        ),
      ),
      home: ConsoleScreen(audioState: audioState),
    );
  }
}

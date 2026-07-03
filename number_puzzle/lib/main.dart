import 'package:flutter/material.dart';
import 'screens/welcome.dart';

void main() {
  runApp(const NumberPuzzleApp());
}

class NumberPuzzleApp extends StatelessWidget {
  const NumberPuzzleApp({super.key});

  static const String _fontFamily = 'Roboto';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Numo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
        fontFamily: _fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C6EFF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}

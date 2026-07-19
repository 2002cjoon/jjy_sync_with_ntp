// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/emulator_screen.dart';

void main() {
  runApp(const JJYEmulatorApp());
}

class JJYEmulatorApp extends StatelessWidget {
  const JJYEmulatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JJY Atomic Sync Emulator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          secondary: Colors.greenAccent,
        ),
      ),
      home: const EmulatorScreen(),
    );
  }
}
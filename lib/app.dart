import 'package:flutter/material.dart';
import 'core/theme/retro_theme.dart';
import 'core/llm/llm_setup_screen.dart';

class ReadyPlayerApp extends StatelessWidget {
  const ReadyPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ready Player',
      theme: RetroTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const LlmSetupScreen(),
    );
  }
}

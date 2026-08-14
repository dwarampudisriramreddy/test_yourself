import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';

import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const token = String.fromEnvironment('HUGGINGFACE_TOKEN');
  try {
    await FlutterGemma.initialize(
      inferenceEngines: const [LiteRtLmEngine()],
      huggingFaceToken: token.isNotEmpty ? token : null,
    );
  } catch (e) {
    debugPrint('FlutterGemma.initialize failed: $e');
  }

  runApp(const TestAiApp());
}

class TestAiApp extends StatelessWidget {
  const TestAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Quiz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

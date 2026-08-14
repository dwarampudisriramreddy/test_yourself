import 'package:flutter_gemma/flutter_gemma.dart';

import '../models/quiz.dart';

class QuizGenerationException implements Exception {
  final String message;
  const QuizGenerationException(this.message);

  @override
  String toString() => message;
}

/// Thin wrapper around the on-device Gemma model (LiteRT-LM engine).
///
/// The model file is downloaded once on first launch and cached on device;
/// afterwards quiz generation works fully offline.
class QuizGenerator {
  /// Override at build/run time with
  /// `--dart-define=GEMMA_MODEL_URL=...` if you want a different model.
  static const String modelUrl = String.fromEnvironment(
    'GEMMA_MODEL_URL',
    defaultValue:
        'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/'
        'Gemma3-1B-IT_multi-prefill-seq_q4_ekv4096.litertlm',
  );

  static const String _modelId =
      'Gemma3-1B-IT_multi-prefill-seq_q4_ekv4096.litertlm';

  static const String _hfToken = String.fromEnvironment('HUGGINGFACE_TOKEN');

  static InferenceModel? _model;

  static Future<bool> isModelInstalled() async {
    try {
      return await FlutterGemma.isModelInstalled(_modelId);
    } catch (_) {
      return false;
    }
  }

  /// Downloads and installs the model file (one time). The token is only
  /// needed for gated HuggingFace repos (Gemma 3 1B is one of them).
  static Future<void> installModel({
    void Function(int progress)? onProgress,
  }) async {
    await FlutterGemma.installModel(modelType: ModelType.gemmaIt)
        .fromNetwork(modelUrl, token: _hfToken.isNotEmpty ? _hfToken : null)
        .withProgress(onProgress ?? (_) {})
        .install();
  }

  /// Loads the installed model into memory. Tries the GPU backend first and
  /// falls back to CPU. The loaded model is reused across generations.
  static Future<InferenceModel> _ensureModel() async {
    if (_model != null) return _model!;
    try {
      _model = await FlutterGemma.getActiveModel(
        maxTokens: 4096,
        preferredBackend: PreferredBackend.gpu,
      );
    } catch (_) {
      _model = await FlutterGemma.getActiveModel(
        maxTokens: 4096,
        preferredBackend: PreferredBackend.cpu,
      );
    }
    return _model!;
  }

  /// Generates [questionCount] multiple-choice questions for [topic] in a
  /// single inference, parses the returned JSON, and hands back a [Quiz].
  static Future<Quiz> generateQuiz({
    required String topic,
    required int questionCount,
    required String difficulty,
  }) async {
    final model = await _ensureModel();
    final chat = await model.createChat(
      systemInstruction:
          'You are a quiz generator. Respond with ONLY a single valid JSON '
          'object. Never use markdown, code fences, or any other text.',
      maxOutputTokens: 2500,
    );

    final prompt = '''
Generate a multiple-choice quiz as strict JSON.

Topic: $topic
Number of questions: $questionCount
Difficulty: $difficulty

Use EXACTLY this schema. "answer" is the 0-based index of the correct option:

{"topic": "$topic", "questions": [{"question": "?", "options": ["A", "B", "C", "D"], "answer": 0, "explanation": "why"}]}

Rules:
- Exactly $questionCount questions.
- Every question has exactly 4 options.
- "answer" must be the 0-based index (0..3) of the correct option.
- Explanations must be one concise sentence.
- Output ONLY the JSON object, nothing else.''';

    try {
      await chat.addQueryChunk(Message.text(text: prompt, isUser: true));
      final response = await chat.generateChatResponse();

      final text = switch (response) {
        TextResponse(:final token) => token,
        _ => '',
      };

      final quiz = Quiz.tryParseJson(text);
      if (quiz == null) {
        throw const QuizGenerationException(
          'The model did not return valid quiz JSON. Please try again.',
        );
      }
      return quiz;
    } finally {
      await chat.close();
    }
  }
}

import 'package:flutter_gemma/flutter_gemma.dart';

import '../models/quiz.dart';

class QuizGenerationException implements Exception {
  final String message;
  const QuizGenerationException(this.message);

  @override
  String toString() => message;
}

/// Thin wrapper around the on-device LLM (LiteRT-LM engine).
///
/// The model file is downloaded once on first launch and cached on device;
/// afterwards quiz generation works fully offline.
///
/// Model selection is compile-time configurable with `--dart-define`:
/// - `MODEL_URL`: huggingface download URL (default: public Qwen3 0.6B)
/// - `MODEL_TYPE`: `qwen3` | `qwen` | `gemma` | `deepseek` | `general`
/// - `HUGGINGFACE_TOKEN`: only needed for gated repos (e.g. Gemma 3 1B)
class QuizGenerator {
  /// Defaults to a PUBLIC (no-token) Qwen3 0.6B Instruct `.litertlm`.
  /// This is the model Google officially benchmarks on Android GPU (OpenCL).
  static const String modelUrl = String.fromEnvironment(
    'MODEL_URL',
    defaultValue: 'https://huggingface.co/litert-community/'
        'Qwen3-0.6B/resolve/main/Qwen3-0.6B.litertlm',
  );

  static const String _modelTypeName = String.fromEnvironment(
    'MODEL_TYPE',
    defaultValue: 'qwen3',
  );

  /// To use gated Gemma models, run with
  /// `--dart-define=HUGGINGFACE_TOKEN=hf_...` and request access at
  /// https://huggingface.co/litert-community/Gemma3-1B-IT
  static const String _hfToken = String.fromEnvironment('HUGGINGFACE_TOKEN');

  static ModelType get modelType => switch (_modelTypeName) {
        'gemma' => ModelType.gemmaIt,
        'qwen3' => ModelType.qwen3,
        'deepseek' => ModelType.deepSeek,
        'general' => ModelType.general,
        _ => ModelType.qwen,
      };

  static String get modelDisplayName => switch (_modelTypeName) {
        'gemma' => 'Gemma 3 1B IT',
        'qwen3' => 'Qwen3 0.6B',
        'deepseek' => 'DeepSeek R1 1.5B',
        'general' => 'On-device model',
        _ => 'Qwen 2.5 1.5B Instruct',
      };

  static String get _modelId => modelUrl.split('/').last;

  static InferenceModel? _model;

  static Future<bool> isModelInstalled() async {
    try {
      return await FlutterGemma.isModelInstalled(_modelId);
    } catch (_) {
      return false;
    }
  }

  /// Downloads and installs the model file (one time). The token is only
  /// needed for gated HuggingFace repos (e.g. Gemma 3 1B).
  static Future<void> installModel({
    void Function(int progress)? onProgress,
  }) async {
    if (!modelUrl.toLowerCase().endsWith('.litertlm')) {
      throw const QuizGenerationException(
        'MODEL_URL must point to a .litertlm file. '
        'The LiteRT-LM engine cannot load .task/.tflite models.',
      );
    }
    await FlutterGemma.installModel(
      modelType: modelType,
      fileType: ModelFileType.litertlm,
    )
        .fromNetwork(modelUrl, token: _hfToken.isNotEmpty ? _hfToken : null)
        .withProgress(onProgress ?? (_) {})
        .install();
  }

  /// Loads the installed model into memory. Tries the GPU backend first and
  /// falls back to CPU. The loaded model is reused across generations.
  static Future<InferenceModel> _ensureModel() async {
    if (_model != null) return _model!;
    try {
      debugPrint('Attempting to load model on GPU...');
      _model = await FlutterGemma.getActiveModel(
        maxTokens: 1024,
        preferredBackend: PreferredBackend.gpu,
      );
      debugPrint('Successfully loaded on GPU!');
    } catch (e) {
      debugPrint('GPU load failed: $e. Falling back to CPU...');
      _model = await FlutterGemma.getActiveModel(
        maxTokens: 1024,
        preferredBackend: PreferredBackend.cpu,
      );
      debugPrint('Loaded on CPU (this will be slow).');
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
    if (!await isModelInstalled()) {
      throw const QuizGenerationException(
        'The quiz model is not downloaded yet. Tap "Download Model" first.',
      );
    }
    final model = await _ensureModel();
    final chat = await model.createChat(
      systemInstruction:
          'You are a quiz generator. Respond ONLY with a valid JSON object. '
          'Do not include introductory or concluding text.',
      maxOutputTokens: 1024,
    );

    final prompt = '''
Generate a multiple-choice quiz about $topic.
Difficulty: $difficulty
Number of questions: $questionCount

You MUST respond with ONLY a single JSON object in this exact format:
```json
{
  "topic": "$topic",
  "questions": [
    {
      "question": "question text here",
      "options": ["A", "B", "C", "D"],
      "answer": 0,
      "explanation": "concise explanation here"
    }
  ]
}
```
Rules:
- Exactly $questionCount questions.
- Every question has exactly 4 options.
- "answer" must be the 0-based index (0..3) of the correct option.
- Output ONLY valid JSON.''';

    try {
      await chat.addQueryChunk(Message.text(text: prompt, isUser: true));
      final stream = chat.generateChatResponseAsync();

      String accumulatedText = '';
      Quiz? parsedQuiz;

      await for (final response in stream) {
        final textChunk = switch (response) {
          TextResponse(:final token) => token,
          _ => '',
        };
        accumulatedText += textChunk;

        // Try to parse early if we see a closing brace
        if (textChunk.contains('}')) {
          parsedQuiz = Quiz.tryParseJson(accumulatedText);
          if (parsedQuiz != null && parsedQuiz.questions.length == questionCount) {
            break; // We have our valid quiz, stop generating to save time!
          }
        }
      }

      if (parsedQuiz == null) {
        parsedQuiz = Quiz.tryParseJson(accumulatedText);
      }

      if (parsedQuiz == null) {
        throw const QuizGenerationException(
          'The model did not return valid quiz JSON. Please try again.',
        );
      }
      return parsedQuiz;
    } finally {
      await chat.close();
    }
  }
}

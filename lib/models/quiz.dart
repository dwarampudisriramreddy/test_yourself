import 'dart:convert';

/// A parsed quiz returned by the on-device model.
class Quiz {
  final String topic;
  final List<QuizQuestion> questions;

  const Quiz({required this.topic, required this.questions});

  factory Quiz.fromJson(Map<String, dynamic> json) {
    final questions = <QuizQuestion>[];
    final rawQuestions = json['questions'];
    if (rawQuestions is List) {
      for (final item in rawQuestions) {
        if (item is Map<String, dynamic>) {
          final parsed = QuizQuestion.tryParse(item);
          if (parsed != null) questions.add(parsed);
        }
      }
    }
    return Quiz(
      topic: (json['topic'] as String?)?.trim().isNotEmpty == true
          ? (json['topic'] as String).trim()
          : 'Quiz',
      questions: questions,
    );
  }

  /// Parses the model output into a [Quiz], tolerating code fences, prose,
  /// and trailing junk that small on-device models sometimes emit.
  static Quiz? tryParseJson(String raw) {
    final object = extractJsonObject(raw);
    if (object == null) return null;
    try {
      final quiz = Quiz.fromJson(object);
      return quiz.questions.isEmpty ? null : quiz;
    } catch (_) {
      return null;
    }
  }

  /// Returns the first JSON object found in [raw], or null if there is none.
  static Map<String, dynamic>? extractJsonObject(String raw) {
    final fenceMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(raw);
    final candidate = fenceMatch?.group(1) ?? raw;

    final start = candidate.indexOf('{');
    final end = candidate.lastIndexOf('}');
    if (start == -1 || end <= start) return null;

    final slice = candidate.substring(start, end + 1);
    try {
      final decoded = jsonDecode(slice);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int answer;
  final String explanation;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.answer,
    required this.explanation,
  });

  static QuizQuestion? tryParse(Map<String, dynamic> json) {
    final question = (json['question'] as String?)?.trim();
    if (question == null || question.isEmpty) return null;

    final rawOptions = json['options'];
    final options = <String>[];
    if (rawOptions is List) {
      for (final item in rawOptions) {
        if (item is String && item.trim().isNotEmpty) {
          options.add(item.trim());
        }
      }
    }
    if (options.length < 2) return null;

    final answer = _parseAnswer(json['answer'], options.length);
    if (answer == null) return null;

    return QuizQuestion(
      question: question,
      options: options,
      answer: answer,
      explanation: (json['explanation'] as String?)?.trim() ?? '',
    );
  }

  static int? _parseAnswer(dynamic value, int optionCount) {
    if (value is int) {
      return value >= 0 && value < optionCount ? value : null;
    }
    if (value is double && value == value.roundToDouble()) {
      final asInt = value.toInt();
      return asInt >= 0 && asInt < optionCount ? asInt : null;
    }
    if (value is String) {
      final v = value.trim().toUpperCase();
      final int? numeric = int.tryParse(v);
      if (numeric != null) {
        return numeric >= 0 && numeric < optionCount ? numeric : null;
      }
      if (v.length == 1 && v.codeUnitAt(0) >= 65 && v.codeUnitAt(0) < 65 + optionCount) {
        return v.codeUnitAt(0) - 65;
      }
    }
    return null;
  }
}

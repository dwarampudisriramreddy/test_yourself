import 'package:flutter/material.dart';

import '../models/quiz.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  final Quiz quiz;

  const QuizScreen({super.key, required this.quiz});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _index = 0;
  int? _selected;
  int _score = 0;

  Quiz get _quiz => widget.quiz;
  QuizQuestion get _question => _quiz.questions[_index];

  bool get _answered => _selected != null;

  void _select(int optionIndex) {
    if (_answered) return;
    setState(() {
      _selected = optionIndex;
      if (optionIndex == _question.answer) _score++;
    });
  }

  void _next() {
    if (_index + 1 >= _quiz.questions.length) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            topic: _quiz.topic,
            score: _score,
            total: _quiz.questions.length,
          ),
        ),
      );
      return;
    }
    setState(() {
      _index++;
      _selected = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _quiz.questions.length;
    final progress = (_index + (_answered ? 1 : 0)) / total;

    return Scaffold(
      appBar: AppBar(
        title: Text(_quiz.topic),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Question ${_index + 1} / $total',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: progress, minHeight: 8),
              ),
              const SizedBox(height: 24),
              Text(
                _question.question,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: _question.options.length,
                  itemBuilder: (context, i) => _buildOption(context, i),
                ),
              ),
              if (_answered) ...[
                const SizedBox(height: 12),
                _buildExplanation(context),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _index + 1 >= total ? 'SEE RESULTS' : 'NEXT →',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, int i) {
    final theme = Theme.of(context);
    final correct = _question.answer == i;
    final selected = _selected == i;

    Color? background;
    Color? borderColor;
    IconData? trailing;

    if (_answered) {
      if (correct) {
        background = Colors.green.withValues(alpha: 0.15);
        borderColor = Colors.green;
        trailing = Icons.check_circle;
      } else if (selected) {
        background = Colors.red.withValues(alpha: 0.12);
        borderColor = Colors.red;
        trailing = Icons.cancel;
      }
    }

    return Card(
      color: background,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: borderColor ?? theme.colorScheme.outlineVariant,
          width: selected || (borderColor != null) ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _select(i),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: _answered && correct
                    ? Colors.green
                    : selected
                        ? Colors.red
                        : theme.colorScheme.primaryContainer,
                child: Text(
                  String.fromCharCode(65 + i),
                  style: TextStyle(
                    color: (_answered && correct) || selected
                        ? Colors.white
                        : theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _question.options[i],
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              if (trailing != null) Icon(trailing, color: borderColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExplanation(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _question.explanation.isEmpty
                  ? 'No explanation provided.'
                  : _question.explanation,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

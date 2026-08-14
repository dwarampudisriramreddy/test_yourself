import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final String topic;
  final int score;
  final int total;

  const ResultScreen({
    super.key,
    required this.topic,
    required this.score,
    required this.total,
  });

  double get _percent => total == 0 ? 0 : score / total;

  String get _message {
    final p = _percent;
    if (p >= 0.9) return 'Excellent!';
    if (p >= 0.7) return 'Great job!';
    if (p >= 0.5) return 'Not bad — keep practicing.';
    return 'Keep studying, you will get there.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(topic),
        backgroundColor: theme.colorScheme.inversePrimary,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                _percent >= 0.7 ? Icons.emoji_events : Icons.school,
                size: 72,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'QUIZ COMPLETE',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              Text(
                '$score / $total',
                textAlign: TextAlign.center,
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _percent,
                  minHeight: 12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(_percent * 100).round()}%',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                icon: const Icon(Icons.restart_alt),
                label: const Text('RESTART'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

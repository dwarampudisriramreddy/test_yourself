import 'package:flutter/material.dart';

import '../models/quiz.dart';
import '../services/quiz_generator.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _ModelStatus { checking, notInstalled, installing, installed }

class _HomeScreenState extends State<HomeScreen> {
  final _topicController = TextEditingController();
  _ModelStatus _status = _ModelStatus.checking;
  double _downloadProgress = 0;
  bool _generating = false;

  int _questionCount = 10;
  String _difficulty = 'Medium';

  static const _counts = [5, 10, 15, 20];
  static const _difficulties = ['Easy', 'Medium', 'Hard'];

  @override
  void initState() {
    super.initState();
    _checkModel();
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _checkModel() async {
    final installed = await QuizGenerator.isModelInstalled();
    if (!mounted) return;
    setState(() {
      _status = installed ? _ModelStatus.installed : _ModelStatus.notInstalled;
    });
  }

  Future<void> _downloadModel() async {
    setState(() {
      _status = _ModelStatus.installing;
      _downloadProgress = 0;
    });
    try {
      await QuizGenerator.installModel(
        onProgress: (progress) {
          if (!mounted) return;
          setState(() => _downloadProgress = progress / 100);
        },
      );
      if (!mounted) return;
      setState(() => _status = _ModelStatus.installed);
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = _ModelStatus.notInstalled);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Model download failed: $e')),
      );
    }
  }

  Future<void> _generateQuiz() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a topic first.')),
      );
      return;
    }
    setState(() => _generating = true);
    try {
      final Quiz quiz = await QuizGenerator.generateQuiz(
        topic: topic,
        questionCount: _questionCount,
        difficulty: _difficulty,
      );
      if (!mounted) return;
      final answer = await Navigator.of(context).push<Object?>(
        MaterialPageRoute(builder: (_) => QuizScreen(quiz: quiz)),
      );
      if (answer == true && mounted) {
        setState(() {});
      }
    } on QuizGenerationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Generation failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Quiz'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildModelCard(context),
              const SizedBox(height: 24),
              const Text(
                'Enter a topic',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _topicController,
                enabled: _status == _ModelStatus.installed && !_generating,
                decoration: const InputDecoration(
                  hintText: 'e.g. Dental anatomy',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit_note),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _generateQuiz(),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _DropdownField<String>(
                      label: 'Difficulty',
                      value: _difficulty,
                      items: _difficulties,
                      onChanged: (v) => setState(() => _difficulty = v),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _DropdownField<int>(
                      label: 'Questions',
                      value: _questionCount,
                      items: _counts,
                      onChanged: (v) => setState(() => _questionCount = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: (_status == _ModelStatus.installed && !_generating)
                    ? _generateQuiz
                    : null,
                icon: _generating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  _generating
                      ? 'Generating quiz…'
                      : 'GENERATE QUIZ',
                  style: const TextStyle(fontSize: 16),
                ),
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

  Widget _buildModelCard(BuildContext context) {
    final theme = Theme.of(context);

    final (icon, title, subtitle, action) = switch (_status) {
      _ModelStatus.checking => (
          Icons.settings,
          'Checking on-device model…',
          'Looking for Gemma 3 1B IT',
          null,
        ),
      _ModelStatus.notInstalled => (
          Icons.download_for_offline_outlined,
          'Model not installed',
          'Download Gemma 3 1B (~0.5 GB, one time)',
          'Download',
        ),
      _ModelStatus.installing => (
          Icons.downloading,
          'Downloading model…',
          '${(_downloadProgress * 100).toStringAsFixed(0)}%',
          null,
        ),
      _ModelStatus.installed => (
          Icons.offline_pin,
          'Model ready — 100% offline',
          'Gemma 3 1B IT generates quizzes on-device',
          null,
        ),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 36, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  if (_status == _ModelStatus.installing)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _downloadProgress,
                          minHeight: 6,
                        ),
                      ),
                    )
                  else
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (action != null)
              TextButton(
                onPressed: _status == _ModelStatus.installing
                    ? null
                    : _downloadModel,
                child: const Text('Download'),
              ),
          ],
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          isExpanded: true,
          items: [
            for (final item in items)
              DropdownMenuItem(value: item, child: Text('$item')),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

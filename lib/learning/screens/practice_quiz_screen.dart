import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/learning_models.dart';
import '../services/progress_service.dart';

/// Per-lesson practice quiz: one question at a time, instant right /
/// wrong with the explanation, final score + full review, retakes
/// allowed. NO timer — this is practice, not an exam.
class PracticeQuizController extends GetxController {
  final ProgressService _progress = ProgressService.instance;

  late final Lesson lesson;

  final index = 0.obs;
  final selected = (-1).obs; // -1 = nothing tapped yet
  final finished = false.obs;
  final chosen = <int>[].obs; // chosen option per question
  final best = RxnInt();

  LessonMcq get current => lesson.mcqs[index.value];
  bool get answered => selected.value >= 0;

  int get score {
    var s = 0;
    for (var i = 0; i < chosen.length; i++) {
      if (chosen[i] == lesson.mcqs[i].correctIndex) s++;
    }
    return s;
  }

  @override
  void onInit() {
    super.onInit();
    lesson = Get.arguments as Lesson;
    _loadBest();
  }

  Future<void> _loadBest() async {
    best.value = await _progress.bestScore(lesson.id);
  }

  void choose(int option) {
    if (answered || finished.value) return;
    selected.value = option;
    chosen.add(option);
  }

  Future<void> next() async {
    if (!answered) return;
    if (index.value >= lesson.mcqs.length - 1) {
      finished.value = true;
      best.value = await _progress.saveBestScore(lesson.id, score);
      // Finishing the practice quiz completes the lesson too.
      await _progress.setDone(lesson.id, true);
    } else {
      index.value++;
      selected.value = -1;
    }
  }

  void retake() {
    index.value = 0;
    selected.value = -1;
    chosen.clear();
    finished.value = false;
  }
}

class PracticeQuizScreen extends GetView<PracticeQuizController> {
  const PracticeQuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Practice — Lesson ${controller.lesson.number}'),
      ),
      body: Obx(() {
        if (controller.finished.value) return _resultView(context);
        return _questionView(context);
      }),
    );
  }

  Widget _questionView(BuildContext context) {
    final theme = Theme.of(context);
    final mcq = controller.current;
    final total = controller.lesson.mcqs.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              'Sawal ${controller.index.value + 1} / $total',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            if (controller.best.value != null)
              Text(
                'Best: ${controller.best.value}/$total',
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (controller.index.value + 1) / total,
          minHeight: 7,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 20),
        Text(
          mcq.question,
          style: theme.textTheme.titleLarge?.copyWith(height: 1.35),
        ),
        const SizedBox(height: 18),
        for (var i = 0; i < mcq.options.length; i++)
          _optionTile(context, mcq, i),
        if (controller.answered) ...<Widget>[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  controller.selected.value == mcq.correctIndex
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: controller.selected.value == mcq.correctIndex
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    mcq.explanation,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: controller.next,
            child: Text(
              controller.index.value >= total - 1
                  ? 'Result dekho'
                  : 'Agla sawal',
            ),
          ),
        ],
      ],
    );
  }

  Widget _optionTile(BuildContext context, LessonMcq mcq, int i) {
    final theme = Theme.of(context);
    final answered = controller.answered;
    final isCorrect = i == mcq.correctIndex;
    final isChosen = i == controller.selected.value;
    Color? bg;
    if (answered && isCorrect) {
      bg = Colors.green.shade100;
    } else if (answered && isChosen) {
      bg = Colors.red.shade100;
    }
    return Card(
      color: bg,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          radius: 15,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            'ABCD'[i],
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        title: Text(mcq.options[i], style: const TextStyle(fontSize: 16)),
        trailing: answered && isCorrect
            ? Icon(Icons.check_circle, color: Colors.green.shade700)
            : answered && isChosen
                ? Icon(Icons.cancel, color: Colors.red.shade700)
                : null,
        onTap: () => controller.choose(i),
      ),
    );
  }

  Widget _resultView(BuildContext context) {
    final theme = Theme.of(context);
    final total = controller.lesson.mcqs.length;
    final score = controller.score;
    final pct = total == 0 ? 0 : (score * 100 / total).round();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: <Widget>[
        Icon(
          pct >= 70 ? Icons.emoji_events : Icons.school,
          size: 56,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 10),
        Text(
          '$score / $total',
          textAlign: TextAlign.center,
          style: theme.textTheme.displaySmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          '$pct% — ${controller.lesson.title}',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        if (controller.best.value != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Best score: ${controller.best.value}/$total',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        const SizedBox(height: 20),
        Text(
          'Review — har sawal ka sahi jawab',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < total; i++) _reviewCard(context, i),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: controller.retake,
          icon: const Icon(Icons.replay),
          label: const Text('Dobara practice karo'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => Get.back<void>(),
          child: const Text('Wapas lesson par'),
        ),
      ],
    );
  }

  Widget _reviewCard(BuildContext context, int i) {
    final theme = Theme.of(context);
    final mcq = controller.lesson.mcqs[i];
    final mine = i < controller.chosen.length ? controller.chosen[i] : -1;
    final right = mine == mcq.correctIndex;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  right ? Icons.check_circle : Icons.cancel,
                  color: right ? Colors.green.shade700 : Colors.red.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${i + 1}. ${mcq.question}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Sahi jawab: ${'ABCD'[mcq.correctIndex]}. '
              '${mcq.options[mcq.correctIndex]}',
              style: TextStyle(color: Colors.green.shade800, height: 1.4),
            ),
            if (!right && mine >= 0)
              Text(
                'Tumhara jawab: ${'ABCD'[mine]}. ${mcq.options[mine]}',
                style: TextStyle(color: Colors.red.shade800, height: 1.4),
              ),
            const SizedBox(height: 4),
            Text(
              mcq.explanation,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

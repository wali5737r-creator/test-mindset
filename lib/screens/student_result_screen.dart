import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/attempt.dart';
import '../models/question.dart';
import '../models/quiz_test.dart';
import '../routes/app_routes.dart';
import '../utils/format.dart';
import '../widgets/question_review_card.dart';

/// The student's instant result: score card + full answer review.
/// Arguments: {'test': TestModel, 'attempt': Attempt, 'questions': List<Question>}.
class StudentResultScreen extends StatelessWidget {
  const StudentResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    if (args is! Map ||
        args['test'] is! TestModel ||
        args['attempt'] is! Attempt) {
      return Scaffold(
        appBar: AppBar(title: const Text('Result')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'No result to show. If you just finished a test, '
                  'please do not refresh this page.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => Get.offAllNamed(AppRoutes.home),
                  child: const Text('Go to Home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final test = args['test'] as TestModel;
    final attempt = args['attempt'] as Attempt;
    final questions = (args['questions'] as List?)?.cast<Question>() ??
        const <Question>[];
    final byId = <String, Question>{for (final q in questions) q.id: q};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Result'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _scoreCard(context, test, attempt),
          const SizedBox(height: 18),
          Text(
            'Review Answers',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < attempt.answers.length; i++)
            if (byId[attempt.questionIds[i]] != null)
              QuestionReviewCard(
                number: i + 1,
                question: byId[attempt.questionIds[i]]!,
                selectedIndex: attempt.answers[i],
              ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => Get.offAllNamed(AppRoutes.home),
            icon: const Icon(Icons.home),
            label: const Text('Back to Home'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _scoreCard(BuildContext context, TestModel test, Attempt attempt) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Text(test.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(attempt.studentName, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 14),
            Text(
              '${attempt.percent.toStringAsFixed(1)}%',
              style: theme.textTheme.displaySmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Score: ${formatScore(attempt.score)} / '
              '${formatScore(attempt.total)}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _chip(Icons.check_circle, 'Correct: ${attempt.correct}',
                    Colors.green),
                _chip(Icons.cancel, 'Wrong: ${attempt.wrong}', Colors.red),
                _chip(Icons.help_outline, 'Skipped: ${attempt.skipped}',
                    Colors.grey),
                _chip(Icons.timer_outlined,
                    'Time: ${formatTimeUsed(attempt.timeUsedSec)}',
                    Colors.blueGrey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

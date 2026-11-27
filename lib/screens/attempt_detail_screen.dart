import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/attempt.dart';
import '../models/question.dart';
import '../models/quiz_test.dart';
import '../services/test_service.dart';
import '../utils/format.dart';
import '../widgets/question_review_card.dart';

/// Teacher's per-question review of one student's attempt.
/// Arguments: {'test': TestModel, 'attempt': Attempt}.
class AttemptDetailScreen extends StatelessWidget {
  const AttemptDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    if (args is! Map ||
        args['test'] is! TestModel ||
        args['attempt'] is! Attempt) {
      return Scaffold(
        appBar: AppBar(title: const Text('Attempt')),
        body: const Center(child: Text('Nothing to show.')),
      );
    }
    final test = args['test'] as TestModel;
    final attempt = args['attempt'] as Attempt;

    return Scaffold(
      appBar: AppBar(title: Text(attempt.studentName)),
      body: FutureBuilder<List<Question>>(
        future: Get.find<TestService>().fetchQuestionsWithAnswersOnce(test.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final questions = snapshot.data ?? const <Question>[];
          final byId = <String, Question>{
            for (final q in questions) q.id: q,
          };
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _summaryCard(context, attempt),
              const SizedBox(height: 16),
              for (var i = 0; i < attempt.answers.length; i++)
                if (byId[attempt.questionIds[i]] != null)
                  QuestionReviewCard(
                    number: i + 1,
                    question: byId[attempt.questionIds[i]]!,
                    selectedIndex: attempt.answers[i],
                  )
                else
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: Text('Question ${i + 1}'),
                      subtitle: const Text(
                        'This question was deleted from the test after '
                        'the student submitted.',
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryCard(BuildContext context, Attempt attempt) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              attempt.studentName,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (attempt.roll.isNotEmpty) Text('Roll / ID: ${attempt.roll}'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                Text(
                  'Score: ${formatScore(attempt.score)} / '
                  '${formatScore(attempt.total)}',
                ),
                Text('Percent: ${attempt.percent.toStringAsFixed(1)}%'),
                Text('Correct: ${attempt.correct}'),
                Text('Wrong: ${attempt.wrong}'),
                Text('Skipped: ${attempt.skipped}'),
                Text('Time: ${formatTimeUsed(attempt.timeUsedSec)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

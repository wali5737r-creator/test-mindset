import 'package:flutter/material.dart';

import '../models/question.dart';

/// Read-only review of one answered question, used by the student's result
/// screen and the teacher's attempt-detail screen.
///
/// Shows every option: the correct one in green, the student's wrong pick
/// in red, and the explanation (when the teacher wrote one).
class QuestionReviewCard extends StatelessWidget {
  /// 1-based question number for display.
  final int number;
  final Question question;

  /// The option the student picked; -1 = skipped.
  final int selectedIndex;

  const QuestionReviewCard({
    super.key,
    required this.number,
    required this.question,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCorrect = selectedIndex == question.correctIndex;
    final isSkipped = selectedIndex == -1;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Q$number. ${question.text}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                _statusChip(context, isSkipped, isCorrect),
              ],
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < question.options.length; i++)
              _optionRow(context, i),
            if (question.explanation.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Explanation: ${question.explanation}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusChip(BuildContext context, bool isSkipped, bool isCorrect) {
    final String label;
    final Color color;
    if (isSkipped) {
      label = 'Skipped';
      color = Colors.grey;
    } else if (isCorrect) {
      label = 'Correct';
      color = Colors.green;
    } else {
      label = 'Wrong';
      color = Colors.red;
    }
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }

  Widget _optionRow(BuildContext context, int index) {
    final theme = Theme.of(context);
    final isCorrectOption = index == question.correctIndex;
    final isPicked = index == selectedIndex;

    Color? background;
    IconData? icon;
    Color iconColor = Colors.grey;
    if (isCorrectOption) {
      background = Colors.green.withValues(alpha: 0.12);
      icon = Icons.check_circle;
      iconColor = Colors.green;
    } else if (isPicked) {
      background = Colors.red.withValues(alpha: 0.12);
      icon = Icons.cancel;
      iconColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCorrectOption
              ? Colors.green
              : (isPicked ? Colors.red : theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${'ABCD'[index]}. ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(question.options[index])),
          if (icon != null) Icon(icon, size: 18, color: iconColor),
          if (isPicked && !isCorrectOption)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                'Your answer',
                style: TextStyle(fontSize: 11, color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
}

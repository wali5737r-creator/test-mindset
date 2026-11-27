import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/results_controller.dart';
import '../models/attempt.dart';
import '../routes/app_routes.dart';
import '../utils/format.dart';

/// Teacher results for one test: every student's attempt, with export
/// CSV, clear-all and per-attempt delete. Tap an attempt for its
/// per-question review.
class TeacherResultsScreen extends GetView<ResultsController> {
  const TeacherResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Results - ${controller.test.title}'),
        actions: [
          Obx(
            () => IconButton(
              icon: controller.isExporting.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Icons.download),
              tooltip: 'Export CSV',
              onPressed: controller.attempts.isEmpty || controller.isExporting.value
                  ? null
                  : controller.exportCsv,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear all results',
            onPressed: () {
              if (controller.attempts.isEmpty) {
                Get.snackbar('Nothing to clear', 'There are no results yet.');
                return;
              }
              _confirmClearAll();
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.attempts.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No results yet.\nShare the test link with your students - '
                'their results will appear here.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: controller.attempts.length,
          itemBuilder: (context, index) {
            final attempt = controller.attempts[index];
            return _AttemptTile(attempt: attempt, controller: controller);
          },
        );
      }),
    );
  }

  void _confirmClearAll() {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear all results?'),
        content: const Text(
          'Every student result for this test will be deleted. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Get.back();
              controller.clearAll();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

class _AttemptTile extends StatelessWidget {
  final Attempt attempt;
  final ResultsController controller;

  const _AttemptTile({required this.attempt, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateText = attempt.submittedAt == null
        ? ''
        : DateFormat('dd MMM yyyy, hh:mm a').format(attempt.submittedAt!);
    final rollText = attempt.roll.isEmpty ? '' : 'Roll: ${attempt.roll}  •  ';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          attempt.studentName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '$rollText$dateText\n'
          'Time used: ${formatTimeUsed(attempt.timeUsedSec)}',
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${attempt.percent.toStringAsFixed(1)}%',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${formatScore(attempt.score)}/${formatScore(attempt.total)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete result',
              onPressed: () => _confirmDelete(),
            ),
          ],
        ),
        onTap: () => Get.toNamed(
          AppRoutes.attemptDetail,
          arguments: <String, dynamic>{
            'test': controller.test,
            'attempt': attempt,
          },
        ),
      ),
    );
  }

  void _confirmDelete() {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete this result?'),
        content: Text(
          'The result of ${attempt.studentName} will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Get.back();
              controller.deleteAttempt(attempt);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

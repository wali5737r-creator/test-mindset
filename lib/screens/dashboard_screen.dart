import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../models/quiz_test.dart';
import '../routes/app_routes.dart';

/// Teacher dashboard: "My Tests".
class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => Get.find<AuthController>().logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.testEditor),
        icon: const Icon(Icons.add),
        label: const Text('New Test'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.tests.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'No tests yet.\nTap "New Test" to create your first test.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
          itemCount: controller.tests.length,
          itemBuilder: (context, index) {
            final test = controller.tests[index];
            final attempts = controller.attemptCounts[test.id] ?? 0;
            return _TestCard(
              test: test,
              attempts: attempts,
              controller: controller,
            );
          },
        );
      }),
    );
  }
}

class _TestCard extends StatelessWidget {
  final TestModel test;
  final int attempts;
  final DashboardController controller;

  const _TestCard({
    required this.test,
    required this.attempts,
    required this.controller,
  });

  Color get _statusColor {
    switch (test.status) {
      case TestStatus.published:
        return Colors.green;
      case TestStatus.closed:
        return Colors.red;
      case TestStatus.draft:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateText = test.createdAt == null
        ? ''
        : '  •  ${DateFormat('dd MMM yyyy').format(test.createdAt!)}';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Get.toNamed(
          AppRoutes.questionList,
          arguments: <String, dynamic>{'test': test},
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      test.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${test.questionCount} questions  •  '
                      '$attempts attempts$dateText',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Chip(
                          label: Text(
                            test.status.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor: _statusColor,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(
                            'Code: ${test.code}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _onAction(context, value),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit Settings')),
                  PopupMenuItem(value: 'questions', child: Text('Questions')),
                  PopupMenuItem(value: 'share', child: Text('Share')),
                  PopupMenuItem(value: 'results', child: Text('Results')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        Get.toNamed(
          AppRoutes.testEditor,
          arguments: <String, dynamic>{'test': test},
        );
        break;
      case 'questions':
        Get.toNamed(
          AppRoutes.questionList,
          arguments: <String, dynamic>{'test': test},
        );
        break;
      case 'share':
        Get.toNamed(
          AppRoutes.share,
          arguments: <String, dynamic>{'test': test},
        );
        break;
      case 'results':
        Get.toNamed(
          AppRoutes.results,
          arguments: <String, dynamic>{'test': test},
        );
        break;
      case 'delete':
        Get.dialog(
          AlertDialog(
            title: const Text('Delete this test?'),
            content: Text(
              '"${test.title}" and all its questions and results will be '
              'deleted. This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Get.back();
                  controller.deleteTest(test);
                },
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        break;
    }
  }
}

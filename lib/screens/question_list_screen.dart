import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/app_config.dart';
import '../controllers/question_editor_controller.dart';
import '../models/question.dart';
import '../routes/app_routes.dart';

/// All questions of one test, with add / edit / delete and CSV import.
class QuestionListScreen extends GetView<QuestionEditorController> {
  const QuestionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.test.title),
        actions: [
          Obx(
            () => IconButton(
              icon: controller.isImporting.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Icons.upload_file),
              tooltip: 'Import CSV',
              onPressed: controller.isImporting.value
                  ? null
                  : controller.importCsvFromFile,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share test',
            onPressed: () => Get.toNamed(
              AppRoutes.share,
              arguments: <String, dynamic>{'test': controller.test},
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Results',
            onPressed: () => Get.toNamed(
              AppRoutes.results,
              arguments: <String, dynamic>{'test': controller.test},
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (!controller.canAddMore) {
            Get.snackbar(
              'Test is full',
              'A test can have at most '
                  '${AppConfig.maxQuestionsPerTest} questions.',
            );
            return;
          }
          Get.toNamed(
            AppRoutes.questionEditor,
            arguments: <String, dynamic>{
              'test': controller.test,
              'nextOrder': controller.nextOrder,
            },
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Question'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Text(
                '${controller.questions.length} / '
                '${AppConfig.maxQuestionsPerTest} questions',
              ),
            ),
            Expanded(
              child: controller.questions.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No questions yet.\nTap "Add Question", or import '
                          'a CSV file from the top-right button.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                      itemCount: controller.questions.length,
                      itemBuilder: (context, index) {
                        final question = controller.questions[index];
                        return _QuestionTile(
                          index: index,
                          question: question,
                          controller: controller,
                        );
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }
}

class _QuestionTile extends StatelessWidget {
  final int index;
  final Question question;
  final QuestionEditorController controller;

  const _QuestionTile({
    required this.index,
    required this.question,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Text('${index + 1}')),
        title: Text(
          question.text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          question.correctIndex >= 0 && question.correctIndex < 4
              ? 'Answer: ${'ABCD'[question.correctIndex]}. '
                  '${question.correctOptionText}'
              : 'Answer not loaded',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.green.shade700),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete question',
          onPressed: () => _confirmDelete(context),
        ),
        onTap: () => Get.toNamed(
          AppRoutes.questionEditor,
          arguments: <String, dynamic>{
            'test': controller.test,
            'question': question,
          },
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete this question?'),
        content: Text(
          question.text,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Get.back();
              controller.deleteQuestion(question);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

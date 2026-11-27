import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/test_editor_controller.dart';
import '../models/quiz_test.dart';
import '../widgets/loading_button.dart';

/// Create / edit a test's settings: title, description, duration,
/// marks, negative marks, shuffle, status.
class TestEditorScreen extends GetView<TestEditorController> {
  const TestEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.isEditing ? 'Edit Test' : 'New Test'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: controller.titleController,
                    decoration: const InputDecoration(
                      labelText: 'Test Title *',
                      hintText: 'e.g. PPSC General Knowledge Test 1',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller.descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      hintText: 'Shown to students before the test starts.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller.durationController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Duration (minutes) *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: controller.marksController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Marks per question *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller.negativeController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Negative marks per wrong answer',
                      hintText: '0 means no negative marking',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(
                    () => SwitchListTile(
                      title: const Text('Shuffle questions'),
                      subtitle: const Text(
                        'Every student sees the questions in a different order.',
                      ),
                      value: controller.shuffle.value,
                      onChanged: (v) => controller.shuffle.value = v,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Obx(
                    () => Wrap(
                      spacing: 8,
                      children: [
                        for (final status in TestStatus.values)
                          ChoiceChip(
                            label: Text(status.label),
                            selected: controller.status.value == status,
                            onSelected: (_) =>
                                controller.status.value = status,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Draft: only you can see it. Published: students can take '
                    'it. Closed: students can no longer take it.',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  Obx(
                    () => LoadingButton(
                      label: controller.isEditing ? 'Save Changes' : 'Create Test',
                      icon: Icons.save,
                      loading: controller.isSaving.value,
                      onPressed: controller.save,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

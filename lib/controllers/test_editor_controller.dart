import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/quiz_test.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../services/test_service.dart';

/// Backs the create/edit test settings form.
///
/// Arguments: {'test': TestModel} when editing, nothing when creating.
class TestEditorController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();
  final TestService _testService = Get.find<TestService>();

  /// The test being edited, or null when creating a new one.
  TestModel? existing;

  bool get isEditing => existing != null;

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final durationController = TextEditingController(text: '30');
  final marksController = TextEditingController(text: '1');
  final negativeController = TextEditingController(text: '0');

  final shuffle = false.obs;
  final showAnswers = true.obs;
  final status = TestStatus.draft.obs;
  final isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['test'] is TestModel) {
      final test = args['test'] as TestModel;
      existing = test;
      titleController.text = test.title;
      descriptionController.text = test.description;
      durationController.text = test.durationMin.toString();
      marksController.text = _plainNumber(test.marksPerQuestion);
      negativeController.text = _plainNumber(test.negativeMarks);
      shuffle.value = test.shuffle;
      showAnswers.value = test.showAnswers;
      status.value = test.status;
    }
  }

  static String _plainNumber(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  Future<void> save() async {
    if (isSaving.value) return;

    final title = titleController.text.trim();
    if (title.isEmpty) {
      Get.snackbar('Title needed', 'Please enter a test title.');
      return;
    }
    final duration = int.tryParse(durationController.text.trim());
    if (duration == null || duration < 1 || duration > 600) {
      Get.snackbar(
        'Check duration',
        'Duration must be a whole number of minutes (1 to 600).',
      );
      return;
    }
    final marks = double.tryParse(marksController.text.trim());
    if (marks == null || marks <= 0) {
      Get.snackbar(
        'Check marks',
        'Marks per question must be a number greater than 0.',
      );
      return;
    }
    final negative = double.tryParse(negativeController.text.trim());
    if (negative == null || negative < 0) {
      Get.snackbar(
        'Check negative marks',
        'Negative marks must be 0 or a positive number.',
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    isSaving.value = true;
    try {
      if (existing == null) {
        final created = await _testService.createTest(
          TestModel(
            id: '',
            ownerId: user.uid,
            code: '',
            title: title,
            description: descriptionController.text.trim(),
            durationMin: duration,
            marksPerQuestion: marks,
            negativeMarks: negative,
            shuffle: shuffle.value,
            showAnswers: showAnswers.value,
            status: status.value,
          ),
        );
        Get.snackbar('Test created', 'Now add questions to "${created.title}".');
        // Replace the editor with the question list for the new test.
        Get.offNamed(
          AppRoutes.questionList,
          arguments: <String, dynamic>{'test': created},
        );
      } else {
        final updated = existing!.copyWith(
          title: title,
          description: descriptionController.text.trim(),
          durationMin: duration,
          marksPerQuestion: marks,
          negativeMarks: negative,
          shuffle: shuffle.value,
          showAnswers: showAnswers.value,
          status: status.value,
        );
        await _testService.updateTest(updated);
        Get.snackbar('Saved', 'Test settings have been updated.');
        Get.back();
      }
    } catch (e) {
      Get.snackbar('Save failed', AuthService.friendlyError(e));
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    durationController.dispose();
    marksController.dispose();
    negativeController.dispose();
    super.onClose();
  }
}

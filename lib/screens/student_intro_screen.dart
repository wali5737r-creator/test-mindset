import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/quiz_test.dart';
import '../routes/app_routes.dart';
import '../services/test_service.dart';
import '../widgets/loading_button.dart';

/// Loads the test for the student link (/t/:code) and collects the
/// student's name (+ optional roll) before the test starts.
class StudentIntroController extends GetxController {
  final TestService _testService = Get.find<TestService>();

  final test = Rxn<TestModel>();
  final isLoading = true.obs;
  final error = ''.obs;

  final nameController = TextEditingController();
  final rollController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    final args = Get.arguments;
    if (args is Map && args['test'] is TestModel) {
      // Arrived from the home screen code entry - test already fetched.
      test.value = args['test'] as TestModel;
      isLoading.value = false;
      return;
    }
    // Arrived from a shared link: only the code is in the URL.
    final code = Get.parameters['code'] ?? '';
    if (code.isEmpty) {
      error.value = 'This link is incomplete. Please check the link.';
      isLoading.value = false;
      return;
    }
    try {
      final found = await _testService.findTestByCode(code);
      if (found == null) {
        error.value = 'No test exists with this code. '
            'Please check the link or ask your teacher.';
      } else if (found.status == TestStatus.draft) {
        error.value = 'Your teacher has not published this test yet.';
      } else if (found.status == TestStatus.closed) {
        error.value = 'This test is closed by the teacher.';
      } else {
        test.value = found;
      }
    } catch (e) {
      error.value = 'Could not load the test. Check your internet '
          'and try again.';
    } finally {
      isLoading.value = false;
    }
  }

  void start() {
    final current = test.value;
    if (current == null) return;
    final name = nameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar('Name needed', 'Please enter your name to start.');
      return;
    }
    if (current.questionCount <= 0) {
      Get.snackbar(
        'No questions yet',
        'This test has no questions yet. Please ask your teacher.',
      );
      return;
    }
    Get.toNamed(
      AppRoutes.takeTest,
      arguments: <String, dynamic>{
        'test': current,
        'name': name,
        'roll': rollController.text.trim(),
      },
    );
  }

  @override
  void onClose() {
    nameController.dispose();
    rollController.dispose();
    super.onClose();
  }
}

/// Student intro page: test summary + name/roll form.
class StudentIntroScreen extends GetView<StudentIntroController> {
  const StudentIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Details')),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.error.value.isNotEmpty) {
            return _message(context, Icons.error_outline, controller.error.value);
          }
          final test = controller.test.value;
          if (test == null) {
            return _message(
              context,
              Icons.search_off,
              'Test not found. Please check the link.',
            );
          }
          return _content(context, test);
        }),
      ),
    );
  }

  Widget _message(BuildContext context, IconData icon, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 14),
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Get.offAllNamed(AppRoutes.home),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, TestModel test) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                test.title,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              if (test.description.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(test.description, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _infoRow(
                        Icons.help_outline,
                        'Questions',
                        '${test.questionCount}',
                      ),
                      _infoRow(
                        Icons.timer_outlined,
                        'Time',
                        '${test.durationMin} minutes',
                      ),
                      _infoRow(
                        Icons.star_outline,
                        'Marks per question',
                        _plain(test.marksPerQuestion),
                      ),
                      _infoRow(
                        Icons.remove_circle_outline,
                        'Negative marking',
                        test.negativeMarks > 0
                            ? '-${_plain(test.negativeMarks)} per wrong answer'
                            : 'None',
                        last: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller.nameController,
                decoration: const InputDecoration(
                  labelText: 'Your Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller.rollController,
                decoration: const InputDecoration(
                  labelText: 'Roll No / ID (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                onSubmitted: (_) => controller.start(),
              ),
              const SizedBox(height: 20),
              LoadingButton(
                label: 'Start Test',
                icon: Icons.play_arrow,
                loading: false,
                onPressed: controller.start,
              ),
              const SizedBox(height: 10),
              const Text(
                'The timer starts as soon as you tap Start Test. '
                'The test submits itself when the time ends.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _plain(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  Widget _infoRow(IconData icon, String label, String value,
      {bool last = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/app_config.dart';
import '../models/quiz_test.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../services/test_service.dart';
import '../widgets/loading_button.dart';

/// Landing logic: students enter a test code here.
class HomeController extends GetxController {
  final TestService _testService = Get.find<TestService>();
  final AuthService _auth = Get.find<AuthService>();

  final codeController = TextEditingController();
  final isChecking = false.obs;

  bool get teacherLoggedIn => _auth.isLoggedIn;

  Future<void> startWithCode() async {
    if (isChecking.value) return;
    final code = codeController.text.trim().toUpperCase();
    if (code.length != AppConfig.testCodeLength) {
      Get.snackbar(
        'Check the code',
        'A test code has ${AppConfig.testCodeLength} characters.',
      );
      return;
    }
    isChecking.value = true;
    try {
      final test = await _testService.findTestByCode(code);
      if (test == null) {
        Get.snackbar(
          'Test not found',
          'No test exists with this code. Please check the code.',
        );
        return;
      }
      if (test.status == TestStatus.draft) {
        Get.snackbar(
          'Not available yet',
          'Your teacher has not published this test yet.',
        );
        return;
      }
      if (test.status == TestStatus.closed) {
        Get.snackbar('Test closed', 'This test is closed by the teacher.');
        return;
      }
      Get.toNamed(
        AppRoutes.studentIntroPath(test.code),
        arguments: <String, dynamic>{'test': test},
      );
    } catch (e) {
      Get.snackbar('Something went wrong', AuthService.friendlyError(e));
    } finally {
      isChecking.value = false;
    }
  }

  void goToTeacherArea() {
    if (teacherLoggedIn) {
      Get.toNamed(AppRoutes.dashboard);
    } else {
      Get.toNamed(AppRoutes.login);
    }
  }

  @override
  void onClose() {
    codeController.dispose();
    super.onClose();
  }
}

/// The landing page. Students join a test with a code - no login.
/// Teachers go to their dashboard / login from here.
class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.quiz, size: 72, color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    AppConfig.appName,
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    AppConfig.appTagline,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Students: enter your test code',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: controller.codeController,
                            textCapitalization: TextCapitalization.characters,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'ABC123',
                              hintStyle: TextStyle(letterSpacing: 4),
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => controller.startWithCode(),
                          ),
                          const SizedBox(height: 14),
                          Obx(
                            () => LoadingButton(
                              label: 'Start Test',
                              icon: Icons.play_arrow,
                              loading: controller.isChecking.value,
                              onPressed: controller.startWithCode,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'No account or login needed.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('Teachers'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: controller.goToTeacherArea,
                    icon: const Icon(Icons.school),
                    label: const Text('Teacher Login'),
                  ),
                  TextButton(
                    onPressed: () => Get.toNamed(AppRoutes.register),
                    child: const Text('Create a free teacher account'),
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

import 'dart:async';

import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../models/attempt.dart';
import '../models/quiz_test.dart';
import '../services/auth_service.dart';
import '../services/test_service.dart';

/// Backs the teacher results screen for one test: live attempts list,
/// delete one attempt, clear all, export CSV.
///
/// Arguments: {'test': TestModel}.
class ResultsController extends GetxController {
  final TestService _testService = Get.find<TestService>();

  TestModel? _test;
  TestModel get test => _test!;

  final attempts = <Attempt>[].obs;
  final isLoading = true.obs;
  final isExporting = false.obs;

  StreamSubscription<List<Attempt>>? _subscription;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['test'] is TestModel) {
      _test = args['test'] as TestModel;
      _subscription = _testService.attemptsStream(test.id).listen(
        (list) {
          attempts.assignAll(list);
          isLoading.value = false;
        },
        onError: (_) {
          isLoading.value = false;
        },
      );
    } else {
      isLoading.value = false;
    }
  }

  Future<void> deleteAttempt(Attempt attempt) async {
    try {
      await _testService.deleteAttempt(test.id, attempt.id);
      Get.snackbar('Deleted', 'Result of ${attempt.studentName} deleted.');
    } catch (e) {
      Get.snackbar('Delete failed', AuthService.friendlyError(e));
    }
  }

  Future<void> clearAll() async {
    try {
      await _testService.clearAttempts(test.id);
      Get.snackbar('Cleared', 'All results for this test have been deleted.');
    } catch (e) {
      Get.snackbar('Clear failed', AuthService.friendlyError(e));
    }
  }

  /// Builds the results CSV and opens the system share sheet with it.
  /// (Sharing as text keeps v1 dependency-light; saving straight to a
  /// .csv file is a v1.1 nicety - see BUILD_NOTES.md.)
  Future<void> exportCsv() async {
    if (isExporting.value || attempts.isEmpty) return;
    isExporting.value = true;
    try {
      final csv = _testService.buildAttemptsCsv(test, attempts);
      await SharePlus.instance.share(
        ShareParams(
          text: csv,
          subject: '${test.title} - Results',
        ),
      );
    } catch (e) {
      Get.snackbar('Export failed', AuthService.friendlyError(e));
    } finally {
      isExporting.value = false;
    }
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}

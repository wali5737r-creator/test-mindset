import 'dart:async';

import 'package:get/get.dart';

import '../models/quiz_test.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../services/test_service.dart';

/// Backs the teacher dashboard: the live list of my tests plus a cached
/// attempts count per test.
class DashboardController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();
  final TestService _testService = Get.find<TestService>();

  final tests = <TestModel>[].obs;
  final attemptCounts = <String, int>{}.obs;
  final isLoading = true.obs;

  StreamSubscription<List<TestModel>>? _subscription;

  @override
  void onInit() {
    super.onInit();
    final user = _auth.currentUser;
    if (user == null) {
      // The route middleware should already have redirected; stay safe.
      Get.offAllNamed(AppRoutes.login);
      return;
    }
    _subscription = _testService.myTestsStream(user.uid).listen(
      (list) {
        tests.assignAll(list);
        isLoading.value = false;
        _refreshAttemptCounts(list);
      },
      onError: (_) {
        isLoading.value = false;
      },
    );
  }

  Future<void> _refreshAttemptCounts(List<TestModel> list) async {
    for (final test in list) {
      final count = await _testService.attemptsCount(test.id);
      attemptCounts[test.id] = count;
    }
  }

  Future<void> deleteTest(TestModel test) async {
    try {
      await _testService.deleteTest(test.id);
      Get.snackbar('Deleted', 'Test "${test.title}" has been deleted.');
    } catch (e) {
      Get.snackbar('Delete failed', AuthService.friendlyError(e));
    }
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}

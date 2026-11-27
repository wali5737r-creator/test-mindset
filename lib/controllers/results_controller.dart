import 'dart:async';

import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../models/attempt.dart';
import '../models/question.dart';
import '../models/quiz_test.dart';
import '../services/auth_service.dart';
import '../services/test_service.dart';

/// One row of the class report's per-question breakdown.
class QuestionStat {
  final Question question;

  /// Students who picked an option for this question (skips excluded).
  final int attempted;

  /// Students who picked the correct option.
  final int correct;

  const QuestionStat({
    required this.question,
    required this.attempted,
    required this.correct,
  });

  /// Share of attempted answers that were correct, 0..1 (0 when nobody
  /// attempted the question).
  double get correctRatio => attempted == 0 ? 0 : correct / attempted;
}

/// Backs the teacher results screen for one test: live attempts list,
/// delete one attempt, clear all, export CSV, and the class report
/// (totals, average, highest scorer, per-question breakdown).
///
/// Arguments: {'test': TestModel}.
class ResultsController extends GetxController {
  final TestService _testService = Get.find<TestService>();

  TestModel? _test;
  TestModel get test => _test!;

  final attempts = <Attempt>[].obs;

  /// The test's questions WITH answers merged in (teacher flow), in test
  /// order. Loaded once for the class report's per-question breakdown.
  final reportQuestions = <Question>[].obs;

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
      _loadReportQuestions();
    } else {
      isLoading.value = false;
    }
  }

  Future<void> _loadReportQuestions() async {
    try {
      final questions =
          await _testService.fetchQuestionsWithAnswersOnce(test.id);
      reportQuestions.assignAll(questions);
    } catch (_) {
      // The breakdown simply stays hidden; the attempts list still works.
    }
  }

  // ---------------------------------------------------------------------------
  // Class report
  // ---------------------------------------------------------------------------

  int get totalAttempts => attempts.length;

  /// Mean of the attempts' display percents; 0 when there are none.
  double get averagePercent {
    if (attempts.isEmpty) return 0;
    var sum = 0.0;
    for (final a in attempts) {
      sum += a.percent;
    }
    return sum / attempts.length;
  }

  /// The highest-scoring attempt (by percent, then raw score), or null
  /// when there are no attempts yet.
  Attempt? get topAttempt {
    if (attempts.isEmpty) return null;
    var best = attempts.first;
    for (final a in attempts.skip(1)) {
      if (a.percent > best.percent ||
          (a.percent == best.percent && a.score > best.score)) {
        best = a;
      }
    }
    return best;
  }

  /// Per-question correct/attempted counts across all attempts, in the
  /// test's question order. An attempt counts toward a question when the
  /// question id appears in its stored questionIds (attempts taken
  /// before a question was added simply do not mention it).
  List<QuestionStat> get questionStats {
    final stats = <QuestionStat>[];
    for (final question in reportQuestions) {
      var attempted = 0;
      var correct = 0;
      for (final attempt in attempts) {
        final index = attempt.questionIds.indexOf(question.id);
        if (index < 0 || index >= attempt.answers.length) continue;
        final chosen = attempt.answers[index];
        if (chosen == -1) continue; // skipped: not attempted
        attempted++;
        if (chosen == question.correctIndex) correct++;
      }
      stats.add(QuestionStat(
        question: question,
        attempted: attempted,
        correct: correct,
      ));
    }
    return stats;
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

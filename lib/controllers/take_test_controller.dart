import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';

import '../models/attempt.dart';
import '../models/question.dart';
import '../models/question_answer.dart';
import '../models/quiz_test.dart';
import '../routes/app_routes.dart';
import '../services/test_service.dart';

/// Runs one student's attempt: loads the questions once, counts the timer
/// down, tracks answers for the palette, scores with negative marking and
/// saves the attempt on submit.
///
/// Arguments: {'test': TestModel, 'name': String, 'roll': String}.
///
/// v1.1 (SRS section 6 fix): the questions loaded at start are the PUBLIC
/// payload — no correct answers. The answers collection is fetched ONCE,
/// here at submit time, the score is computed locally, and the complete
/// attempt is then written in a single write. Scoring still happens on
/// the client (full server-side scoring needs a paid Cloud Function);
/// see BUILD_NOTES.md for the honest limits of this level.
class TakeTestController extends GetxController {
  final TestService _testService = Get.find<TestService>();

  late final TestModel test;
  late final String studentName;
  late final String roll;

  final questions = <Question>[].obs;

  /// Selected option per question (same order as [questions]); -1 = skipped.
  final answers = <int>[].obs;

  final currentIndex = 0.obs;
  final remainingSec = 0.obs;
  final isLoading = true.obs;
  final isSubmitting = false.obs;
  final loadError = ''.obs;

  /// false = one question at a time; true = scroll-all view.
  final scrollAll = false.obs;

  Timer? _timer;
  DateTime? _startedAt;
  bool _submitted = false;

  bool get hasSubmitted => _submitted;
  int get answeredCount => answers.where((a) => a != -1).length;
  int get skippedCount => answers.where((a) => a == -1).length;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['test'] is TestModel) {
      test = args['test'] as TestModel;
      studentName = (args['name'] as String?)?.trim() ?? '';
      roll = (args['roll'] as String?)?.trim() ?? '';
      _load();
    } else {
      // Fallback values so the screen can still render the error state.
      test = const TestModel(id: '', ownerId: '', code: '', title: 'Test');
      studentName = '';
      roll = '';
      isLoading.value = false;
      loadError.value = 'This test link is incomplete. Please open the '
          'test link again or enter the test code on the home screen.';
    }
  }

  Future<void> _load() async {
    try {
      var loaded = await _testService.fetchQuestionsOnce(test.id);
      if (loaded.isEmpty) {
        loadError.value =
            'This test has no questions yet. Please ask your teacher.';
        return;
      }
      if (test.shuffle) {
        loaded = List<Question>.of(loaded)..shuffle(Random());
      }
      questions.assignAll(loaded);
      answers.assignAll(List<int>.filled(loaded.length, -1));
      remainingSec.value = test.durationMin * 60;
      _startedAt = DateTime.now();
      _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
    } catch (e) {
      loadError.value = 'Could not load the questions. '
          'Check your internet and try again.';
    } finally {
      isLoading.value = false;
    }
  }

  void _onTick(Timer timer) {
    if (_submitted) {
      timer.cancel();
      return;
    }
    if (remainingSec.value > 0) {
      remainingSec.value = remainingSec.value - 1;
    }
    if (remainingSec.value <= 0) {
      submit(auto: true);
    }
  }

  // ---------------------------------------------------------------------------
  // Answering / navigation
  // ---------------------------------------------------------------------------

  void selectOption(int questionIndex, int optionIndex) {
    if (_submitted) return;
    if (questionIndex < 0 || questionIndex >= answers.length) return;
    answers[questionIndex] = optionIndex;
    answers.refresh();
  }

  void clearAnswer(int questionIndex) {
    if (_submitted) return;
    if (questionIndex < 0 || questionIndex >= answers.length) return;
    answers[questionIndex] = -1;
    answers.refresh();
  }

  void next() {
    if (currentIndex.value < questions.length - 1) {
      currentIndex.value = currentIndex.value + 1;
    }
  }

  void previous() {
    if (currentIndex.value > 0) {
      currentIndex.value = currentIndex.value - 1;
    }
  }

  void jumpTo(int index) {
    if (index >= 0 && index < questions.length) {
      currentIndex.value = index;
    }
  }

  void toggleScrollAll() {
    scrollAll.value = !scrollAll.value;
  }

  // ---------------------------------------------------------------------------
  // Submit + scoring
  // ---------------------------------------------------------------------------

  /// Scores the attempt and saves it. Called by the submit button
  /// (after a confirm dialog) and automatically when the timer hits zero.
  ///
  /// First the answers collection is fetched (once); if that fetch fails
  /// the attempt is NOT submitted — the student keeps their answers and
  /// can submit again. Only after scoring is the complete attempt
  /// written, in one write, exactly as in v1.
  Future<void> submit({bool auto = false}) async {
    if (_submitted || isSubmitting.value) return;
    isSubmitting.value = true;

    final Map<String, QuestionAnswer> answersById;
    try {
      answersById = await _testService.fetchAnswersOnce(test.id);
    } catch (_) {
      isSubmitting.value = false;
      Get.snackbar(
        'Could not submit',
        'Your result could not be checked. Please check your internet '
            'and submit again - your answers are still here.',
      );
      return;
    }

    _submitted = true;
    _timer?.cancel();

    // Merge the fetched answers into the questions for scoring and for
    // the post-submit review. Legacy v1 tests have no answers collection;
    // their questions already carry the answers, so they pass through
    // unchanged (the fallback in TestService._mergeAnswers' contract).
    final gradedQuestions = questions
        .map((q) {
          final answer = answersById[q.id];
          return answer == null ? q : q.withAnswer(answer);
        })
        .toList(growable: false);

    var correct = 0;
    var wrong = 0;
    var skipped = 0;
    for (var i = 0; i < gradedQuestions.length; i++) {
      final answer = answers[i];
      if (answer == -1) {
        skipped++;
      } else if (answer == gradedQuestions[i].correctIndex) {
        correct++;
      } else {
        wrong++;
      }
    }

    final rawScore =
        correct * test.marksPerQuestion - wrong * test.negativeMarks;
    final total = questions.length * test.marksPerQuestion;

    var timeUsed = test.durationMin * 60 - remainingSec.value;
    if (_startedAt != null) {
      final elapsed = DateTime.now().difference(_startedAt!).inSeconds;
      if (elapsed >= 0 && elapsed <= test.durationMin * 60 + 5) {
        timeUsed = elapsed;
      }
    }
    if (timeUsed < 0) timeUsed = 0;

    final attempt = Attempt(
      id: '',
      studentName: studentName,
      roll: roll,
      answers: List<int>.of(answers),
      questionIds: questions.map((q) => q.id).toList(growable: false),
      score: rawScore,
      total: total,
      correct: correct,
      wrong: wrong,
      skipped: skipped,
      timeUsedSec: timeUsed,
      submittedAt: DateTime.now(),
    );

    try {
      await _testService.saveAttempt(test.id, attempt);
    } catch (_) {
      // The student must still see the result even if saving failed
      // (e.g. connection dropped at the last second). The teacher simply
      // will not see this attempt in the dashboard.
      Get.snackbar(
        'Result not saved',
        'Your result is shown below, but it could not be saved. '
            'Please tell your teacher.',
      );
    }

    isSubmitting.value = false;
    Get.offNamed(
      AppRoutes.studentResult,
      arguments: <String, dynamic>{
        'test': test,
        'attempt': attempt,
        // The review needs the answers, so it gets the graded questions
        // (public questions + the answers fetched at submit).
        'questions': gradedQuestions,
      },
    );
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../config/app_config.dart';
import '../models/attempt.dart';
import '../models/question.dart';
import '../models/question_answer.dart';
import '../models/quiz_test.dart';
import '../utils/format.dart';
import 'code_generator.dart';

/// All Firestore work for tests, their questions and their attempts.
///
/// Layout (SRS section 6, answers split added in v1.1):
///   tests/{testId}
///   tests/{testId}/questions/{qid}   public: text, options, order
///   tests/{testId}/answers/{qid}     correctIndex, explanation
///   tests/{testId}/attempts/{aid}
///
/// Lists are sorted in Dart after fetching instead of using orderBy on
/// combined queries, so no composite Firestore indexes are needed and the
/// app works on a brand-new Firebase project with zero index setup.
class TestService extends GetxService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _testsRef =>
      _db.collection(AppConfig.testsCollection);

  CollectionReference<Map<String, dynamic>> _questionsRef(String testId) =>
      _testsRef.doc(testId).collection(AppConfig.questionsSubcollection);

  CollectionReference<Map<String, dynamic>> _answersRef(String testId) =>
      _testsRef.doc(testId).collection(AppConfig.answersSubcollection);

  CollectionReference<Map<String, dynamic>> _attemptsRef(String testId) =>
      _testsRef.doc(testId).collection(AppConfig.attemptsSubcollection);

  // ---------------------------------------------------------------------------
  // Tests
  // ---------------------------------------------------------------------------

  /// Live list of one teacher's tests, newest first.
  Stream<List<TestModel>> myTestsStream(String ownerId) {
    return _testsRef
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
      final tests =
          snapshot.docs.map(TestModel.fromDoc).toList(growable: false);
      tests.sort((a, b) {
        final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
      return tests;
    });
  }

  /// Creates a test with a fresh unique code. Returns the stored test.
  Future<TestModel> createTest(TestModel draft) async {
    final code = await _uniqueCode();
    final ref = _testsRef.doc();
    final toSave = draft.copyWith(id: ref.id, code: code);
    final map = toSave.toMap();
    map['createdAt'] = FieldValue.serverTimestamp();
    await ref.set(map);
    return toSave.copyWith(createdAt: DateTime.now());
  }

  /// Updates editable fields of an existing test (code and createdAt are
  /// never changed by an edit).
  Future<void> updateTest(TestModel test) async {
    await _testsRef.doc(test.id).update(test.toMap());
  }

  /// Deletes a test together with all of its questions, answers and
  /// attempts.
  Future<void> deleteTest(String testId) async {
    await _deleteAllDocs(_questionsRef(testId));
    await _deleteAllDocs(_answersRef(testId));
    await _deleteAllDocs(_attemptsRef(testId));
    await _testsRef.doc(testId).delete();
  }

  /// Finds a test by its 6-character student code. Returns null when no
  /// test has that code.
  Future<TestModel?> findTestByCode(String code) async {
    final normalized = code.trim().toUpperCase();
    final snapshot =
        await _testsRef.where('code', isEqualTo: normalized).limit(1).get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    return TestModel.fromDoc(snapshot.docs.first);
  }

  Future<String> _uniqueCode() async {
    for (var attempt = 0; attempt < 12; attempt++) {
      final code = CodeGenerator.generate();
      final existing =
          await _testsRef.where('code', isEqualTo: code).limit(1).get();
      if (existing.docs.isEmpty) {
        return code;
      }
    }
    // Astronomically unlikely with 31^6 combinations; fall back to a
    // longer code rather than failing the create.
    return CodeGenerator.generate(length: AppConfig.testCodeLength + 2);
  }

  // ---------------------------------------------------------------------------
  // Questions
  // ---------------------------------------------------------------------------

  /// Live list of a test's PUBLIC questions, in display order. Since v1.1
  /// these carry no answers (correctIndex == -1) unless the test is a
  /// legacy v1 test whose answers are embedded in the question docs.
  Stream<List<Question>> questionsStream(String testId) {
    return _questionsRef(testId).snapshots().map((snapshot) {
      final questions =
          snapshot.docs.map(Question.fromDoc).toList(growable: false);
      questions.sort((a, b) => a.order.compareTo(b.order));
      return questions;
    });
  }

  /// Live list of a test's questions WITH their answers merged in, in
  /// display order. Teacher flows only (question list/editor). Combines
  /// the questions and answers snapshot streams and re-emits whenever
  /// either side changes.
  Stream<List<Question>> questionsWithAnswersStream(String testId) {
    late StreamController<List<Question>> controller;
    List<Question>? latestQuestions;
    Map<String, QuestionAnswer> latestAnswers = const {};
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? qSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? aSub;

    void emit() {
      final questions = latestQuestions;
      if (questions == null || controller.isClosed) return;
      controller.add(_mergeAnswers(questions, latestAnswers));
    }

    controller = StreamController<List<Question>>(
      onListen: () {
        qSub = _questionsRef(testId).snapshots().listen(
          (snapshot) {
            final questions =
                snapshot.docs.map(Question.fromDoc).toList(growable: false);
            questions.sort((a, b) => a.order.compareTo(b.order));
            latestQuestions = questions;
            emit();
          },
          onError: controller.addError,
        );
        aSub = _answersRef(testId).snapshots().listen(
          (snapshot) {
            latestAnswers = <String, QuestionAnswer>{
              for (final doc in snapshot.docs)
                doc.id: QuestionAnswer.fromDoc(doc),
            };
            emit();
          },
          onError: controller.addError,
        );
      },
      onCancel: () async {
        await qSub?.cancel();
        await aSub?.cancel();
      },
    );
    return controller.stream;
  }

  /// One-time read of all PUBLIC questions, in display order. Used when a
  /// student starts a test: the payload deliberately contains no answers
  /// for v1.1 tests.
  Future<List<Question>> fetchQuestionsOnce(String testId) async {
    final snapshot = await _questionsRef(testId).get();
    final questions =
        snapshot.docs.map(Question.fromDoc).toList(growable: false);
    questions.sort((a, b) => a.order.compareTo(b.order));
    return questions;
  }

  /// One-time read of a test's answers, keyed by question id. Empty for
  /// legacy v1 tests (their answers live inside the question docs).
  Future<Map<String, QuestionAnswer>> fetchAnswersOnce(String testId) async {
    final snapshot = await _answersRef(testId).get();
    return <String, QuestionAnswer>{
      for (final doc in snapshot.docs) doc.id: QuestionAnswer.fromDoc(doc),
    };
  }

  /// One-time read of all questions WITH their answers merged in, in
  /// display order. Teacher flows (attempt detail, class report).
  Future<List<Question>> fetchQuestionsWithAnswersOnce(String testId) async {
    final questions = await fetchQuestionsOnce(testId);
    final answers = await fetchAnswersOnce(testId);
    return _mergeAnswers(questions, answers);
  }

  /// Fills each question's answer in from the answers collection. When a
  /// question has no answers doc, the question is kept as-is: a legacy v1
  /// question already carries its answer inside its own document, which
  /// is exactly the backward-compatibility fallback.
  List<Question> _mergeAnswers(
    List<Question> questions,
    Map<String, QuestionAnswer> answers,
  ) {
    if (answers.isEmpty) return questions;
    return questions
        .map((q) {
          final answer = answers[q.id];
          return answer == null ? q : q.withAnswer(answer);
        })
        .toList(growable: false);
  }

  /// Writes a question as TWO documents (v1.1 split): the public half to
  /// `questions/{qid}` and the answer half to `answers/{qid}`, in one
  /// batch together with the questionCount increment.
  Future<Question> addQuestion(String testId, Question question) async {
    final ref = _questionsRef(testId).doc();
    final toSave = question.copyWith(id: ref.id);
    final batch = _db.batch();
    batch.set(ref, toSave.toPublicMap());
    batch.set(_answersRef(testId).doc(ref.id), toSave.toAnswerMap());
    batch.update(_testsRef.doc(testId), <String, dynamic>{
      'questionCount': FieldValue.increment(1),
    });
    await batch.commit();
    return toSave;
  }

  /// Updates both halves of a question. The answers doc is written with
  /// `set` so editing a legacy v1 question creates its answers doc, and
  /// any answer fields still embedded in the question doc are deleted —
  /// editing a question migrates it to the v1.1 layout.
  Future<void> updateQuestion(String testId, Question question) async {
    final batch = _db.batch();
    final publicUpdate = question.toPublicMap();
    publicUpdate['correctIndex'] = FieldValue.delete();
    publicUpdate['explanation'] = FieldValue.delete();
    batch.update(_questionsRef(testId).doc(question.id), publicUpdate);
    batch.set(_answersRef(testId).doc(question.id), question.toAnswerMap());
    await batch.commit();
  }

  Future<void> deleteQuestion(String testId, String questionId) async {
    final batch = _db.batch();
    batch.delete(_questionsRef(testId).doc(questionId));
    batch.delete(_answersRef(testId).doc(questionId));
    batch.update(_testsRef.doc(testId), <String, dynamic>{
      'questionCount': FieldValue.increment(-1),
    });
    await batch.commit();
  }

  // ---------------------------------------------------------------------------
  // Attempts (results)
  // ---------------------------------------------------------------------------

  /// Saves a student's finished attempt. Returns the stored attempt.
  Future<Attempt> saveAttempt(String testId, Attempt attempt) async {
    final ref = _attemptsRef(testId).doc();
    final toSave = attempt.copyWith(id: ref.id);
    final map = toSave.toMap();
    map['submittedAt'] = FieldValue.serverTimestamp();
    await ref.set(map);
    return toSave.copyWith(submittedAt: DateTime.now());
  }

  /// Live list of a test's attempts, newest first.
  Stream<List<Attempt>> attemptsStream(String testId) {
    return _attemptsRef(testId).snapshots().map((snapshot) {
      final attempts =
          snapshot.docs.map(Attempt.fromDoc).toList(growable: false);
      attempts.sort((a, b) {
        final at = a.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
      return attempts;
    });
  }

  /// How many attempts a test has (for the dashboard cards).
  Future<int> attemptsCount(String testId) async {
    try {
      final aggregate = await _attemptsRef(testId).count().get();
      return aggregate.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> deleteAttempt(String testId, String attemptId) async {
    await _attemptsRef(testId).doc(attemptId).delete();
  }

  /// Deletes every attempt of a test ("clear results").
  Future<void> clearAttempts(String testId) async {
    await _deleteAllDocs(_attemptsRef(testId));
  }

  /// Builds the results spreadsheet as CSV text (shared / copied by the
  /// teacher from the results screen).
  String buildAttemptsCsv(TestModel test, List<Attempt> attempts) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final rows = <List<dynamic>>[
      <dynamic>[
        'Student Name',
        'Roll / ID',
        'Score',
        'Total',
        'Percent',
        'Correct',
        'Wrong',
        'Skipped',
        'Time Used (sec)',
        'Submitted At',
      ],
      for (final a in attempts)
        <dynamic>[
          a.studentName,
          a.roll,
          formatScore(a.score),
          formatScore(a.total),
          a.percent.toStringAsFixed(1),
          a.correct,
          a.wrong,
          a.skipped,
          a.timeUsedSec,
          a.submittedAt == null ? '' : dateFormat.format(a.submittedAt!),
        ],
    ];
    return const ListToCsvConverter().convert(rows);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Deletes every document in a collection, in batches under the
  /// Firestore 500-writes-per-batch limit.
  Future<void> _deleteAllDocs(
    CollectionReference<Map<String, dynamic>> ref,
  ) async {
    final snapshot = await ref.get();
    final docs = snapshot.docs;
    for (var start = 0; start < docs.length; start += 400) {
      final end = (start + 400 < docs.length) ? start + 400 : docs.length;
      final batch = _db.batch();
      for (var i = start; i < end; i++) {
        batch.delete(docs[i].reference);
      }
      await batch.commit();
    }
  }
}

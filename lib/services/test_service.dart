import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../config/app_config.dart';
import '../models/attempt.dart';
import '../models/question.dart';
import '../models/quiz_test.dart';
import '../utils/format.dart';
import 'code_generator.dart';

/// All Firestore work for tests, their questions and their attempts.
///
/// Layout (SRS section 6):
///   tests/{testId}
///   tests/{testId}/questions/{qid}
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

  /// Deletes a test together with all of its questions and attempts.
  Future<void> deleteTest(String testId) async {
    await _deleteAllDocs(_questionsRef(testId));
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

  /// Live list of a test's questions, in display order.
  Stream<List<Question>> questionsStream(String testId) {
    return _questionsRef(testId).snapshots().map((snapshot) {
      final questions =
          snapshot.docs.map(Question.fromDoc).toList(growable: false);
      questions.sort((a, b) => a.order.compareTo(b.order));
      return questions;
    });
  }

  /// One-time read of all questions, in display order. Used when a student
  /// starts a test and by the teacher's attempt-detail screen.
  Future<List<Question>> fetchQuestionsOnce(String testId) async {
    final snapshot = await _questionsRef(testId).get();
    final questions =
        snapshot.docs.map(Question.fromDoc).toList(growable: false);
    questions.sort((a, b) => a.order.compareTo(b.order));
    return questions;
  }

  Future<Question> addQuestion(String testId, Question question) async {
    final ref = _questionsRef(testId).doc();
    final toSave = question.copyWith(id: ref.id);
    await ref.set(toSave.toMap());
    await _testsRef
        .doc(testId)
        .update(<String, dynamic>{'questionCount': FieldValue.increment(1)});
    return toSave;
  }

  Future<void> updateQuestion(String testId, Question question) async {
    await _questionsRef(testId).doc(question.id).update(question.toMap());
  }

  Future<void> deleteQuestion(String testId, String questionId) async {
    await _questionsRef(testId).doc(questionId).delete();
    await _testsRef
        .doc(testId)
        .update(<String, dynamic>{'questionCount': FieldValue.increment(-1)});
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

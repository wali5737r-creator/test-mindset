import 'package:cloud_firestore/cloud_firestore.dart';

/// One student's submitted attempt. Firestore: `tests/{testId}/attempts/{aid}`.
class Attempt {
  final String id;
  final String studentName;

  /// Optional roll number / student ID given on the intro screen.
  final String roll;

  /// Selected option index per question, in the order the questions were
  /// shown to THIS student (after any shuffle). -1 means skipped.
  /// Parallel to [questionIds].
  final List<int> answers;

  /// Question ids parallel to [answers]. Stored in addition to the SRS data
  /// model so the teacher's per-question review stays correct even if the
  /// teacher later edits or reorders the test's questions.
  final List<String> questionIds;

  /// Raw score: correct * marksPerQuestion - wrong * negativeMarks.
  /// May be negative; only the DISPLAY percent is floored at 0 (SRS section 4).
  final double score;

  /// Maximum possible score for this attempt.
  final double total;

  final int correct;
  final int wrong;
  final int skipped;

  /// Seconds the student used, from start to submit.
  final int timeUsedSec;

  final DateTime? submittedAt;

  const Attempt({
    required this.id,
    required this.studentName,
    this.roll = '',
    required this.answers,
    required this.questionIds,
    required this.score,
    required this.total,
    required this.correct,
    required this.wrong,
    required this.skipped,
    required this.timeUsedSec,
    this.submittedAt,
  });

  int get totalQuestions => answers.length;

  /// Percent for display: raw score floored at 0, clamped to 0-100.
  double get percent {
    if (total <= 0) return 0;
    final raw = score < 0 ? 0.0 : score;
    return (raw / total * 100).clamp(0, 100).toDouble();
  }

  factory Attempt.fromMap(String id, Map<String, dynamic> map) {
    final rawAnswers = map['answers'];
    final answers = <int>[];
    if (rawAnswers is List) {
      for (final a in rawAnswers) {
        answers.add((a as num?)?.toInt() ?? -1);
      }
    }
    final rawIds = map['questionIds'];
    final questionIds = <String>[];
    if (rawIds is List) {
      for (final q in rawIds) {
        questionIds.add(q?.toString() ?? '');
      }
    }
    return Attempt(
      id: id,
      studentName: (map['studentName'] ?? '') as String,
      roll: (map['roll'] ?? '') as String,
      answers: answers,
      questionIds: questionIds,
      score: (map['score'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num?)?.toDouble() ?? 0,
      correct: (map['correct'] as num?)?.toInt() ?? 0,
      wrong: (map['wrong'] as num?)?.toInt() ?? 0,
      skipped: (map['skipped'] as num?)?.toInt() ?? 0,
      timeUsedSec: (map['timeUsedSec'] as num?)?.toInt() ?? 0,
      submittedAt: (map['submittedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory Attempt.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Attempt.fromMap(doc.id, doc.data() ?? <String, dynamic>{});
  }

  /// Note: submittedAt is set by TestService with
  /// FieldValue.serverTimestamp() when the attempt is saved.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'studentName': studentName,
      'roll': roll,
      'answers': answers,
      'questionIds': questionIds,
      'score': score,
      'total': total,
      'correct': correct,
      'wrong': wrong,
      'skipped': skipped,
      'timeUsedSec': timeUsedSec,
    };
  }

  Attempt copyWith({
    String? id,
    String? studentName,
    String? roll,
    List<int>? answers,
    List<String>? questionIds,
    double? score,
    double? total,
    int? correct,
    int? wrong,
    int? skipped,
    int? timeUsedSec,
    DateTime? submittedAt,
  }) {
    return Attempt(
      id: id ?? this.id,
      studentName: studentName ?? this.studentName,
      roll: roll ?? this.roll,
      answers: answers ?? this.answers,
      questionIds: questionIds ?? this.questionIds,
      score: score ?? this.score,
      total: total ?? this.total,
      correct: correct ?? this.correct,
      wrong: wrong ?? this.wrong,
      skipped: skipped ?? this.skipped,
      timeUsedSec: timeUsedSec ?? this.timeUsedSec,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }
}

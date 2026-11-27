import 'package:cloud_firestore/cloud_firestore.dart';

/// The answer half of one question, stored separately from the public
/// question document since v1.1:
/// Firestore: `tests/{testId}/answers/{qid}` (same id as the question).
///
/// The student client only fetches this collection at submit time, so the
/// correct answers are not part of the payload a student receives when a
/// test starts. See BUILD_NOTES.md (v1.1 section) for the honest limits
/// of this split on the free tier.
class QuestionAnswer {
  /// Id of the question this answer belongs to (the document id).
  final String questionId;

  /// Index (0-3) of the correct option inside the question's options.
  final int correctIndex;

  /// Optional explanation shown in the result review. May be empty.
  final String explanation;

  const QuestionAnswer({
    required this.questionId,
    required this.correctIndex,
    this.explanation = '',
  });

  factory QuestionAnswer.fromMap(String id, Map<String, dynamic> map) {
    return QuestionAnswer(
      questionId: id,
      correctIndex: (map['correctIndex'] as num?)?.toInt() ?? 0,
      explanation: (map['explanation'] ?? '') as String,
    );
  }

  factory QuestionAnswer.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return QuestionAnswer.fromMap(doc.id, doc.data() ?? <String, dynamic>{});
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'correctIndex': correctIndex,
      'explanation': explanation,
    };
  }
}

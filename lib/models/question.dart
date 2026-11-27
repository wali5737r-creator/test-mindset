import 'package:cloud_firestore/cloud_firestore.dart';

import 'question_answer.dart';

/// One multiple-choice question. Firestore: `tests/{testId}/questions/{qid}`.
///
/// A question always has exactly 4 options and exactly one correct option.
///
/// Since v1.1 the question document itself is the PUBLIC payload (text,
/// options, order only). The correct answer lives in a separate document,
/// `tests/{testId}/answers/{qid}` (see [QuestionAnswer]), and is merged
/// back into this model by TestService wherever a flow legitimately needs
/// it. A question parsed from a public document therefore has
/// [correctIndex] == -1 ("answer not loaded"). v1 documents embedded the
/// answer in the question document; those still parse with their real
/// [correctIndex], which is the backward-compatibility fallback.
class Question {
  final String id;
  final String text;

  /// Exactly 4 options, in display order A, B, C, D.
  final List<String> options;

  /// Index (0-3) of the correct option inside [options], or -1 when the
  /// answer has not been loaded (public student payload).
  final int correctIndex;

  /// Optional explanation shown in the result review. May be empty.
  final String explanation;

  /// Display order inside the test (0-based).
  final int order;

  const Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    this.explanation = '',
    this.order = 0,
  });

  String get correctOptionText =>
      (correctIndex >= 0 && correctIndex < options.length)
          ? options[correctIndex]
          : '';

  factory Question.fromMap(String id, Map<String, dynamic> map) {
    final rawOptions = map['options'];
    final options = <String>['', '', '', ''];
    if (rawOptions is List) {
      for (var i = 0; i < options.length && i < rawOptions.length; i++) {
        options[i] = rawOptions[i]?.toString() ?? '';
      }
    }
    return Question(
      id: id,
      text: (map['text'] ?? '') as String,
      options: options,
      // -1 (not 0) when the field is absent: a v1.1 public question doc
      // has no correctIndex, and 0 would falsely claim option A is right.
      correctIndex: (map['correctIndex'] as num?)?.toInt() ?? -1,
      explanation: (map['explanation'] ?? '') as String,
      order: (map['order'] as num?)?.toInt() ?? 0,
    );
  }

  factory Question.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Question.fromMap(doc.id, doc.data() ?? <String, dynamic>{});
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'text': text,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
      'order': order,
    };
  }

  /// The PUBLIC document written to `tests/{id}/questions/{qid}` since
  /// v1.1: everything a student may see when a test starts — no answer.
  Map<String, dynamic> toPublicMap() {
    return <String, dynamic>{
      'text': text,
      'options': options,
      'order': order,
    };
  }

  /// The ANSWER document written to `tests/{id}/answers/{qid}` since v1.1.
  Map<String, dynamic> toAnswerMap() {
    return <String, dynamic>{
      'correctIndex': correctIndex,
      'explanation': explanation,
    };
  }

  /// Returns this question with the answer half filled in from [answer].
  Question withAnswer(QuestionAnswer answer) {
    return copyWith(
      correctIndex: answer.correctIndex,
      explanation: answer.explanation,
    );
  }

  Question copyWith({
    String? id,
    String? text,
    List<String>? options,
    int? correctIndex,
    String? explanation,
    int? order,
  }) {
    return Question(
      id: id ?? this.id,
      text: text ?? this.text,
      options: options ?? this.options,
      correctIndex: correctIndex ?? this.correctIndex,
      explanation: explanation ?? this.explanation,
      order: order ?? this.order,
    );
  }
}

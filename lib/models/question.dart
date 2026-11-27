import 'package:cloud_firestore/cloud_firestore.dart';

/// One multiple-choice question. Firestore: `tests/{testId}/questions/{qid}`.
///
/// A question always has exactly 4 options and exactly one correct option.
class Question {
  final String id;
  final String text;

  /// Exactly 4 options, in display order A, B, C, D.
  final List<String> options;

  /// Index (0-3) of the correct option inside [options].
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
      correctIndex: (map['correctIndex'] as num?)?.toInt() ?? 0,
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

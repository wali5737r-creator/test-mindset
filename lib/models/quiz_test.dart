import 'package:cloud_firestore/cloud_firestore.dart';

/// Lifecycle of a test. Students can only open Published tests.
enum TestStatus { draft, published, closed }

extension TestStatusX on TestStatus {
  String get label {
    switch (this) {
      case TestStatus.draft:
        return 'Draft';
      case TestStatus.published:
        return 'Published';
      case TestStatus.closed:
        return 'Closed';
    }
  }

  static TestStatus fromString(String? value) {
    return TestStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => TestStatus.draft,
    );
  }
}

/// A quiz/test created by a teacher. Firestore: `tests/{testId}`.
class TestModel {
  final String id;
  final String ownerId;

  /// Unique 6-character code students use to join (see CodeGenerator).
  final String code;

  final String title;
  final String description;

  /// Time limit for the whole test, in minutes.
  final int durationMin;

  /// Marks awarded for each correct answer.
  final double marksPerQuestion;

  /// Marks deducted for each wrong answer (0 = no negative marking).
  final double negativeMarks;

  /// Whether question order is shuffled for each student.
  final bool shuffle;

  final TestStatus status;

  /// Denormalized count, kept in sync by TestService.
  final int questionCount;

  final DateTime? createdAt;

  const TestModel({
    required this.id,
    required this.ownerId,
    required this.code,
    required this.title,
    this.description = '',
    this.durationMin = 30,
    this.marksPerQuestion = 1,
    this.negativeMarks = 0,
    this.shuffle = false,
    this.status = TestStatus.draft,
    this.questionCount = 0,
    this.createdAt,
  });

  /// Maximum score a student can reach with the current question count.
  double get totalMarks => questionCount * marksPerQuestion;

  factory TestModel.fromMap(String id, Map<String, dynamic> map) {
    return TestModel(
      id: id,
      ownerId: (map['ownerId'] ?? '') as String,
      code: (map['code'] ?? '') as String,
      title: (map['title'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      durationMin: (map['durationMin'] as num?)?.toInt() ?? 30,
      marksPerQuestion: (map['marksPerQuestion'] as num?)?.toDouble() ?? 1,
      negativeMarks: (map['negativeMarks'] as num?)?.toDouble() ?? 0,
      shuffle: (map['shuffle'] ?? false) as bool,
      status: TestStatusX.fromString(map['status'] as String?),
      questionCount: (map['questionCount'] as num?)?.toInt() ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory TestModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return TestModel.fromMap(doc.id, doc.data() ?? <String, dynamic>{});
  }

  /// Note: createdAt is intentionally NOT written here. TestService sets it
  /// with FieldValue.serverTimestamp() when the test is created, and updates
  /// must not overwrite it.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ownerId': ownerId,
      'code': code,
      'title': title,
      'description': description,
      'durationMin': durationMin,
      'marksPerQuestion': marksPerQuestion,
      'negativeMarks': negativeMarks,
      'shuffle': shuffle,
      'status': status.name,
      'questionCount': questionCount,
    };
  }

  TestModel copyWith({
    String? id,
    String? ownerId,
    String? code,
    String? title,
    String? description,
    int? durationMin,
    double? marksPerQuestion,
    double? negativeMarks,
    bool? shuffle,
    TestStatus? status,
    int? questionCount,
    DateTime? createdAt,
  }) {
    return TestModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      durationMin: durationMin ?? this.durationMin,
      marksPerQuestion: marksPerQuestion ?? this.marksPerQuestion,
      negativeMarks: negativeMarks ?? this.negativeMarks,
      shuffle: shuffle ?? this.shuffle,
      status: status ?? this.status,
      questionCount: questionCount ?? this.questionCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

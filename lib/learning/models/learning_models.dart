/// Data model for Learning Mode content.
///
/// All learning content is bundled with the app (no login, no internet,
/// no Firebase). The data files under lib/learning/data/ are GENERATED
/// from the markdown masters in docs/ by
/// tools/generate_learning_data.py — never edit them by hand.
library;

/// One block of lesson / topic / feature body text, in reading order.
enum LessonBlockType { heading, paragraph, example, rule, trap }

class LessonBlock {
  final LessonBlockType type;

  /// Main text for heading / paragraph / example / rule blocks.
  final String text;

  /// Extra note: the wajah line under an example (trap note lives here
  /// too, see [wrong] / [right]).
  final String note;

  /// Trap blocks only: the wrong sentence (Ghalat).
  final String wrong;

  /// Trap blocks only: the corrected sentence (Sahi).
  final String right;

  const LessonBlock._(
    this.type, {
    this.text = '',
    this.note = '',
    this.wrong = '',
    this.right = '',
  });

  const LessonBlock.heading(String text)
      : this._(LessonBlockType.heading, text: text);

  const LessonBlock.paragraph(String text)
      : this._(LessonBlockType.paragraph, text: text);

  const LessonBlock.example(String text, {String note = ''})
      : this._(LessonBlockType.example, text: text, note: note);

  const LessonBlock.rule(String text)
      : this._(LessonBlockType.rule, text: text);

  const LessonBlock.trap(String wrong, String right, String note)
      : this._(LessonBlockType.trap, wrong: wrong, right: right, note: note);
}

/// One practice MCQ attached to a lesson. Exactly 10 per lesson.
class LessonMcq {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const LessonMcq({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}

/// One English grammar lesson (46 in total, grouped into named parts).
class Lesson {
  final String id; // 'grammar-01'
  final int number; // 1..46
  final String title;
  final String subtitle;
  final int partIndex; // 0..12
  final String partName;
  final List<LessonBlock> blocks;
  final List<LessonMcq> mcqs;

  const Lesson({
    required this.id,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.partIndex,
    required this.partName,
    required this.blocks,
    required this.mcqs,
  });
}

/// One pin on the Pakistan relief map, with its full detail body.
class MapFeature {
  final String id; // e.g. 'rivers-01'
  final String name;
  final String category; // Darya, Bandh/Barrage, Daray, ...
  final double lat;
  final double lon;
  final List<LessonBlock> blocks;

  const MapFeature({
    required this.id,
    required this.name,
    required this.category,
    required this.lat,
    required this.lon,
    required this.blocks,
  });

  /// Position on the relief image as fractions of its size.
  /// The bundled relief map spans lon 60.5..80.5 and lat 37.3..23.4.
  double get xFraction => (lon - 60.5) / 20.0;
  double get yFraction => (37.3 - lat) / 13.9;
}

/// A reading topic in the GK / Pakistan Studies portion
/// (e.g. geography terms, provinces and districts).
class GeoTopic {
  final String id; // 'terms' / 'provinces'
  final String title;
  final String subtitle;
  final List<LessonBlock> blocks;

  const GeoTopic({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.blocks,
  });
}

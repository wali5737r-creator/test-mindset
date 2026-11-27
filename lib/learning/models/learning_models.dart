/// Data model for Learning Mode content.
///
/// All learning content is bundled with the app (no login, no internet,
/// no Firebase). The data files under lib/learning/data/ are GENERATED
/// from the markdown masters in docs/ by
/// tools/generate_learning_data.py — never edit them by hand.
library;

/// One block of lesson / topic / feature body text, in reading order.
enum LessonBlockType { heading, paragraph, example, rule, trap, visual, image }

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

  /// A described-diagram card: the docs' "Tasveer ka khayal" text for
  /// portions where visuals matter (computer, everyday science,
  /// islamiat, history, space). Rendered as a highlighted card.
  const LessonBlock.visual(String text)
      : this._(LessonBlockType.visual, text: text);

  /// A bundled map snapshot image (v1.5): [text] holds the asset
  /// path, [note] the optional caption shown under the image.
  /// Rendered full-width with rounded corners.
  const LessonBlock.image(String asset, {String caption = ''})
      : this._(LessonBlockType.image, text: asset, note: caption);
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

/// One lesson with practice MCQs (English grammar: 46, grouped into
/// named parts; Maths: 9, one flat list). [portion] says which
/// Learning Mode portion the lesson belongs to ('english' / 'maths')
/// and drives its progress keys and resume entry.
class Lesson {
  final String id; // 'grammar-01' / 'percentage'
  final int number; // 1..46 (english) / 1..9 (maths)
  final String title;
  final String subtitle;
  final int partIndex; // 0..12 (english parts; 0 for maths)
  final String partName;
  final String portion;
  final List<LessonBlock> blocks;
  final List<LessonMcq> mcqs;

  const Lesson({
    required this.id,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.partIndex,
    required this.partName,
    this.portion = 'english',
    required this.blocks,
    required this.mcqs,
  });
}

/// One pin on the Pakistan map, with its full detail body.
class MapFeature {
  final String id; // e.g. 'rivers-01'
  final String name;
  final String category; // Rivers, Dams & Barrages, Passes, ...
  final double lat;
  final double lon;

  /// Bundled OpenTopoMap snapshot centred on this feature (v1.5),
  /// shown at the top of the detail sheet. '' when none.
  final String imageAsset;
  final List<LessonBlock> blocks;

  const MapFeature({
    required this.id,
    required this.name,
    required this.category,
    required this.lat,
    required this.lon,
    this.imageAsset = '',
    required this.blocks,
  });

  /// Legacy position fractions from the v1.2/v1.3 static relief
  /// image (lon 60.5..80.5, lat 37.3..23.4). Unused since v1.4 —
  /// the real map places pins by [lat]/[lon] directly.
  double get xFraction => (lon - 60.5) / 20.0;
  double get yFraction => (37.3 - lat) / 13.9;
}

/// A reading topic in any Learning Mode portion (geography terms,
/// provinces, Pak Studies, world, space, computer, urdu, islamiat,
/// history, organisations, everyday science).
class GeoTopic {
  final String id; // 'terms' / 'provinces' / 'quran' / ...
  final String title;
  final String subtitle;

  /// Portion id ('pakistan', 'world', 'space', 'computer', 'urdu',
  /// 'islamiat', 'history', 'orgs', 'eds'). Pakistan topics keep the
  /// v1.2 progress keys (their plain id); every other portion prefixes
  /// its progress keys with the portion id so nothing collides.
  final String portion;
  final List<LessonBlock> blocks;

  const GeoTopic({
    required this.id,
    required this.title,
    required this.subtitle,
    this.portion = 'pakistan',
    required this.blocks,
  });

  /// Key used for done/best progress storage.
  String get progressId => portion == 'pakistan' ? id : '$portion:$id';
}

/// One pin on the world map, with its full detail body.
class WorldFeature {
  final String id; // e.g. 'world-features-01'
  final String name;
  final String category; // Rivers, Mountains, Gulfs, Straits, ...
  final double lat;
  final double lon;

  /// Bundled OpenTopoMap snapshot centred on this feature (v1.5),
  /// shown at the top of the detail sheet. '' when none.
  final String imageAsset;
  final List<LessonBlock> blocks;

  const WorldFeature({
    required this.id,
    required this.name,
    required this.category,
    required this.lat,
    required this.lon,
    this.imageAsset = '',
    required this.blocks,
  });

  /// Legacy position fractions from the v1.3 static world image
  /// (full equirectangular, lon -180..180, lat 90..-90). Unused
  /// since v1.4 — the real map places pins by [lat]/[lon] directly.
  double get xFraction => (lon + 180.0) / 360.0;
  double get yFraction => (90.0 - lat) / 180.0;
}

/// One section of the solar-system topic (the Sun or one planet),
/// opened from the Space portion's solar-system visual.
class PlanetSection {
  final String id; // 'sun', 'mercury', ...
  final String name; // 'Mercury'
  final String urduName; // 'Utarid' ('' when the doc gives none)
  final List<LessonBlock> blocks;

  const PlanetSection({
    required this.id,
    required this.name,
    required this.urduName,
    required this.blocks,
  });

  String get label => urduName.isEmpty ? name : '$name — $urduName';
}

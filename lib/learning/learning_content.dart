import 'data/english_lessons_a.dart';
import 'data/english_lessons_b.dart';
import 'data/english_lessons_c.dart';
import 'data/geography_data.dart';
import 'models/learning_models.dart';

/// Single access point for all bundled Learning Mode content.
///
/// English Grammar and GK / Pakistan Studies are two fully separate
/// portions: separate lists, separate screens, separate progress.

/// All 46 English lessons, in course order (by lesson number).
const List<Lesson> allLessons = <Lesson>[
  ...englishLessonsA,
  ...englishLessonsB,
  ...englishLessonsC,
];

/// All map pins for the Pakistan relief map.
const List<MapFeature> allMapFeatures = mapFeatures;

/// Reading topics of the Pakistan portion (terms, provinces).
const List<GeoTopic> allGeoTopics = geoTopics;

Lesson? lessonById(String id) {
  for (final lesson in allLessons) {
    if (lesson.id == id) return lesson;
  }
  return null;
}

GeoTopic? topicById(String id) {
  for (final topic in allGeoTopics) {
    if (topic.id == id) return topic;
  }
  return null;
}

/// A named part (topic group) of the English course.
class EnglishPart {
  final int index;
  final String name;
  final List<Lesson> lessons;

  const EnglishPart({
    required this.index,
    required this.name,
    required this.lessons,
  });
}

/// The 13 named parts, in course order, lessons sorted by number.
List<EnglishPart> englishParts() {
  final byIndex = <int, List<Lesson>>{};
  final names = <int, String>{};
  for (final lesson in allLessons) {
    byIndex.putIfAbsent(lesson.partIndex, () => <Lesson>[]).add(lesson);
    names[lesson.partIndex] = lesson.partName;
  }
  final indexes = byIndex.keys.toList()..sort();
  return <EnglishPart>[
    for (final i in indexes)
      EnglishPart(
        index: i,
        name: names[i] ?? '',
        lessons: byIndex[i]!
          ..sort((a, b) => a.number.compareTo(b.number)),
      ),
  ];
}

/// Map categories in the order they first appear in the data,
/// for the filter chips on the map screen.
List<String> mapCategories() {
  final seen = <String>[];
  for (final f in allMapFeatures) {
    if (!seen.contains(f.category)) seen.add(f.category);
  }
  return seen;
}

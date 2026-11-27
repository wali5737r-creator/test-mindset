import 'data/computer_data.dart';
import 'data/eds_data.dart';
import 'data/english_lessons_a.dart';
import 'data/english_lessons_b.dart';
import 'data/english_lessons_c.dart';
import 'data/geography_data.dart';
import 'data/history_data.dart';
import 'data/islamiat_data.dart';
import 'data/maths_lessons.dart';
import 'data/orgs_data.dart';
import 'data/space_data.dart';
import 'data/urdu_data.dart';
import 'data/world_data.dart';
import 'models/learning_models.dart';

/// Single access point for all bundled Learning Mode content.
///
/// Every portion is fully separate: separate lists, separate screens,
/// separate progress. Portions (v1.3): English, Pakistan, World,
/// Space, Computer, Maths, Urdu, Islamiat, History,
/// Tanzeemain aur Muahide, Everyday Science.

/// All 46 English lessons, in course order (by lesson number).
const List<Lesson> allLessons = <Lesson>[
  ...englishLessonsA,
  ...englishLessonsB,
  ...englishLessonsC,
];

/// All 9 Maths lessons, in course order.
const List<Lesson> allMathsLessons = mathsLessons;

/// Every lesson in the app (English + Maths), for id lookups.
const List<Lesson> everyLesson = <Lesson>[
  ...allLessons,
  ...allMathsLessons,
];

/// All map pins for the Pakistan relief map.
const List<MapFeature> allMapFeatures = mapFeatures;

/// Reading topics of the Pakistan portion: geography terms and
/// provinces first, then the Pak Studies topics.
const List<GeoTopic> allGeoTopics = geoTopics;

/// All pins for the world map.
const List<WorldFeature> allWorldFeatures = worldFeatures;

/// Reading topics per portion (Pakistan lives in [allGeoTopics]).
const Map<String, List<GeoTopic>> topicsByPortion = <String, List<GeoTopic>>{
  'world': worldTopics,
  'space': spaceTopics,
  'computer': computerTopics,
  'urdu': urduTopics,
  'islamiat': islamiatTopics,
  'history': historyTopics,
  'orgs': orgsTopics,
  'eds': edsTopics,
};

/// Sun + planet sections of the solar-system topic, for the Space
/// portion's solar-system visual.
const List<PlanetSection> allPlanetSections = planetSections;

/// Topics of one portion ('pakistan' included).
List<GeoTopic> topicsForPortion(String portion) {
  if (portion == 'pakistan') return allGeoTopics;
  return topicsByPortion[portion] ?? const <GeoTopic>[];
}

/// Every reading topic in the app, across all portions.
List<GeoTopic> get everyTopic => <GeoTopic>[
      ...allGeoTopics,
      for (final list in topicsByPortion.values) ...list,
    ];

Lesson? lessonById(String id) {
  for (final lesson in everyLesson) {
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

/// Finds a topic by the progress id stored in SharedPreferences
/// (plain id for Pakistan topics, '<portion>:<id>' for the rest).
GeoTopic? topicByProgressId(String progressId) {
  for (final topic in everyTopic) {
    if (topic.progressId == progressId) return topic;
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

/// World-map categories in first-appearance order, for filter chips.
List<String> worldMapCategories() {
  final seen = <String>[];
  for (final f in allWorldFeatures) {
    if (!seen.contains(f.category)) seen.add(f.category);
  }
  return seen;
}

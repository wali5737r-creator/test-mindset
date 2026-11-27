import 'package:shared_preferences/shared_preferences.dart';

/// Local, offline progress for Learning Mode (SharedPreferences).
///
/// Keys:
///  - learn_done_<id>     bool  lesson/topic complete. The <id> is the
///                        lesson id, or a topic's progressId: plain id
///                        for the Pakistan portion (v1.2 keys, kept),
///                        '<portion>:<id>' for every other portion.
///  - learn_best_<id>     int   best practice-quiz score (0-10)
///  - learn_last_lesson   String  last opened lesson/topic progress id
///  - learn_last_subject  String  portion id ('english', 'pakistan',
///                        'maths', 'world', ...)
///  - learn_best_map_quiz int   best Pakistan map-quiz score (0-10)
///  - learn_best_world_map_quiz int  best world map-quiz score (0-10)
///
/// Progress lives only on this device; uninstalling the app clears it.
/// Learning Mode accounts do not exist, by design.
class ProgressService {
  ProgressService._();

  static final ProgressService instance = ProgressService._();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _sp async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<bool> isDone(String id) async =>
      (await _sp).getBool('learn_done_$id') ?? false;

  Future<void> setDone(String id, bool value) async =>
      (await _sp).setBool('learn_done_$id', value);

  Future<Set<String>> doneSet(Iterable<String> ids) async {
    final prefs = await _sp;
    final done = <String>{};
    for (final id in ids) {
      if (prefs.getBool('learn_done_$id') ?? false) done.add(id);
    }
    return done;
  }

  Future<int?> bestScore(String id) async =>
      (await _sp).getInt('learn_best_$id');

  Future<Map<String, int>> bestScores(Iterable<String> ids) async {
    final prefs = await _sp;
    final out = <String, int>{};
    for (final id in ids) {
      final v = prefs.getInt('learn_best_$id');
      if (v != null) out[id] = v;
    }
    return out;
  }

  /// Saves [score] only if it beats the stored best. Returns the best.
  Future<int> saveBestScore(String id, int score) async {
    final prefs = await _sp;
    final current = prefs.getInt('learn_best_$id');
    if (current == null || score > current) {
      await prefs.setInt('learn_best_$id', score);
      return score;
    }
    return current;
  }

  Future<String?> lastLessonId() async =>
      (await _sp).getString('learn_last_lesson');

  Future<String?> lastSubject() async =>
      (await _sp).getString('learn_last_subject');

  Future<void> setLast(String subject, String id) async {
    final prefs = await _sp;
    await prefs.setString('learn_last_subject', subject);
    await prefs.setString('learn_last_lesson', id);
  }

  Future<int?> mapQuizBest() async =>
      (await _sp).getInt('learn_best_map_quiz');

  Future<int> saveMapQuizBest(int score) async {
    final prefs = await _sp;
    final current = prefs.getInt('learn_best_map_quiz');
    if (current == null || score > current) {
      await prefs.setInt('learn_best_map_quiz', score);
      return score;
    }
    return current;
  }

  Future<int?> worldMapQuizBest() async =>
      (await _sp).getInt('learn_best_world_map_quiz');

  Future<int> saveWorldMapQuizBest(int score) async {
    final prefs = await _sp;
    final current = prefs.getInt('learn_best_world_map_quiz');
    if (current == null || score > current) {
      await prefs.setInt('learn_best_world_map_quiz', score);
      return score;
    }
    return current;
  }
}

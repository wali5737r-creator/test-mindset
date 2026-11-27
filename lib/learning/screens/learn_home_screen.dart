import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../learning_content.dart';
import '../models/learning_models.dart';
import '../services/progress_service.dart';

/// One portion's progress snapshot for the home cards.
class PortionProgress {
  final String id;
  final int done;
  final int total;

  const PortionProgress({
    required this.id,
    required this.done,
    required this.total,
  });
}

/// Learning Mode home: one card per portion, each fully separate
/// with its own progress (English, Pakistan, World, Space, Computer,
/// Maths, Urdu, Islamiat, History, Organizations & Treaties,
/// Everyday Science). No login, no internet.
class LearnHomeController extends GetxController {
  final ProgressService _progress = ProgressService.instance;

  final loading = true.obs;
  final portions = <PortionProgress>[].obs;
  final mapQuizBest = RxnInt();
  final worldMapQuizBest = RxnInt();
  final lastSubject = RxnString();
  Lesson? lastLesson;
  GeoTopic? lastTopic;

  int get totalDone => portions.fold(0, (sum, p) => sum + p.done);
  int get totalAll => portions.fold(0, (sum, p) => sum + p.total);

  int doneOf(String id) =>
      portions.firstWhere((p) => p.id == id, orElse: () => const PortionProgress(id: '', done: 0, total: 0)).done;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<int> _doneCount(Iterable<String> progressIds) async =>
      (await _progress.doneSet(progressIds)).length;

  Future<void> load() async {
    loading.value = true;
    portions.value = <PortionProgress>[
      PortionProgress(
        id: 'english',
        done: await _doneCount(allLessons.map((l) => l.id)),
        total: allLessons.length,
      ),
      PortionProgress(
        id: 'pakistan',
        done: await _doneCount(allGeoTopics.map((t) => t.progressId)),
        total: allGeoTopics.length,
      ),
      PortionProgress(
        id: 'world',
        done: await _doneCount(
            topicsForPortion('world').map((t) => t.progressId)),
        total: topicsForPortion('world').length,
      ),
      PortionProgress(
        id: 'space',
        done: await _doneCount(
            topicsForPortion('space').map((t) => t.progressId)),
        total: topicsForPortion('space').length,
      ),
      PortionProgress(
        id: 'computer',
        done: await _doneCount(
            topicsForPortion('computer').map((t) => t.progressId)),
        total: topicsForPortion('computer').length,
      ),
      PortionProgress(
        id: 'maths',
        done: await _doneCount(allMathsLessons.map((l) => l.id)),
        total: allMathsLessons.length,
      ),
      PortionProgress(
        id: 'urdu',
        done: await _doneCount(
            topicsForPortion('urdu').map((t) => t.progressId)),
        total: topicsForPortion('urdu').length,
      ),
      PortionProgress(
        id: 'islamiat',
        done: await _doneCount(
            topicsForPortion('islamiat').map((t) => t.progressId)),
        total: topicsForPortion('islamiat').length,
      ),
      PortionProgress(
        id: 'history',
        done: await _doneCount(
            topicsForPortion('history').map((t) => t.progressId)),
        total: topicsForPortion('history').length,
      ),
      PortionProgress(
        id: 'orgs',
        done: await _doneCount(
            topicsForPortion('orgs').map((t) => t.progressId)),
        total: topicsForPortion('orgs').length,
      ),
      PortionProgress(
        id: 'eds',
        done: await _doneCount(
            topicsForPortion('eds').map((t) => t.progressId)),
        total: topicsForPortion('eds').length,
      ),
    ];
    mapQuizBest.value = await _progress.mapQuizBest();
    worldMapQuizBest.value = await _progress.worldMapQuizBest();
    lastSubject.value = await _progress.lastSubject();
    final lastId = await _progress.lastLessonId();
    lastLesson = lastId == null ? null : lessonById(lastId);
    lastTopic = lastId == null ? null : topicByProgressId(lastId);
    loading.value = false;
  }
}

class LearnHomeScreen extends GetView<LearnHomeController> {
  const LearnHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Learning Mode')),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final totalDone = controller.totalDone;
        final totalAll = controller.totalAll;
        final lastLesson = controller.lastLesson;
        final lastTopic = controller.lastTopic;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Text(
              'PPSC Preparation — at Your Own Pace',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'No login and no internet needed. Read, practise, and your '
              'progress stays saved on this phone. Every subject is '
              'kept separate — open only what you want to study.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                const Icon(Icons.emoji_events, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Total progress: $totalDone / $totalAll complete',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: totalAll == 0 ? 0 : totalDone / totalAll,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            if (lastLesson != null &&
                lastLesson.portion == controller.lastSubject.value) ...<Widget>[
              const SizedBox(height: 14),
              _resumeChip(
                context,
                lastLesson.portion == 'maths'
                    ? 'Continue: ${lastLesson.title}'
                    : 'Continue: Lesson ${lastLesson.number} — '
                        '${lastLesson.title}',
                () async {
                  await Get.toNamed(
                    AppRoutes.learnLesson,
                    arguments: lastLesson,
                  );
                  controller.load();
                },
              ),
            ],
            if (lastTopic != null &&
                lastTopic.portion == controller.lastSubject.value) ...<Widget>[
              const SizedBox(height: 14),
              _resumeChip(
                context,
                'Continue: ${lastTopic.title}',
                () async {
                  await Get.toNamed(
                    AppRoutes.learnTopic,
                    arguments: lastTopic,
                  );
                  controller.load();
                },
              ),
            ],
            const SizedBox(height: 22),
            _portionCard(
              context,
              portionId: 'english',
              icon: Icons.menu_book,
              title: 'English Grammar',
              subtitle:
                  '${allLessons.length} lessons in 13 parts — 10 practice '
                  'questions with every lesson',
              onTap: () async {
                await Get.toNamed(AppRoutes.learnEnglish);
                controller.load();
              },
            ),
            _portionCard(
              context,
              portionId: 'pakistan',
              icon: Icons.map,
              title: 'GK & Pakistan Studies',
              subtitle:
                  'Pakistan map (${allMapFeatures.length} places), geography '
                  'topics and complete Pak Studies',
              extra: controller.mapQuizBest.value == null
                  ? null
                  : 'Map Quiz best: ${controller.mapQuizBest.value}/10',
              onTap: () async {
                await Get.toNamed(AppRoutes.learnPakistan);
                controller.load();
              },
            ),
            _portionCard(
              context,
              portionId: 'world',
              icon: Icons.public,
              title: 'World',
              subtitle:
                  'World map (${allWorldFeatures.length} places), famous '
                  'countries, gulfs, straits and map terms',
              extra: controller.worldMapQuizBest.value == null
                  ? null
                  : 'Map Quiz best: ${controller.worldMapQuizBest.value}/10',
              onTap: () => _openPortion('world'),
            ),
            _portionCard(
              context,
              portionId: 'space',
              icon: Icons.rocket_launch,
              title: 'Space',
              subtitle:
                  'The solar system with a planet chart, the layers of the '
                  'atmosphere, ozone, satellites, comets and galaxies',
              onTap: () => _openPortion('space'),
            ),
            _portionCard(
              context,
              portionId: 'computer',
              icon: Icons.computer,
              title: 'Computer',
              subtitle:
                  'Basics, complete MS Word / Excel / PowerPoint overviews, '
                  'shortcut keys — and hands-on Practical work',
              onTap: () => _openPortion('computer'),
            ),
            _portionCard(
              context,
              portionId: 'maths',
              icon: Icons.calculate,
              title: 'Maths',
              subtitle:
                  '${allMathsLessons.length} topics — concept first, formula '
                  'after; 10 practice questions with every topic',
              onTap: () async {
                await Get.toNamed(
                  AppRoutes.learnLessons,
                  arguments: 'maths',
                );
                controller.load();
              },
            ),
            _portionCard(
              context,
              portionId: 'urdu',
              icon: Icons.translate,
              title: 'Urdu',
              subtitle:
                  'Ghazal terms (matla, maqta, radeef), poetry and prose '
                  'forms, grammar, idioms and literature facts',
              onTap: () => _openPortion('urdu'),
            ),
            _portionCard(
              context,
              portionId: 'islamiat',
              icon: Icons.mosque,
              title: 'Islamiat',
              subtitle:
                  'Quran and Hadith in detail, Seerat, Ghazwaat told as '
                  'stories, the Khulafa and the Pillars of Islam',
              onTap: () => _openPortion('islamiat'),
            ),
            _portionCard(
              context,
              portionId: 'history',
              icon: Icons.history_edu,
              title: 'History',
              subtitle:
                  'The five dynasties of the Delhi Sultanate, the Mughal '
                  'emperors and their deeds, wars from 712 to 2026',
              onTap: () => _openPortion('history'),
            ),
            _portionCard(
              context,
              portionId: 'orgs',
              icon: Icons.groups,
              title: 'Organizations & Treaties',
              subtitle:
                  'UNO, IMF, World Bank, NATO, OIC, SAARC — and famous '
                  'treaties like Indus Waters, Tashkent and Simla',
              onTap: () => _openPortion('orgs'),
            ),
            _portionCard(
              context,
              portionId: 'eds',
              icon: Icons.science,
              title: 'Everyday Science',
              subtitle:
                  'The human body, food and vitamins, plants and nature, '
                  'everyday physics and chemistry',
              onTap: () => _openPortion('eds'),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _openPortion(String portion) async {
    await Get.toNamed(AppRoutes.learnPortion, arguments: portion);
    controller.load();
  }

  Widget _resumeChip(
    BuildContext context,
    String label,
    VoidCallback onTap,
  ) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ActionChip(
        avatar: const Icon(Icons.play_arrow, size: 18),
        label: Text(label),
        onPressed: onTap,
      ),
    );
  }

  Widget _portionCard(
    BuildContext context, {
    required String portionId,
    required IconData icon,
    required String title,
    required String subtitle,
    String? extra,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final done = controller.doneOf(portionId);
    final total = controller.portions
        .firstWhere(
          (p) => p.id == portionId,
          orElse: () => const PortionProgress(id: '', done: 0, total: 0),
        )
        .total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        icon,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                const SizedBox(height: 10),
                Text(subtitle, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: total == 0 ? 0 : done / total,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 6),
                Text(
                  '$done / $total complete',
                  style: theme.textTheme.bodySmall,
                ),
                if (extra != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    extra,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

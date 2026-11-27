import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../learning_content.dart';
import '../models/learning_models.dart';
import '../services/progress_service.dart';

/// Learning Mode home: two fully separate portions —
/// English Grammar and GK & Pakistan Studies — each with its own
/// progress. No login, no internet.
class LearnHomeController extends GetxController {
  final ProgressService _progress = ProgressService.instance;

  final loading = true.obs;
  final englishDone = 0.obs;
  final pakistanDone = 0.obs;
  final mapQuizBest = RxnInt();
  final lastSubject = RxnString();
  Lesson? lastLesson;
  GeoTopic? lastTopic;

  int get englishTotal => allLessons.length;
  int get pakistanTotal => allGeoTopics.length;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    englishDone.value =
        (await _progress.doneSet(allLessons.map((l) => l.id))).length;
    pakistanDone.value =
        (await _progress.doneSet(allGeoTopics.map((t) => t.id))).length;
    mapQuizBest.value = await _progress.mapQuizBest();
    lastSubject.value = await _progress.lastSubject();
    final lastId = await _progress.lastLessonId();
    lastLesson = lastId == null ? null : lessonById(lastId);
    lastTopic = lastId == null ? null : topicById(lastId);
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
        final totalDone = controller.englishDone.value +
            controller.pakistanDone.value;
        final totalAll = controller.englishTotal + controller.pakistanTotal;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Text(
              'PPSC ki tayyari — apni raftaar se',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Koi login nahi, koi internet nahi. Parho, practice karo, '
              'aur progress isi phone par save rahegi.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                const Icon(Icons.emoji_events, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Kul progress: $totalDone / $totalAll complete',
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
            if (controller.lastSubject.value == 'english' &&
                controller.lastLesson != null) ...<Widget>[
              const SizedBox(height: 14),
              _resumeChip(
                context,
                'Jari rakhein: Lesson ${controller.lastLesson!.number} — '
                '${controller.lastLesson!.title}',
                () async {
                  await Get.toNamed(
                    AppRoutes.learnLesson,
                    arguments: controller.lastLesson,
                  );
                  controller.load();
                },
              ),
            ],
            if (controller.lastSubject.value == 'pakistan' &&
                controller.lastTopic != null) ...<Widget>[
              const SizedBox(height: 14),
              _resumeChip(
                context,
                'Jari rakhein: ${controller.lastTopic!.title}',
                () async {
                  await Get.toNamed(
                    AppRoutes.learnTopic,
                    arguments: controller.lastTopic,
                  );
                  controller.load();
                },
              ),
            ],
            const SizedBox(height: 22),
            _subjectCard(
              context,
              icon: Icons.menu_book,
              title: 'English Grammar',
              subtitle:
                  '${controller.englishTotal} lessons, 13 hisso me — '
                  'har lesson ke sath 10 practice sawal',
              done: controller.englishDone.value,
              total: controller.englishTotal,
              onTap: () async {
                await Get.toNamed(AppRoutes.learnEnglish);
                controller.load();
              },
            ),
            const SizedBox(height: 16),
            _subjectCard(
              context,
              icon: Icons.map,
              title: 'GK & Pakistan Studies',
              subtitle:
                  'Pakistan ka naqsha (${allMapFeatures.length} jagahen), '
                  'darya, daray, pahar, sobay aur zilon ki mukammal tafseel',
              done: controller.pakistanDone.value,
              total: controller.pakistanTotal,
              extra: controller.mapQuizBest.value == null
                  ? null
                  : 'Map Quiz best: ${controller.mapQuizBest.value}/10',
              onTap: () async {
                await Get.toNamed(AppRoutes.learnPakistan);
                controller.load();
              },
            ),
          ],
        );
      }),
    );
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

  Widget _subjectCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required int done,
    required int total,
    String? extra,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
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
    );
  }
}

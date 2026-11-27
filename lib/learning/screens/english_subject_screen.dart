import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../learning_content.dart';
import '../models/learning_models.dart';
import '../services/progress_service.dart';

/// English Grammar portion: the 46 lessons grouped into 13 named
/// parts. Lesson numbers and course order are kept inside each part.
class EnglishSubjectController extends GetxController {
  final ProgressService _progress = ProgressService.instance;

  final loading = true.obs;
  final doneIds = <String>{}.obs;
  final bestScores = <String, int>{}.obs;
  final lastLessonId = RxnString();

  final List<EnglishPart> parts = englishParts();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    doneIds.value =
        await _progress.doneSet(allLessons.map((l) => l.id));
    bestScores.value =
        await _progress.bestScores(allLessons.map((l) => l.id));
    lastLessonId.value = await _progress.lastLessonId();
    loading.value = false;
  }

  int partDone(EnglishPart part) =>
      part.lessons.where((l) => doneIds.contains(l.id)).length;
}

class EnglishSubjectScreen extends GetView<EnglishSubjectController> {
  const EnglishSubjectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('English Grammar')),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: controller.parts.length,
          itemBuilder: (BuildContext context, int index) {
            final part = controller.parts[index];
            final done = controller.partDone(part);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 4),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          part.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      Text(
                        '$done/${part.lessons.length}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                for (final lesson in part.lessons)
                  _lessonRow(context, lesson),
              ],
            );
          },
        );
      }),
    );
  }

  Widget _lessonRow(BuildContext context, Lesson lesson) {
    final theme = Theme.of(context);
    final done = controller.doneIds.contains(lesson.id);
    final best = controller.bestScores[lesson.id];
    final isLast = controller.lastLessonId.value == lesson.id;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: done
              ? const Color(0xFFF97316)
              : theme.colorScheme.primaryContainer,
          child: done
              ? const Icon(Icons.check, color: Colors.white, size: 20)
              : Text(
                  '${lesson.number}',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        title: Text(
          lesson.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(lesson.subtitle),
            if (best != null || isLast) ...<Widget>[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: <Widget>[
                  if (best != null)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text('Best: $best/10'),
                      side: BorderSide.none,
                      backgroundColor:
                          theme.colorScheme.secondaryContainer,
                    ),
                  if (isLast)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: const Text('Continue'),
                      side: BorderSide.none,
                      backgroundColor: theme.colorScheme.tertiaryContainer,
                    ),
                ],
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          await Get.toNamed(AppRoutes.learnLesson, arguments: lesson);
          controller.load();
        },
      ),
    );
  }
}

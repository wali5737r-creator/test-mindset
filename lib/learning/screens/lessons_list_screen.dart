import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../learning_content.dart';
import '../models/learning_models.dart';
import '../services/progress_service.dart';

/// A flat lesson list for a lesson-based portion (Maths): every
/// lesson with its done tick and practice-quiz best score. Lessons
/// open in the shared LessonScreen / PracticeQuizScreen.
class LessonsListController extends GetxController {
  final ProgressService _progress = ProgressService.instance;

  late final String portion;
  final loading = true.obs;
  final doneIds = <String>{}.obs;
  final bestScores = <String, int>{}.obs;
  final lastLessonId = RxnString();

  List<Lesson> get lessons =>
      portion == 'maths' ? allMathsLessons : const <Lesson>[];

  @override
  void onInit() {
    super.onInit();
    portion = Get.arguments as String;
    load();
  }

  Future<void> load() async {
    loading.value = true;
    doneIds.value = await _progress.doneSet(lessons.map((l) => l.id));
    bestScores.value = await _progress.bestScores(lessons.map((l) => l.id));
    lastLessonId.value = await _progress.lastLessonId();
    loading.value = false;
  }
}

class LessonsListScreen extends GetView<LessonsListController> {
  const LessonsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Maths')),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 8),
              child: Text(
                'Har topic pehle concept se, phir formula se — ratta '
                'nahi, samajh. Har lesson ke sath 10 practice sawal.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            for (final lesson in controller.lessons)
              _lessonRow(context, lesson),
          ],
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
              ? Colors.green.shade600
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
                      label: const Text('Jari rakhein'),
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

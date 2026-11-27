import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../models/learning_models.dart';
import '../services/progress_service.dart';
import '../widgets/lesson_blocks_view.dart';

/// One lesson (English or Maths): full body in styled blocks, then
/// the practice quiz button and the mark-complete button.
class LessonController extends GetxController {
  final ProgressService _progress = ProgressService.instance;

  late final Lesson lesson;
  final done = false.obs;
  final best = RxnInt();

  @override
  void onInit() {
    super.onInit();
    lesson = Get.arguments as Lesson;
    _progress.setLast(lesson.portion, lesson.id);
    load();
  }

  Future<void> load() async {
    done.value = await _progress.isDone(lesson.id);
    best.value = await _progress.bestScore(lesson.id);
  }

  Future<void> toggleDone() async {
    final value = !done.value;
    await _progress.setDone(lesson.id, value);
    done.value = value;
  }
}

class LessonScreen extends GetView<LessonController> {
  const LessonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lesson = controller.lesson;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          lesson.portion == 'maths'
              ? lesson.title
              : 'Lesson ${lesson.number}',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: <Widget>[
          Text(
            lesson.partName,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            lesson.title,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            lesson.subtitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Divider(height: 28),
          LessonBlocksView(blocks: lesson.blocks),
          const SizedBox(height: 18),
          Obx(() {
            final best = controller.best.value;
            if (best == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Practice quiz best score: $best/10',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            );
          }),
          FilledButton.icon(
            onPressed: () async {
              await Get.toNamed(AppRoutes.learnQuiz, arguments: lesson);
              controller.load();
            },
            icon: const Icon(Icons.quiz),
            label: const Text('Practice MCQs (10)'),
          ),
          const SizedBox(height: 10),
          Obx(
            () => controller.done.value
                ? FilledButton.tonalIcon(
                    onPressed: controller.toggleDone,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Lesson Complete hai — undo karo'),
                  )
                : OutlinedButton.icon(
                    onPressed: controller.toggleDone,
                    icon: const Icon(Icons.check),
                    label: const Text('Lesson Complete'),
                  ),
          ),
        ],
      ),
    );
  }
}

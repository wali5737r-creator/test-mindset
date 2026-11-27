import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/learning_models.dart';
import '../services/progress_service.dart';
import '../widgets/lesson_blocks_view.dart';

/// One reading topic from any portion, full detail body. Progress is
/// stored under the topic's progressId (plain id for the Pakistan
/// portion — the v1.2 keys — '<portion>:<id>' everywhere else).
class TopicController extends GetxController {
  final ProgressService _progress = ProgressService.instance;

  late final GeoTopic topic;
  final done = false.obs;

  @override
  void onInit() {
    super.onInit();
    topic = Get.arguments as GeoTopic;
    _progress.setLast(topic.portion, topic.progressId);
    load();
  }

  Future<void> load() async {
    done.value = await _progress.isDone(topic.progressId);
  }

  Future<void> toggleDone() async {
    final value = !done.value;
    await _progress.setDone(topic.progressId, value);
    done.value = value;
  }
}

class TopicScreen extends GetView<TopicController> {
  const TopicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topic = controller.topic;
    return Scaffold(
      appBar: AppBar(title: const Text('Topic')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: <Widget>[
          Text(
            topic.title,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            topic.subtitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Divider(height: 28),
          LessonBlocksView(blocks: topic.blocks),
          const SizedBox(height: 18),
          Obx(
            () => controller.done.value
                ? FilledButton.tonalIcon(
                    onPressed: controller.toggleDone,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Topic Completed — tap to undo'),
                  )
                : OutlinedButton.icon(
                    onPressed: controller.toggleDone,
                    icon: const Icon(Icons.check),
                    label: const Text('Topic Complete'),
                  ),
          ),
        ],
      ),
    );
  }
}

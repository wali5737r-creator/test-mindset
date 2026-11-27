import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../learning_content.dart';
import '../models/learning_models.dart';
import '../services/progress_service.dart';

/// GK & Pakistan Studies portion: the interactive map first, then the
/// reading topics (geography terms, provinces & districts, and the
/// Pak Studies topics — movement, leaders, constitutions, symbols) —
/// each with its full detail text.
class PakistanSubjectController extends GetxController {
  final ProgressService _progress = ProgressService.instance;

  final loading = true.obs;
  final doneIds = <String>{}.obs;
  final mapQuizBest = RxnInt();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    doneIds.value =
        await _progress.doneSet(allGeoTopics.map((t) => t.id));
    mapQuizBest.value = await _progress.mapQuizBest();
    loading.value = false;
  }
}

class PakistanSubjectScreen extends GetView<PakistanSubjectController> {
  const PakistanSubjectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('GK & Pakistan Studies')),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: <Widget>[
            Card(
              clipBehavior: Clip.antiAlias,
              color: theme.colorScheme.primaryContainer,
              child: InkWell(
                onTap: () async {
                  await Get.toNamed(AppRoutes.learnMap);
                  controller.load();
                },
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.map,
                            size: 30,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Pakistan Map',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${allMapFeatures.length} places on the map — rivers, '
                        'dams, passes, mountains, doabs, borders, '
                        'historic sites and lakes. Tap any pin to '
                        'open its full details. The Map Quiz is '
                        'there too.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      if (controller.mapQuizBest.value != null) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(
                          'Map Quiz best: ${controller.mapQuizBest.value}/10',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Reading Topics',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Every topic in full detail — geography terms and the '
              'provinces, then Pak Studies: the movement, the '
              'leaders, the constitutions and national symbols.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            for (final topic in allGeoTopics) _topicRow(context, topic),
          ],
        );
      }),
    );
  }

  Widget _topicRow(BuildContext context, GeoTopic topic) {
    final theme = Theme.of(context);
    final done = controller.doneIds.contains(topic.id);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: done
              ? Colors.green.shade600
              : theme.colorScheme.primaryContainer,
          child: done
              ? const Icon(Icons.check, color: Colors.white, size: 20)
              : Icon(
                  Icons.article,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 20,
                ),
        ),
        title: Text(
          topic.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(topic.subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          await Get.toNamed(AppRoutes.learnTopic, arguments: topic);
          controller.load();
        },
      ),
    );
  }
}

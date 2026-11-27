import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../learning_content.dart';
import '../models/learning_models.dart';
import '../services/progress_service.dart';
import '../widgets/solar_system_visual.dart';

/// Static presentation info for one topic-based portion.
class PortionInfo {
  final String title;
  final String intro;
  final IconData icon;

  const PortionInfo({
    required this.title,
    required this.intro,
    required this.icon,
  });
}

const Map<String, PortionInfo> portionInfos = <String, PortionInfo>{
  'world': PortionInfo(
    title: 'World — Duniya',
    intro: 'Pehle naqshay par duniya ki mashhoor jagahen dekho, phir '
        'mulk aur istilahaat parho.',
    icon: Icons.public,
  ),
  'space': PortionInfo(
    title: 'Space — Asmaan',
    intro: 'Upar siyaron ko chhu kar un ki tafseel kholo, phir teen '
        'topics mukammal parho.',
    icon: Icons.rocket_launch,
  ),
  'computer': PortionInfo(
    title: 'Computer',
    intro: 'Pehle course parho — buniyad, Word, Excel, PowerPoint aur '
        'shortcuts — phir Practical hisse me asal kaam step by step.',
    icon: Icons.computer,
  ),
  'urdu': PortionInfo(
    title: 'Urdu',
    intro: 'Ghazal ki istilahaat, asnaaf, qawaid, muhawaray aur adab '
        'ke mashhoor facts — nukta ba nukta.',
    icon: Icons.translate,
  ),
  'islamiat': PortionInfo(
    title: 'Islamiat',
    intro: 'Quran, Hadees, Seerat, Ghazwaat, Khulafa-e-Rashideen aur '
        'Arkan-e-Islam — har cheez tafseel se.',
    icon: Icons.mosque,
  ),
  'history': PortionInfo(
    title: 'History',
    intro: 'Delhi Sultanate aur Mughal badshah kahani ke andaaz me, '
        'aur 712 se 2026 tak ki jangain mukammal tafseel ke sath.',
    icon: Icons.history_edu,
  ),
  'orgs': PortionInfo(
    title: 'Tanzeemain aur Muahide',
    intro: 'UNO, IMF, NATO, OIC, SAARC jaisi tanzeemain aur Indus '
        'Waters, Tashkent, Simla jese mashhoor muahide.',
    icon: Icons.groups,
  ),
  'eds': PortionInfo(
    title: 'Everyday Science',
    intro: 'Jo cheezain paper poochta hai lekin hum ne kabhi dekhi '
        'nahi — har topic ke sath tasveer-numa cards.',
    icon: Icons.science,
  ),
};

/// One topic-based portion (World, Space, Computer, Urdu, Islamiat,
/// History, Tanzeemain aur Muahide, Everyday Science): an optional
/// header visual (world map card / solar system), then the reading
/// topics, each opening in the shared TopicScreen.
class PortionController extends GetxController {
  final ProgressService _progress = ProgressService.instance;

  late final String portion;
  final loading = true.obs;
  final doneIds = <String>{}.obs;
  final worldMapQuizBest = RxnInt();

  List<GeoTopic> get topics => topicsForPortion(portion);
  PortionInfo get info => portionInfos[portion]!;

  @override
  void onInit() {
    super.onInit();
    portion = Get.arguments as String;
    load();
  }

  Future<void> load() async {
    loading.value = true;
    doneIds.value =
        await _progress.doneSet(topics.map((t) => t.progressId));
    if (portion == 'world') {
      worldMapQuizBest.value = await _progress.worldMapQuizBest();
    }
    loading.value = false;
  }
}

class PortionScreen extends GetView<PortionController> {
  const PortionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(controller.info.title)),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final topics = controller.topics;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: <Widget>[
            if (controller.portion == 'world') ...<Widget>[
              _worldMapCard(context),
              const SizedBox(height: 20),
            ],
            if (controller.portion == 'space') ...<Widget>[
              const SolarSystemVisual(),
              const SizedBox(height: 20),
            ],
            Text(
              'Parhai ke Topics',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              controller.info.intro,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            for (final topic in topics) ...<Widget>[
              if (controller.portion == 'computer' &&
                  topic.id.startsWith('practical-') &&
                  topic.id == 'practical-word')
                _groupHeading(context, 'Practical — Asal Kaam'),
              _topicRow(context, topic),
            ],
          ],
        );
      }),
    );
  }

  Widget _groupHeading(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _worldMapCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.primaryContainer,
      child: InkWell(
        onTap: () async {
          await Get.toNamed(AppRoutes.learnWorldMap);
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
                    Icons.public,
                    size: 30,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Duniya ka Naqsha',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
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
                '${allWorldFeatures.length} jagahen naqshay par — bare '
                'darya, pahar, khaleejain, aabnayen aur jazire. Kisi '
                'bhi nishan ko chhuo, mukammal tafseel khul jayegi. '
                'Map Quiz bhi wahin hai.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              if (controller.worldMapQuizBest.value != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  'Map Quiz best: ${controller.worldMapQuizBest.value}/10',
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
    );
  }

  Widget _topicRow(BuildContext context, GeoTopic topic) {
    final theme = Theme.of(context);
    final done = controller.doneIds.contains(topic.progressId);
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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../learning_content.dart';
import '../models/learning_models.dart';
import '../services/progress_service.dart';
import '../widgets/feature_sheet.dart';

/// Pakistan relief map with pins only (no circles, no region
/// overlays — owner's order). Tap a pin for its full detail.
/// Map Quiz mode: "X kahan hai?" — tap the right place.
class MapController extends GetxController {
  final ProgressService _progress = ProgressService.instance;

  final category = 'Sab'.obs;

  // Quiz state
  final quizMode = false.obs;
  final targets = <MapFeature>[].obs;
  final round = 0.obs;
  final quizScore = 0.obs;
  final revealed = Rxn<MapFeature>();
  final lastCorrect = RxnBool();
  final quizFinished = false.obs;
  final quizBest = RxnInt();

  List<MapFeature> get visibleFeatures => category.value == 'Sab'
      ? allMapFeatures
      : allMapFeatures
          .where((f) => f.category == category.value)
          .toList();

  MapFeature? get currentTarget =>
      targets.isEmpty ? null : targets[round.value];

  @override
  void onInit() {
    super.onInit();
    _loadBest();
  }

  Future<void> _loadBest() async {
    quizBest.value = await _progress.mapQuizBest();
  }

  void startQuiz() {
    final pool = List<MapFeature>.of(allMapFeatures)..shuffle();
    targets.value = pool.take(10).toList();
    round.value = 0;
    quizScore.value = 0;
    revealed.value = null;
    lastCorrect.value = null;
    quizFinished.value = false;
    quizMode.value = true;
  }

  void exitQuiz() {
    quizMode.value = false;
    revealed.value = null;
    lastCorrect.value = null;
    quizFinished.value = false;
  }

  /// [local] is the tap position inside the map child (image pixels
  /// of the displayed child), [size] the child's size.
  void onMapTap(Offset local, Size size) {
    if (!quizMode.value || quizFinished.value || revealed.value != null) {
      return;
    }
    final target = currentTarget;
    if (target == null) return;
    final pin = Offset(
      target.xFraction * size.width,
      target.yFraction * size.height,
    );
    final distance = (local - pin).distance;
    // Generous radius: about 5.5% of the map width plus a base pad.
    final ok = distance <= size.width * 0.055 + 26;
    lastCorrect.value = ok;
    if (ok) quizScore.value++;
    revealed.value = target;
  }

  Future<void> nextRound() async {
    if (round.value >= targets.length - 1) {
      quizFinished.value = true;
      quizBest.value =
          await _progress.saveMapQuizBest(quizScore.value);
    } else {
      round.value++;
      revealed.value = null;
      lastCorrect.value = null;
    }
  }
}

class MapScreen extends GetView<MapController> {
  const MapScreen({super.key});

  static const double _imgW = 1600;
  static const double _imgH = 1279;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pakistan ka Naqsha'),
        actions: <Widget>[
          Obx(
            () => controller.quizMode.value
                ? TextButton.icon(
                    onPressed: controller.exitQuiz,
                    icon: const Icon(Icons.close),
                    label: const Text('Quiz band'),
                  )
                : TextButton.icon(
                    onPressed: controller.startQuiz,
                    icon: const Icon(Icons.quiz),
                    label: const Text('Map Quiz'),
                  ),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Obx(() {
            if (controller.quizMode.value) {
              return _quizBar(context);
            }
            return _chipsBar(context);
          }),
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final w = constraints.maxWidth;
                final h = w * _imgH / _imgW;
                return InteractiveViewer(
                  minScale: 0.6,
                  maxScale: 6,
                  boundaryMargin: const EdgeInsets.all(90),
                  child: SizedBox(
                    width: w,
                    height: h,
                    child: Obx(() => _mapStack(context, w, h)),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Obx(
              () => Text(
                controller.quizMode.value
                    ? 'Naqshay par sahi jagah tap karo. Zoom ke liye '
                        'do ungliyan phailao.'
                    : 'Kisi nishan (pin) ko chhuo — us jagah ki mukammal '
                        'tafseel khul jayegi. Zoom ke liye do ungliyan '
                        'phailao.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipsBar(BuildContext context) {
    final categories = <String>['Sab', ...mapCategories()];
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: categories.length,
        itemBuilder: (BuildContext context, int i) {
          final cat = categories[i];
          final selected = controller.category.value == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat),
              selected: selected,
              onSelected: (_) => controller.category.value = cat,
            ),
          );
        },
      ),
    );
  }

  Widget _quizBar(BuildContext context) {
    final theme = Theme.of(context);
    if (controller.quizFinished.value) {
      return Container(
        width: double.infinity,
        color: theme.colorScheme.primaryContainer,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Map Quiz khatam — Score: ${controller.quizScore.value}/'
              '${controller.targets.length}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            if (controller.quizBest.value != null)
              Text(
                'Best: ${controller.quizBest.value}/10',
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                FilledButton.icon(
                  onPressed: controller.startQuiz,
                  icon: const Icon(Icons.replay),
                  label: const Text('Dobara'),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: controller.exitQuiz,
                  child: const Text('Naqsha dekho'),
                ),
              ],
            ),
          ],
        ),
      );
    }
    final target = controller.currentTarget;
    final revealed = controller.revealed.value;
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'Sawal ${controller.round.value + 1}/'
                '${controller.targets.length}',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                'Score: ${controller.quizScore.value}',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            target == null
                ? ''
                : '${target.name} kahan hai? Naqshay par tap karo.',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (revealed != null) ...<Widget>[
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                Icon(
                  controller.lastCorrect.value == true
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: controller.lastCorrect.value == true
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    controller.lastCorrect.value == true
                        ? 'Bilkul sahi jagah!'
                        : 'Ye rahi sahi jagah — ${revealed.name}.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                FilledButton(
                  onPressed: controller.nextRound,
                  child: Text(
                    controller.round.value >= controller.targets.length - 1
                        ? 'Result'
                        : 'Agla',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _mapStack(BuildContext context, double w, double h) {
    final inQuiz = controller.quizMode.value;
    final revealed = controller.revealed.value;
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: Image.asset(
            'assets/learning/pakistan_relief.jpg',
            fit: BoxFit.fill,
          ),
        ),
        if (inQuiz && !controller.quizFinished.value)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapUp: (TapUpDetails details) =>
                  controller.onMapTap(details.localPosition, Size(w, h)),
            ),
          ),
        if (!inQuiz)
          for (final f in controller.visibleFeatures)
            _pin(context, f, w, h, big: false),
        if (inQuiz && revealed != null)
          _pin(context, revealed, w, h, big: true),
      ],
    );
  }

  Widget _pin(
    BuildContext context,
    MapFeature feature,
    double w,
    double h, {
    required bool big,
  }) {
    final size = big ? 44.0 : 30.0;
    final box = size + 10;
    final pin = Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Icon(
          Icons.location_on,
          size: box,
          color: Colors.white.withValues(alpha: 0.9),
        ),
        Icon(
          Icons.location_on,
          size: size,
          color: categoryColor(feature.category),
        ),
      ],
    );
    return Positioned(
      left: feature.xFraction * w - box / 2,
      top: feature.yFraction * h - box + 5,
      child: big
          ? IgnorePointer(child: pin)
          : GestureDetector(
              onTap: () => showFeatureSheet(context, feature),
              child: pin,
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../learning_content.dart';
import '../models/learning_models.dart';
import '../services/progress_service.dart';
import '../widgets/feature_sheet.dart';
import '../widgets/topo_map.dart';

/// The world on a REAL interactive map (v1.4): OpenTopoMap tiles —
/// pinch zoom and pan across the whole world, relief shading on the
/// mountain ranges, Mapcarta-style. Pins are grouped by category and
/// NOTHING is shown until the student picks one category (the old
/// static image showed all 39 pins at once — owner's complaint).
/// Tap a pin for its full detail.
/// Map Quiz mode: "X kahan hai?" — tap the right place on the map.
class WorldMapController extends GetxController {
  final ProgressService _progress = ProgressService.instance;

  /// flutter_map's own controller (camera moves for the quiz reveal).
  final fm.MapController mapController = fm.MapController();

  /// Selected category; null = none picked yet, so the map starts
  /// clean. 'Sab' is available but is never the default.
  final category = RxnString();

  /// True once any tile failed to load (offline + nothing cached).
  final tilesFailed = false.obs;

  // Quiz state
  final quizMode = false.obs;
  final targets = <WorldFeature>[].obs;
  final round = 0.obs;
  final quizScore = 0.obs;
  final revealed = Rxn<WorldFeature>();
  final lastCorrect = RxnBool();
  final quizFinished = false.obs;
  final quizBest = RxnInt();

  List<WorldFeature> get visibleFeatures {
    final cat = category.value;
    if (cat == null) return const <WorldFeature>[];
    if (cat == 'Sab') return allWorldFeatures;
    return allWorldFeatures.where((f) => f.category == cat).toList();
  }

  WorldFeature? get currentTarget =>
      targets.isEmpty ? null : targets[round.value];

  @override
  void onInit() {
    super.onInit();
    _loadBest();
  }

  Future<void> _loadBest() async {
    quizBest.value = await _progress.worldMapQuizBest();
  }

  void markTilesFailed() {
    tilesFailed.value = true;
  }

  void startQuiz() {
    final pool = List<WorldFeature>.of(allWorldFeatures)..shuffle();
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

  /// A tap on the map during the quiz. The world is big, so the
  /// generous radius is 900 km — the right region of the right
  /// continent counts.
  void onMapTap(LatLng point) {
    if (!quizMode.value || quizFinished.value || revealed.value != null) {
      return;
    }
    final target = currentTarget;
    if (target == null) return;
    final km = distanceKm(point.latitude, point.longitude, target.lat,
        target.lon);
    final ok = km <= 900;
    lastCorrect.value = ok;
    if (ok) quizScore.value++;
    revealed.value = target;
    // Bring the right place into view so the student SEES where it is.
    final zoom = mapController.camera.zoom;
    mapController.move(
      LatLng(target.lat, target.lon),
      zoom < 3.5 ? 3.5 : zoom,
    );
  }

  Future<void> nextRound() async {
    if (round.value >= targets.length - 1) {
      quizFinished.value = true;
      quizBest.value =
          await _progress.saveWorldMapQuizBest(quizScore.value);
    } else {
      round.value++;
      revealed.value = null;
      lastCorrect.value = null;
    }
  }
}

class WorldMapScreen extends GetView<WorldMapController> {
  const WorldMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duniya ka Naqsha'),
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
          Obx(
            () => controller.tilesFailed.value
                ? const MapOfflineNote()
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: Obx(() => _flutterMap(context)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Obx(
              () => Text(
                _hintText(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _hintText() {
    if (controller.quizMode.value) {
      return 'Naqshay par sahi jagah tap karo. Zoom ke liye do '
          'ungliyan phailao.';
    }
    if (controller.category.value == null) {
      return 'Pehle upar se aik qisam chunein — phir naqshay par sirf '
          'usi ke pins ayenge. Zoom ke liye do ungliyan phailao.';
    }
    return 'Kisi pin ko chhuo — us jagah ki mukammal tafseel khul '
        'jayegi. Zoom ke liye do ungliyan phailao.';
  }

  Widget _flutterMap(BuildContext context) {
    return fm.FlutterMap(
      mapController: controller.mapController,
      options: fm.MapOptions(
        initialCameraFit: fm.CameraFit.bounds(
          bounds: fm.LatLngBounds(
            const LatLng(-58, -180),
            const LatLng(84, 180),
          ),
          padding: const EdgeInsets.all(8),
        ),
        minZoom: 2,
        maxZoom: 16,
        backgroundColor: const Color(0xFFDCE8EC),
        interactionOptions: const fm.InteractionOptions(
          flags: fm.InteractiveFlag.all & ~fm.InteractiveFlag.rotate,
        ),
        onTap: (tapPosition, point) => controller.onMapTap(point),
      ),
      children: <Widget>[
        topoTileLayer(onTileError: controller.markTilesFailed),
        fm.MarkerLayer(markers: _markers(context)),
        mapAttribution(),
      ],
    );
  }

  List<fm.Marker> _markers(BuildContext context) {
    if (controller.quizMode.value) {
      final revealed = controller.revealed.value;
      if (revealed == null || controller.quizFinished.value) {
        return const <fm.Marker>[];
      }
      return <fm.Marker>[_marker(context, revealed, big: true)];
    }
    return <fm.Marker>[
      for (final f in controller.visibleFeatures)
        _marker(context, f, big: false),
    ];
  }

  fm.Marker _marker(BuildContext context, WorldFeature feature,
      {required bool big}) {
    final pin = MapPin(
      color: worldCategoryColor(feature.category),
      label: feature.name,
      big: big,
      onTap: big ? null : () => showWorldFeatureSheet(context, feature),
    );
    return fm.Marker(
      point: LatLng(feature.lat, feature.lon),
      width: pin.boxSize,
      height: pin.boxSize,
      alignment: Alignment.topCenter,
      child: pin,
    );
  }

  Widget _chipsBar(BuildContext context) {
    final theme = Theme.of(context);
    final categories = <String>['Sab', ...worldMapCategories()];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: 52,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: categories.length,
            itemBuilder: (BuildContext context, int i) {
              final cat = categories[i];
              final selected = controller.category.value == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (bool sel) =>
                      controller.category.value = sel ? cat : null,
                ),
              );
            },
          ),
        ),
        if (controller.category.value == null)
          Container(
            width: double.infinity,
            color: theme.colorScheme.primaryContainer,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Upar se aik qisam chunein — jese sirf Darya ya sirf '
              'Khaleej. Phir naqshay par sirf usi qisam ke pins nazar '
              'ayenge, sab mix nahi honge.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
      ],
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
}

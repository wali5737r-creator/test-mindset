import 'package:flutter/material.dart';

import '../models/learning_models.dart';
import 'lesson_blocks_view.dart';

/// Accent colour per map category (pins + chips share these).
Color categoryColor(String category) {
  switch (category) {
    case 'Rivers':
      return Colors.blue.shade700;
    case 'Dams & Barrages':
      return Colors.indigo.shade600;
    case 'Doabs':
      return Colors.orange.shade800;
    case 'Passes':
      return Colors.brown.shade600;
    case 'Mountains':
      return Colors.grey.shade800;
    case 'Deserts & Plains':
      return Colors.amber.shade800;
    case 'Borders':
      return Colors.purple.shade700;
    case 'Heritage Sites':
      return Colors.red.shade700;
    case 'Coast & Ports':
      return Colors.cyan.shade800;
    case 'Lakes':
      return Colors.teal.shade700;
    default:
      return Colors.blueGrey.shade700;
  }
}

/// Accent colour per world-map category.
Color worldCategoryColor(String category) {
  switch (category) {
    case 'Rivers':
      return Colors.blue.shade700;
    case 'Seas & Oceans':
      return Colors.blue.shade900;
    case 'Gulfs':
      return Colors.cyan.shade800;
    case 'Bays':
      return Colors.teal.shade700;
    case 'Straits':
      return Colors.indigo.shade600;
    case 'Canals & Straits':
      return Colors.deepPurple.shade600;
    case 'Mountains':
      return Colors.grey.shade800;
    case 'Deserts':
      return Colors.amber.shade800;
    case 'Lakes':
      return Colors.lightBlue.shade800;
    case 'Islands':
      return Colors.green.shade700;
    default:
      return Colors.blueGrey.shade700;
  }
}

/// Opens the detail sheet for a map feature: name, category and the
/// FULL detail body from the docs — never a summary.
void showFeatureSheet(BuildContext context, MapFeature feature) {
  showBlocksSheet(
    context,
    title: feature.name,
    category: feature.category,
    color: categoryColor(feature.category),
    imageAsset: feature.imageAsset,
    blocks: feature.blocks,
  );
}

/// Opens the detail sheet for a world-map feature.
void showWorldFeatureSheet(BuildContext context, WorldFeature feature) {
  showBlocksSheet(
    context,
    title: feature.name,
    category: feature.category,
    color: worldCategoryColor(feature.category),
    imageAsset: feature.imageAsset,
    blocks: feature.blocks,
  );
}

/// Shared bottom sheet: a title, an optional category chip, an
/// optional map snapshot image at the top (v1.5) and a full block
/// body (map features, planet sections).
void showBlocksSheet(
  BuildContext context, {
  required String title,
  String? category,
  Color? color,
  IconData icon = Icons.location_on,
  String imageAsset = '',
  required List<LessonBlock> blocks,
}) {
  final chipColor = color ?? Colors.blueGrey.shade700;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext sheetContext) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (BuildContext context, ScrollController scrollController) {
          final theme = Theme.of(context);
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    icon,
                    color: chipColor,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              if (category != null) ...<Widget>[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    label: Text(category),
                    backgroundColor: chipColor.withValues(alpha: 0.14),
                    side: BorderSide.none,
                  ),
                ),
              ],
              if (imageAsset.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    imageAsset,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              LessonBlocksView(blocks: blocks),
            ],
          );
        },
      );
    },
  );
}

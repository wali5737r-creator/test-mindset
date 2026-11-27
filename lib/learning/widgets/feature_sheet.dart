import 'package:flutter/material.dart';

import '../models/learning_models.dart';
import 'lesson_blocks_view.dart';

/// Accent colour per map category (pins + chips share these).
Color categoryColor(String category) {
  switch (category) {
    case 'Darya':
      return Colors.blue.shade700;
    case 'Bandh/Barrage':
      return Colors.indigo.shade600;
    case 'Doab':
      return Colors.orange.shade800;
    case 'Daray':
      return Colors.brown.shade600;
    case 'Pahar':
      return Colors.grey.shade800;
    case 'Registran/Maidan':
      return Colors.amber.shade800;
    case 'Sarhad':
      return Colors.purple.shade700;
    case 'Heritage':
      return Colors.red.shade700;
    case 'Sahel':
      return Colors.cyan.shade800;
    case 'Jheelain':
      return Colors.teal.shade700;
    default:
      return Colors.blueGrey.shade700;
  }
}

/// Opens the detail sheet for a map feature: name, category and the
/// FULL detail body from the docs — never a summary.
void showFeatureSheet(BuildContext context, MapFeature feature) {
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
                    Icons.location_on,
                    color: categoryColor(feature.category),
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature.name,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  label: Text(feature.category),
                  backgroundColor:
                      categoryColor(feature.category).withValues(alpha: 0.14),
                  side: BorderSide.none,
                ),
              ),
              const SizedBox(height: 6),
              LessonBlocksView(blocks: feature.blocks),
            ],
          );
        },
      );
    },
  );
}

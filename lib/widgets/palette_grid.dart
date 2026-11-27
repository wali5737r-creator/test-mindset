import 'package:flutter/material.dart';

/// The question palette: one numbered cell per question.
/// Filled green = answered, grey = not answered yet, ring = current question.
class PaletteGrid extends StatelessWidget {
  final int count;

  /// Selected option per question; -1 means unanswered.
  final List<int> answers;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const PaletteGrid({
    super.key,
    required this.count,
    required this.answers,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: count,
      itemBuilder: (context, index) {
        final answered = index < answers.length && answers[index] != -1;
        final isCurrent = index == currentIndex;
        return Material(
          color: answered ? Colors.green.shade600 : scheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: isCurrent
                ? BorderSide(color: scheme.primary, width: 2.5)
                : BorderSide.none,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onTap(index),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: answered ? Colors.white : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

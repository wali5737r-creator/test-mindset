import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/take_test_controller.dart';
import '../models/question.dart';
import '../routes/app_routes.dart';
import '../utils/format.dart';
import '../widgets/option_tile.dart';
import '../widgets/palette_grid.dart';

/// The student's test screen: countdown timer in the app bar, one
/// question at a time (or scroll-all), a question palette, and a
/// confirm-before-submit dialog. Auto-submits when the timer ends.
class TakeTestScreen extends GetView<TakeTestController> {
  const TakeTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !controller.hasSubmitted) {
          _confirmExit(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Obx(
            () => Text(
              controller.isLoading.value || controller.questions.isEmpty
                  ? controller.test.title
                  : 'Q ${controller.currentIndex.value + 1} of '
                      '${controller.questions.length}',
            ),
          ),
          actions: [
            Obx(() {
              final low = controller.remainingSec.value <= 60;
              return Center(
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: low ? Colors.red : Colors.green.shade700,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer, size: 16, color: Colors.white),
                      const SizedBox(width: 5),
                      Text(
                        formatClock(controller.remainingSec.value),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            Obx(
              () => IconButton(
                icon: Icon(
                  controller.scrollAll.value
                      ? Icons.view_agenda_outlined
                      : Icons.view_list_outlined,
                ),
                tooltip: controller.scrollAll.value
                    ? 'One question view'
                    : 'Scroll-all view',
                onPressed: controller.questions.isEmpty
                    ? null
                    : controller.toggleScrollAll,
              ),
            ),
          ],
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.loadError.value.isNotEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 52),
                    const SizedBox(height: 12),
                    Text(
                      controller.loadError.value,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: () => Get.offAllNamed(AppRoutes.home),
                      child: const Text('Go to Home'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (controller.scrollAll.value) {
            return _scrollAllView(context);
          }
          return _oneByOneView(context);
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // One-question-at-a-time view
  // ---------------------------------------------------------------------------

  Widget _oneByOneView(BuildContext context) {
    final index = controller.currentIndex.value;
    final question = controller.questions[index];
    final total = controller.questions.length;
    return Column(
      children: [
        LinearProgressIndicator(
          value: total == 0 ? 0 : (index + 1) / total,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: _questionBlock(context, question, index),
              ),
            ),
          ),
        ),
        _bottomBar(context, index, total),
      ],
    );
  }

  Widget _bottomBar(BuildContext context, int index, int total) {
    final isLast = index >= total - 1;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            OutlinedButton(
              onPressed: index > 0 ? controller.previous : null,
              child: const Text('Previous'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _openPalette(context),
              icon: const Icon(Icons.grid_view, size: 18),
              label: const Text('Palette'),
            ),
            const Spacer(),
            if (!isLast)
              FilledButton(
                onPressed: controller.next,
                child: const Text('Next'),
              )
            else
              FilledButton.icon(
                onPressed: () => _confirmSubmit(context),
                icon: const Icon(Icons.send, size: 18),
                label: const Text('Submit'),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Scroll-all view
  // ---------------------------------------------------------------------------

  Widget _scrollAllView(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.questions.length,
            itemBuilder: (context, index) {
              final question = controller.questions[index];
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: _questionBlock(context, question, index),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _openPalette(context),
                  icon: const Icon(Icons.grid_view, size: 18),
                  label: const Text('Palette'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _confirmSubmit(context),
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('Submit Test'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Shared pieces
  // ---------------------------------------------------------------------------

  Widget _questionBlock(BuildContext context, Question question, int index) {
    final theme = Theme.of(context);
    final selected = controller.answers[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Question ${index + 1}',
          style: theme.textTheme.labelLarge
              ?.copyWith(color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 6),
        Text(
          question.text,
          style:
              theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < question.options.length; i++)
          OptionTile(
            letter: 'ABCD'[i],
            text: question.options[i],
            selected: selected == i,
            onTap: () => controller.selectOption(index, i),
          ),
        if (selected != -1)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => controller.clearAnswer(index),
              child: const Text('Clear answer'),
            ),
          ),
      ],
    );
  }

  void _openPalette(BuildContext context) {
    Get.bottomSheet(
      Container(
        color: Theme.of(context).colorScheme.surface,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Questions',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Obx(
                () => Text(
                  '${controller.answeredCount} answered  •  '
                  '${controller.skippedCount} not answered',
                ),
              ),
              const SizedBox(height: 14),
              Obx(
                () => PaletteGrid(
                  count: controller.questions.length,
                  answers: controller.answers,
                  currentIndex: controller.currentIndex.value,
                  onTap: (i) {
                    controller.jumpTo(i);
                    Get.back();
                  },
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () {
                  Get.back();
                  _confirmSubmit(context);
                },
                icon: const Icon(Icons.send, size: 18),
                label: const Text('Submit Test'),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _confirmSubmit(BuildContext context) {
    if (controller.hasSubmitted || controller.isSubmitting.value) return;
    Get.dialog(
      AlertDialog(
        title: const Text('Submit test?'),
        content: Text(
          'You answered ${controller.answeredCount} of '
          '${controller.questions.length} questions.\n'
          '${controller.skippedCount} question(s) are unanswered.\n\n'
          'After submitting you cannot change your answers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Keep Solving'),
          ),
          FilledButton(
            onPressed: () {
              Get.back();
              controller.submit();
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Leave the test?'),
        content: const Text(
          'Your answers will be lost and the test will not be submitted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () {
              Get.back();
              Get.offAllNamed(AppRoutes.home);
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}

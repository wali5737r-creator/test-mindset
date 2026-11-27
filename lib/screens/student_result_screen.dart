import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../config/app_config.dart';
import '../models/attempt.dart';
import '../models/question.dart';
import '../models/quiz_test.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../utils/format.dart';
import '../widgets/question_review_card.dart';

/// The student's instant result: a shareable result card + full answer
/// review. Arguments: {'test': TestModel, 'attempt': Attempt,
/// 'questions': List<Question>}.
///
/// The card at the top is a plain RESULT CARD (never a certificate): it
/// shows the student's own score summary and can be shared as a PNG
/// image via the "Share result" button.
class StudentResultScreen extends StatefulWidget {
  const StudentResultScreen({super.key});

  @override
  State<StudentResultScreen> createState() => _StudentResultScreenState();
}

class _StudentResultScreenState extends State<StudentResultScreen> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    if (args is! Map ||
        args['test'] is! TestModel ||
        args['attempt'] is! Attempt) {
      return Scaffold(
        appBar: AppBar(title: const Text('Result')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'No result to show. If you just finished a test, '
                  'please do not refresh this page.',
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
        ),
      );
    }

    final test = args['test'] as TestModel;
    final attempt = args['attempt'] as Attempt;
    final questions = (args['questions'] as List?)?.cast<Question>() ??
        const <Question>[];
    final byId = <String, Question>{for (final q in questions) q.id: q};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Result'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _resultCard(context, test, attempt),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _isSharing ? null : () => _shareResult(test, attempt),
            icon: _isSharing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Icon(Icons.share),
            label: const Text('Share result'),
          ),
          const SizedBox(height: 18),
          Text(
            'Review Answers',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < attempt.answers.length; i++)
            if (byId[attempt.questionIds[i]] != null)
              QuestionReviewCard(
                number: i + 1,
                question: byId[attempt.questionIds[i]]!,
                selectedIndex: attempt.answers[i],
              ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => Get.offAllNamed(AppRoutes.home),
            icon: const Icon(Icons.home),
            label: const Text('Back to Home'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// The shareable result card. Wrapped in a RepaintBoundary so the
  /// "Share result" button can render exactly this card to a PNG.
  Widget _resultCard(BuildContext context, TestModel test, Attempt attempt) {
    final theme = Theme.of(context);
    final date = attempt.submittedAt ?? DateTime.now();
    return RepaintBoundary(
      key: _cardKey,
      child: Container(
        // A solid background so the shared PNG is never transparent.
        color: theme.colorScheme.surface,
        child: Card(
          color: theme.colorScheme.primaryContainer,
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppConfig.appName,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Student Result Card',
                  style: theme.textTheme.bodySmall,
                ),
                const Divider(height: 22),
                Text(
                  test.title,
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  attempt.roll.isEmpty
                      ? attempt.studentName
                      : '${attempt.studentName}  •  Roll: ${attempt.roll}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                Text(
                  '${attempt.percent.toStringAsFixed(1)}%',
                  style: theme.textTheme.displaySmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Score: ${formatScore(attempt.score)} / '
                  '${formatScore(attempt.total)}',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _chip(Icons.check_circle, 'Correct: ${attempt.correct}',
                        Colors.green),
                    _chip(Icons.cancel, 'Wrong: ${attempt.wrong}', Colors.red),
                    _chip(Icons.help_outline, 'Skipped: ${attempt.skipped}',
                        Colors.grey),
                    _chip(Icons.timer_outlined,
                        'Time: ${formatTimeUsed(attempt.timeUsedSec)}',
                        Colors.blueGrey),
                  ],
                ),
                const Divider(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Test code: ${test.code}',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      DateFormat('dd MMM yyyy').format(date),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }

  /// Renders the result card to PNG bytes, or null when capture is not
  /// possible (the caller then falls back to sharing text).
  Future<Uint8List?> _captureCardPng() async {
    try {
      final renderObject = _cardKey.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) return null;
      final image = await renderObject.toImage(pixelRatio: 3);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  /// Shares the result card as a PNG image; falls back to a text summary
  /// when the image capture or the file share itself fails.
  Future<void> _shareResult(TestModel test, Attempt attempt) async {
    if (_isSharing) return;
    setState(() {
      _isSharing = true;
    });
    final summary = '${attempt.studentName} scored '
        '${formatScore(attempt.score)}/${formatScore(attempt.total)} '
        '(${attempt.percent.toStringAsFixed(1)}%) in "${test.title}" '
        'on ${AppConfig.appName}.';
    try {
      final png = await _captureCardPng();
      if (png == null) {
        throw Exception('Result card capture failed');
      }
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[
            XFile.fromData(
              png,
              name: 'test-mindset-result.png',
              mimeType: 'image/png',
            ),
          ],
          text: summary,
          subject: 'My ${AppConfig.appName} result',
        ),
      );
    } catch (_) {
      // Image capture or image sharing failed: share the same result as
      // plain text instead, so the student can always share something.
      try {
        await SharePlus.instance.share(
          ShareParams(
            text: summary,
            subject: 'My ${AppConfig.appName} result',
          ),
        );
      } catch (e) {
        Get.snackbar('Share failed', AuthService.friendlyError(e));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }
}

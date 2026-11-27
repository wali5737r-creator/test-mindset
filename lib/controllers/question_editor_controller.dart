import 'dart:async';
import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';

import '../config/app_config.dart';
import '../models/question.dart';
import '../models/quiz_test.dart';
import '../services/auth_service.dart';
import '../services/test_service.dart';

/// Outcome of a CSV import, shown to the teacher as a summary.
class ImportResult {
  final int added;
  final int skipped;
  final List<String> problems;
  final String? fatalError;
  final bool cancelled;

  const ImportResult({
    this.added = 0,
    this.skipped = 0,
    this.problems = const <String>[],
    this.fatalError,
    this.cancelled = false,
  });

  String get summary {
    if (cancelled) return 'Import cancelled.';
    if (fatalError != null) return fatalError!;
    final base = 'Imported $added question(s).';
    if (skipped > 0) {
      return '$base Skipped $skipped row(s).';
    }
    return base;
  }
}

/// Backs the question list screen of one test: live question list,
/// delete, and CSV import.
///
/// Arguments: {'test': TestModel}.
class QuestionEditorController extends GetxController {
  final TestService _testService = Get.find<TestService>();

  TestModel? _test;
  TestModel get test => _test!;

  final questions = <Question>[].obs;
  final isLoading = true.obs;
  final isImporting = false.obs;

  StreamSubscription<List<Question>>? _subscription;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['test'] is TestModel) {
      _test = args['test'] as TestModel;
      _subscription = _testService.questionsStream(test.id).listen(
        (list) {
          questions.assignAll(list);
          isLoading.value = false;
        },
        onError: (_) {
          isLoading.value = false;
        },
      );
    } else {
      isLoading.value = false;
    }
  }

  bool get canAddMore => questions.length < AppConfig.maxQuestionsPerTest;

  /// Order value for the next manually added question.
  int get nextOrder => questions.isEmpty ? 0 : questions.last.order + 1;

  Future<void> deleteQuestion(Question question) async {
    try {
      await _testService.deleteQuestion(test.id, question.id);
      Get.snackbar('Deleted', 'Question has been deleted.');
    } catch (e) {
      Get.snackbar('Delete failed', AuthService.friendlyError(e));
    }
  }

  // ---------------------------------------------------------------------------
  // CSV import
  //
  // Expected columns (a header row with these names is skipped):
  //   question, optionA, optionB, optionC, optionD, correct, explanation
  // `correct` accepts A/B/C/D or 1/2/3/4. `explanation` is optional.
  // ---------------------------------------------------------------------------

  /// Opens the file picker, reads a .csv/.txt file and imports its rows.
  Future<void> importCsvFromFile() async {
    if (isImporting.value) return;
    if (!canAddMore) {
      Get.snackbar(
        'Test is full',
        'A test can have at most ${AppConfig.maxQuestionsPerTest} questions.',
      );
      return;
    }
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['csv', 'txt'],
    );
    if (picked.isEmpty) {
      return; // teacher cancelled the picker - not an error
    }
    final List<int> bytes;
    try {
      bytes = await picked.single.readAsBytes();
    } catch (_) {
      Get.snackbar(
        'Import failed',
        'Could not read that file. Please try again.',
      );
      return;
    }
    var content = utf8.decode(bytes, allowMalformed: true);
    if (content.startsWith('\uFEFF')) {
      content = content.substring(1); // strip byte-order mark
    }
    final result = await importCsvString(content);
    _showImportResult(result);
  }

  /// Parses CSV text and adds every valid row as a question.
  /// Kept separate from the file picker so it can be unit-tested.
  Future<ImportResult> importCsvString(String content) async {
    if (isImporting.value) {
      return const ImportResult(fatalError: 'An import is already running.');
    }
    isImporting.value = true;
    try {
      final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      List<List<dynamic>> rows;
      try {
        rows = const CsvToListConverter(
          shouldParseNumbers: false,
          eol: '\n',
        ).convert(normalized);
      } catch (_) {
        return const ImportResult(
          fatalError: 'That file could not be read as CSV. '
              'Check the format and try again.',
        );
      }

      var added = 0;
      var skipped = 0;
      final problems = <String>[];
      var order = nextOrder;
      var isFirstRow = true;

      for (final row in rows) {
        final cells =
            row.map((c) => c?.toString().trim() ?? '').toList(growable: false);

        // Skip completely blank lines.
        if (cells.every((c) => c.isEmpty)) {
          continue;
        }
        // Skip the header row.
        if (isFirstRow && cells.first.toLowerCase() == 'question') {
          isFirstRow = false;
          continue;
        }
        isFirstRow = false;

        if (questions.length + added >= AppConfig.maxQuestionsPerTest) {
          skipped++;
          problems.add(
            'Stopped at ${AppConfig.maxQuestionsPerTest} questions (test limit).',
          );
          break;
        }

        if (cells.length < 6) {
          skipped++;
          problems.add(
            'A row had only ${cells.length} column(s); 6 are needed.',
          );
          continue;
        }

        final text = cells[0];
        final options = <String>[cells[1], cells[2], cells[3], cells[4]];
        final correctIndex = _parseCorrect(cells[5]);
        final explanation = cells.length >= 7 ? cells[6] : '';

        if (text.isEmpty || options.any((o) => o.isEmpty)) {
          skipped++;
          problems.add('A row had an empty question or option.');
          continue;
        }
        if (correctIndex == null) {
          skipped++;
          problems.add(
            'A row had an invalid correct value "${cells[5]}" (use A-D or 1-4).',
          );
          continue;
        }

        await _testService.addQuestion(
          test.id,
          Question(
            id: '',
            text: text,
            options: options,
            correctIndex: correctIndex,
            explanation: explanation,
            order: order,
          ),
        );
        order++;
        added++;
      }

      return ImportResult(
        added: added,
        skipped: skipped,
        problems: problems,
      );
    } catch (e) {
      return ImportResult(fatalError: AuthService.friendlyError(e));
    } finally {
      isImporting.value = false;
    }
  }

  /// Accepts A/B/C/D (any case) or 1/2/3/4. Returns null when invalid.
  static int? _parseCorrect(String raw) {
    final value = raw.trim().toUpperCase();
    switch (value) {
      case 'A':
      case '1':
        return 0;
      case 'B':
      case '2':
        return 1;
      case 'C':
      case '3':
        return 2;
      case 'D':
      case '4':
        return 3;
      default:
        return null;
    }
  }

  void _showImportResult(ImportResult result) {
    if (result.fatalError != null) {
      Get.snackbar('Import failed', result.fatalError!);
      return;
    }
    var message = result.summary;
    if (result.problems.isNotEmpty) {
      message = '$message ${result.problems.first}';
    }
    Get.snackbar('CSV import', message);
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}

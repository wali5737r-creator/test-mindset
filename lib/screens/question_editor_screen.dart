import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/question.dart';
import '../models/quiz_test.dart';
import '../services/auth_service.dart';
import '../services/test_service.dart';
import '../widgets/loading_button.dart';

/// Add or edit one MCQ: question text, 4 options, one correct option,
/// optional explanation. Question text supports Urdu.
///
/// Arguments: {'test': TestModel, 'nextOrder': int} when adding,
///            {'test': TestModel, 'question': Question} when editing.
class QuestionEditorScreen extends StatefulWidget {
  const QuestionEditorScreen({super.key});

  @override
  State<QuestionEditorScreen> createState() => _QuestionEditorScreenState();
}

class _QuestionEditorScreenState extends State<QuestionEditorScreen> {
  late final TestModel _test;
  Question? _existing;
  int _nextOrder = 0;

  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers =
      List<TextEditingController>.generate(4, (_) => TextEditingController());
  final _explanationController = TextEditingController();

  int _correctIndex = 0;
  bool _isSaving = false;

  bool get _isEditing => _existing != null;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map) {
      _test = args['test'] as TestModel;
      if (args['question'] is Question) {
        _existing = args['question'] as Question;
        _questionController.text = _existing!.text;
        for (var i = 0; i < 4; i++) {
          _optionControllers[i].text = _existing!.options[i];
        }
        _explanationController.text = _existing!.explanation;
        _correctIndex = _existing!.correctIndex;
      }
      if (args['nextOrder'] is int) {
        _nextOrder = args['nextOrder'] as int;
      }
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    _explanationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final text = _questionController.text.trim();
    final options =
        _optionControllers.map((c) => c.text.trim()).toList(growable: false);
    if (text.isEmpty) {
      Get.snackbar('Question needed', 'Please write the question.');
      return;
    }
    if (options.any((o) => o.isEmpty)) {
      Get.snackbar('Options needed', 'Please fill all 4 options.');
      return;
    }

    setState(() {
      _isSaving = true;
    });
    try {
      final service = Get.find<TestService>();
      if (_isEditing) {
        await service.updateQuestion(
          _test.id,
          _existing!.copyWith(
            text: text,
            options: options,
            correctIndex: _correctIndex,
            explanation: _explanationController.text.trim(),
          ),
        );
        Get.snackbar('Saved', 'Question has been updated.');
      } else {
        await service.addQuestion(
          _test.id,
          Question(
            id: '',
            text: text,
            options: options,
            correctIndex: _correctIndex,
            explanation: _explanationController.text.trim(),
            order: _nextOrder,
          ),
        );
        Get.snackbar('Added', 'Question has been added.');
      }
      Get.back();
    } catch (e) {
      Get.snackbar('Save failed', AuthService.friendlyError(e));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Question' : 'Add Question'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _questionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Question *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Options - tap the circle to mark the correct answer',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  for (var i = 0; i < 4; i++) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _correctPicker(i),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _optionControllers[i],
                            decoration: InputDecoration(
                              labelText: 'Option ${'ABCD'[i]} *',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  TextField(
                    controller: _explanationController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Explanation (optional)',
                      hintText: 'Shown to students in the result review.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 22),
                  LoadingButton(
                    label: _isEditing ? 'Save Changes' : 'Add Question',
                    icon: Icons.save,
                    loading: _isSaving,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _correctPicker(int index) {
    final isCorrect = _correctIndex == index;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        setState(() {
          _correctIndex = index;
        });
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCorrect ? Colors.green : null,
          border: Border.all(
            color: isCorrect ? Colors.green : Colors.grey,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            'ABCD'[index],
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isCorrect ? Colors.white : null,
            ),
          ),
        ),
      ),
    );
  }
}

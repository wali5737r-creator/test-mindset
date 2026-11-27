import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../config/app_config.dart';
import '../models/quiz_test.dart';
import '../services/auth_service.dart';
import '../services/test_service.dart';

/// Shows the test code, with copy/share buttons.
/// Students need no login - just this code, entered in the app.
///
/// Arguments: {'test': TestModel}.
class ShareScreen extends StatefulWidget {
  const ShareScreen({super.key});

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  late TestModel _test;
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    _test = (args as Map)['test'] as TestModel;
  }

  String get _shareText =>
      'Take my test "${_test.title}" on ${AppConfig.appName}:\n'
      'Open the ${AppConfig.appName} app and enter this code: ${_test.code}\n'
      'No login needed.';

  Future<void> _publishNow() async {
    if (_isPublishing) return;
    setState(() {
      _isPublishing = true;
    });
    try {
      final updated = _test.copyWith(status: TestStatus.published);
      await Get.find<TestService>().updateTest(updated);
      setState(() {
        _test = updated;
      });
      Get.snackbar('Published', 'Students can now take this test.');
    } catch (e) {
      Get.snackbar('Publish failed', AuthService.friendlyError(e));
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
        });
      }
    }
  }

  void _copy(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    Get.snackbar('Copied', '$label copied to clipboard.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPublished = _test.status == TestStatus.published;
    return Scaffold(
      appBar: AppBar(title: const Text('Share Test')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _test.title,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  if (!isPublished)
                    Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            Text(
                              _test.status == TestStatus.closed
                                  ? 'This test is CLOSED. Students cannot '
                                      'take it until you publish it again.'
                                  : 'This test is still a DRAFT. Students '
                                      'cannot take it until you publish it.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            FilledButton.icon(
                              onPressed: _isPublishing ? null : _publishNow,
                              icon: const Icon(Icons.publish),
                              label: const Text('Publish Now'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'Test Code',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _test.code,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () => _copy(_test.code, 'Test code'),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Code'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () {
                      SharePlus.instance.share(
                        ShareParams(text: _shareText, subject: _test.title),
                      );
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Students open the app and enter this code - no account '
                    'or login is needed. They write their name, take the '
                    'timed test, and you see every result in your dashboard.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

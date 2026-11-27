import 'package:flutter/material.dart';

import '../config/app_config.dart';

/// Shown when Firebase has not been configured yet (or its init failed).
/// This is a friendly dead-end, not a crash: the app code is complete,
/// only the owner's Firebase project values are missing.
class SetupPendingScreen extends StatelessWidget {
  const SetupPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off,
                    size: 72,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${AppConfig.appName} - Setup Pending',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'The app is built and ready, but it is not connected '
                    'to Firebase yet, so logins and tests cannot work.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('What is left to do (one time, about 10 minutes):'),
                        SizedBox(height: 8),
                        Text('1. Create a free Firebase project.'),
                        Text('2. Register the Android app (package '
                            'com.muhammad.quizwala) and the Web app.'),
                        Text('3. Paste the project values into '
                            'lib/firebase_options.dart and set '
                            'isConfigured to true.'),
                        Text('4. Enable Email/Password sign-in and create '
                            'the Firestore database.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Full step-by-step instructions are in README.md '
                    '("Firebase setup").',
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

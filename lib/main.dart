import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'config/app_config.dart';
import 'controllers/auth_controller.dart';
import 'firebase_options.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'services/auth_service.dart';
import 'services/test_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var firebaseReady = false;
  if (DefaultFirebaseOptions.isConfigured) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      firebaseReady = true;
    } catch (_) {
      // Bad or missing config: fall through to the setup-pending screen
      // instead of crashing on a white/black screen.
      firebaseReady = false;
    }
  }

  if (firebaseReady) {
    Get.put<AuthService>(AuthService(), permanent: true);
    Get.put<TestService>(TestService(), permanent: true);
    Get.put<AuthController>(AuthController(), permanent: true);
  }

  runApp(TestMindsetApp(firebaseReady: firebaseReady));
}

class TestMindsetApp extends StatelessWidget {
  final bool firebaseReady;

  const TestMindsetApp({super.key, required this.firebaseReady});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0E7C66),
        ),
        useMaterial3: true,
      ),
      // When Firebase is ready, leave initialRoute unset so a student
      // link (/#/t/CODE) opened in the browser is honoured as the start
      // route; the plain root route is the splash/auth gate.
      initialRoute: firebaseReady ? null : AppRoutes.setupPending,
      getPages: AppPages.pages,
    );
  }
}

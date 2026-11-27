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

/// The app-wide premium palette (v1.7): deep navy + orange, matching
/// the app icon. Navy is the primary (AppBars, filled buttons),
/// orange the accent (progress, highlights, ticks).
abstract final class AppColors {
  static const Color navy = Color(0xFF0B2A4A);
  static const Color orange = Color(0xFFF97316);
  static const Color amber = Color(0xFFF59E0B);
  static const Color scaffold = Color(0xFFF7F8FA);
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
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.navy,
          primary: AppColors.navy,
          secondary: AppColors.orange,
          tertiary: AppColors.amber,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: AppColors.scaffold,
        appBarTheme: const AppBarThemeData(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          actionsIconTheme: IconThemeData(color: Colors.white),
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 1,
          shadowColor: Color(0x140B2A4A),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.navy,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.navy,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.navy,
            side: const BorderSide(color: Color(0x660B2A4A)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.navy),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.orange,
          linearTrackColor: Color(0x1F0B2A4A),
          circularTrackColor: Color(0x1F0B2A4A),
        ),
        inputDecorationTheme: InputDecorationThemeData(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD5DBE3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD5DBE3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.navy, width: 1.6),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
        dialogTheme: const DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: AppColors.navy,
          contentTextStyle: TextStyle(color: Colors.white),
        ),
        dividerTheme: const DividerThemeData(color: Color(0xFFE3E8EF)),
        listTileTheme: const ListTileThemeData(iconColor: AppColors.navy),
      ),
      // When Firebase is ready, leave initialRoute unset so a student
      // link (/#/t/CODE) opened in the browser is honoured as the start
      // route; the plain root route is the splash/auth gate.
      initialRoute: firebaseReady ? null : AppRoutes.setupPending,
      getPages: AppPages.pages,
    );
  }
}

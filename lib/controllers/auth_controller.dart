import 'package:get/get.dart';

import '../routes/app_routes.dart';
import '../services/auth_service.dart';

/// Drives the login / register / forgot-password screens.
/// Registered permanently in main.dart so every screen can find it.
class AuthController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();

  final isLoading = false.obs;

  AuthService get auth => _auth;

  Future<void> login({required String email, required String password}) async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      await _auth.login(email: email, password: password);
      Get.offAllNamed(AppRoutes.dashboard);
    } catch (e) {
      Get.snackbar('Login failed', AuthService.friendlyError(e));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register({
    required String name,
    required String institute,
    required String email,
    required String password,
  }) async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      await _auth.register(
        name: name,
        institute: institute,
        email: email,
        password: password,
      );
      Get.offAllNamed(AppRoutes.dashboard);
    } catch (e) {
      Get.snackbar('Registration failed', AuthService.friendlyError(e));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signInWithGoogle() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final signedIn = await _auth.signInWithGoogle();
      if (!signedIn) {
        // User cancelled the Google account picker - stay put, no error.
        return;
      }
      Get.offAllNamed(AppRoutes.dashboard);
    } catch (e) {
      Get.snackbar('Google sign-in failed', AuthService.friendlyError(e));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetPassword(String email) async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      await _auth.sendPasswordReset(email);
      Get.snackbar(
        'Email sent',
        'If an account exists for this email, a password reset link has '
            'been sent to it.',
      );
      Get.back();
    } catch (e) {
      Get.snackbar('Could not send email', AuthService.friendlyError(e));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _auth.logout();
    Get.offAllNamed(AppRoutes.home);
  }
}

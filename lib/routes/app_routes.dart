/// Route names for GetX navigation. Constants only - the page wiring
/// lives in app_pages.dart.
class AppRoutes {
  AppRoutes._();

  /// Splash / auth gate (decides home vs dashboard).
  static const String splash = '/';
  static const String setupPending = '/setup-pending';

  /// Landing page: students enter a test code, teachers go to login.
  static const String home = '/home';

  // Teacher auth
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Teacher area (all behind AuthMiddleware)
  static const String dashboard = '/dashboard';
  static const String testEditor = '/test-editor';
  static const String questionList = '/questions';
  static const String questionEditor = '/question-editor';
  static const String share = '/share';
  static const String results = '/results';
  static const String attemptDetail = '/attempt-detail';

  // Student flow (no login)
  /// Student link route, e.g. /t/AB3K9Z
  static const String studentIntro = '/t/:code';
  static const String takeTest = '/take-test';
  static const String studentResult = '/student-result';

  static String studentIntroPath(String code) => '/t/$code';
}

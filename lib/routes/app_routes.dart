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

  // Learning Mode (no login, fully offline, bundled content)
  static const String learn = '/learn';
  static const String learnEnglish = '/learn/english';
  static const String learnPakistan = '/learn/pakistan';
  static const String learnLesson = '/learn/lesson';
  static const String learnTopic = '/learn/topic';
  static const String learnQuiz = '/learn/quiz';
  static const String learnMap = '/learn/map';

  /// Generic topic portion (arguments: portion id string — 'world',
  /// 'space', 'computer', 'urdu', 'islamiat', 'history', 'orgs',
  /// 'eds').
  static const String learnPortion = '/learn/portion';

  /// Generic lesson-list portion (arguments: portion id — 'maths').
  static const String learnLessons = '/learn/lessons';

  /// World map (pins + Map Quiz, equirectangular world image).
  static const String learnWorldMap = '/learn/world-map';

  static String studentIntroPath(String code) => '/t/$code';
}

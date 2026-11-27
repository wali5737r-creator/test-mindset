/// Central app configuration.
///
/// The app name lives ONLY here (plus the Android launcher label) so the
/// owner can rename the app from one place.
class AppConfig {
  AppConfig._();

  /// Working app name. Rename the app by changing this one value
  /// (and the Android label in AndroidManifest.xml).
  static const String appName = 'Test Mindset';

  static const String appTagline =
      'Create a test, share one link. Students take it with no login.';

  // ---------------------------------------------------------------------------
  // Firestore layout (see docs/SRS.md section 6)
  // ---------------------------------------------------------------------------
  static const String teachersCollection = 'teachers';
  static const String testsCollection = 'tests';
  static const String questionsSubcollection = 'questions';
  static const String attemptsSubcollection = 'attempts';

  // ---------------------------------------------------------------------------
  // Limits / rules
  // ---------------------------------------------------------------------------

  /// Length of the short code students type to join a test.
  static const int testCodeLength = 6;

  /// Maximum questions allowed in one test.
  static const int maxQuestionsPerTest = 200;

  /// Base URL of the deployed web build, used to build student links.
  ///
  /// TODO(owner): after the web build is deployed (Cloudflare Pages),
  /// replace this with the real domain, e.g. https://testmindset.pages.dev
  static const String webBaseUrl = 'https://testmindset.pages.dev';

  /// The shareable student link for a test code, e.g.
  /// https://testmindset.pages.dev/#/t/AB3K9Z
  static String studentLinkFor(String code) => '$webBaseUrl/#/t/$code';
}

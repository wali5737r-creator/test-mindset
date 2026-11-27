import 'package:get/get.dart';

import '../controllers/dashboard_controller.dart';
import '../learning/screens/english_subject_screen.dart';
import '../learning/screens/learn_home_screen.dart';
import '../learning/screens/lesson_screen.dart';
import '../learning/screens/map_screen.dart';
import '../learning/screens/pakistan_subject_screen.dart';
import '../learning/screens/practice_quiz_screen.dart';
import '../learning/screens/topic_screen.dart';
import '../controllers/question_editor_controller.dart';
import '../controllers/results_controller.dart';
import '../controllers/take_test_controller.dart';
import '../controllers/test_editor_controller.dart';
import '../screens/attempt_detail_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/question_editor_screen.dart';
import '../screens/question_list_screen.dart';
import '../screens/register_screen.dart';
import '../screens/setup_pending_screen.dart';
import '../screens/share_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/student_intro_screen.dart';
import '../screens/student_result_screen.dart';
import '../screens/take_test_screen.dart';
import '../screens/teacher_results_screen.dart';
import '../screens/test_editor_screen.dart';
import 'app_routes.dart';
import 'auth_middleware.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
  }
}

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardController>(() => DashboardController());
  }
}

class TestEditorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TestEditorController>(() => TestEditorController());
  }
}

class QuestionEditorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<QuestionEditorController>(() => QuestionEditorController());
  }
}

class ResultsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ResultsController>(() => ResultsController());
  }
}

class StudentIntroBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StudentIntroController>(() => StudentIntroController());
  }
}

class TakeTestBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TakeTestController>(() => TakeTestController());
  }
}

class LearnHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LearnHomeController>(() => LearnHomeController());
  }
}

class EnglishSubjectBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EnglishSubjectController>(() => EnglishSubjectController());
  }
}

class PakistanSubjectBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PakistanSubjectController>(() => PakistanSubjectController());
  }
}

class LessonBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LessonController>(() => LessonController());
  }
}

class TopicBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TopicController>(() => TopicController());
  }
}

class PracticeQuizBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PracticeQuizController>(() => PracticeQuizController());
  }
}

class MapBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MapController>(() => MapController());
  }
}

/// All GetX pages. Teacher pages carry [AuthMiddleware]; student pages
/// deliberately do not - the student flow works with no login.
class AppPages {
  AppPages._();

  static final List<GetPage> pages = <GetPage>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: AppRoutes.setupPending,
      page: () => const SetupPendingScreen(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterScreen(),
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordScreen(),
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardScreen(),
      binding: DashboardBinding(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.testEditor,
      page: () => const TestEditorScreen(),
      binding: TestEditorBinding(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.questionList,
      page: () => const QuestionListScreen(),
      binding: QuestionEditorBinding(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.questionEditor,
      page: () => const QuestionEditorScreen(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.share,
      page: () => const ShareScreen(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.results,
      page: () => const TeacherResultsScreen(),
      binding: ResultsBinding(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.attemptDetail,
      page: () => const AttemptDetailScreen(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.studentIntro,
      page: () => const StudentIntroScreen(),
      binding: StudentIntroBinding(),
    ),
    GetPage(
      name: AppRoutes.takeTest,
      page: () => const TakeTestScreen(),
      binding: TakeTestBinding(),
    ),
    GetPage(
      name: AppRoutes.studentResult,
      page: () => const StudentResultScreen(),
    ),
    // Learning Mode pages deliberately carry NO AuthMiddleware -
    // learning works with no login, like the student flow.
    GetPage(
      name: AppRoutes.learn,
      page: () => const LearnHomeScreen(),
      binding: LearnHomeBinding(),
    ),
    GetPage(
      name: AppRoutes.learnEnglish,
      page: () => const EnglishSubjectScreen(),
      binding: EnglishSubjectBinding(),
    ),
    GetPage(
      name: AppRoutes.learnPakistan,
      page: () => const PakistanSubjectScreen(),
      binding: PakistanSubjectBinding(),
    ),
    GetPage(
      name: AppRoutes.learnLesson,
      page: () => const LessonScreen(),
      binding: LessonBinding(),
    ),
    GetPage(
      name: AppRoutes.learnTopic,
      page: () => const TopicScreen(),
      binding: TopicBinding(),
    ),
    GetPage(
      name: AppRoutes.learnQuiz,
      page: () => const PracticeQuizScreen(),
      binding: PracticeQuizBinding(),
    ),
    GetPage(
      name: AppRoutes.learnMap,
      page: () => const MapScreen(),
      binding: MapBinding(),
    ),
  ];
}

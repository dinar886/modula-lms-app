import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:modula_lms/app/scaffold_with_nav_bar.dart';
import 'package:modula_lms/features/1_auth/presentation/bloc/authentication_bloc.dart';
import 'package:modula_lms/features/1_auth/presentation/pages/login_page.dart';
import 'package:modula_lms/features/1_auth/presentation/pages/register_page.dart';
import 'package:modula_lms/features/2_marketplace/domain/entities/course_entity.dart';
import 'package:modula_lms/features/2_marketplace/presentation/pages/course_detail_page.dart';
import 'package:modula_lms/features/2_marketplace/presentation/pages/course_list_page.dart';
import 'package:modula_lms/features/3_learner_space/presentation/pages/my_courses_page.dart';
import 'package:modula_lms/features/4_instructor_space/presentation/pages/course_editor_page.dart';
import 'package:modula_lms/features/4_instructor_space/presentation/pages/course_info_editor_page.dart'; // Ajout
import 'package:modula_lms/features/4_instructor_space/presentation/pages/create_course_page.dart';
import 'package:modula_lms/features/4_instructor_space/presentation/pages/lesson_editor_page.dart';
import 'package:modula_lms/features/4_instructor_space/presentation/pages/quiz_editor_page.dart';
import 'package:modula_lms/features/course_player/presentation/pages/course_player_page.dart';
import 'package:modula_lms/features/course_player/presentation/pages/lesson_viewer_page.dart';
import 'package:modula_lms/features/course_player/presentation/pages/quiz_page.dart';
import 'package:modula_lms/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:modula_lms/features/shared/profile/presentation/pages/profile_page.dart';

class AppRouter {
  static GoRouter buildRouter(BuildContext context) {
    final authBloc = context.read<AuthenticationBloc>();

    return GoRouter(
      initialLocation: '/marketplace',
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      routes: [
        // ... (autres routes inchangées)
        ShellRoute(
          builder: (context, state, child) => ScaffoldWithNavBar(child: child),
          routes: [
            GoRoute(
              path: '/marketplace',
              builder: (context, state) => const CourseListPage(),
              routes: [
                GoRoute(
                  path: 'course/:id',
                  builder: (context, state) {
                    final courseId = state.pathParameters['id']!;
                    return CourseDetailPage(courseId: courseId);
                  },
                ),
              ],
            ),
            GoRoute(
              path: '/my-courses',
              builder: (context, state) => const MyCoursesPage(),
            ),
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardPage(),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
        GoRoute(
          path: '/course-player',
          builder: (context, state) {
            final course = state.extra as CourseEntity;
            return CoursePlayerPage(course: course);
          },
        ),
        GoRoute(
          path: '/lesson-viewer/:id',
          builder: (context, state) {
            final lessonId = int.parse(state.pathParameters['id']!);
            return LessonViewerPage(lessonId: lessonId);
          },
        ),
        GoRoute(
          path: '/quiz/:id',
          builder: (context, state) {
            final lessonId = int.parse(state.pathParameters['id']!);
            return QuizPage(lessonId: lessonId);
          },
        ),
        GoRoute(
          path: '/create-course',
          builder: (context, state) => const CreateCoursePage(),
        ),
        GoRoute(
          path: '/course-editor',
          builder: (context, state) {
            final course = state.extra as CourseEntity;
            return CourseEditorPage(course: course);
          },
        ),
        // Nouvelle route pour l'éditeur d'informations
        GoRoute(
          path: '/course-info-editor',
          builder: (context, state) {
            final course = state.extra as CourseEntity;
            return CourseInfoEditorPage(course: course);
          },
        ),
        GoRoute(
          path: '/lesson-editor/:id',
          builder: (context, state) {
            final lessonId = int.parse(state.pathParameters['id']!);
            return LessonEditorPage(lessonId: lessonId);
          },
        ),
        GoRoute(
          path: '/quiz-editor/:id',
          builder: (context, state) {
            final lessonId = int.parse(state.pathParameters['id']!);
            return QuizEditorPage(lessonId: lessonId);
          },
        ),
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterPage(),
        ),
      ],
      redirect: (context, state) {
        final bool loggedIn = authBloc.state.user.isNotEmpty;
        final bool isLoggingIn =
            state.uri.path == '/login' || state.uri.path == '/register';
        final protectedRoutes = [
          '/profile',
          '/my-courses',
          '/dashboard',
          '/course-player',
          '/lesson-viewer',
          '/create-course',
          '/course-editor',
          '/course-info-editor', // Ajout de la nouvelle route protégée
          '/lesson-editor',
          '/quiz',
          '/quiz-editor',
        ];

        if (!loggedIn &&
            protectedRoutes.any((route) => state.uri.path.startsWith(route))) {
          return '/login';
        }
        if (loggedIn && isLoggingIn) {
          return '/profile';
        }
        return null;
      },
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// lib/app/config/routes/app_router.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:modula_lms/app/scaffold_with_nav_bar.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart';
import 'package:modula_lms/features/1_auth/login_page.dart';
import 'package:modula_lms/features/1_auth/register_page.dart';
import 'package:modula_lms/features/2_marketplace/marketplace_logic.dart';
import 'package:modula_lms/features/2_marketplace/marketplace_page.dart';
import 'package:modula_lms/features/3_learner_space/my_courses_page.dart';
import 'package:modula_lms/features/4_instructor_space/course_editor_page.dart';
import 'package:modula_lms/features/4_instructor_space/course_info_editor_page.dart';
import 'package:modula_lms/features/4_instructor_space/create_course_page.dart';
import 'package:modula_lms/features/4_instructor_space/instructor_courses_page.dart';
import 'package:modula_lms/features/4_instructor_space/lesson_editor_page.dart';
import 'package:modula_lms/features/4_instructor_space/quiz_editor_page.dart';
import 'package:modula_lms/features/4_instructor_space/student_details_page.dart';
import 'package:modula_lms/features/4_instructor_space/students_page.dart';
import 'package:modula_lms/features/4_instructor_space/submissions_page.dart';
import 'package:modula_lms/features/course_player/course_player_page.dart';
import 'package:modula_lms/features/course_player/lesson_viewer_page.dart';
import 'package:modula_lms/features/course_player/quiz_page.dart';
import 'package:modula_lms/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:modula_lms/features/shared/profile_page.dart';
// NOUVEAU: Importation de la nouvelle page
import 'package:modula_lms/features/shared/pdf_viewer_page.dart';

class AppRouter {
  static GoRouter buildRouter(BuildContext context) {
    final authBloc = context.read<AuthenticationBloc>();

    return GoRouter(
      initialLocation: '/marketplace',
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      routes: [
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
        // NOUVEAU: Déclaration de la route pour le visualiseur PDF.
        GoRoute(
          path: '/pdf-viewer',
          builder: (context, state) {
            // On s'attend à recevoir l'URL et le titre en paramètres 'extra'.
            final params = state.extra as Map<String, String>;
            final pdfUrl = params['url']!;
            final title = params['title']!;
            return PdfViewerPage(pdfUrl: pdfUrl, documentTitle: title);
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
        GoRoute(
          path: '/course-info-editor',
          builder: (context, state) {
            final course = state.extra as CourseEntity;
            return CourseInfoEditorPage(course: course);
          },
        ),
        GoRoute(
          path: '/lesson-editor/:lessonId/section/:sectionId',
          builder: (context, state) {
            final lessonId = int.parse(state.pathParameters['lessonId']!);
            final sectionId = int.parse(state.pathParameters['sectionId']!);

            return LessonEditorPage(lessonId: lessonId, sectionId: sectionId);
          },
        ),
        GoRoute(
          path: '/quiz-editor/:id',
          builder: (context, state) {
            final quizId = int.parse(state.pathParameters['id']!);
            return QuizEditorPage(quizId: quizId);
          },
        ),
        GoRoute(
          path: '/instructor-courses',
          builder: (context, state) => const InstructorCoursesPage(),
        ),
        GoRoute(
          path: '/students',
          builder: (context, state) => const StudentsPage(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final studentId = state.pathParameters['id']!;
                return StudentDetailsPage(studentId: studentId);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/submissions',
          builder: (context, state) => const SubmissionsPage(),
        ),
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterPage(),
        ),
      ],
      redirect: (context, state) {
        final authState = authBloc.state;
        final loggedIn = authState.user.isNotEmpty;
        final isAccessingAuthPages =
            state.uri.path == '/login' || state.uri.path == '/register';

        // On ajoute la nouvelle route à la liste des routes protégées.
        const protectedRoutes = [
          '/my-courses',
          '/dashboard',
          '/profile',
          '/course-player',
          '/lesson-viewer',
          '/pdf-viewer', // Ajout ici
          '/quiz',
          '/create-course',
          '/course-editor',
          '/course-info-editor',
          '/lesson-editor',
          '/quiz-editor',
          '/instructor-courses',
          '/students',
          '/submissions',
        ];

        if (!loggedIn &&
            protectedRoutes.any((route) => state.uri.path.startsWith(route))) {
          return '/login';
        }

        if (loggedIn && isAccessingAuthPages) {
          return '/profile';
        }

        return null;
      },
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

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
import 'package:modula_lms/features/3_learner_space/my_submissions_page.dart';
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
// Importation de la page du visualiseur PDF
import 'package:modula_lms/features/shared/pdf_viewer_page.dart';

class AppRouter {
  // Cette méthode statique construit et configure l'instance de GoRouter.
  static GoRouter buildRouter(BuildContext context) {
    // Le routeur a besoin d'accéder au BLoC d'authentification pour gérer les redirections.
    final authBloc = context.read<AuthenticationBloc>();

    return GoRouter(
      // La route initiale de l'application.
      initialLocation: '/marketplace',
      // Le routeur écoute les changements d'état du BLoC d'authentification pour se rafraîchir.
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      // Définition de toutes les routes de l'application.
      routes: [
        // ShellRoute définit l'interface principale avec la barre de navigation.
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
            // NOUVELLE ROUTE : Les rendus de l'élève
            GoRoute(
              path: '/my-submissions',
              builder: (context, state) => const MySubmissionsPage(),
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
            // On récupère l'ID du cours passé en paramètre
            final courseId = state.extra as String;
            // CORRECTION : Le constructeur de LessonViewerPage accepte maintenant les deux paramètres.
            return LessonViewerPage(lessonId: lessonId, courseId: courseId);
          },
        ),
        GoRoute(
          path: '/pdf-viewer',
          builder: (context, state) {
            final params = state.extra as Map<String, dynamic>;
            final pdfUrl = params['url'] as String;
            final title = params['title'] as String;
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
      // Logique de redirection pour gérer l'authentification.
      redirect: (context, state) {
        final authState = authBloc.state;
        final loggedIn = authState.user.isNotEmpty;
        final isAccessingAuthPages =
            state.uri.path == '/login' || state.uri.path == '/register';

        // Liste des routes qui nécessitent que l'utilisateur soit connecté.
        const protectedRoutes = [
          '/my-courses',
          '/dashboard',
          '/profile',
          '/my-submissions',
          '/course-player',
          '/lesson-viewer',
          '/pdf-viewer',
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

        // Si l'utilisateur n'est pas connecté et essaie d'accéder à une page protégée, on le redirige vers le login.
        if (!loggedIn &&
            protectedRoutes.any((route) => state.uri.path.startsWith(route))) {
          return '/login';
        }

        // Si l'utilisateur est connecté et essaie d'aller sur les pages de login/register, on le redirige vers son profil.
        if (loggedIn && isAccessingAuthPages) {
          return '/profile';
        }

        // Sinon, on ne fait rien.
        return null;
      },
    );
  }
}

// Cette classe permet à GoRouter de réagir aux changements d'état du BLoC d'authentification.
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

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

/// Classe de configuration pour le routeur de l'application.
/// Elle utilise GoRouter pour définir toutes les routes disponibles.
class AppRouter {
  /// Construit l'instance du routeur GoRouter.
  /// Cette méthode statique est appelée au démarrage de l'application.
  static GoRouter buildRouter(BuildContext context) {
    // Récupère le BLoC d'authentification pour gérer la redirection.
    final authBloc = context.read<AuthenticationBloc>();

    return GoRouter(
      // La route initiale de l'application.
      initialLocation: '/marketplace',
      // 'refreshListenable' permet au routeur de réagir aux changements d'état
      // d'authentification pour appliquer les redirections.
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      routes: [
        // 'ShellRoute' est utilisée pour les routes qui partagent une interface commune,
        // ici, le 'ScaffoldWithNavBar' qui affiche la barre de navigation.
        ShellRoute(
          builder: (context, state, child) => ScaffoldWithNavBar(child: child),
          routes: [
            // Route pour la place de marché (Marketplace).
            GoRoute(
              path: '/marketplace',
              builder: (context, state) => const CourseListPage(),
              routes: [
                // Route imbriquée pour afficher les détails d'un cours.
                GoRoute(
                  path: 'course/:id',
                  builder: (context, state) {
                    final courseId = state.pathParameters['id']!;
                    return CourseDetailPage(courseId: courseId);
                  },
                ),
              ],
            ),
            // Route pour la page "Mes Cours" de l'apprenant.
            GoRoute(
              path: '/my-courses',
              builder: (context, state) => const MyCoursesPage(),
            ),
            // Route pour le tableau de bord.
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardPage(),
            ),
            // Route pour la page de profil de l'utilisateur.
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
        // Routes qui s'affichent par-dessus la barre de navigation.
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
        // **ROUTE CORRIGÉE**
        // La route pour que l'étudiant passe le quiz.
        // On s'assure que le chemin est bien '/quiz/:id'.
        GoRoute(
          path: '/quiz/:id',
          builder: (context, state) {
            final lessonId = int.parse(state.pathParameters['id']!);
            return QuizPage(lessonId: lessonId);
          },
        ),
        // Routes pour l'espace instructeur.
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
          path: '/lesson-editor/:id',
          builder: (context, state) {
            final lessonId = int.parse(state.pathParameters['id']!);
            final sectionId = state.extra as int?;

            if (sectionId == null) {
              return const Scaffold(
                body: Center(
                  child: Text("Erreur : ID de la section manquant."),
                ),
              );
            }
            return LessonEditorPage(lessonId: lessonId, sectionId: sectionId);
          },
        ),
        // La route pour que l'instructeur édite le quiz.
        GoRoute(
          path: '/quiz-editor/:id',
          builder: (context, state) {
            final lessonId = int.parse(state.pathParameters['id']!);
            return QuizEditorPage(lessonId: lessonId);
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
            // Route imbriquée pour les détails d'un étudiant.
            GoRoute(
              path: ':id', // exemple: /students/123
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
        // Routes d'authentification.
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterPage(),
        ),
      ],
      // Logique de redirection pour protéger les routes.
      redirect: (context, state) {
        final authState = authBloc.state;
        final loggedIn = authState.user.isNotEmpty;
        final isAccessingAuthPages =
            state.uri.path == '/login' || state.uri.path == '/register';

        // Liste de toutes les routes qui nécessitent une authentification.
        const protectedRoutes = [
          '/my-courses',
          '/dashboard',
          '/profile',
          '/course-player',
          '/lesson-viewer',
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

        // Si l'utilisateur n'est pas connecté et essaie d'accéder à une page protégée,
        // il est redirigé vers la page de connexion.
        if (!loggedIn &&
            protectedRoutes.any((route) => state.uri.path.startsWith(route))) {
          return '/login';
        }

        // Si l'utilisateur est déjà connecté et essaie d'accéder aux pages de
        // connexion ou d'inscription, il est redirigé vers son profil.
        if (loggedIn && isAccessingAuthPages) {
          return '/profile';
        }

        // Aucune redirection nécessaire dans les autres cas.
        return null;
      },
    );
  }
}

/// Un `ChangeNotifier` qui écoute un `Stream` et notifie ses auditeurs à chaque
/// nouvel événement. C'est le mécanisme qui permet à GoRouter de réagir aux
// changements d'état (comme la connexion ou la déconnexion).
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

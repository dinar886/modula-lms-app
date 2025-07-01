// lib/app/config/routes/app_router.dart

import 'package:go_router/go_router.dart';
import 'package:modula_lms/features/1_auth/presentation/pages/login_page.dart';
import 'package:modula_lms/features/2_marketplace/presentation/pages/course_list_page.dart';

class AppRouter {
  // Crée l'instance du routeur.
  static final GoRouter router = GoRouter(
    // URL initiale de l'application.
    initialLocation: '/marketplace',

    // Définit toutes les routes de l'application.
    routes: [
      // Route pour la page de connexion
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),

      // Route pour le catalogue de cours (la place de marché)
      GoRoute(
        path: '/marketplace',
        builder: (context, state) => const CourseListPage(),
        routes: [
          // Ceci est une sous-route. Par exemple, pour voir les détails d'un cours.
          // L'URL serait '/marketplace/course/123'
          GoRoute(
            path: 'course/:id', // ':id' est un paramètre dynamique
            builder: (context, state) {
              final courseId = state.pathParameters['id']!;
              // Vous créerez cette page plus tard.
              // return CourseDetailPage(courseId: courseId);
              return const CourseListPage(); // Placeholder
            },
          ),
        ],
      ),
    ],

    // Vous pourrez ajouter ici une logique de redirection.
    // Par exemple, si l'utilisateur n'est pas connecté, le rediriger vers /login.
    // redirect: (context, state) { ... }
  );
}

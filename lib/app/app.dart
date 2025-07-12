// lib/app/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/app/config/routes/app_router.dart';
import 'package:modula_lms/app/config/theme/app_theme.dart';
import 'package:modula_lms/core/di/service_locator.dart';
// NOUVEL IMPORT qui regroupe Repository et BLoC d'authentification
import 'package:modula_lms/features/1_auth/auth_feature.dart';
// NOUVEAUX IMPORTS
import 'package:firebase_messaging/firebase_messaging.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // On utilise RepositoryProvider pour fournir le AuthenticationRepository...
    return RepositoryProvider.value(
      value: sl<AuthenticationRepository>(),
      // ...et BlocProvider pour fournir l'AuthenticationBloc à toute l'application.
      child: BlocProvider(
        create: (_) => sl<AuthenticationBloc>(),
        child: const AppView(),
      ),
    );
  }
}

// On sépare la vue pour pouvoir accéder facilement au contexte avec le Bloc et le Router.
class AppView extends StatefulWidget {
  const AppView({super.key});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  @override
  void initState() {
    super.initState();
    // Configure le listener pour les messages reçus lorsque l'application est en avant-plan.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Message reçu en avant-plan!');
      print('Données du message: ${message.data}');

      if (message.notification != null) {
        print('Le message contenait une notification: ${message.notification}');

        // Affiche une SnackBar pour informer l'utilisateur.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message.notification!.title ?? 'Nouvelle notification',
            ),
            action: SnackBarAction(
              label: 'VOIR',
              onPressed: () {
                // Ici, vous pouvez ajouter une logique pour naviguer vers un écran spécifique
                // en utilisant les données du message (`message.data`).
              },
            ),
          ),
        );
      }
    });

    // Gère le cas où l'utilisateur clique sur une notification
    // alors que l'application est terminée ou en arrière-plan.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message ouvert depuis une notification: ${message.messageId}');
      // Ici, vous pouvez naviguer vers un écran spécifique.
      // Par exemple, si `message.data['screen']` contient '/chat', vous pouvez faire :
      // context.go(message.data['screen']);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // On passe maintenant le router construit dynamiquement.
      routerConfig: AppRouter.buildRouter(context),
    );
  }
}

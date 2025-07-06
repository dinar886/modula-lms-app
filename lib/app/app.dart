// lib/app/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/app/config/routes/app_router.dart';
import 'package:modula_lms/app/config/theme/app_theme.dart';
import 'package:modula_lms/core/di/service_locator.dart';
// NOUVEL IMPORT qui regroupe Repository et BLoC d'authentification
import 'package:modula_lms/features/1_auth/auth_feature.dart';

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
class AppView extends StatelessWidget {
  const AppView({super.key});

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

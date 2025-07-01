// lib/app/app.dart

import 'package:flutter/material.dart';
import 'package:modula_lms/app/config/routes/app_router.dart';
import 'package:modula_lms/app/config/theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp.router est utilisé pour intégrer un routeur comme go_router.
    return MaterialApp.router(
      // Désactive la bannière de debug en haut à droite.
      debugShowCheckedModeBanner: false,

      // Applique le thème global défini dans app_theme.dart.
      theme: AppTheme.lightTheme,
      // Vous pouvez aussi définir un darkTheme: AppTheme.darkTheme,

      // Fournit la configuration de la navigation à l'application.
      routerConfig: AppRouter.router,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/app/app.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart';

// La fonction main redevient synchrone, car nous n'utilisons plus await.
void main() {
  // On s'assure que les services de la plateforme sont prêts. C'est correct.
  WidgetsFlutterBinding.ensureInitialized();

  // CORRECTION 1 : On appelle `setupLocator` sans `await`, car elle retourne 'void'.
  setupLocator();

  // CORRECTION 2 : On insère le BlocProvider à la racine de l'application
  // pour qu'il soit disponible partout, y compris dans le routeur.
  runApp(
    BlocProvider(
      // CORRECTION 3 : On crée le BLoC sans lui ajouter d'événement `AppStarted`.
      // Le BLoC se chargera lui-même de son état initial à sa création.
      create: (context) => sl<AuthenticationBloc>(),
      child: const App(), // Ton widget `App` est maintenant un enfant du BLoC.
    ),
  );
}

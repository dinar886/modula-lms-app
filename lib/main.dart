// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // NOUVEL IMPORT
import 'package:modula_lms/app/app.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart';

// La fonction main doit maintenant être 'async' pour pouvoir attendre
// le chargement des variables d'environnement.
Future<void> main() async {
  // Assure que les bindings Flutter sont prêts avant d'exécuter du code asynchrone.
  WidgetsFlutterBinding.ensureInitialized();

  // Charge les variables d'environnement depuis le fichier .env à la racine du projet.
  await dotenv.load(fileName: ".env");

  // Initialisation de Stripe avec la clé qui a été chargée depuis le fichier .env.
  // La variable est récupérée via `dotenv.env['NOM_DE_LA_VARIABLE']`.
  // Le '!' à la fin assure à Dart que la valeur ne sera pas nulle (sinon, l'app crashera, ce qui est souhaitable si la clé manque).
  Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY']!;

  // Initialise le service locator pour l'injection de dépendances.
  setupLocator();

  // Lance l'application Flutter.
  runApp(
    BlocProvider(
      create: (context) => sl<AuthenticationBloc>(),
      child: const App(),
    ),
  );
}

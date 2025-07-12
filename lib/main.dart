// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:modula_lms/app/app.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart';
// NOUVEAUX IMPORTS
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Ce fichier est généré par `flutterfire configure`

// Ce gestionnaire doit être une fonction de haut niveau (en dehors d'une classe).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Si vous utilisez d'autres services Firebase en arrière-plan (ex: Analytics),
  // vous devez vous assurer qu'ils sont initialisés avant de les utiliser.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print("Un message a été reçu en arrière-plan: ${message.messageId}");
  // Ici, vous pouvez gérer la notification, par exemple, en affichant une notification locale.
}

// La fonction main doit maintenant être 'async' pour pouvoir attendre
// le chargement des variables d'environnement et l'initialisation des services.
Future<void> main() async {
  // Assure que les bindings Flutter sont prêts avant d'exécuter du code asynchrone.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Firebase. C'est la première chose à faire.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Configure le gestionnaire pour les messages reçus lorsque l'app est en arrière-plan ou terminée.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Charge les variables d'environnement depuis le fichier .env à la racine du projet.
  await dotenv.load(fileName: ".env");

  // Initialisation de Stripe avec la clé qui a été chargée depuis le fichier .env.
  Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY']!;

  // MISE À JOUR : Initialise le service locator de manière asynchrone.
  await setupLocator();

  // Lance l'application Flutter.
  runApp(
    BlocProvider.value(
      value: sl<AuthenticationBloc>(),
      child: BlocListener<AuthenticationBloc, AuthenticationState>(
        // Ce listener va écouter les changements d'état d'authentification globaux.
        listener: (context, state) {
          // Si l'utilisateur est authentifié...
          if (state.user.isNotEmpty) {
            // ...on lance la mise à jour du token FCM.
            // On peut appeler la méthode directement depuis le repository.
            sl<AuthenticationRepository>().updateFcmToken(state.user.id);
          }
        },
        child: const App(),
      ),
    ),
  );
}

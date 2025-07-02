import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/features/1_auth/presentation/bloc/authentication_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // On écoute l'état de notre AuthenticationBloc global.
    final authState = context.watch<AuthenticationBloc>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          // On affiche un bouton de déconnexion seulement si l'utilisateur est connecté.
          if (authState.user.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                // On envoie l'événement de déconnexion.
                context.read<AuthenticationBloc>().add(
                  AuthenticationLogoutRequested(),
                );
              },
            ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Si l'utilisateur est connecté...
              if (authState.user.isNotEmpty) ...[
                Text(
                  'Bienvenue,',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  authState.user.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  authState.user.email,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                ),
              ] else ...[
                // ...sinon
                const Text('Vous n\'êtes pas connecté.'),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    // Le routeur va automatiquement rediriger vers /login
                    // mais on peut le forcer au cas où.
                  },
                  child: const Text('Se connecter'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

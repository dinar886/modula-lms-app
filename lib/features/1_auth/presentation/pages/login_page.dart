// lib/features/1_auth/presentation/pages/login_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Page de Connexion'),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                // Navigue vers la place de marché une fois connecté
                context.go('/marketplace');
              },
              child: const Text('Se connecter'),
            ),
          ],
        ),
      ),
    );
  }
}

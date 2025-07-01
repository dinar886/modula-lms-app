// lib/features/2_marketplace/presentation/pages/course_list_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CourseListPage extends StatelessWidget {
  const CourseListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalogue des Cours'),
        actions: [
          // Bouton pour naviguer vers la page de connexion
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Bienvenue sur Modula LMS !',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}

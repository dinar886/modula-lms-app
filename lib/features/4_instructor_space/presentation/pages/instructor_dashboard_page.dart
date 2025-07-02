// lib/features/4_instructor_space/presentation/pages/instructor_dashboard_page.dart
import 'package:flutter/material.dart';

class InstructorDashboardPage extends StatelessWidget {
  const InstructorDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de Bord Instructeur')),
      body: const Center(
        child: Text('Statistiques et outils pour l\'instructeur'),
      ),
    );
  }
}

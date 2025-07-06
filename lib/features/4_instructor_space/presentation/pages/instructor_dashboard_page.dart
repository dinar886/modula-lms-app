// lib/features/4_instructor_space/presentation/pages/instructor_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class InstructorDashboardPage extends StatelessWidget {
  const InstructorDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de Bord Instructeur')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        children: [
          _DashboardCard(
            icon: Icons.school_outlined,
            label: 'Mes Cours',
            onTap: () => context.push('/instructor-courses'),
          ),
          _DashboardCard(
            icon: Icons.people_outline,
            label: 'Élèves',
            onTap: () => context.push('/students'),
          ),
          _DashboardCard(
            icon: Icons.assignment_turned_in_outlined,
            label: 'Rendus',
            onTap: () => context.push('/submissions'),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48.0, color: Theme.of(context).primaryColor),
            const SizedBox(height: 16.0),
            Text(label, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

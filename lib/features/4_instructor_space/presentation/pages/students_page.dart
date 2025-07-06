// lib/features/4_instructor_space/presentation/pages/students_page.dart
import 'package:flutter/material.dart';

class StudentsPage extends StatelessWidget {
  const StudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Élèves')),
      body: const Center(child: Text('La liste des élèves apparaîtra ici.')),
    );
  }
}

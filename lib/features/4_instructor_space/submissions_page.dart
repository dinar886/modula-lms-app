// lib/features/4_instructor_space/submissions_page.dart
import 'package:flutter/material.dart';

class SubmissionsPage extends StatelessWidget {
  const SubmissionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rendus')),
      body: const Center(
        child: Text('Les devoirs rendus par les élèves apparaîtront ici.'),
      ),
    );
  }
}

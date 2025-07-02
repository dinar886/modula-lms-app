import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/1_auth/presentation/bloc/authentication_bloc.dart';
import 'package:modula_lms/features/4_instructor_space/presentation/bloc/course_management_bloc.dart';
import 'package:modula_lms/features/4_instructor_space/presentation/bloc/course_management_event.dart';
import 'package:modula_lms/features/4_instructor_space/presentation/bloc/course_management_state.dart';

class CreateCoursePage extends StatelessWidget {
  const CreateCoursePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<CourseManagementBloc>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Créer un nouveau cours')),
        body: BlocListener<CourseManagementBloc, CourseManagementState>(
          listener: (context, state) {
            if (state is CourseManagementSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cours créé avec succès !'),
                  backgroundColor: Colors.green,
                ),
              );
              // On retourne au tableau de bord après la création.
              context.pop();
            }
            if (state is CourseManagementFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const CreateCourseForm(),
        ),
      ),
    );
  }
}

class CreateCourseForm extends StatefulWidget {
  const CreateCourseForm({super.key});

  @override
  State<CreateCourseForm> createState() => _CreateCourseFormState();
}

class _CreateCourseFormState extends State<CreateCourseForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Titre du cours'),
              validator: (value) =>
                  value!.isEmpty ? 'Veuillez entrer un titre' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 5,
              validator: (value) =>
                  value!.isEmpty ? 'Veuillez entrer une description' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Prix (€)'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value!.isEmpty) return 'Veuillez entrer un prix';
                if (double.tryParse(value) == null)
                  return 'Veuillez entrer un nombre valide';
                return null;
              },
            ),
            const SizedBox(height: 24),
            BlocBuilder<CourseManagementBloc, CourseManagementState>(
              builder: (context, state) {
                if (state is CourseManagementLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return FilledButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final instructorId = context
                          .read<AuthenticationBloc>()
                          .state
                          .user
                          .id;
                      context.read<CourseManagementBloc>().add(
                        CreateCourseRequested(
                          title: _titleController.text,
                          description: _descriptionController.text,
                          price: double.parse(_priceController.text),
                          instructorId: instructorId,
                        ),
                      );
                    }
                  },
                  child: const Text('Publier le cours'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

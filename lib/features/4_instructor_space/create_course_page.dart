// lib/features/4_instructor_space/create_course_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart';
import 'package:modula_lms/features/4_instructor_space/instructor_space_logic.dart';

class CreateCoursePage extends StatelessWidget {
  const CreateCoursePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<CourseManagementBloc>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Créer un nouveau cours')),
        body: BlocListener<CourseManagementBloc, CourseManagementState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: (context, state) {
            if (state.status == CourseManagementStatus.success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cours créé avec succès !'),
                  backgroundColor: Colors.green,
                ),
              );
              context.pop(true);
            }
            if (state.status == CourseManagementStatus.failure) {
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

  XFile? _imageFile;
  Color _selectedColor = const Color(0xFF005A9C); // Couleur par défaut

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  void _pickColor(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisissez une couleur'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() => _selectedColor = color);
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Annuler'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            child: const Text('Valider'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _ImageAndColorPicker(
            imageFile: _imageFile,
            color: _selectedColor,
            onPickImage: _pickImage,
            onPickColor: () => _pickColor(context),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Titre du cours',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value!.isEmpty ? 'Veuillez entrer un titre' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
            validator: (value) =>
                value!.isEmpty ? 'Veuillez entrer une description' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _priceController,
            decoration: const InputDecoration(
              labelText: 'Prix (€)',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value!.isEmpty) return 'Veuillez entrer un prix';
              if (double.tryParse(value.replaceAll(',', '.')) == null) {
                return 'Veuillez entrer un nombre valide';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          BlocBuilder<CourseManagementBloc, CourseManagementState>(
            builder: (context, state) {
              if (state.status == CourseManagementStatus.loading) {
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
                        price: double.parse(
                          _priceController.text.replaceAll(',', '.'),
                        ),
                        instructorId: instructorId,
                        imageFile: _imageFile,
                        color: _selectedColor,
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
    );
  }
}

class _ImageAndColorPicker extends StatelessWidget {
  final XFile? imageFile;
  final Color color;
  final VoidCallback onPickImage;
  final VoidCallback onPickColor;

  const _ImageAndColorPicker({
    required this.imageFile,
    required this.color,
    required this.onPickImage,
    required this.onPickColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              color: imageFile == null ? color : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              image: imageFile != null
                  ? DecorationImage(
                      image: FileImage(File(imageFile!.path)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageFile == null
                ? const Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: Colors.white,
                      size: 50,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: ElevatedButton.icon(
                onPressed: onPickImage,
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text(
                  'Choisir une image',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            if (imageFile == null) ...[
              const SizedBox(width: 16),
              Flexible(
                child: TextButton.icon(
                  onPressed: onPickColor,
                  icon: Icon(Icons.color_lens_outlined, size: 18, color: color),
                  label: Text(
                    'Changer la couleur',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: color),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

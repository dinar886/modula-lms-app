// lib/features/4_instructor_space/course_info_editor_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/2_marketplace/marketplace_logic.dart';
import 'package:modula_lms/features/4_instructor_space/instructor_space_logic.dart';

class CourseInfoEditorPage extends StatelessWidget {
  final CourseEntity course;
  const CourseInfoEditorPage({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<CourseInfoEditorBloc>()..add(LoadCourseInfo(course.id)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Modifier les informations'),
          actions: [
            BlocBuilder<CourseInfoEditorBloc, CourseInfoEditorState>(
              builder: (context, state) {
                if (state.isDirty) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilledButton(
                      onPressed: state.status == CourseInfoEditorStatus.saving
                          ? null
                          : () => context.read<CourseInfoEditorBloc>().add(
                              SaveCourseInfoChanges(),
                            ),
                      child: state.status == CourseInfoEditorStatus.saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : const Text('Enregistrer'),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocListener<CourseInfoEditorBloc, CourseInfoEditorState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: (context, state) {
            if (state.status == CourseInfoEditorStatus.success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cours mis à jour !'),
                  backgroundColor: Colors.green,
                ),
              );
              context.pop(state.course);
            } else if (state.status == CourseInfoEditorStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: BlocBuilder<CourseInfoEditorBloc, CourseInfoEditorState>(
            builder: (context, state) {
              if (state.status == CourseInfoEditorStatus.loading ||
                  state.status == CourseInfoEditorStatus.initial) {
                return const Center(child: CircularProgressIndicator());
              }
              return CourseInfoForm(
                key: ValueKey(state.course.id),
                state: state,
              );
            },
          ),
        ),
      ),
    );
  }
}

class CourseInfoForm extends StatefulWidget {
  final CourseInfoEditorState state;
  const CourseInfoForm({super.key, required this.state});

  @override
  State<CourseInfoForm> createState() => _CourseInfoFormState();
}

class _CourseInfoFormState extends State<CourseInfoForm> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    final course = widget.state.course;
    _titleController = TextEditingController(text: course.title);
    _descriptionController = TextEditingController(text: course.description);
    _priceController = TextEditingController(
      text: course.price.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CourseInfoEditorBloc>();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        child: ListView(
          children: [
            _ImageAndColorPicker(state: widget.state, bloc: bloc),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre du cours',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => bloc.add(CourseInfoChanged(title: value)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              onChanged: (value) =>
                  bloc.add(CourseInfoChanged(description: value)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Prix (€)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (value) => bloc.add(
                CourseInfoChanged(
                  price: double.tryParse(value.replaceAll(',', '.')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageAndColorPicker extends StatelessWidget {
  final CourseInfoEditorState state;
  final CourseInfoEditorBloc bloc;

  const _ImageAndColorPicker({required this.state, required this.bloc});

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      bloc.add(CourseInfoChanged(newImageFile: pickedFile));
    }
  }

  void _pickColor(BuildContext context) {
    Color pickerColor = state.newColor ?? Colors.blue;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisissez une couleur'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) {
              pickerColor = color;
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
            onPressed: () {
              bloc.add(CourseInfoChanged(newColor: pickerColor));
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (state.newImageFile != null) {
      imageProvider = FileImage(File(state.newImageFile!.path));
    } else if (state.course.imageUrl.isNotEmpty) {
      imageProvider = NetworkImage(state.course.imageUrl);
    }

    final bool isPlaceholder = state.course.imageUrl.contains('placehold.co');
    final bool canRemoveImage = state.newImageFile != null || !isPlaceholder;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  image: imageProvider != null
                      ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                      : null,
                ),
                child: imageProvider == null
                    ? const Center(
                        child: Icon(
                          Icons.image_outlined,
                          color: Colors.grey,
                          size: 50,
                        ),
                      )
                    : null,
              ),
            ),
            if (canRemoveImage)
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      bloc.add(RemoveCourseImage());
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(6.0),
                      child: Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: const Text('Changer l\'image'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(width: 16),
            if (isPlaceholder && state.newImageFile == null)
              TextButton.icon(
                onPressed: () => _pickColor(context),
                icon: Icon(
                  Icons.color_lens_outlined,
                  size: 18,
                  color: state.newColor ?? Theme.of(context).primaryColor,
                ),
                label: Text(
                  'Changer la couleur',
                  style: TextStyle(
                    color: state.newColor ?? Theme.of(context).primaryColor,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

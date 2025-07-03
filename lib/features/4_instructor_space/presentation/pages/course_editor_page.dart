import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/course_player/domain/entities/lesson_entity.dart';
import 'package:modula_lms/features/course_player/presentation/bloc/course_content_bloc.dart';
import 'package:modula_lms/features/course_player/presentation/bloc/course_content_event.dart';
import 'package:modula_lms/features/course_player/presentation/bloc/course_content_state.dart';
import 'package:modula_lms/features/2_marketplace/domain/entities/course_entity.dart';
import 'package:modula_lms/features/4_instructor_space/presentation/bloc/course_editor_bloc.dart';
import 'package:modula_lms/features/4_instructor_space/presentation/bloc/course_editor_event.dart';
import 'package:modula_lms/features/4_instructor_space/presentation/bloc/course_editor_state.dart';

class CourseEditorPage extends StatelessWidget {
  final CourseEntity course;
  const CourseEditorPage({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              sl<CourseContentBloc>()..add(FetchCourseContent(course.id)),
        ),
        BlocProvider(create: (context) => sl<CourseEditorBloc>()),
      ],
      child: BlocListener<CourseEditorBloc, CourseEditorState>(
        listener: (context, state) {
          if (state is CourseEditorSuccess) {
            context.read<CourseContentBloc>().add(
              FetchCourseContent(course.id),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Opération réussie !'),
                backgroundColor: Colors.green,
              ),
            );
          }
          if (state is CourseEditorFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: Colors.red),
            );
          }
        },
        child: Builder(
          builder: (context) {
            return Scaffold(
              appBar: AppBar(title: Text(course.title)),
              body: BlocBuilder<CourseContentBloc, CourseContentState>(
                builder: (context, state) {
                  if (state is CourseContentLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is CourseContentLoaded) {
                    return ListView.builder(
                      itemCount: state.sections.length,
                      itemBuilder: (context, index) {
                        final section = state.sections[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: ExpansionTile(
                            title: Text(
                              section.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                final courseEditorBloc = context
                                    .read<CourseEditorBloc>();
                                if (value == 'edit') {
                                  _showEditSectionDialog(
                                    context,
                                    section.id,
                                    section.title,
                                    courseEditorBloc,
                                  );
                                } else if (value == 'delete') {
                                  _showDeleteConfirmationDialog(
                                    context,
                                    'Supprimer la section ?',
                                    () {
                                      courseEditorBloc.add(
                                        DeleteSection(section.id),
                                      );
                                    },
                                  );
                                } else if (value == 'add_lesson') {
                                  _showAddLessonDialog(
                                    context,
                                    section.id,
                                    courseEditorBloc,
                                  );
                                }
                              },
                              itemBuilder: (BuildContext context) =>
                                  <PopupMenuEntry<String>>[
                                    const PopupMenuItem<String>(
                                      value: 'add_lesson',
                                      child: Text('Ajouter une leçon'),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'edit',
                                      child: Text('Modifier la section'),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Text(
                                        'Supprimer la section',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                            ),
                            children: section.lessons.map((lesson) {
                              return ListTile(
                                leading: Icon(
                                  _getIconForLessonType(lesson.lessonType),
                                ),
                                title: Text(lesson.title),
                                onTap: () {
                                  // **CORRECTION** : Utilisation de `push` pour naviguer
                                  // vers l'éditeur de leçon ou de quiz.
                                  if (lesson.lessonType == LessonType.quiz) {
                                    context.push('/quiz-editor/${lesson.id}');
                                  } else {
                                    context.push('/lesson-editor/${lesson.id}');
                                  }
                                },
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    final courseEditorBloc = context
                                        .read<CourseEditorBloc>();
                                    if (value == 'edit') {
                                      _showEditLessonDialog(
                                        context,
                                        lesson.id,
                                        lesson.title,
                                        courseEditorBloc,
                                      );
                                    } else if (value == 'delete') {
                                      _showDeleteConfirmationDialog(
                                        context,
                                        'Supprimer la leçon ?',
                                        () {
                                          courseEditorBloc.add(
                                            DeleteLesson(lesson.id),
                                          );
                                        },
                                      );
                                    }
                                  },
                                  itemBuilder: (BuildContext context) =>
                                      <PopupMenuEntry<String>>[
                                        const PopupMenuItem<String>(
                                          value: 'edit',
                                          child: Text('Modifier le nom'),
                                        ),
                                        const PopupMenuItem<String>(
                                          value: 'delete',
                                          child: Text(
                                            'Supprimer',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                  icon: const Icon(
                                    Icons.more_vert,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    );
                  }
                  if (state is CourseContentError) {
                    return Center(child: Text(state.message));
                  }
                  return const SizedBox.shrink();
                },
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () {
                  final courseEditorBloc = context.read<CourseEditorBloc>();
                  _showAddSectionDialog(context, course.id, courseEditorBloc);
                },
                label: const Text('Ajouter une Section'),
                icon: const Icon(Icons.add),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- BOÎTES DE DIALOGUE ---

  void _showAddSectionDialog(
    BuildContext context,
    String courseId,
    CourseEditorBloc courseEditorBloc,
  ) {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nouvelle Section'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(labelText: 'Titre'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                courseEditorBloc.add(
                  AddSection(title: titleController.text, courseId: courseId),
                );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showAddLessonDialog(
    BuildContext context,
    int sectionId,
    CourseEditorBloc courseEditorBloc,
  ) {
    final titleController = TextEditingController();
    String selectedType = 'text';
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nouvelle Leçon'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Titre'),
              autofocus: true,
            ),
            StatefulBuilder(
              builder: (context, setState) => DropdownButton<String>(
                value: selectedType,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'text', child: Text('Texte')),
                  DropdownMenuItem(value: 'video', child: Text('Vidéo')),
                  DropdownMenuItem(value: 'document', child: Text('Document')),
                  DropdownMenuItem(value: 'quiz', child: Text('Quiz')),
                ],
                onChanged: (value) => setState(() => selectedType = value!),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                courseEditorBloc.add(
                  AddLesson(
                    title: titleController.text,
                    sectionId: sectionId,
                    lessonType: selectedType,
                  ),
                );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showEditSectionDialog(
    BuildContext context,
    int sectionId,
    String currentTitle,
    CourseEditorBloc courseEditorBloc,
  ) {
    final titleController = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Modifier la Section'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(labelText: 'Nouveau titre'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                courseEditorBloc.add(
                  EditSection(
                    newTitle: titleController.text,
                    sectionId: sectionId,
                  ),
                );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  void _showEditLessonDialog(
    BuildContext context,
    int lessonId,
    String currentTitle,
    CourseEditorBloc courseEditorBloc,
  ) {
    final titleController = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Modifier le nom de la Leçon'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(labelText: 'Nouveau titre'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                courseEditorBloc.add(
                  EditLesson(
                    newTitle: titleController.text,
                    lessonId: lessonId,
                  ),
                );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    String title,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              onConfirm();
              Navigator.pop(dialogContext);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  IconData _getIconForLessonType(LessonType type) {
    switch (type) {
      case LessonType.video:
        return Icons.play_circle_outline;
      case LessonType.text:
        return Icons.article_outlined;
      case LessonType.document:
        return Icons.picture_as_pdf_outlined;
      case LessonType.quiz:
        return Icons.quiz_outlined;
      default:
        return Icons.help_outline;
    }
  }
}

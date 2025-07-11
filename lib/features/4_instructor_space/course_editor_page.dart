// lib/features/4_instructor_space/course_editor_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart'; // IMPORT AJOUTÉ pour l'ID utilisateur
import 'package:modula_lms/features/course_player/course_player_logic.dart';
import 'package:modula_lms/features/2_marketplace/marketplace_logic.dart';
import 'package:modula_lms/features/4_instructor_space/instructor_space_logic.dart';

class CourseEditorPage extends StatefulWidget {
  final CourseEntity course;
  const CourseEditorPage({super.key, required this.course});

  @override
  State<CourseEditorPage> createState() => _CourseEditorPageState();
}

class _CourseEditorPageState extends State<CourseEditorPage> {
  late CourseEntity _currentCourse;

  @override
  void initState() {
    super.initState();
    _currentCourse = widget.course;
  }

  @override
  Widget build(BuildContext context) {
    // On récupère l'ID de l'utilisateur connecté une seule fois ici.
    final String userId = context.read<AuthenticationBloc>().state.user.id;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<CourseContentBloc>()
            // CORRECTION : On utilise les paramètres nommés 'courseId' et 'userId'.
            ..add(
              FetchCourseContent(courseId: _currentCourse.id, userId: userId),
            ),
        ),
        BlocProvider(create: (context) => sl<CourseEditorBloc>()),
      ],
      child: Builder(
        builder: (context) {
          return BlocListener<CourseEditorBloc, CourseEditorState>(
            listener: (context, state) {
              if (state is CourseEditorSuccess) {
                // CORRECTION : On utilise les paramètres nommés pour rafraîchir.
                context.read<CourseContentBloc>().add(
                  FetchCourseContent(
                    courseId: _currentCourse.id,
                    userId: userId,
                  ),
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
                  SnackBar(
                    content: Text(state.error),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Scaffold(
              appBar: AppBar(
                title: Text(_currentCourse.title),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_note),
                    tooltip: 'Modifier les informations du cours',
                    onPressed: () async {
                      // Ouvre la page d'édition des métadonnées du cours
                      final updatedCourse = await context.push<CourseEntity>(
                        '/course-info-editor',
                        extra: _currentCourse,
                      );

                      // Met à jour l'état si des changements ont été faits
                      if (updatedCourse != null && mounted) {
                        setState(() {
                          _currentCourse = updatedCourse;
                        });
                        // CORRECTION : On utilise les paramètres nommés pour rafraîchir.
                        context.read<CourseContentBloc>().add(
                          FetchCourseContent(
                            courseId: _currentCourse.id,
                            userId: userId,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              body: BlocBuilder<CourseContentBloc, CourseContentState>(
                builder: (context, state) {
                  if (state is CourseContentLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is CourseContentLoaded) {
                    // Construit la liste des sections et leçons
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
                            // Titre de la section
                            title: Text(
                              section.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // Menu pour la section (modifier, supprimer, etc.)
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
                                } else if (value == 'add_content') {
                                  // Ouvre le menu d'ajout de contenu
                                  _showAddContentMenu(
                                    context,
                                    section.id,
                                    courseEditorBloc,
                                  );
                                }
                              },
                              itemBuilder: (BuildContext context) =>
                                  <PopupMenuEntry<String>>[
                                    const PopupMenuItem<String>(
                                      value: 'add_content',
                                      child: Text('Ajouter du contenu'),
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
                            // Liste des leçons dans la section
                            children: section.lessons.map((lesson) {
                              return ListTile(
                                leading: Icon(
                                  _getIconForLessonType(lesson.lessonType),
                                ),
                                title: Text(lesson.title),
                                subtitle: lesson.dueDate != null
                                    ? Text(
                                        'À rendre le ${DateFormat('dd/MM/yyyy HH:mm').format(lesson.dueDate!)}',
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontSize: 12,
                                        ),
                                      )
                                    : null,
                                onTap: () {
                                  // Navigue vers l'éditeur de la leçon
                                  context.push(
                                    '/lesson-editor/${lesson.id}/section/${section.id}',
                                  );
                                },
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit_name') {
                                      _showEditLessonDialog(
                                        context,
                                        lesson.id,
                                        lesson.title,
                                        context.read<CourseEditorBloc>(),
                                      );
                                    } else if (value == 'preview') {
                                      // Navigue vers l'aperçu élève de la leçon
                                      context.push(
                                        '/lesson-viewer/${lesson.id}',
                                        extra: _currentCourse.id,
                                      );
                                    } else if (value == 'delete') {
                                      _showDeleteConfirmationDialog(
                                        context,
                                        'Supprimer cette activité ?',
                                        () {
                                          context.read<CourseEditorBloc>().add(
                                            DeleteLesson(lesson.id),
                                          );
                                        },
                                      );
                                    }
                                  },
                                  itemBuilder: (BuildContext context) =>
                                      <PopupMenuEntry<String>>[
                                        const PopupMenuItem<String>(
                                          value: 'edit_name',
                                          child: Text('Modifier le nom'),
                                        ),
                                        const PopupMenuItem<String>(
                                          value: 'preview',
                                          child: Text("Voir l'aperçu"),
                                        ),
                                        const PopupMenuDivider(),
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
                  _showAddSectionDialog(
                    context,
                    _currentCourse.id,
                    courseEditorBloc,
                  );
                },
                label: const Text('Ajouter une Section'),
                icon: const Icon(Icons.add),
              ),
            ),
          );
        },
      ),
    );
  }

  // Affiche le menu pour choisir quel type de contenu ajouter.
  void _showAddContentMenu(
    BuildContext context,
    int sectionId,
    CourseEditorBloc bloc,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (builderContext) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('Ajouter une Leçon'),
            onTap: () {
              Navigator.pop(builderContext);
              _showAddLessonDialog(context, sectionId, bloc, 'text');
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment_outlined),
            title: const Text('Ajouter un Devoir'),
            onTap: () {
              Navigator.pop(builderContext);
              _showAddLessonDialog(context, sectionId, bloc, 'devoir');
            },
          ),
          ListTile(
            leading: const Icon(Icons.assessment_outlined),
            title: const Text('Ajouter un Contrôle'),
            onTap: () {
              Navigator.pop(builderContext);
              _showAddLessonDialog(context, sectionId, bloc, 'evaluation');
            },
          ),
        ],
      ),
    );
  }

  // Dialogue pour ajouter une leçon/devoir/contrôle. Gère le titre et la date.
  void _showAddLessonDialog(
    BuildContext context,
    int sectionId,
    CourseEditorBloc courseEditorBloc,
    String lessonType, // 'text', 'devoir', ou 'evaluation'
  ) {
    final titleController = TextEditingController();
    DateTime? dueDate;
    final bool isAssignment =
        lessonType == 'devoir' || lessonType == 'evaluation';

    String dialogTitle;
    switch (lessonType) {
      case 'devoir':
        dialogTitle = 'Nouveau Devoir';
        break;
      case 'evaluation':
        dialogTitle = 'Nouveau Contrôle';
        break;
      default:
        dialogTitle = 'Nouvelle Leçon';
        break;
    }

    showDialog(
      context: context,
      // On utilise un StatefulWidget pour le dialogue afin de gérer l'état de la date.
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(dialogTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Titre'),
                  autofocus: true,
                ),
                // Affiche le sélecteur de date pour les devoirs et contrôles.
                if (isAssignment)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: ListTile(
                      title: Text(
                        dueDate == null
                            ? 'Définir une date de rendu'
                            : 'À rendre le: ${DateFormat('dd/MM/yyyy HH:mm').format(dueDate!)}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: dueDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (pickedDate != null) {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(
                              dueDate ?? DateTime.now(),
                            ),
                          );
                          if (pickedTime != null) {
                            setDialogState(() {
                              dueDate = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                            });
                          }
                        }
                      },
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
                    if (isAssignment && dueDate == null) {
                      // Affiche une erreur si la date est requise mais non définie
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Veuillez définir une date de rendu.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    courseEditorBloc.add(
                      AddLesson(
                        title: titleController.text,
                        sectionId: sectionId,
                        lessonType: lessonType,
                        // On envoie la date au format ISO 8601 si elle existe.
                        dueDate: dueDate?.toIso8601String(),
                      ),
                    );
                    Navigator.pop(dialogContext);
                  }
                },
                child: const Text('Ajouter'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Dialogue pour ajouter une nouvelle section.
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

  // Dialogue pour modifier le titre d'une section.
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

  // Dialogue pour modifier le nom d'une leçon.
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

  // Dialogue générique de confirmation pour les suppressions.
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

  // Retourne l'icône appropriée pour chaque type de leçon.
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
      case LessonType.devoir:
        return Icons.assignment_outlined;
      case LessonType.evaluation:
        return Icons.assessment_outlined;
      default:
        return Icons.help_outline;
    }
  }
}

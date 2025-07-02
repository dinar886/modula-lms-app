import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/course_player/domain/entities/lesson_entity.dart';
import 'package:modula_lms/features/4_instructor_space/presentation/bloc/lesson_editor_bloc.dart';
import 'package:modula_lms/features/4_instructor_space/presentation/bloc/lesson_editor_event.dart';
import 'package:modula_lms/features/4_instructor_space/presentation/bloc/lesson_editor_state.dart';

// On transforme la page en StatefulWidget pour pouvoir gérer les contrôleurs de texte.
class LessonEditorPage extends StatefulWidget {
  final int lessonId;
  const LessonEditorPage({super.key, required this.lessonId});

  @override
  State<LessonEditorPage> createState() => _LessonEditorPageState();
}

class _LessonEditorPageState extends State<LessonEditorPage> {
  // Les contrôleurs sont maintenant gérés par l'état de la page.
  final _urlController = TextEditingController();
  final _textController = TextEditingController();

  @override
  void dispose() {
    // Il est important de "dispose" les contrôleurs pour libérer la mémoire.
    _urlController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<LessonEditorBloc>()..add(FetchLessonDetails(widget.lessonId)),
      child: BlocConsumer<LessonEditorBloc, LessonEditorState>(
        // Le listener réagit aux changements d'état sans reconstruire l'UI.
        listener: (context, state) {
          // Si une erreur survient, on affiche un message.
          if (state.status == LessonEditorStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: Colors.red),
            );
          }
          // Quand les données de la leçon sont chargées avec succès...
          if (state.status == LessonEditorStatus.success) {
            // ...on met à jour le texte de nos contrôleurs.
            // Cela évite de perdre les modifications si l'utilisateur quitte et revient.
            _urlController.text = state.lesson.contentUrl ?? '';
            _textController.text = state.lesson.contentText ?? '';
          }
        },
        // Le builder reconstruit l'interface quand l'état change.
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                state.lesson.title.isNotEmpty
                    ? state.lesson.title
                    : 'Chargement...',
              ),
              actions: [
                // On affiche le bouton de sauvegarde seulement si le contenu est chargé.
                if (state.status == LessonEditorStatus.success)
                  BlocBuilder<LessonEditorBloc, LessonEditorState>(
                    builder: (context, state) {
                      // On affiche un indicateur de chargement pendant la sauvegarde.
                      if (state.status == LessonEditorStatus.saving) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      }
                      return IconButton(
                        icon: const Icon(Icons.save),
                        tooltip: 'Sauvegarder',
                        onPressed: () {
                          // On envoie l'événement de sauvegarde au BLoC.
                          // Le BLoC a maintenant toutes les informations dont il a besoin.
                          final lesson = state.lesson;
                          context.read<LessonEditorBloc>().add(
                            SaveLessonContent(
                              lessonId: lesson.id,
                              // On envoie le contenu du bon contrôleur en fonction du type de leçon.
                              contentText: lesson.lessonType == LessonType.text
                                  ? _textController.text
                                  : null,
                              contentUrl: lesson.lessonType != LessonType.text
                                  ? _urlController.text
                                  : null,
                            ),
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
            body: _buildBody(context, state),
          );
        },
      ),
    );
  }

  // Affiche le bon widget en fonction de l'état de chargement.
  Widget _buildBody(BuildContext context, LessonEditorState state) {
    switch (state.status) {
      case LessonEditorStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case LessonEditorStatus.success:
      case LessonEditorStatus
          .saving: // On continue d'afficher l'éditeur pendant la sauvegarde.
        return _buildEditor(context, state.lesson);
      case LessonEditorStatus.failure:
        return Center(child: Text(state.error));
      default:
        return const SizedBox.shrink();
    }
  }

  // Affiche le bon éditeur en fonction du type de leçon.
  Widget _buildEditor(BuildContext context, LessonEntity lesson) {
    switch (lesson.lessonType) {
      case LessonType.text:
        return _TextEditor(controller: _textController);
      case LessonType.video:
      case LessonType.document:
        return _UrlEditor(controller: _urlController);
      default:
        return const Center(child: Text('Type de leçon non éditable.'));
    }
  }
}

// --- WIDGETS D'ÉDITION SIMPLIFIÉS ---

// Widget pour éditer les leçons de type URL (vidéo, document).
class _UrlEditor extends StatelessWidget {
  final TextEditingController controller;
  const _UrlEditor({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextFormField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'URL du contenu',
          border: OutlineInputBorder(),
          helperText:
              'Entrez le lien complet vers votre vidéo ou document PDF.',
        ),
      ),
    );
  }
}

// Widget pour éditer les leçons de type Texte.
class _TextEditor extends StatelessWidget {
  final TextEditingController controller;
  const _TextEditor({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextFormField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Contenu de la leçon (Markdown supporté)',
          border: OutlineInputBorder(),
          helperText:
              'Vous pouvez utiliser la syntaxe Markdown pour formater votre texte.',
        ),
        maxLines: null, // Permet au champ de s'étendre verticalement.
        expands:
            true, // Fait en sorte que le champ occupe tout l'espace vertical disponible.
        textAlignVertical: TextAlignVertical.top,
      ),
    );
  }
}

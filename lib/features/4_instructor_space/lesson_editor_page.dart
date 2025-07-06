// lib/features/4_instructor_space/lesson_editor_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/core/di/service_locator.dart';
// On importe la logique du lecteur de cours, mais on cache la classe qui pose conflit.
import 'package:modula_lms/features/course_player/course_player_logic.dart'
    hide FetchLessonDetails;
// On importe la logique de l'espace instructeur qui contient le bon FetchLessonDetails.
import 'package:modula_lms/features/4_instructor_space/instructor_space_logic.dart';

class LessonEditorPage extends StatefulWidget {
  final int lessonId;
  const LessonEditorPage({super.key, required this.lessonId});

  @override
  State<LessonEditorPage> createState() => _LessonEditorPageState();
}

class _LessonEditorPageState extends State<LessonEditorPage> {
  final _urlController = TextEditingController();
  final _textController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Maintenant, Dart sait qu'il doit utiliser le FetchLessonDetails de LessonEditorBloc.
      create: (context) =>
          sl<LessonEditorBloc>()..add(FetchLessonDetails(widget.lessonId)),
      child: BlocConsumer<LessonEditorBloc, LessonEditorState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == LessonEditorStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: Colors.red),
            );
          } else if (state.status == LessonEditorStatus.success &&
              !state.isDirty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Leçon sauvegardée avec succès !'),
                backgroundColor: Colors.green,
              ),
            );
          }

          if (state.status == LessonEditorStatus.success) {
            _urlController.text = state.lesson.contentUrl ?? '';
            _textController.text = state.lesson.contentText ?? '';
            _urlController.selection = TextSelection.fromPosition(
              TextPosition(offset: _urlController.text.length),
            );
            _textController.selection = TextSelection.fromPosition(
              TextPosition(offset: _textController.text.length),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                state.lesson.title.isNotEmpty
                    ? state.lesson.title
                    : 'Chargement...',
              ),
              actions: [
                if (state.isDirty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: BlocBuilder<LessonEditorBloc, LessonEditorState>(
                      builder: (context, state) {
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
                        return FilledButton(
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            context.read<LessonEditorBloc>().add(
                              SaveLessonContent(),
                            );
                          },
                          child: const Text('Enregistrer'),
                        );
                      },
                    ),
                  ),
              ],
            ),
            body: _buildBody(context, state),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, LessonEditorState state) {
    if (state.status == LessonEditorStatus.loading ||
        state.status == LessonEditorStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == LessonEditorStatus.failure) {
      return Center(child: Text(state.error));
    }
    return _buildEditor(context, state.lesson);
  }

  Widget _buildEditor(BuildContext context, LessonEntity lesson) {
    switch (lesson.lessonType) {
      case LessonType.text:
        return _TextEditor(
          controller: _textController,
          onChanged: (value) {
            context.read<LessonEditorBloc>().add(
              LessonContentChanged(contentText: value),
            );
          },
        );
      case LessonType.video:
      case LessonType.document:
        return _UrlEditor(
          controller: _urlController,
          onChanged: (value) {
            context.read<LessonEditorBloc>().add(
              LessonContentChanged(contentUrl: value),
            );
          },
        );
      default:
        return const Center(child: Text('Type de leçon non éditable.'));
    }
  }
}

class _UrlEditor extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _UrlEditor({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
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

class _TextEditor extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _TextEditor({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        decoration: const InputDecoration(
          labelText: 'Contenu de la leçon (Markdown supporté)',
          border: OutlineInputBorder(),
          helperText:
              'Vous pouvez utiliser la syntaxe Markdown pour formater votre texte.',
        ),
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
      ),
    );
  }
}

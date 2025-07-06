// lib/features/4_instructor_space/lesson_editor_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:modula_lms/core/di/service_locator.dart';
// CORRECTION : On importe 'course_player_logic.dart' mais on masque la classe 'FetchLessonDetails'
// pour éviter le conflit de nom avec celle définie dans 'instructor_space_logic.dart'.
import 'package:modula_lms/features/course_player/course_player_logic.dart'
    hide FetchLessonDetails;
import 'package:modula_lms/features/4_instructor_space/instructor_space_logic.dart';

class LessonEditorPage extends StatefulWidget {
  final int lessonId;
  final int sectionId;

  const LessonEditorPage({
    super.key,
    required this.lessonId,
    required this.sectionId,
  });

  @override
  State<LessonEditorPage> createState() => _LessonEditorPageState();
}

class _LessonEditorPageState extends State<LessonEditorPage> {
  // Map pour garder en mémoire les titres des quiz et éviter les appels API répétitifs
  final Map<int, String> _quizTitles = {};

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<LessonEditorBloc>()
        // Cette ligne fonctionne maintenant car il n'y a plus d'ambiguïté sur 'FetchLessonDetails'
        ..add(FetchLessonDetails(widget.lessonId)),
      child: BlocConsumer<LessonEditorBloc, LessonEditorState>(
        listenWhen: (previous, current) =>
            previous.status != current.status ||
            previous.lesson != current.lesson,
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
                          onPressed: () => context.read<LessonEditorBloc>().add(
                            SaveLessonContent(),
                          ),
                          child: const Text('Enregistrer'),
                        );
                      },
                    ),
                  ),
              ],
            ),
            body: _buildBody(context, state),
            floatingActionButton: FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () => _showAddBlockMenu(context),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, LessonEditorState state) {
    if (state.status == LessonEditorStatus.loading && state.lesson.id == 0) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == LessonEditorStatus.failure &&
        state.lesson.contentBlocks.isEmpty) {
      return Center(child: Text(state.error));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0).copyWith(bottom: 80),
      itemCount: state.lesson.contentBlocks.length,
      itemBuilder: (context, index) {
        final block = state.lesson.contentBlocks[index];

        // Pour les blocs de quiz, on s'assure d'avoir le titre.
        if (block.blockType == ContentBlockType.quiz &&
            int.tryParse(block.content) != null &&
            int.parse(block.content) > 0) {
          _fetchQuizTitle(context, int.parse(block.content));
        }

        return _ContentBlockEditor(
          key: ValueKey(block.localId),
          block: block,
          quizTitle: _quizTitles[int.tryParse(block.content)],
          onContentChanged: (newContent) {
            _updateBlockContent(context, index, newContent);
          },
          onDelete: () {
            _deleteBlock(context, index);
          },
          onEditQuiz: () async {
            final quizId = int.tryParse(block.content) ?? 0;
            // On navigue vers l'éditeur de quiz et on attend le nouvel ID en retour.
            final savedQuizId = await context.push<int>('/quiz-editor/$quizId');

            if (savedQuizId != null && mounted) {
              // On met à jour le bloc avec l'ID du quiz sauvegardé.
              context.read<LessonEditorBloc>().add(
                UpdateQuizBlock(
                  localBlockId: block.localId,
                  quizId: savedQuizId,
                ),
              );
            }
          },
        );
      },
    );
  }

  // Helper pour récupérer le titre d'un quiz et le mettre en cache
  void _fetchQuizTitle(BuildContext context, int quizId) {
    if (_quizTitles.containsKey(quizId)) return; // Déjà en cache

    // On crée un BLoC temporaire juste pour récupérer les détails du quiz.
    final quizEditorBloc = sl<QuizEditorBloc>();
    quizEditorBloc.add(FetchQuizForEditing(quizId));
    quizEditorBloc.stream
        .firstWhere((state) => state.status == QuizEditorStatus.loaded)
        .then((state) {
          if (mounted) {
            setState(() {
              _quizTitles[quizId] = state.quiz.title;
            });
          }
          quizEditorBloc.close();
        });
  }

  void _showAddBlockMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (builderContext) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.article_outlined),
              title: const Text('Texte'),
              onTap: () {
                Navigator.pop(builderContext);
                _addBlock(
                  context,
                  ContentBlockType.text,
                  'Nouveau bloc de texte...',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('Vidéo (URL)'),
              onTap: () {
                Navigator.pop(builderContext);
                _addBlock(context, ContentBlockType.video, 'https://');
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Image (Téléverser)'),
              onTap: () {
                Navigator.pop(builderContext);
                _pickAndUploadFile(context, ContentBlockType.image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Document (Téléverser)'),
              onTap: () {
                Navigator.pop(builderContext);
                _pickAndUploadFile(context, ContentBlockType.document);
              },
            ),
            // MODIFICATION: Ajout de l'option pour créer un Quiz.
            const Divider(),
            ListTile(
              leading: const Icon(Icons.quiz_outlined),
              title: const Text('Quiz'),
              onTap: () {
                Navigator.pop(builderContext);
                _addBlock(
                  context,
                  ContentBlockType.quiz,
                  '0', // On initialise le contenu avec '0' pour un nouveau quiz.
                  // On met le statut à 'uploading' pour indiquer qu'il n'est pas encore sauvegardé.
                  uploadStatus: UploadStatus.uploading,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickAndUploadFile(
    BuildContext context,
    ContentBlockType type,
  ) async {
    XFile? pickedFile;
    if (type == ContentBlockType.image) {
      pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    } else if (type == ContentBlockType.document) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null) {
        pickedFile = XFile(result.files.single.path!);
      }
    }

    if (pickedFile != null && mounted) {
      final bloc = context.read<LessonEditorBloc>();
      final localId = DateTime.now().millisecondsSinceEpoch.toString();

      _addBlock(
        context,
        type,
        '',
        uploadStatus: UploadStatus.uploading,
        localId: localId,
      );

      bloc.add(
        UploadBlockFile(
          file: pickedFile,
          blockType: type,
          localBlockId: localId,
        ),
      );
    }
  }

  void _addBlock(
    BuildContext context,
    ContentBlockType type,
    String initialContent, {
    UploadStatus uploadStatus = UploadStatus.completed,
    String? localId,
  }) {
    final bloc = context.read<LessonEditorBloc>();
    final currentState = bloc.state;

    final newBlock = ContentBlockEntity(
      id: 0,
      localId: localId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      blockType: type,
      content: initialContent,
      orderIndex: currentState.lesson.contentBlocks.length,
      uploadStatus: uploadStatus,
    );

    final updatedBlocks = List<ContentBlockEntity>.from(
      currentState.lesson.contentBlocks,
    )..add(newBlock);
    bloc.add(
      LessonContentChanged(
        lesson: currentState.lesson.copyWith(contentBlocks: updatedBlocks),
      ),
    );
  }

  void _updateBlockContent(
    BuildContext context,
    int blockIndex,
    String newContent,
  ) {
    final bloc = context.read<LessonEditorBloc>();
    final currentState = bloc.state;

    final updatedBlocks = List<ContentBlockEntity>.from(
      currentState.lesson.contentBlocks,
    );
    final oldBlock = updatedBlocks[blockIndex];

    updatedBlocks[blockIndex] = oldBlock.copyWith(content: newContent);

    bloc.add(
      LessonContentChanged(
        lesson: currentState.lesson.copyWith(contentBlocks: updatedBlocks),
      ),
    );
  }

  void _deleteBlock(BuildContext context, int blockIndex) {
    final bloc = context.read<LessonEditorBloc>();
    final currentState = bloc.state;

    final updatedBlocks = List<ContentBlockEntity>.from(
      currentState.lesson.contentBlocks,
    )..removeAt(blockIndex);
    bloc.add(
      LessonContentChanged(
        lesson: currentState.lesson.copyWith(contentBlocks: updatedBlocks),
      ),
    );
  }
}

class _ContentBlockEditor extends StatelessWidget {
  final ContentBlockEntity block;
  final ValueChanged<String> onContentChanged;
  final VoidCallback onDelete;
  final VoidCallback? onEditQuiz; // Callback pour éditer un quiz.
  final String? quizTitle; // Titre du quiz à afficher.

  const _ContentBlockEditor({
    super.key,
    required this.block,
    required this.onContentChanged,
    required this.onDelete,
    this.onEditQuiz,
    this.quizTitle,
  });

  @override
  Widget build(BuildContext context) {
    if (block.uploadStatus == UploadStatus.uploading) {
      // MODIFICATION: Affichage différent pour un quiz en cours de création.
      if (block.blockType == ContentBlockType.quiz) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            leading: const Icon(Icons.quiz_outlined),
            title: const Text('Nouveau Quiz'),
            subtitle: const Text('Cliquez pour commencer à l\'éditer'),
            trailing: const Icon(Icons.edit_outlined),
            onTap: onEditQuiz,
          ),
        );
      }
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListTile(
          leading: const CircularProgressIndicator(),
          title: const Text('Téléversement en cours...'),
          trailing: IconButton(
            icon: const Icon(Icons.close),
            onPressed: onDelete,
          ),
        ),
      );
    }

    if (block.uploadStatus == UploadStatus.failed) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        color: Colors.red.shade100,
        child: ListTile(
          leading: const Icon(Icons.error_outline, color: Colors.red),
          title: const Text('Le téléversement a échoué'),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: onDelete,
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getBlockTitle(block.blockType),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: Colors.grey.shade600),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Contenu spécifique pour chaque type de bloc
            if (block.blockType == ContentBlockType.image)
              Image.network(block.content, height: 150, fit: BoxFit.cover),
            if (block.blockType == ContentBlockType.document)
              const ListTile(
                leading: Icon(Icons.picture_as_pdf),
                title: Text("Document PDF"),
                subtitle: Text("Prêt à être sauvegardé."),
              ),
            // MODIFICATION: Widget pour afficher le bloc Quiz.
            if (block.blockType == ContentBlockType.quiz)
              ListTile(
                leading: const Icon(Icons.quiz, color: Colors.deepPurple),
                title: Text(quizTitle ?? 'Chargement du titre...'),
                subtitle: Text('Quiz ID: ${block.content}'),
                trailing: const Icon(Icons.edit_outlined),
                onTap: onEditQuiz,
              ),

            if (block.blockType == ContentBlockType.text ||
                block.blockType == ContentBlockType.video)
              TextFormField(
                initialValue: block.content,
                onChanged: onContentChanged,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  helperText: _getHelperText(block.blockType),
                ),
                maxLines: block.blockType == ContentBlockType.text ? null : 1,
              ),
          ],
        ),
      ),
    );
  }

  String _getBlockTitle(ContentBlockType type) {
    switch (type) {
      case ContentBlockType.text:
        return 'Bloc Texte';
      case ContentBlockType.video:
        return 'Bloc Vidéo (URL)';
      case ContentBlockType.image:
        return 'Bloc Image';
      case ContentBlockType.document:
        return 'Bloc Document';
      // MODIFICATION: Titre pour le bloc Quiz.
      case ContentBlockType.quiz:
        return 'Bloc Quiz';
      default:
        return 'Bloc inconnu';
    }
  }

  String _getHelperText(ContentBlockType type) {
    switch (type) {
      case ContentBlockType.text:
        return 'Syntaxe Markdown supportée.';
      case ContentBlockType.video:
        return 'URL de la vidéo (YouTube, Vimeo, etc.).';
      default:
        return '';
    }
  }
}

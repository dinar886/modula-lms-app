// lib/features/4_instructor_space/lesson_editor_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/course_player/course_player_logic.dart'
    hide FetchLessonDetails;
import 'package:modula_lms/features/4_instructor_space/instructor_space_logic.dart';

class LessonEditorPage extends StatefulWidget {
  final int lessonId;
  // NOTE: Le sectionId n'est plus utilisé ici mais est conservé pour la compatibilité avec le routeur.
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
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<LessonEditorBloc>()..add(FetchLessonDetails(widget.lessonId)),
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
        return _ContentBlockEditor(
          key: ValueKey(block.localId),
          block: block,
          onContentChanged: (newContent) {
            _updateBlockContent(context, index, newContent);
          },
          onDelete: () {
            _deleteBlock(context, index);
          },
        );
      },
    );
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

  const _ContentBlockEditor({
    super.key,
    required this.block,
    required this.onContentChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (block.uploadStatus == UploadStatus.uploading) {
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

            // Le champ de texte ne s'affiche que pour les types Texte et Vidéo
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

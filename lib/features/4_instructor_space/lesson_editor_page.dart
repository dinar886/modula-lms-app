// lib/features/4_instructor_space/lesson_editor_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:modula_lms/core/di/service_locator.dart';
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
  final Map<int, String> _quizTitles = {};

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

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(8.0).copyWith(bottom: 80),
      itemCount: state.lesson.contentBlocks.length,
      itemBuilder: (context, index) {
        final block = state.lesson.contentBlocks[index];

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
            _updateBlockMetadata(context, index, {'content': newContent});
          },
          onMetadataChanged: (newMetadata) {
            _updateBlockMetadata(context, index, newMetadata);
          },
          onDelete: () {
            _deleteBlock(context, index);
          },
          onEditQuiz: () async {
            final quizId = int.tryParse(block.content) ?? 0;
            final savedQuizId = await context.push<int>('/quiz-editor/$quizId');

            if (savedQuizId != null && mounted) {
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
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }
        final bloc = context.read<LessonEditorBloc>();
        final currentState = bloc.state;
        final blocks = List<ContentBlockEntity>.from(
          currentState.lesson.contentBlocks,
        );
        final movedBlock = blocks.removeAt(oldIndex);
        blocks.insert(newIndex, movedBlock);

        final reorderedBlocks = blocks
            .asMap()
            .entries
            .map((e) => e.value.copyWith(orderIndex: e.key))
            .toList();

        bloc.add(
          LessonContentChanged(
            lesson: currentState.lesson.copyWith(
              contentBlocks: reorderedBlocks,
            ),
          ),
        );
      },
    );
  }

  void _fetchQuizTitle(BuildContext context, int quizId) {
    if (_quizTitles.containsKey(quizId)) return;

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
                  'Nouveau texte...',
                  metadata: {'style': 'paragraph'},
                );
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
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('Vidéo (URL)'),
              onTap: () {
                Navigator.pop(builderContext);
                _addBlock(context, ContentBlockType.video, 'https://');
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
            const Divider(),
            ListTile(
              leading: const Icon(Icons.quiz_outlined),
              title: const Text('Quiz'),
              onTap: () {
                Navigator.pop(builderContext);
                _addBlock(
                  context,
                  ContentBlockType.quiz,
                  '0',
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
        metadata: type == ContentBlockType.image
            ? {'width': 100.0, 'alignment': 'center'}
            : {},
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
    Map<String, dynamic> metadata = const {},
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
      metadata: metadata,
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

  void _updateBlockMetadata(
    BuildContext context,
    int blockIndex,
    Map<String, dynamic> newMetadata,
  ) {
    final bloc = context.read<LessonEditorBloc>();
    final currentState = bloc.state;
    final updatedBlocks = List<ContentBlockEntity>.from(
      currentState.lesson.contentBlocks,
    );
    final oldBlock = updatedBlocks[blockIndex];

    final content = newMetadata.containsKey('content')
        ? newMetadata['content']
        : oldBlock.content;

    final updatedMetadata = Map<String, dynamic>.from(oldBlock.metadata)
      ..addAll(newMetadata);

    updatedBlocks[blockIndex] = oldBlock.copyWith(
      content: content,
      metadata: updatedMetadata,
    );

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
  final ValueChanged<Map<String, dynamic>> onMetadataChanged;
  final VoidCallback onDelete;
  final VoidCallback? onEditQuiz;
  final String? quizTitle;

  const _ContentBlockEditor({
    super.key,
    required this.block,
    required this.onContentChanged,
    required this.onMetadataChanged,
    required this.onDelete,
    this.onEditQuiz,
    this.quizTitle,
  });

  @override
  Widget build(BuildContext context) {
    if (block.uploadStatus == UploadStatus.uploading) {
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
                Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Icon(Icons.drag_handle, color: Colors.grey),
                    ),
                    Text(
                      _getBlockTitle(block.blockType),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),

            _buildSpecificEditor(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecificEditor(BuildContext context) {
    switch (block.blockType) {
      case ContentBlockType.text:
        return _buildTextEditor();
      case ContentBlockType.image:
        return _buildImageEditor(context);
      case ContentBlockType.quiz:
        return ListTile(
          leading: const Icon(Icons.quiz, color: Colors.deepPurple),
          title: Text(quizTitle ?? 'Chargement du titre...'),
          subtitle: Text('Quiz ID: ${block.content}'),
          trailing: const Icon(Icons.edit_outlined),
          onTap: onEditQuiz,
        );
      case ContentBlockType.video:
        return TextFormField(
          initialValue: block.content,
          onChanged: onContentChanged,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            helperText: 'URL de la vidéo (YouTube, Vimeo, etc.).',
          ),
          maxLines: 1,
        );
      case ContentBlockType.document:
        return const ListTile(
          leading: Icon(Icons.picture_as_pdf),
          title: Text("Document PDF"),
          subtitle: Text("Prêt à être sauvegardé."),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTextEditor() {
    final currentStyle = block.metadata['style'] ?? 'paragraph';
    return Column(
      children: [
        DropdownButton<String>(
          value: currentStyle,
          isExpanded: true,
          onChanged: (value) {
            if (value != null) {
              onMetadataChanged({'style': value});
            }
          },
          items: const [
            DropdownMenuItem(value: 'h1', child: Text('Titre 1')),
            DropdownMenuItem(value: 'h2', child: Text('Titre 2')),
            DropdownMenuItem(value: 'paragraph', child: Text('Paragraphe')),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: block.content,
          onChanged: onContentChanged,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            helperText: 'Syntaxe Markdown supportée.',
          ),
          maxLines: null,
        ),
      ],
    );
  }

  Widget _buildImageEditor(BuildContext context) {
    // CORRECTION: Assure que la valeur est toujours un double.
    // On convertit la valeur `num` (qui peut être un int ou un double) en `double`.
    final double width = (block.metadata['width'] as num?)?.toDouble() ?? 100.0;
    final String alignment = block.metadata['alignment'] ?? 'center';

    return Column(
      children: [
        Image.network(block.content, fit: BoxFit.cover),
        const SizedBox(height: 16),

        Text('Largeur: ${width.round()}%'),
        Slider(
          value: width,
          min: 10.0,
          max: 100.0,
          divisions: 9,
          label: '${width.round()}%',
          onChanged: (value) {
            onMetadataChanged({'width': value});
          },
        ),

        Text('Alignement'),
        ToggleButtons(
          isSelected: [
            alignment == 'left',
            alignment == 'center',
            alignment == 'right',
          ],
          onPressed: (index) {
            final newAlignment = ['left', 'center', 'right'][index];
            onMetadataChanged({'alignment': newAlignment});
          },
          borderRadius: BorderRadius.circular(8),
          children: const [
            Icon(Icons.format_align_left),
            Icon(Icons.format_align_center),
            Icon(Icons.format_align_right),
          ],
        ),
      ],
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
      case ContentBlockType.quiz:
        return 'Bloc Quiz';
      default:
        return 'Bloc inconnu';
    }
  }
}

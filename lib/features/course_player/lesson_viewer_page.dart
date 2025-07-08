// lib/features/course_player/lesson_viewer_page.dart
import 'package:chewie/chewie.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart';
import 'package:modula_lms/features/course_player/course_player_logic.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class LessonViewerPage extends StatelessWidget {
  final int lessonId;
  final String courseId;

  const LessonViewerPage({
    super.key,
    required this.lessonId,
    required this.courseId,
  });

  @override
  Widget build(BuildContext context) {
    final studentId = context.read<AuthenticationBloc>().state.user.id;

    // On utilise MultiBlocProvider pour fournir les deux BLoCs à l'arbre des widgets.
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<LessonDetailBloc>()
            ..add(FetchLessonDetails(lessonId: lessonId, studentId: studentId)),
        ),
        // Le QuizBloc est maintenant fourni ici pour être accessible globalement sur la page.
        BlocProvider(
          create: (context) =>
              sl<QuizBloc>()
                ..add(FetchQuiz(lessonId: lessonId, studentId: studentId)),
        ),
      ],
      child: Scaffold(
        body: BlocConsumer<LessonDetailBloc, LessonDetailState>(
          listener: (context, state) {
            if (state is LessonDetailSubmitSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Travail rendu avec succès !'),
                  backgroundColor: Colors.green,
                ),
              );
            }
            if (state is LessonDetailError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur : ${state.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is LessonDetailLoading || state is LessonDetailInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is LessonDetailLoaded) {
              return _buildLessonContent(context, state);
            }
            if (state is LessonDetailError) {
              return Center(child: Text(state.message));
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildLessonContent(BuildContext context, LessonDetailLoaded state) {
    final lesson = state.lesson;
    final isAssignment =
        lesson.lessonType == LessonType.devoir ||
        lesson.lessonType == LessonType.evaluation;

    return CustomScrollView(
      slivers: [
        SliverAppBar(title: Text(lesson.title), pinned: true, floating: true),

        if (isAssignment)
          SliverToBoxAdapter(
            child: AssignmentViewWidget(lesson: lesson, courseId: courseId),
          ),

        if (lesson.contentBlocks.isEmpty)
          const SliverFillRemaining(
            child: Center(child: Text("Cette activité n'a pas d'énoncé.")),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final block = lesson.contentBlocks[index];
              return _buildBlockWidget(context, block, lesson.id);
            }, childCount: lesson.contentBlocks.length),
          ),
      ],
    );
  }

  Widget _buildBlockWidget(
    BuildContext context,
    ContentBlockEntity block,
    int lessonId,
  ) {
    switch (block.blockType) {
      case ContentBlockType.submission_placeholder:
        return const SubmissionPlaceholderWidget();

      case ContentBlockType.text:
        return TextContentWidget(
          markdownContent: block.content,
          metadata: block.metadata,
        );
      case ContentBlockType.video:
        final videoId = YoutubePlayer.convertUrlToId(block.content);
        if (videoId != null && videoId.isNotEmpty) {
          return YouTubeBlockWidget(videoId: videoId);
        } else {
          return VideoPlayerWidget(videoUrl: block.content);
        }
      case ContentBlockType.image:
        return ImageWidget(imageUrl: block.content, metadata: block.metadata);
      case ContentBlockType.document:
        final pdfUrl = block.content;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: FilledButton.icon(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Ouvrir le document'),
            onPressed: () {
              context.push(
                '/pdf-viewer',
                extra: {
                  'url': pdfUrl,
                  'title': block.metadata['fileName'] ?? 'Document',
                },
              );
            },
          ),
        );
      case ContentBlockType.quiz:
        return QuizBlockWidget(lessonId: lessonId);
      case ContentBlockType.unknown:
      default:
        return const SizedBox.shrink();
    }
  }
}

// =======================================================================
// WIDGET POUR LA VUE DEVOIR/ÉVALUATION (Mis à jour)
// =======================================================================
class AssignmentViewWidget extends StatelessWidget {
  final LessonEntity lesson;
  final String courseId;

  const AssignmentViewWidget({
    super.key,
    required this.lesson,
    required this.courseId,
  });

  @override
  Widget build(BuildContext context) {
    // On écoute les deux BLoCs pour obtenir toutes les informations nécessaires.
    final lessonDetailState = context.watch<LessonDetailBloc>().state;
    final quizState = context.watch<QuizBloc>().state;

    // Sécurité : si l'état n'est pas encore chargé, on n'affiche rien.
    if (lessonDetailState is! LessonDetailLoaded) {
      return const SizedBox.shrink();
    }

    // Extraction des données des états.
    final submissionContent = lessonDetailState.submissionContent;
    final submission = lesson.submission;

    // =======================================================================
    // NOUVELLE LOGIQUE DE VALIDATION DE LA SOUMISSION
    // =======================================================================
    final hasQuiz = lesson.contentBlocks.any(
      (b) => b.blockType == ContentBlockType.quiz,
    );
    final hasSubmissionPlaceholder = lesson.contentBlocks.any(
      (b) => b.blockType == ContentBlockType.submission_placeholder,
    );

    // [CORRECTION] : On vérifie maintenant si le quiz a été soumis (validé)
    // et non plus si une simple réponse a été sélectionnée.
    final isQuizSubmitted = quizState.status == QuizStatus.submitted;

    // Condition 2 : L'élève a-t-il téléversé au moins un fichier (et l'upload est terminé) ?
    final isFileUploaded = submissionContent.any(
      (b) => b.uploadStatus == UploadStatus.completed,
    );

    bool isReadyToSubmit = false;

    // Cas 1 : Placeholder ET Quiz
    if (hasSubmissionPlaceholder && hasQuiz) {
      isReadyToSubmit = isFileUploaded && isQuizSubmitted;
      // Cas 2 : Placeholder seulement
    } else if (hasSubmissionPlaceholder) {
      isReadyToSubmit = isFileUploaded;
      // Cas 3 : Quiz seulement
    } else if (hasQuiz) {
      isReadyToSubmit = isQuizSubmitted;
      // Cas 4 : Ni placeholder, ni quiz (l'élève doit juste confirmer la lecture)
    } else {
      isReadyToSubmit = true;
    }

    final bool canSubmit = submission == null;

    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusChip(context, submission),
            const SizedBox(height: 16),
            if (lesson.dueDate != null)
              _buildInfoRow(
                Icons.calendar_today_outlined,
                'À rendre avant le :',
                DateFormat('dd/MM/yyyy à HH:mm').format(lesson.dueDate!),
              ),
            if (submission != null)
              _buildInfoRow(
                Icons.check_circle_outline,
                'Rendu le :',
                DateFormat(
                  'dd/MM/yyyy à HH:mm',
                ).format(submission.submissionDate),
              ),
            if (submission?.grade != null)
              _buildInfoRow(
                Icons.star_border_purple500_outlined,
                'Note :',
                '${submission!.grade!.toStringAsFixed(1)} / 20.0',
              ),
            const Divider(height: 32),
            Center(
              child: canSubmit
                  ? FilledButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Confirmer et Rendre le Travail'),
                      // Le bouton est activé si `canSubmit` ET `isReadyToSubmit` sont vrais.
                      onPressed: canSubmit && isReadyToSubmit
                          ? () => _confirmSubmission(context)
                          : null,
                    )
                  : const Text(
                      'Votre travail a été rendu et ne peut plus être modifié.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSubmission(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmer le rendu ?'),
        content: const Text(
          'Une fois rendu, vous ne pourrez plus modifier votre travail. Êtes-vous sûr de vouloir continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final studentId = context
                  .read<AuthenticationBloc>()
                  .state
                  .user
                  .id;
              context.read<LessonDetailBloc>().add(
                SubmitAssignment(
                  lessonId: lesson.id,
                  courseId: int.parse(courseId),
                  studentId: studentId,
                ),
              );
              Navigator.pop(dialogContext);
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text('$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, SubmissionEntity? submission) {
    String label;
    Color color;
    IconData icon;
    if (submission?.status == 'graded') {
      label = 'Noté';
      color = Colors.green;
      icon = Icons.check_circle;
    } else if (submission != null) {
      label = 'Rendu';
      color = Colors.blue;
      icon = Icons.task_alt;
    } else {
      label = 'À Rendre';
      color = Colors.orange;
      icon = Icons.pending_actions;
    }
    return Chip(
      avatar: Icon(icon, color: Colors.white, size: 18),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color,
      elevation: 2,
    );
  }
}

// =======================================================================
// WIDGET POUR LE PLACEHOLDER DE RENDU
// =======================================================================
class SubmissionPlaceholderWidget extends StatelessWidget {
  const SubmissionPlaceholderWidget({super.key});

  Future<void> _pickAndUploadFile(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      final file = XFile(result.files.single.path!);
      if (context.mounted) {
        context.read<LessonDetailBloc>().add(UploadSubmissionFile(file));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LessonDetailBloc, LessonDetailState>(
      builder: (context, state) {
        if (state is! LessonDetailLoaded) {
          return const SizedBox.shrink();
        }

        if (state.lesson.submission != null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...state.submissionContent.map((block) {
                return Card(
                  elevation: 1,
                  child: ListTile(
                    leading: block.uploadStatus == UploadStatus.uploading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.insert_drive_file_outlined),
                    title: Text(block.metadata['fileName'] ?? 'Fichier'),
                    subtitle: Text(
                      block.uploadStatus.name,
                      style: TextStyle(
                        color: block.uploadStatus == UploadStatus.failed
                            ? Colors.red
                            : null,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () {
                        context.read<LessonDetailBloc>().add(
                          RemoveSubmissionFile(block.localId),
                        );
                      },
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Ajouter un fichier'),
                onPressed: () => _pickAndUploadFile(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

// =======================================================================
// WIDGETS DE VISUALISATION (Inchangés)
// =======================================================================
class ImageWidget extends StatelessWidget {
  final String? imageUrl;
  final Map<String, dynamic> metadata;
  const ImageWidget({super.key, this.imageUrl, required this.metadata});

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    final double widthFactor =
        ((metadata['width'] as num?)?.toDouble() ?? 100.0) / 100.0;
    final String alignmentStr = metadata['alignment'] ?? 'center';

    Alignment alignment;
    switch (alignmentStr) {
      case 'left':
        alignment = Alignment.centerLeft;
        break;
      case 'right':
        alignment = Alignment.centerRight;
        break;
      default:
        alignment = Alignment.center;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Align(
        alignment: alignment,
        child: FractionallySizedBox(
          widthFactor: widthFactor,
          child: Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.broken_image, size: 40, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}

class TextContentWidget extends StatelessWidget {
  final String? markdownContent;
  final Map<String, dynamic> metadata;
  const TextContentWidget({
    super.key,
    this.markdownContent,
    required this.metadata,
  });

  TextStyle _getTextStyle(BuildContext context, String style) {
    final textTheme = Theme.of(context).textTheme;
    switch (style) {
      case 'h1':
        return textTheme.headlineSmall ??
            const TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
      case 'h2':
        return textTheme.titleLarge ??
            const TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
      case 'paragraph':
      default:
        return textTheme.bodyMedium ?? const TextStyle(fontSize: 16);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (markdownContent == null || markdownContent!.isEmpty) {
      return const SizedBox.shrink();
    }

    final style = metadata['style'] ?? 'paragraph';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: MarkdownBody(
        data: markdownContent!,
        styleSheet: MarkdownStyleSheet.fromTheme(
          Theme.of(context),
        ).copyWith(p: _getTextStyle(context, style)),
      ),
    );
  }
}

class YouTubeBlockWidget extends StatefulWidget {
  final String videoId;
  const YouTubeBlockWidget({super.key, required this.videoId});

  @override
  State<YouTubeBlockWidget> createState() => _YouTubeBlockWidgetState();
}

class _YouTubeBlockWidgetState extends State<YouTubeBlockWidget> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        forceHD: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String? videoUrl;
  const VideoPlayerWidget({super.key, this.videoUrl});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl != null && Uri.tryParse(widget.videoUrl!) != null) {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl!),
      );
      _videoPlayerController
          .initialize()
          .then((_) {
            if (mounted) {
              setState(() {
                _chewieController = ChewieController(
                  videoPlayerController: _videoPlayerController,
                  autoPlay: false,
                  looping: false,
                  aspectRatio: 16 / 9,
                );
              });
            }
          })
          .catchError((error) {
            if (mounted) {
              setState(() {
                _hasError = true;
              });
            }
          });
    } else {
      _hasError = true;
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) return const SizedBox.shrink();
    if (_chewieController == null) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Chewie(controller: _chewieController!),
      ),
    );
  }
}

class QuizBlockWidget extends StatelessWidget {
  final int lessonId;

  const QuizBlockWidget({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuizBloc, QuizState>(
      builder: (context, state) {
        switch (state.status) {
          case QuizStatus.loading:
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          case QuizStatus.failure:
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Erreur : ${state.error}",
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          case QuizStatus.submitted:
            return _buildQuizResult(context, state);
          case QuizStatus.loaded:
            if (!state.canAttemptQuiz) {
              return _buildAttemptsExceeded(context);
            }
            return _buildQuizForm(context, state);
          case QuizStatus.initial:
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildQuizForm(BuildContext context, QuizState state) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              state.quiz.title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (state.quiz.description != null &&
                state.quiz.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  state.quiz.description!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const Divider(height: 32),
            ...state.quiz.questions.map((question) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.text,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...question.answers.map((answer) {
                      return RadioListTile<int>(
                        title: Text(answer.text),
                        value: answer.id,
                        groupValue: state.userAnswers[question.id],
                        onChanged: (value) {
                          if (value != null) {
                            context.read<QuizBloc>().add(
                              AnswerSelected(
                                questionId: question.id,
                                answerId: value,
                              ),
                            );
                          }
                        },
                      );
                    }),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            Center(
              child: FilledButton(
                onPressed: () {
                  final studentId = context
                      .read<AuthenticationBloc>()
                      .state
                      .user
                      .id;
                  context.read<QuizBloc>().add(
                    SubmitQuiz(studentId: studentId, lessonId: lessonId),
                  );
                },
                child: const Text("Valider mes réponses"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizResult(BuildContext context, QuizState state) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              "Quiz terminé !",
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.green.shade800),
            ),
            const SizedBox(height: 16),
            Text(
              "Votre score :",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              "${state.score?.toStringAsFixed(0) ?? '0'}%",
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: Colors.green.shade900,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttemptsExceeded(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade800, size: 40),
            const SizedBox(height: 16),
            Text(
              "Tentatives épuisées",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.orange.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Vous avez déjà atteint le nombre maximum de tentatives pour ce quiz.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

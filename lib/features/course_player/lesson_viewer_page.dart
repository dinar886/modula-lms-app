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

  // NOUVELLE MÉTHODE pour marquer la leçon comme terminée
  void _markLessonAsViewed(BuildContext context) {
    final lessonDetailState = context.read<LessonDetailBloc>().state;
    if (lessonDetailState is LessonDetailLoaded) {
      final lesson = lessonDetailState.lesson;
      // On ne marque comme "vu" que si ce n'est pas un devoir et si ce n'est pas déjà fait.
      final isCompletableByView =
          lesson.lessonType != LessonType.devoir &&
          lesson.lessonType != LessonType.evaluation;
      if (isCompletableByView && !lesson.isCompleted) {
        final userId = context.read<AuthenticationBloc>().state.user.id;
        // On utilise le CourseContentBloc, qui est accessible via le service locator
        // ou pourrait être passé en paramètre si nécessaire. Pour l'instant, c'est la solution la plus simple.
        sl<CourseContentBloc>().add(
          MarkLessonAsCompleted(
            lessonId: lessonId,
            courseId: int.parse(courseId),
            userId: userId,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentId = context.read<AuthenticationBloc>().state.user.id;

    // Le BlocProvider pour le LessonDetailBloc gère l'état de la leçon.
    return BlocProvider(
      create: (context) =>
          sl<LessonDetailBloc>()
            ..add(FetchLessonDetails(lessonId: lessonId, studentId: studentId)),
      child: Scaffold(
        body: BlocConsumer<LessonDetailBloc, LessonDetailState>(
          listener: (context, state) {
            // Une fois la leçon chargée, on vérifie si on doit la marquer comme vue.
            if (state is LessonDetailLoaded) {
              _markLessonAsViewed(context);
            }
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

        // Si c'est un devoir, on affiche le widget de gestion du rendu.
        if (isAssignment)
          SliverToBoxAdapter(
            child: AssignmentViewWidget(lesson: lesson, courseId: courseId),
          ),

        // Affiche l'énoncé de la leçon (les blocs de contenu).
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

  // Affiche le widget approprié en fonction du type de bloc.
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
        final quizId = int.tryParse(block.content) ?? 0;
        final maxAttempts =
            (block.metadata['max_attempts'] as num?)?.toInt() ?? -1;
        if (quizId > 0) {
          return QuizBlockWidget(
            quizId: quizId,
            lessonId: lessonId,
            maxAttempts: maxAttempts,
          );
        }
        return const SizedBox.shrink();

      case ContentBlockType.unknown:
      default:
        return const SizedBox.shrink();
    }
  }
}

// =======================================================================
// WIDGET POUR LA VUE DEVOIR/ÉVALUATION (Logique de validation corrigée)
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
    // On écoute l'état du LessonDetailBloc pour avoir les dernières informations.
    final lessonDetailState = context.watch<LessonDetailBloc>().state;

    if (lessonDetailState is! LessonDetailLoaded) {
      return const SizedBox.shrink();
    }

    final submissionContent = lessonDetailState.submissionContent;
    final submission = lesson.submission;

    // --- LOGIQUE DE VALIDATION CORRIGÉE ---

    // 1. On identifie ce qui est requis pour ce devoir.
    final allQuizBlocks = lesson.contentBlocks
        .where((b) => b.blockType == ContentBlockType.quiz)
        .toList();
    final allPlaceholderBlocks = lesson.contentBlocks
        .where((b) => b.blockType == ContentBlockType.submission_placeholder)
        .toList();

    final bool requiresQuiz = allQuizBlocks.isNotEmpty;
    final bool requiresFile = allPlaceholderBlocks.isNotEmpty;

    // 2. On vérifie si les conditions sont remplies.
    final bool allQuizzesCompleted =
        requiresQuiz &&
        lessonDetailState.completedQuizIds.length >= allQuizBlocks.length;

    final bool allFilesUploaded =
        requiresFile &&
        submissionContent.any((b) => b.uploadStatus == UploadStatus.completed);

    // 3. On détermine si le bouton "Rendre" doit être activé.
    bool isReadyToSubmit = false;
    if (requiresQuiz && requiresFile) {
      // Cas 1: Quiz ET Fichier requis
      isReadyToSubmit = allQuizzesCompleted && allFilesUploaded;
    } else if (requiresQuiz && !requiresFile) {
      // Cas 2: Uniquement Quiz requis
      isReadyToSubmit = allQuizzesCompleted;
    } else if (!requiresQuiz && requiresFile) {
      // Cas 3: Uniquement Fichier requis
      isReadyToSubmit = allFilesUploaded;
    }

    // On ne peut rendre le travail que s'il n'a pas déjà été soumis.
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
                      // Le bouton est activé seulement si `isReadyToSubmit` est vrai.
                      onPressed: isReadyToSubmit
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

// Le reste du fichier (widgets d'affichage des blocs) est identique au précédent.
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

// =======================================================================
// WIDGET DU QUIZ (FORTEMENT MODIFIÉ)
// =======================================================================
class QuizBlockWidget extends StatelessWidget {
  final int quizId;
  final int lessonId;
  final int maxAttempts;

  const QuizBlockWidget({
    super.key,
    required this.quizId,
    required this.lessonId,
    required this.maxAttempts,
  });

  @override
  Widget build(BuildContext context) {
    final studentId = context.read<AuthenticationBloc>().state.user.id;
    // Chaque QuizBlockWidget a son propre BlocProvider pour gérer son état local.
    return BlocProvider(
      create: (context) => sl<QuizBloc>()
        ..add(
          FetchQuiz(
            quizId: quizId,
            studentId: studentId,
            maxAttempts: maxAttempts,
          ),
        ),
      // BlocListener pour communiquer avec le LessonDetailBloc parent.
      child: BlocListener<QuizBloc, QuizState>(
        listener: (context, state) {
          // Si le quiz est terminé (résultat affiché ou tentatives épuisées),
          // on notifie la page parente.
          final isQuizFinished =
              state.status == QuizStatus.showingResult ||
              (state.status == QuizStatus.loaded && !state.canAttemptQuiz);

          if (isQuizFinished) {
            context.read<LessonDetailBloc>().add(QuizCompletedInLesson(quizId));
          }
        },
        child: BlocBuilder<QuizBloc, QuizState>(
          builder: (context, state) {
            switch (state.status) {
              case QuizStatus.loading:
              case QuizStatus.initial:
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );

              case QuizStatus.submitted:
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("Correction en cours..."),
                      ],
                    ),
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

              case QuizStatus.showingResult:
                return _buildQuizResult(context, state);

              case QuizStatus.loaded:
                if (!state.canAttemptQuiz) {
                  return _buildAttemptsExceeded(context, state);
                }
                return _buildQuizForm(context, state);

              default:
                return const SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }

  // --- Widget pour le formulaire du quiz (répondre aux questions) ---
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
                child: _buildQuestionInput(context, question, state),
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

  // NOUVEAU WIDGET : Pour afficher le bon type d'input par question
  Widget _buildQuestionInput(
    BuildContext context,
    QuestionEntity question,
    QuizState state,
  ) {
    if (question.questionType == QuestionType.fill_in_the_blank) {
      return _FillInTheBlankInput(question: question);
    }
    // Par défaut, c'est un QCM
    return _McqInput(
      question: question,
      groupValue: state.userAnswers[question.id],
    );
  }

  // --- Widget pour afficher les résultats détaillés du quiz ---
  Widget _buildQuizResult(BuildContext context, QuizState state) {
    final attempt = state.lastAttempt;
    if (attempt == null) {
      return const Center(child: Text("Aucune donnée de tentative trouvée."));
    }

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
              "Résultats du Quiz",
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Center(
              child: Chip(
                label: Text(
                  'Score : ${attempt.score.toStringAsFixed(1)} / 20.0',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: attempt.score >= 10
                    ? Colors.green
                    : Colors.red,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
            const Divider(height: 32),
            ...state.quiz.questions.map((question) {
              final userAnswer = attempt.answers[question.id];
              final bool isCorrect = question.questionType == QuestionType.mcq
                  ? userAnswer ==
                        question.answers.firstWhere((a) => a.isCorrect).id
                  : (userAnswer as String? ?? '').toLowerCase().trim() ==
                        (question.correctTextAnswer ?? '').toLowerCase().trim();

              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: _buildQuestionResult(
                  context,
                  question,
                  userAnswer,
                  isCorrect,
                ),
              );
            }),
            if (state.canAttemptQuiz) ...[
              const Divider(height: 32),
              Center(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text("Recommencer le Quiz"),
                  onPressed: () {
                    context.read<QuizBloc>().add(RestartQuiz());
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // NOUVEAU WIDGET : Pour afficher la correction d'une question
  Widget _buildQuestionResult(
    BuildContext context,
    QuestionEntity question,
    dynamic userAnswer,
    bool isCorrect,
  ) {
    if (question.questionType == QuestionType.fill_in_the_blank) {
      return _FillInTheBlankResult(
        question: question,
        userAnswer: userAnswer as String? ?? '',
        isCorrect: isCorrect,
      );
    }

    // Par défaut, QCM
    return _McqResult(
      question: question,
      selectedAnswerId: userAnswer as int?,
      isCorrect: isCorrect,
    );
  }

  // --- Widget pour le message "Tentatives épuisées" ---
  Widget _buildAttemptsExceeded(BuildContext context, QuizState state) {
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
            if (state.lastAttempt != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.read<QuizBloc>().add(
                    FetchQuiz(
                      quizId: state.quiz.id,
                      studentId: context
                          .read<AuthenticationBloc>()
                          .state
                          .user
                          .id,
                      maxAttempts: 0,
                    ),
                  );
                },
                child: const Text("Voir mon dernier résultat"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// --- WIDGETS SPÉCIFIQUES POUR LES TYPES DE QUESTIONS ---

// --- INPUTS ---
class _McqInput extends StatelessWidget {
  final QuestionEntity question;
  final int? groupValue;
  const _McqInput({required this.question, this.groupValue});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question.text, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...question.answers.map((answer) {
          return RadioListTile<int>(
            title: Text(answer.text),
            value: answer.id,
            groupValue: groupValue,
            onChanged: (value) {
              if (value != null) {
                context.read<QuizBloc>().add(
                  AnswerSelected(questionId: question.id, answerId: value),
                );
              }
            },
          );
        }),
      ],
    );
  }
}

class _FillInTheBlankInput extends StatelessWidget {
  final QuestionEntity question;
  const _FillInTheBlankInput({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    final parts = question.text.split('{{blank}}');
    final textBefore = parts.isNotEmpty ? parts[0] : '';
    final textAfter = parts.length > 1 ? parts[1] : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 8,
          children: [
            if (textBefore.isNotEmpty)
              Text(textBefore, style: Theme.of(context).textTheme.titleMedium),
            SizedBox(
              width: 150,
              child: TextField(
                onChanged: (value) {
                  context.read<QuizBloc>().add(
                    TextAnswerChanged(questionId: question.id, text: value),
                  );
                },
                decoration: const InputDecoration(
                  hintText: 'Votre réponse',
                  isDense: true,
                ),
              ),
            ),
            if (textAfter.isNotEmpty)
              Text(textAfter, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ],
    );
  }
}

// --- RESULTS ---

class _McqResult extends StatelessWidget {
  final QuestionEntity question;
  final int? selectedAnswerId;
  final bool isCorrect;
  const _McqResult({
    required this.question,
    this.selectedAnswerId,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question.text, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ...question.answers.map((answer) {
          final bool isSelected = answer.id == selectedAnswerId;
          final bool isCorrectAnswer = answer.isCorrect;

          Color? tileColor;
          Icon? trailingIcon;

          if (isCorrectAnswer) {
            tileColor = Colors.green.withOpacity(0.15);
            trailingIcon = const Icon(Icons.check_circle, color: Colors.green);
          }
          if (isSelected && !isCorrectAnswer) {
            tileColor = Colors.red.withOpacity(0.15);
            trailingIcon = const Icon(Icons.cancel, color: Colors.red);
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: tileColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              title: Text(answer.text),
              leading: Radio<int>(
                value: answer.id,
                groupValue: selectedAnswerId,
                onChanged: null,
              ),
              trailing: trailingIcon,
            ),
          );
        }),
      ],
    );
  }
}

class _FillInTheBlankResult extends StatelessWidget {
  final QuestionEntity question;
  final String userAnswer;
  final bool isCorrect;
  const _FillInTheBlankResult({
    required this.question,
    required this.userAnswer,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final parts = question.text.split('{{blank}}');
    final textBefore = parts.isNotEmpty ? parts[0] : '';
    final textAfter = parts.length > 1 ? parts[1] : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            if (textBefore.isNotEmpty)
              Text(textBefore, style: Theme.of(context).textTheme.titleMedium),
            Text(
              userAnswer.isNotEmpty ? userAnswer : '______',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isCorrect ? Colors.green : Colors.red,
                decoration: isCorrect
                    ? TextDecoration.none
                    : TextDecoration.lineThrough,
              ),
            ),
            if (textAfter.isNotEmpty)
              Text(textAfter, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        if (!isCorrect)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              "Bonne réponse : ${question.correctTextAnswer}",
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

// lib/features/course_player/lesson_viewer_page.dart
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:modula_lms/core/di/service_locator.dart';
// J'importe le BLoC d'authentification pour récupérer l'ID de l'utilisateur.
import 'package:modula_lms/features/1_auth/auth_feature.dart';
import 'package:modula_lms/features/course_player/course_player_logic.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class LessonViewerPage extends StatelessWidget {
  final int lessonId;
  const LessonViewerPage({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context) {
    // On fournit le BLoC qui charge les détails de la leçon.
    return BlocProvider(
      create: (context) =>
          sl<LessonDetailBloc>()..add(FetchLessonDetails(lessonId)),
      child: Scaffold(
        // Le corps de la page est un BlocBuilder qui réagit aux états du LessonDetailBloc.
        body: BlocBuilder<LessonDetailBloc, LessonDetailState>(
          builder: (context, state) {
            // Affiche un indicateur de chargement.
            if (state is LessonDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            // Si la leçon est chargée avec succès, on construit son contenu.
            if (state is LessonDetailLoaded) {
              return _buildLessonContent(context, state.lesson);
            }
            // En cas d'erreur, on affiche le message.
            if (state is LessonDetailError) {
              return Center(child: Text(state.message));
            }
            // Par défaut, on n'affiche rien.
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  /// Construit la vue de la leçon avec une barre d'application et la liste des blocs de contenu.
  Widget _buildLessonContent(BuildContext context, LessonEntity lesson) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(title: Text(lesson.title), pinned: true, floating: true),
        // Si la leçon n'a pas de contenu, on affiche un message.
        if (lesson.contentBlocks.isEmpty)
          const SliverFillRemaining(
            child: Center(child: Text("Cette leçon est actuellement vide.")),
          )
        else
          // Sinon, on construit la liste des blocs.
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final block = lesson.contentBlocks[index];
              // On passe le bloc de contenu et l'ID de la leçon pour la construction du widget.
              return _buildBlockWidget(context, block, lesson.id);
            }, childCount: lesson.contentBlocks.length),
          ),
      ],
    );
  }

  /// Construit le widget approprié en fonction du type de bloc de contenu.
  Widget _buildBlockWidget(
    BuildContext context,
    ContentBlockEntity block,
    int lessonId, // On a besoin de l'ID de la leçon pour le quiz.
  ) {
    switch (block.blockType) {
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
              // Navigation vers la page de visualisation de PDF.
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
        final quizId = int.tryParse(block.content);
        if (quizId != null) {
          // CORRECTION : On passe maintenant l'ID de la leçon au widget du quiz.
          return QuizBlockWidget(lessonId: lessonId);
        }
        return const SizedBox.shrink();

      case ContentBlockType.unknown:
      default:
        return const SizedBox.shrink();
    }
  }
}

// =======================================================================
// WIDGET POUR LE BLOC QUIZ (MIS À JOUR)
// =======================================================================
class QuizBlockWidget extends StatelessWidget {
  // CORRECTION : Le widget a maintenant besoin de l'ID de la leçon, pas du quiz.
  // L'ID du quiz sera récupéré depuis les détails de la leçon dans le BLoC.
  final int lessonId;

  const QuizBlockWidget({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context) {
    // On récupère l'ID de l'étudiant connecté.
    final studentId = context.read<AuthenticationBloc>().state.user.id;

    // On fournit le QuizBloc au sous-arbre de widgets.
    return BlocProvider(
      create: (context) => sl<QuizBloc>()
        // CORRECTION : L'événement `FetchQuiz` est maintenant appelé avec les bons paramètres nommés.
        ..add(FetchQuiz(lessonId: lessonId, studentId: studentId)),
      child: BlocBuilder<QuizBloc, QuizState>(
        builder: (context, state) {
          // On affiche différents widgets en fonction de l'état du quiz.
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
              // Affiche le résultat après soumission.
              return _buildQuizResult(context, state);
            case QuizStatus.loaded:
              // Si le quiz est chargé mais que l'étudiant ne peut pas le tenter, on affiche un message.
              if (!state.canAttemptQuiz) {
                return _buildAttemptsExceeded(context);
              }
              // Sinon, on affiche le formulaire du quiz.
              return _buildQuizForm(context, state);
            case QuizStatus.initial:
            default:
              return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  /// Construit le formulaire du quiz avec les questions et les réponses.
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
            // On itère sur chaque question pour l'afficher.
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
                    // On itère sur les réponses possibles pour chaque question.
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
                  // CORRECTION : L'événement `SubmitQuiz` a maintenant aussi besoin des IDs.
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

  /// Construit le widget affichant le résultat du quiz.
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

  /// Construit le widget affiché lorsque l'étudiant a dépassé le nombre de tentatives.
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

// =======================================================================
// WIDGETS DE VISUALISATION (INCHANGÉS)
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

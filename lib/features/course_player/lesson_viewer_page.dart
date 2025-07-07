// lib/features/course_player/lesson_viewer_page.dart
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart'; // Assurez-vous que cette importation est présente
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/course_player/course_player_logic.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class LessonViewerPage extends StatelessWidget {
  final int lessonId;
  const LessonViewerPage({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<LessonDetailBloc>()..add(FetchLessonDetails(lessonId)),
      child: Scaffold(
        body: BlocBuilder<LessonDetailBloc, LessonDetailState>(
          builder: (context, state) {
            if (state is LessonDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is LessonDetailLoaded) {
              return _buildLessonContent(context, state.lesson);
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

  Widget _buildLessonContent(BuildContext context, LessonEntity lesson) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(title: Text(lesson.title), pinned: true),
        if (lesson.contentBlocks.isEmpty)
          const SliverFillRemaining(
            child: Center(child: Text("Cette leçon est vide.")),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final block = lesson.contentBlocks[index];
              // On passe le titre de la leçon pour l'utiliser comme titre du document
              return _buildBlockWidget(context, block, lesson.title);
            }, childCount: lesson.contentBlocks.length),
          ),
      ],
    );
  }

  /// Construit le widget approprié pour chaque type de bloc de contenu.
  Widget _buildBlockWidget(
    BuildContext context,
    ContentBlockEntity block,
    String lessonTitle,
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

      // --- CORRECTION POUR LE DOCUMENT PDF ---
      case ContentBlockType.document:
        final pdfUrl = block.content;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: FilledButton.icon(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Ouvrir le document'),
            onPressed: () {
              // Navigue vers la page du visualiseur PDF
              context.push(
                '/pdf-viewer',
                extra: {
                  'url': pdfUrl,
                  'title': lessonTitle, // On utilise le titre de la leçon
                },
              );
            },
          ),
        );

      case ContentBlockType.quiz:
        final quizId = int.tryParse(block.content);
        if (quizId != null) {
          return QuizBlockWidget(quizId: quizId);
        }
        return const SizedBox.shrink();

      case ContentBlockType.unknown:
      default:
        return const SizedBox.shrink();
    }
  }
}

// =======================================================================
// WIDGET POUR LE QUIZ (inchangé)
// =======================================================================
class QuizBlockWidget extends StatelessWidget {
  final int quizId;

  const QuizBlockWidget({super.key, required this.quizId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<QuizBloc>()..add(FetchQuiz(quizId)),
      child: BlocBuilder<QuizBloc, QuizState>(
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
                    "Erreur lors du chargement du quiz : ${state.error}",
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            case QuizStatus.submitted:
              return _buildQuizResult(context, state);
            case QuizStatus.loaded:
            case QuizStatus.initial:
            default:
              return _buildQuizForm(context, state);
          }
        },
      ),
    );
  }

  Widget _buildQuizForm(BuildContext context, QuizState state) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.quiz.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (state.quiz.description != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(state.quiz.description!),
              ),
            const Divider(height: 24),
            ...state.quiz.questions.map((question) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.text,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
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
                  const SizedBox(height: 16),
                ],
              );
            }).toList(),
            const SizedBox(height: 16),
            Center(
              child: FilledButton(
                onPressed: () => context.read<QuizBloc>().add(SubmitQuiz()),
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
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Résultats du Quiz",
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.blue.shade800),
            ),
            const SizedBox(height: 16),
            Text(
              "Votre score : ${state.score?.toStringAsFixed(0) ?? '0'}%",
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(color: Colors.blue.shade900),
            ),
          ],
        ),
      ),
    );
  }
}

// =======================================================================
// WIDGETS DE VISUALISATION (CORRIGÉS ET INCHANGÉS)
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

    // --- CORRECTION DE LA TAILLE DE L'IMAGE ---
    // On s'assure que la valeur est un 'double' et on la divise par 100
    // pour obtenir un facteur de proportion (ex: 80.0 devient 0.8).
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
        forceHD: true,
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
        progressIndicatorColor: Colors.amber,
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
            setState(() {
              _chewieController = ChewieController(
                videoPlayerController: _videoPlayerController,
                autoPlay: false,
                looping: false,
                aspectRatio: 16 / 9,
              );
            });
          })
          .catchError((error) {
            setState(() {
              _hasError = true;
            });
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

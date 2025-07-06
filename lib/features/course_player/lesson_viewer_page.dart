// lib/features/course_player/lesson_viewer_page.dart
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/course_player/course_player_logic.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';
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
              return _buildBlockWidget(context, block);
            }, childCount: lesson.contentBlocks.length),
          ),
      ],
    );
  }

  Widget _buildBlockWidget(BuildContext context, ContentBlockEntity block) {
    switch (block.blockType) {
      case ContentBlockType.text:
        return TextContentWidget(markdownContent: block.content);

      case ContentBlockType.video:
        final videoId = YoutubePlayer.convertUrlToId(block.content);
        if (videoId != null && videoId.isNotEmpty) {
          return YouTubeBlockWidget(videoId: videoId);
        } else {
          return VideoPlayerWidget(videoUrl: block.content);
        }

      case ContentBlockType.image:
        return ImageWidget(imageUrl: block.content);

      case ContentBlockType.document:
        return DocumentLinkWidget(documentUrl: block.content);

      case ContentBlockType.unknown:
      default:
        return const SizedBox.shrink();
    }
  }
}

// WIDGET POUR LE LECTEUR YOUTUBE
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
      // **CORRECTION APPLIQUÉE ICI**
      // Le paramètre 'hideAnnotations' a été retiré.
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
      child: YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Colors.amber,
          progressColors: const ProgressBarColors(
            playedColor: Colors.amber,
            handleColor: Colors.amberAccent,
          ),
        ),
        builder: (context, player) {
          return player;
        },
      ),
    );
  }
}

// --- WIDGET POUR LE LECTEUR VIDÉO STANDARD ---
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
                errorBuilder: (context, errorMessage) {
                  return const Center(
                    child: Text(
                      "Erreur de chargement de la vidéo.",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                },
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
    if (_hasError) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.black,
        child: const Center(
          child: Text(
            'URL de la vidéo invalide ou manquante.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    if (_chewieController == null ||
        !_chewieController!.videoPlayerController.value.isInitialized) {
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

// --- WIDGET POUR L'IMAGE ---
class ImageWidget extends StatelessWidget {
  final String? imageUrl;
  const ImageWidget({super.key, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null ||
        imageUrl!.isEmpty ||
        Uri.tryParse(imageUrl!) == null) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('URL de l\'image invalide.')),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        loadingBuilder:
            (
              BuildContext context,
              Widget child,
              ImageChunkEvent? loadingProgress,
            ) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, size: 40, color: Colors.grey),
      ),
    );
  }
}

// --- WIDGET POUR LE CONTENU TEXTE ---
class TextContentWidget extends StatelessWidget {
  final String? markdownContent;
  const TextContentWidget({super.key, this.markdownContent});

  @override
  Widget build(BuildContext context) {
    if (markdownContent == null || markdownContent!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: MarkdownBody(data: markdownContent!),
    );
  }
}

// --- WIDGET POUR LE LIEN DOCUMENT ---
class DocumentLinkWidget extends StatelessWidget {
  final String? documentUrl;
  const DocumentLinkWidget({super.key, this.documentUrl});

  @override
  Widget build(BuildContext context) {
    if (documentUrl == null || documentUrl!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: FilledButton.icon(
        icon: const Icon(Icons.download_for_offline),
        label: const Text('Télécharger le document'),
        onPressed: () async {
          final uri = Uri.parse(documentUrl!);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Impossible d\'ouvrir le lien')),
            );
          }
        },
      ),
    );
  }
}

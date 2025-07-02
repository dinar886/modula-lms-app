import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/course_player/domain/entities/lesson_entity.dart';
import 'package:modula_lms/features/course_player/presentation/bloc/lesson_detail_bloc.dart';
import 'package:modula_lms/features/course_player/presentation/bloc/lesson_detail_event.dart';
import 'package:modula_lms/features/course_player/presentation/bloc/lesson_detail_state.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

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
        SliverToBoxAdapter(child: _buildContentView(lesson)),
      ],
    );
  }

  Widget _buildContentView(LessonEntity lesson) {
    switch (lesson.lessonType) {
      case LessonType.video:
        return VideoPlayerWidget(videoUrl: lesson.contentUrl);
      case LessonType.text:
        return TextContentWidget(markdownContent: lesson.contentText);
      case LessonType.document:
        return DocumentLinkWidget(documentUrl: lesson.contentUrl);
      default:
        return const Center(child: Text('Type de contenu non supporté.'));
    }
  }
}

// --- WIDGET POUR LE LECTEUR VIDÉO ---
class VideoPlayerWidget extends StatefulWidget {
  final String? videoUrl;
  const VideoPlayerWidget({super.key, this.videoUrl});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl != null) {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl!),
      );
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        aspectRatio: 16 / 9,
      );
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
    if (_chewieController == null) {
      return const Center(child: Text('URL de la vidéo non disponible.'));
    }
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Chewie(controller: _chewieController!),
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
      return const Center(child: Text('Contenu non disponible.'));
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
      return const Center(child: Text('Lien du document non disponible.'));
    }
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
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
      ),
    );
  }
}

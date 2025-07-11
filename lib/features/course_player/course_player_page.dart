// lib/features/course_player/course_player_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart'; // IMPORTANT : pour l'ID utilisateur
import 'package:modula_lms/features/2_marketplace/marketplace_logic.dart';
import 'package:modula_lms/features/course_player/course_player_logic.dart';

class CoursePlayerPage extends StatefulWidget {
  final CourseEntity course;
  const CoursePlayerPage({super.key, required this.course});

  @override
  State<CoursePlayerPage> createState() => _CoursePlayerPageState();
}

class _CoursePlayerPageState extends State<CoursePlayerPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userId = context.read<AuthenticationBloc>().state.user.id;

    return BlocProvider(
      create: (context) => sl<CourseContentBloc>()
        ..add(FetchCourseContent(courseId: widget.course.id, userId: userId)),
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0A0A0A)
            : const Color(0xFFF8F9FA),
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildModernAppBar(context, theme, isDark),
            _buildContent(theme, isDark),
          ],
        ),
      ),
    );
  }

  // L'AppBar reste identique
  Widget _buildModernAppBar(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    final expandedHeight = 280.0;
    final collapsedHeight = 120.0;
    final scrollProgress = (_scrollOffset / (expandedHeight - collapsedHeight))
        .clamp(0.0, 1.0);

    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDark ? Colors.black : Colors.white).withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? Colors.white : Colors.black87,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                      : [
                          theme.primaryColor.withOpacity(0.8),
                          theme.primaryColor,
                        ],
                ),
              ),
            ),
            // Pattern Overlay
            Opacity(
              opacity: 0.1,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/pattern.png'),
                    repeat: ImageRepeat.repeat,
                  ),
                ),
              ),
            ),
            // Content
            Positioned(
              left: 24,
              right: 24,
              bottom: 40,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.course.category ?? 'Cours',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.course.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28 - (scrollProgress * 10),
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Opacity(
                      opacity: 1 - scrollProgress,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.course.author,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, bool isDark) {
    return SliverToBoxAdapter(
      child: BlocBuilder<CourseContentBloc, CourseContentState>(
        builder: (context, state) {
          if (state is CourseContentLoading) {
            return _buildLoadingState(theme);
          }
          if (state is CourseContentLoaded) {
            return _buildLoadedContent(state, theme, isDark);
          }
          if (state is CourseContentError) {
            return _buildErrorState(state, theme);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // La méthode _buildLoadingState reste identique
  Widget _buildLoadingState(ThemeData theme) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement du contenu...',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // La méthode _buildLoadedContent reste identique
  Widget _buildLoadedContent(
    CourseContentLoaded state,
    ThemeData theme,
    bool isDark,
  ) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Progress Indicator
            _buildProgressIndicator(state, theme),
            const SizedBox(height: 24),
            // Sections
            ...state.sections.asMap().entries.map((entry) {
              final index = entry.key;
              final section = entry.value;
              return _buildSection(
                section,
                index,
                theme,
                isDark,
                state.sections.length,
              );
            }).toList(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Le widget de progression est maintenant fonctionnel
  Widget _buildProgressIndicator(CourseContentLoaded state, ThemeData theme) {
    final totalLessons = state.sections.fold<int>(
      0,
      (total, section) => total + section.lessons.length,
    );
    final completedLessons = state.sections.fold<int>(
      0,
      (total, section) =>
          total + section.lessons.where((l) => l.isCompleted).length,
    );
    final double progress = totalLessons > 0
        ? completedLessons / totalLessons
        : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withOpacity(0.05),
            theme.primaryColor.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progression du cours',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$completedLessons / $totalLessons leçons terminées',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  // La méthode _buildSection reste identique
  Widget _buildSection(
    SectionEntity section,
    int index,
    ThemeData theme,
    bool isDark,
    int totalSections,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: theme.copyWith(
          dividerColor: Colors.transparent,
          expansionTileTheme: const ExpansionTileThemeData(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
          ),
        ),
        child: ExpansionTile(
          initiallyExpanded: index == 0,
          title: Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.primaryColor.withOpacity(0.7),
                        theme.primaryColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${section.lessons.length} leçons',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.dividerColor.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: section.lessons.asMap().entries.map((entry) {
                  final lessonIndex = entry.key;
                  final lesson = entry.value;
                  final isLast = lessonIndex == section.lessons.length - 1;

                  // On utilise directement le champ `isCompleted` de la leçon.
                  return _buildLessonTile(
                    lesson,
                    lesson.isCompleted,
                    isLast,
                    theme,
                    isDark,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Le `ListTile` de la leçon affiche maintenant une icône de validation
  Widget _buildLessonTile(
    LessonEntity lesson,
    bool isCompleted,
    bool isLast,
    ThemeData theme,
    bool isDark,
  ) {
    final icon = _getIconForLessonType(lesson.lessonType);
    final color = _getColorForLessonType(lesson.lessonType, theme);

    return Container(
      decoration: BoxDecoration(
        border: !isLast
            ? Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withOpacity(0.1),
                  width: 1,
                ),
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            HapticFeedback.lightImpact();
            await context.push(
              '/lesson-viewer/${lesson.id}',
              extra: widget.course.id,
            );
            // Après le retour de la page de la leçon, on rafraîchit les données
            // pour mettre à jour la progression.
            if (mounted) {
              final userId = context.read<AuthenticationBloc>().state.user.id;
              context.read<CourseContentBloc>().add(
                FetchCourseContent(courseId: widget.course.id, userId: userId),
              );
            }
          },
          borderRadius: BorderRadius.only(
            bottomLeft: isLast ? const Radius.circular(20) : Radius.zero,
            bottomRight: isLast ? const Radius.circular(20) : Radius.zero,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (lesson.dueDate != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDueDate(lesson.dueDate!),
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // L'icône de validation est maintenant conditionnelle
                if (isCompleted)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // La méthode _buildErrorState reste identique
  Widget _buildErrorState(CourseContentError state, ThemeData theme) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.error_outline, color: Colors.red, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            'Oops! Une erreur est survenue',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.message,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              final userId = context.read<AuthenticationBloc>().state.user.id;
              context.read<CourseContentBloc>().add(
                FetchCourseContent(courseId: widget.course.id, userId: userId),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Réessayer',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // La méthode _getIconForLessonType reste identique
  IconData _getIconForLessonType(LessonType type) {
    switch (type) {
      case LessonType.video:
        return Icons.play_circle_fill;
      case LessonType.text:
        return Icons.article;
      case LessonType.document:
        return Icons.picture_as_pdf;
      case LessonType.quiz:
        return Icons.quiz;
      case LessonType.devoir:
        return Icons.assignment;
      case LessonType.evaluation:
        return Icons.assessment;
      default:
        return Icons.help_outline;
    }
  }

  // La méthode _getColorForLessonType reste identique
  Color _getColorForLessonType(LessonType type, ThemeData theme) {
    switch (type) {
      case LessonType.video:
        return Colors.blue;
      case LessonType.text:
        return Colors.orange;
      case LessonType.document:
        return Colors.red;
      case LessonType.quiz:
        return Colors.purple;
      case LessonType.devoir:
        return Colors.teal;
      case LessonType.evaluation:
        return Colors.indigo;
      default:
        return theme.primaryColor;
    }
  }

  // La méthode _formatDueDate reste identique
  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) {
      return "Aujourd'hui";
    } else if (difference == 1) {
      return "Demain";
    } else if (difference > 0) {
      return "Dans $difference jours";
    } else {
      return "En retard";
    }
  }
}

// lib/features/course_player/course_player_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/2_marketplace/marketplace_logic.dart';
import 'package:modula_lms/features/course_player/course_player_logic.dart';

class CoursePlayerPage extends StatelessWidget {
  final CourseEntity course;
  const CoursePlayerPage({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<CourseContentBloc>()..add(FetchCourseContent(course.id)),
      child: Scaffold(
        appBar: AppBar(title: Text(course.title)),
        body: BlocBuilder<CourseContentBloc, CourseContentState>(
          builder: (context, state) {
            if (state is CourseContentLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is CourseContentLoaded) {
              return ListView.builder(
                itemCount: state.sections.length,
                itemBuilder: (context, index) {
                  final section = state.sections[index];
                  return ExpansionTile(
                    title: Text(
                      section.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    initiallyExpanded: index == 0,
                    children: section.lessons.map((lesson) {
                      return ListTile(
                        leading: Icon(_getIconForLessonType(lesson.lessonType)),
                        title: Text(lesson.title),
                        onTap: () {
                          if (lesson.lessonType == LessonType.quiz) {
                            context.push('/quiz/${lesson.id}');
                          } else {
                            context.push('/lesson-viewer/${lesson.id}');
                          }
                        },
                      );
                    }).toList(),
                  );
                },
              );
            }
            if (state is CourseContentError) {
              return Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  IconData _getIconForLessonType(LessonType type) {
    switch (type) {
      case LessonType.video:
        return Icons.play_circle_outline;
      case LessonType.text:
        return Icons.article_outlined;
      case LessonType.document:
        return Icons.picture_as_pdf_outlined;
      case LessonType.quiz:
        return Icons.quiz_outlined;
      default:
        return Icons.help_outline;
    }
  }
}

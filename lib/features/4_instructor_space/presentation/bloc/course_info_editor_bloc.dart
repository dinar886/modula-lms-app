// lib/features/4_instructor_space/presentation/bloc/course_info_editor_bloc.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/core/api/api_client.dart';
import 'package:modula_lms/features/2_marketplace/data/models/course_model.dart';
import 'course_info_editor_event.dart';
import 'course_info_editor_state.dart';

class CourseInfoEditorBloc
    extends Bloc<CourseInfoEditorEvent, CourseInfoEditorState> {
  final ApiClient apiClient;

  CourseInfoEditorBloc({required this.apiClient})
    : super(const CourseInfoEditorState()) {
    on<LoadCourseInfo>(_onLoadCourseInfo);
    on<CourseInfoChanged>(_onCourseInfoChanged);
    // On enregistre le handler pour le nouvel événement.
    on<RemoveCourseImage>(_onRemoveCourseImage);
    on<SaveCourseInfoChanges>(_onSaveCourseInfoChanges);
  }

  /// Charge les détails du cours depuis l'API.
  Future<void> _onLoadCourseInfo(
    LoadCourseInfo event,
    Emitter<CourseInfoEditorState> emit,
  ) async {
    emit(state.copyWith(status: CourseInfoEditorStatus.loading));
    try {
      final response = await apiClient.get(
        '/api/v1/get_course_details.php',
        queryParameters: {'id': event.courseId},
      );
      final course = CourseModel.fromJson(response.data);
      emit(
        state.copyWith(
          status: CourseInfoEditorStatus.loaded,
          course: course,
          isDirty: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CourseInfoEditorStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  /// Met à jour l'état local lorsqu'un champ du formulaire est modifié.
  void _onCourseInfoChanged(
    CourseInfoChanged event,
    Emitter<CourseInfoEditorState> emit,
  ) {
    final newCourse = state.course.copyWith(
      title: event.title,
      description: event.description,
      price: event.price,
    );
    emit(
      state.copyWith(
        course: newCourse,
        newImageFile: event.newImageFile,
        newColor: event.newColor,
        isDirty: true,
        clearImage: event.clearImage,
      ),
    );
  }

  /// **NOUVELLE MÉTHODE** : Gère la suppression de l'image.
  void _onRemoveCourseImage(
    RemoveCourseImage event,
    Emitter<CourseInfoEditorState> emit,
  ) {
    // On récupère le titre et la couleur actuels pour générer un placeholder.
    final title = state.course.title;
    final color = state.newColor ?? const Color(0xFF005A9C);
    final hexColor = color.value.toRadixString(16).substring(2).toUpperCase();
    final encodedTitle = Uri.encodeComponent(title);
    final placeholderUrl =
        "https://placehold.co/600x400/$hexColor/FFFFFF/png?text=$encodedTitle";

    // On met à jour l'entité du cours avec la nouvelle URL du placeholder.
    final updatedCourse = state.course.copyWith(imageUrl: placeholderUrl);

    // On émet le nouvel état.
    emit(
      state.copyWith(
        course: updatedCourse,
        newImageFile:
            null, // On s'assure qu'aucun fichier local n'est en attente.
        clearImage:
            true, // On utilise ce flag pour forcer la suppression du fichier local.
        isDirty: true, // On marque le formulaire comme modifié.
      ),
    );
  }

  /// Gère la sauvegarde des modifications vers le backend.
  Future<void> _onSaveCourseInfoChanges(
    SaveCourseInfoChanges event,
    Emitter<CourseInfoEditorState> emit,
  ) async {
    if (!state.isDirty) return;

    emit(state.copyWith(status: CourseInfoEditorStatus.saving));
    try {
      final data = {
        'course_id': state.course.id,
        'title': state.course.title,
        'description': state.course.description,
        'price': state.course.price,
        if (state.newColor != null)
          'color':
              '#${state.newColor!.value.toRadixString(16).substring(2).toUpperCase()}',
      };

      final response = await apiClient.postMultipart(
        '/api/v1/edit_course.php',
        data: data,
        imageFile: state.newImageFile,
      );

      final newImageUrl = response.data['new_image_url'];
      final updatedCourse = state.course.copyWith(imageUrl: newImageUrl);

      emit(
        state.copyWith(
          status: CourseInfoEditorStatus.success,
          isDirty: false,
          course: updatedCourse,
          clearImage: true,
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: CourseInfoEditorStatus.failure,
          error: "Erreur API : ${e.response?.data['message'] ?? e.message}",
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CourseInfoEditorStatus.failure,
          error: "Une erreur inattendue est survenue : $e",
        ),
      );
    }
  }
}

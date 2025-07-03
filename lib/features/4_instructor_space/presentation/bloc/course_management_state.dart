import 'package:equatable/equatable.dart';

// Enum pour gérer les différents états du BLoC
enum CourseManagementStatus { initial, loading, success, failure }

class CourseManagementState extends Equatable {
  final CourseManagementStatus status;
  final String error;

  const CourseManagementState({
    this.status = CourseManagementStatus.initial,
    this.error = '',
  });

  // Ajout de la méthode copyWith pour corriger les erreurs de compilation
  CourseManagementState copyWith({
    CourseManagementStatus? status,
    String? error,
  }) {
    return CourseManagementState(
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }

  @override
  List<Object> get props => [status, error];
}

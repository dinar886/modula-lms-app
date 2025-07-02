import 'package:equatable/equatable.dart';

abstract class CourseManagementState extends Equatable {
  const CourseManagementState();
  @override
  List<Object> get props => [];
}

class CourseManagementInitial extends CourseManagementState {}

class CourseManagementLoading extends CourseManagementState {}

class CourseManagementSuccess extends CourseManagementState {}

class CourseManagementFailure extends CourseManagementState {
  final String error;
  const CourseManagementFailure(this.error);
}

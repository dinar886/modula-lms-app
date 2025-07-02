import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/features/3_learner_space/domain/get_my_courses_usecase.dart';
import 'package:modula_lms/features/3_learner_space/presentation/bloc/my_courses_event.dart';
import 'package:modula_lms/features/3_learner_space/presentation/bloc/my_courses_state.dart';

class MyCoursesBloc extends Bloc<MyCoursesEvent, MyCoursesState> {
  final GetMyCoursesUseCase getMyCoursesUseCase;

  MyCoursesBloc({required this.getMyCoursesUseCase})
    : super(MyCoursesInitial()) {
    on<FetchMyCourses>((event, emit) async {
      emit(MyCoursesLoading());
      try {
        final courses = await getMyCoursesUseCase(event.userId);
        emit(MyCoursesLoaded(courses));
      } catch (e) {
        emit(MyCoursesError(e.toString()));
      }
    });
  }
}

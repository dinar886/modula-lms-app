// lib/features/2_marketplace/marketplace_logic.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:modula_lms/core/api/api_client.dart';

//==============================================================================
// ENTITY
//==============================================================================
class CourseEntity extends Equatable {
  final String id;
  final String title;
  final String author;
  final String? description;
  final String imageUrl;
  final double price;
  final String? category;
  final double? rating;
  final int? enrollmentCount;

  const CourseEntity({
    required this.id,
    required this.title,
    required this.author,
    this.description,
    required this.imageUrl,
    required this.price,
    this.category,
    this.rating,
    this.enrollmentCount,
  });

  CourseEntity copyWith({
    String? id,
    String? title,
    String? author,
    String? description,
    String? imageUrl,
    double? price,
    String? category,
    double? rating,
    int? enrollmentCount,
  }) {
    return CourseEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      enrollmentCount: enrollmentCount ?? this.enrollmentCount,
    );
  }

  factory CourseEntity.fromJson(Map<String, dynamic> json) {
    return CourseEntity(
      id: json['id'].toString(),
      title: json['title'],
      author: json['author'],
      description: json['description'],
      imageUrl: json['image_url'],
      price: (json['price'] as num).toDouble(),
      category: json['category'],
      rating: json['rating'] != null
          ? (json['rating'] as num).toDouble()
          : null,
      enrollmentCount: json['enrollment_count'] as int?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    author,
    description,
    imageUrl,
    price,
    category,
    rating,
    enrollmentCount,
  ];
}

//==============================================================================
// ENUMS ET CLASSES POUR FILTRAGE
//==============================================================================
enum SortOption { popularity, priceAsc, priceDesc, rating, newest }

enum PriceRange { all, free, under50, under100, over100 }

class CourseFilter extends Equatable {
  final String searchQuery;
  final SortOption sortOption;
  final PriceRange priceRange;
  final List<String> selectedCategories;
  final List<String> selectedAuthors;

  const CourseFilter({
    this.searchQuery = '',
    this.sortOption = SortOption.popularity,
    this.priceRange = PriceRange.all,
    this.selectedCategories = const [],
    this.selectedAuthors = const [],
  });

  CourseFilter copyWith({
    String? searchQuery,
    SortOption? sortOption,
    PriceRange? priceRange,
    List<String>? selectedCategories,
    List<String>? selectedAuthors,
  }) {
    return CourseFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      sortOption: sortOption ?? this.sortOption,
      priceRange: priceRange ?? this.priceRange,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      selectedAuthors: selectedAuthors ?? this.selectedAuthors,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};

    if (searchQuery.isNotEmpty) {
      params['search'] = searchQuery;
    }

    params['sort'] = sortOption.name;

    if (priceRange != PriceRange.all) {
      params['price_range'] = priceRange.name;
    }

    if (selectedCategories.isNotEmpty) {
      params['categories'] = selectedCategories.join(',');
    }

    if (selectedAuthors.isNotEmpty) {
      params['authors'] = selectedAuthors.join(',');
    }

    return params;
  }

  @override
  List<Object?> get props => [
    searchQuery,
    sortOption,
    priceRange,
    selectedCategories,
    selectedAuthors,
  ];
}

//==============================================================================
// DATA SOURCE
//==============================================================================
abstract class CourseRemoteDataSource {
  Future<List<CourseEntity>> getCourses({CourseFilter? filter});
  Future<CourseEntity> getCourseDetails(String id);
  Future<Map<String, List<String>>> getFilterOptions();
}

class CourseRemoteDataSourceImpl implements CourseRemoteDataSource {
  final ApiClient apiClient;
  CourseRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<CourseEntity>> getCourses({CourseFilter? filter}) async {
    try {
      final response = await apiClient.get(
        '/api/v1/get_courses.php',
        queryParameters: filter?.toQueryParameters() ?? {},
      );
      return (response.data as List)
          .map((courseJson) => CourseEntity.fromJson(courseJson))
          .toList();
    } on DioException catch (e) {
      throw Exception('Impossible de récupérer les cours : $e');
    }
  }

  @override
  Future<CourseEntity> getCourseDetails(String id) async {
    try {
      final response = await apiClient.get(
        '/api/v1/get_course_details.php',
        queryParameters: {'id': id},
      );
      return CourseEntity.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Impossible de récupérer les détails du cours : $e');
    }
  }

  @override
  Future<Map<String, List<String>>> getFilterOptions() async {
    try {
      final response = await apiClient.get('/api/v1/get_filter_options.php');
      return {
        'categories': List<String>.from(response.data['categories'] ?? []),
        'authors': List<String>.from(response.data['authors'] ?? []),
      };
    } on DioException catch (e) {
      throw Exception('Impossible de récupérer les options de filtrage : $e');
    }
  }
}

//==============================================================================
// REPOSITORY
//==============================================================================
abstract class CourseRepository {
  Future<List<CourseEntity>> getCourses({CourseFilter? filter});
  Future<CourseEntity> getCourseDetails(String id);
  Future<Map<String, List<String>>> getFilterOptions();
}

class CourseRepositoryImpl implements CourseRepository {
  final CourseRemoteDataSource remoteDataSource;
  CourseRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<CourseEntity>> getCourses({CourseFilter? filter}) =>
      remoteDataSource.getCourses(filter: filter);

  @override
  Future<CourseEntity> getCourseDetails(String id) =>
      remoteDataSource.getCourseDetails(id);

  @override
  Future<Map<String, List<String>>> getFilterOptions() =>
      remoteDataSource.getFilterOptions();
}

//==============================================================================
// USE CASES
//==============================================================================
class GetCourses {
  final CourseRepository repository;
  GetCourses(this.repository);
  Future<List<CourseEntity>> call({CourseFilter? filter}) =>
      repository.getCourses(filter: filter);
}

class GetCourseDetails {
  final CourseRepository repository;
  GetCourseDetails(this.repository);
  Future<CourseEntity> call(String id) => repository.getCourseDetails(id);
}

class GetFilterOptions {
  final CourseRepository repository;
  GetFilterOptions(this.repository);
  Future<Map<String, List<String>>> call() => repository.getFilterOptions();
}

//==============================================================================
// BLOC EVENTS
//==============================================================================
abstract class CourseEvent extends Equatable {
  const CourseEvent();
  @override
  List<Object?> get props => [];
}

class FetchCourses extends CourseEvent {
  final CourseFilter? filter;
  const FetchCourses({this.filter});
  @override
  List<Object?> get props => [filter];
}

class UpdateSearchQuery extends CourseEvent {
  final String query;
  const UpdateSearchQuery(this.query);
  @override
  List<Object> get props => [query];
}

class UpdateSortOption extends CourseEvent {
  final SortOption sortOption;
  const UpdateSortOption(this.sortOption);
  @override
  List<Object> get props => [sortOption];
}

class UpdatePriceRange extends CourseEvent {
  final PriceRange priceRange;
  const UpdatePriceRange(this.priceRange);
  @override
  List<Object> get props => [priceRange];
}

class ToggleCategory extends CourseEvent {
  final String category;
  const ToggleCategory(this.category);
  @override
  List<Object> get props => [category];
}

class ToggleAuthor extends CourseEvent {
  final String author;
  const ToggleAuthor(this.author);
  @override
  List<Object> get props => [author];
}

class ClearFilters extends CourseEvent {}

class FetchCourseDetails extends CourseEvent {
  final String courseId;
  const FetchCourseDetails(this.courseId);
  @override
  List<Object> get props => [courseId];
}

class LoadFilterOptions extends CourseEvent {}

//==============================================================================
// BLOC STATES
//==============================================================================
abstract class CourseState extends Equatable {
  const CourseState();
  @override
  List<Object?> get props => [];
}

class CourseInitial extends CourseState {}

class CourseLoading extends CourseState {
  final bool isLoadingMore;
  const CourseLoading({this.isLoadingMore = false});
  @override
  List<Object> get props => [isLoadingMore];
}

class CourseListLoaded extends CourseState {
  final List<CourseEntity> courses;
  final CourseFilter currentFilter;
  final Map<String, List<String>> filterOptions;

  const CourseListLoaded({
    required this.courses,
    required this.currentFilter,
    this.filterOptions = const {},
  });

  @override
  List<Object> get props => [courses, currentFilter, filterOptions];
}

class CourseDetailLoaded extends CourseState {
  final CourseEntity course;
  const CourseDetailLoaded(this.course);
  @override
  List<Object> get props => [course];
}

class CourseError extends CourseState {
  final String message;
  const CourseError(this.message);
  @override
  List<Object> get props => [message];
}

//==============================================================================
// BLOCS
//==============================================================================
class CourseBloc extends Bloc<CourseEvent, CourseState> {
  final GetCourses getCourses;
  final GetFilterOptions getFilterOptions;

  CourseFilter _currentFilter = const CourseFilter();
  Map<String, List<String>> _filterOptions = {};

  CourseBloc({required this.getCourses, required this.getFilterOptions})
    : super(CourseInitial()) {
    on<FetchCourses>(_onFetchCourses);
    on<UpdateSearchQuery>(_onUpdateSearchQuery);
    on<UpdateSortOption>(_onUpdateSortOption);
    on<UpdatePriceRange>(_onUpdatePriceRange);
    on<ToggleCategory>(_onToggleCategory);
    on<ToggleAuthor>(_onToggleAuthor);
    on<ClearFilters>(_onClearFilters);
    on<LoadFilterOptions>(_onLoadFilterOptions);
  }

  Future<void> _onFetchCourses(
    FetchCourses event,
    Emitter<CourseState> emit,
  ) async {
    emit(CourseLoading());
    try {
      final filter = event.filter ?? _currentFilter;
      final courses = await getCourses(filter: filter);
      _currentFilter = filter;
      emit(
        CourseListLoaded(
          courses: courses,
          currentFilter: _currentFilter,
          filterOptions: _filterOptions,
        ),
      );
    } catch (e) {
      emit(CourseError('Erreur de chargement des cours: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateSearchQuery(
    UpdateSearchQuery event,
    Emitter<CourseState> emit,
  ) async {
    _currentFilter = _currentFilter.copyWith(searchQuery: event.query);
    add(FetchCourses(filter: _currentFilter));
  }

  Future<void> _onUpdateSortOption(
    UpdateSortOption event,
    Emitter<CourseState> emit,
  ) async {
    _currentFilter = _currentFilter.copyWith(sortOption: event.sortOption);
    add(FetchCourses(filter: _currentFilter));
  }

  Future<void> _onUpdatePriceRange(
    UpdatePriceRange event,
    Emitter<CourseState> emit,
  ) async {
    _currentFilter = _currentFilter.copyWith(priceRange: event.priceRange);
    add(FetchCourses(filter: _currentFilter));
  }

  Future<void> _onToggleCategory(
    ToggleCategory event,
    Emitter<CourseState> emit,
  ) async {
    final categories = List<String>.from(_currentFilter.selectedCategories);
    if (categories.contains(event.category)) {
      categories.remove(event.category);
    } else {
      categories.add(event.category);
    }
    _currentFilter = _currentFilter.copyWith(selectedCategories: categories);
    add(FetchCourses(filter: _currentFilter));
  }

  Future<void> _onToggleAuthor(
    ToggleAuthor event,
    Emitter<CourseState> emit,
  ) async {
    final authors = List<String>.from(_currentFilter.selectedAuthors);
    if (authors.contains(event.author)) {
      authors.remove(event.author);
    } else {
      authors.add(event.author);
    }
    _currentFilter = _currentFilter.copyWith(selectedAuthors: authors);
    add(FetchCourses(filter: _currentFilter));
  }

  Future<void> _onClearFilters(
    ClearFilters event,
    Emitter<CourseState> emit,
  ) async {
    _currentFilter = const CourseFilter();
    add(FetchCourses(filter: _currentFilter));
  }

  Future<void> _onLoadFilterOptions(
    LoadFilterOptions event,
    Emitter<CourseState> emit,
  ) async {
    try {
      _filterOptions = await getFilterOptions();
      if (state is CourseListLoaded) {
        emit(
          (state as CourseListLoaded).copyWith(filterOptions: _filterOptions),
        );
      }
    } catch (e) {
      // Log error but don't crash
    }
  }
}

class CourseDetailBloc extends Bloc<FetchCourseDetails, CourseState> {
  final GetCourseDetails getCourseDetails;

  CourseDetailBloc({required this.getCourseDetails}) : super(CourseInitial()) {
    on<FetchCourseDetails>(_onFetchCourseDetails);
  }

  Future<void> _onFetchCourseDetails(
    FetchCourseDetails event,
    Emitter<CourseState> emit,
  ) async {
    emit(CourseLoading());
    try {
      final course = await getCourseDetails(event.courseId);
      emit(CourseDetailLoaded(course));
    } catch (e) {
      emit(CourseError('Erreur de chargement du détail: ${e.toString()}'));
    }
  }
}

// Extension pour copier CourseListLoaded
extension CourseListLoadedCopyWith on CourseListLoaded {
  CourseListLoaded copyWith({
    List<CourseEntity>? courses,
    CourseFilter? currentFilter,
    Map<String, List<String>>? filterOptions,
  }) {
    return CourseListLoaded(
      courses: courses ?? this.courses,
      currentFilter: currentFilter ?? this.currentFilter,
      filterOptions: filterOptions ?? this.filterOptions,
    );
  }
}

// lib/features/2_marketplace/marketplace_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart';
import 'package:modula_lms/features/shared/stripe_logic.dart';
import 'marketplace_logic.dart';
import 'dart:async';

//==============================================================================
// PAGE LISTE DES COURS (Maintenant un StatelessWidget)
//==============================================================================

/// Le widget principal est maintenant un StatelessWidget.
/// Son unique rôle est de fournir le CourseBloc à son enfant, `_CourseListView`.
/// De cette manière, le BLoC n'est créé qu'une seule fois et persiste
/// même lorsque la vue se reconstruit, ce qui est la correction clé.
class CourseListPage extends StatelessWidget {
  const CourseListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<CourseBloc>()
        ..add(FetchCourses()) // Charge les cours initiaux
        ..add(LoadFilterOptions()), // Charge les options de filtre
      child: const _CourseListView(), // Affiche la vue réelle
    );
  }
}

//==============================================================================
// VUE DE LA LISTE DES COURS (Maintenant un StatefulWidget interne)
//==============================================================================

/// Ce widget contient toute la logique de la vue (Scaffold, contrôleurs, etc.).
/// Comme il est un enfant du BlocProvider, il peut y accéder via context.read
/// sans jamais le recréer à chaque mise à jour de l'interface.
class _CourseListView extends StatefulWidget {
  const _CourseListView();

  @override
  State<_CourseListView> createState() => _CourseListViewState();
}

class _CourseListViewState extends State<_CourseListView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  /// Fonction de recherche avec un délai (debounce) pour ne pas surcharger l'API.
  /// Se déclenche quand l'utilisateur tape du texte.
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      // On s'assure que le widget est toujours "monté" avant d'appeler le BLoC.
      if (mounted) {
        context.read<CourseBloc>().add(UpdateSearchQuery(query));
      }
    });
  }

  /// NOUVELLE FONCTION : Gère la soumission directe depuis le clavier.
  /// Se déclenche quand l'utilisateur appuie sur "Rechercher" ou "Terminé".
  void _onSearchSubmitted(String query) {
    // On annule tout debounce en cours pour lancer la recherche immédiatement.
    _debounce?.cancel();
    context.read<CourseBloc>().add(UpdateSearchQuery(query));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: BlocBuilder<CourseBloc, CourseState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              // App Bar moderne avec recherche intégrée
              SliverAppBar(
                expandedHeight: 120.0,
                floating: true,
                pinned: true,
                backgroundColor: Theme.of(context).colorScheme.surface,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: EdgeInsets.zero,
                  title: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Catalogue',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Badge(
                                    isLabelVisible:
                                        state is CourseListLoaded &&
                                        (state
                                                .currentFilter
                                                .selectedCategories
                                                .isNotEmpty ||
                                            state
                                                .currentFilter
                                                .selectedAuthors
                                                .isNotEmpty ||
                                            state.currentFilter.priceRange !=
                                                PriceRange.all),
                                    child: Icon(
                                      _showFilters
                                          ? Icons.filter_alt
                                          : Icons.filter_alt_outlined,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _showFilters = !_showFilters;
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.person_outline),
                                  onPressed: () => context.push('/profile'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),

              // Barre de recherche moderne
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    // --- CORRECTION & AJOUT ---
                    // Ajout de l'action de recherche sur le clavier.
                    textInputAction: TextInputAction.search,
                    // Ajout du handler pour la soumission via le clavier.
                    onSubmitted: _onSearchSubmitted,
                    decoration: InputDecoration(
                      hintText: 'Rechercher des cours...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                // Utilise la nouvelle fonction pour la soumission directe.
                                _onSearchSubmitted('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Theme.of(
                        context,
                      ).colorScheme.surfaceVariant.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),

              // Panneau de filtres animé
              if (_showFilters)
                SliverToBoxAdapter(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: _FilterPanel(),
                  ),
                ),

              // Statistiques et tri
              if (state is CourseListLoaded)
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${state.courses.length} cours trouvés',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        PopupMenuButton<SortOption>(
                          icon: const Icon(Icons.sort),
                          onSelected: (SortOption option) {
                            context.read<CourseBloc>().add(
                              UpdateSortOption(option),
                            );
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<SortOption>>[
                                const PopupMenuItem<SortOption>(
                                  value: SortOption.popularity,
                                  child: Text('Popularité'),
                                ),
                                const PopupMenuItem<SortOption>(
                                  value: SortOption.priceAsc,
                                  child: Text('Prix croissant'),
                                ),
                                const PopupMenuItem<SortOption>(
                                  value: SortOption.priceDesc,
                                  child: Text('Prix décroissant'),
                                ),
                                const PopupMenuItem<SortOption>(
                                  value: SortOption.rating,
                                  child: Text('Note'),
                                ),
                                const PopupMenuItem<SortOption>(
                                  value: SortOption.newest,
                                  child: Text('Plus récents'),
                                ),
                              ],
                        ),
                      ],
                    ),
                  ),
                ),

              // Liste des cours
              if (state is CourseLoading && state.isLoadingMore == false)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state is CourseListLoaded)
                if (state.courses.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun cours trouvé',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Essayez de modifier vos critères de recherche',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.tonal(
                            onPressed: () {
                              _searchController.clear();
                              context.read<CourseBloc>().add(ClearFilters());
                            },
                            child: const Text('Réinitialiser les filtres'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final course = state.courses[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _ModernCourseCard(
                            course: course,
                            onTap: () => context.push(
                              '/marketplace/course/${course.id}',
                            ),
                          ),
                        );
                      }, childCount: state.courses.length),
                    ),
                  )
              else if (state is CourseError)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Une erreur est survenue',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.message,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () =>
                              context.read<CourseBloc>().add(FetchCourses()),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

//==============================================================================
// WIDGET: Panneau de filtres
//==============================================================================
class _FilterPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CourseBloc, CourseState>(
      builder: (context, state) {
        if (state is! CourseListLoaded) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filtres',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (state.currentFilter.selectedCategories.isNotEmpty ||
                      state.currentFilter.selectedAuthors.isNotEmpty ||
                      state.currentFilter.priceRange != PriceRange.all)
                    TextButton(
                      onPressed: () {
                        context.read<CourseBloc>().add(ClearFilters());
                      },
                      child: const Text('Tout effacer'),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Filtre par prix
              Text(
                'Gamme de prix',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final range in PriceRange.values)
                    ChoiceChip(
                      label: Text(_getPriceRangeLabel(range)),
                      selected: state.currentFilter.priceRange == range,
                      onSelected: (selected) {
                        if (selected) {
                          context.read<CourseBloc>().add(
                            UpdatePriceRange(range),
                          );
                        }
                      },
                    ),
                ],
              ),

              if (state.filterOptions['categories']?.isNotEmpty ?? false) ...[
                const SizedBox(height: 16),
                Text(
                  'Catégories',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final category in state.filterOptions['categories']!)
                      FilterChip(
                        label: Text(category),
                        selected: state.currentFilter.selectedCategories
                            .contains(category),
                        onSelected: (selected) {
                          context.read<CourseBloc>().add(
                            ToggleCategory(category),
                          );
                        },
                      ),
                  ],
                ),
              ],

              if (state.filterOptions['authors']?.isNotEmpty ?? false) ...[
                const SizedBox(height: 16),
                Text(
                  'Formateurs',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final author in state.filterOptions['authors']!)
                      FilterChip(
                        label: Text(author),
                        selected: state.currentFilter.selectedAuthors.contains(
                          author,
                        ),
                        onSelected: (selected) {
                          context.read<CourseBloc>().add(ToggleAuthor(author));
                        },
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _getPriceRangeLabel(PriceRange range) {
    switch (range) {
      case PriceRange.all:
        return 'Tous';
      case PriceRange.free:
        return 'Gratuit';
      case PriceRange.under50:
        return '< 50€';
      case PriceRange.under100:
        return '< 100€';
      case PriceRange.over100:
        return '> 100€';
    }
  }
}

//==============================================================================
// WIDGET: Carte de cours moderne
//==============================================================================
class _ModernCourseCard extends StatelessWidget {
  final CourseEntity course;
  final VoidCallback onTap;

  const _ModernCourseCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image avec overlay gradient
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        course.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          child: const Icon(Icons.broken_image, size: 50),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        course.price == 0
                            ? 'Gratuit'
                            : '${course.price.toStringAsFixed(2)} €',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: course.price == 0
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  if (course.category != null)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          course.category!,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ),
                ],
              ),
              // Contenu
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                          child: Text(
                            course.author.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            course.author,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (course.rating != null ||
                        course.enrollmentCount != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (course.rating != null) ...[
                            Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              course.rating!.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ],
                          if (course.rating != null &&
                              course.enrollmentCount != null)
                            const SizedBox(width: 16),
                          if (course.enrollmentCount != null) ...[
                            Icon(
                              Icons.people_outline,
                              size: 16,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${course.enrollmentCount} inscrits',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//==============================================================================
// PAGE DÉTAIL D'UN COURS
//==============================================================================
class CourseDetailPage extends StatelessWidget {
  final String courseId;
  const CourseDetailPage({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              sl<CourseDetailBloc>()..add(FetchCourseDetails(courseId)),
        ),
        BlocProvider(create: (context) => sl<StripeBloc>()),
      ],
      child: Scaffold(
        body: BlocConsumer<StripeBloc, StripeState>(
          listener: (context, stripeState) {
            if (stripeState is StripeError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(stripeState.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, stripeState) {
            return BlocBuilder<CourseDetailBloc, CourseState>(
              builder: (context, courseState) {
                if (courseState is CourseLoading ||
                    courseState is CourseInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (courseState is CourseDetailLoaded) {
                  final course = courseState.course;
                  return CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        expandedHeight: 300.0,
                        pinned: true,
                        flexibleSpace: FlexibleSpaceBar(
                          title: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              course.title,
                              style: const TextStyle(fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          background: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                course.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceVariant,
                                  child: const Icon(
                                    Icons.broken_image,
                                    size: 50,
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.7),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Informations du formateur
                              Card(
                                elevation: 0,
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceVariant.withOpacity(0.5),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        child: Text(
                                          course.author
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onPrimary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Formateur',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                            Text(
                                              course.author,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Stats du cours
                              if (course.rating != null ||
                                  course.enrollmentCount != null ||
                                  course.category != null)
                                Row(
                                  children: [
                                    if (course.rating != null) ...[
                                      _StatChip(
                                        icon: Icons.star,
                                        label: course.rating!.toStringAsFixed(
                                          1,
                                        ),
                                        color: Colors.amber[700]!,
                                      ),
                                      const SizedBox(width: 12),
                                    ],
                                    if (course.enrollmentCount != null) ...[
                                      _StatChip(
                                        icon: Icons.people_outline,
                                        label:
                                            '${course.enrollmentCount} inscrits',
                                      ),
                                      const SizedBox(width: 12),
                                    ],
                                    if (course.category != null)
                                      _StatChip(
                                        icon: Icons.category_outlined,
                                        label: course.category!,
                                      ),
                                  ],
                                ),

                              if (course.rating != null ||
                                  course.enrollmentCount != null ||
                                  course.category != null)
                                const SizedBox(height: 24),

                              // Description
                              Text(
                                'À propos de ce cours',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                course.description ??
                                    'Aucune description disponible.',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.copyWith(height: 1.5),
                              ),
                              const SizedBox(height: 32),

                              // Bouton d'achat fixe en bas
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                      .withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Prix du cours',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                        Text(
                                          course.price == 0
                                              ? 'Gratuit'
                                              : '${course.price.toStringAsFixed(2)} €',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    if (stripeState is StripeCheckoutInProgress)
                                      const Center(
                                        child: CircularProgressIndicator(),
                                      )
                                    else
                                      SizedBox(
                                        width: double.infinity,
                                        height: 56,
                                        child: FilledButton.icon(
                                          icon: const Icon(
                                            Icons.shopping_cart_checkout,
                                          ),
                                          label: Text(
                                            course.price == 0
                                                ? 'S\'inscrire gratuitement'
                                                : 'Acheter maintenant',
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                          onPressed: () {
                                            final user = context
                                                .read<AuthenticationBloc>()
                                                .state
                                                .user;
                                            if (user.isEmpty) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    "Veuillez vous connecter pour acheter ce cours.",
                                                  ),
                                                ),
                                              );
                                              context.push('/login');
                                              return;
                                            }
                                            context.read<StripeBloc>().add(
                                              InitiateCheckout(
                                                courseId: course.id,
                                                userId: user.id,
                                              ),
                                            );
                                          },
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
                  );
                }
                if (courseState is CourseError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            courseState.message,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Retour'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            );
          },
        ),
      ),
    );
  }
}

// Widget helper pour les statistiques
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _StatChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

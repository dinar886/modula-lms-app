// lib/features/3_learner_space/my_courses_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart';
import 'package:modula_lms/features/2_marketplace/marketplace_logic.dart';
import 'package:modula_lms/features/3_learner_space/learner_space_logic.dart';

// La page est un StatelessWidget qui fournit le BLoC.
// Cela garantit que le BLoC est créé une seule fois et partagé dans toute la vue.
class MyCoursesPage extends StatelessWidget {
  final bool purchaseSuccess;

  const MyCoursesPage({super.key, this.purchaseSuccess = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<MyCoursesBloc>(),
      child: _MyCoursesView(purchaseSuccess: purchaseSuccess),
    );
  }
}

// La vue interne est un StatefulWidget pour gérer son propre état local, comme l'indicateur de chargement.
class _MyCoursesView extends StatefulWidget {
  final bool purchaseSuccess;

  const _MyCoursesView({this.purchaseSuccess = false});

  @override
  State<_MyCoursesView> createState() => _MyCoursesViewState();
}

class _MyCoursesViewState extends State<_MyCoursesView> {
  bool _isVerifyingPurchase = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthenticationBloc>().state;
    final userId = authState.user.id;
    final userRole = authState.user.role;

    // On récupère le BLoC depuis le contexte.
    final myCoursesBloc = context.read<MyCoursesBloc>();

    // Si l'utilisateur vient d'acheter un cours, on affiche un message et on rafraîchit la liste après un court délai.
    if (widget.purchaseSuccess) {
      setState(() {
        _isVerifyingPurchase = true;
      });

      // Délai pour simuler la finalisation de l'inscription et laisser le temps au backend de se mettre à jour.
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          // On vérifie que le widget est toujours affiché.
          myCoursesBloc.add(FetchMyCourses(userId: userId, role: userRole));
          setState(() {
            _isVerifyingPurchase = false;
          });
        }
      });
    } else {
      // Si c'est une visite normale, on charge les cours immédiatement.
      myCoursesBloc.add(FetchMyCourses(userId: userId, role: userRole));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthenticationBloc>().state;
    final userId = authState.user.id;
    final userRole = authState.user.role;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Cours'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: _isVerifyingPurchase
          ? _buildVerifyingPurchaseView()
          : BlocBuilder<MyCoursesBloc, MyCoursesState>(
              builder: (context, state) {
                // État de chargement initial
                if (state is MyCoursesLoading || state is MyCoursesInitial) {
                  return const Center(child: CircularProgressIndicator());
                }

                // État où les cours sont chargés avec succès
                if (state is MyCoursesLoaded) {
                  // Si l'utilisateur n'a aucun cours
                  if (state.courses.isEmpty) {
                    return _buildEmptyState();
                  }
                  // Affichage de la liste des cours
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<MyCoursesBloc>().add(
                        FetchMyCourses(userId: userId, role: userRole),
                      );
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.courses.length,
                      itemBuilder: (context, index) {
                        final course = state.courses[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _MyCourseCard(
                            course: course,
                            onTap: () {
                              context.push('/course-player', extra: course);
                            },
                          ),
                        );
                      },
                    ),
                  );
                }

                // État d'erreur
                if (state is MyCoursesError) {
                  return _buildErrorState(state.message);
                }

                return const SizedBox.shrink();
              },
            ),
    );
  }

  // Widget pour l'état vide (aucun cours)
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun cours pour le moment',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Explorez notre catalogue pour commencer votre apprentissage !',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.go('/marketplace'),
              icon: const Icon(Icons.explore),
              label: const Text('Explorer le catalogue'),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour l'état d'erreur
  Widget _buildErrorState(String message) {
    final authState = context.read<AuthenticationBloc>().state;
    final userId = authState.user.id;
    final userRole = authState.user.role;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
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
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                context.read<MyCoursesBloc>().add(
                  FetchMyCourses(userId: userId, role: userRole),
                );
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour la vue de vérification de l'achat
  Widget _buildVerifyingPurchaseView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Finalisation de votre inscription...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Cela peut prendre quelques secondes.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget de carte personnalisé pour les cours de l'utilisateur.
class _MyCourseCard extends StatelessWidget {
  final CourseEntity course;
  final VoidCallback onTap;

  const _MyCourseCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          // Décoration de la carte avec une ombre et des coins arrondis.
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
          child: Row(
            children: [
              // **CORRECTION APPLIQUÉE ICI**
              // On enveloppe l'image dans un SizedBox pour lui donner une taille fixe.
              // Cela résout l'erreur "unbounded constraints" car le Row sait maintenant quelle largeur allouer à l'image.
              SizedBox(
                width: 120,
                height: 120,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: Image.network(
                    course.imageUrl,
                    fit: BoxFit.cover, // L'image remplit l'espace alloué.
                    // Widget affiché pendant le chargement de l'image
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    // Widget affiché en cas d'erreur de chargement de l'image
                    errorBuilder: (_, __, ___) => Container(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: Icon(
                        Icons.school,
                        size: 50,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              // Informations du cours (Titre, auteur, etc.)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        course.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
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
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_circle_outline,
                              size: 16,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Continuer',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Flèche indicative sur la droite
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

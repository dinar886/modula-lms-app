// lib/features/2_marketplace/marketplace_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart';
import 'package:modula_lms/features/2_marketplace/course_card.dart';
import 'package:modula_lms/features/shared/stripe_logic.dart'; // NOUVEL IMPORT
import 'marketplace_logic.dart';

//==============================================================================
// PAGE LISTE DES COURS (Catalogue)
//==============================================================================
class CourseListPage extends StatelessWidget {
  const CourseListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<CourseBloc>()..add(FetchCourses()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Catalogue des Cours'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () => context.push('/profile'),
            ),
          ],
        ),
        body: BlocBuilder<CourseBloc, CourseState>(
          builder: (context, state) {
            if (state is CourseLoading || state is CourseInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is CourseListLoaded) {
              if (state.courses.isEmpty) {
                return const Center(child: Text("Aucun cours disponible."));
              }
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<CourseBloc>().add(FetchCourses());
                },
                child: ListView.builder(
                  itemCount: state.courses.length,
                  itemBuilder: (context, index) {
                    final course = state.courses[index];
                    return CourseCard(
                      course: course,
                      onTap: () =>
                          context.push('/marketplace/course/${course.id}'),
                    );
                  },
                ),
              );
            }
            if (state is CourseError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.message,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () =>
                          context.read<CourseBloc>().add(FetchCourses()),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              );
            }
            return const Center(child: Text('État non géré.'));
          },
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
    // On utilise MultiBlocProvider pour fournir à la fois les détails du cours et la logique de Stripe.
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              sl<CourseDetailBloc>()..add(FetchCourseDetails(courseId)),
        ),
        BlocProvider(create: (context) => sl<StripeBloc>()),
      ],
      child: Scaffold(
        // Le BlocConsumer écoute les états de Stripe pour afficher des messages (ex: erreur)
        // tout en reconstruisant l'interface en fonction de l'état du paiement.
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
            // Le BlocBuilder principal gère l'affichage des détails du cours.
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
                        expandedHeight: 250.0,
                        pinned: true,
                        flexibleSpace: FlexibleSpaceBar(
                          title: Text(
                            course.title,
                            style: const TextStyle(fontSize: 16),
                          ),
                          background: Image.network(
                            course.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image, size: 50),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Par ${course.author}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                course.description ?? 'Aucune description.',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 32),
                              // Le bouton d'achat affiche un loader si le paiement est en cours.
                              if (stripeState is StripeCheckoutInProgress)
                                const Center(child: CircularProgressIndicator())
                              else
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.shopping_cart_checkout,
                                    ),
                                    label: Text(
                                      'Acheter pour ${course.price.toStringAsFixed(2)} €',
                                    ),
                                    onPressed: () {
                                      // On récupère l'ID de l'utilisateur connecté.
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
                                        context.push(
                                          '/login',
                                        ); // Redirige vers le login.
                                        return;
                                      }
                                      // Déclenche l'événement pour créer une session de paiement Stripe.
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
                      ),
                    ],
                  );
                }
                if (courseState is CourseError) {
                  return Center(
                    child: Text(
                      courseState.message,
                      style: const TextStyle(color: Colors.red),
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

// lib/features/4_instructor_space/instructor_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:modula_lms/core/api/api_client.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart';
import 'package:modula_lms/features/2_marketplace/marketplace_logic.dart';
import 'package:modula_lms/features/3_learner_space/learner_space_logic.dart';
import 'package:modula_lms/features/4_instructor_space/instructor_dashboard_logic.dart';
import 'package:modula_lms/features/5_messaging/messaging_logic.dart';

class InstructorDashboardPage extends StatelessWidget {
  const InstructorDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // On récupère l'ID de l'instructeur une seule fois ici.
    final instructorId = context.read<AuthenticationBloc>().state.user.id;

    // On utilise MultiBlocProvider pour injecter les BLoCs nécessaires
    // à l'arbre de widgets qui suit.
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              sl<InstructorDashboardBloc>()
                ..add(FetchInstructorStats(instructorId)),
        ),
        BlocProvider(
          create: (context) => sl<MyCoursesBloc>()
            ..add(
              FetchMyCourses(userId: instructorId, role: UserRole.instructor),
            ),
        ),
      ],
      // Le widget _InstructorDashboardView est maintenant un enfant du MultiBlocProvider.
      // Tout contexte à l'intérieur de ce widget aura accès aux BLoCs.
      child: const _InstructorDashboardView(),
    );
  }
}

/// Un widget privé qui contient toute la logique d'affichage.
/// Il est séparé pour garantir que son contexte est bien un descendant du MultiBlocProvider.
class _InstructorDashboardView extends StatelessWidget {
  const _InstructorDashboardView();

  @override
  Widget build(BuildContext context) {
    // On récupère l'ID de l'instructeur depuis le contexte qui a maintenant accès au AuthBloc.
    final instructorId = context.read<AuthenticationBloc>().state.user.id;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Tableau de Bord'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Mon Profil',
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        // Le contexte ici est valide pour accéder aux BLoCs.
        onRefresh: () async {
          context.read<InstructorDashboardBloc>().add(
            FetchInstructorStats(instructorId),
          );
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          children: [
            Text(
              "Aperçu de votre activité",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatsSection(),
            const SizedBox(height: 32),
            Text(
              "Accès Rapide",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            // On passe le contexte valide à la méthode.
            _buildActionsGrid(context),
          ],
        ),
      ),
    );
  }

  /// Construit la section qui affiche les statistiques.
  Widget _buildStatsSection() {
    return BlocBuilder<InstructorDashboardBloc, InstructorDashboardState>(
      builder: (context, state) {
        if (state is InstructorDashboardLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is InstructorDashboardError) {
          return Center(
            child: Text(
              state.message,
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
          );
        }
        if (state is InstructorDashboardLoaded) {
          final stats = state.stats;
          final currencyFormatter = NumberFormat.currency(
            locale: 'fr_FR',
            symbol: '€',
          );

          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _StatCard(
                label: 'Revenus (7j)',
                value: currencyFormatter.format(stats.recentRevenue),
                icon: Icons.euro_rounded,
                color1: Colors.green.shade300,
                color2: Colors.green.shade500,
              ),
              _StatCard(
                label: 'Élèves Totaux',
                value: stats.totalStudents.toString(),
                icon: Icons.people_alt_rounded,
                color1: Colors.blue.shade300,
                color2: Colors.blue.shade500,
              ),
              _StatCard(
                label: 'Rendus à corriger',
                value: stats.pendingSubmissions.toString(),
                icon: Icons.hourglass_top_rounded,
                color1: Colors.orange.shade300,
                color2: Colors.orange.shade500,
              ),
              _StatCard(
                label: 'Nouveaux Messages',
                value: "12",
                icon: Icons.mail_rounded,
                color1: Colors.purple.shade300,
                color2: Colors.purple.shade500,
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  /// Construit la grille avec les boutons d'actions rapides.
  Widget _buildActionsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16.0,
      mainAxisSpacing: 16.0,
      childAspectRatio: 1.2,
      children: [
        _ActionCard(
          icon: Icons.school_outlined,
          label: 'Gérer mes Cours',
          onTap: () => context.push('/instructor-courses'),
        ),
        _ActionCard(
          icon: Icons.assignment_turned_in_outlined,
          label: 'Voir les Rendus',
          onTap: () => context.push('/submissions'),
        ),
        _ActionCard(
          icon: Icons.group_outlined,
          label: 'Voir mes Élèves',
          onTap: () => context.push('/students'),
        ),
        _ActionCard(
          icon: Icons.campaign_outlined,
          label: 'Faire une annonce',
          // Le contexte passé ici est maintenant correct.
          onTap: () => _showSelectCourseDialog(context),
        ),
      ],
    );
  }

  /// Affiche une boîte de dialogue pour sélectionner un cours.
  void _showSelectCourseDialog(BuildContext pageContext) {
    showDialog(
      context: pageContext,
      builder: (dialogContext) {
        // La clé de la correction est ici : on fournit l'instance de MyCoursesBloc
        // obtenue depuis le `pageContext` (qui est valide) à l'arbre de la dialog.
        return BlocProvider.value(
          value: BlocProvider.of<MyCoursesBloc>(pageContext),
          child: BlocBuilder<MyCoursesBloc, MyCoursesState>(
            builder: (builderContext, state) {
              if (state is MyCoursesLoading) {
                return const AlertDialog(
                  content: Center(child: CircularProgressIndicator()),
                );
              }
              if (state is MyCoursesLoaded) {
                return AlertDialog(
                  title: const Text('Choisir un cours'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: state.courses.length,
                      itemBuilder: (_, index) {
                        final course = state.courses[index];
                        return ListTile(
                          title: Text(course.title),
                          onTap: () {
                            Navigator.of(dialogContext).pop();
                            _createOrGetGroupChat(pageContext, course);
                          },
                        );
                      },
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Annuler'),
                    ),
                  ],
                );
              }
              return AlertDialog(
                title: const Text('Erreur'),
                content: const Text(
                  'Impossible de charger la liste de vos cours.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Fermer'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// Appelle le backend pour créer/récupérer le chat de groupe et y naviguer.
  Future<void> _createOrGetGroupChat(
    BuildContext context,
    CourseEntity course,
  ) async {
    final apiClient = sl<ApiClient>();
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ouverture de la discussion de groupe...'),
        ),
      );

      final response = await apiClient.post(
        '/api/v1/create_or_get_group_chat.php',
        data: {'course_id': course.id},
      );
      final conversationId = response.data['conversation_id'];

      final conversation = ConversationEntity(
        id: conversationId,
        conversationName: course.title,
        conversationImageUrl: course.imageUrl,
        type: 'group',
        lastMessage: '',
        lastMessageAt: null,
      );

      context.push('/chat/$conversationId', extra: conversation);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur: Impossible d'accéder à la conversation."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Widget pour une carte de statistique.
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color1;
  final Color color2;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color1,
    required this.color2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color2.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: constraints.maxHeight * 0.25,
                  color: Colors.white,
                ),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: constraints.maxHeight * 0.28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: constraints.maxHeight * 0.12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  maxLines: 1,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Widget pour une carte d'action rapide.
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40.0, color: Theme.of(context).primaryColor),
            const SizedBox(height: 12.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

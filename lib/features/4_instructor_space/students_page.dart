// lib/features/4_instructor_space/students_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart';
import 'package:modula_lms/features/4_instructor_space/students_logic.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  // Garde en mémoire l'état (ouvert/fermé) de chaque panneau de cours.
  List<bool> _isPanelOpen = [];

  // **NOUVELLE FONCTION** : Génère une couleur déterministe pour un étudiant.
  /// Prend l'ID de l'étudiant, utilise son `hashCode` pour choisir une couleur
  /// dans une liste prédéfinie. Ainsi, un même étudiant aura toujours la même couleur.
  Color _getColorForStudent(String studentId) {
    // Une liste de couleurs vives et agréables.
    const List<Color> avatarColors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      Colors.cyan,
    ];
    // L'opérateur modulo (%) garantit que l'index reste dans les limites de la liste.
    final int colorIndex = studentId.hashCode % avatarColors.length;
    return avatarColors[colorIndex];
  }

  @override
  Widget build(BuildContext context) {
    // On récupère l'ID de l'instructeur actuellement connecté.
    final instructorId = context.read<AuthenticationBloc>().state.user.id;

    return BlocProvider(
      create: (context) =>
          sl<InstructorStudentsBloc>()
            ..add(FetchInstructorStudents(instructorId)),
      child: Scaffold(
        appBar: AppBar(title: const Text('Gestion des Élèves')),
        body: BlocBuilder<InstructorStudentsBloc, InstructorStudentsState>(
          builder: (context, state) {
            // Affichage d'un indicateur de chargement.
            if (state is InstructorStudentsLoading ||
                state is InstructorStudentsInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            // Affichage d'un message d'erreur.
            if (state is InstructorStudentsError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    state.message,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            // Affichage de la liste des cours et étudiants.
            if (state is InstructorStudentsLoaded) {
              // On s'assure que notre liste `_isPanelOpen` a la bonne taille.
              if (_isPanelOpen.length != state.coursesWithStudents.length) {
                _isPanelOpen = List.generate(
                  state.coursesWithStudents.length,
                  (_) => false,
                );
              }
              // Si l'instructeur n'a aucun élève.
              if (state.coursesWithStudents.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      "Aucun élève n'est encore inscrit à vos cours.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                );
              }
              // On affiche la liste des cours sous forme de panneaux dépliants.
              return SingleChildScrollView(
                padding: const EdgeInsets.all(8.0),
                child: ExpansionPanelList(
                  animationDuration: const Duration(milliseconds: 300),
                  elevation: 2,
                  expansionCallback: (panelIndex, isExpanded) {
                    setState(() {
                      _isPanelOpen[panelIndex] = !_isPanelOpen[panelIndex];
                    });
                  },
                  children: state.coursesWithStudents.asMap().entries.map((
                    entry,
                  ) {
                    final int courseIndex = entry.key;
                    final CourseWithStudentsEntity courseWithStudents =
                        entry.value;
                    return ExpansionPanel(
                      isExpanded: _isPanelOpen[courseIndex],
                      canTapOnHeader: true,
                      headerBuilder: (context, isExpanded) {
                        return ListTile(
                          title: Text(
                            courseWithStudents.courseTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "${courseWithStudents.students.length} élève(s) inscrit(s)",
                          ),
                          trailing: Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                          ),
                        );
                      },
                      // Le corps du panneau contient la liste des étudiants.
                      body: Column(
                        children: courseWithStudents.students.map((student) {
                          // **MODIFICATION DU LISTTILE DE L'ÉTUDIANT**
                          final hasImage =
                              student.profileImageUrl != null &&
                              student.profileImageUrl!.isNotEmpty;

                          return ListTile(
                            leading: CircleAvatar(
                              // On utilise la fonction pour obtenir une couleur de fond unique.
                              backgroundColor: _getColorForStudent(student.id),
                              // Si une image existe, on l'affiche avec NetworkImage.
                              // Sinon, `backgroundImage` est `null`.
                              backgroundImage: hasImage
                                  ? NetworkImage(student.profileImageUrl!)
                                  : null,
                              // Le `child` (l'initiale) ne s'affiche que si `backgroundImage` est `null`.
                              child: !hasImage
                                  ? Text(
                                      student.name
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null, // Si on a une image, le child est null.
                            ),
                            title: Text(student.name),
                            subtitle: Text(student.email),
                            onTap: () {
                              // Navigue vers la page de détails de l'élève.
                              context.push('/students/${student.id}');
                            },
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
              );
            }
            // Cas par défaut (ne devrait pas être atteint).
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

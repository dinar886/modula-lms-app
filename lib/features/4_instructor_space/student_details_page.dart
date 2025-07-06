// lib/features/4_instructor_space/student_details_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import pour la localisation des dates
import 'package:modula_lms/core/di/service_locator.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart';
import 'package:modula_lms/features/4_instructor_space/student_details_logic.dart';

class StudentDetailsPage extends StatefulWidget {
  final String studentId;
  const StudentDetailsPage({super.key, required this.studentId});

  @override
  State<StudentDetailsPage> createState() => _StudentDetailsPageState();
}

class _StudentDetailsPageState extends State<StudentDetailsPage> {
  // On initialise la localisation pour les dates en français.
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR');
  }

  @override
  Widget build(BuildContext context) {
    final instructorId = context.read<AuthenticationBloc>().state.user.id;
    return BlocProvider(
      create: (context) => sl<StudentDetailsBloc>()
        ..add(
          FetchStudentDetails(
            studentId: widget.studentId,
            instructorId: instructorId,
          ),
        ),
      child: Scaffold(
        // On utilise une couleur de fond sobre pour un look plus professionnel.
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('Profil de l\'Élève'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
        ),
        body: BlocBuilder<StudentDetailsBloc, StudentDetailsState>(
          builder: (context, state) {
            if (state is StudentDetailsLoading ||
                state is StudentDetailsInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is StudentDetailsError) {
              return Center(child: Text("Erreur : ${state.message}"));
            }
            if (state is StudentDetailsLoaded) {
              final data = state.data;
              // La page est scrollable pour s'adapter à tous les contenus.
              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Section 1 : Carte de profil de l'élève.
                  _buildProfileHeader(context, data.studentInfo),
                  const SizedBox(height: 24),

                  // Section 2 : Liste des cours suivis.
                  _buildSectionTitle('Cours Suivis'),
                  const SizedBox(height: 8),
                  _buildCoursesList(data.enrolledCourses),
                  const SizedBox(height: 24),

                  // Section 3 : Liste des rendus récents.
                  _buildSectionTitle('Rendus Récents'),
                  const SizedBox(height: 8),
                  _buildSubmissionsList(data.submissions),
                ],
              );
            }
            return const Center(child: Text("État non géré."));
          },
        ),
      ),
    );
  }

  /// Construit la carte d'en-tête avec la photo, le nom et l'email.
  Widget _buildProfileHeader(BuildContext context, StudentInfoEntity student) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            // La photo de profil dans un cercle.
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blueGrey.shade300,
              backgroundImage: student.profileImageUrl != null
                  ? NetworkImage(student.profileImageUrl!)
                  : null,
              child: student.profileImageUrl == null
                  ? Text(
                      student.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 32, color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 20),
            // Le nom et l'email de l'élève.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    student.email,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit le titre pour chaque section.
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  /// Construit la liste horizontale des cours.
  Widget _buildCoursesList(List<StudentEnrolledCourseEntity> courses) {
    if (courses.isEmpty) {
      return const Text(
        "Aucun cours de vous n'est suivi par cet élève.",
        style: TextStyle(color: Colors.grey),
      );
    }
    return SizedBox(
      height: 140, // Hauteur fixe pour toute la liste horizontale.
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];
          return Container(
            width: 110,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // **LA CORRECTION EST ICI**
                // Le widget `Expanded` force l'image à prendre toute la place verticale
                // disponible, moins la place nécessaire pour le texte en dessous.
                // Cela résout le problème de débordement (overflow).
                Expanded(
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.network(
                      course.imageUrl,
                      fit: BoxFit.cover,
                      width: double
                          .infinity, // L'image remplit la carte horizontalement.
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.school, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Le texte prend uniquement la hauteur dont il a besoin.
                Text(
                  course.title,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Construit la liste verticale des soumissions.
  Widget _buildSubmissionsList(List<StudentSubmissionEntity> submissions) {
    if (submissions.isEmpty) {
      return const Text(
        "Aucun rendu pour le moment.",
        style: TextStyle(color: Colors.grey),
      );
    }
    return ListView.builder(
      shrinkWrap: true, // Important dans un ListView parent.
      physics:
          const NeverScrollableScrollPhysics(), // Pour ne pas avoir de double scroll.
      itemCount: submissions.length,
      itemBuilder: (context, index) {
        final submission = submissions[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: _buildGradeIndicator(submission.grade),
            title: Text(
              submission.lessonTitle,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              "Cours : ${submission.courseTitle}\nRendu le ${DateFormat('d MMMM yyyy', 'fr_FR').format(submission.submissionDate)}",
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  /// Construit le cercle coloré pour afficher la note.
  Widget _buildGradeIndicator(double? grade) {
    String gradeText = '-';
    Color color = Colors.grey.shade400;

    if (grade != null) {
      gradeText = grade.toStringAsFixed(0);
      if (grade >= 75) {
        color = Colors.green.shade400;
      } else if (grade >= 50) {
        color = Colors.orange.shade400;
      } else {
        color = Colors.red.shade400;
      }
    }

    return CircleAvatar(
      radius: 25,
      backgroundColor: color,
      child: Text(
        gradeText,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

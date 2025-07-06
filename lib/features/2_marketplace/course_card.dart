// lib/features/2_marketplace/course_card.dart
import 'package:flutter/material.dart';
import 'package:modula_lms/features/2_marketplace/marketplace_logic.dart';

/// Un widget réutilisable pour afficher les informations d'un cours sous forme de carte.
class CourseCard extends StatelessWidget {
  final CourseEntity course;
  final VoidCallback? onTap;
  // NOUVEAU : Un booléen pour contrôler l'affichage du prix.
  // Par défaut, il est à `true` pour que le prix s'affiche dans le catalogue.
  final bool showPrice;

  const CourseCard({
    super.key,
    required this.course,
    this.onTap,
    this.showPrice = true, // Valeur par défaut
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior:
          Clip.antiAlias, // Pour que l'image respecte les bords arrondis
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Affiche l'image du cours
            Image.network(
              course.imageUrl,
              height: 180,
              fit: BoxFit.cover,
              // Widget à afficher en cas d'erreur de chargement de l'image
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox(
                  height: 180,
                  child: Icon(Icons.school, size: 50, color: Colors.grey),
                );
              },
            ),
            // Conteneur pour les textes (titre, auteur, prix)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Affiche le titre du cours
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Affiche l'auteur du cours
                  Text(
                    'Par ${course.author}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  // CONDITION : On affiche le prix seulement si `showPrice` est vrai.
                  if (showPrice)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${course.price.toStringAsFixed(2)} €',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:modula_lms/features/2_marketplace/domain/entities/course_entity.dart';

// Le widget qui affiche un aperçu de cours dans une liste.
class CourseCard extends StatelessWidget {
  final CourseEntity course;
  // On ajoute un paramètre optionnel pour gérer le clic.
  // VoidCallback est simplement un autre nom pour une fonction qui ne prend aucun argument et ne retourne rien.
  final VoidCallback? onTap;

  const CourseCard({
    super.key,
    required this.course,
    this.onTap, // On l'ajoute au constructeur.
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // On utilise le widget Card directement.
    return Card(
      color: colorScheme.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      // On enveloppe le contenu de la carte dans un InkWell pour l'effet visuel au clic.
      child: InkWell(
        // On assigne la fonction onTap reçue en paramètre à l'événement du clic.
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // L'image du cours
            Image.network(
              course.imageUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 150,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 150,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                );
              },
            ),
            // Le contenu textuel
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'par ${course.author}',
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${course.price.toStringAsFixed(2)} €',
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
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

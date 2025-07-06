<?php
// En-têtes requis pour les requêtes CORS (Cross-Origin Resource Sharing) et pour spécifier le type de contenu.
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
// Autorise les méthodes HTTP spécifiques pour la requête.
header("Access-Control-Allow-Methods: POST");
// Définit la durée maximale de mise en cache des résultats de la pré-vérification CORS.
header("Access-Control-Max-Age: 3600");
// Spécifie les en-têtes autorisés lors de la requête.
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Inclusion du fichier de configuration pour la connexion à la base de données.
require_once 'config.php';

// Récupération des données JSON envoyées dans le corps de la requête.
// file_get_contents("php://input") lit le flux d'entrée brut.
$data = json_decode(file_get_contents("php://input"));

// Vérification que toutes les données nécessaires sont présentes.
// Si une des données est manquante, on envoie une réponse d'erreur 400 (Bad Request).
if (
    !isset($data->course_id) ||
    !isset($data->title) ||
    !isset($data->description) ||
    !isset($data->image_url) ||
    !isset($data->price) ||
    !isset($data->instructor_id) 
) {
    // Définit le code de réponse HTTP à 400.
    http_response_code(400);
    // Envoie un message d'erreur au format JSON.
    echo json_encode(array("message" => "Impossible de mettre à jour le cours. Les données sont incomplètes."));
    // Arrête l'exécution du script.
    exit();
}

// Définition de la requête SQL pour la mise à jour.
// On utilise des marqueurs de position (?) pour se prémunir contre les injections SQL.
// La clause WHERE vérifie à la fois l'ID du cours ET l'ID de l'instructeur pour s'assurer
// que seul le propriétaire du cours peut le modifier. C'est une mesure de sécurité cruciale.
$query = "UPDATE courses 
          SET title = ?, description = ?, image_url = ?, price = ? 
          WHERE id = ? AND instructor_id = ?";

// Préparation de la requête pour l'exécution.
$stmt = $conn->prepare($query);

// Nettoyage des données pour éviter les failles XSS (Cross-Site Scripting).
// htmlspecialchars convertit les caractères spéciaux en entités HTML.
// strip_tags supprime les balises HTML et PHP.
$course_id = htmlspecialchars(strip_tags($data->course_id));
$title = htmlspecialchars(strip_tags($data->title));
$description = htmlspecialchars(strip_tags($data->description));
$image_url = htmlspecialchars(strip_tags($data->image_url));
$price = htmlspecialchars(strip_tags($data->price));
$instructor_id = htmlspecialchars(strip_tags($data->instructor_id));


// Liaison des variables PHP aux marqueurs de position de la requête préparée.
// "ssdii" spécifie les types de données pour chaque paramètre :
// s = string, d = double, i = integer.
$stmt->bind_param("sssdis", $title, $description, $image_url, $price, $course_id, $instructor_id);


// Exécution de la requête.
if ($stmt->execute()) {
    // affected_rows > 0 signifie que la mise à jour a bien eu lieu (au moins une ligne a été modifiée).
    if ($stmt->affected_rows > 0) {
        // Définit le code de réponse HTTP à 200 (OK).
        http_response_code(200);
        // Envoie un message de succès.
        echo json_encode(array("message" => "Le cours a été mis à jour avec succès."));
    } else {
        // Si aucune ligne n'a été affectée, cela peut signifier soit que les données n'ont pas changé,
        // soit que l'utilisateur n'est pas le propriétaire du cours (la condition WHERE n'a pas correspondu).
        http_response_code(404); // Not Found ou Forbidden. 404 est un choix raisonnable ici.
        echo json_encode(array("message" => "Aucune modification effectuée. Vérifiez que vous êtes le propriétaire du cours ou que les données sont différentes."));
    }
} else {
    // Si l'exécution de la requête échoue, on envoie une erreur 503 (Service Unavailable).
    http_response_code(503);
    echo json_encode(array("message" => "Impossible de mettre à jour le cours."));
}

// Fermeture de la requête préparée.
$stmt->close();
// Fermeture de la connexion à la base de données.
$conn->close();
?>
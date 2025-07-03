<?php
// Fichier : /api/v1/create_course.php

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once 'config.php';

$data = json_decode(file_get_contents("php://input"));

// On vérifie que toutes les données nécessaires sont présentes.
if (
    !empty($data->title) &&
    !empty($data->description) &&
    isset($data->price) &&
    !empty($data->instructor_id)
) {
    $conn = new mysqli($servername, $username, $password, $dbname);

    if ($conn->connect_error) {
        http_response_code(500);
        echo json_encode(["message" => "Erreur de connexion à la base de données."]);
        exit();
    }

    // On démarre une transaction pour s'assurer que toutes les requêtes réussissent
    $conn->begin_transaction();

    try {
        // Sécurise les données reçues.
        $title = $conn->real_escape_string($data->title);
        $description = $conn->real_escape_string($data->description);
        $price = (float)$data->price;
        $instructor_id = (int)$data->instructor_id;

        // **LA CORRECTION EST ICI**
        // 1. On récupère le nom de l'instructeur depuis la table 'users'.
        $author_name = '';
        $user_sql = "SELECT name FROM users WHERE id = ?";
        $user_stmt = $conn->prepare($user_sql);
        $user_stmt->bind_param("i", $instructor_id);
        $user_stmt->execute();
        $user_result = $user_stmt->get_result();
        if ($user_row = $user_result->fetch_assoc()) {
            $author_name = $user_row['name'];
        }
        $user_stmt->close();

        if (empty($author_name)) {
            // Si on ne trouve pas l'utilisateur, on arrête tout.
            throw new Exception("Instructeur non trouvé.");
        }

        // URL de l'image par défaut.
        $default_image_url = "https://placehold.co/600x400/005A9C/FFFFFF/png?text=" . urlencode($title);

        // 2. Prépare la requête d'insertion en ajoutant le nom de l'auteur.
        $sql = "INSERT INTO courses (title, description, price, image_url, author) VALUES (?, ?, ?, ?, ?)";
        $stmt = $conn->prepare($sql);
        // 'ssdss' correspond aux types : string, string, double, string, string
        $stmt->bind_param("ssdss", $title, $description, $price, $default_image_url, $author_name);
        $stmt->execute();
        $course_id = $conn->insert_id; // Récupère l'ID du cours créé.
        $stmt->close();
        
        // 3. On lie l'instructeur au cours dans la table de liaison.
        $link_sql = "INSERT INTO user_courses (user_id, course_id) VALUES (?, ?)";
        $link_stmt = $conn->prepare($link_sql);
        $link_stmt->bind_param("ii", $instructor_id, $course_id);
        $link_stmt->execute();
        $link_stmt->close();
        
        // Si tout a réussi, on valide la transaction.
        $conn->commit();
        
        http_response_code(201); // Created
        echo json_encode(["message" => "Cours créé et assigné avec succès.", "course_id" => $course_id]);

    } catch (Exception $e) {
        // En cas d'erreur, on annule la transaction.
        $conn->rollback();
        http_response_code(500);
        echo json_encode(["message" => "Erreur lors de la création du cours.", "error" => $e->getMessage()]);
    } finally {
        $conn->close();
    }

} else {
    http_response_code(400);
    echo json_encode(["message" => "Données incomplètes pour la création du cours."]);
}
?>

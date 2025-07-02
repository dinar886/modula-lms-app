<?php
// Fichier : /api/v1/create_course.php

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once 'config.php';

$data = json_decode(file_get_contents("php://input"));

// Vérifie que toutes les données nécessaires sont présentes.
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

    // Sécurise les données reçues.
    $title = $conn->real_escape_string($data->title);
    $description = $conn->real_escape_string($data->description);
    $price = (float)$data->price;
    $instructor_id = (int)$data->instructor_id;

    // URL de l'image par défaut.
    $default_image_url = "https://placehold.co/600x400/005A9C/FFFFFF/png?text=" . urlencode($title);

    // Prépare la requête d'insertion.
    // Note: nous n'avons pas de colonne 'author' dans la table 'courses'.
    // L'auteur est l'instructeur, lié par son ID.
    $sql = "INSERT INTO courses (title, description, price, image_url) VALUES (?, ?, ?, ?)";
    $stmt = $conn->prepare($sql);

    $stmt->bind_param("ssds", $title, $description, $price, $default_image_url);

    if ($stmt->execute()) {
        // Si la création du cours réussit, on lie l'instructeur au cours.
        $course_id = $conn->insert_id; // Récupère l'ID du cours qui vient d'être créé.
        
        $link_sql = "INSERT INTO user_courses (user_id, course_id) VALUES (?, ?)";
        $link_stmt = $conn->prepare($link_sql);
        $link_stmt->bind_param("ii", $instructor_id, $course_id);
        
        if($link_stmt->execute()){
             http_response_code(201); // Created
             echo json_encode(["message" => "Cours créé et assigné avec succès.", "course_id" => $course_id]);
        } else {
             http_response_code(500);
             echo json_encode(["message" => "Cours créé, mais erreur lors de l'assignation à l'instructeur."]);
        }
        $link_stmt->close();

    } else {
        http_response_code(500);
        echo json_encode(["message" => "Erreur lors de la création du cours."]);
    }
    $stmt->close();
    $conn->close();

} else {
    http_response_code(400);
    echo json_encode(["message" => "Données incomplètes pour la création du cours."]);
}
?>
<?php
// Fichier : /api/v1/add_section.php

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once 'config.php';

$data = json_decode(file_get_contents("php://input"));

// Vérifie que les données nécessaires sont présentes.
if (
    !empty($data->title) &&
    !empty($data->course_id)
) {
    $conn = new mysqli($servername, $username, $password, $dbname);

    if ($conn->connect_error) {
        http_response_code(500);
        echo json_encode(["message" => "Erreur de connexion à la base de données."]);
        exit();
    }

    $title = $conn->real_escape_string($data->title);
    $course_id = (int)$data->course_id;

    // Détermine le prochain 'order_index' pour la nouvelle section.
    $order_sql = "SELECT MAX(order_index) as max_order FROM sections WHERE course_id = ?";
    $order_stmt = $conn->prepare($order_sql);
    $order_stmt->bind_param("i", $course_id);
    $order_stmt->execute();
    $result = $order_stmt->get_result();
    $row = $result->fetch_assoc();
    $next_order_index = ($row['max_order'] ?? 0) + 1;
    $order_stmt->close();

    // Prépare la requête d'insertion.
    $sql = "INSERT INTO sections (course_id, title, order_index) VALUES (?, ?, ?)";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("isi", $course_id, $title, $next_order_index);

    if ($stmt->execute()) {
        http_response_code(201); // Created
        echo json_encode(["message" => "Section créée avec succès."]);
    } else {
        http_response_code(500);
        echo json_encode(["message" => "Erreur lors de la création de la section."]);
    }
    $stmt->close();
    $conn->close();

} else {
    http_response_code(400);
    echo json_encode(["message" => "Données incomplètes."]);
}
?>

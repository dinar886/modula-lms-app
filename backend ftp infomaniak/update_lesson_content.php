<?php
// Fichier : /api/v1/update_lesson_content.php

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once 'config.php';

$data = json_decode(file_get_contents("php://input"));

// On a seulement besoin de l'ID de la leçon. Le reste est optionnel.
if (!empty($data->lesson_id)) {
    $conn = new mysqli($servername, $username, $password, $dbname);
    if ($conn->connect_error) {
        http_response_code(500);
        echo json_encode(["message" => "Erreur de connexion."]);
        exit();
    }

    $lesson_id = (int)$data->lesson_id;
    // On vérifie si les contenus ont été envoyés et on les assigne.
    // On utilise l'opérateur de coalescence nulle (??) pour mettre NULL si la clé n'existe pas.
    $content_url = $data->content_url ?? null;
    $content_text = $data->content_text ?? null;


    $sql = "UPDATE lessons SET content_url = ?, content_text = ? WHERE id = ?";
    $stmt = $conn->prepare($sql);
    // 'ssi' correspond aux types : string, string, integer
    $stmt->bind_param("ssi", $content_url, $content_text, $lesson_id);

    if ($stmt->execute()) {
        http_response_code(200);
        echo json_encode(["message" => "Contenu de la leçon mis à jour."]);
    } else {
        http_response_code(500);
        echo json_encode(["message" => "Erreur lors de la mise à jour."]);
    }
    $stmt->close();
    $conn->close();
} else {
    http_response_code(400);
    echo json_encode(["message" => "ID de leçon manquant."]);
}
?>

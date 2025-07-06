<?php
// Fichier : /api/v1/get_lesson_details.php

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");

require_once 'config.php';

// Vérifie que l'ID de la leçon est bien passé en paramètre.
if (!isset($_GET['lesson_id']) || empty($_GET['lesson_id'])) {
    http_response_code(400);
    echo json_encode(["error" => "L'ID de la leçon est manquant."]);
    exit();
}
$lesson_id = $_GET['lesson_id'];

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["error" => "Erreur de connexion à la base de données."]);
    exit();
}

// L'objectif est de construire une réponse JSON complète pour la leçon.
$lesson_details = [];

// 1. Récupérer les informations de base de la leçon.
$sql_lesson = "SELECT id, title, lesson_type FROM lessons WHERE id = ?";
$stmt_lesson = $conn->prepare($sql_lesson);
$stmt_lesson->bind_param("i", $lesson_id);
$stmt_lesson->execute();
$result_lesson = $stmt_lesson->get_result();

if ($result_lesson->num_rows > 0) {
    $lesson_details = $result_lesson->fetch_assoc();
    $lesson_details['id'] = (int)$lesson_details['id'];
    $lesson_details['content_blocks'] = []; // On prépare un tableau pour les blocs.

    // 2. Récupérer tous les blocs de contenu associés à cette leçon, ordonnés.
    $sql_blocks = "SELECT id, block_type, content, order_index FROM lesson_content_blocks WHERE lesson_id = ? ORDER BY order_index ASC";
    $stmt_blocks = $conn->prepare($sql_blocks);
    $stmt_blocks->bind_param("i", $lesson_id);
    $stmt_blocks->execute();
    $result_blocks = $stmt_blocks->get_result();

    if ($result_blocks->num_rows > 0) {
        while ($block_row = $result_blocks->fetch_assoc()) {
            // Pour chaque bloc, on s'assure que son ID est un entier.
            $block_row['id'] = (int)$block_row['id'];
            $lesson_details['content_blocks'][] = $block_row;
        }
    }
    $stmt_blocks->close();

    // On renvoie la structure complète de la leçon avec ses blocs.
    http_response_code(200);
    echo json_encode($lesson_details);

} else {
    http_response_code(404);
    echo json_encode(["error" => "Aucune leçon trouvée avec cet ID."]);
}

$stmt_lesson->close();
$conn->close();
?>
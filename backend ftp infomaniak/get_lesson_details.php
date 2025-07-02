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

// Sélectionne toutes les informations pour la leçon demandée.
$sql = "SELECT id, title, lesson_type, content_url, content_text FROM lessons WHERE id = ?";
$stmt = $conn->prepare($sql);

if ($stmt === false) {
    http_response_code(500);
    echo json_encode(["error" => "Erreur lors de la préparation de la requête."]);
    exit();
}

$stmt->bind_param("i", $lesson_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $lesson = $result->fetch_assoc();
    $lesson['id'] = (int)$lesson['id'];
    // Renvoie le contenu de la leçon.
    echo json_encode($lesson);
} else {
    http_response_code(404);
    echo json_encode(["error" => "Aucune leçon trouvée avec cet ID."]);
}

$stmt->close();
$conn->close();

?>

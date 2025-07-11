<?php
// Fichier : /api/v1/mark_lesson_completed.php
// Description : Enregistre la complétion d'une leçon pour un utilisateur.

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once 'config.php';

// Récupération des données JSON envoyées depuis Flutter.
$data = json_decode(file_get_contents("php://input"));

// Validation des données requises.
if (
    !empty($data->user_id) &&
    !empty($data->lesson_id) &&
    !empty($data->course_id)
) {
    $conn = new mysqli($servername, $username, $password, $dbname);
    if ($conn->connect_error) {
        http_response_code(500);
        echo json_encode(["message" => "Erreur de connexion à la base de données."]);
        exit();
    }
    $conn->set_charset("utf8mb4");

    $user_id = (int)$data->user_id;
    $lesson_id = (int)$data->lesson_id;
    $course_id = (int)$data->course_id;

    // Insertion ou mise à jour dans la table des complétions.
    // "ON DUPLICATE KEY UPDATE" évite les erreurs si l'utilisateur consulte la leçon plusieurs fois.
    $sql = "INSERT INTO user_lesson_completions (user_id, lesson_id, course_id) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE completion_date = NOW()";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("iii", $user_id, $lesson_id, $course_id);

    if ($stmt->execute()) {
        http_response_code(200);
        echo json_encode(["message" => "Leçon marquée comme terminée."]);
    } else {
        http_response_code(500);
        echo json_encode(["message" => "Erreur lors de la mise à jour de la leçon."]);
    }
    $stmt->close();
    $conn->close();
} else {
    http_response_code(400);
    echo json_encode(["message" => "Données incomplètes."]);
}
?>
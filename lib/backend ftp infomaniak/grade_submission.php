<?php
// Fichier: /api/v1/grade_submission.php
// Description: Permet à un instructeur de noter un rendu, de laisser un commentaire structuré en JSON et d'attacher des fichiers.

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once 'config.php';

$data = json_decode(file_get_contents("php://input"));

// Validation des données
if (!isset($data->submission_id)) {
    http_response_code(400);
    echo json_encode(["message" => "L'ID du rendu est manquant."]);
    exit();
}

$submission_id = (int)$data->submission_id;
// La note est optionnelle (pour les devoirs sans note)
$grade = isset($data->grade) ? (float)$data->grade : null;
// Le feedback est un objet JSON, on le ré-encode en chaîne pour le stocker
$feedback_json = isset($data->feedback) ? json_encode($data->feedback) : null;

$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["message" => "Erreur de connexion à la base de données."]);
    exit();
}
$conn->set_charset("utf8mb4");

// La requête met à jour la note, le feedback, le statut, et la date de correction.
$sql = "UPDATE submissions 
        SET 
            grade = ?, 
            instructor_feedback = ?, 
            status = 'graded', 
            graded_date = NOW() 
        WHERE id = ?";

$stmt = $conn->prepare($sql);
if ($stmt === false) {
    http_response_code(500);
    echo json_encode(["message" => "Erreur de préparation de la requête: " . $conn->error]);
    exit();
}

// 'dsi': double, string, integer. Le type pour `grade` peut être NULL, donc on utilise une variable.
$stmt->bind_param("dsi", $grade, $feedback_json, $submission_id);

if ($stmt->execute()) {
    http_response_code(200);
    echo json_encode(["message" => "Rendu noté avec succès."]);
} else {
    http_response_code(500);
    echo json_encode(["message" => "Erreur lors de la notation.", "error" => $stmt->error]);
}

$stmt->close();
$conn->close();
?>
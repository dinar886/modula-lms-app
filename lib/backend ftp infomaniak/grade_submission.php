<?php
// Fichier: /api/v1/grade_submission.php
// Description: Permet à un instructeur de noter un rendu et de laisser un commentaire.

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once 'config.php';

$data = json_decode(file_get_contents("php://input"));

// Validation des données
if (!isset($data->submission_id) || !isset($data->grade)) {
    http_response_code(400);
    echo json_encode(["message" => "ID du rendu et note requis."]);
    exit();
}

$submission_id = (int)$data->submission_id;
$grade = (float)$data->grade;
// Le feedback est optionnel
$feedback = isset($data->feedback) ? $data->feedback : null;

$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["message" => "Erreur de connexion à la base de données."]);
    exit();
}
$conn->set_charset("utf8mb4");

// La requête met à jour la note, le feedback et passe le statut à 'graded' (noté).
$sql = "UPDATE submissions SET grade = ?, instructor_feedback = ?, status = 'graded' WHERE id = ?";
$stmt = $conn->prepare($sql);
// 'dsi': double, string, integer
$stmt->bind_param("dsi", $grade, $feedback, $submission_id);

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
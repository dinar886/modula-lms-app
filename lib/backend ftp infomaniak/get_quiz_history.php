<?php
// Fichier : /api/v1/get_quiz_history.php
// Description : Récupère l'historique des tentatives pour un étudiant et un quiz spécifiques.

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");

require_once 'config.php';

if (!isset($_GET['student_id']) || !isset($_GET['quiz_id'])) {
    http_response_code(400);
    echo json_encode(["error" => "Les ID étudiant et quiz sont requis."]);
    exit();
}

$student_id = (int)$_GET['student_id'];
$quiz_id = (int)$_GET['quiz_id'];

$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["message" => "Erreur de connexion BDD."]);
    exit();
}

$history = [];
$sql = "SELECT score, attempt_date FROM quiz_attempts WHERE student_id = ? AND quiz_id = ? ORDER BY attempt_date DESC";
$stmt = $conn->prepare($sql);
$stmt->bind_param("ii", $student_id, $quiz_id);
$stmt->execute();
$result = $stmt->get_result();

while ($row = $result->fetch_assoc()) {
    $history[] = $row;
}

$stmt->close();
$conn->close();

http_response_code(200);
echo json_encode($history);
?>
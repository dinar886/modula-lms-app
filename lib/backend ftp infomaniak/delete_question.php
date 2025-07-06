<?php
// Fichier : /api/v1/delete_question.php
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once 'config.php';

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->question_id)) {
    $conn = new mysqli($servername, $username, $password, $dbname);
    if ($conn->connect_error) { die("Connection failed: " . $conn->connect_error); }

    $question_id = (int)$data->question_id;

    $sql = "DELETE FROM questions WHERE id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $question_id);

    if ($stmt->execute()) {
        http_response_code(200);
        echo json_encode(["message" => "Question supprimée."]);
    } else {
        http_response_code(500);
        echo json_encode(["message" => "Erreur."]);
    }
    $stmt->close();
    $conn->close();
} else {
    http_response_code(400);
    echo json_encode(["message" => "ID de question manquant."]);
}
?>

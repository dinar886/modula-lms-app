<?php
// Fichier : /api/v1/add_answer.php
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once 'config.php';

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->question_id) && !empty($data->answer_text)) {
    $conn = new mysqli($servername, $username, $password, $dbname);
    if ($conn->connect_error) { die("Connection failed: " . $conn->connect_error); }

    $question_id = (int)$data->question_id;
    $answer_text = $conn->real_escape_string($data->answer_text);

    // Par défaut, une nouvelle réponse n'est pas la bonne.
    $is_correct = 0; 

    $sql = "INSERT INTO answers (question_id, answer_text, is_correct) VALUES (?, ?, ?)";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("isi", $question_id, $answer_text, $is_correct);

    if ($stmt->execute()) {
        http_response_code(201);
        echo json_encode(["message" => "Réponse ajoutée."]);
    } else {
        http_response_code(500);
        echo json_encode(["message" => "Erreur."]);
    }
    $stmt->close();
    $conn->close();
} else {
    http_response_code(400);
    echo json_encode(["message" => "Données incomplètes."]);
}
?>

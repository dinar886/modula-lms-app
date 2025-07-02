<?php
// Fichier : /api/v1/add_question.php
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once 'config.php';

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->quiz_id) && !empty($data->question_text)) {
    $conn = new mysqli($servername, $username, $password, $dbname);
    if ($conn->connect_error) { die("Connection failed: " . $conn->connect_error); }

    $quiz_id = (int)$data->quiz_id;
    $question_text = $conn->real_escape_string($data->question_text);

    $order_sql = "SELECT MAX(order_index) as max_order FROM questions WHERE quiz_id = ?";
    $order_stmt = $conn->prepare($order_sql);
    $order_stmt->bind_param("i", $quiz_id);
    $order_stmt->execute();
    $result = $order_stmt->get_result();
    $row = $result->fetch_assoc();
    $next_order_index = ($row['max_order'] ?? 0) + 1;
    $order_stmt->close();

    $sql = "INSERT INTO questions (quiz_id, question_text, order_index) VALUES (?, ?, ?)";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("isi", $quiz_id, $question_text, $next_order_index);

    if ($stmt->execute()) {
        http_response_code(201);
        echo json_encode(["message" => "Question ajoutée."]);
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

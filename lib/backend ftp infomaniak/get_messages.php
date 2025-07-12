<?php
// Fichier: /api/v1/get_messages.php
// Description: Récupère les messages pour une conversation donnée.

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");

require_once 'config.php';

if (!isset($_GET['conversation_id'])) {
    http_response_code(400);
    echo json_encode(["error" => "L'ID de la conversation est manquant."]);
    exit();
}
$conversation_id = (int)$_GET['conversation_id'];

$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["message" => "Erreur de connexion BDD."]);
    exit();
}
$conn->set_charset("utf8mb4");

$sql = "
    SELECT 
        m.id,
        m.sender_id,
        m.content,
        m.image_url,
        m.created_at,
        u.name as sender_name,
        u.profile_image_url as sender_image_url
    FROM messages m
    JOIN users u ON m.sender_id = u.id
    WHERE m.conversation_id = ?
    ORDER BY m.created_at ASC;
";

$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $conversation_id);
$stmt->execute();
$result = $stmt->get_result();
$messages = [];

while ($row = $result->fetch_assoc()) {
    $messages[] = $row;
}

$stmt->close();
$conn->close();

http_response_code(200);
echo json_encode($messages);
?>
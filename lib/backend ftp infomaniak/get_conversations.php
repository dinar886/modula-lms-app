<?php
// Fichier: /api/v1/get_conversations.php
// Description: Récupère la liste des conversations pour un utilisateur.

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");

require_once 'config.php';

if (!isset($_GET['user_id'])) {
    http_response_code(400);
    echo json_encode(["error" => "L'ID de l'utilisateur est manquant."]);
    exit();
}
$user_id = (int)$_GET['user_id'];

$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["message" => "Erreur de connexion BDD."]);
    exit();
}
$conn->set_charset("utf8mb4");

// Cette requête complexe récupère les conversations et les informations nécessaires :
// - Pour les chats de groupe, le nom du cours.
// - Pour les chats individuels, le nom de l'autre participant.
// - Le dernier message et sa date pour l'aperçu.
$sql = "
    SELECT 
        c.id,
        c.type,
        c.last_message_at,
        CASE
            WHEN c.type = 'group' THEN c.name
            ELSE other_user.name
        END AS conversation_name,
        CASE
            WHEN c.type = 'group' THEN co.image_url
            ELSE other_user.profile_image_url
        END AS conversation_image_url,
        (SELECT content FROM messages WHERE conversation_id = c.id ORDER BY created_at DESC LIMIT 1) as last_message
    FROM conversations c
    JOIN conversation_participants cp ON c.id = cp.conversation_id
    LEFT JOIN courses co ON c.course_id = co.id
    LEFT JOIN conversation_participants other_cp ON c.id = other_cp.conversation_id AND other_cp.user_id != ?
    LEFT JOIN users other_user ON other_cp.user_id = other_user.id
    WHERE cp.user_id = ? AND (c.type = 'group' OR other_user.id IS NOT NULL)
    GROUP BY c.id
    ORDER BY c.last_message_at DESC;
";

$stmt = $conn->prepare($sql);
$stmt->bind_param("ii", $user_id, $user_id);
$stmt->execute();
$result = $stmt->get_result();
$conversations = [];

while ($row = $result->fetch_assoc()) {
    $conversations[] = $row;
}

$stmt->close();
$conn->close();

http_response_code(200);
echo json_encode($conversations);
?>
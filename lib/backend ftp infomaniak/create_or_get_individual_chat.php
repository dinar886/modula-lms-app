<?php
// Fichier: /api/v1/create_or_get_individual_chat.php
// Description: Crée ou récupère une conversation individuelle entre deux utilisateurs.

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");

require_once 'config.php';

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->user1_id) || !isset($data->user2_id)) {
    http_response_code(400);
    echo json_encode(["message" => "Les IDs des deux utilisateurs sont requis."]);
    exit();
}

$user1_id = (int)$data->user1_id;
$user2_id = (int)$data->user2_id;

$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["message" => "Erreur de connexion BDD."]);
    exit();
}
$conn->set_charset("utf8mb4");

// 1. Chercher une conversation existante entre ces deux utilisateurs
$sql_find = "
    SELECT cp1.conversation_id 
    FROM conversation_participants cp1
    JOIN conversation_participants cp2 ON cp1.conversation_id = cp2.conversation_id
    JOIN conversations c ON cp1.conversation_id = c.id
    WHERE cp1.user_id = ? AND cp2.user_id = ? AND c.type = 'individual'
";

$stmt_find = $conn->prepare($sql_find);
$stmt_find->bind_param("ii", $user1_id, $user2_id);
$stmt_find->execute();
$result_find = $stmt_find->get_result();

if ($result_find->num_rows > 0) {
    // La conversation existe, on renvoie son ID
    $conversation = $result_find->fetch_assoc();
    http_response_code(200);
    echo json_encode(['conversation_id' => $conversation['conversation_id']]);
    $stmt_find->close();
    $conn->close();
    exit();
}
$stmt_find->close();

// 2. Si non trouvée, créer une nouvelle conversation
$conn->begin_transaction();
try {
    // Créer la conversation
    $sql_create_convo = "INSERT INTO conversations (type) VALUES ('individual')";
    $conn->query($sql_create_convo);
    $conversation_id = $conn->insert_id;

    // Ajouter les deux participants
    $sql_add_participants = "INSERT INTO conversation_participants (conversation_id, user_id) VALUES (?, ?), (?, ?)";
    $stmt_add = $conn->prepare($sql_add_participants);
    $stmt_add->bind_param("iiii", $conversation_id, $user1_id, $conversation_id, $user2_id);
    $stmt_add->execute();
    $stmt_add->close();

    $conn->commit();
    http_response_code(201);
    echo json_encode(['conversation_id' => $conversation_id]);

} catch (Exception $e) {
    $conn->rollback();
    http_response_code(500);
    echo json_encode(['message' => 'Erreur lors de la création de la conversation.', 'error' => $e->getMessage()]);
}

$conn->close();
?>
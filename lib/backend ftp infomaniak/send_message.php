<?php
/**
 * Fichier: /api/v1/send_message.php
 * Description: Gère l'envoi de messages, les notifications push et renvoie le message créé.
 */

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");

require_once 'config.php';
// S'assure que le chemin vers le dossier vendor est correct par rapport à l'emplacement de ce script.
require_once __DIR__ . '/vendor/autoload.php';

use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->conversation_id) || !isset($data->sender_id) || !isset($data->content)) {
    http_response_code(400);
    echo json_encode(["message" => "Données manquantes (conversation_id, sender_id, content)."]);
    exit();
}

$conversation_id = (int)$data->conversation_id;
$sender_id = (int)$data->sender_id;
$content = $data->content;
$image_url = $data->image_url ?? null; 

$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["message" => "Erreur de connexion à la base de données."]);
    exit();
}
$conn->set_charset("utf8mb4");

// On utilise une transaction pour garantir l'intégrité des données
$conn->begin_transaction();

try {
    // 1. Insérer le message dans la base de données
    $sql_insert = "INSERT INTO messages (conversation_id, sender_id, content, image_url) VALUES (?, ?, ?, ?)";
    $stmt_insert = $conn->prepare($sql_insert);
    $stmt_insert->bind_param("iiss", $conversation_id, $sender_id, $content, $image_url);
    $stmt_insert->execute();
    $message_id = $conn->insert_id; // On récupère l'ID du message inséré
    $stmt_insert->close();

    // 2. Mettre à jour la date du dernier message dans la table des conversations
    $sql_update_convo = "UPDATE conversations SET last_message_at = NOW() WHERE id = ?";
    $stmt_update = $conn->prepare($sql_update_convo);
    $stmt_update->bind_param("i", $conversation_id);
    $stmt_update->execute();
    $stmt_update->close();

    // 3. Récupérer l'objet complet du message qui vient d'être créé
    $sql_get_sent_message = "
        SELECT 
            m.id, m.sender_id, m.content, m.image_url, m.created_at,
            u.name as sender_name, u.profile_image_url as sender_image_url
        FROM messages m
        JOIN users u ON m.sender_id = u.id
        WHERE m.id = ?
    ";
    $stmt_get_message = $conn->prepare($sql_get_sent_message);
    $stmt_get_message->bind_param("i", $message_id);
    $stmt_get_message->execute();
    $sent_message_result = $stmt_get_message->get_result();
    $sent_message = $sent_message_result->fetch_assoc();
    $stmt_get_message->close();

    // 4. Récupérer les informations pour la notification push
    $sql_info = "
        SELECT 
            u.name as sender_name,
            c.name as conversation_name,
            c.type as conversation_type
        FROM users u
        CROSS JOIN conversations c 
        WHERE u.id = ? AND c.id = ?;
    ";
    $stmt_info = $conn->prepare($sql_info);
    $stmt_info->bind_param("ii", $sender_id, $conversation_id);
    $stmt_info->execute();
    $info_result = $stmt_info->get_result()->fetch_assoc();
    $sender_name = $info_result['sender_name'];
    $conversation_name = $info_result['conversation_name'];
    $conversation_type = $info_result['conversation_type'];

    // 5. Récupérer les tokens FCM des autres participants de la conversation
    $sql_tokens = "
        SELECT u.fcm_token 
        FROM users u
        JOIN conversation_participants cp ON u.id = cp.user_id
        WHERE cp.conversation_id = ? AND u.id != ? AND u.fcm_token IS NOT NULL
    ";
    $stmt_tokens = $conn->prepare($sql_tokens);
    $stmt_tokens->bind_param("ii", $conversation_id, $sender_id);
    $stmt_tokens->execute();
    $result_tokens = $stmt_tokens->get_result();
    
    $tokens = [];
    while ($row = $result_tokens->fetch_assoc()) {
        $tokens[] = $row['fcm_token'];
    }
    $stmt_tokens->close();

    // 6. Envoyer les notifications push via Firebase si des tokens existent
    if (!empty($tokens)) {
        $factory = (new Factory)->withServiceAccount(__DIR__ . '/firebase_credentials.json');
        $messaging = $factory->createMessaging();

        $notification_title = ($conversation_type === 'group') ? $conversation_name : $sender_name;
        $notification_body = ($conversation_type === 'group' && $content) ? "$sender_name: $content" : $content;
        if(empty($content) && !empty($image_url)){
            $notification_body = ($conversation_type === 'group') ? "$sender_name a envoyé une image" : "Vous a envoyé une image";
        }


        $notification = Notification::create($notification_title, $notification_body);
        
        $data_payload = [
            'screen' => '/chat',
            'conversation_id' => (string)$conversation_id,
        ];

        $message = CloudMessage::new()
            ->withNotification($notification)
            ->withData($data_payload);
        
        $messaging->sendMulticast($message, $tokens);
    }

    // Si tout est OK, on valide la transaction
    $conn->commit();
    
    http_response_code(200); // 200 OK car on renvoie du contenu
    echo json_encode([
        "success" => true,
        "message" => "Message envoyé avec succès.", 
        "sent_message" => $sent_message // On renvoie le message complet
    ]);

} catch (Exception $e) {
    $conn->rollback();
    http_response_code(500);
    error_log("Erreur lors de l'envoi du message: " . $e->getMessage());
    echo json_encode(["success" => false, "message" => "Erreur lors de l'envoi du message.", "error" => $e->getMessage()]);
}

$conn->close();
?>
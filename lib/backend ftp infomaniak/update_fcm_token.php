<?php
// Fichier : /api/v1/update_fcm_token.php
// Description : Met à jour le token FCM pour un utilisateur donné.

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once 'config.php';

// Récupération des données JSON envoyées depuis Flutter.
$data = json_decode(file_get_contents("php://input"));

// Validation des données.
if (!isset($data->user_id) || !isset($data->fcm_token)) {
    http_response_code(400);
    echo json_encode(["message" => "L'ID utilisateur et le token FCM sont requis."]);
    exit();
}

$user_id = (int)$data->user_id;
$fcm_token = $data->fcm_token;

// Connexion à la base de données.
$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["message" => "Erreur de connexion à la base de données."]);
    exit();
}
$conn->set_charset("utf8mb4");

// Préparation de la requête de mise à jour.
$sql = "UPDATE users SET fcm_token = ? WHERE id = ?";
$stmt = $conn->prepare($sql);

if ($stmt === false) {
    http_response_code(500);
    echo json_encode(["message" => "Erreur de préparation de la requête."]);
    exit();
}

// Liaison des paramètres et exécution.
$stmt->bind_param("si", $fcm_token, $user_id);
if ($stmt->execute()) {
    http_response_code(200);
    echo json_encode(["message" => "Token FCM mis à jour avec succès."]);
} else {
    http_response_code(500);
    echo json_encode(["message" => "Erreur lors de la mise à jour du token."]);
}

$stmt->close();
$conn->close();
?>
<?php
// Fichier : /api/v1/login.php

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once 'config.php';

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->email) && !empty($data->password)) {
    $conn = new mysqli($servername, $username, $password, $dbname);

    if ($conn->connect_error) {
        http_response_code(500);
        echo json_encode(["message" => "Erreur de connexion à la base de données."]);
        exit();
    }

    $email = $conn->real_escape_string($data->email);

    // On sélectionne maintenant aussi la colonne 'role'.
    $sql = "SELECT id, name, email, password, role FROM users WHERE email = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        $user = $result->fetch_assoc();
        $hashed_password = $user['password'];

        if (password_verify($data->password, $hashed_password)) {
            
            // On ajoute le rôle aux données de l'utilisateur renvoyées.
            $user_data = [
                "id" => $user['id'],
                "name" => $user['name'],
                "email" => $user['email'],
                "role" => $user['role'] // Ajout du rôle
            ];

            http_response_code(200);
            echo json_encode([
                "message" => "Connexion réussie.",
                "user" => $user_data
            ]);

        } else {
            http_response_code(401);
            echo json_encode(["message" => "Mot de passe incorrect."]);
        }
    } else {
        http_response_code(404);
        echo json_encode(["message" => "Aucun compte trouvé avec cet email."]);
    }
    $stmt->close();
    $conn->close();
} else {
    http_response_code(400);
    echo json_encode(["message" => "Données incomplètes."]);
}
?>
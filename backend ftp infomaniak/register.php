<?php
// Fichier : /api/v1/register.php

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST"); // Cette route n'accepte que les requêtes POST.
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once 'config.php';

// Récupère les données envoyées depuis l'application Flutter.
$data = json_decode(file_get_contents("php://input"));

// Vérifie que toutes les données nécessaires sont présentes.
if (
    !empty($data->name) &&
    !empty($data->email) &&
    !empty($data->password)
) {
    $conn = new mysqli($servername, $username, $password, $dbname);

    if ($conn->connect_error) {
        http_response_code(500);
        echo json_encode(["message" => "Erreur de connexion à la base de données."]);
        exit();
    }

    // Sécurise les données reçues.
    $name = $conn->real_escape_string($data->name);
    $email = $conn->real_escape_string($data->email);

    // Hachage sécurisé du mot de passe. Ne JAMAIS stocker un mot de passe en clair !
    $hashed_password = password_hash($data->password, PASSWORD_BCRYPT);

    // Vérifie si l'email existe déjà.
    $check_email_sql = "SELECT id FROM users WHERE email = ?";
    $stmt_check = $conn->prepare($check_email_sql);
    $stmt_check->bind_param("s", $email);
    $stmt_check->execute();
    $stmt_check->store_result();

    if ($stmt_check->num_rows > 0) {
        http_response_code(409); // Conflict
        echo json_encode(["message" => "Un compte avec cet email existe déjà."]);
        $stmt_check->close();
        $conn->close();
        exit();
    }
    $stmt_check->close();


    // Prépare la requête d'insertion.
    $sql = "INSERT INTO users (name, email, password) VALUES (?, ?, ?)";
    $stmt = $conn->prepare($sql);

    // Lie les variables à la requête préparée.
    $stmt->bind_param("sss", $name, $email, $hashed_password);

    // Exécute la requête.
    if ($stmt->execute()) {
        http_response_code(201); // Created
        echo json_encode(["message" => "Compte créé avec succès."]);
    } else {
        http_response_code(500);
        echo json_encode(["message" => "Erreur lors de la création du compte."]);
    }
    $stmt->close();
    $conn->close();

} else {
    // Si des données sont manquantes, renvoie une erreur.
    http_response_code(400); // Bad Request
    echo json_encode(["message" => "Données incomplètes."]);
}
?>
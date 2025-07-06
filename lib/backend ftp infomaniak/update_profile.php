<?php
// Fichier : /api/v1/update_profile.php

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once 'config.php';

$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["message" => "Erreur de connexion à la base de données: " . $conn->connect_error]);
    exit();
}
$conn->set_charset("utf8");

// Vérification de la présence de l'ID utilisateur
if (!isset($_POST['user_id'])) {
    http_response_code(400);
    echo json_encode(["message" => "L'ID de l'utilisateur est manquant."]);
    exit();
}

$user_id = (int)$_POST['user_id'];
// Utilisation de l'opérateur null coalescent pour plus de sécurité
$name = $_POST['name'] ?? '';
$email = $_POST['email'] ?? '';

// On initialise les variables pour la requête SQL
$update_fields = ['name = ?', 'email = ?'];
$params = [$name, $email];
$param_types = 'ss';

// --- LOGIQUE DE GESTION DE L'IMAGE (AMÉLIORÉE) ---

// On vérifie si un fichier a été envoyé ET s'il n'y a pas eu d'erreur d'upload.
if (isset($_FILES['profile_image']) && $_FILES['profile_image']['error'] === UPLOAD_ERR_OK) {
    
    // Chemin de destination plus sécurisé, à la racine du serveur web.
    // $_SERVER['DOCUMENT_ROOT'] pointe vers la racine de votre site (ex: /home/clients/.../web/).
    // Assurez-vous que le dossier /uploads/profile_images/ existe et a les bonnes permissions.
    $upload_dir = $_SERVER['DOCUMENT_ROOT'] . '/uploads/profile_images/';

    // Crée le répertoire s'il n'existe pas.
    if (!is_dir($upload_dir)) {
        if (!mkdir($upload_dir, 0755, true)) {
            http_response_code(500);
            echo json_encode(["message" => "Impossible de créer le répertoire de destination sur le serveur."]);
            exit();
        }
    }

    $file_info = pathinfo($_FILES['profile_image']['name']);
    $file_ext = strtolower($file_info['extension']);
    $unique_filename = 'user_' . $user_id . '_' . time() . '.' . $file_ext;
    $target_file_path = $upload_dir . $unique_filename;

    // Déplace le fichier temporaire vers sa destination finale
    if (move_uploaded_file($_FILES['profile_image']['tmp_name'], $target_file_path)) {
        
        // Construction de l'URL publique accessible depuis le navigateur
        $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off' || $_SERVER['SERVER_PORT'] == 443) ? "https://" : "http://";
        $domain_name = $_SERVER['HTTP_HOST'];
        // L'URL pointe maintenant vers le dossier à la racine.
        $profile_image_url = $protocol . $domain_name . '/uploads/profile_images/' . $unique_filename;

        // **On ajoute le champ de l'URL à la requête SQL UNIQUEMENT si l'upload a réussi**
        $update_fields[] = 'profile_image_url = ?';
        $params[] = $profile_image_url;
        $param_types .= 's';

    } else {
        http_response_code(500);
        echo json_encode(["message" => "Erreur lors de la sauvegarde de l'image sur le serveur."]);
        exit();
    }
}

// Construction dynamique de la requête SQL
$sql = "UPDATE users SET " . implode(', ', $update_fields) . " WHERE id = ?";
$params[] = $user_id;
$param_types .= 'i';

$stmt = $conn->prepare($sql);
if ($stmt === false) {
    http_response_code(500);
    echo json_encode(["message" => "Erreur de préparation de la requête: " . $conn->error]);
    exit();
}

// '...' est l'opérateur "splat" qui décompose le tableau $params en arguments individuels
$stmt->bind_param($param_types, ...$params);

if ($stmt->execute()) {
    // Après la mise à jour, on récupère l'utilisateur complet pour le renvoyer à l'app.
    $stmt_select = $conn->prepare("SELECT id, name, email, role, profile_image_url FROM users WHERE id = ?");
    $stmt_select->bind_param("i", $user_id);
    $stmt_select->execute();
    $updated_user = $stmt_select->get_result()->fetch_assoc();
    $stmt_select->close();

    http_response_code(200);
    echo json_encode([
        "message" => "Profil mis à jour avec succès.",
        "user" => $updated_user
    ]);
} else {
    http_response_code(500);
    echo json_encode(["message" => "Erreur lors de la mise à jour du profil: " . $stmt->error]);
}

$stmt->close();
$conn->close();
?>
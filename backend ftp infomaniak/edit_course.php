<?php
// Fichier : /api/v1/edit_course.php

// Headers pour la réponse JSON et les autorisations CORS
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Inclusion du fichier de configuration pour la base de données
require_once 'config.php';

// Connexion à la base de données
$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["message" => "Erreur de connexion à la base de données: " . $conn->connect_error]);
    exit();
}
// On s'assure que l'encodage est bien en UTF-8
$conn->set_charset("utf8");

// On vérifie que les données POST nécessaires sont présentes.
if (
    !empty($_POST['course_id']) &&
    !empty($_POST['title']) &&
    !empty($_POST['description']) &&
    isset($_POST['price'])
) {
    // Sécurisation des données reçues via POST
    $course_id = (int)$_POST['course_id'];
    $title = $conn->real_escape_string($_POST['title']);
    $description = $conn->real_escape_string($_POST['description']);
    $price = (float)$_POST['price'];
    $color = isset($_POST['color']) ? $conn->real_escape_string($_POST['color']) : '#005A9C'; // Couleur par défaut

    $image_url = '';

    // --- Gestion de l'upload de l'image ---
    if (isset($_FILES['image']) && $_FILES['image']['error'] == UPLOAD_ERR_OK) {
        $upload_dir = 'uploads/';
        // Créer le dossier s'il n'existe pas
        if (!is_dir($upload_dir)) {
            mkdir($upload_dir, 0755, true);
        }

        $file_info = pathinfo($_FILES['image']['name']);
        $file_ext = strtolower($file_info['extension']);
        // Générer un nom de fichier unique pour éviter les conflits
        $unique_filename = uniqid('course_', true) . '.' . $file_ext;
        $target_file = $upload_dir . $unique_filename;

        // Déplacer le fichier uploadé vers le dossier de destination
        if (move_uploaded_file($_FILES['image']['tmp_name'], $target_file)) {
            // Construire l'URL complète de l'image
            // Assurez-vous que le protocole (http/https) et le nom de domaine sont corrects
            $image_url = "https://modula-lms.com/api/v1/" . $target_file;
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Erreur lors du déplacement du fichier uploadé."]);
            exit();
        }
    } else {
        // --- Si aucune image n'est uploadée, on utilise le placeholder ---
        // On récupère l'ancienne URL pour ne pas la régénérer si la couleur n'a pas changé
        $result = $conn->query("SELECT image_url FROM courses WHERE id = $course_id");
        $row = $result->fetch_assoc();
        $current_image_url = $row['image_url'];

        // On ne génère une nouvelle URL de placeholder que si la couleur a changé ou si l'URL n'est pas déjà un placeholder
        $encoded_title = urlencode($title);
        $hex_color = ltrim($color, '#'); // Enlève le '#' pour l'URL
        $image_url = "https://placehold.co/600x400/{$hex_color}/FFFFFF/png?text={$encoded_title}";
    }

    // --- Mise à jour de la base de données ---
    // On prépare la requête de mise à jour avec les nouvelles colonnes
    $sql = "UPDATE courses SET title = ?, description = ?, price = ?, image_url = ?, color = ? WHERE id = ?";
    $stmt = $conn->prepare($sql);
    if ($stmt === false) {
        http_response_code(500);
        echo json_encode(["message" => "Erreur de préparation de la requête: " . $conn->error]);
        exit();
    }
    
    // 'sddssi' correspond aux types : string, string, double, string, string, integer
    $stmt->bind_param("ssdssi", $title, $description, $price, $image_url, $color, $course_id);

    if ($stmt->execute()) {
        http_response_code(200);
        echo json_encode(["message" => "Cours mis à jour avec succès.", "new_image_url" => $image_url]);
    } else {
        http_response_code(500);
        echo json_encode(["message" => "Erreur lors de la mise à jour du cours: " . $stmt->error]);
    }
    $stmt->close();

} else {
    http_response_code(400);
    echo json_encode(["message" => "Données incomplètes.", "received" => $_POST]);
}

$conn->close();
?>
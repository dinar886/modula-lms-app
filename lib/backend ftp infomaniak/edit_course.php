<?php
// Fichier : /api/v1/edit_course.php

// Headers pour autoriser l'accès à l'API et définir le type de contenu
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Inclusion du fichier de configuration de la base de données
require_once 'config.php';

// Établissement de la connexion à la base de données
$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500); // Erreur serveur
    echo json_encode(["message" => "Erreur de connexion à la base de données: " . $conn->connect_error]);
    exit();
}
// Forcer l'encodage en UTF-8 pour la communication avec la base de données
$conn->set_charset("utf8");

// Vérification que les données nécessaires ont été envoyées via la méthode POST
if (
    !empty($_POST['course_id']) &&
    !empty($_POST['title']) &&
    isset($_POST['description']) && // La description peut être vide, mais doit être définie
    isset($_POST['price'])
) {
    // Nettoyage et sécurisation des données reçues
    $course_id = (int)$_POST['course_id'];
    $title = $conn->real_escape_string($_POST['title']);
    $description = $conn->real_escape_string($_POST['description']);
    $price = (float)$_POST['price'];

    // Étape 1 : Récupérer les informations actuelles du cours (image et couleur)
    $stmt_select = $conn->prepare("SELECT image_url, color FROM courses WHERE id = ?");
    $stmt_select->bind_param("i", $course_id);
    $stmt_select->execute();
    $result = $stmt_select->get_result();
    $existing_course = $result->fetch_assoc();
    $stmt_select->close();

    // Si le cours n'existe pas, on arrête le script
    if (!$existing_course) {
        http_response_code(404); // Non trouvé
        echo json_encode(["message" => "Cours non trouvé."]);
        exit();
    }

    // On récupère l'URL de l'image et la couleur actuelles
    $image_url = $existing_course['image_url'];
    $color = !empty($_POST['color']) ? $conn->real_escape_string($_POST['color']) : $existing_course['color'];

    $image_was_updated = false;

    // Étape 2 : Gestion de l'upload d'une NOUVELLE image
    if (isset($_FILES['image']) && $_FILES['image']['error'] == UPLOAD_ERR_OK) {
        $upload_dir = 'uploads/'; // Dossier de destination des images
        if (!is_dir($upload_dir)) {
            mkdir($upload_dir, 0755, true);
        }

        // On génère un nom de fichier unique pour éviter les conflits
        $file_info = pathinfo($_FILES['image']['name']);
        $file_ext = strtolower($file_info['extension']);
        $unique_filename = uniqid('course_', true) . '.' . $file_ext;
        $target_file = $upload_dir . $unique_filename;

        // On déplace le fichier temporaire vers son emplacement final
        if (move_uploaded_file($_FILES['image']['tmp_name'], $target_file)) {
            // Si le déplacement réussit, on met à jour l'URL de l'image
            $image_url = "https://modula-lms.com/api/v1/" . $target_file;
            $image_was_updated = true;
        } else {
            http_response_code(500); // Erreur serveur
            echo json_encode(["message" => "Erreur lors du déplacement du fichier uploadé."]);
            exit();
        }
    }

    // Étape 3 : Si aucune nouvelle image n'a été uploadée, on gère le placeholder
    if (!$image_was_updated) {
        // On vérifie si l'image actuelle est un placeholder ou si elle est vide
        // Si c'est le cas, on la (re)génère pour refléter les changements de titre ou de couleur
        if (empty($image_url) || strpos($image_url, 'placehold.co') !== false) {
             $encoded_title = urlencode($title); // On encode le titre pour l'URL
             $hex_color = ltrim($color, '#');   // On s'assure que la couleur est au format hexadécimal sans #
             $image_url = "https://placehold.co/600x400/{$hex_color}/FFFFFF/png?text={$encoded_title}";
        }
        // Si une "vraie" image existait déjà, on ne touche à rien et on la conserve.
    }

    // Étape 4 : Mise à jour des informations dans la base de données
    $sql = "UPDATE courses SET title = ?, description = ?, price = ?, image_url = ?, color = ? WHERE id = ?";
    $stmt = $conn->prepare($sql);
    if ($stmt === false) {
        http_response_code(500);
        echo json_encode(["message" => "Erreur de préparation de la requête: " . $conn->error]);
        exit();
    }
    
    // On lie les variables à la requête préparée
    $stmt->bind_param("ssdssi", $title, $description, $price, $image_url, $color, $course_id);

    // On exécute la requête
    if ($stmt->execute()) {
        http_response_code(200); // Succès
        echo json_encode(["message" => "Cours mis à jour avec succès."]);
    } else {
        http_response_code(500); // Erreur serveur
        echo json_encode(["message" => "Erreur lors de la mise à jour du cours: " . $stmt->error]);
    }
    $stmt->close();

} else {
    // Si les données POST sont incomplètes
    http_response_code(400); // Mauvaise requête
    echo json_encode(["message" => "Données incomplètes.", "received" => $_POST]);
}

// On ferme la connexion à la base de données
$conn->close();
?>
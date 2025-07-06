<?php
// Fichier : /api/v1/upload_file.php
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// L'URL de base de votre API. Assurez-vous qu'elle est correcte !
$base_url = "https://modula-lms.com/api/v1"; 
$upload_dir_name = 'uploads';
$upload_path = __DIR__ . '/' . $upload_dir_name . '/';

// Crée le dossier 'uploads' s'il n'existe pas.
if (!is_dir($upload_path)) {
    if (!mkdir($upload_path, 0777, true)) {
        http_response_code(500);
        echo json_encode(["success" => false, "message" => "Impossible de créer le dossier de téléversement. Vérifiez les permissions."]);
        exit;
    }
}

// **CORRECTION** : On vérifie si le fichier existe sous la clé 'file' (préférée)
// ou 'imageFile' (ancienne clé, pour la compatibilité).
$file = null;
if (isset($_FILES['file'])) {
    $file = $_FILES['file'];
} elseif (isset($_FILES['imageFile'])) {
    $file = $_FILES['imageFile'];
}

// Si après vérification, aucun fichier n'a été trouvé.
if ($file === null || $file['error'] === UPLOAD_ERR_NO_FILE) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Aucun fichier n'a été reçu. Assurez-vous d'envoyer le fichier sous la clé 'file'."]);
    exit;
}

$error = $file['error'];
$file_name = $file['name'];
$file_tmp_name = $file['tmp_name'];
$file_ext = strtolower(pathinfo($file_name, PATHINFO_EXTENSION));

// --- Validation ---
$allowed_ext = ['jpg', 'jpeg', 'png', 'gif', 'pdf'];
if (!in_array($file_ext, $allowed_ext)) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Type de fichier non autorisé. Uniquement : " . implode(', ', $allowed_ext)]);
    exit;
}

if ($error !== UPLOAD_ERR_OK) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Erreur durant le téléversement. Code d'erreur : " . $error]);
    exit;
}

// --- Sauvegarde du Fichier ---
$unique_file_name = uniqid('file_', true) . '.' . $file_ext;
$destination = $upload_path . $unique_file_name;

if (move_uploaded_file($file_tmp_name, $destination)) {
    $file_url = $base_url . '/' . $upload_dir_name . '/' . $unique_file_name;
    
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "message" => "Fichier téléversé avec succès.",
        "url" => $file_url,
        "file_type" => $file_ext
    ]);
} else {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Échec de la sauvegarde du fichier sur le serveur."]);
}
?>
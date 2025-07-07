<?php
// Fichier : /api/v1/upload_file.php
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// --- CORRECTION 1 : L'URL de base pointe maintenant à la racine de votre site.
$base_url = "https://modula-lms.com"; 
$upload_dir_name = 'uploads';

// --- CORRECTION 2 : On utilise $_SERVER['DOCUMENT_ROOT'] pour accéder à la racine de votre hébergement (ex: /home/user/public_html).
// Cela garantit que le dossier 'uploads' sera à la racine et non dans le dossier de l'API.
$upload_path = $_SERVER['DOCUMENT_ROOT'] . '/' . $upload_dir_name . '/';

// Crée le dossier 'uploads' à la racine s'il n'existe pas.
// IMPORTANT : Assurez-vous que le serveur PHP a les droits pour créer ce dossier.
// Sinon, créez-le manuellement via votre client FTP.
if (!is_dir($upload_path)) {
    if (!mkdir($upload_path, 0755, true)) { // 0755 est plus sécurisé que 0777
        http_response_code(500);
        echo json_encode(["success" => false, "message" => "Impossible de créer le dossier de téléversement à la racine. Vérifiez les permissions."]);
        exit;
    }
}

// On vérifie si le fichier a été envoyé.
$file = null;
if (isset($_FILES['file'])) {
    $file = $_FILES['file'];
} elseif (isset($_FILES['imageFile'])) {
    $file = $_FILES['imageFile'];
}

if ($file === null || $file['error'] === UPLOAD_ERR_NO_FILE) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Aucun fichier n'a été reçu."]);
    exit;
}

$error = $file['error'];
$file_name = $file['name'];
$file_tmp_name = $file['tmp_name'];
$file_ext = strtolower(pathinfo($file_name, PATHINFO_EXTENSION));

// Validation des extensions autorisées
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

// Sauvegarde du Fichier avec un nom unique
$unique_file_name = uniqid('file_', true) . '.' . $file_ext;
$destination = $upload_path . $unique_file_name;

if (move_uploaded_file($file_tmp_name, $destination)) {
    // --- CORRECTION 3 : L'URL est maintenant beaucoup plus propre et directement accessible.
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
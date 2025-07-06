<?php
// Fichier : /api/v1/create_course.php

// Headers pour la réponse JSON et les autorisations CORS
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once 'config.php';

// Connexion à la base de données
$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["message" => "Erreur de connexion à la base de données: " . $conn->connect_error]);
    exit();
}
$conn->set_charset("utf8");

// **MODIFIÉ** : On lit les données depuis `$_POST` car on utilise `multipart/form-data`.
if (
    !empty($_POST['title']) &&
    isset($_POST['description']) &&
    isset($_POST['price']) &&
    !empty($_POST['instructor_id'])
) {
    // On commence une transaction pour garantir la cohérence des données.
    $conn->begin_transaction();

    try {
        // Sécurisation des données
        $title = $conn->real_escape_string($_POST['title']);
        $description = $conn->real_escape_string($_POST['description']);
        $price = (float)$_POST['price'];
        $instructor_id = (int)$_POST['instructor_id'];
        // On récupère la couleur (ou une couleur par défaut si non fournie).
        $color = !empty($_POST['color']) ? $conn->real_escape_string($_POST['color']) : '#005A9C';

        // Récupération du nom de l'auteur
        $author_name = '';
        $user_sql = "SELECT name FROM users WHERE id = ?";
        $user_stmt = $conn->prepare($user_sql);
        $user_stmt->bind_param("i", $instructor_id);
        $user_stmt->execute();
        $user_result = $user_stmt->get_result();
        if ($user_row = $user_result->fetch_assoc()) {
            $author_name = $user_row['name'];
        }
        $user_stmt->close();

        if (empty($author_name)) {
            throw new Exception("Instructeur non trouvé.");
        }

        $image_url = '';

        // **NOUVEAU** : Gestion de l'upload de l'image
        if (isset($_FILES['image']) && $_FILES['image']['error'] == UPLOAD_ERR_OK) {
            $upload_dir = 'uploads/';
            if (!is_dir($upload_dir)) {
                mkdir($upload_dir, 0755, true);
            }
            $file_info = pathinfo($_FILES['image']['name']);
            $file_ext = strtolower($file_info['extension']);
            $unique_filename = uniqid('course_', true) . '.' . $file_ext;
            $target_file = $upload_dir . $unique_filename;

            if (move_uploaded_file($_FILES['image']['tmp_name'], $target_file)) {
                // On construit l'URL complète de l'image
                $image_url = "https://modula-lms.com/api/v1/" . $target_file;
            } else {
                throw new Exception("Erreur lors du déplacement du fichier uploadé.");
            }
        } else {
            // Si aucune image n'est uploadée, on crée une image placeholder.
            $encoded_title = urlencode($title);
            $hex_color = ltrim($color, '#');
            $image_url = "https://placehold.co/600x400/{$hex_color}/FFFFFF/png?text={$encoded_title}";
        }

        // **MODIFIÉ** : On insère le cours avec l'image et la couleur.
        $sql = "INSERT INTO courses (title, description, price, image_url, color, author) VALUES (?, ?, ?, ?, ?, ?)";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("ssdsss", $title, $description, $price, $image_url, $color, $author_name);
        $stmt->execute();
        $course_id = $conn->insert_id;
        $stmt->close();
        
        // On lie l'instructeur au cours.
        $link_sql = "INSERT INTO user_courses (user_id, course_id) VALUES (?, ?)";
        $link_stmt = $conn->prepare($link_sql);
        $link_stmt->bind_param("ii", $instructor_id, $course_id);
        $link_stmt->execute();
        $link_stmt->close();
        
        // On valide la transaction.
        $conn->commit();
        
        http_response_code(201);
        echo json_encode(["message" => "Cours créé avec succès.", "course_id" => $course_id]);

    } catch (Exception $e) {
        $conn->rollback();
        http_response_code(500);
        echo json_encode(["message" => "Erreur lors de la création du cours.", "error" => $e->getMessage()]);
    }

} else {
    http_response_code(400);
    echo json_encode(["message" => "Données incomplètes.", "received_post" => $_POST, "received_files" => $_FILES]);
}

$conn->close();
?>
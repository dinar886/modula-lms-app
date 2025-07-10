<?php
// Fichier : /api/v1/create_course.php

// Headers pour la réponse JSON et les autorisations CORS
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// --- INCLUSIONS ---
require_once 'config.php';
// Inclusion de la librairie Stripe
require_once __DIR__ . '/vendor/autoload.php';

// Initialisation du client Stripe avec la clé secrète de votre config
\Stripe\Stripe::setApiKey($stripeSecretKey);

// --- CONNEXION BDD ---
$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["message" => "Erreur de connexion à la base de données: " . $conn->connect_error]);
    exit();
}
$conn->set_charset("utf8");

// --- TRAITEMENT DE LA REQUÊTE ---
if (
    !empty($_POST['title']) &&
    isset($_POST['description']) &&
    isset($_POST['price']) &&
    !empty($_POST['instructor_id'])
) {
    $conn->begin_transaction();

    try {
        // --- DONNÉES DU COURS ---
        $title = $conn->real_escape_string($_POST['title']);
        $description = $conn->real_escape_string($_POST['description']);
        $price = (float)$_POST['price'];
        $instructor_id = (int)$_POST['instructor_id'];
        $color = !empty($_POST['color']) ? $conn->real_escape_string($_POST['color']) : '#005A9C';

        // --- GESTION DE L'IMAGE ---
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
        if (isset($_FILES['imageFile']) && $_FILES['imageFile']['error'] == UPLOAD_ERR_OK) {
            $upload_dir = $_SERVER['DOCUMENT_ROOT'] . '/uploads/courses/';
            if (!is_dir($upload_dir)) {
                mkdir($upload_dir, 0755, true);
            }
            $file_info = pathinfo($_FILES['imageFile']['name']);
            $file_ext = strtolower($file_info['extension']);
            $unique_filename = uniqid('course_', true) . '.' . $file_ext;
            $target_file = $upload_dir . $unique_filename;

            if (move_uploaded_file($_FILES['imageFile']['tmp_name'], $target_file)) {
                $image_url = "https://modula-lms.com/uploads/courses/" . $unique_filename;
            } else {
                throw new Exception("Erreur lors du déplacement du fichier uploadé.");
            }
        } else {
            $encoded_title = urlencode($title);
            $hex_color = ltrim($color, '#');
            $image_url = "https://placehold.co/600x400/{$hex_color}/FFFFFF/png?text={$encoded_title}";
        }

        // --- CRÉATION DU PRODUIT ET DU PRIX SUR STRIPE ---
        // 1. On crée le produit sur Stripe
        $stripe_product = \Stripe\Product::create([
            'name' => $title,
            'description' => $description,
            'images' => [$image_url]
        ]);
        $stripe_product_id = $stripe_product->id;

        // 2. On crée le prix associé à ce produit
        $stripe_price = \Stripe\Price::create([
            'unit_amount' => (int)($price * 100), // Le prix en centimes
            'currency' => 'eur',
            'product' => $stripe_product_id,
        ]);
        $stripe_price_id = $stripe_price->id;


        // --- INSERTION DANS LA BASE DE DONNÉES ---
        // On insère le cours avec les ID Stripe
        $sql = "INSERT INTO courses (title, description, price, image_url, color, author, stripe_product_id, stripe_price_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("ssdsssss", $title, $description, $price, $image_url, $color, $author_name, $stripe_product_id, $stripe_price_id);
        $stmt->execute();
        $course_id = $conn->insert_id;
        $stmt->close();
        
        // On lie l'instructeur au cours.
        $link_sql = "INSERT INTO user_courses (user_id, course_id) VALUES (?, ?)";
        $link_stmt = $conn->prepare($link_sql);
        $link_stmt->bind_param("ii", $instructor_id, $course_id);
        $link_stmt->execute();
        $link_stmt->close();
        
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
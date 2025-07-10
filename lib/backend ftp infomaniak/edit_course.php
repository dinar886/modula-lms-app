<?php
// Fichier : /api/v1/edit_course.php

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// --- INCLUSIONS ---
require_once 'config.php';
require_once __DIR__ . '/vendor/autoload.php';

// Initialisation Stripe
\Stripe\Stripe::setApiKey($stripeSecretKey);

// --- CONNEXION BDD ---
$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["message" => "Erreur de connexion à la base de données: " . $conn->connect_error]);
    exit();
}
$conn->set_charset("utf8");

// --- TRAITEMENT ---
if (
    !empty($_POST['course_id']) &&
    !empty($_POST['title']) &&
    isset($_POST['description']) &&
    isset($_POST['price'])
) {
    $course_id = (int)$_POST['course_id'];
    $title = $conn->real_escape_string($_POST['title']);
    $description = $conn->real_escape_string($_POST['description']);
    $new_price = (float)$_POST['price'];

    // Étape 1 : Récupérer les infos actuelles du cours (image, couleur, prix, IDs Stripe)
    $stmt_select = $conn->prepare("SELECT image_url, color, price, stripe_product_id, stripe_price_id FROM courses WHERE id = ?");
    $stmt_select->bind_param("i", $course_id);
    $stmt_select->execute();
    $result = $stmt_select->get_result();
    $existing_course = $result->fetch_assoc();
    $stmt_select->close();

    if (!$existing_course) {
        http_response_code(404);
        echo json_encode(["message" => "Cours non trouvé."]);
        exit();
    }

    $image_url = $existing_course['image_url'];
    $color = !empty($_POST['color']) ? $conn->real_escape_string($_POST['color']) : $existing_course['color'];
    $current_price = (float)$existing_course['price'];
    $stripe_product_id = $existing_course['stripe_product_id'];
    $stripe_price_id = $existing_course['stripe_price_id'];
    
    $image_was_updated = false;

    // --- Gestion de l'image (identique à create_course.php) ---
    if (isset($_FILES['imageFile']) && $_FILES['imageFile']['error'] == UPLOAD_ERR_OK) {
        // ... (logique d'upload d'image inchangée)
        $upload_dir = $_SERVER['DOCUMENT_ROOT'] . '/uploads/courses/';
        if (!is_dir($upload_dir)) { mkdir($upload_dir, 0755, true); }
        $file_info = pathinfo($_FILES['imageFile']['name']);
        $file_ext = strtolower($file_info['extension']);
        $unique_filename = uniqid('course_', true) . '.' . $file_ext;
        $target_file = $upload_dir . $unique_filename;
        if (move_uploaded_file($_FILES['imageFile']['tmp_name'], $target_file)) {
            $image_url = "https://modula-lms.com/uploads/courses/" . $unique_filename;
            $image_was_updated = true;
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Erreur lors du déplacement du fichier uploadé."]);
            exit();
        }
    }
    if (!$image_was_updated) {
        if (empty($image_url) || strpos($image_url, 'placehold.co') !== false) {
             $encoded_title = urlencode($title);
             $hex_color = ltrim($color, '#');
             $image_url = "https://placehold.co/600x400/{$hex_color}/FFFFFF/png?text={$encoded_title}";
        }
    }

    // --- Synchronisation avec Stripe ---
    // Mettre à jour le produit sur Stripe
    if ($stripe_product_id) {
        \Stripe\Product::update($stripe_product_id, [
            'name' => $title,
            'description' => $description,
            'images' => [$image_url],
        ]);

        // Si le prix a changé, archiver l'ancien et en créer un nouveau
        if ($new_price != $current_price) {
            // Archiver l'ancien prix
            if ($stripe_price_id) {
                \Stripe\Price::update($stripe_price_id, ['active' => false]);
            }
            // Créer le nouveau prix
            $new_stripe_price = \Stripe\Price::create([
                'unit_amount' => (int)($new_price * 100),
                'currency' => 'eur',
                'product' => $stripe_product_id,
            ]);
            $stripe_price_id = $new_stripe_price->id;
        }
    }


    // --- Mise à jour de la base de données ---
    $sql = "UPDATE courses SET title = ?, description = ?, price = ?, image_url = ?, color = ?, stripe_price_id = ? WHERE id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ssdsssi", $title, $description, $new_price, $image_url, $color, $stripe_price_id, $course_id);

    if ($stmt->execute()) {
        http_response_code(200);
        echo json_encode([
            "message" => "Cours mis à jour avec succès.",
            "new_image_url" => $image_url
        ]);
    } else {
        http_response_code(500);
        echo json_encode(["message" => "Erreur lors de la mise à jour du cours: " . $stmt->error]);
    }
    $stmt->close();

} else {
    http_response_code(400);
    echo json_encode(["message" => "Données incomplètes.", "received" => $_POST, "files" => $_FILES]);
}

$conn->close();
?>
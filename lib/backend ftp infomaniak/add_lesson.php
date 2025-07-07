<?php
// Fichier : /api/v1/add_lesson.php

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once 'config.php';

$data = json_decode(file_get_contents("php://input"));

// On vérifie maintenant aussi le type de leçon.
if (
    !empty($data->title) &&
    !empty($data->section_id) &&
    !empty($data->lesson_type)
) {
    $conn = new mysqli($servername, $username, $password, $dbname);

    if ($conn->connect_error) {
        http_response_code(500);
        echo json_encode(["message" => "Erreur de connexion à la base de données."]);
        exit();
    }
    
    $conn->set_charset("utf8mb4");

    $title = $conn->real_escape_string($data->title);
    $section_id = (int)$data->section_id;
    // On récupère le type de leçon envoyé par Flutter
    $lesson_type = $conn->real_escape_string($data->lesson_type);
    // La date d'échéance est optionnelle, donc on utilise l'opérateur de coalescence nulle
    $due_date = isset($data->due_date) && !empty($data->due_date) ? $conn->real_escape_string($data->due_date) : null;

    // On vérifie que le type est valide pour éviter les erreurs.
    $allowed_types = ['text', 'devoir', 'evaluation'];
    if (!in_array($lesson_type, $allowed_types)) {
        http_response_code(400);
        echo json_encode(["message" => "Type de leçon non valide."]);
        exit();
    }

    $conn->begin_transaction();

    try {
        // Détermine le prochain 'order_index' pour la nouvelle leçon.
        $order_sql = "SELECT MAX(order_index) as max_order FROM lessons WHERE section_id = ?";
        $order_stmt = $conn->prepare($order_sql);
        $order_stmt->bind_param("i", $section_id);
        $order_stmt->execute();
        $result = $order_stmt->get_result();
        $row = $result->fetch_assoc();
        $next_order_index = ($row['max_order'] ?? 0) + 1;
        $order_stmt->close();

        // On insère la nouvelle leçon avec son type et sa date d'échéance (si elle existe).
        $sql = "INSERT INTO lessons (section_id, title, lesson_type, due_date, order_index) VALUES (?, ?, ?, ?, ?)";
        $stmt = $conn->prepare($sql);
        // 'ssssi' : string, string, string, string, integer
        $stmt->bind_param("isssi", $section_id, $title, $lesson_type, $due_date, $next_order_index);
        
        if (!$stmt->execute()) {
            throw new Exception("Erreur lors de l'insertion de la leçon: " . $stmt->error);
        }
        
        $stmt->close();
        $conn->commit();

        http_response_code(201); // Created
        echo json_encode(["message" => "Contenu créé avec succès."]);

    } catch (Exception $exception) {
        $conn->rollback();
        http_response_code(500);
        echo json_encode(["message" => "Erreur lors de la création.", "error" => $exception->getMessage()]);
    } finally {
        $conn->close();
    }

} else {
    http_response_code(400);
    echo json_encode(["message" => "Données incomplètes."]);
}
?>
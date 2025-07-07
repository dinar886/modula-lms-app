<?php
// Fichier : /api/v1/add_lesson.php

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once 'config.php';

$data = json_decode(file_get_contents("php://input"));

// Vérifie que les données nécessaires sont présentes.
// Le type de leçon n'est plus requis ici, on le force à 'text' par défaut.
if (
    !empty($data->title) &&
    !empty($data->section_id)
) {
    $conn = new mysqli($servername, $username, $password, $dbname);

    if ($conn->connect_error) {
        http_response_code(500);
        echo json_encode(["message" => "Erreur de connexion à la base de données."]);
        exit();
    }

    $conn->begin_transaction();

    try {
        $title = $conn->real_escape_string($data->title);
        $section_id = (int)$data->section_id;
        // MODIFICATION: On force le type à 'text', car la leçon est maintenant un conteneur générique.
        $lesson_type = 'text'; 

        // Détermine le prochain 'order_index' pour la nouvelle leçon.
        $order_sql = "SELECT MAX(order_index) as max_order FROM lessons WHERE section_id = ?";
        $order_stmt = $conn->prepare($order_sql);
        $order_stmt->bind_param("i", $section_id);
        $order_stmt->execute();
        $result = $order_stmt->get_result();
        $row = $result->fetch_assoc();
        $next_order_index = ($row['max_order'] ?? 0) + 1;
        $order_stmt->close();

        // On insère la nouvelle leçon dans la table 'lessons'.
        $sql = "INSERT INTO lessons (section_id, title, lesson_type, order_index) VALUES (?, ?, ?, ?)";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("issi", $section_id, $title, $lesson_type, $next_order_index);
        $stmt->execute();
        
        $stmt->close();

        // SUPPRESSION: La logique qui créait un quiz en même temps que la leçon a été retirée.
        
        $conn->commit();

        http_response_code(201); // Created
        echo json_encode(["message" => "Leçon créée avec succès."]);

    } catch (mysqli_sql_exception $exception) {
        $conn->rollback();
        
        http_response_code(500);
        echo json_encode(["message" => "Erreur lors de la création de la leçon.", "error" => $exception->getMessage()]);
    } finally {
        $conn->close();
    }

} else {
    http_response_code(400);
    echo json_encode(["message" => "Données incomplètes."]);
}
?>
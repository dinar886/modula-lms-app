<?php
// Fichier : /api/v1/add_lesson.php

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once 'config.php';

$data = json_decode(file_get_contents("php://input"));

// Vérifie que les données nécessaires sont présentes.
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

    // On démarre une "transaction". Cela garantit que soit TOUTES les requêtes réussissent,
    // soit aucune n'est appliquée. C'est plus sûr.
    $conn->begin_transaction();

    try {
        $title = $conn->real_escape_string($data->title);
        $section_id = (int)$data->section_id;
        $lesson_type = $conn->real_escape_string($data->lesson_type);

        // Détermine le prochain 'order_index' pour la nouvelle leçon.
        $order_sql = "SELECT MAX(order_index) as max_order FROM lessons WHERE section_id = ?";
        $order_stmt = $conn->prepare($order_sql);
        $order_stmt->bind_param("i", $section_id);
        $order_stmt->execute();
        $result = $order_stmt->get_result();
        $row = $result->fetch_assoc();
        $next_order_index = ($row['max_order'] ?? 0) + 1;
        $order_stmt->close();

        // Étape 1 : On insère la nouvelle leçon dans la table 'lessons'.
        $sql = "INSERT INTO lessons (section_id, title, lesson_type, order_index) VALUES (?, ?, ?, ?)";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("issi", $section_id, $title, $lesson_type, $next_order_index);
        $stmt->execute();
        
        // On récupère l'ID de la leçon que l'on vient de créer.
        $new_lesson_id = $conn->insert_id;
        $stmt->close();

        // **LA CORRECTION EST ICI**
        // Étape 2 : Si la leçon est de type 'quiz', on crée aussi une entrée dans la table 'quizzes'.
        if ($lesson_type === 'quiz') {
            // On crée un titre et une description par défaut pour le quiz.
            $quiz_title = "Quiz : " . $title;
            $quiz_description = "Testez vos connaissances sur la leçon '" . $title . "'.";
            
            $quiz_sql = "INSERT INTO quizzes (lesson_id, title, description) VALUES (?, ?, ?)";
            $quiz_stmt = $conn->prepare($quiz_sql);
            $quiz_stmt->bind_param("iss", $new_lesson_id, $quiz_title, $quiz_description);
            $quiz_stmt->execute();
            $quiz_stmt->close();
        }

        // Si tout s'est bien passé, on valide la transaction.
        $conn->commit();

        http_response_code(201); // Created
        echo json_encode(["message" => "Leçon créée avec succès."]);

    } catch (mysqli_sql_exception $exception) {
        // Si une erreur survient, on annule toutes les opérations.
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

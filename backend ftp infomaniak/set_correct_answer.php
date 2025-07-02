<?php
// Fichier : /api/v1/set_correct_answer.php
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once 'config.php';

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->question_id) && !empty($data->answer_id)) {
    $conn = new mysqli($servername, $username, $password, $dbname);
    if ($conn->connect_error) { die("Connection failed: " . $conn->connect_error); }

    $question_id = (int)$data->question_id;
    $correct_answer_id = (int)$data->answer_id;

    // Début de la transaction pour assurer la cohérence des données.
    $conn->begin_transaction();

    try {
        // 1. Met toutes les réponses pour cette question à 'is_correct = 0' (faux).
        $sql_reset = "UPDATE answers SET is_correct = 0 WHERE question_id = ?";
        $stmt_reset = $conn->prepare($sql_reset);
        $stmt_reset->bind_param("i", $question_id);
        $stmt_reset->execute();
        $stmt_reset->close();

        // 2. Met uniquement la réponse choisie à 'is_correct = 1' (vrai).
        $sql_set = "UPDATE answers SET is_correct = 1 WHERE id = ? AND question_id = ?";
        $stmt_set = $conn->prepare($sql_set);
        $stmt_set->bind_param("ii", $correct_answer_id, $question_id);
        $stmt_set->execute();
        $stmt_set->close();
        
        // Valide la transaction.
        $conn->commit();

        http_response_code(200);
        echo json_encode(["message" => "Bonne réponse définie."]);

    } catch (mysqli_sql_exception $exception) {
        // En cas d'erreur, annule la transaction.
        $conn->rollback();
        http_response_code(500);
        echo json_encode(["message" => "Erreur lors de la mise à jour."]);
    }

    $conn->close();
} else {
    http_response_code(400);
    echo json_encode(["message" => "Données incomplètes."]);
}
?>

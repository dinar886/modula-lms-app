<?php
// Fichier : /api/v1/save_quiz.php
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once 'config.php';

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->quiz_id) && isset($data->questions)) {
    $conn = new mysqli($servername, $username, $password, $dbname);
    if ($conn->connect_error) { die("Connection failed: " . $conn->connect_error); }

    $quiz_id = (int)$data->quiz_id;
    $questions = $data->questions;

    // Début de la transaction pour assurer la cohérence.
    $conn->begin_transaction();

    try {
        // 1. On supprime d'abord toutes les anciennes questions (et réponses en cascade) pour ce quiz.
        $sql_delete_questions = "DELETE FROM questions WHERE quiz_id = ?";
        $stmt_delete = $conn->prepare($sql_delete_questions);
        $stmt_delete->bind_param("i", $quiz_id);
        $stmt_delete->execute();
        $stmt_delete->close();

        // 2. On boucle sur les nouvelles questions pour les insérer.
        foreach ($questions as $question_index => $question) {
            $sql_insert_question = "INSERT INTO questions (quiz_id, question_text, order_index) VALUES (?, ?, ?)";
            $stmt_question = $conn->prepare($sql_insert_question);
            $stmt_question->bind_param("isi", $quiz_id, $question->question_text, $question_index);
            $stmt_question->execute();
            $new_question_id = $conn->insert_id; // On récupère l'ID de la nouvelle question.
            $stmt_question->close();

            // 3. On boucle sur les réponses de cette question pour les insérer.
            foreach ($question->answers as $answer) {
                $is_correct = (int)$answer->is_correct;
                $sql_insert_answer = "INSERT INTO answers (question_id, answer_text, is_correct) VALUES (?, ?, ?)";
                $stmt_answer = $conn->prepare($sql_insert_answer);
                $stmt_answer->bind_param("isi", $new_question_id, $answer->answer_text, $is_correct);
                $stmt_answer->execute();
                $stmt_answer->close();
            }
        }

        // Si tout s'est bien passé, on valide la transaction.
        $conn->commit();
        http_response_code(200);
        echo json_encode(["message" => "Quiz sauvegardé avec succès."]);

    } catch (mysqli_sql_exception $exception) {
        // En cas d'erreur, on annule tout.
        $conn->rollback();
        http_response_code(500);
        echo json_encode(["message" => "Erreur lors de la sauvegarde du quiz.", "error" => $exception->getMessage()]);
    }

    $conn->close();
} else {
    http_response_code(400);
    echo json_encode(["message" => "Données du quiz incomplètes."]);
}
?>

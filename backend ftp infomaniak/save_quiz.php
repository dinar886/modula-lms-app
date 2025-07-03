<?php
// Fichier : /api/v1/save_quiz.php
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once 'config.php';

// On récupère le corps de la requête qui contient notre objet Quiz en JSON.
$data = json_decode(file_get_contents("php://input"));

// On vérifie que les données essentielles (ID du quiz et la liste des questions) sont présentes.
if (!empty($data->id) && isset($data->questions)) {
    $conn = new mysqli($servername, $username, $password, $dbname);
    if ($conn->connect_error) {
        http_response_code(500);
        echo json_encode(["message" => "Connection failed: " . $conn->connect_error]);
        exit();
    }

    // Récupération et nettoyage des données.
    $quiz_id = (int)$data->id;
    $quiz_title = $conn->real_escape_string($data->title);
    $quiz_description = $conn->real_escape_string($data->description);
    $questions = $data->questions;

    // --- DEBUT DE LA TRANSACTION ---
    // Une transaction assure que toutes les opérations (DELETE, INSERTs)
    // réussissent ensemble. Si une seule échoue, tout est annulé (rollback).
    // C'est crucial pour la cohérence des données.
    $conn->begin_transaction();

    try {
        // Étape 1: Mettre à jour le titre et la description du quiz lui-même.
        $sql_update_quiz = "UPDATE quizzes SET title = ?, description = ? WHERE id = ?";
        $stmt_update_quiz = $conn->prepare($sql_update_quiz);
        $stmt_update_quiz->bind_param("ssi", $quiz_title, $quiz_description, $quiz_id);
        $stmt_update_quiz->execute();
        $stmt_update_quiz->close();


        // Étape 2: Récupérer les IDs de toutes les anciennes questions liées à ce quiz.
        $sql_get_old_questions = "SELECT id FROM questions WHERE quiz_id = ?";
        $stmt_get_old = $conn->prepare($sql_get_old_questions);
        $stmt_get_old->bind_param("i", $quiz_id);
        $stmt_get_old->execute();
        $result_old = $stmt_get_old->get_result();
        $old_question_ids = [];
        while($row = $result_old->fetch_assoc()){
            $old_question_ids[] = $row['id'];
        }
        $stmt_get_old->close();
        
        // Étape 3: Si des anciennes questions existent, supprimer leurs réponses associées.
        if (!empty($old_question_ids)) {
             $id_list = implode(',', $old_question_ids); // Crée une chaine "1,2,3"
             $conn->query("DELETE FROM answers WHERE question_id IN ($id_list)");
        }
        
        // Étape 4: Supprimer toutes les anciennes questions du quiz.
        $sql_delete_questions = "DELETE FROM questions WHERE quiz_id = ?";
        $stmt_delete = $conn->prepare($sql_delete_questions);
        $stmt_delete->bind_param("i", $quiz_id);
        $stmt_delete->execute();
        $stmt_delete->close();


        // Étape 5: Boucler sur les nouvelles questions reçues pour les insérer.
        foreach ($questions as $question_index => $question) {
            $sql_insert_question = "INSERT INTO questions (quiz_id, question_text, order_index) VALUES (?, ?, ?)";
            $stmt_question = $conn->prepare($sql_insert_question);
            // On s'assure que le texte est bien une chaine.
            $question_text = is_string($question->question_text) ? $question->question_text : '';
            $stmt_question->bind_param("isi", $quiz_id, $question_text, $question_index);
            $stmt_question->execute();
            $new_question_id = $conn->insert_id; // On récupère l'ID de la question juste insérée.
            $stmt_question->close();

            // Étape 6: Boucler sur les réponses de cette question pour les insérer.
            if (isset($question->answers) && is_array($question->answers)) {
                foreach ($question->answers as $answer) {
                    $is_correct = isset($answer->is_correct) ? (int)$answer->is_correct : 0;
                    $answer_text = is_string($answer->answer_text) ? $answer->answer_text : '';
                    
                    $sql_insert_answer = "INSERT INTO answers (question_id, answer_text, is_correct) VALUES (?, ?, ?)";
                    $stmt_answer = $conn->prepare($sql_insert_answer);
                    $stmt_answer->bind_param("isi", $new_question_id, $answer_text, $is_correct);
                    $stmt_answer->execute();
                    $stmt_answer->close();
                }
            }
        }

        // --- COMMIT ---
        // Si toutes les opérations ci-dessus ont réussi, on valide la transaction.
        // Les changements sont maintenant permanents dans la base de données.
        $conn->commit();
        http_response_code(200);
        echo json_encode(["message" => "Quiz sauvegardé avec succès."]);

    } catch (mysqli_sql_exception $exception) {
        // --- ROLLBACK ---
        // Si une erreur est survenue à n'importe quelle étape, on annule TOUT.
        $conn->rollback();
        http_response_code(500);
        echo json_encode(["message" => "Erreur lors de la sauvegarde du quiz.", "error" => $exception->getMessage()]);
    }

    $conn->close();
} else {
    // Si les données envoyées ne sont pas valides.
    http_response_code(400);
    echo json_encode(["message" => "Données du quiz incomplètes ou invalides."]);
}
?>

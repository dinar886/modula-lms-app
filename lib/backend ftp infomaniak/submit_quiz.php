<?php
/**
 * Fichier : /api/v1/submit_quiz.php
 * Description : Gère la soumission d'un quiz, calcule le score, et enregistre la tentative complète.
 * Version : 4.0 (Gère les QCM et les Textes à trous)
 */

// --- En-têtes HTTP ---
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// --- Dépendances ---
require_once 'config.php';

// --- Logique du script ---

// 1. Récupération et validation des données d'entrée
$raw_data = file_get_contents("php://input");
$data = json_decode($raw_data, true);

if (
    $data === null || !is_array($data) ||
    !isset($data['student_id']) || !isset($data['quiz_id']) ||
    !isset($data['lesson_id']) || !isset($data['answers']) ||
    !is_array($data['answers'])
) {
    http_response_code(400);
    echo json_encode([
        "message" => "Données invalides ou incomplètes.",
        "error_details" => "Assurez-vous que student_id, quiz_id, lesson_id et un tableau 'answers' sont fournis.",
        "received_data" => $raw_data
    ]);
    exit();
}

// 2. Assignation des variables
$student_id = (int)$data['student_id'];
$quiz_id = (int)$data['quiz_id'];
$lesson_id = (int)$data['lesson_id'];
$user_answers = $data['answers']; // Tableau associatif [question_id => answer_id ou answer_text]

// 3. Connexion à la base de données
$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["message" => "Erreur de connexion BDD: " . $conn->connect_error]);
    exit();
}
$conn->set_charset("utf8mb4");
$conn->begin_transaction(); // Démarrage de la transaction

try {
    // 4. Calcul du score et récupération des détails
    $questions_details = []; // Pour stocker les détails de chaque question
    $sql_questions = "SELECT id, question_type, correct_text_answer, (SELECT id FROM answers WHERE question_id = questions.id AND is_correct = 1 LIMIT 1) as correct_answer_id FROM questions WHERE quiz_id = ?";
    $stmt_questions = $conn->prepare($sql_questions);
    $stmt_questions->bind_param("i", $quiz_id);
    $stmt_questions->execute();
    $result_questions = $stmt_questions->get_result();

    $total_questions = $result_questions->num_rows;
    $correct_answers_count = 0;

    if ($total_questions > 0) {
        while ($question = $result_questions->fetch_assoc()) {
            $questions_details[$question['id']] = $question;
        }

        foreach ($user_answers as $question_id => $user_answer) {
            if (!isset($questions_details[$question_id])) continue;

            $question_detail = $questions_details[$question_id];
            $is_correct = false;

            if ($question_detail['question_type'] === 'mcq') {
                if ($user_answer == $question_detail['correct_answer_id']) {
                    $is_correct = true;
                }
            } elseif ($question_detail['question_type'] === 'fill_in_the_blank') {
                // Comparaison insensible à la casse et sans espaces superflus
                if (strtolower(trim($user_answer)) === strtolower(trim($question_detail['correct_text_answer']))) {
                    $is_correct = true;
                }
            }

            if ($is_correct) {
                $correct_answers_count++;
            }
        }
    }
    $stmt_questions->close();

    // Calcul du score sur 20
    $score = ($total_questions > 0) ? ($correct_answers_count / $total_questions) * 20 : 0;

    // 5. Enregistrement de la tentative dans `quiz_attempts`
    $sql_insert_attempt = "INSERT INTO quiz_attempts (student_id, quiz_id, lesson_id, score, total_questions, correct_answers) VALUES (?, ?, ?, ?, ?, ?)";
    $stmt_insert = $conn->prepare($sql_insert_attempt);
    $stmt_insert->bind_param("iiidii", $student_id, $quiz_id, $lesson_id, $score, $total_questions, $correct_answers_count);
    $stmt_insert->execute();
    $attempt_id = $conn->insert_id;
    $stmt_insert->close();

    // 6. Enregistrement de chaque réponse dans `quiz_attempt_answers`
    $sql_insert_answer = "INSERT INTO quiz_attempt_answers (quiz_attempt_id, question_id, selected_answer_id, selected_text_answer, is_correct) VALUES (?, ?, ?, ?, ?)";
    $stmt_answer = $conn->prepare($sql_insert_answer);
    foreach ($user_answers as $question_id => $user_answer) {
        if (!isset($questions_details[$question_id])) continue;
        
        $question_detail = $questions_details[$question_id];
        $selected_answer_id = null;
        $selected_text_answer = null;
        $is_answer_correct = false;

        if ($question_detail['question_type'] === 'mcq') {
            $selected_answer_id = (int)$user_answer;
            if ($selected_answer_id == $question_detail['correct_answer_id']) {
                $is_answer_correct = true;
            }
        } elseif ($question_detail['question_type'] === 'fill_in_the_blank') {
            $selected_text_answer = (string)$user_answer;
             if (strtolower(trim($selected_text_answer)) === strtolower(trim($question_detail['correct_text_answer']))) {
                $is_answer_correct = true;
            }
        }
        
        $stmt_answer->bind_param("iiisi", $attempt_id, $question_id, $selected_answer_id, $selected_text_answer, $is_answer_correct);
        $stmt_answer->execute();
    }
    $stmt_answer->close();


    // 7. Validation de la transaction
    $conn->commit();

    // 8. Envoi de la réponse de succès
    http_response_code(200);
    echo json_encode([
        "message" => "Quiz soumis avec succès.",
        "score" => $score,
        "correct_answers" => $correct_answers_count,
        "total_questions" => $total_questions
    ]);

} catch (Exception $e) {
    $conn->rollback(); // Annulation en cas d'erreur
    http_response_code(500);
    echo json_encode([
        "message" => "Une erreur interne est survenue lors du traitement du quiz.",
        "error" => $e->getMessage()
    ]);
}

$conn->close();
?>
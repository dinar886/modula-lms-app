<?php
// Fichier : /api/v1/save_quiz.php
// Version améliorée qui gère la CRÉATION et la MISE À JOUR d'un quiz.

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once 'config.php';

$data = json_decode(file_get_contents("php://input"));

// On vérifie seulement la présence du titre et des questions.
if (!isset($data->title) || !isset($data->questions)) {
    http_response_code(400);
    echo json_encode(["message" => "Données du quiz incomplètes."]);
    exit();
}

$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["message" => "Échec de la connexion : " . $conn->connect_error]);
    exit();
}
$conn->set_charset("utf8mb4");

// On récupère les données. L'ID peut être 0 si c'est un nouveau quiz.
$quiz_id = isset($data->id) ? (int)$data->id : 0;
$title = $conn->real_escape_string($data->title);
$description = isset($data->description) ? $conn->real_escape_string($data->description) : '';
$questions = $data->questions;

$conn->begin_transaction();

try {
    // **Partie 1: Création ou Mise à jour de l'entité Quiz**
    if ($quiz_id === 0) {
        // C'est un nouveau quiz. On l'insère dans la table 'quizzes'.
        // NOTE: Ce script suppose une table `quizzes`. Si vos quiz sont dans la table `lessons`,
        // il faudra adapter cette requête.
        $sql_quiz = "INSERT INTO quizzes (title, description) VALUES (?, ?)";
        $stmt_quiz = $conn->prepare($sql_quiz);
        $stmt_quiz->bind_param("ss", $title, $description);
        $stmt_quiz->execute();
        $quiz_id = $conn->insert_id; // On récupère l'ID du quiz qu'on vient de créer.
        $stmt_quiz->close();
    } else {
        // C'est une mise à jour. On met à jour le titre et la description.
        $sql_quiz = "UPDATE quizzes SET title = ?, description = ? WHERE id = ?";
        $stmt_quiz = $conn->prepare($sql_quiz);
        $stmt_quiz->bind_param("ssi", $title, $description, $quiz_id);
        $stmt_quiz->execute();
        $stmt_quiz->close();
    }

    // **Partie 2: Synchronisation des Questions et Réponses**
    // La méthode la plus simple et la plus sûre est de tout supprimer puis tout réinsérer.
    // On s'assure que le quiz est dans un état propre, correspondant exactement à ce qui a été envoyé.

    // On supprime d'abord les anciennes réponses liées aux questions de ce quiz.
    $conn->query("DELETE answers FROM answers JOIN questions ON answers.question_id = questions.id WHERE questions.quiz_id = $quiz_id");

    // Ensuite, on supprime les anciennes questions elles-mêmes.
    $conn->query("DELETE FROM questions WHERE quiz_id = $quiz_id");

    // Maintenant, on insère les nouvelles questions et réponses.
    if (is_array($questions)) {
        foreach ($questions as $question_index => $question) {
            $question_text = $conn->real_escape_string($question->question_text);
            
            $sql_insert_question = "INSERT INTO questions (quiz_id, question_text, order_index) VALUES (?, ?, ?)";
            $stmt_question = $conn->prepare($sql_insert_question);
            $stmt_question->bind_param("isi", $quiz_id, $question_text, $question_index);
            $stmt_question->execute();
            $new_question_id = $conn->insert_id;
            $stmt_question->close();

            if (isset($question->answers) && is_array($question->answers)) {
                foreach ($question->answers as $answer) {
                    $answer_text = $conn->real_escape_string($answer->answer_text);
                    $is_correct = (isset($answer->is_correct) && $answer->is_correct) ? 1 : 0;

                    $sql_insert_answer = "INSERT INTO answers (question_id, answer_text, is_correct) VALUES (?, ?, ?)";
                    $stmt_answer = $conn->prepare($sql_insert_answer);
                    $stmt_answer->bind_param("isi", $new_question_id, $answer_text, $is_correct);
                    $stmt_answer->execute();
                    $stmt_answer->close();
                }
            }
        }
    }

    // Si tout s'est bien passé, on valide la transaction.
    $conn->commit();
    
    // **TRÈS IMPORTANT** : On renvoie l'ID du quiz, qu'il soit nouveau ou mis à jour.
    // L'application Flutter en a besoin pour mettre à jour le contenu du bloc.
    http_response_code(200);
    echo json_encode([
        "message" => "Quiz sauvegardé avec succès.",
        "quiz_id" => $quiz_id
    ]);

} catch (mysqli_sql_exception $exception) {
    // En cas d'erreur, on annule toutes les opérations.
    $conn->rollback();
    http_response_code(500);
    echo json_encode([
        "message" => "Erreur lors de la sauvegarde du quiz.",
        "error" => $exception->getMessage()
    ]);
}

$conn->close();
?>
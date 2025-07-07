<?php
// Fichier : /api/v1/get_quiz_details.php

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");

require_once 'config.php';

$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) { die("Connection failed: " . $conn->connect_error); }
$conn->set_charset("utf8mb4");

$quiz_id = 0;

// --- NOUVELLE LOGIQUE FLEXIBLE ---
// Le script vérifie s'il reçoit un quiz_id ou un lesson_id.

if (isset($_GET['quiz_id']) && !empty($_GET['quiz_id'])) {
    // CAS 1: L'instructeur modifie le quiz, on a directement le quiz_id.
    $quiz_id = (int)$_GET['quiz_id'];
} 
elseif (isset($_GET['lesson_id']) && !empty($_GET['lesson_id'])) {
    // CAS 2: L'étudiant visionne la leçon, on doit trouver le quiz_id.
    $lesson_id = (int)$_GET['lesson_id'];
    
    // On cherche dans les blocs de contenu le premier bloc de type 'quiz' pour cette leçon.
    $stmt_find = $conn->prepare("SELECT content FROM lesson_content_blocks WHERE lesson_id = ? AND block_type = 'quiz' LIMIT 1");
    $stmt_find->bind_param("i", $lesson_id);
    $stmt_find->execute();
    $result_find = $stmt_find->get_result();

    if ($result_find->num_rows > 0) {
        $row = $result_find->fetch_assoc();
        // Le contenu du bloc est l'ID du quiz.
        $quiz_id = (int)$row['content'];
    }
    $stmt_find->close();
}

// Si après toutes les vérifications, on n'a pas pu trouver un quiz_id valide.
if ($quiz_id === 0) {
    http_response_code(404);
    echo json_encode(["error" => "Aucun quiz trouvé pour l'identifiant fourni."]);
    $conn->close();
    exit();
}

// --- Le reste du script est identique et utilise le $quiz_id trouvé ---

$quiz_data = [];

$sql_quiz = "SELECT id, title, description FROM quizzes WHERE id = ? LIMIT 1";
$stmt_quiz = $conn->prepare($sql_quiz);
$stmt_quiz->bind_param("i", $quiz_id);
$stmt_quiz->execute();
$result_quiz = $stmt_quiz->get_result();

if ($result_quiz->num_rows > 0) {
    $quiz_row = $result_quiz->fetch_assoc();
    
    $quiz_data = [
        'id' => (int)$quiz_row['id'],
        'title' => $quiz_row['title'],
        'description' => $quiz_row['description'],
        'questions' => []
    ];

    $sql_questions = "SELECT id, question_text FROM questions WHERE quiz_id = ? ORDER BY order_index ASC";
    $stmt_questions = $conn->prepare($sql_questions);
    $stmt_questions->bind_param("i", $quiz_id);
    $stmt_questions->execute();
    $result_questions = $stmt_questions->get_result();

    if ($result_questions->num_rows > 0) {
        while ($question_row = $result_questions->fetch_assoc()) {
            $question_id = $question_row['id'];
            
            $question_data = [
                'id' => (int)$question_id,
                'question_text' => $question_row['question_text'],
                'answers' => []
            ];

            $sql_answers = "SELECT id, answer_text, is_correct FROM answers WHERE question_id = ?";
            $stmt_answers = $conn->prepare($sql_answers);
            $stmt_answers->bind_param("i", $question_id);
            $stmt_answers->execute();
            $result_answers = $stmt_answers->get_result();

            if ($result_answers->num_rows > 0) {
                while ($answer_row = $result_answers->fetch_assoc()) {
                    $answer_row['id'] = (int)$answer_row['id'];
                    $answer_row['is_correct'] = (bool)$answer_row['is_correct'];
                    $question_data['answers'][] = $answer_row;
                }
            }
            $stmt_answers->close();
            
            $quiz_data['questions'][] = $question_data;
        }
    }
    $stmt_questions->close();

    http_response_code(200);
    echo json_encode($quiz_data);

} else {
    http_response_code(404);
    echo json_encode(["error" => "Aucun quiz trouvé avec l'ID " . $quiz_id]);
}

$stmt_quiz->close();
$conn->close();

?>
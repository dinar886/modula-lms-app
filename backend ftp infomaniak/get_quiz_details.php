<?php
// Fichier : /api/v1/get_quiz_details.php

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");

require_once 'config.php';

// Le script prend l'ID de la *leçon* en paramètre.
if (!isset($_GET['lesson_id']) || empty($_GET['lesson_id'])) {
    http_response_code(400);
    echo json_encode(["error" => "L'ID de la leçon est manquant."]);
    exit();
}
$lesson_id = $_GET['lesson_id'];

$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) { die("Connection failed: " . $conn->connect_error); }

// Structure de la réponse finale
$quiz_data = [];

// 1. Trouver le quiz lié à cette leçon
$sql_quiz = "SELECT id, title, description FROM quizzes WHERE lesson_id = ? LIMIT 1";
$stmt_quiz = $conn->prepare($sql_quiz);
$stmt_quiz->bind_param("i", $lesson_id);
$stmt_quiz->execute();
$result_quiz = $stmt_quiz->get_result();

if ($result_quiz->num_rows > 0) {
    $quiz_row = $result_quiz->fetch_assoc();
    $quiz_id = $quiz_row['id'];
    
    $quiz_data = [
        'id' => $quiz_id,
        'title' => $quiz_row['title'],
        'description' => $quiz_row['description'],
        'questions' => []
    ];

    // 2. Récupérer toutes les questions pour ce quiz
    $sql_questions = "SELECT id, question_text FROM questions WHERE quiz_id = ? ORDER BY order_index ASC";
    $stmt_questions = $conn->prepare($sql_questions);
    $stmt_questions->bind_param("i", $quiz_id);
    $stmt_questions->execute();
    $result_questions = $stmt_questions->get_result();

    if ($result_questions->num_rows > 0) {
        while ($question_row = $result_questions->fetch_assoc()) {
            $question_id = $question_row['id'];
            
            $question_data = [
                'id' => $question_id,
                'question_text' => $question_row['question_text'],
                'answers' => []
            ];

            // 3. Pour chaque question, récupérer ses réponses
            // IMPORTANT: Dans une vraie application, on ne renverrait JAMAIS la colonne 'is_correct'.
            // L'application enverrait les réponses choisies à un autre script pour la correction.
            // Pour simplifier, nous l'envoyons ici, mais c'est une faille de sécurité.
            $sql_answers = "SELECT id, answer_text, is_correct FROM answers WHERE question_id = ?";
            $stmt_answers = $conn->prepare($sql_answers);
            $stmt_answers->bind_param("i", $question_id);
            $stmt_answers->execute();
            $result_answers = $stmt_answers->get_result();

            if ($result_answers->num_rows > 0) {
                while ($answer_row = $result_answers->fetch_assoc()) {
                    // On convertit is_correct en un vrai booléen
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
    echo json_encode(["error" => "Aucun quiz trouvé pour cette leçon."]);
}

$stmt_quiz->close();
$conn->close();

?>

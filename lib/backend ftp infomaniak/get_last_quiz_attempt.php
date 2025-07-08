<?php
// Fichier: /api/v1/get_last_quiz_attempt.php
// Description: Récupère la dernière tentative d'un étudiant pour un quiz donné, avec le détail des réponses.

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");

require_once 'config.php';

// Validation des paramètres
if (!isset($_GET['student_id']) || !isset($_GET['quiz_id'])) {
    http_response_code(400);
    echo json_encode(["error" => "Les ID étudiant et quiz sont requis."]);
    exit();
}

$student_id = (int)$_GET['student_id'];
$quiz_id = (int)$_GET['quiz_id'];

$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["message" => "Erreur de connexion BDD."]);
    exit();
}
$conn->set_charset("utf8mb4");

$response = null;

// 1. Trouver la dernière tentative
$sql_last_attempt = "SELECT id, score, total_questions, correct_answers, attempt_date 
                     FROM quiz_attempts 
                     WHERE student_id = ? AND quiz_id = ? 
                     ORDER BY attempt_date DESC 
                     LIMIT 1";

$stmt = $conn->prepare($sql_last_attempt);
$stmt->bind_param("ii", $student_id, $quiz_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $attempt_row = $result->fetch_assoc();
    $attempt_id = $attempt_row['id'];

    $response = [
        'attempt_id' => (int)$attempt_id,
        'score' => (float)$attempt_row['score'],
        'total_questions' => (int)$attempt_row['total_questions'],
        'correct_answers' => (int)$attempt_row['correct_answers'],
        'attempt_date' => $attempt_row['attempt_date'],
        'answers' => []
    ];

    // 2. Récupérer les réponses associées à cette tentative
    $sql_answers = "SELECT question_id, selected_answer_id, is_correct 
                    FROM quiz_attempt_answers 
                    WHERE quiz_attempt_id = ?";
    
    $stmt_answers = $conn->prepare($sql_answers);
    $stmt_answers->bind_param("i", $attempt_id);
    $stmt_answers->execute();
    $result_answers = $stmt_answers->get_result();

    while ($answer_row = $result_answers->fetch_assoc()) {
        $response['answers'][] = [
            'question_id' => (int)$answer_row['question_id'],
            'selected_answer_id' => (int)$answer_row['selected_answer_id'],
            'is_correct' => (bool)$answer_row['is_correct']
        ];
    }
    $stmt_answers->close();
}

$stmt->close();
$conn->close();

http_response_code(200);
// Si aucune tentative n'est trouvée, la réponse sera `null`, ce qui est géré côté Flutter.
echo json_encode($response);
?>
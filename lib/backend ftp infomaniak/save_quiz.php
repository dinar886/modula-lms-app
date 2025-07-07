<?php
// Fichier : /api/v1/save_quiz.php

// --- Configuration des logs et des en-têtes ---
ini_set('log_errors', 1);
// Crée un fichier de log dans le même dossier que le script.
ini_set('error_log', __DIR__ . '/error_log.txt'); 

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// --- Inclusion et connexion à la BDD ---
require_once 'config.php';
$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    error_log("DB Connection failed: " . $conn->connect_error);
    http_response_code(500);
    echo json_encode(["message" => "Échec de la connexion à la base de données."]);
    exit();
}
$conn->set_charset("utf8mb4");

// --- Récupération des données ---
$input = file_get_contents("php://input");
$data = json_decode($input);

// --- Validation des données ---
if (json_last_error() !== JSON_ERROR_NONE) {
    error_log("Invalid JSON received: " . json_last_error_msg());
    http_response_code(400);
    echo json_encode(["message" => "JSON mal formé."]);
    exit();
}

if (!isset($data->title) || !isset($data->questions) || !is_array($data->questions)) {
    error_log("Incomplete data received: " . $input);
    http_response_code(400);
    echo json_encode(["message" => "Données manquantes : le titre et les questions sont requis."]);
    exit();
}

// --- Démarrage de la transaction ---
$conn->begin_transaction();

try {
    // --- Étape 1 : Créer ou mettre à jour le quiz ---
    $quiz_id = isset($data->id) && (int)$data->id > 0 ? (int)$data->id : 0;
    $title = $conn->real_escape_string($data->title);
    $description = isset($data->description) ? $conn->real_escape_string($data->description) : '';

    if ($quiz_id === 0) {
        $stmt = $conn->prepare("INSERT INTO quizzes (title, description) VALUES (?, ?)");
        $stmt->bind_param("ss", $title, $description);
        $stmt->execute();
        $quiz_id = $conn->insert_id;
        $stmt->close();
    } else {
        $stmt = $conn->prepare("UPDATE quizzes SET title = ?, description = ? WHERE id = ?");
        $stmt->bind_param("ssi", $title, $description, $quiz_id);
        $stmt->execute();
        $stmt->close();
    }

    // --- Étape 2 : Supprimer les anciennes questions (les réponses sont supprimées en cascade grâce à ON DELETE CASCADE) ---
    $stmt = $conn->prepare("DELETE FROM questions WHERE quiz_id = ?");
    $stmt->bind_param("i", $quiz_id);
    $stmt->execute();
    $stmt->close();
    
    // --- Étape 3 : Insérer les nouvelles questions et réponses ---
    foreach ($data->questions as $q_index => $question) {
        $question_text = $conn->real_escape_string($question->question_text);
        
        $stmt_q = $conn->prepare("INSERT INTO questions (quiz_id, question_text, order_index) VALUES (?, ?, ?)");
        $stmt_q->bind_param("isi", $quiz_id, $question_text, $q_index);
        $stmt_q->execute();
        $new_question_id = $conn->insert_id;
        $stmt_q->close();

        if (isset($question->answers) && is_array($question->answers)) {
            foreach ($question->answers as $answer) {
                $answer_text = $conn->real_escape_string($answer->answer_text);
                $is_correct = (isset($answer->is_correct) && $answer->is_correct) ? 1 : 0;
                
                $stmt_a = $conn->prepare("INSERT INTO answers (question_id, answer_text, is_correct) VALUES (?, ?, ?)");
                $stmt_a->bind_param("isi", $new_question_id, $answer_text, $is_correct);
                $stmt_a->execute();
                $stmt_a->close();
            }
        }
    }

    // --- Validation finale ---
    $conn->commit();
    
    http_response_code(200);
    echo json_encode(["message" => "Quiz sauvegardé avec succès.", "quiz_id" => $quiz_id]);

} catch (Exception $e) {
    // --- En cas d'erreur, on annule tout et on logue l'erreur précise ---
    $conn->rollback();
    // Logue l'erreur dans le fichier error_log.txt
    error_log("Transaction failed: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        "message" => "Une erreur serveur est survenue lors de la sauvegarde.",
        "error" => $e->getMessage()
    ]);
}

$conn->close();
?>
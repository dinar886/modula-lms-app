<?php
/**
 * Fichier : /api/v1/submit_quiz.php
 * Description : Gère la soumission d'un quiz par un étudiant, calcule le score et l'enregistre.
 * Version : 2.0 (Avec validation et débogage améliorés)
 */

// --- En-têtes HTTP ---
// Permet de spécifier que la réponse est au format JSON et d'autoriser les requêtes cross-origine.
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// --- Dépendances ---
require_once 'config.php';

// --- Logique du script ---

// 1. Récupération et validation des données d'entrée
// On récupère le corps brut de la requête pour pouvoir le renvoyer en cas d'erreur de décodage.
$raw_data = file_get_contents("php://input");
// On décode la chaîne JSON en tableau associatif PHP.
$data = json_decode($raw_data, true);

// On vérifie que le décodage a réussi et que tous les champs requis sont présents et du bon type.
if (
    $data === null || !is_array($data) ||
    !isset($data['student_id']) ||
    !isset($data['quiz_id']) ||
    !isset($data['lesson_id']) ||
    !isset($data['answers']) ||
    !is_array($data['answers']) // On s'assure que 'answers' est bien un tableau.
) {
    http_response_code(400); // Bad Request
    // On renvoie un message d'erreur détaillé pour faciliter le débogage côté client.
    echo json_encode([
        "message" => "Données invalides ou incomplètes.",
        "error_details" => "Assurez-vous que student_id, quiz_id, lesson_id et un tableau 'answers' sont fournis.",
        "received_data" => $raw_data // Renvoyer les données brutes peut aider à voir ce que le serveur a reçu.
    ]);
    exit();
}

// 2. Assignation des variables
// On convertit les IDs en entiers pour plus de sécurité.
$student_id = (int)$data['student_id'];
$quiz_id = (int)$data['quiz_id'];
$lesson_id = (int)$data['lesson_id'];
$user_answers = $data['answers'];

// 3. Connexion à la base de données
$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500); // Internal Server Error
    echo json_encode(["message" => "Erreur de connexion à la base de données: " . $conn->connect_error]);
    exit();
}
$conn->set_charset("utf8mb4");

try {
    // 4. Calcul du score
    $total_questions = 0;
    $correct_answers_count = 0;
    
    // On récupère l'ID de la bonne réponse pour chaque question du quiz.
    $sql_questions = "SELECT id, (SELECT id FROM answers WHERE question_id = questions.id AND is_correct = 1 LIMIT 1) as correct_answer_id FROM questions WHERE quiz_id = ?";
    $stmt_questions = $conn->prepare($sql_questions);
    $stmt_questions->bind_param("i", $quiz_id);
    $stmt_questions->execute();
    $result_questions = $stmt_questions->get_result();
    
    $total_questions = $result_questions->num_rows;

    if ($total_questions > 0) {
        // On compare les réponses de l'utilisateur avec les bonnes réponses.
        while ($question = $result_questions->fetch_assoc()) {
            $question_id = $question['id']; // L'ID de la question est un entier.
            $correct_answer_id = $question['correct_answer_id'];
            
            // PHP gère nativement les clés de tableau qui sont des chaînes de caractères numériques.
            if (isset($user_answers[$question_id]) && $user_answers[$question_id] == $correct_answer_id) {
                $correct_answers_count++;
            }
        }
    }
    $stmt_questions->close();

    // On calcule le score en pourcentage.
    $score = ($total_questions > 0) ? ($correct_answers_count / $total_questions) * 100 : 0;

    // 5. Enregistrement de la tentative dans la base de données.
    $sql_insert_attempt = "INSERT INTO quiz_attempts (student_id, quiz_id, lesson_id, score) VALUES (?, ?, ?, ?)";
    $stmt_insert = $conn->prepare($sql_insert_attempt);
    // 'd' pour double (le type du score).
    $stmt_insert->bind_param("iiid", $student_id, $quiz_id, $lesson_id, $score);
    $stmt_insert->execute();
    $stmt_insert->close();

    // 6. Envoi de la réponse de succès
    http_response_code(200); // OK
    echo json_encode([
        "message" => "Quiz soumis avec succès.",
        "score" => $score,
        "correct_answers" => $correct_answers_count,
        "total_questions" => $total_questions
    ]);

} catch (Exception $e) {
    http_response_code(500); // Internal Server Error
    echo json_encode([
        "message" => "Une erreur interne est survenue lors du traitement du quiz.",
        "error" => $e->getMessage()
    ]);
}

$conn->close();
?>
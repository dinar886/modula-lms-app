<?php
// Fichier : /api/v1/get_submission_details.php
// Description : Version finale corrigée.

// --- CONFIGURATION DE LA GESTION D'ERREURS ---
ini_set('display_errors', 0);
error_reporting(E_ALL);

set_error_handler(function($severity, $message, $file, $line) {
    if (!(error_reporting() & $severity)) {
        return;
    }
    throw new ErrorException($message, 0, $severity, $file, $line);
});


// --- EN-TÊTES HTTP ---
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");

// --- BLOC TRY-CATCH PRINCIPAL ---
try {
    require_once 'config.php';

    // 1. Validation de l'input
    if (!isset($_GET['submission_id'])) {
        http_response_code(400);
        echo json_encode(["success" => false, "error" => "L'ID du rendu est manquant."]);
        exit();
    }
    $submission_id = (int)$_GET['submission_id'];

    // 2. Connexion à la base de données
    $conn = new mysqli($servername, $username, $password, $dbname);
    if ($conn->connect_error) {
        throw new Exception("Erreur de connexion à la base de données: " . $conn->connect_error);
    }
    $conn->set_charset("utf8mb4");

    // 3. REQUÊTE N°1 : Récupérer les informations du rendu et de la leçon associée.
    // On récupère aussi l'id de l'élève.
    $sql_submission = "SELECT s.*, l.title as lesson_title, l.lesson_type FROM submissions s JOIN lessons l ON s.lesson_id = l.id WHERE s.id = ?";
    $stmt = $conn->prepare($sql_submission);
    if (!$stmt) {
        throw new Exception("Erreur de préparation de la requête de rendu: " . $conn->error);
    }
    
    $stmt->bind_param("i", $submission_id);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 0) {
        http_response_code(404);
        echo json_encode(["success" => false, "error" => "Aucun rendu trouvé avec cet ID."]);
        exit();
    }

    $submission_data = $result->fetch_assoc();
    $stmt->close();
    
    // CORRECTION : On convertit explicitement la note en float ou null.
    $submission_data['grade'] = $submission_data['grade'] !== null ? (float)$submission_data['grade'] : null;

    // Décodage sécurisé des champs JSON de la BDD.
    $submission_data['content'] = json_decode($submission_data['content'] ?? '[]') ?? [];
    $submission_data['instructor_feedback'] = json_decode($submission_data['instructor_feedback'] ?? '{}') ?? (object)[];
    
    $lesson_id = $submission_data['lesson_id'];
    $student_id = $submission_data['student_id']; // On récupère l'ID de l'étudiant

    // 4. REQUÊTE N°2 : Récupérer les blocs de contenu de l'énoncé original de la leçon.
    $submission_data['lesson_enonce'] = [];
    $sql_enonce = "SELECT id, block_type, content, order_index, metadata FROM lesson_content_blocks WHERE lesson_id = ? ORDER BY order_index ASC";
    $stmt_enonce = $conn->prepare($sql_enonce);
    if (!$stmt_enonce) {
        throw new Exception("Erreur de préparation de la requête d'énoncé: " . $conn->error);
    }

    $stmt_enonce->bind_param("i", $lesson_id);
    $stmt_enonce->execute();
    $result_enonce = $stmt_enonce->get_result();

    // NOUVEAU : On cherche l'ID du quiz pendant qu'on parcourt les blocs
    $quiz_id = null;
    while ($block_row = $result_enonce->fetch_assoc()) {
        $block_row['metadata'] = json_decode($block_row['metadata'] ?? '{}') ?? (object)[];
        $submission_data['lesson_enonce'][] = $block_row;
        if ($block_row['block_type'] === 'quiz') {
            $quiz_id = (int)$block_row['content'];
        }
    }
    $stmt_enonce->close();

    // On ajoute l'ID du quiz trouvé (ou null) à la réponse
    $submission_data['associated_quiz_id'] = $quiz_id;

    $conn->close();

    // 5. Encodage final en JSON et envoi de la réponse.
    $json_response = json_encode($submission_data);

    if (json_last_error() !== JSON_ERROR_NONE) {
        throw new Exception("Erreur lors de l'encodage de la réponse JSON: " . json_last_error_msg());
    }
    
    http_response_code(200);
    echo $json_response;

} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "error" => "Une erreur est survenue sur le serveur.",
        "details" => $e->getMessage(),
        "file" => $e->getFile(),
        "line" => $e->getLine()
    ]);
}
?>
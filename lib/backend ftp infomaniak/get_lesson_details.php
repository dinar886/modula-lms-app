<?php
// Fichier : /api/v1/get_lesson_details.php
// Description : Récupère les détails complets d'une leçon, y compris ses blocs,
// et maintenant, les informations sur la soumission de l'étudiant connecté.

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");

require_once 'config.php';

// On a maintenant besoin de l'ID de l'étudiant pour vérifier s'il a déjà soumis son travail.
if (!isset($_GET['lesson_id']) || empty($_GET['lesson_id']) || !isset($_GET['student_id'])) {
    http_response_code(400);
    echo json_encode(["error" => "Les ID de leçon et d'étudiant sont manquants."]);
    exit();
}
$lesson_id = (int)$_GET['lesson_id'];
$student_id = (int)$_GET['student_id'];

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["error" => "Erreur de connexion à la base de données."]);
    exit();
}
$conn->set_charset("utf8mb4");

$lesson_details = [];

// 1. Récupérer les informations de base de la leçon.
// On ajoute la `due_date`
$sql_lesson = "SELECT id, title, lesson_type, due_date, metadata FROM lessons WHERE id = ?";
$stmt_lesson = $conn->prepare($sql_lesson);
$stmt_lesson->bind_param("i", $lesson_id);
$stmt_lesson->execute();
$result_lesson = $stmt_lesson->get_result();

if ($result_lesson->num_rows > 0) {
    $lesson_details = $result_lesson->fetch_assoc();
    $lesson_details['id'] = (int)$lesson_details['id'];
    $lesson_details['metadata'] = !empty($lesson_details['metadata']) ? json_decode($lesson_details['metadata']) : new stdClass();
    $lesson_details['content_blocks'] = [];
    // On initialise le champ pour la soumission
    $lesson_details['submission'] = null;

    // 2. Récupérer tous les blocs de contenu (inchangé).
    $sql_blocks = "SELECT id, block_type, content, order_index, metadata FROM lesson_content_blocks WHERE lesson_id = ? ORDER BY order_index ASC";
    $stmt_blocks = $conn->prepare($sql_blocks);
    $stmt_blocks->bind_param("i", $lesson_id);
    $stmt_blocks->execute();
    $result_blocks = $stmt_blocks->get_result();

    if ($result_blocks->num_rows > 0) {
        while ($block_row = $result_blocks->fetch_assoc()) {
            $block_row['id'] = (int)$block_row['id'];
            $block_row['metadata'] = !empty($block_row['metadata']) ? json_decode($block_row['metadata']) : new stdClass();
            $lesson_details['content_blocks'][] = $block_row;
        }
    }
    $stmt_blocks->close();

    // 3. NOUVEAU : Si la leçon est un devoir ou une évaluation, on cherche la soumission de l'étudiant.
    if ($lesson_details['lesson_type'] === 'devoir' || $lesson_details['lesson_type'] === 'evaluation') {
        $sql_submission = "SELECT id, submission_date, content, grade, status, instructor_feedback FROM submissions WHERE lesson_id = ? AND student_id = ? LIMIT 1";
        $stmt_submission = $conn->prepare($sql_submission);
        $stmt_submission->bind_param("ii", $lesson_id, $student_id);
        $stmt_submission->execute();
        $result_submission = $stmt_submission->get_result();
        if ($result_submission->num_rows > 0) {
            $submission_data = $result_submission->fetch_assoc();
            // Le contenu est stocké en JSON, on le décode pour l'application.
            $submission_data['content'] = json_decode($submission_data['content']);
            $lesson_details['submission'] = $submission_data;
        }
        $stmt_submission->close();
    }


    http_response_code(200);
    echo json_encode($lesson_details);

} else {
    http_response_code(404);
    echo json_encode(["error" => "Aucune leçon trouvée avec cet ID."]);
}

$stmt_lesson->close();
$conn->close();
?>
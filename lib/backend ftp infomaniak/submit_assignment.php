<?php
// Fichier: /api/v1/submit_assignment.php
// MODIFIÉ : Marque la leçon comme terminée lors de la soumission.

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once 'config.php';

$data = json_decode(file_get_contents("php://input"));

if (
    !isset($data->lesson_id) ||
    !isset($data->student_id) ||
    !isset($data->course_id) ||
    !isset($data->content)
) {
    http_response_code(400);
    echo json_encode(["message" => "Données incomplètes."]);
    exit();
}

$lesson_id = (int)$data->lesson_id;
$student_id = (int)$data->student_id;
$course_id = (int)$data->course_id;
$content_json = json_encode($data->content);


$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["message" => "Erreur de connexion à la base de données."]);
    exit();
}
$conn->set_charset("utf8mb4");

// On démarre une transaction pour assurer que les deux opérations (soumission et complétion) réussissent ou échouent ensemble.
$conn->begin_transaction();

try {
    // Étape 1 : Insérer ou mettre à jour la soumission.
    $sql_check = "SELECT id FROM submissions WHERE lesson_id = ? AND student_id = ?";
    $stmt_check = $conn->prepare($sql_check);
    $stmt_check->bind_param("ii", $lesson_id, $student_id);
    $stmt_check->execute();
    $stmt_check->store_result();

    if ($stmt_check->num_rows > 0) {
        $sql_update = "UPDATE submissions SET content = ?, submission_date = NOW(), status = 'submitted', grade = NULL, instructor_feedback = NULL WHERE lesson_id = ? AND student_id = ?";
        $stmt = $conn->prepare($sql_update);
        $stmt->bind_param("sii", $content_json, $lesson_id, $student_id);
    } else {
        $sql_insert = "INSERT INTO submissions (lesson_id, student_id, course_id, content, status) VALUES (?, ?, ?, ?, 'submitted')";
        $stmt = $conn->prepare($sql_insert);
        $stmt->bind_param("iiis", $lesson_id, $student_id, $course_id, $content_json);
    }
    $stmt_check->close();

    if (!$stmt->execute()) {
        throw new Exception("Erreur lors de l'envoi du rendu: " . $stmt->error);
    }
    $stmt->close();

    // Étape 2 : Marquer la leçon comme terminée.
    $sql_complete = "INSERT INTO user_lesson_completions (user_id, lesson_id, course_id) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE completion_date = NOW()";
    $stmt_complete = $conn->prepare($sql_complete);
    $stmt_complete->bind_param("iii", $student_id, $lesson_id, $course_id);

    if (!$stmt_complete->execute()) {
         throw new Exception("Erreur lors de la mise à jour de la complétion: " . $stmt_complete->error);
    }
    $stmt_complete->close();
    
    // Si tout s'est bien passé, on valide la transaction.
    $conn->commit();

    http_response_code(200);
    echo json_encode(["message" => "Rendu envoyé avec succès."]);

} catch (Exception $e) {
    // En cas d'erreur, on annule toutes les opérations.
    $conn->rollback();
    http_response_code(500);
    echo json_encode(["message" => "Une erreur interne est survenue.", "error" => $e->getMessage()]);
}

$conn->close();
?>
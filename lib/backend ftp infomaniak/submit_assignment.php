<?php
// Fichier: /api/v1/submit_assignment.php
// Description: Gère la soumission d'un devoir ou d'une évaluation par un étudiant.

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once 'config.php';

// On lit le corps de la requête qui est au format JSON.
$data = json_decode(file_get_contents("php://input"));

// Validation des données d'entrée (on s'assure que les clés existent dans l'objet JSON).
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
// Le contenu arrive sous forme de tableau d'objets, on le ré-encode en chaîne JSON pour le stocker.
$content_json = json_encode($data->content);


$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["message" => "Erreur de connexion à la base de données."]);
    exit();
}
$conn->set_charset("utf8mb4");

// On vérifie d'abord si une soumission existe déjà pour cet élève et cette leçon
// pour éviter les doublons et permettre la mise à jour si nécessaire.
$sql_check = "SELECT id FROM submissions WHERE lesson_id = ? AND student_id = ?";
$stmt_check = $conn->prepare($sql_check);
$stmt_check->bind_param("ii", $lesson_id, $student_id);
$stmt_check->execute();
$stmt_check->store_result();

if ($stmt_check->num_rows > 0) {
    // Si une soumission existe, on pourrait la mettre à jour, mais par défaut,
    // on considère une soumission comme finale. Pour l'instant, on ne fait rien
    // ou on pourrait renvoyer une erreur indiquant qu'un travail a déjà été rendu.
    // Pour être sûr, on met à jour la soumission existante.
    $sql_update = "UPDATE submissions SET content = ?, submission_date = NOW(), status = 'submitted', grade = NULL, instructor_feedback = NULL WHERE lesson_id = ? AND student_id = ?";
    $stmt = $conn->prepare($sql_update);
    $stmt->bind_param("sii", $content_json, $lesson_id, $student_id);
} else {
    // Sinon, on insère une nouvelle ligne.
    // Le statut est 'submitted' par défaut.
    $sql_insert = "INSERT INTO submissions (lesson_id, student_id, course_id, content, status) VALUES (?, ?, ?, ?, 'submitted')";
    $stmt = $conn->prepare($sql_insert);
    $stmt->bind_param("iiis", $lesson_id, $student_id, $course_id, $content_json);
}
$stmt_check->close();


if ($stmt->execute()) {
    http_response_code(200);
    echo json_encode(["message" => "Rendu envoyé avec succès."]);
} else {
    http_response_code(500);
    echo json_encode(["message" => "Erreur lors de l'envoi du rendu.", "error" => $stmt->error]);
}

$stmt->close();
$conn->close();
?>
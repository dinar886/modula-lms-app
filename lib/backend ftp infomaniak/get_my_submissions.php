<?php
// Fichier : /api/v1/get_my_submissions.php
// Description: Récupère la liste de tous les rendus pour un étudiant donné.

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");

require_once 'config.php';

// On a besoin de l'ID de l'étudiant.
if (!isset($_GET['student_id'])) {
    http_response_code(400);
    echo json_encode(["error" => "L'ID de l'étudiant est manquant."]);
    exit();
}
$student_id = (int)$_GET['student_id'];

$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["message" => "Erreur de connexion à la base de données."]);
    exit();
}
$conn->set_charset("utf8mb4");

$sql = "
    SELECT 
        s.id as submission_id,
        s.status,
        s.submission_date,
        s.grade,
        s.instructor_feedback,
        l.id as lesson_id,
        l.title as lesson_title,
        l.lesson_type,
        c.id as course_id,
        c.title as course_title
    FROM submissions s
    JOIN lessons l ON s.lesson_id = l.id
    JOIN courses c ON s.course_id = c.id
    WHERE s.student_id = ?
    ORDER BY s.submission_date DESC
";

$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $student_id);
$stmt->execute();
$result = $stmt->get_result();

$submissions = [];
while ($row = $result->fetch_assoc()) {
    $submissions[] = $row;
}

http_response_code(200);
echo json_encode($submissions);

$stmt->close();
$conn->close();
?>
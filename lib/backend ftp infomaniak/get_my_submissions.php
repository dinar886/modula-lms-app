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

// CORRECTION : La requête a été modifiée pour être identique à celle utilisée
// pour les instructeurs, en joignant la table 'users' pour récupérer les
// informations de l'étudiant (nom, image, etc.).
$sql = "
    SELECT 
        s.id as submission_id,
        s.status,
        s.submission_date,
        s.grade,
        u.id as student_id,
        u.name as student_name,
        u.profile_image_url as student_image_url,
        l.id as lesson_id,
        l.title as lesson_title,
        l.lesson_type,
        c.id as course_id,
        c.title as course_title
    FROM submissions s
    JOIN users u ON s.student_id = u.id
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
    // On s'assure que les valeurs numériques sont bien des nombres
    $row['submission_id'] = (int)$row['submission_id'];
    $row['student_id'] = (int)$row['student_id'];
    $row['lesson_id'] = (int)$row['lesson_id'];
    $row['course_id'] = (int)$row['course_id'];
    $row['grade'] = $row['grade'] !== null ? (float)$row['grade'] : null;
    $submissions[] = $row;
}

http_response_code(200);
echo json_encode($submissions);

$stmt->close();
$conn->close();
?>
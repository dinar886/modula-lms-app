<?php
// Fichier : /api/v1/get_instructor_submissions.php
// Description: Récupère la liste de tous les rendus des élèves pour les cours d'un instructeur donné.

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");

require_once 'config.php';

// On a besoin de l'ID de l'instructeur pour filtrer les résultats.
if (!isset($_GET['instructor_id'])) {
    http_response_code(400);
    echo json_encode(["error" => "L'ID de l'instructeur est manquant."]);
    exit();
}
$instructor_id = (int)$_GET['instructor_id'];

$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["message" => "Erreur de connexion à la base de données."]);
    exit();
}
$conn->set_charset("utf8mb4");

// Cette requête complexe joint plusieurs tables pour récupérer toutes les infos nécessaires :
// - submissions (le rendu)
// - users (pour le nom de l'élève)
// - lessons (pour le titre du devoir/contrôle)
// - courses (pour le titre du cours)
// - user_courses (pour s'assurer qu'on ne prend que les cours de l'instructeur connecté)
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
    JOIN user_courses uc ON s.course_id = uc.course_id
    WHERE uc.user_id = ?
    ORDER BY s.submission_date DESC
";

$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $instructor_id);
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
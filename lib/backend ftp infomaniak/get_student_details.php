<?php
// Fichier : /api/v1/get_student_details.php
// Description : Version finale pour récupérer le profil complet d'un élève.

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");

require_once 'config.php';

// Vérification des paramètres d'entrée.
if (!isset($_GET['student_id']) || !isset($_GET['instructor_id'])) {
    http_response_code(400);
    echo json_encode(["error" => "Les paramètres 'student_id' et 'instructor_id' sont requis."]);
    exit();
}
$student_id = (int)$_GET['student_id'];
$instructor_id = (int)$_GET['instructor_id'];

$conn = new mysqli($servername, $username, $password, $dbname);
$conn->set_charset("utf8");

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["error" => "Erreur de connexion à la base de données: " . $conn->connect_error]);
    exit();
}

$response = [];

// --- 1. Récupérer les informations de base de l'élève ---
// **MODIFICATION : On sélectionne maintenant la colonne `profile_image_url`.**
$stmt_user = $conn->prepare("SELECT id, name, email, profile_image_url FROM users WHERE id = ?");
$stmt_user->bind_param("i", $student_id);
$stmt_user->execute();
$user_result = $stmt_user->get_result();

if ($user_result->num_rows > 0) {
    $response['student_info'] = $user_result->fetch_assoc();
} else {
    http_response_code(404);
    echo json_encode(["error" => "Aucun élève trouvé avec l'ID " . $student_id]);
    exit();
}
$stmt_user->close();


// --- 2. Récupérer les cours de cet instructeur auxquels l'élève est inscrit ---
$stmt_courses = $conn->prepare("
    SELECT c.id, c.title, c.image_url
    FROM enrollments e
    JOIN courses c ON e.course_id = c.id
    JOIN user_courses uc ON c.id = uc.course_id
    WHERE e.user_id = ? AND uc.user_id = ?
");
$stmt_courses->bind_param("ii", $student_id, $instructor_id);
$stmt_courses->execute();
$courses_result = $stmt_courses->get_result();
$courses_data = [];
while ($row = $courses_result->fetch_assoc()) {
    $courses_data[] = $row;
}
$response['enrolled_courses'] = $courses_data;
$stmt_courses->close();


// --- 3. Récupérer les soumissions (rendus) de l'élève ---
$submissions_data = [];
$table_check = $conn->query("SHOW TABLES LIKE 'submissions'");
if ($table_check && $table_check->num_rows == 1) {
    $stmt_submissions = $conn->prepare("
        SELECT s.id, s.grade, s.submission_date, l.title as lesson_title, c.title as course_title
        FROM submissions s
        JOIN lessons l ON s.lesson_id = l.id
        JOIN courses c ON s.course_id = c.id
        JOIN user_courses uc ON c.id = uc.course_id
        WHERE s.student_id = ? AND uc.user_id = ?
        ORDER BY s.submission_date DESC
        LIMIT 10
    ");
    $stmt_submissions->bind_param("ii", $student_id, $instructor_id);
    $stmt_submissions->execute();
    $submissions_result = $stmt_submissions->get_result();
    while ($row = $submissions_result->fetch_assoc()) {
        $row['grade'] = isset($row['grade']) ? (float)$row['grade'] : null;
        $submissions_data[] = $row;
    }
    $stmt_submissions->close();
}
$response['submissions'] = $submissions_data;


$conn->close();

// On renvoie la réponse JSON complète.
http_response_code(200);
echo json_encode($response);

?>

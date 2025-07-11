<?php
// Fichier : /api/v1/get_course_content.php
// MODIFIÉ : Récupère maintenant l'état de complétion de chaque leçon.

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");

require_once 'config.php';

// MISE À JOUR : On a maintenant besoin de l'ID du cours et de l'utilisateur.
if (!isset($_GET['course_id']) || empty($_GET['course_id']) || !isset($_GET['user_id']) || empty($_GET['user_id'])) {
    http_response_code(400);
    echo json_encode(["error" => "Les ID de cours et d'utilisateur sont requis."]);
    exit();
}
$course_id = (int)$_GET['course_id'];
$user_id = (int)$_GET['user_id'];

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["error" => "Erreur de connexion à la base de données."]);
    exit();
}
$conn->set_charset("utf8mb4");

$course_content = [];

// 1. Récupérer les sections du cours.
$sql_sections = "SELECT id, title FROM sections WHERE course_id = ? ORDER BY order_index ASC";
$stmt_sections = $conn->prepare($sql_sections);
$stmt_sections->bind_param("i", $course_id);
$stmt_sections->execute();
$result_sections = $stmt_sections->get_result();

if ($result_sections->num_rows > 0) {
    while ($section_row = $result_sections->fetch_assoc()) {
        $section_id = $section_row['id'];
        
        $section_data = [
            'id' => (int)$section_id,
            'title' => $section_row['title'],
            'lessons' => []
        ];

        // 2. Pour chaque section, récupérer ses leçons avec leur état de complétion.
        // MISE À JOUR : On fait une jointure à gauche (LEFT JOIN) avec la table user_lesson_completions.
        $sql_lessons = "
            SELECT 
                l.id, 
                l.title, 
                l.lesson_type, 
                l.due_date,
                (CASE WHEN ulc.id IS NOT NULL THEN true ELSE false END) as is_completed
            FROM lessons l
            LEFT JOIN user_lesson_completions ulc ON l.id = ulc.lesson_id AND ulc.user_id = ?
            WHERE l.section_id = ? 
            ORDER BY l.order_index ASC
        ";
        $stmt_lessons = $conn->prepare($sql_lessons);
        $stmt_lessons->bind_param("ii", $user_id, $section_id);
        $stmt_lessons->execute();
        $result_lessons = $stmt_lessons->get_result();

        if ($result_lessons->num_rows > 0) {
            while ($lesson_row = $result_lessons->fetch_assoc()) {
                $lesson_row['id'] = (int)$lesson_row['id'];
                // Le champ 'is_completed' est un booléen (vrai/faux).
                $lesson_row['is_completed'] = (bool)$lesson_row['is_completed'];
                $section_data['lessons'][] = $lesson_row;
            }
        }
        $stmt_lessons->close();
        
        $course_content[] = $section_data;
    }
}
$stmt_sections->close();

http_response_code(200);
echo json_encode($course_content);

$conn->close();
?>
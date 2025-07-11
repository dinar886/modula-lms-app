<?php
// Fichier : /api/v1/get_my_courses.php
// Description : Récupère les cours pour un utilisateur donné.
// La logique est divisée en fonction du rôle de l'utilisateur :
// - 'instructor' : Récupère les cours créés.
// - 'learner' : Récupère les cours achetés avec les statistiques de progression.

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");

require_once 'config.php';

// Vérification des paramètres d'entrée 'user_id' et 'role'.
if (!isset($_GET['user_id']) || empty($_GET['user_id']) || !isset($_GET['role']) || empty($_GET['role'])) {
    http_response_code(400);
    echo json_encode(["error" => "Les paramètres 'user_id' et 'role' sont requis."]);
    exit();
}
$user_id = (int)$_GET['user_id'];
$role = $_GET['role'];

$conn = new mysqli($servername, $username, $password, $dbname);
$conn->set_charset("utf8mb4");

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["error" => "Erreur de connexion à la base de données: " . $conn->connect_error]);
    exit();
}

$sql = "";
$stmt = null;

if ($role === 'instructor') {
    // LOGIQUE POUR L'INSTRUCTEUR (inchangée)
    $sql = "SELECT c.* FROM courses c
            JOIN user_courses uc ON c.id = uc.course_id
            WHERE uc.user_id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $user_id);

} elseif ($role === 'learner') {
    // LOGIQUE POUR L'ÉLÈVE (MISE À JOUR AVEC LES STATISTIQUES)
    // Cette requête complexe utilise des sous-requêtes pour calculer :
    // - total_lessons: Le nombre total de leçons dans le cours.
    // - completed_lessons: Le nombre de leçons que l'utilisateur a marquées comme terminées.
    // - pending_assignments: Le nombre de leçons de type 'devoir' pour lesquelles l'utilisateur n'a pas encore de rendu (submission).
    // - pending_evaluations: Le nombre de leçons de type 'evaluation' pour lesquelles l'utilisateur n'a pas encore de rendu.
    $sql = "
        SELECT 
            c.*,
            (SELECT COUNT(l.id) FROM lessons l JOIN sections s ON l.section_id = s.id WHERE s.course_id = c.id) as total_lessons,
            (SELECT COUNT(ulc.id) FROM user_lesson_completions ulc WHERE ulc.user_id = e.user_id AND ulc.course_id = c.id) as completed_lessons,
            (SELECT COUNT(l.id) FROM lessons l JOIN sections s ON l.section_id = s.id WHERE s.course_id = c.id AND l.lesson_type = 'devoir' AND l.id NOT IN (SELECT sub.lesson_id FROM submissions sub WHERE sub.student_id = e.user_id AND sub.lesson_id = l.id)) as pending_assignments,
            (SELECT COUNT(l.id) FROM lessons l JOIN sections s ON l.section_id = s.id WHERE s.course_id = c.id AND l.lesson_type = 'evaluation' AND l.id NOT IN (SELECT sub.lesson_id FROM submissions sub WHERE sub.student_id = e.user_id AND sub.lesson_id = l.id)) as pending_evaluations
        FROM courses c
        JOIN enrollments e ON c.id = e.course_id
        WHERE e.user_id = ?
    ";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $user_id);

} else {
    http_response_code(400);
    echo json_encode(["error" => "Rôle utilisateur non valide. Le rôle doit être 'instructor' ou 'learner'."]);
    $conn->close();
    exit();
}

if ($stmt) {
    $stmt->execute();
    $result = $stmt->get_result();
    $courses = [];

    if ($result->num_rows > 0) {
      while($row = $result->fetch_assoc()) {
        // Conversion des types de données pour une réponse JSON propre et cohérente.
        $row['id'] = (int)$row['id'];
        $row['price'] = (float)$row['price'];
        // On s'assure que les nouvelles statistiques sont bien des entiers.
        if (isset($row['total_lessons'])) {
            $row['total_lessons'] = (int)$row['total_lessons'];
        }
        if (isset($row['completed_lessons'])) {
            $row['completed_lessons'] = (int)$row['completed_lessons'];
        }
        if (isset($row['pending_assignments'])) {
            $row['pending_assignments'] = (int)$row['pending_assignments'];
        }
        if (isset($row['pending_evaluations'])) {
            $row['pending_evaluations'] = (int)$row['pending_evaluations'];
        }
        $courses[] = $row;
      }
    }

    http_response_code(200);
    echo json_encode($courses);

    $stmt->close();
} else {
    http_response_code(500);
    echo json_encode(["error" => "Erreur lors de la préparation de la requête SQL."]);
}

$conn->close();
?>
<?php
// Fichier : /api/v1/get_upcoming_assignments.php
// Description : Récupère la liste de tous les devoirs et évaluations non soumis pour un étudiant donné.

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");

require_once 'config.php';

// On s'assure que l'ID de l'étudiant est bien fourni.
if (!isset($_GET['student_id'])) {
    http_response_code(400);
    echo json_encode(["error" => "L'ID de l'étudiant est manquant."]);
    exit();
}
$student_id = (int)$_GET['student_id'];

// Connexion à la base de données
$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["message" => "Erreur de connexion à la base de données."]);
    exit();
}
$conn->set_charset("utf8mb4");

// Cette requête récupère toutes les leçons de type 'devoir' ou 'evaluation' pour les cours d'un étudiant,
// à l'exception de celles pour lesquelles une soumission (un rendu) existe déjà.
// On fait une jointure à gauche (LEFT JOIN) sur la table des soumissions et on ne garde que les lignes où la soumission est NULL.
$sql = "
    SELECT
        l.id as lesson_id,
        l.title as lesson_title,
        l.lesson_type,
        l.due_date,
        c.id as course_id,
        c.title as course_title
    FROM lessons l
    JOIN sections s ON l.section_id = s.id
    JOIN courses c ON s.course_id = c.id
    JOIN enrollments e ON c.id = e.course_id
    LEFT JOIN submissions sub ON l.id = sub.lesson_id AND sub.student_id = ?
    WHERE e.user_id = ?
    AND l.lesson_type IN ('devoir', 'evaluation')
    AND sub.id IS NULL
    ORDER BY l.due_date ASC
";

$stmt = $conn->prepare($sql);
// On lie l'ID de l'étudiant aux deux placeholders '?' dans la requête.
$stmt->bind_param("ii", $student_id, $student_id);
$stmt->execute();
$result = $stmt->get_result();

$assignments = [];
while ($row = $result->fetch_assoc()) {
    // Conversion des types pour une réponse JSON propre.
    $row['lesson_id'] = (int)$row['lesson_id'];
    $row['course_id'] = (int)$row['course_id'];
    $assignments[] = $row;
}

http_response_code(200);
echo json_encode($assignments);

$stmt->close();
$conn->close();
?>
<?php
// Fichier : /api/v1/get_instructor_students.php
// Description : Récupère la liste de tous les élèves inscrits aux cours d'un instructeur spécifique.
// Le script renvoie les données groupées par cours pour un affichage facile côté client.

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");

require_once 'config.php';

// On s'assure que l'ID de l'instructeur est bien fourni.
if (!isset($_GET['instructor_id']) || empty($_GET['instructor_id'])) {
    http_response_code(400);
    echo json_encode(["error" => "Le paramètre 'instructor_id' est requis."]);
    exit();
}
$instructor_id = $_GET['instructor_id'];

$conn = new mysqli($servername, $username, $password, $dbname);
$conn->set_charset("utf8");

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["error" => "Erreur de connexion à la base de données: " . $conn->connect_error]);
    exit();
}

// LA REQUÊTE CLÉ :
// 1. On sélectionne les cours (c) appartenant à l'instructeur via la table `user_courses` (uc).
// 2. On joint avec `enrollments` (e) pour trouver toutes les inscriptions à ces cours.
// 3. On joint avec `users` (u) pour obtenir les détails de chaque élève inscrit.
// **MODIFICATION : Ajout de u.profile_image_url à la sélection.**
$sql = "
    SELECT
        c.id AS course_id,
        c.title AS course_title,
        u.id AS student_id,
        u.name AS student_name,
        u.email AS student_email,
        u.profile_image_url,
        e.enrollment_date
    FROM user_courses uc
    JOIN courses c ON uc.course_id = c.id
    JOIN enrollments e ON c.id = e.course_id
    JOIN users u ON e.user_id = u.id
    WHERE uc.user_id = ?
    ORDER BY c.title, u.name;
";

$stmt = $conn->prepare($sql);

// On vérifie si la préparation de la requête a échoué.
if ($stmt === false) {
    http_response_code(500);
    echo json_encode(["error" => "Erreur de préparation de la requête SQL: " . $conn->error]);
    $conn->close();
    exit();
}

$stmt->bind_param("i", $instructor_id);
$stmt->execute();
$result = $stmt->get_result();

$courses = [];

// On parcourt les résultats pour construire un tableau associatif bien structuré.
if ($result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $course_id = $row['course_id'];

        // Si c'est la première fois qu'on rencontre ce cours, on l'initialise.
        if (!isset($courses[$course_id])) {
            $courses[$course_id] = [
                'course_id' => (int)$course_id,
                'course_title' => $row['course_title'],
                'students' => []
            ];
        }

        // On ajoute l'élève à la liste des étudiants pour ce cours.
        // **MODIFICATION : On inclut profile_image_url dans les données de l'étudiant.**
        $courses[$course_id]['students'][] = [
            'id' => (int)$row['student_id'], // L'app s'attend à 'id', pas 'student_id'
            'name' => $row['student_name'],
            'email' => $row['student_email'],
            'profile_image_url' => $row['profile_image_url'],
            'enrollment_date' => $row['enrollment_date']
        ];
    }
}

$stmt->close();
$conn->close();

// On renvoie les données au format JSON, en s'assurant que c'est bien une liste (array).
http_response_code(200);
echo json_encode(array_values($courses));

?>
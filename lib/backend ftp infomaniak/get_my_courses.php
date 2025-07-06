<?php
// Fichier : /api/v1/get_my_courses.php
// Description : Récupère les cours pour un utilisateur donné.
// La logique est divisée en fonction du rôle de l'utilisateur :
// - 'instructor' : Utilise la table `user_courses` pour récupérer les cours créés.
// - 'learner' : Utilise la table `enrollments` pour récupérer les cours achetés.

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");

require_once 'config.php';

// Vérification des paramètres d'entrée 'user_id' et 'role'.
if (!isset($_GET['user_id']) || empty($_GET['user_id']) || !isset($_GET['role']) || empty($_GET['role'])) {
    http_response_code(400);
    echo json_encode(["error" => "Les paramètres 'user_id' et 'role' sont requis."]);
    exit();
}
$user_id = $_GET['user_id'];
$role = $_GET['role'];

$conn = new mysqli($servername, $username, $password, $dbname);
$conn->set_charset("utf8");

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["error" => "Erreur de connexion à la base de données: " . $conn->connect_error]);
    exit();
}

$sql = "";
$stmt = null;

// On choisit la requête SQL à exécuter en fonction du rôle de l'utilisateur.
if ($role === 'instructor') {
    // LOGIQUE POUR L'INSTRUCTEUR :
    // On fait une jointure (JOIN) entre la table `courses` et la table `user_courses`
    // pour récupérer les détails de tous les cours créés par cet instructeur.
    // **CORRECTION : Utilisation de la table `user_courses` comme demandé.**
    $sql = "SELECT c.* FROM courses c
            JOIN user_courses uc ON c.id = uc.course_id
            WHERE uc.user_id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $user_id);

} elseif ($role === 'learner') {
    // LOGIQUE POUR L'ÉLÈVE :
    // On fait une jointure entre `courses` et `enrollments` pour trouver
    // les cours auxquels l'élève est inscrit.
    $sql = "SELECT c.* FROM courses c
            JOIN enrollments e ON c.id = e.course_id
            WHERE e.user_id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $user_id);

} else {
    // Si le rôle n'est ni 'instructor' ni 'learner', on renvoie une erreur.
    http_response_code(400);
    echo json_encode(["error" => "Rôle utilisateur non valide. Le rôle doit être 'instructor' ou 'learner'."]);
    $conn->close();
    exit();
}

// Exécution de la requête préparée.
if ($stmt) {
    $stmt->execute();
    $result = $stmt->get_result();

    $courses = array();

    if ($result->num_rows > 0) {
      while($row = $result->fetch_assoc()) {
        // On s'assure que les types de données sont corrects (entier, flottant) avant de les envoyer.
        $row['id'] = (int)$row['id'];
        $row['price'] = (float)$row['price'];
        $courses[] = $row;
      }
    }

    http_response_code(200);
    echo json_encode($courses);

    $stmt->close();
} else {
    // Si la requête n'a pas pu être préparée (erreur de syntaxe SQL, etc.).
    http_response_code(500);
    echo json_encode(["error" => "Erreur lors de la préparation de la requête SQL."]);
}

$conn->close();

?>

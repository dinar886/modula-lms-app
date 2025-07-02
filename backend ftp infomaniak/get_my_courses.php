<?php
// Fichier : /api/v1/get_my_courses.php

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");

require_once 'config.php';

// Vérifie que l'ID de l'utilisateur est bien passé en paramètre.
if (!isset($_GET['user_id']) || empty($_GET['user_id'])) {
    http_response_code(400);
    echo json_encode(["error" => "L'ID de l'utilisateur est manquant."]);
    exit();
}
$user_id = $_GET['user_id'];

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["error" => "Erreur de connexion à la base de données: " . $conn->connect_error]);
    exit();
}

// C'est ici que la magie opère : la jointure SQL (JOIN).
// On sélectionne toutes les colonnes de la table 'courses'...
// ...en joignant 'user_courses' et 'courses' là où les ID correspondent...
// ...et on filtre pour ne garder que les entrées correspondant à l'ID de l'utilisateur fourni.
$sql = "SELECT c.* FROM courses c
        JOIN user_courses uc ON c.id = uc.course_id
        WHERE uc.user_id = ?";

$stmt = $conn->prepare($sql);

if ($stmt === false) {
    http_response_code(500);
    echo json_encode(["error" => "Erreur lors de la préparation de la requête."]);
    exit();
}

$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();

$courses = array();

if ($result->num_rows > 0) {
  while($row = $result->fetch_assoc()) {
    $row['id'] = (int)$row['id'];
    $row['price'] = (float)$row['price'];
    $courses[] = $row;
  }
}

// On renvoie le tableau de cours (qui peut être vide si l'utilisateur n'a aucun cours).
http_response_code(200);
echo json_encode($courses);

$stmt->close();
$conn->close();

?>
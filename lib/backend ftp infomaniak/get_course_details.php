<?php
// Fichier : /api/v1/get_course_details.php

// Définit les en-têtes pour indiquer une réponse JSON et autoriser l'accès depuis n'importe quelle origine.
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");

// Inclut le fichier de configuration pour récupérer les identifiants de la base de données.
require_once 'config.php';

// Vérifie si un 'id' a été passé en paramètre dans l'URL (ex: ?id=1).
if (!isset($_GET['id']) || empty($_GET['id'])) {
    // Si l'ID est manquant, renvoie une erreur 400 (Bad Request).
    http_response_code(400);
    echo json_encode(["error" => "L'ID du cours est manquant."]);
    exit(); // Arrête l'exécution du script.
}
$course_id = $_GET['id'];

// Établit la connexion à la base de données en utilisant les variables du fichier config.
$conn = new mysqli($servername, $username, $password, $dbname);

// Vérifie si la connexion a échoué.
if ($conn->connect_error) {
    http_response_code(500); // Erreur interne du serveur.
    echo json_encode(["error" => "Erreur de connexion à la base de données: " . $conn->connect_error]);
    exit();
}

// Prépare une requête SQL sécurisée pour éviter les injections SQL.
// Le '?' est un placeholder qui sera remplacé par la valeur de l'ID.
$sql = "SELECT id, title, author, description, image_url, price FROM courses WHERE id = ?";
$stmt = $conn->prepare($sql);

if ($stmt === false) {
    http_response_code(500);
    echo json_encode(["error" => "Erreur lors de la préparation de la requête."]);
    exit();
}

// Lie la variable $course_id au placeholder '?' en spécifiant que c'est un entier ('i').
$stmt->bind_param("i", $course_id);

// Exécute la requête.
$stmt->execute();
$result = $stmt->get_result();

// Vérifie si un résultat a été trouvé.
if ($result->num_rows > 0) {
    $course = $result->fetch_assoc();
    // S'assure que les types de données sont corrects avant de les envoyer en JSON.
    $course['id'] = (int)$course['id'];
    $course['price'] = (float)$course['price'];
    // Encode le tableau du cours en JSON et l'affiche.
    echo json_encode($course);
} else {
    // Si aucun cours n'est trouvé, renvoie une erreur 404 (Not Found).
    http_response_code(404);
    echo json_encode(["error" => "Aucun cours trouvé avec cet ID."]);
}

// Ferme la requête préparée et la connexion à la base de données.
$stmt->close();
$conn->close();

?>

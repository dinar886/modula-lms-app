<?php
// Fichier : /api/v1/get_courses.php

// --- HEADERS HTTP ---
// Définit le type de contenu de la réponse en JSON et autorise les requêtes cross-origin.
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");

// --- CONNEXION À LA BASE DE DONNÉES ---
// Inclut les identifiants depuis un fichier de configuration séparé.
require_once 'config.php';

// Établit la connexion à la base de données.
$conn = new mysqli($servername, $username, $password, $dbname);

// Vérifie et gère les erreurs de connexion.
if ($conn->connect_error) {
  http_response_code(500); // Erreur serveur
  echo json_encode(["error" => "Erreur de connexion à la base de données: " . $conn->connect_error]);
  exit(); // Arrête le script
}

// --- RÉCUPÉRATION DES DONNÉES ---
// Prépare et exécute la requête SQL pour obtenir tous les cours.
$sql = "SELECT id, title, author, image_url, price FROM courses";
$result = $conn->query($sql);

$courses = array();

// Boucle sur les résultats et les stocke dans un tableau.
if ($result->num_rows > 0) {
  while($row = $result->fetch_assoc()) {
    // Assure le bon type de données pour l'ID et le prix.
    $row['id'] = (int)$row['id'];
    $row['price'] = (float)$row['price'];
    $courses[] = $row;
  }
}

// --- ENVOI DE LA RÉPONSE ---
// Encode le tableau des cours en JSON et l'affiche.
echo json_encode($courses);

// --- FERMETURE DE LA CONNEXION ---
// Libère les ressources en fermant la connexion.
$conn->close();

?>
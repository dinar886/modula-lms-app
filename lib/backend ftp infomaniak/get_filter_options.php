<?php
// Fichier : /api/v1/get_filter_options.php

// --- HEADERS HTTP ---
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type");

// --- CONNEXION À LA BASE DE DONNÉES ---
require_once 'config.php';

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
  http_response_code(500);
  echo json_encode(["error" => "Erreur de connexion à la base de données: " . $conn->connect_error]);
  exit();
}

// --- RÉCUPÉRATION DES OPTIONS ---
$filterOptions = array(
    'categories' => array(),
    'authors' => array()
);

// Récupérer toutes les catégories uniques
$sqlCategories = "SELECT DISTINCT category FROM courses WHERE category IS NOT NULL AND category != '' ORDER BY category";
$resultCategories = $conn->query($sqlCategories);

if ($resultCategories && $resultCategories->num_rows > 0) {
    while($row = $resultCategories->fetch_assoc()) {
        $filterOptions['categories'][] = $row['category'];
    }
}

// Récupérer tous les auteurs uniques
$sqlAuthors = "SELECT DISTINCT author FROM courses WHERE author IS NOT NULL AND author != '' ORDER BY author";
$resultAuthors = $conn->query($sqlAuthors);

if ($resultAuthors && $resultAuthors->num_rows > 0) {
    while($row = $resultAuthors->fetch_assoc()) {
        $filterOptions['authors'][] = $row['author'];
    }
}

// --- ENVOI DE LA RÉPONSE ---
echo json_encode($filterOptions);

// --- FERMETURE DE LA CONNEXION ---
$conn->close();

?>
<?php
// Fichier : /api/v1/get_courses.php

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

// --- RÉCUPÉRATION DES PARAMÈTRES DE REQUÊTE ---
$search = isset($_GET['search']) ? $conn->real_escape_string($_GET['search']) : '';
$sort = isset($_GET['sort']) ? $_GET['sort'] : 'popularity';
$priceRange = isset($_GET['price_range']) ? $_GET['price_range'] : 'all';
$categories = isset($_GET['categories']) ? explode(',', $_GET['categories']) : [];
$authors = isset($_GET['authors']) ? explode(',', $_GET['authors']) : [];

// --- CONSTRUCTION DE LA REQUÊTE SQL ---
$sql = "SELECT 
    c.id, 
    c.title, 
    c.author, 
    c.description,
    c.image_url, 
    c.price,
    c.category,
    c.created_at,
    COALESCE(AVG(r.rating), 0) as rating,
    COUNT(DISTINCT e.user_id) as enrollment_count
FROM courses c
LEFT JOIN course_ratings r ON c.id = r.course_id
LEFT JOIN enrollments e ON c.id = e.course_id
WHERE 1=1";

// Filtre de recherche
if (!empty($search)) {
    $sql .= " AND (c.title LIKE '%$search%' OR c.description LIKE '%$search%' OR c.author LIKE '%$search%')";
}

// Filtre par gamme de prix
switch ($priceRange) {
    case 'free':
        $sql .= " AND c.price = 0";
        break;
    case 'under50':
        $sql .= " AND c.price > 0 AND c.price < 50";
        break;
    case 'under100':
        $sql .= " AND c.price > 0 AND c.price < 100";
        break;
    case 'over100':
        $sql .= " AND c.price >= 100";
        break;
}

// Filtre par catégories
if (!empty($categories)) {
    $categoriesEscaped = array_map(function($cat) use ($conn) {
        return "'" . $conn->real_escape_string($cat) . "'";
    }, $categories);
    $sql .= " AND c.category IN (" . implode(',', $categoriesEscaped) . ")";
}

// Filtre par auteurs
if (!empty($authors)) {
    $authorsEscaped = array_map(function($auth) use ($conn) {
        return "'" . $conn->real_escape_string($auth) . "'";
    }, $authors);
    $sql .= " AND c.author IN (" . implode(',', $authorsEscaped) . ")";
}

// Groupement nécessaire pour les agrégations
$sql .= " GROUP BY c.id";

// Tri
switch ($sort) {
    case 'priceAsc':
        $sql .= " ORDER BY c.price ASC";
        break;
    case 'priceDesc':
        $sql .= " ORDER BY c.price DESC";
        break;
    case 'rating':
        $sql .= " ORDER BY rating DESC, enrollment_count DESC";
        break;
    case 'newest':
        $sql .= " ORDER BY c.created_at DESC";
        break;
    case 'popularity':
    default:
        $sql .= " ORDER BY enrollment_count DESC, rating DESC";
        break;
}

// --- EXÉCUTION DE LA REQUÊTE ---
$result = $conn->query($sql);

if ($result === false) {
    http_response_code(500);
    echo json_encode(["error" => "Erreur lors de l'exécution de la requête"]);
    $conn->close();
    exit();
}

$courses = array();

if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        // Conversion des types
        $row['id'] = (int)$row['id'];
        $row['price'] = (float)$row['price'];
        $row['rating'] = (float)$row['rating'];
        $row['enrollment_count'] = (int)$row['enrollment_count'];
        
        // Ne pas inclure les valeurs null ou 0 pour rating et enrollment_count
        if ($row['rating'] == 0) {
            $row['rating'] = null;
        }
        if ($row['enrollment_count'] == 0) {
            $row['enrollment_count'] = null;
        }
        
        $courses[] = $row;
    }
}

// --- ENVOI DE LA RÉPONSE ---
echo json_encode($courses);

// --- FERMETURE DE LA CONNEXION ---
$conn->close();

?>
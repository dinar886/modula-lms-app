<?php
// Fichier : /api/v1/get_course_content.php

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");

require_once 'config.php';

// Vérifie que l'ID du cours est bien passé en paramètre.
if (!isset($_GET['course_id']) || empty($_GET['course_id'])) {
    http_response_code(400);
    echo json_encode(["error" => "L'ID du cours est manquant."]);
    exit();
}
$course_id = $_GET['course_id'];

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["error" => "Erreur de connexion à la base de données."]);
    exit();
}
$conn->set_charset("utf8mb4");

// L'objectif est de construire un tableau final structuré.
$course_content = [];

// 1. Récupérer les sections du cours, ordonnées par leur index.
$sql_sections = "SELECT id, title FROM sections WHERE course_id = ? ORDER BY order_index ASC";
$stmt_sections = $conn->prepare($sql_sections);
$stmt_sections->bind_param("i", $course_id);
$stmt_sections->execute();
$result_sections = $stmt_sections->get_result();

if ($result_sections->num_rows > 0) {
    // On boucle sur chaque section trouvée.
    while ($section_row = $result_sections->fetch_assoc()) {
        $section_id = $section_row['id'];
        
        $section_data = [
            'id' => (int)$section_id,
            'title' => $section_row['title'],
            'lessons' => [] // On prépare un tableau vide pour les leçons de cette section.
        ];

        // 2. Pour chaque section, récupérer ses leçons, ordonnées.
        // ON AJOUTE `due_date` à la sélection.
        $sql_lessons = "SELECT id, title, lesson_type, due_date FROM lessons WHERE section_id = ? ORDER BY order_index ASC";
        $stmt_lessons = $conn->prepare($sql_lessons);
        $stmt_lessons->bind_param("i", $section_id);
        $stmt_lessons->execute();
        $result_lessons = $stmt_lessons->get_result();

        if ($result_lessons->num_rows > 0) {
            while ($lesson_row = $result_lessons->fetch_assoc()) {
                // On s'assure que les types sont corrects pour le JSON
                $lesson_row['id'] = (int)$lesson_row['id'];
                // On ajoute chaque leçon au tableau 'lessons' de la section courante.
                $section_data['lessons'][] = $lesson_row;
            }
        }
        $stmt_lessons->close();
        
        // On ajoute la section complète (avec ses leçons) au contenu du cours.
        $course_content[] = $section_data;
    }
}
$stmt_sections->close();

// On renvoie la structure complète en JSON.
http_response_code(200);
echo json_encode($course_content);

$conn->close();
?>
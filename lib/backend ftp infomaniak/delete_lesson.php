<?php
// Fichier : /api/v1/delete_lesson.php

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once 'config.php';

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->lesson_id)) {
    $conn = new mysqli($servername, $username, $password, $dbname);
    if ($conn->connect_error) { exit(); }

    $lesson_id = (int)$data->lesson_id;

    $sql = "DELETE FROM lessons WHERE id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $lesson_id);

    if ($stmt->execute()) {
        echo json_encode(["message" => "Leçon supprimée."]);
    } else {
        echo json_encode(["message" => "Erreur."]);
    }
    $stmt->close();
    $conn->close();
} else {
    echo json_encode(["message" => "ID de leçon manquant."]);
}
?>

<?php
// Fichier : /api/v1/delete_section.php

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once 'config.php';

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->section_id)) {
    $conn = new mysqli($servername, $username, $password, $dbname);
    if ($conn->connect_error) {
        http_response_code(500);
        echo json_encode(["message" => "Erreur de connexion."]);
        exit();
    }

    $section_id = (int)$data->section_id;

    $sql = "DELETE FROM sections WHERE id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $section_id);

    if ($stmt->execute()) {
        http_response_code(200);
        echo json_encode(["message" => "Section supprimée."]);
    } else {
        http_response_code(500);
        echo json_encode(["message" => "Erreur lors de la suppression."]);
    }
    $stmt->close();
    $conn->close();
} else {
    http_response_code(400);
    echo json_encode(["message" => "ID de section manquant."]);
}
?>

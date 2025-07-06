<?php
// Fichier : /api/v1/save_lesson_content.php
// Description : Sauvegarde l'ensemble des blocs de contenu pour une leçon donnée.

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once 'config.php';

// On récupère le corps de la requête qui contient notre objet Leçon en JSON.
$data = json_decode(file_get_contents("php://input"));

// On vérifie que les données essentielles sont présentes.
if (!empty($data->lesson_id) && isset($data->content_blocks)) {
    $conn = new mysqli($servername, $username, $password, $dbname);
    if ($conn->connect_error) {
        http_response_code(500);
        echo json_encode(["message" => "Connection failed: " . $conn->connect_error]);
        exit();
    }
    $conn->set_charset("utf8");

    // Récupération et nettoyage des données.
    $lesson_id = (int)$data->lesson_id;
    $content_blocks = $data->content_blocks;

    // Début de la transaction pour garantir la cohérence.
    $conn->begin_transaction();

    try {
        // Étape 1: Supprimer tous les anciens blocs de contenu pour cette leçon.
        // C'est la méthode la plus simple pour synchroniser l'état.
        $sql_delete = "DELETE FROM lesson_content_blocks WHERE lesson_id = ?";
        $stmt_delete = $conn->prepare($sql_delete);
        $stmt_delete->bind_param("i", $lesson_id);
        $stmt_delete->execute();
        $stmt_delete->close();

        // Étape 2: Boucler sur les nouveaux blocs reçus pour les insérer.
        if (is_array($content_blocks)) {
            foreach ($content_blocks as $index => $block) {
                // On prépare la requête d'insertion pour chaque bloc.
                $sql_insert = "INSERT INTO lesson_content_blocks (lesson_id, block_type, content, order_index) VALUES (?, ?, ?, ?)";
                $stmt_insert = $conn->prepare($sql_insert);

                // On s'assure que les données du bloc sont valides.
                $block_type = isset($block->block_type) ? $conn->real_escape_string($block->block_type) : 'text';
                $content = isset($block->content) ? $conn->real_escape_string($block->content) : '';
                $order_index = $index; // L'ordre est déterminé par la position dans le tableau reçu.

                $stmt_insert->bind_param("issi", $lesson_id, $block_type, $content, $order_index);
                $stmt_insert->execute();
                $stmt_insert->close();
            }
        }

        // Si tout s'est bien passé, on valide la transaction.
        $conn->commit();
        http_response_code(200);
        echo json_encode(["message" => "Contenu de la leçon sauvegardé avec succès."]);

    } catch (mysqli_sql_exception $exception) {
        // En cas d'erreur, on annule tout.
        $conn->rollback();
        http_response_code(500);
        echo json_encode(["message" => "Erreur lors de la sauvegarde.", "error" => $exception->getMessage()]);
    }

    $conn->close();
} else {
    // Si les données envoyées ne sont pas valides.
    http_response_code(400);
    echo json_encode(["message" => "Données de la leçon incomplètes ou invalides."]);
}
?>
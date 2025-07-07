<?php
// Fichier : /api/v1/save_lesson_content.php
// Description : Sauvegarde l'ensemble des blocs de contenu pour une leçon, y compris leur ordre et leurs métadonnées.

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once 'config.php';

$data = json_decode(file_get_contents("php://input"));

// On vérifie que les données essentielles sont présentes.
if (!empty($data->lesson_id) && isset($data->content_blocks)) {
    $conn = new mysqli($servername, $username, $password, $dbname);
    if ($conn->connect_error) {
        http_response_code(500);
        echo json_encode(["message" => "Connection failed: " . $conn->connect_error]);
        exit();
    }
    $conn->set_charset("utf8mb4");

    $lesson_id = (int)$data->lesson_id;
    $content_blocks = $data->content_blocks;

    $conn->begin_transaction();

    try {
        // Étape 1: Supprimer tous les anciens blocs de contenu pour cette leçon.
        $sql_delete = "DELETE FROM lesson_content_blocks WHERE lesson_id = ?";
        $stmt_delete = $conn->prepare($sql_delete);
        $stmt_delete->bind_param("i", $lesson_id);
        $stmt_delete->execute();
        $stmt_delete->close();

        // Étape 2: Boucler sur les nouveaux blocs reçus pour les insérer.
        if (is_array($content_blocks)) {
            // La requête d'insertion inclut maintenant la colonne `metadata`.
            $sql_insert = "INSERT INTO lesson_content_blocks (lesson_id, block_type, content, order_index, metadata) VALUES (?, ?, ?, ?, ?)";
            $stmt_insert = $conn->prepare($sql_insert);

            foreach ($content_blocks as $index => $block) {
                $block_type = $block->block_type ?? 'text';
                $content = $block->content ?? '';
                $order_index = $index;

                // On encode l'objet `metadata` en chaîne JSON.
                // S'il n'existe pas, on insère NULL.
                $metadata_json = isset($block->metadata) ? json_encode($block->metadata) : null;
                
                // On lie les 5 paramètres à la requête. 's' pour la chaîne JSON.
                $stmt_insert->bind_param("issis", $lesson_id, $block_type, $content, $order_index, $metadata_json);
                $stmt_insert->execute();
            }
            $stmt_insert->close();
        }

        $conn->commit();
        http_response_code(200);
        echo json_encode(["message" => "Contenu de la leçon sauvegardé avec succès."]);

    } catch (mysqli_sql_exception $exception) {
        $conn->rollback();
        http_response_code(500);
        echo json_encode(["message" => "Erreur lors de la sauvegarde.", "error" => $exception->getMessage()]);
    }

    $conn->close();
} else {
    http_response_code(400);
    echo json_encode(["message" => "Données de la leçon incomplètes ou invalides."]);
}
?>
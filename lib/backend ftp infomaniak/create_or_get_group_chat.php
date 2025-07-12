<?php
// Fichier: /api/v1/create_or_get_group_chat.php
// Description: Crée une nouvelle conversation de groupe pour un cours ou récupère celle qui existe déjà.
// Ajoute automatiquement l'instructeur et tous les élèves inscrits comme participants.

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once 'config.php';

// Récupère l'ID du cours envoyé depuis l'application Flutter.
$data = json_decode(file_get_contents("php://input"));

if (!isset($data->course_id)) {
    http_response_code(400);
    echo json_encode(["message" => "L'ID du cours est requis."]);
    exit();
}

$course_id = (int)$data->course_id;

// Connexion à la base de données.
$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["message" => "Erreur de connexion à la base de données."]);
    exit();
}
$conn->set_charset("utf8mb4");

// --- ÉTAPE 1: Vérifier si une conversation de groupe existe déjà pour ce cours. ---
$sql_find = "SELECT id FROM conversations WHERE course_id = ? AND type = 'group' LIMIT 1";
$stmt_find = $conn->prepare($sql_find);
$stmt_find->bind_param("i", $course_id);
$stmt_find->execute();
$result_find = $stmt_find->get_result();

if ($result_find->num_rows > 0) {
    // Si la conversation existe, on renvoie simplement son ID.
    $existing_conversation = $result_find->fetch_assoc();
    http_response_code(200);
    echo json_encode(['conversation_id' => $existing_conversation['id']]);
    $stmt_find->close();
    $conn->close();
    exit();
}
$stmt_find->close();

// --- ÉTAPE 2: Si aucune conversation n'existe, on la crée. ---
// On utilise une transaction pour s'assurer que toutes les opérations réussissent ou échouent ensemble.
$conn->begin_transaction();

try {
    // On récupère le titre du cours pour nommer la conversation.
    $stmt_course_title = $conn->prepare("SELECT title FROM courses WHERE id = ?");
    $stmt_course_title->bind_param("i", $course_id);
    $stmt_course_title->execute();
    $course_title = $stmt_course_title->get_result()->fetch_assoc()['title'];
    $stmt_course_title->close();

    // Insertion de la nouvelle conversation dans la table `conversations`.
    $sql_create_convo = "INSERT INTO conversations (course_id, name, type) VALUES (?, ?, 'group')";
    $stmt_create_convo = $conn->prepare($sql_create_convo);
    $stmt_create_convo->bind_param("is", $course_id, $course_title);
    $stmt_create_convo->execute();
    $conversation_id = $conn->insert_id; // On récupère l'ID de la nouvelle conversation.
    $stmt_create_convo->close();

    // On récupère l'ID de l'instructeur du cours.
    $stmt_instructor = $conn->prepare("SELECT user_id FROM user_courses WHERE course_id = ? LIMIT 1");
    $stmt_instructor->bind_param("i", $course_id);
    $stmt_instructor->execute();
    $instructor_id = $stmt_instructor->get_result()->fetch_assoc()['user_id'];
    $stmt_instructor->close();

    // On récupère les IDs de tous les élèves inscrits à ce cours.
    $stmt_students = $conn->prepare("SELECT user_id FROM enrollments WHERE course_id = ?");
    $stmt_students->bind_param("i", $course_id);
    $stmt_students->execute();
    $students_result = $stmt_students->get_result();
    
    $participant_ids = [];
    if ($instructor_id) {
        $participant_ids[] = $instructor_id;
    }
    while ($student = $students_result->fetch_assoc()) {
        $participant_ids[] = $student['user_id'];
    }
    $stmt_students->close();

    // On s'assure qu'il n'y a pas de doublons (même si c'est peu probable).
    $participant_ids = array_unique($participant_ids);

    // On insère tous les participants (instructeur et élèves) dans la table `conversation_participants`.
    if (!empty($participant_ids)) {
        $sql_add_participants = "INSERT INTO conversation_participants (conversation_id, user_id) VALUES (?, ?)";
        $stmt_add_participant = $conn->prepare($sql_add_participants);
        foreach ($participant_ids as $user_id) {
            $stmt_add_participant->bind_param("ii", $conversation_id, $user_id);
            $stmt_add_participant->execute();
        }
        $stmt_add_participant->close();
    }
    
    // Si tout s'est bien passé, on valide la transaction.
    $conn->commit();
    
    http_response_code(201); // 201 Created
    echo json_encode(['conversation_id' => $conversation_id]);

} catch (Exception $e) {
    // En cas d'erreur, on annule tout ce qui a été fait.
    $conn->rollback();
    http_response_code(500);
    echo json_encode(['message' => 'Erreur lors de la création de la conversation de groupe.', 'error' => $e->getMessage()]);
}

$conn->close();
?>
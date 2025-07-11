<?php
// Fichier: /api/v1/stripe_webhook_checkout.php
// Description: Webhook DÉDIÉ qui gère les événements de paiement Stripe (Checkout).

require_once __DIR__ . '/vendor/autoload.php';
require_once 'config.php'; // Charge la config BDD et les clés Stripe

// --- GESTION DES LOGS ---
// Il est crucial d'avoir des logs séparés pour faciliter le débogage.
ini_set('log_errors', 1);
ini_set('error_log', __DIR__ . '/stripe_webhook_checkout_log.txt'); // Fichier de log DÉDIÉ

// Le secret du webhook pour les paiements est chargé depuis config.php.
$endpoint_secret = $stripeCheckoutWebhookSecret;

// Vérification que le secret est bien configuré.
if (empty($endpoint_secret)) {
    error_log("ERREUR FATALE: Le secret du webhook de paiement (\$stripeCheckoutWebhookSecret) n'est pas défini dans config.php.");
    http_response_code(500);
    exit();
}

$payload = @file_get_contents('php://input');
$sig_header = $_SERVER['HTTP_STRIPE_SIGNATURE'];
$event = null;

try {
    // Vérification de la signature du webhook avec le secret DÉDIÉ.
    $event = \Stripe\Webhook::constructEvent(
        $payload, $sig_header, $endpoint_secret
    );
} catch(\UnexpectedValueException $e) {
    error_log("Webhook Checkout Error: Payload JSON invalide.");
    http_response_code(400);
    exit();
} catch(\Stripe\Exception\SignatureVerificationException $e) {
    error_log("Webhook Checkout Error: Signature invalide. Vérifiez que le secret du webhook est correct.");
    http_response_code(400);
    exit();
}

// Traitement de l'événement
if ($event->type == 'checkout.session.completed') {
    // Connexion à la base de données uniquement si l'événement est pertinent.
    $conn = new mysqli($servername, $username, $password, $dbname);
    if ($conn->connect_error) {
        error_log("DB Connection Error: " . $conn->connect_error);
        http_response_code(500);
        exit();
    }
    $conn->set_charset("utf8mb4");

    $session = $event->data->object;
    $user_id = $session->metadata->user_id ?? null;
    $course_id = $session->metadata->course_id ?? null;

    if ($user_id && $course_id) {
        $sql = "INSERT INTO enrollments (user_id, course_id) VALUES (?, ?) ON DUPLICATE KEY UPDATE enrollment_date = NOW()";
        $stmt = $conn->prepare($sql);
        if ($stmt) {
            $stmt->bind_param("ii", $user_id, $course_id);
            if ($stmt->execute()) {
                error_log("SUCCÈS: Inscription de l'utilisateur $user_id au cours $course_id.");
            } else {
                 error_log("Webhook DB Error: Échec de l'inscription de l'utilisateur $user_id au cours $course_id. Erreur: " . $stmt->error);
            }
            $stmt->close();
        } else {
            error_log("Webhook DB Error: Échec de la préparation de la requête. Erreur: " . $conn->error);
        }
    } else {
         error_log("Webhook Checkout Error: user_id ou course_id manquant dans les métadonnées pour la session " . $session->id);
    }

    $conn->close();
} else {
    // Log si ce webhook reçoit un événement inattendu.
    error_log('Événement non géré reçu par le webhook de paiement: ' . $event->type);
}

// Répondre 200 à Stripe pour confirmer la bonne réception.
http_response_code(200);
echo json_encode(['status' => 'success']);

?>
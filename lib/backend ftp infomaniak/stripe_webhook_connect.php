<?php
// Fichier: /api/v1/stripe_webhook_connect.php
// Description: Webhook DÉDIÉ qui gère les événements Stripe Connect (comptes des formateurs).

require_once __DIR__ . '/vendor/autoload.php';
require_once 'config.php'; // Charge la config BDD et les clés Stripe

// --- GESTION DES LOGS ---
ini_set('log_errors', 1);
ini_set('error_log', __DIR__ . '/stripe_webhook_connect_log.txt'); // Fichier de log DÉDIÉ

// Le secret du webhook pour Connect est chargé depuis config.php.
$endpoint_secret = $stripeConnectWebhookSecret;

// Vérification que le secret est bien configuré.
if (empty($endpoint_secret)) {
    error_log("ERREUR FATALE: Le secret du webhook Connect (\$stripeConnectWebhookSecret) n'est pas défini dans config.php.");
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
    error_log("Webhook Connect Error: Payload JSON invalide.");
    http_response_code(400);
    exit();
} catch(\Stripe\Exception\SignatureVerificationException $e) {
    error_log("Webhook Connect Error: Signature invalide. Vérifiez que le secret du webhook est correct.");
    http_response_code(400);
    exit();
}

// Traitement de l'événement
if ($event->type == 'account.updated') {
    // Connexion à la base de données uniquement si l'événement est pertinent.
    $conn = new mysqli($servername, $username, $password, $dbname);
    if ($conn->connect_error) {
        error_log("DB Connection Error: " . $conn->connect_error);
        http_response_code(500);
        exit();
    }
    $conn->set_charset("utf8mb4");

    $account = $event->data->object;
    $stripe_account_id = $account->id;

    $details_submitted = $account->details_submitted ? 1 : 0;
    $payouts_enabled = $account->payouts_enabled ? 1 : 0;

    $sql = "UPDATE user_stripe_accounts SET details_submitted = ?, payouts_enabled = ? WHERE stripe_account_id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("iis", $details_submitted, $payouts_enabled, $stripe_account_id);
    if ($stmt->execute()) {
        error_log("SUCCÈS: Mise à jour du compte Stripe Connect $stripe_account_id.");
    } else {
        error_log("Webhook DB Error: Échec de la mise à jour du compte Connect $stripe_account_id. Erreur: " . $stmt->error);
    }
    $stmt->close();
    $conn->close();

} else {
    // Log si ce webhook reçoit un événement inattendu.
    error_log('Événement non géré reçu par le webhook Connect: ' . $event->type);
}

// Répondre 200 à Stripe pour confirmer la bonne réception.
http_response_code(200);
echo json_encode(['status' => 'success']);

?>
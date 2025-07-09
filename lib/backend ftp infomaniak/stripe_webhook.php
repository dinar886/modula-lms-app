<?php
// Fichier: /api/v1/stripe_webhook.php
// Description: Webhook unifié qui gère les événements Stripe.

require_once __DIR__ . '/vendor/autoload.php';
require_once 'config.php'; // Charge la config BDD et les clés Stripe

// Initialisation de Stripe avec la clé secrète du fichier de configuration.
\Stripe\Stripe::setApiKey($stripeSecretKey);

// Le secret du webhook est maintenant chargé depuis config.php.
$endpoint_secret = $stripeWebhookSecret;

$payload = @file_get_contents('php://input');
$sig_header = $_SERVER['HTTP_STRIPE_SIGNATURE'];
$event = null;

try {
    // Vérification de la signature du webhook avec le secret de config.php.
    $event = \Stripe\Webhook::constructEvent(
        $payload, $sig_header, $endpoint_secret
    );
} catch(\UnexpectedValueException $e) {
    // Payload JSON invalide
    http_response_code(400);
    exit();
} catch(\Stripe\Exception\SignatureVerificationException $e) {
    // Signature invalide
    http_response_code(400);
    exit();
}

// Connexion à la base de données
$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    exit();
}
$conn->set_charset("utf8mb4");

// Traitement des événements
switch ($event->type) {
    // Cas 1 : Un paiement de cours est réussi
    case 'checkout.session.completed':
        $session = $event->data->object;
        $user_id = $session->metadata->user_id;
        $course_id = $session->metadata->course_id;

        if ($user_id && $course_id) {
            $sql = "INSERT INTO enrollments (user_id, course_id) VALUES (?, ?) ON DUPLICATE KEY UPDATE enrollment_date = NOW()";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("ii", $user_id, $course_id);
            $stmt->execute();
            $stmt->close();
        }
        break;

    // Cas 2 : Un compte connecté (formateur) est mis à jour
    case 'account.updated':
        $account = $event->data->object;
        $stripe_account_id = $account->id;

        $details_submitted = $account->details_submitted ? 1 : 0;
        $payouts_enabled = $account->payouts_enabled ? 1 : 0;

        // Mise à jour de la base de données avec le statut réel de Stripe.
        $sql = "UPDATE user_stripe_accounts SET details_submitted = ?, payouts_enabled = ? WHERE stripe_account_id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("iis", $details_submitted, $payouts_enabled, $stripe_account_id);
        $stmt->execute();
        $stmt->close();
        break;

    // Ajoutez d'autres cas pour d'autres événements si nécessaire.
}

$conn->close();
// Répondre 200 à Stripe pour confirmer la bonne réception.
http_response_code(200);
?>

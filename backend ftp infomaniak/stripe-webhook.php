// backend ftp infomaniak/stripe-webhook.php
<?php
require_once 'config.php';
require_once 'vendor/autoload.php';

\Stripe\Stripe::setApiKey($stripeSecretKey);

$payload = @file_get_contents('php://input');
$event = null;

try {
    $event = \Stripe\Event::constructFrom(
        json_decode($payload, true)
    );
} catch(\UnexpectedValueException $e) {
    // Invalid payload
    http_response_code(400);
    exit();
}

// Gérer l'événement
switch ($event->type) {
    case 'checkout.session.completed':
        $session = $event->data->object;
        // Logique métier :
        // 1. Récupérez l'ID de l'étudiant et l'ID du cours depuis les métadonnées de la session (à ajouter lors de la création de la session)
        // 2. Mettez à jour votre base de données pour enregistrer que cet étudiant a acheté ce cours
        // (ex: INSERT INTO user_courses ...)
        break;
    // ... gérez d'autres types d'événements si nécessaire
    default:
        // Événement inattendu
}

http_response_code(200);
?>
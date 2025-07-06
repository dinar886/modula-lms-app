// backend ftp infomaniak/create-stripe-account.php

<?php
header("Content-Type: application/json; charset=UTF-8");
require_once 'config.php';
require_once 'vendor/autoload.php'; // Inclure l'autoloader de Stripe

// Initialise Stripe avec votre clé secrète
\Stripe\Stripe::setApiKey($stripeSecretKey);

$data = json_decode(file_get_contents("php://input"));

// On a besoin de l'ID de l'utilisateur de notre base de données
if (empty($data->user_id) || empty($data->email)) {
    http_response_code(400);
    echo json_encode(['error' => 'Données manquantes']);
    exit;
}

try {
    // Créer un compte Connect Express pour l'instructeur
    $account = \Stripe\Account::create([
        'type' => 'express',
        'email' => $data->email,
        'capabilities' => [
            'card_payments' => ['requested' => true],
            'transfers' => ['requested' => true],
        ],
    ]);

    // Enregistrer l'ID du compte Stripe dans votre table 'users'
    $conn = new mysqli($servername, $username, $password, $dbname);
    $stmt = $conn->prepare("UPDATE users SET stripe_account_id = ? WHERE id = ?");
    $stmt->bind_param("si", $account->id, $data->user_id);
    $stmt->execute();
    $conn->close();

    // Créer un lien d'onboarding pour cet instructeur
    $accountLink = \Stripe\AccountLink::create([
        'account' => $account->id,
        'refresh_url' => $frontendUrl . '/onboarding-refresh',
        'return_url' => $frontendUrl . '/onboarding-success',
        'type' => 'account_onboarding',
    ]);

    // Renvoyer l'URL de ce lien au client Flutter
    http_response_code(200);
    echo json_encode(['onboarding_url' => $accountLink->url]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>
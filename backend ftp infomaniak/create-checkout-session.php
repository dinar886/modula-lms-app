// backend ftp infomaniak/create-checkout-session.php

<?php
header("Content-Type: application/json; charset=UTF-8");
require_once 'config.php';
require_once 'vendor/autoload.php';

\Stripe\Stripe::setApiKey($stripeSecretKey);

$data = json_decode(file_get_contents("php://input"));

if (empty($data->course_id) || empty($data->instructor_stripe_id)) {
    http_response_code(400);
    echo json_encode(['error' => 'Données de paiement manquantes.']);
    exit;
}

$course_id = $data->course_id;
$instructor_stripe_id = $data->instructor_stripe_id;

// Logique pour récupérer les détails du cours (prix, nom) depuis votre BDD
$conn = new mysqli($servername, $username, $password, $dbname);
$stmt = $conn->prepare("SELECT title, price FROM courses WHERE id = ?");
$stmt->bind_param("i", $course_id);
$stmt->execute();
$result = $stmt->get_result();
$course = $result->fetch_assoc();
$conn->close();

if (!$course) {
    http_response_code(404);
    echo json_encode(['error' => 'Cours non trouvé.']);
    exit;
}

// Frais de la plateforme (ex: 10%)
$application_fee_amount = (int)($course['price'] * 100 * 0.10);

try {
    $checkout_session = \Stripe\Checkout\Session::create([
        'payment_method_types' => ['card'],
        'line_items' => [[
            'price_data' => [
                'currency' => 'eur',
                'product_data' => [
                    'name' => $course['title'],
                ],
                'unit_amount' => (int)($course['price'] * 100), // Montant en centimes
            ],
            'quantity' => 1,
        ]],
        'mode' => 'payment', // 'payment' pour un paiement unique, 'subscription' pour un abonnement
        'success_url' => $frontendUrl . '/payment-success?session_id={CHECKOUT_SESSION_ID}',
        'cancel_url' => $frontendUrl . '/payment-cancel',
        'payment_intent_data' => [
            'application_fee_amount' => $application_fee_amount,
            'transfer_data' => [
                'destination' => $instructor_stripe_id,
            ],
        ],
    ]);

    http_response_code(200);
    echo json_encode(['session_id' => $checkout_session->id]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>
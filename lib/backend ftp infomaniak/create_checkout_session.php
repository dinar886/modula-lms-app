<?php
// Fichier: /api/v1/create_checkout_session.php
// Description: Crée une session de paiement Stripe Checkout pour un cours.

require_once __DIR__ . '/vendor/autoload.php';
require_once 'config.php'; // Charge la config BDD et les clés Stripe

header("Content-Type: application/json; charset=UTF-8");

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->course_id) || !isset($data->user_id)) {
    http_response_code(400);
    echo json_encode(['error' => 'Données manquantes.']);
    exit();
}

$course_id = (int)$data->course_id;
$user_id = (int)$data->user_id;

// Initialisation de Stripe avec la clé du fichier de configuration
\Stripe\Stripe::setApiKey($stripeSecretKey);

try {
    $conn = new mysqli($servername, $username, $password, $dbname);
    if ($conn->connect_error) {
        throw new Exception("Erreur de connexion BDD.");
    }
    $conn->set_charset("utf8mb4");

    // 1. Récupérer les détails du cours, l'ID du prix Stripe, et l'ID Stripe du formateur
    $stmt = $conn->prepare("
        SELECT c.title, c.price, c.stripe_price_id, usa.stripe_account_id
        FROM courses c
        JOIN user_courses uc ON c.id = uc.course_id
        JOIN user_stripe_accounts usa ON uc.user_id = usa.user_id
        WHERE c.id = ? AND usa.payouts_enabled = 1
    ");
    $stmt->bind_param("i", $course_id);
    $stmt->execute();
    $result = $stmt->get_result();

    if (!($course = $result->fetch_assoc())) {
        throw new Exception("Cours non trouvé, le formateur ne peut pas recevoir de paiements ou le prix Stripe est manquant.");
    }
    $stmt->close();
    $conn->close();

    $instructor_stripe_account_id = $course['stripe_account_id'];
    $stripe_price_id = $course['stripe_price_id'];
    $price_in_cents = (int)((float)$course['price'] * 100);

    // Si l'ID du prix est manquant pour une raison quelconque, on renvoie une erreur.
    if (empty($stripe_price_id)) {
        throw new Exception("L'ID du prix Stripe pour ce cours est introuvable.");
    }

    // 2. Calculer les frais de la plateforme (ex: 20%)
    $application_fee_amount = (int)($price_in_cents * 0.20);

    // 3. Créer la session de paiement en utilisant l'ID du prix
    $checkout_session = \Stripe\Checkout\Session::create([
        'payment_method_types' => ['card'],
        'line_items' => [[
            'price' => $stripe_price_id,
            'quantity' => 1,
        ]],
        'mode' => 'payment',
        // CORRECTION : On ajoute un paramètre `purchase_success=true` à l'URL de succès.
        'success_url' => 'https://modula-lms.com/my-courses?purchase_success=true&session_id={CHECKOUT_SESSION_ID}',
        'cancel_url' => 'https://modula-lms.com/marketplace?payment_cancelled=true',
        'payment_intent_data' => [
            'application_fee_amount' => $application_fee_amount,
            'transfer_data' => [
                'destination' => $instructor_stripe_account_id,
            ],
        ],
        'metadata' => [
            'user_id' => $user_id,
            'course_id' => $course_id
        ]
    ]);

    // On renvoie l'URL de la session complète au lieu de l'ID
    echo json_encode(['url' => $checkout_session->url]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>
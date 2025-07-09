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

    // 1. Récupérer les détails du cours et l'ID Stripe du formateur
    $stmt = $conn->prepare("
        SELECT c.title, c.price, usa.stripe_account_id
        FROM courses c
        JOIN user_courses uc ON c.id = uc.course_id
        JOIN user_stripe_accounts usa ON uc.user_id = usa.user_id
        WHERE c.id = ? AND usa.payouts_enabled = 1
    ");
    $stmt->bind_param("i", $course_id);
    $stmt->execute();
    $result = $stmt->get_result();

    if (!($course = $result->fetch_assoc())) {
        throw new Exception("Cours non trouvé ou le formateur ne peut pas recevoir de paiements.");
    }
    $stmt->close();
    $conn->close();

    $instructor_stripe_account_id = $course['stripe_account_id'];
    $price_in_cents = (int)($course['price'] * 100);

    // 2. Calculer les frais de la plateforme (ex: 20%)
    $application_fee_amount = (int)($price_in_cents * 0.20);

    // 3. Créer la session de paiement
    $checkout_session = \Stripe\Checkout\Session::create([
        'payment_method_types' => ['card'],
        'line_items' => [[
            'price_data' => [
                'currency' => 'eur',
                'product_data' => [
                    'name' => $course['title'],
                ],
                'unit_amount' => $price_in_cents,
            ],
            'quantity' => 1,
        ]],
        'mode' => 'payment',
        'success_url' => 'https://modula-lms.com/my-courses', // URL de redirection en cas de succès
        'cancel_url' => 'https://modula-lms.com/marketplace/course/' . $course_id, // URL en cas d'annulation
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

    echo json_encode(['id' => $checkout_session->id]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>

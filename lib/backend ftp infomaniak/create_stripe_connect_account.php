<?php
// Fichier: /api/v1/create_stripe_connect_account.php
// Description: Crée un compte Stripe Express et génère un lien d'onboarding.

// Inclusion de l'autoloader de Composer pour charger la librairie Stripe
require_once __DIR__ . '/vendor/autoload.php';

// Inclusion du fichier de configuration pour la base de données ET les clés Stripe
require_once 'config.php';

// Définition des en-têtes pour la réponse JSON
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Récupération des données POST envoyées depuis l'application Flutter
$data = json_decode(file_get_contents("php://input"));

// Vérification de la présence des données nécessaires
if (!isset($data->user_id) || !isset($data->email)) {
    http_response_code(400); // Bad Request
    echo json_encode(["message" => "L'ID et l'email de l'utilisateur sont requis."]);
    exit();
}

$user_id = (int)$data->user_id;
$email = $data->email;

try {
    // Initialisation du client Stripe avec la clé secrète depuis config.php
    \Stripe\Stripe::setApiKey($stripeSecretKey);

    // Connexion à la base de données
    $conn = new mysqli($servername, $username, $password, $dbname);
    if ($conn->connect_error) {
        throw new Exception("Erreur de connexion à la base de données: " . $conn->connect_error);
    }
    $conn->set_charset("utf8mb4");

    // 1. Vérifier si un compte Stripe existe déjà pour cet utilisateur dans votre base
    $stmt_check = $conn->prepare("SELECT stripe_account_id FROM user_stripe_accounts WHERE user_id = ?");
    $stmt_check->bind_param("i", $user_id);
    $stmt_check->execute();
    $result_check = $stmt_check->get_result();
    $stripe_account_id = null;

    if ($row = $result_check->fetch_assoc()) {
        $stripe_account_id = $row['stripe_account_id'];
    }
    $stmt_check->close();

    // 2. Si aucun compte n'existe, en créer un nouveau via l'API Stripe
    if (!$stripe_account_id) {
        $account = \Stripe\Account::create([
            'type' => 'express',
            'country' => 'FR', // Pays par défaut, à adapter si nécessaire
            'email' => $email,
            'capabilities' => [
                'card_payments' => ['requested' => true],
                'transfers' => ['requested' => true],
            ],
        ]);
        $stripe_account_id = $account->id;

        // Sauvegarder l'ID du nouveau compte dans votre table `user_stripe_accounts`
        $stmt_insert = $conn->prepare("INSERT INTO user_stripe_accounts (user_id, stripe_account_id) VALUES (?, ?)");
        $stmt_insert->bind_param("is", $user_id, $stripe_account_id);
        $stmt_insert->execute();
        $stmt_insert->close();
    }

    // 3. Créer le lien d'onboarding (Account Link) pour l'utilisateur
    $account_link = \Stripe\AccountLink::create([
        'account' => $stripe_account_id,
        'refresh_url' => 'https://modula-lms.com/profile', // URL si le lien a expiré
        'return_url' => 'https://modula-lms.com/profile?stripe_return=1', // URL de retour après la procédure
        'type' => 'account_onboarding',
    ]);

    $conn->close();

    // Renvoyer l'URL d'onboarding à l'application Flutter
    http_response_code(200); // OK
    echo json_encode(['onboarding_url' => $account_link->url]);

} catch (\Stripe\Exception\ApiErrorException $e) {
    // Gérer les erreurs spécifiques à l'API Stripe
    http_response_code($e->getHttpStatus());
    echo json_encode([
        'message' => 'Erreur de l\'API Stripe.',
        'error' => $e->getMessage()
    ]);
} catch (Exception $e) {
    // Gérer les autres erreurs (connexion BDD, etc.)
    http_response_code(500); // Internal Server Error
    echo json_encode([
        'message' => 'Une erreur interne est survenue.',
        'error' => $e->getMessage()
    ]);
}
?>

<?php
// Fichier : /api/v1/get_stripe_account_status.php
// Rôle : Récupère le statut du compte Stripe d'un utilisateur directement depuis la base de données locale.
// La mise à jour est désormais gérée exclusivement par le webhook stripe_webhook.php.

// Définit le type de contenu de la réponse comme étant du JSON.
header("Content-Type: application/json");
// Autorise les requêtes depuis n'importe quelle origine (utile pour le développement avec Flutter).
header("Access-Control-Allow-Origin: *");
// Autorise les en-têtes nécessaires pour les requêtes.
header("Access-Control-Allow-Headers: Content-Type, Authorization");

// Inclusion du fichier de configuration pour la connexion à la base de données.
require_once 'config.php';

// On s'assure que l'ID de l'utilisateur a bien été envoyé avec la requête.
if (!isset($_GET['user_id'])) {
    // Si l'ID est manquant, on renvoie une erreur "Bad Request".
    http_response_code(400); 
    echo json_encode(['error' => 'Le paramètre user_id est manquant.']);
    exit; // Arrête l'exécution du script.
}

$user_id = $_GET['user_id'];

// Établissement de la connexion à la base de données.
$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    // Si la connexion échoue, on renvoie une erreur "Internal Server Error".
    http_response_code(500);
    echo json_encode(['error' => 'Erreur de connexion à la base de données.']);
    exit();
}
// Définit le jeu de caractères pour la connexion.
$conn->set_charset("utf8mb4");

// Préparation de la requête SQL pour LIRE les informations du compte.
// On sélectionne les colonnes pertinentes de la table user_stripe_accounts pour l'utilisateur donné.
$sql = "SELECT stripe_account_id, details_submitted, payouts_enabled FROM user_stripe_accounts WHERE user_id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();

// On vérifie si un résultat a été trouvé.
if ($result->num_rows > 0) {
    // Si un compte est trouvé, on récupère les données.
    $account_status = $result->fetch_assoc();
    
    // Convertit les valeurs de la base de données (0 ou 1) en booléens (false ou true) pour le JSON.
    $account_status['details_submitted'] = (bool)$account_status['details_submitted'];
    $account_status['payouts_enabled'] = (bool)$account_status['payouts_enabled'];

    // On renvoie une réponse "OK" avec les données du compte.
    http_response_code(200);
    echo json_encode($account_status);
} else {
    // Si aucun compte n'est trouvé pour cet utilisateur, on renvoie une erreur "Not Found".
    // L'application Flutter saura ainsi que l'utilisateur doit créer son compte.
    http_response_code(404);
    echo json_encode(['error' => 'Aucun compte Stripe trouvé pour cet utilisateur.']);
}

// On ferme le statement et la connexion pour libérer les ressources.
$stmt->close();
$conn->close();
?>
<?php
// Fichier : /api/v1/get_instructor_dashboard_stats.php
// Description : Récupère les statistiques clés pour le tableau de bord de l'instructeur.

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");

require_once 'config.php';
require_once __DIR__ . '/vendor/autoload.php';

// On s'assure que l'ID de l'instructeur est bien fourni.
if (!isset($_GET['instructor_id']) || empty($_GET['instructor_id'])) {
    http_response_code(400);
    echo json_encode(["error" => "Le paramètre 'instructor_id' est requis."]);
    exit();
}
$instructor_id = (int)$_GET['instructor_id'];

// Initialisation de la réponse
$stats = [
    'total_students' => 0,
    'pending_submissions' => 0,
    'recent_revenue' => 0.0
];

// --- 1. Connexion à la base de données ---
$conn = new mysqli($servername, $username, $password, $dbname);
// --- CORRECTION : Utilisation de utf8mb4 ---
$conn->set_charset("utf8mb4");

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["error" => "Erreur de connexion à la base de données: " . $conn->connect_error]);
    exit();
}

// --- 2. Calculer le nombre total d'élèves uniques ---
$sql_students = "
    SELECT COUNT(DISTINCT e.user_id) as student_count
    FROM user_courses uc
    JOIN enrollments e ON uc.course_id = e.course_id
    WHERE uc.user_id = ?
";
$stmt_students = $conn->prepare($sql_students);
if ($stmt_students) {
    $stmt_students->bind_param("i", $instructor_id);
    $stmt_students->execute();
    $result_students = $stmt_students->get_result();
    if ($row = $result_students->fetch_assoc()) {
        $stats['total_students'] = (int)$row['student_count'];
    }
    $stmt_students->close();
}

// --- 3. Calculer le nombre de rendus en attente ---
$sql_submissions = "
    SELECT COUNT(s.id) as pending_count
    FROM submissions s
    JOIN user_courses uc ON s.course_id = uc.course_id
    WHERE uc.user_id = ? AND s.status = 'submitted'
";
$stmt_submissions = $conn->prepare($sql_submissions);
if ($stmt_submissions) {
    $stmt_submissions->bind_param("i", $instructor_id);
    $stmt_submissions->execute();
    $result_submissions = $stmt_submissions->get_result();
    if ($row = $result_submissions->fetch_assoc()) {
        $stats['pending_submissions'] = (int)$row['pending_count'];
    }
    $stmt_submissions->close();
}


// --- 4. Récupérer les revenus récents depuis Stripe (7 derniers jours) ---
try {
    \Stripe\Stripe::setApiKey($stripeSecretKey);

    // On cherche l'ID du compte Stripe de l'instructeur
    $stmt_stripe = $conn->prepare("SELECT stripe_account_id FROM user_stripe_accounts WHERE user_id = ?");
    $stmt_stripe->bind_param("i", $instructor_id);
    $stmt_stripe->execute();
    $result_stripe = $stmt_stripe->get_result();
    $stripe_account_id = null;
    if ($row = $result_stripe->fetch_assoc()) {
        $stripe_account_id = $row['stripe_account_id'];
    }
    $stmt_stripe->close();

    if ($stripe_account_id) {
        $seven_days_ago = strtotime('-7 days');
        
        // On récupère les transferts vers le compte de l'instructeur
        $transfers = \Stripe\Transfer::all([
            'destination' => $stripe_account_id,
            'created' => [
                'gte' => $seven_days_ago,
            ],
            'limit' => 100 // Limite pour la requête
        ]);

        $total_revenue = 0;
        foreach ($transfers->data as $transfer) {
            $total_revenue += $transfer->amount;
        }

        // Le montant est en centimes, on le convertit en euros
        $stats['recent_revenue'] = $total_revenue / 100.0;
    }

} catch (\Stripe\Exception\ApiErrorException $e) {
    // Ne pas bloquer la réponse si Stripe échoue, on logue l'erreur
    error_log("Stripe API error for instructor $instructor_id: " . $e->getMessage());
} catch (Exception $e) {
    error_log("General error for instructor $instructor_id: " . $e->getMessage());
}


$conn->close();

// --- 5. Renvoyer la réponse finale ---
http_response_code(200);
echo json_encode($stats);

?>
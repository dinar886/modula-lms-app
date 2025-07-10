-- phpMyAdmin SQL Dump
-- version 4.9.6
-- https://www.phpmyadmin.net/
--
-- Hôte : vd9wgs.myd.infomaniak.com
-- Généré le :  ven. 11 juil. 2025 à 01:38
-- Version du serveur :  10.6.18-MariaDB-deb11-log
-- Version de PHP :  7.4.33

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de données :  `vd9wgs_modula`
--

-- --------------------------------------------------------

--
-- Structure de la table `courses`
--

CREATE TABLE `courses` (
  `id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `author` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `image_url` varchar(255) NOT NULL,
  `price` decimal(10,2) NOT NULL,
  `color` varchar(7) DEFAULT '#005A9C',
  `stripe_product_id` varchar(255) DEFAULT NULL COMMENT 'ID du produit sur Stripe',
  `stripe_price_id` varchar(255) DEFAULT NULL COMMENT 'ID du prix sur Stripe',
  `category` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Déchargement des données de la table `courses`
--

INSERT INTO `courses` (`id`, `title`, `author`, `description`, `image_url`, `price`, `color`, `stripe_product_id`, `stripe_price_id`, `category`, `created_at`) VALUES
(11, 'Cours Arabe', 'a', 'ii', 'https://modula-lms.com/uploads/courses/course_686c2a90c82241.78323660.jpg', '25.00', '#F32124', NULL, NULL, 'Développement Web', '2025-07-10 20:54:37'),
(12, 'zz', 'a', 'zhh', 'https://modula-lms.com/uploads/courses/course_686c2aa24e2ec6.53784212.jpg', '25.00', '#005A9C', NULL, NULL, 'Design', '2025-07-10 20:54:37'),
(13, 'ca marche', 'a', 'ou pas', 'https://placehold.co/600x400/FF00BD/FFFFFF/png?text=ca+marche', '22.00', '#FF00BD', 'prod_SeNmF1TTcefj5c', 'price_1Rj516Q3IcvreDHMTnFpC45M', 'Business', '2025-07-10 20:54:37');

--
-- Index pour les tables déchargées
--

--
-- Index pour la table `courses`
--
ALTER TABLE `courses`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT pour les tables déchargées
--

--
-- AUTO_INCREMENT pour la table `courses`
--
ALTER TABLE `courses`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

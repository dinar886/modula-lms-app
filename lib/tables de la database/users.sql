-- phpMyAdmin SQL Dump
-- version 4.9.6
-- https://www.phpmyadmin.net/
--
-- Hôte : vd9wgs.myd.infomaniak.com
-- Généré le :  mar. 08 juil. 2025 à 07:29
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
-- Structure de la table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `profile_image_url` varchar(255) DEFAULT NULL COMMENT 'URL vers l''image de profil de l''utilisateur',
  `password` varchar(255) NOT NULL,
  `role` enum('learner','instructor') NOT NULL DEFAULT 'learner',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Déchargement des données de la table `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `profile_image_url`, `password`, `role`, `created_at`) VALUES
(1, 'Nardihg', 'nardih1234@gmail.com', 'https://modula-lms.com/uploads/profile_images/user_1_1751819450.jpg', '$2y$10$m4sEMRDA02muYcWz3YreC.eInleiIbW8pccEleT.1STj5DwqokNNG', 'instructor', '2025-07-02 13:00:35'),
(2, 'wesh', 'a@gmail.com', NULL, '$2y$10$oLamVYYCKlKqyerNZVBsO.70ceI3825mmswmjaWRNQwntcmda44.S', 'learner', '2025-07-02 13:13:21'),
(3, 'a', 'ab@gmail.com', 'https://modula-lms.com/uploads/profile_images/user_3_1751919166.jpg', '$2y$10$u6g0PZR2kp9FgXWVvPWdEumxPVH9JmNj/WSPrSxupwkWZzlGqj.Zq', 'instructor', '2025-07-06 13:10:33'),
(4, 'b', 'b@gmail.com', NULL, '$2y$10$8O6PTYRfaCtG62E9xxKZ2OZ8D3KsjMsGCDkqilpZ1DcodFgYdQdPi', 'learner', '2025-07-07 20:47:55');

--
-- Index pour les tables déchargées
--

--
-- Index pour la table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT pour les tables déchargées
--

--
-- AUTO_INCREMENT pour la table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

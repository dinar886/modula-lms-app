-- phpMyAdmin SQL Dump
-- version 4.9.6
-- https://www.phpmyadmin.net/
--
-- Hôte : vd9wgs.myd.infomaniak.com
-- Généré le :  mar. 08 juil. 2025 à 16:40
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
-- Structure de la table `lesson_content_blocks`
--

CREATE TABLE `lesson_content_blocks` (
  `id` int(11) NOT NULL,
  `lesson_id` int(11) NOT NULL,
  `block_type` enum('text','video','image','document','quiz','submission_placeholder','unknown') NOT NULL,
  `content` text NOT NULL,
  `order_index` int(11) NOT NULL,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'Stocke des données supplémentaires comme le style du texte ou la taille de l''image' CHECK (json_valid(`metadata`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `lesson_content_blocks`
--

INSERT INTO `lesson_content_blocks` (`id`, `lesson_id`, `block_type`, `content`, `order_index`, `metadata`) VALUES
(94, 32, 'text', 'yo', 0, '\"{\\\"style\\\":\\\"h1\\\",\\\"content\\\":\\\"yo\\\"}\"'),
(95, 32, 'quiz', '4', 1, '\"{\\\"max_attempts\\\":-1}\"'),
(132, 33, 'text', 'devoir 1', 0, '\"{\\\"style\\\":\\\"h1\\\",\\\"content\\\":\\\"devoir 1\\\"}\"'),
(133, 33, 'quiz', '5', 1, '\"{\\\"max_attempts\\\":0}\"'),
(134, 33, 'document', 'https://modula-lms.com/uploads/file_686ca24d677b46.92455082.pdf', 2, '\"{}\"'),
(135, 33, 'submission_placeholder', '', 3, '\"{}\"'),
(136, 34, 'text', 'premier conseil\n', 0, '\"{\\\"style\\\":\\\"h1\\\",\\\"content\\\":\\\"premier conseil\\\\n\\\"}\"'),
(137, 34, 'image', 'https://modula-lms.com/uploads/file_686c317b6743e5.70146294.jpg', 1, '\"{\\\"width\\\":100.0,\\\"alignment\\\":\\\"center\\\"}\"'),
(138, 34, 'quiz', '6', 2, '\"{\\\"max_attempts\\\":-1}\"'),
(139, 34, 'submission_placeholder', '', 3, '\"{}\"'),
(142, 35, 'text', 'jugh', 0, '\"{\\\"style\\\":\\\"paragraph\\\",\\\"content\\\":\\\"jugh\\\"}\"'),
(143, 35, 'submission_placeholder', '', 1, '\"{}\"'),
(144, 35, 'quiz', '7', 2, '\"{\\\"max_attempts\\\":-1}\"'),
(145, 35, 'image', 'https://modula-lms.com/uploads/file_686d262ec3c4a0.04514383.jpg', 3, '\"{\\\"width\\\":60.0,\\\"alignment\\\":\\\"center\\\"}\"');

--
-- Index pour les tables déchargées
--

--
-- Index pour la table `lesson_content_blocks`
--
ALTER TABLE `lesson_content_blocks`
  ADD PRIMARY KEY (`id`),
  ADD KEY `lesson_id` (`lesson_id`);

--
-- AUTO_INCREMENT pour les tables déchargées
--

--
-- AUTO_INCREMENT pour la table `lesson_content_blocks`
--
ALTER TABLE `lesson_content_blocks`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=146;

--
-- Contraintes pour les tables déchargées
--

--
-- Contraintes pour la table `lesson_content_blocks`
--
ALTER TABLE `lesson_content_blocks`
  ADD CONSTRAINT `lesson_content_blocks_ibfk_1` FOREIGN KEY (`lesson_id`) REFERENCES `lessons` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

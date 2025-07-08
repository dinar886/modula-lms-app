-- phpMyAdmin SQL Dump
-- version 4.9.6
-- https://www.phpmyadmin.net/
--
-- Hôte : vd9wgs.myd.infomaniak.com
-- Généré le :  mar. 08 juil. 2025 à 20:38
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
-- Structure de la table `quiz_attempts`
--

CREATE TABLE `quiz_attempts` (
  `id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `quiz_id` int(11) NOT NULL,
  `lesson_id` int(11) NOT NULL,
  `score` decimal(5,2) NOT NULL,
  `total_questions` int(11) NOT NULL COMMENT 'Nombre total de questions dans le quiz',
  `correct_answers` int(11) NOT NULL COMMENT 'Nombre de réponses correctes de l''étudiant',
  `attempt_date` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci COMMENT='Enregistre chaque tentative d''un étudiant à un quiz.';

--
-- Déchargement des données de la table `quiz_attempts`
--

INSERT INTO `quiz_attempts` (`id`, `student_id`, `quiz_id`, `lesson_id`, `score`, `total_questions`, `correct_answers`, `attempt_date`) VALUES
(3, 3, 5, 33, '100.00', 0, 0, '2025-07-07 20:45:06'),
(4, 3, 6, 34, '0.00', 0, 0, '2025-07-07 20:45:48'),
(5, 4, 4, 32, '0.00', 0, 0, '2025-07-08 02:03:53'),
(6, 4, 5, 33, '100.00', 0, 0, '2025-07-08 02:04:01'),
(7, 3, 7, 35, '0.00', 0, 0, '2025-07-08 16:34:24'),
(8, 3, 8, 37, '100.00', 0, 0, '2025-07-08 18:03:14'),
(9, 3, 8, 37, '100.00', 0, 0, '2025-07-08 18:03:27'),
(10, 3, 10, 37, '0.00', 0, 0, '2025-07-08 18:16:00'),
(11, 3, 10, 37, '100.00', 0, 0, '2025-07-08 18:16:23'),
(12, 3, 11, 38, '50.00', 0, 0, '2025-07-08 18:17:27'),
(13, 3, 11, 38, '10.00', 2, 1, '2025-07-08 18:35:39');

--
-- Index pour les tables déchargées
--

--
-- Index pour la table `quiz_attempts`
--
ALTER TABLE `quiz_attempts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `student_id` (`student_id`),
  ADD KEY `quiz_id` (`quiz_id`),
  ADD KEY `lesson_id` (`lesson_id`);

--
-- AUTO_INCREMENT pour les tables déchargées
--

--
-- AUTO_INCREMENT pour la table `quiz_attempts`
--
ALTER TABLE `quiz_attempts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- Contraintes pour les tables déchargées
--

--
-- Contraintes pour la table `quiz_attempts`
--
ALTER TABLE `quiz_attempts`
  ADD CONSTRAINT `quiz_attempts_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `quiz_attempts_ibfk_2` FOREIGN KEY (`quiz_id`) REFERENCES `quizzes` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `quiz_attempts_ibfk_3` FOREIGN KEY (`lesson_id`) REFERENCES `lessons` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

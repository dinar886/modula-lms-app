-- phpMyAdmin SQL Dump
-- version 4.9.6
-- https://www.phpmyadmin.net/
--
-- Hôte : vd9wgs.myd.infomaniak.com
-- Généré le :  ven. 11 juil. 2025 à 20:39
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
-- Structure de la table `user_lesson_completions`
--

CREATE TABLE `user_lesson_completions` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `lesson_id` int(11) NOT NULL,
  `course_id` int(11) NOT NULL,
  `completion_date` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Index pour les tables déchargées
--

--
-- Index pour la table `user_lesson_completions`
--
ALTER TABLE `user_lesson_completions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `user_lesson_unique` (`user_id`,`lesson_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `lesson_id` (`lesson_id`),
  ADD KEY `course_id` (`course_id`);

--
-- AUTO_INCREMENT pour les tables déchargées
--

--
-- AUTO_INCREMENT pour la table `user_lesson_completions`
--
ALTER TABLE `user_lesson_completions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- Contraintes pour les tables déchargées
--

--
-- Contraintes pour la table `user_lesson_completions`
--
ALTER TABLE `user_lesson_completions`
  ADD CONSTRAINT `user_lesson_completions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `user_lesson_completions_ibfk_2` FOREIGN KEY (`lesson_id`) REFERENCES `lessons` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `user_lesson_completions_ibfk_3` FOREIGN KEY (`course_id`) REFERENCES `courses` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

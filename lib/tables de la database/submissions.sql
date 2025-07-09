-- phpMyAdmin SQL Dump
-- version 4.9.6
-- https://www.phpmyadmin.net/
--
-- Hôte : vd9wgs.myd.infomaniak.com
-- Généré le :  mer. 09 juil. 2025 à 17:31
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
-- Structure de la table `submissions`
--

CREATE TABLE `submissions` (
  `id` int(11) NOT NULL,
  `lesson_id` int(11) NOT NULL COMMENT 'La leçon de type devoir/contrôle associée',
  `student_id` int(11) NOT NULL COMMENT 'L''étudiant qui a soumis le travail',
  `course_id` int(11) NOT NULL COMMENT 'Le cours concerné, pour faciliter les requêtes',
  `submission_date` datetime NOT NULL DEFAULT current_timestamp() COMMENT 'Date de soumission',
  `content` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT 'Contenu JSON de la soumission de l''étudiant' CHECK (json_valid(`content`)),
  `grade` decimal(5,2) DEFAULT NULL COMMENT 'Note attribuée par l''instructeur',
  `status` varchar(50) NOT NULL DEFAULT 'submitted' COMMENT 'Statut: submitted, graded, returned',
  `instructor_feedback` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'Contenu JSON du feedback de l''instructeur' CHECK (json_valid(`instructor_feedback`)),
  `graded_date` datetime DEFAULT NULL COMMENT 'Date de la correction'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Tableau pour les rendus des devoirs et contrôles';

--
-- Déchargement des données de la table `submissions`
--

INSERT INTO `submissions` (`id`, `lesson_id`, `student_id`, `course_id`, `submission_date`, `content`, `grade`, `status`, `instructor_feedback`, `graded_date`) VALUES
(1, 33, 3, 11, '2025-07-07 22:45:10', '[]', NULL, 'submitted', NULL, NULL),
(2, 34, 3, 11, '2025-07-07 22:45:50', '[]', NULL, 'submitted', NULL, NULL),
(3, 33, 4, 11, '2025-07-08 04:04:03', '[]', NULL, 'submitted', NULL, NULL),
(4, 35, 3, 11, '2025-07-08 19:53:17', '[{\"block_type\":\"document\",\"content\":\"https:\\/\\/modula-lms.com\\/uploads\\/file_686d5b0b715624.35150595.pdf\",\"order_index\":0,\"metadata\":\"{\\\"fileName\\\":\\\"Re\\u0301sume\\u0301 AH.pdf\\\"}\"}]', NULL, 'submitted', NULL, NULL),
(5, 37, 3, 11, '2025-07-08 20:16:03', '[]', NULL, 'submitted', NULL, NULL),
(6, 38, 3, 11, '2025-07-08 20:36:07', '[]', NULL, 'submitted', NULL, NULL),
(7, 40, 3, 11, '2025-07-09 17:18:48', '[{\"id\":0,\"localId\":\"1752074685208\",\"block_type\":\"document\",\"content\":\"https:\\/\\/modula-lms.com\\/uploads\\/file_686e88568dd288.33925532.pdf\",\"order_index\":0,\"metadata\":\"{\\\"fileName\\\":\\\"Projet site e\\u0301cole arabe.pdf\\\"}\"}]', NULL, 'graded', '{\"comments\":{},\"files\":[{\"id\":0,\"localId\":\"1752075154288\",\"block_type\":\"document\",\"content\":\"https:\\/\\/modula-lms.com\\/uploads\\/file_686e8a2b99ce25.42206264.jpg\",\"order_index\":0,\"metadata\":\"{\\\"fileName\\\":\\\"image_picker_43484361-7ABE-47DE-83FD-B0237299888A-40478-00001EE0DA424045.jpg\\\"}\"}],\"general_comment\":\"\"}', '2025-07-09 17:26:37'),
(8, 40, 4, 11, '2025-07-09 17:27:24', '[{\"id\":0,\"localId\":\"1752075201139\",\"block_type\":\"document\",\"content\":\"https:\\/\\/modula-lms.com\\/uploads\\/file_686e8a5a78baa1.66046527.pdf\",\"order_index\":0,\"metadata\":\"{\\\"fileName\\\":\\\"Questions Ge\\u0301ne\\u0301rales_Oral_2e\\u0300me anne\\u0301e_Ge\\u0301otech.pdf\\\"}\"}]', NULL, 'graded', '{\"comments\":{},\"files\":[{\"id\":0,\"localId\":\"1752075234836\",\"block_type\":\"document\",\"content\":\"https:\\/\\/modula-lms.com\\/uploads\\/file_686e8a7c379bb6.24274903.jpg\",\"order_index\":0,\"metadata\":\"{\\\"fileName\\\":\\\"image_picker_8AC98F06-0E8D-4711-B567-3041711B2AC4-40478-00001EE14D7BCBF1.jpg\\\"}\"}],\"general_comment\":\"\"}', '2025-07-09 17:28:00');

--
-- Index pour les tables déchargées
--

--
-- Index pour la table `submissions`
--
ALTER TABLE `submissions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `lesson_id` (`lesson_id`),
  ADD KEY `student_id` (`student_id`),
  ADD KEY `course_id` (`course_id`);

--
-- AUTO_INCREMENT pour les tables déchargées
--

--
-- AUTO_INCREMENT pour la table `submissions`
--
ALTER TABLE `submissions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- Contraintes pour les tables déchargées
--

--
-- Contraintes pour la table `submissions`
--
ALTER TABLE `submissions`
  ADD CONSTRAINT `submissions_ibfk_1` FOREIGN KEY (`lesson_id`) REFERENCES `lessons` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `submissions_ibfk_2` FOREIGN KEY (`student_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `submissions_ibfk_3` FOREIGN KEY (`course_id`) REFERENCES `courses` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

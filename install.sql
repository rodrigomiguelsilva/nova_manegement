CREATE TABLE IF NOT EXISTS `nova_doorlocks` (
  `id` int NOT NULL AUTO_INCREMENT,
  `label` varchar(100) NOT NULL,
  `model` varchar(100) NOT NULL,
  `coords` longtext NOT NULL,
  `jobs` longtext NOT NULL,
  `locked` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
);

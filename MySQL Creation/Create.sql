-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

-- -----------------------------------------------------
-- Schema mydb
-- -----------------------------------------------------
-- -----------------------------------------------------
-- Schema plexPlaying
-- -----------------------------------------------------
DROP SCHEMA IF EXISTS `plexPlaying` ;

-- -----------------------------------------------------
-- Schema plexPlaying
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `plexPlaying` DEFAULT CHARACTER SET latin1 ;
USE `plexPlaying` ;

-- -----------------------------------------------------
-- Table `plexPlaying`.`plexUsers`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `plexPlaying`.`plexUsers` ;

CREATE TABLE IF NOT EXISTS `plexPlaying`.`plexUsers` (
  `idUser` INT(11) NOT NULL AUTO_INCREMENT,
  `UserName` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`idUser`, `UserName`),
  UNIQUE INDEX `UserName_UNIQUE` (`UserName` ASC),
  INDEX `User_ID_idx` (`idUser` ASC))
ENGINE = InnoDB
AUTO_INCREMENT = 0
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `plexPlaying`.`Device`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `plexPlaying`.`Device` ;

CREATE TABLE IF NOT EXISTS `plexPlaying`.`Device` (
  `idDevice` INT(11) NOT NULL AUTO_INCREMENT,
  `idUser` INT(11) NOT NULL DEFAULT '0',
  `DeviceName` VARCHAR(45) NULL DEFAULT NULL,
  `Platform` VARCHAR(45) NULL DEFAULT NULL,
  `Product` VARCHAR(45) NULL DEFAULT NULL,
  PRIMARY KEY (`idDevice`, `idUser`),
  UNIQUE INDEX `Device` (`idUser` ASC, `DeviceName` ASC),
  INDEX `FK_DeviceOwner_idx` (`idUser` ASC),
  CONSTRAINT `FK_DeviceOwner`
    FOREIGN KEY (`idUser`)
    REFERENCES `plexPlaying`.`plexUsers` (`idUser`)
    ON DELETE NO ACTION
    ON UPDATE CASCADE)
ENGINE = InnoDB
AUTO_INCREMENT = 0
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `plexPlaying`.`plexServer`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `plexPlaying`.`plexServer` ;

CREATE TABLE IF NOT EXISTS `plexPlaying`.`plexServer` (
  `idServer` INT(11) NOT NULL AUTO_INCREMENT,
  `ServerOwnerID` INT(11) NULL DEFAULT NULL,
  `ServerName` VARCHAR(45) NULL DEFAULT NULL,
  `ServerURL` VARCHAR(250) NULL DEFAULT NULL,
  PRIMARY KEY (`idServer`),
  UNIQUE INDEX `ServerName_UNIQUE` (`ServerName` ASC),
  UNIQUE INDEX `ServerURL_UNIQUE` (`ServerURL` ASC),
  INDEX `FK_ServerOwner_idx` (`ServerOwnerID` ASC),
  CONSTRAINT `FK_ServerOwner`
    FOREIGN KEY (`ServerOwnerID`)
    REFERENCES `plexPlaying`.`plexUsers` (`idUser`)
    ON DELETE SET NULL
    ON UPDATE CASCADE)
ENGINE = InnoDB
AUTO_INCREMENT = 0
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `plexPlaying`.`MediaFile`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `plexPlaying`.`MediaFile` ;

CREATE TABLE IF NOT EXISTS `plexPlaying`.`MediaFile` (
  `idMediaFile` INT(11) NOT NULL AUTO_INCREMENT,
  `MediaFileName` VARCHAR(100) NULL DEFAULT NULL,
  `MediaFilePath` VARCHAR(250) NULL DEFAULT NULL,
  `idServer` INT(11) NULL DEFAULT NULL,
  PRIMARY KEY (`idMediaFile`),
  UNIQUE INDEX `MediaFiles` (`MediaFileName` ASC, `MediaFilePath` ASC),
  INDEX `FK_Server_idx` (`idServer` ASC),
  CONSTRAINT `FK_ServerID`
    FOREIGN KEY (`idServer`)
    REFERENCES `plexPlaying`.`plexServer` (`idServer`)
    ON DELETE SET NULL
    ON UPDATE CASCADE)
ENGINE = InnoDB
AUTO_INCREMENT = 0
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `plexPlaying`.`watchedItem`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `plexPlaying`.`watchedItem` ;

CREATE TABLE IF NOT EXISTS `plexPlaying`.`watchedItem` (
  `idWatched` INT(11) NOT NULL AUTO_INCREMENT,
  `Start_Time` DATETIME NULL DEFAULT NULL,
  `End_Time` DATETIME NULL DEFAULT NULL,
  `ShowID` INT(11) NULL DEFAULT NULL,
  `idUser` INT(11) NOT NULL,
  `idDevice` INT(11) NOT NULL,
  `idServer` INT(11) NULL DEFAULT NULL,
  PRIMARY KEY (`idWatched`, `idUser`, `idDevice`),
  INDEX `idDevice_idx` (`idDevice` ASC),
  INDEX `idUser_idx` (`idUser` ASC),
  INDEX `idMediaFile_idx` (`ShowID` ASC),
  INDEX `FK_User_idx` (`idUser` ASC),
  INDEX `FK_Device_idx` (`idDevice` ASC),
  INDEX `FK_Show_idx` (`ShowID` ASC),
  INDEX `FK_Server_idx` (`idServer` ASC),
  CONSTRAINT `FK_User`
    FOREIGN KEY (`idUser`)
    REFERENCES `plexPlaying`.`plexUsers` (`idUser`)
    ON DELETE NO ACTION
    ON UPDATE CASCADE,
  CONSTRAINT `FK_Device`
    FOREIGN KEY (`idDevice`)
    REFERENCES `plexPlaying`.`Device` (`idDevice`)
    ON DELETE NO ACTION
    ON UPDATE CASCADE,
  CONSTRAINT `FK_Server`
    FOREIGN KEY (`idServer`)
    REFERENCES `plexPlaying`.`plexServer` (`idServer`)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  CONSTRAINT `FK_Show`
    FOREIGN KEY (`ShowID`)
    REFERENCES `plexPlaying`.`MediaFile` (`idMediaFile`)
    ON DELETE SET NULL
    ON UPDATE CASCADE)
ENGINE = InnoDB
AUTO_INCREMENT = 0
DEFAULT CHARACTER SET = latin1;

USE `plexPlaying` ;

-- -----------------------------------------------------
-- View `plexPlaying`.`Currently_Watching`
-- -----------------------------------------------------
DROP VIEW IF EXISTS `plexPlaying`.`Currently_Watching` ;
USE `plexPlaying`;
CREATE  OR REPLACE ALGORITHM=UNDEFINED DEFINER=`Ben`@`%` SQL SECURITY DEFINER VIEW `plexPlaying`.`Currently_Watching` AS select `plexPlaying`.`plexUsers`.`UserName` AS `User Name`,`plexPlaying`.`MediaFile`.`MediaFileName` AS `Show`,`plexPlaying`.`Device`.`DeviceName` AS `Device`,`plexPlaying`.`plexServer`.`ServerName` AS `Server`,`plexPlaying`.`watchedItem`.`Start_Time` AS `Start Time` from ((((`plexPlaying`.`watchedItem` left join `plexPlaying`.`MediaFile` on((`plexPlaying`.`watchedItem`.`ShowID` = `plexPlaying`.`MediaFile`.`idMediaFile`))) left join `plexPlaying`.`Device` on((`plexPlaying`.`watchedItem`.`idDevice` = `plexPlaying`.`Device`.`idDevice`))) left join `plexPlaying`.`plexUsers` on((`plexPlaying`.`watchedItem`.`idUser` = `plexPlaying`.`plexUsers`.`idUser`))) left join `plexPlaying`.`plexServer` on((`plexPlaying`.`watchedItem`.`idServer` = `plexPlaying`.`plexServer`.`idServer`))) where isnull(`plexPlaying`.`watchedItem`.`End_Time`) order by `plexPlaying`.`watchedItem`.`Start_Time`,`plexPlaying`.`plexServer`.`ServerName`;

-- -----------------------------------------------------
-- View `plexPlaying`.`DevicesWithOwners`
-- -----------------------------------------------------
DROP VIEW IF EXISTS `plexPlaying`.`DevicesWithOwners` ;
USE `plexPlaying`;
CREATE  OR REPLACE ALGORITHM=UNDEFINED DEFINER=`Ben`@`%` SQL SECURITY DEFINER VIEW `plexPlaying`.`DevicesWithOwners` AS select `plexPlaying`.`plexUsers`.`UserName` AS `UserName`,`plexPlaying`.`Device`.`DeviceName` AS `DeviceName`,`plexPlaying`.`Device`.`Platform` AS `Platform`,`plexPlaying`.`Device`.`Product` AS `Product` from (`plexPlaying`.`Device` left join `plexPlaying`.`plexUsers` on((`plexPlaying`.`Device`.`idUser` = `plexPlaying`.`plexUsers`.`idUser`))) order by `plexPlaying`.`plexUsers`.`UserName`;

-- -----------------------------------------------------
-- View `plexPlaying`.`PlayCountByShow`
-- -----------------------------------------------------
DROP VIEW IF EXISTS `plexPlaying`.`PlayCountByShow` ;
USE `plexPlaying`;
CREATE  OR REPLACE ALGORITHM=UNDEFINED DEFINER=`Ben`@`%` SQL SECURITY DEFINER VIEW `plexPlaying`.`PlayCountByShow` AS select `plexPlaying`.`MediaFile`.`MediaFileName` AS `MediaFileName`,count(`plexPlaying`.`watchedItem`.`ShowID`) AS `Play Count`,group_concat(distinct `plexPlaying`.`plexUsers`.`UserName` order by `plexPlaying`.`plexUsers`.`UserName` ASC separator ', ') AS `Users`,group_concat(distinct `plexPlaying`.`plexServer`.`ServerName` order by `plexPlaying`.`plexServer`.`ServerName` ASC separator ', ') AS `Servers` from (((`plexPlaying`.`watchedItem` left join `plexPlaying`.`MediaFile` on((`plexPlaying`.`watchedItem`.`ShowID` = `plexPlaying`.`MediaFile`.`idMediaFile`))) left join `plexPlaying`.`plexUsers` on((`plexPlaying`.`watchedItem`.`idUser` = `plexPlaying`.`plexUsers`.`idUser`))) left join `plexPlaying`.`plexServer` on((`plexPlaying`.`watchedItem`.`idServer` = `plexPlaying`.`plexServer`.`idServer`))) group by `plexPlaying`.`MediaFile`.`MediaFileName` order by count(`plexPlaying`.`watchedItem`.`ShowID`) desc;

-- -----------------------------------------------------
-- View `plexPlaying`.`PlayCountByUser`
-- -----------------------------------------------------
DROP VIEW IF EXISTS `plexPlaying`.`PlayCountByUser` ;
USE `plexPlaying`;
CREATE  OR REPLACE ALGORITHM=UNDEFINED DEFINER=`Ben`@`%` SQL SECURITY DEFINER VIEW `plexPlaying`.`PlayCountByUser` AS select `plexPlaying`.`plexUsers`.`UserName` AS `UserName`,count(`plexPlaying`.`watchedItem`.`idUser`) AS `Total Plays`,count(distinct `plexPlaying`.`watchedItem`.`ShowID`) AS `Shows` from (`plexPlaying`.`watchedItem` left join `plexPlaying`.`plexUsers` on((`plexPlaying`.`watchedItem`.`idUser` = `plexPlaying`.`plexUsers`.`idUser`))) group by `plexPlaying`.`plexUsers`.`UserName` order by count(`plexPlaying`.`watchedItem`.`idUser`) desc;

-- -----------------------------------------------------
-- View `plexPlaying`.`PlayCountByUser-Last Week`
-- -----------------------------------------------------
DROP VIEW IF EXISTS `plexPlaying`.`PlayCountByUser-Last Week` ;
USE `plexPlaying`;
CREATE  OR REPLACE ALGORITHM=UNDEFINED DEFINER=`Ben`@`%` SQL SECURITY DEFINER VIEW `plexPlaying`.`PlayCountByUser-Last Week` AS select `plexPlaying`.`plexUsers`.`UserName` AS `UserName`,count(`plexPlaying`.`watchedItem`.`idUser`) AS `Total Plays`,count(distinct `plexPlaying`.`watchedItem`.`ShowID`) AS `Shows` from (`plexPlaying`.`watchedItem` left join `plexPlaying`.`plexUsers` on((`plexPlaying`.`watchedItem`.`idUser` = `plexPlaying`.`plexUsers`.`idUser`))) where (`plexPlaying`.`watchedItem`.`Start_Time` between (now() - interval 1 week) and now()) group by `plexPlaying`.`plexUsers`.`UserName` order by count(`plexPlaying`.`watchedItem`.`idUser`) desc;

-- -----------------------------------------------------
-- View `plexPlaying`.`PlaysToday`
-- -----------------------------------------------------
DROP VIEW IF EXISTS `plexPlaying`.`PlaysToday` ;
USE `plexPlaying`;
CREATE  OR REPLACE ALGORITHM=UNDEFINED DEFINER=`Ben`@`%` SQL SECURITY DEFINER VIEW `plexPlaying`.`PlaysToday` AS select distinct `plexPlaying`.`MediaFile`.`MediaFileName` AS `MediaFileName`,`plexPlaying`.`plexUsers`.`UserName` AS `UserName`,`plexPlaying`.`plexServer`.`ServerName` AS `ServerName` from (((`plexPlaying`.`watchedItem` left join `plexPlaying`.`plexUsers` on((`plexPlaying`.`watchedItem`.`idUser` = `plexPlaying`.`plexUsers`.`idUser`))) left join `plexPlaying`.`MediaFile` on((`plexPlaying`.`watchedItem`.`ShowID` = `plexPlaying`.`MediaFile`.`idMediaFile`))) left join `plexPlaying`.`plexServer` on((`plexPlaying`.`watchedItem`.`idServer` = `plexPlaying`.`plexServer`.`idServer`))) where (cast(`plexPlaying`.`watchedItem`.`Start_Time` as date) = cast(now() as date)) order by cast(`plexPlaying`.`watchedItem`.`Start_Time` as date) desc;

-- -----------------------------------------------------
-- View `plexPlaying`.`PlaysYesterday`
-- -----------------------------------------------------
DROP VIEW IF EXISTS `plexPlaying`.`PlaysYesterday` ;
USE `plexPlaying`;
CREATE  OR REPLACE ALGORITHM=UNDEFINED DEFINER=`Ben`@`%` SQL SECURITY DEFINER VIEW `plexPlaying`.`PlaysYesterday` AS select distinct `plexPlaying`.`MediaFile`.`MediaFileName` AS `MediaFileName`,`plexPlaying`.`plexUsers`.`UserName` AS `UserName`,`plexPlaying`.`plexServer`.`ServerName` AS `ServerName` from (((`plexPlaying`.`watchedItem` left join `plexPlaying`.`plexUsers` on((`plexPlaying`.`watchedItem`.`idUser` = `plexPlaying`.`plexUsers`.`idUser`))) left join `plexPlaying`.`MediaFile` on((`plexPlaying`.`watchedItem`.`ShowID` = `plexPlaying`.`MediaFile`.`idMediaFile`))) left join `plexPlaying`.`plexServer` on((`plexPlaying`.`watchedItem`.`idServer` = `plexPlaying`.`plexServer`.`idServer`))) where (cast(`plexPlaying`.`watchedItem`.`Start_Time` as date) = (cast(now() as date) - 1)) order by cast(`plexPlaying`.`watchedItem`.`Start_Time` as date) desc;

-- -----------------------------------------------------
-- View `plexPlaying`.`PlaysYesterday-Pfeilhomeserver`
-- -----------------------------------------------------
DROP VIEW IF EXISTS `plexPlaying`.`PlaysYesterday-Pfeilhomeserver` ;
USE `plexPlaying`;
CREATE  OR REPLACE ALGORITHM=UNDEFINED DEFINER=`Ben`@`%` SQL SECURITY DEFINER VIEW `plexPlaying`.`PlaysYesterday-Pfeilhomeserver` AS select distinct `plexPlaying`.`MediaFile`.`MediaFileName` AS `MediaFileName`,`plexPlaying`.`plexUsers`.`UserName` AS `UserName`,`plexPlaying`.`plexServer`.`ServerName` AS `ServerName` from (((`plexPlaying`.`watchedItem` left join `plexPlaying`.`plexUsers` on((`plexPlaying`.`watchedItem`.`idUser` = `plexPlaying`.`plexUsers`.`idUser`))) left join `plexPlaying`.`MediaFile` on((`plexPlaying`.`watchedItem`.`ShowID` = `plexPlaying`.`MediaFile`.`idMediaFile`))) left join `plexPlaying`.`plexServer` on((`plexPlaying`.`watchedItem`.`idServer` = `plexPlaying`.`plexServer`.`idServer`))) where ((cast(`plexPlaying`.`watchedItem`.`Start_Time` as date) = (cast(now() as date) - 1)) and (`plexPlaying`.`watchedItem`.`idServer` = 1)) order by cast(`plexPlaying`.`watchedItem`.`Start_Time` as date) desc;

-- -----------------------------------------------------
-- View `plexPlaying`.`PlaysYesterday-Server3`
-- -----------------------------------------------------
DROP VIEW IF EXISTS `plexPlaying`.`PlaysYesterday-Server3` ;
USE `plexPlaying`;
CREATE  OR REPLACE ALGORITHM=UNDEFINED DEFINER=`Ben`@`%` SQL SECURITY DEFINER VIEW `plexPlaying`.`PlaysYesterday-Server3` AS select distinct `plexPlaying`.`MediaFile`.`MediaFileName` AS `MediaFileName`,`plexPlaying`.`plexUsers`.`UserName` AS `UserName`,`plexPlaying`.`plexServer`.`ServerName` AS `ServerName` from (((`plexPlaying`.`watchedItem` left join `plexPlaying`.`plexUsers` on((`plexPlaying`.`watchedItem`.`idUser` = `plexPlaying`.`plexUsers`.`idUser`))) left join `plexPlaying`.`MediaFile` on((`plexPlaying`.`watchedItem`.`ShowID` = `plexPlaying`.`MediaFile`.`idMediaFile`))) left join `plexPlaying`.`plexServer` on((`plexPlaying`.`watchedItem`.`idServer` = `plexPlaying`.`plexServer`.`idServer`))) where ((cast(`plexPlaying`.`watchedItem`.`Start_Time` as date) = (cast(now() as date) - 1)) and (`plexPlaying`.`watchedItem`.`idServer` = 959)) order by cast(`plexPlaying`.`watchedItem`.`Start_Time` as date) desc;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;

-- -*- mysql -*-

/****** dbscripts/schema.sql
 * NAME
 * schema.sql
 * SYNOPSIS
 * The schema for defining the tables and indexes for the anatolia database.
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20120710
 ******
 */

DROP DATABASE IF EXISTS arts_anatolia_fs;
CREATE DATABASE arts_anatolia_fs;
USE arts_anatolia_fs;

DROP TABLE IF EXISTS documentTypes;
CREATE TABLE documentTypes (
  typeID INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,
	typeName VARCHAR(32)
);

-- the different document types
INSERT INTO documentTypes (typeID, typeName) VALUES (NULL, 'manuscript');
INSERT INTO documentTypes (typeID, typeName) VALUES (NULL, 'authority');
INSERT INTO documentTypes (typeID, typeName) VALUES (NULL, 'bibliography');

-- All documents are XML documents with a unique name.
-- There may be more than one version of a document.
DROP TABLE IF EXISTS documents;
CREATE TABLE documents (
  documentID INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,
	documentName MEDIUMTEXT, -- e.g. Uk_IO_Islamic_4701, lccn:n12345, smith_2012
	documentTypeID INTEGER, -- the type of document
	hexName MEDIUMTEXT, -- hex of documentName
	FOREIGN KEY (documentTypeID) REFERENCES documentTypes(typeID)
);

-- A version is a particular instance of a document.
DROP TABLE IF EXISTS versions;
CREATE TABLE versions (
  versionID INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,
	documentID INTEGER NOT NULL,
	versionPath TEXT, -- path to version file
	versionUUID TEXT, -- name of version file
	versionDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	versionCreator TEXT, -- username of person creating version of document
	FOREIGN KEY (documentID) REFERENCES documents(documentID) ON DELETE CASCADE
);

-- indexes

-- for selecting document using documentName and type
CREATE UNIQUE INDEX document_name_idx ON documents(
  documentTypeID, 
  documentName(30)
);
CREATE UNIQUE INDEX document_hexname_idx ON documents(
  documentTypeID, 
  hexName(60)
);

-- for selecting versionPath and versionUUID using documentID and sorting by versionDate
CREATE INDEX version_idx ON versions(documentID, versionDate);

-- -*- mysql -*-

/****** dbscripts/functions.sql
 * NAME
 * functions.sql
 * SYNOPSIS
 * This file contains the stored procedures for communicating with the database.
 * The database is just for matching documents (TEI/MADS) and versions of these to files stored in the file system.
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20120710
 ******
 */

-- use anatolia database
USE arts_anatolia_fs;

-- change delimiter, so that procedures can use ; as normal
DELIMITER ;;

/****f* functions.sql/getDocuments
 * NAME
 * getDocuments
 * SYNOPSIS
 * Returns all documents of the given type in the system.
 * ARGUMENTS
 *   * in_type_id - INTEGER - the ID of the document type
 *   * in_offset - INTEGER - offset for query
 *   * in_limit - INTEGER - number of rows to get
 * RETURN VALUE
 * All rows from the documents table.
 ******
 */
DROP PROCEDURE IF EXISTS getDocuments;
CREATE PROCEDURE getDocuments(in_type_id INTEGER, in_offset INTEGER, in_limit INTEGER) -- {{{
BEGIN
  SELECT documentID, documentName
    FROM documents
   WHERE documentTypeID = in_type_id
   LIMIT in_offset, in_limit;
END ;;
-- }}}

/****f* functions.sql/getDocumentByID
 * NAME
 * getDocumentByID
 * SYNOPSIS
 * Returns a particular document, using the documentID.
 * ARGUMENTS
 *   * in_id - INTEGER - the ID of the document
 * RETURN VALUE
 * No more than one row from the documents table.
 ******
 */
DROP PROCEDURE IF EXISTS getDocumentByID;
CREATE PROCEDURE getDocumentByID (in_id INTEGER) -- {{{
BEGIN
  SELECT documentID, documentName, documentTypeID
	  FROM documents
	 WHERE documentID = in_id;
END ;;
-- }}}

/****f* functions.sql/getVersionsByDocID
 * NAME
 * getVersionsByDocID
 * SYNOPSIS
 * Returns all versions of a document, using the documentID.
 * ARGUMENTS
 *   * in_doc_id - INTEGER - the ID of the document
 * RETURN VALUE
 * No more than one row from the documents table joined to the versions table.
 ******
 */
DROP PROCEDURE IF EXISTS getVersionsByDocID;
CREATE PROCEDURE getVersionsByDocID(in_doc_id INTEGER) -- {{{
BEGIN
    SELECT v.versionID, v.documentID, v.versionUUID, v.versionPath, v.versionDate, v.versionCreator, 
		       d.documentName, d.documentTypeID
	    FROM versions AS v
INNER JOIN documents AS d
        ON v.documentID = d.documentID
		 WHERE v.documentID = in_doc_id
	ORDER BY v.versionDate ASC;
END ;;
-- }}}

/****f* functions.sql/getVersionsByDocName
 * NAME
 * getVersionsByDocName
 * SYNOPSIS
 * Returns all versions of a document, using the documentName.
 * ARGUMENTS
 *   * in_doc_hexname - MEDIUMINT - the hexname of the document
 * RETURN VALUE
 * No more than one row from the documents table joined to the versions table.
 ******
 */
DROP PROCEDURE IF EXISTS getVersionsByDocName;
CREATE PROCEDURE getVersionsByDocName(in_doc_hexname MEDIUMTEXT) -- {{{
BEGIN
    SELECT v.versionID, v.documentID, v.versionUUID, v.versionPath, v.versionDate, v.versionCreator, 
		       d.documentName, d.documentTypeID
	    FROM versions AS v
INNER JOIN documents AS d
        ON v.documentID = d.documentID
		 WHERE d.hexname = in_doc_hexname
	ORDER BY v.versionDate ASC;
END ;;
-- }}}

/****f* functions.sql/getLatestVersionByName
 * NAME
 * getLatestVersionByName
 * SYNOPSIS
 * Returns the latest version of a document, using the documentName and documentTypeID.
 * ARGUMENTS
 *   * in_doc_hexname - MEDIUMTEXT - the name of the document in HEX
 *   * in_doc_type - INTEGER - the type of document
 * RETURN VALUE
 * No more than one row from the documents table joined to the versions table.
 ******
 */
DROP PROCEDURE IF EXISTS getLatestVersionByName;
CREATE PROCEDURE getLatestVersionByName(in_doc_hexname MEDIUMTEXT, in_doc_type INTEGER) -- {{{
BEGIN
    SELECT v.versionID, v.documentID, v.versionUUID, v.versionPath, v.versionDate, v.versionCreator, 
		       d.documentName, d.documentTypeID
	    FROM versions AS v
INNER JOIN documents AS d
        ON v.documentID = d.documentID
		 WHERE d.hexName = in_doc_hexname AND
		       d.documentTypeID = in_doc_type
	ORDER BY v.versionDate DESC
	   LIMIT 1;
END ;;
-- }}}

/****f* functions.sql/getLatestVersionByDocID
 * NAME
 * getLatestVersionByDocID
 * SYNOPSIS
 * Returns the latest version of a document, using the documentID.
 * ARGUMENTS
 *   * in_doc_id - INTEGER - the ID of the document
 * RETURN VALUE
 * No more than one row from the documents table joined to the versions table.
 ******
 */
DROP PROCEDURE IF EXISTS getLatestVersionByDocID;
CREATE PROCEDURE getLatestVersionByDocID(in_doc_id INTEGER) -- {{{
BEGIN
    SELECT v.versionID, v.documentID, v.versionUUID, v.versionPath, v.versionDate, v.versionCreator, 
		       d.documentName, d.documentTypeID
	    FROM versions AS v
INNER JOIN documents AS d
        ON v.documentID = d.documentID
	   WHERE v.documentID = in_doc_id
  ORDER BY v.versionDate DESC
     LIMIT 1;
END ;;
-- }}}

/****f* functions.sql/getFirstVersionByDocID
 * NAME
 * getFirstVersionByDocID
 * SYNOPSIS
 * Returns the first version of a document, using the documentID.
 * ARGUMENTS
 *   * in_doc_id - INTEGER - the ID of the document
 * RETURN VALUE
 * No more than one row from the documents table joined to the versions table.
 ******
 */
DROP PROCEDURE IF EXISTS getFirstVersionByDocID;
CREATE PROCEDURE getFirstVersionByDocID(in_doc_id INTEGER) -- {{{
BEGIN
    SELECT v.versionID, v.documentID, v.versionUUID, v.versionPath, v.versionDate, v.versionCreator, 
		       d.documentName, d.documentTypeID
	    FROM versions AS v
INNER JOIN documents AS d
        ON v.documentID = d.documentID
	   WHERE v.documentID = in_doc_id
  ORDER BY v.versionDate ASC
   LIMIT 1;
END ;;
-- }}}

/****f* functions.sql/getVersionByDocID
 * NAME
 * getVersionByDocID
 * SYNOPSIS
 * Returns a specific version of a document, using the documentID and versionID.
 * ARGUMENTS
 *   * in_doc_id - INTEGER - the ID of the document
 *   * in_version_id - INTEGER - the ID of the version of the document
 * RETURN VALUE
 * No more than one row from the documents table joined to the versions table.
 ******
 */
DROP PROCEDURE IF EXISTS getVersionByDocID;
CREATE PROCEDURE getVersionByDocID(in_doc_id INTEGER, in_version_id INTEGER) -- {{{
BEGIN
    SELECT v.versionID, v.documentID, v.versionUUID, v.versionPath, v.versionDate, v.versionCreator, 
		       d.documentName, d.documentTypeID
	    FROM versions AS v
INNER JOIN documents AS d
	   WHERE v.documentID = in_doc_id 
		   AND v.versionID = in_version_id;
END ;;
-- }}}

/****f* functions.sql/addDocument
 * NAME
 * addDocument
 * SYNOPSIS
 * Add a document to the system. 
 * The document has a name, and the particular version of the document has a unique name which identifies the file it is in.
 * The creator of the version of the document is also stored.
 * The document information is inserted, or ignored if it already exists.
 * The documentID of the document is remembered, and used when inserting the version information.
 * ARGUMENTS
 *   * in_doc_name - MEDIUMTEXT - the name of the document
 *   * in_type_id - INTEGER - the type of document
 *   * in_version_path - TEXT - the path to the version file
 *   * in_version_uuid - TEXT - the unique name of the version
 *   * in_version_creator - TEXT - the name of the administrator who uploaded the version of the document
 ******
 */
DROP PROCEDURE IF EXISTS addDocument;
CREATE PROCEDURE addDocument(in_doc_name MEDIUMTEXT CHARSET 'utf8', in_type_id INTEGER,
                             in_version_uuid TEXT, in_version_path TEXT, in_version_creator TEXT) -- {{{
BEGIN
  DECLARE doc_id INTEGER;
	
INSERT IGNORE INTO documents (documentID, documentName, documentTypeID, hexName)
	          VALUES (NULL, in_doc_name, in_type_id, HEX(in_doc_name));
	
	-- get ID of new/old document
	SELECT documentID
	  FROM documents
	 WHERE hexName = HEX(in_doc_name)
	  INTO doc_id;
	
	-- insert new version
	INSERT INTO versions (versionID, documentID, versionUUID, versionPath, versionCreator)
	     VALUES (NULL, doc_id, in_version_uuid, in_version_path, in_version_creator);
	SELECT LAST_INSERT_ID() AS id;
END ;;
-- }}}

/****f* functions.sql/getLatestVersions
 * NAME
 * getLatestVersions
 * SYNOPSIS
 * Returns the latest versions of all documents
 * RETURN VALUE
 * All rows from the documents table each joined to row from the versions table
 ******
 */
DROP PROCEDURE IF EXISTS getLatestVersions;
CREATE PROCEDURE getLatestVersions() -- {{{
BEGIN
    SELECT v.versionID, v.documentID, v.versionUUID, v.versionPath, v.versionDate, v.versionCreator, 
		       d.documentName, d.documentTypeID
	    FROM versions AS v
INNER JOIN documents AS d
        ON v.documentID = d.documentID
INNER JOIN (SELECT documentID, MAX(versionDate) AS latestDate
              FROM versions
					GROUP BY documentID) AS l
		    ON v.documentID = l.documentID AND
				   v.versionDate = l.latestDate;
END ;;
-- }}}

/****f* functions.sql/deleteDocumentByDocID
 * NAME
 * deleteDocumentByDocID
 * SYNOPSIS
 * Deletes document and all versions of document, matching document by documentID.
 * ARGUMENTS
 *   * in_doc_id - INTEGER - the ID of the document to delete
 * RETURN VALUE
 * TODO
 ******
 */
DROP PROCEDURE IF EXISTS deleteDocumentByDocID;
CREATE PROCEDURE deleteDocumentByDocID(in_doc_id INTEGER) -- {{{
BEGIN
  DELETE FROM documents
	      WHERE documentID = in_doc_id;
END ;;
-- }}}

/****f* functions.sql/deleteDocumentByDocName
 * NAME
 * deleteDocumentByDocName
 * SYNOPSIS
 * Deletes document and all versions of document, matching document by documentName.
 * ARGUMENTS
 *   * in_doc_hexname - MEDIUMTEXT - the hexname of the document to delete
 * RETURN VALUE
 * TODO
 ******
 */
DROP PROCEDURE IF EXISTS deleteDocumentByDocName;
CREATE PROCEDURE deleteDocumentByDocName(in_doc_hexname MEDIUMTEXT) -- {{{
BEGIN
  DELETE FROM documents
	      WHERE hexName = in_doc_hexname;
END ;;
-- }}}

/****f* functions.sql/getDocumentExists
 * NAME
 * getDocumentExists
 * SYNOPSIS
 * Returns a row if there is a document identified by documentName in the system.
 * ARGUMENTS
 *   * in_doc_hexname - MEDIUMTEXT - hexname of document
 *   * in_doc_type - INTEGER - type of document
 * RETURN VALUE
 * A row from the document table if there is a match, otherwise no rows.
 ******
 */
DROP PROCEDURE IF EXISTS documentExists;
CREATE PROCEDURE documentExists(in_doc_hexname MEDIUMTEXT, in_doc_type INTEGER) -- {{{
BEGIN
  SELECT documentID 
	  FROM documents
	 WHERE hexName = in_doc_hexname AND documentTypeID = in_doc_type;
END ;;
-- }}}

/****f* functions.sql/getNextDocument
 * NAME
 * getNextDocument
 * SYNOPSIS
 * Returns a row from a join of the documents and versions tables matching the most recent version of the alphabetically next document.
 * ARGUMENTS
 *   * in_doc_hexname - MEDIUMTEXT - hexname of document
 *   * in_doc_type - INTEGER - type of document
 * RETURN VALUE
 * A row from the documents and versions tables
 ******
 */
DROP PROCEDURE IF EXISTS getNextDocument;
CREATE PROCEDURE getNextDocument(in_doc_hexname MEDIUMTEXT, in_doc_type INTEGER) -- {{{
BEGIN
    SELECT v.versionID, v.documentID, v.versionUUID, v.versionPath, v.versionDate, v.versionCreator,
           d1.documentName, d1.documentTypeID
      FROM documents d1 
INNER JOIN versions v ON v.documentID = d1.documentID, 
           documents d2 
     WHERE d2.documentTypeID = in_doc_type AND 
           d2.hexName = in_doc_hexname AND 
	   d1.documentTypeID = in_doc_type AND 
	   d1.documentName > d2.documentName 
  ORDER BY d1.documentName ASC, v.versionDate DESC 
     LIMIT 1;
END ;;
-- }}}

/****f* functions.sql/getPrevDocument
 * NAME
 * getPrevDocument
 * SYNOPSIS
 * Returns a row from a join of the documents and versions tables matching the most recent version of the alphabetically previous document.
 * ARGUMENTS
 *   * in_doc_hexname - MEDIUMTEXT - hexname of document
 *   * in_doc_type - INTEGER - type of document
 * RETURN VALUE
 * A row from the documents and versions tables
 ******
 */
DROP PROCEDURE IF EXISTS getPrevDocument;
CREATE PROCEDURE getPrevDocument(in_doc_hexname MEDIUMTEXT, in_doc_type INTEGER) -- {{{
BEGIN
    SELECT v.versionID, v.documentID, v.versionUUID, v.versionPath, v.versionDate, v.versionCreator,
           d1.documentName, d1.documentTypeID
      FROM documents d1 
INNER JOIN versions v ON v.documentID = d1.documentID, 
           documents d2 
     WHERE d2.documentTypeID = in_doc_type AND 
           d2.hexName = in_doc_hexname AND 
	   d1.documentTypeID = in_doc_type AND 
	   d1.documentName < d2.documentName 
  ORDER BY d1.documentName DESC, v.versionDate DESC 
     LIMIT 1;
END ;;
-- }}}

/****f* functions.sql/updateDocumentName
 * NAME
 * updateDocumentName
 * SYNOPSIS
 * Update name of document (and hexname) matched by ID
 * ARGUMENTS
 *   * in_docname - MEDIUMTEXT - name of document
 *   * in_docid - INTEGER - ID of document
 * RETURN VALUE
 * TODO
 * NOTES
 * MySQL treats 'FR_BNF_supplément_persan_57' and 'FR_BNF_supplement_persan_57'
 * as identical, so won't update from one to the other.
 ******
 */
DROP PROCEDURE IF EXISTS updateDocumentName;
CREATE PROCEDURE updateDocumentName(in_docname MEDIUMTEXT, in_docid INTEGER) -- {{{
BEGIN
  UPDATE documents
	   SET documentName = HEX(in_docname),
		     hexName = HEX(in_docname)
	 WHERE documentID = in_docid;
  UPDATE documents
	   SET documentName = in_docname
	 WHERE documentID = in_docid;
END ;;
-- }}}

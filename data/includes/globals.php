<?php

/****** includes/globals.php
 * NAME
 * globals.php
 * SYNOPSIS
 * Various global variables and constant definitions needed by all scripts.
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20120710
 ******
 */

// start session
session_start();
if (!isset($_SESSION["basket"])) {
    $_SESSION["basket"] = array();
}

// WordPress stuff
$wpLoad = "/home/anatolia/public_html/wp-load.php";
$haveWP = file_exists($wpLoad);

$uri = "/anatolia/data/";

$dbHost = ""; // supply MySQL database host
$dbUser = ""; // supply user for MySQL database
$dbName = ""; // supply name of MySQL database
$shibUserField = ""; // supply Shibboleth field containing username
$baseDir = ""; // supply base directory for site
$dbpass = ""; // supply password for MySQL database

$serverName = isset($_SERVER["SERVER_NAME"]) ? $_SERVER["SERVER_NAME"] : "";

// Solr config
define("SOLR_HOST", "localhost");
define("SOLR_PORT", "8983");
define("SOLR_PATH", "/solr/anatolia"); // add core

// FOP config
define("FOP_HOST", "localhost");
define("FOP_PORT", "8983");
define("FOP_PATH", "/fop/fop?");

// paths
define("BASE_DIR", $baseDir);
define("XSLT_DIR", BASE_DIR . "xslt/");
define("INCLUDES_DIR", BASE_DIR . "includes/");
define("DOC_DIR", BASE_DIR . "documents/");
define("BASE_URI", $uri);

// database config
define("ANATOLIA_DB_USER", $dbUser);
define("ANATOLIA_DB_PASS", $dbpass);
define("ANATOLIA_DB_DSN", sprintf("mysql:host=%s;dbname=%s", $dbHost, $dbName));

// URL formats
define("LCCN_URL_FORMAT", "http://lccn.loc.gov/%s/mads");

// field set by Shibboleth for the user name
define("SHIB_USER_FIELD", $shibUserField);

// document types - same as in database and Solr
define("MANUSCRIPT_TYPE", 1);
define("AUTHORITY_TYPE", 2);
define("BIBLIOGRAPHY_TYPE", 3);

// namespaces
define("MODS_URI", "http://www.loc.gov/mods/v3");
define("TEI_URI", "http://www.tei-c.org/ns/1.0");
define("MADS_URI", "http://www.loc.gov/mads/v2");

if ($haveWP) {
    require_once $wpLoad;

    // add CSS
    add_action('wp_enqueue_scripts', function() {
        $path = sprintf("//%s%s", $_SERVER["SERVER_NAME"], BASE_URI);
        
        wp_register_style('anatolia_dynamic', $path . "style.css");
        wp_register_script('anatolia_js', $path . "anatolia.js");
        wp_register_script('anatolia_fold', $path . "fold.js");
        wp_register_script('anatolia_highlight', $path . "jquery.highlight.js");
        wp_register_script('jquery_tools', 'https://cdnjs.cloudflare.com/ajax/libs/jquery-tools/1.2.7/jquery.tools.min.js');
        wp_register_script('jquery_ui', '//code.jquery.com/ui/1.11.4/jquery-ui.js');
        wp_register_script('keyboard_js', $path . 'keyboard.js');
        wp_register_style('keyboard_css', $path . 'keyboard.css');
        wp_enqueue_script('anatolia_fold');
        wp_enqueue_script('jquery_tools');
        wp_enqueue_script('jquery_ui');
        wp_enqueue_script('anatolia_highlight');
        wp_enqueue_script('anatolia_js');
        wp_enqueue_style('anatolia_dynamic');
        wp_enqueue_script('keyboard_js');
        wp_enqueue_style('keyboard_css');
    });
}


// Wordpress uses __autoload, so just include these class files by hand
require_once "DB.php";
require_once "Page.php";
require_once "Solr.php";
require_once "XSLT.php";
require_once "Zip.php";
require_once "FOP.php";

/****f* globals.php/getUser
 * NAME
 * getUser
 * SYNOPSIS
 * Returns the name of the user as set by Shibboleth
 * RETURN VALUE
 * String - the name of the user, e.g. cs2@st-andrews.ac.uk, or empty string if user not logged in to Shibboleth
 ******
 */
function getUser() { //{{{
    return isset($_SERVER[SHIB_USER_FIELD]) ? $_SERVER[SHIB_USER_FIELD] : "";
}
//}}}

/****f* globals.php/uniqueFileName
 * NAME
 * uniqueFileName
 * SYNOPSIS
 * Returns the path to and base name of a file that is unique to the directory.
 * The uniqueness is done with uniquid, and then put through sha1 for a bit of obfuscation.
 * RETURN VALUE
 * Array containing a path (based on the date/time) and the file name (minus .xml), or null if there was an error.
 * NOTES
 * This function will create the directory if it doesn't already exist.
 ******
 */
function uniqueFileName() { //{{{
    $fileName = "";
    $path = "";
    $datePath = date("Y/m/d/H/i");
    $dir = DOC_DIR;

    do {
        // directory part of path
        $p = sprintf("%s%s", $dir, $datePath);

        // create nested directories
        if (!is_dir($p) &&
            !mkdir($p, 0775, true)) {
            $fileName = "";
            break;
        }

        // add file name
        $u = md5(uniqid());
        $fileName = sha1(uniqid($u));
        $path = sprintf("%s/%s.xml", $p, $fileName);
    } while (file_exists($path));

    return $fileName ? array($datePath, $fileName) : null;
}
//}}}

/****f* globals.php/getDom
 * NAME
 * getDom
 * SYNOPSIS
 * Given the path and filename of an XML file, return it as a DOM object.
 * ARGUMENTS
 *   * path - path to file, relative to DOC_DIR
 *   * base - base name of file, without .xml
 * RETURN VALUE
 * DOM object, or false on failure
 ******
 */
function getDom($path, $base) { //{{{
    return DomDocument::load(getFilename($path, $base));
}
//}}}

/****f* globals.php/getFilename
 * NAME
 * getFilename
 * SYNOPSIS
 * Given the path and filename of an XML file, return full path to file.
 * ARGUMENTS
 *   * path - path to file, relative to DOC_DIR
 *   * base - base name of file, without .xml
 * RETURN VALUE
 * String - full path to file
 ******
 */
function getFilename($path, $base) { //{{{
    return sprintf("%s%s/%s.xml", DOC_DIR, $path, $base);
}
//}}}

/****f* globals.php/handleUpload
 * NAME
 * handleUpload
 * SYNOPSIS
 * Handles the upload of single XML documents or ZIP archives of XML documents.
 * ARGUMENTS
 *   * uploadedFile - array - item from $_FILES array containing the uploaded file
 *   * message - string - passed by reference, for recording any errors that occurr
 * RETURN VALUE
 * Boolean - true on success (when at least one file has been added, though maybe not all), false otherwise.
 ******
 */
function handleUpload($uploadedFile, &$message) { //{{{
    $success = false;
    //$successMessage = "";

    do {
        // look for error in upload
        if (UPLOAD_ERR_OK != $uploadedFile["error"]) {
            $message = "Upload error";
            break;
        }

        // see if it isn't ZIP - assume single XML document
        $zip = new ZipArchive();
        if (true !== $zip->open($uploadedFile["tmp_name"])) {
            $dom = new DomDocument();
            $dom->load($uploadedFile["tmp_name"]);
            $success = sniffDocument($message, $dom);
            break;
        }

        // is ZIP, so do upload for contents of each file in archive
        $n = $zip->numFiles;
        if (0 == $n) {
            $message = "ZIP is empty";
            break;
        }

        for ($i = 0; $i < $n; ++ $i) {
            $fileInfo = $zip->statIndex($i);
            $xml = $zip->getFromIndex($i);
            $failMessage = "";

            // if file upload fails, carry on, but remember message
            $dom = new DomDocument();
            $dom->loadXML($xml);
            if (!sniffDocument($failMessage, $dom)) {
                $message .= sprintf("%s (%s)|",
                                    $failMessage, $fileInfo["name"]);
                continue;
            }

            //$successMessage .= "Uploaded " . $fileInfo["name"] . "|";
            $success = true; // success when at least one document uploaded
        }
    } while (false);

    // some failed, so also report which succeeded
    if (!$message) {
        /*$message .= $successMessage;
    }
    // got here without any error message
    else {*/
        $message = "Document/s uploaded";
    }

    return $success;
}
//}}}

/****f* globals.php/sniffDocument
 * NAME
 * sniffDocument
 * SYNOPSIS
 * Work out what type of document has been uploaded, and call the appropriate function.
 * Get XPath object from DOM, and look at namespace and local name of root elements.
 * ARGUMENTS
 *   * message - string - passed by reference, for recording any errors that occurr
 *   * dom - DomDocument - DOM of the XML file being processed, or false if it couldn't be parsed
 *   * index - boolean - if true, just index in Solr, but don't save DOM or add to database
 * RETURN VALUE
 * Boolean - true on success, false otherwise.
 ******
 */
function sniffDocument(&$message, $dom, $index=false) { //{{{
    $success = false;

    do {
        // make sure that it is XML document
        if (!$dom) {
            $message = "Not XML";
            break;
        }

        $xpath = new DOMXPath($dom);

        // details for different XML vocabularies used by different types of document
        // in the order they should be checked
        $xmlDetails = array(array("tei", TEI_URI, "/tei:TEI", "uploadMS"),
                            array("mads", MADS_URI, "/mads:mads", "uploadAuthorityFile"),
                            array("mods", MODS_URI, "/mods:modsCollection", "uploadBibliographyFile"),
                            array("mods", MODS_URI, "/mods:mods", "uploadBibliographyFile"));

        foreach ($xmlDetails as $d) {
            list ($prefix, $uri, $xp, $func) = $d;
            $xpath->registerNamespace($prefix, $uri);
            if (1 == $xpath->query($xp)->length) {
                $success = $func($message, $dom, $index);
                break 2;
            }
        }

        // got here, so unrecognised document
        $message = "Document not recognised";
    } while (false);

    return $success;
}
//}}}

/****f* globals.php/renameDocument
 * NAME
 * renameDocument
 * SYNOPSIS
 * ARGUMENTS
 *   * id - integer - ID of document in database
 *   * newName - string - the new name for the document
 *   * message - string - passed by reference, will store any error message
 * RETURN VALUE
 * boolean - true when document has been renamed successfully
 ******
 */
function renameDocument($id, $newName, &$message) { //{{{
    $success = false;
    
    do {
        $db = DB::getInstance();

        // get latest version as DOM using ID
        if (!$db->getLatestVersionByDocID($id)) {
            $message = "Couldn't run query";
            break;
        }
        if (!$results = $db->getResults()) {
            $message = "Couldn't get results from query";
            break;
        }
        
        $path = $results[0]["versionPath"];
        $uuid = $results[0]["versionUUID"];
        $type = $results[0]["documentTypeID"];
        $oldName = $results[0]["documentName"];
        
        if (!$db->getVersionsByDocName(bin2hex($newName))) {
            $message = "Couldn't check to see if new name is in use";
            break;
        }
        
        $results = $db->getResults();
        if (count($results)) {
            $message = $newName . " is already in use";
            break;
        }
        
        $dom = getDom($path, $uuid);
        if (!$dom) {
            $message = "Couldn't load DOM";
            break;
        }
        
        $xpath = new DOMXPath($dom);
        
        $func = "";
        $xmlDetails = array(array("tei", TEI_URI, "/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/@xml:id", "uploadMS"),
                            array("mads", MADS_URI, "/mads:mads/mads:identifier", "uploadAuthorityFile"),
                            array("mods", MODS_URI, "/mods:mods/mods:classification", "uploadBibliographyFile"));

        // update document name in DOM
        foreach ($xmlDetails as $d) {
            list ($prefix, $uri, $xp, $f) = $d;
            $xpath->registerNamespace($prefix, $uri);
            
            $nodes = $xpath->query($xp);
            if ($nodes->length) {
                $nodes->item(0)->nodeValue = $newName;
                $func = $f;
                break;
            }
        }
        
        // make sure that DOM got updated
        if (!$func) {
            $message = "Couldn't update DOM";
            break;
        }
        
        // delete from Solr
        $solr = Solr::getInstance();
        if (!$solr->deleteDocument($oldName)) {
            $message = "Couldn't delete from Solr";
            break;
        }
        
        // update document name in database
        if (!$db->updateDocumentName($newName, $id)) {
            $message = "Couldn't update document name in database";
            break;
        }
        
        // treat as new upload
        if ($success = $func($message, $dom)) {
            $message = "Document renamed";
        }
    } while (false);
    
    return $success;
}
//}}}

/****f* globals.php/external_uris
 * NAME
 * external_uris
 * SYNOPSIS
 * Called from XSLT, will return node holding all external documents identified by given string of URIs
 * ARGUMENTS
 *   * uris - string - space delimited list of URIs
 *   * exclude - string - space delimited list of URIs to exclude, optional
 * RETURN VALUE
 * DomElement node
 ******
 */
function external_uris($uris, $exclude="") { //{{{
    // create DOM to hold documents
    $dom = new DomDocument();
    $root = $dom->createElement("root");
    $dom->appendChild($root);
    
    // database
    $db = DB::getInstance();
    
    // need type
    $type = AUTHORITY_TYPE;
    
    // remember documents fetched
    $docs = array(AUTHORITY_TYPE => array(),
                  BIBLIOGRAPHY_TYPE => array());
    
    $exclude = explode(" ", $exclude);
    
    foreach (explode(" ", $uris) as $uri) {
        if (!$uri) {
            continue;
        }
        
        switch ($uri) {
            // switch to AUTH_TYPE
         case "auth":
            $type = AUTHORITY_TYPE;
            break;
            
            // switch to BIB_TYPE
         case "bib":
            $type = BIBLIOGRAPHY_TYPE;
            break;
            
            // is URI, so try to add to DOM
         default:
            // check that it is a new one - don't want duplicates
            if (in_array($uri, $exclude) || in_array($uri, $docs[$type])) {
                break;
            }
            
            // remember this one
            $docs[$type][] = $uri;
            
            $db->getLatestVersionByName(bin2hex($uri), $type);
            $results = $db->getResults();
            if (!$results) {
                //printf("No results for %s\n", $uri);
                break;
            }
            $tempDom = getDom($results[0]["versionPath"],
                              $results[0]["versionUUID"]);
            if (!$tempDom) {
                break;
            }
            
            // set ID in tempDom
            $tempDom->documentElement->setAttribute("id", $uri);

            $root->appendChild($dom->importNode($tempDom->documentElement,
                                                true));
            break;
        }
    }
    
    return $root;
}
//}}}

?>

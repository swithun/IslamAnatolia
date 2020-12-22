<?php

/****** admin/view_version.php
 * NAME
 * view_version.php
 * SYNOPSIS
 * View a particular version of a document. This is only available to administrators.
 * Either the earliest, latest or a specific version can be viewed, or all versions of a document can be listed.
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20120710
 * SEE ALSO
 *   * includes/globals.php
 *   * includes/authorityFilesFunctions.php
 *   * includes/bibliographyFunctions.php
 *   * includes/msFunctions.php
 *   * xslt/tei2html.xsl
 *   * xslt/mods2html.xsl
 *   * xslt/mads2html.xsl
 *   * xslt/tei2tei.xsl
 *   * xslt/view_all_versions.xsl
 ******
 */

require_once "../includes/globals.php";
require_once "../includes/authorityFilesFunctions.php";
require_once "../includes/bibliographyFunctions.php";
require_once "../includes/msFunctions.php";

$params = array();
$page = new Page();

$defaultVersion = "latest";
$documentID = 0;
$documentName = "";

do {
    // need document name/ID and type
    if ((!isset($_GET["documentName"]) || "" == $_GET["documentName"]) &&
				(!isset($_GET["documentID"]) || "" == $_GET["documentID"])) {
				$params["message"] = "Need document name";
				$params["messageClass"] = "error";
				break;
    }

		// get MS part of documentName
		$documentName = $_REQUEST["documentName"];
		$p = strpos($documentName, ";");
		if (false !== $p) {
				$documentName = substr($documentName, 0, $p);
		}

    // which document type to show - also affects XSLT to use
    $type = isset($_REQUEST["type"]) ? $_REQUEST["type"] : "ms";
    $typeID = MANUSCRIPT_TYPE;

    switch ($type) {
     case "bib":
				$xsltFile = XSLT_DIR . "mods2html.xsl";
				$typeID = BIBLIOGRAPHY_TYPE;
				break;
				
     case "auth":
				$xsltFile = XSLT_DIR . "mads2html.xsl";
				$typeID = AUTHORITY_TYPE;
				break;
				
		 case "work":
     default:
				$xsltFile = XSLT_DIR . "tei2html.xsl";
				$type = "ms";
				break;
    }

    if (isset($_REQUEST["documentID"])) {
				$documentID = intval($_GET["documentID"]);
    }

    // connect to DB
    $db = new DB();

    if (!$documentID) {
				// get document ID using name
				if (!$db->getLatestVersionByName(bin2hex($documentName),
																				 $typeID)) {
						$params["message"] = "Couldn't get document by name";
						$params["messageClass"] = "error";
						break;
				}
				if (!$results = $db->getResults()) {
						$params["message"] = "No results for document by name";
						$params["messageClass"] = "error";
						break;
				}
				$documentID = $results[0]["documentID"];
    }

    // which version to get, default is latest
    $v = isset($_GET["version"]) ? $_GET["version"] : $defaultVersion;
    $version = $defaultVersion;

    switch ($v) {
     case "latest":
     case "first":
     case "all":
				$version = $v;
				break;
     default:
				if (intval($v)) {
						$version = intval($v);
				}
				break;
    }

    // pass in docType to XSLT
    $params["docType"] = $type;

    // which DB function to call, based on version
    $success = false;
    switch ($version) {
     case "latest":
				$success = $db->getLatestVersionByDocID($documentID);
				break;
     case "first":
				$success = $db->getFirstVersionByDocID($documentID);
				break;
     case "all":
				$success = $db->getVersionsByDocID($documentID);
				break;
     default:
				$success = $db->getVersionByDocID($documentID, $version);
				break;
    }

    if (!$success) {
				$params["message"] = print_r($db->getError(), true);
				$params["messageClass"] = "error";
				break;
    }

    // all versions, so use DOM from database
    if ("all" == $version) {
				$dom = $db->getResultsAsXML();
				$xsltFile = XSLT_DIR . "view_all_versions.xsl";

				$page->setXsltFile($xsltFile);
				$page->setDom($dom);
				break;
    }

    // particular version, so need array from database to get file name
    $results = $db->getResults();

    if (!$results || !isset($results[0]["versionPath"])) {
				$params["message"] = "No document version found";
				$params["messageClass"] = "error";
				break;
    }

    // find TEI file and load that into DOM
    $dom = getDom($results[0]["versionPath"],
									$results[0]["versionUUID"]);
    if (!$dom) {
				$params["message"] = "Problem loading XML document";
				$params["messageClass"] = "error";
				break;
    }

    // process TEI DOM
    if ("ms" == $type) {
				$xslt = new XSLT(XSLT_DIR . "tei2tei.xsl");
				$dom = $xslt->transformToDom($dom);
    }

    $page->setXsltFile($xsltFile);

    // send raw XML of document version
    // and run through stylesheet to modify original document
    if (isset($_REQUEST["raw"])) {
				$page->setRaw(true);
    }

    $page->setDom($dom);
} while (false);

if ($params) {
    $page->setParams($params);
}

print $page;

?>

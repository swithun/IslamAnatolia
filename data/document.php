<?php

/****** /document.php
 * NAME
 * document.php
 * SYNOPSIS
 * Page for displaying the latest version of a document. The document is identified by its name.
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
 *   * xslt/tei2tei.xsl
 ******
 */

require_once "includes/globals.php";
require_once "includes/authorityFilesFunctions.php";
require_once "includes/bibliographyFunctions.php";
require_once "includes/msFunctions.php";

function loadSearchURI() { //{{{
		session_start();
		return isset($_SESSION["search"]) ? $_SESSION["search"] : "";
}
//}}}

// create new page
$page = new Page();

// params for page
$params = array();
// XSLT for transforming data for page
$xsltFile = "";
// DOM for page
$dom = null;

do {
    // need document name
    if (!isset($_GET["name"]) || "" == $_GET["name"]) {
				$params["message"] = "Need document name";
				$params["messageClass"] = "error";
				break;
    }
		
		// remove work ID from document name if necessary
		$workID = "";
    $documentName = $_GET["name"];
		if (false !== strpos($documentName, ";")) {
				list ($documentName, $workID) = explode(";", $documentName, 2);
				// remove any leading 'a'
				$params["workID"] = ltrim($workID, "a");
		}
		
    // which document type to show - also affects XSLT to use
    $params["documentType"] = isset($_REQUEST["type"]) ? 
			$_REQUEST["type"] : "ms";
		
		// which format
		$format = isset($_REQUEST["format"]) ? $_REQUEST["format"] : "html";

		$typeID = MANUSCRIPT_TYPE;

		// pick XSLT file using document type
    switch ($params["documentType"]) {
     case "bib":
				$typeID = BIBLIOGRAPHY_TYPE;
				$xsltFile = XSLT_DIR . "mods2html.xsl";
				break;
     case "auth":
				$typeID = AUTHORITY_TYPE;
				$xsltFile = XSLT_DIR . "tei2html.xsl";
				break;
     default:
				$typeID = MANUSCRIPT_TYPE;
				$xsltFile = XSLT_DIR . "tei2html.xsl";
				break;
    }
		
		// show full details
		if (isset($_REQUEST["full"])) {
				$params["full"] = "true";
		}
		
		// most recent search
		$params["recent_search"] = loadSearchURI();
		
		// document name
		$params["documentName"] = $documentName;

    // looking for next/prev document
    $direction = isset($_REQUEST["direction"]) ? $_REQUEST["direction"] : "";

    // connect to DB
    $db = new DB();

    // get latest version of (prev/next) document
		$success = false;
    switch ($direction) {
     case "next":
				$success = $db->getNextDocument(bin2hex($documentName), $typeID);
				break;
     case "prev":
				$success = $db->getPrevDocument(bin2hex($documentName), $typeID);
				break;
     default:
				$success = $db->getLatestVersionByName(bin2hex($documentName), $typeID);
				break;
    }

    // check for success and results
    if (!$success) {
				$params["message"] = print_r($db->getError(), true);
				$params["messageClass"] = "error";
				break;
    }

    $results = $db->getResults();

    if (!$results) {
				$params["message"] = "No document version found for " . $documentName;
				$params["messageClass"] = "error";
				break;
    }

    // redirect with prev/next
    if ("next" == $direction || "prev" == $direction) {
				$location = sprintf("Location: documents/%s/%s",
														$params["documentType"],
														$results[0]["documentName"]);
				// location header
				header($location);
				break;
    }

    // find XML file and load that into DOM
    $dom = getDom($results[0]["versionPath"],
									$results[0]["versionUUID"]);
    if (!$dom) {
				$params["message"] = "Couldn't get DOM";
				$params["messageClass"] = "error";
				break;
    }
		
		// download XML
		do {
				if ("xml" != $format) {
						break;
				}
				
				header(sprintf('Content-disposition: attachment; filename="%s.xml"',
											 $documentName));
				header("Content-type: text/xml");
				print $dom->saveXML();
				break 2;
		} while (false);

    // TEI needs extra processing
    if (MANUSCRIPT_TYPE == $typeID) {
				// inseert filiations
				$xslt = new XSLT(XSLT_DIR . "tei2tei.xsl");
				$dom = $xslt->transformToDom($dom);
				
				// tidy up TEI, removing empty elements
				$xslt = new XSLT(XSLT_DIR . "tidy.xsl");
				$dom = $xslt->transformToDom($dom);
    }
		
		// get manuscripts refering to this authority file
		if (AUTHORITY_TYPE == $typeID && 
				!getReferers($documentName, $dom, $message)) {
				$params["message"] = $message;
				$params["messageClass"] = "error";
				break;
		}

    $params["documentName"] = $documentName;
		$params["search_url"] = BASE_URI;

    // was referer page the search page?
    do {
				// need referer
				if (!isset($_SERVER["HTTP_REFERER"]) ||
						"" == $_SERVER["HTTP_REFERER"]) {
						break;
				}

				// parse URL
				$url = parse_url($_SERVER["HTTP_REFERER"]);

				// match host name with referer
				if ($_SERVER["SERVER_NAME"] != $url["host"]) {
						break;
				}

				// match path
				if ($url["path"] != BASE_URI . "index.php") {
						break;
				}

				$params["search_url"] = parse_url($_SERVER["HTTP_REFERER"], PHP_URL_PATH);
    } while (false);

		// PDF format?
		do {
				if ("pdf" != $format) {
						break;
				}
				
				$fop = new FOP($documentName, XSLT_DIR . "html2fo.xsl");
				$fop->setParams($params);
				
				// transform TEI dom to HTML
				$xslt = new XSLT($xsltFile);
				$dom = $xslt->transformToDom($dom);
				
				if (!$fop->transform($dom)) {
						$params["message"] = "PDF transform failed";
						$params["messageClass"] = "error";
						break;
				}

				// finished
				break 2;
		} while (false);
				
} while (false);


// only output page when no headers sent
if (!headers_sent()) {
    $page->setXsltFile($xsltFile);
    $page->setDom($dom);
		if ($params) {
				$page->setParams($params);
		}
    print $page;
}

?>

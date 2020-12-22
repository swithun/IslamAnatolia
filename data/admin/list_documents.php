<?php

/****** admin/list_documents.php
 * NAME
 * list_documents.php
 * SYNOPSIS
 * List all the manuscript documents in the system.
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20120710
 * SEE ALSO
 *   * includes/globals.php
 *   * xslt/list_documents.xsl
 * BUGS
 * Should add in the ability to sort on different fields later.
 * Faceting needs to work (joins on ms/work)
 ******
 */

require_once "../includes/globals.php";

$params = array();
$xsltFile = XSLT_DIR . "list_documents.xsl";
$page = new Page($xsltFile);

// paging variables
$offset = 0;
$limit = 50;

do {
    // which document type to show - also affects XSLT to use
    $type = isset($_REQUEST["type"]) ? $_REQUEST["type"] : "ms";

    if (isset($_REQUEST["message"]) && "" != $_REQUEST["message"]) {
				$params["message"] = $_REQUEST["message"];
    }
    if (isset($_REQUEST["messageClass"]) && "" != $_REQUEST["messageClass"]) {
				$params["messageClass"] = $_REQUEST["messageClass"];
    }

    // offset
    $offset = isset($_REQUEST["offset"]) && (int) $_REQUEST["offset"] ?
      (int) $_REQUEST["offset"] : $offset;
    $limit = isset($_REQUEST["limit"]) && (int) $_REQUEST["limit"] ?
      (int) $_REQUEST["limit"] : $limit;

    // remove offset from _GET
    if (isset($_GET["offset"])) {
				unset($_GET["offset"]);
    }

    // params
    $params["type"] = $type;
    $params["offset"] = $offset;
    $params["limit"] = $limit;
    $params["url"] = sprintf("%s?%s",
														 $_SERVER["PHP_SELF"],
														 http_build_query($_GET));
    $params["search_type"] = "list";
		$params["url"] = $_SERVER["REQUEST_URI"];

    $solr = new Solr();
		
		// work out which facets to use
		$physical_location_fields = array("country", "settlement", "institution", "repository", "collection");
		foreach ($physical_location_fields as $field) {
				$f = "ms_physical_location_" . $field;

				if (!isset($_REQUEST[$f])) {
						$solr->addFacet($f);
						// if these aren't set, then facet on this field and finished
						if ("country" == $field || "settlement" == $field) {
								break;
						}
				}
				else {
						$params[$f] = $_REQUEST[$f];
						$searchParams[$f] = $_REQUEST[$f];
				}
		}
		
    $dom = $solr->getDocumentsByType($type, $offset, $limit);
    $page->setDom($dom);
} while (false);

if ($params) {
    $page->setParams($params);
}

print $page;

?>

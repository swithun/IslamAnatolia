<?php

/****** /list.php
 * NAME
 * list.php
 * SYNOPSIS
 * Page for listing documents in the system. This is the public version, so only the latest version of each document is going to be visible.
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20120710
 * SEE ALSO
 *   * includes/globals.php
 *   * xslt/list_documents_public.xsl
 * BUGS
 * Options for sorting and filtering documents can be added later.
 ******
 */

require_once "includes/globals.php";

$params = array();
$searchParams = array();
$xsltFile = XSLT_DIR . "search.xsl";
$page = new Page($xsltFile);

// paging variables
$offset = 0;
$limit = 50;

do {
    // which document type to show
    $type = isset($_REQUEST["type"]) ? $_REQUEST["type"] : "ms";

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

    $solr = new Solr();

		// work out which facets to use
		$physical_location_fields = array("country", "settlement", "institution", "repository", "collection");
		foreach ($physical_location_fields as $field) {
				$f = "physical_location_" . $field;
				
				// not yet facetting on this field
				if (!isset($_REQUEST[$f])) {
						// so add facet for this field
						$solr->addFacet($f);
						// for country/settlement fields, only going to add this one facet
						if ("country" == $field || "settlement" == $field) {
								break;
						}
				}
				// already faceting on this field
				else {
						$params[$f] = $_REQUEST[$f];
						$searchParams[$f] = $_REQUEST[$f];
				}

				/*if ("country" == $field || "settlement" == $field) {
						if (!isset($_REQUEST[$f])) {
								$solr->addFacet($f);
								break;
						}
						$params[$f] = $_REQUEST[$f];
						$searchParams[$f] = $_REQUEST[$f];
				}
				else {
						if (!isset($_REQUEST[$f])) {
								$solr->addFacet($f);
						}
						else {
								$params[$f] = $_REQUEST[$f];
								$searchParams[$f] = $_REQUEST[$f];
						}
				}*/
		}

		$searchParams["type_of_resource"] = $type;
		$dom = $solr->simpleSearch($searchParams, $offset);

		//$dom = $solr->getDocumentsByType($type, $offset);
    $page->setDom($dom);
} while (false);

if ($params) {
    $page->setParams($params);
}

print $page;

?>

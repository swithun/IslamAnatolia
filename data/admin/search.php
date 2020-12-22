<?php

/****** admin/search.php
 * NAME
 * search.php
 * SYNOPSIS
 * Page for displaying search results. Form parameters are passed to Solr and the XML response is transformed to HTML.
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20120710
 * SEE ALSO
 *   * includes/globals.php
 *   * xslt/search.xsl
 * BUGS
 * Advanced search options are not yet available.
 * http://localhost:8983/solr/select?q={!join+from=id+to=relation_bibliography}name:schmidt
 * returns documents which have a bibliographic relation to documents which match a name schmidt
 * http://localhost:8983/solr/select?q=text:two+AND+_query_:%22{!join+from=id+to=relation_authority}name:Muhammad%22
 * returns MS documents containing the word 'two' and which refer to an authority document containing the name Muhammad
 ******
 */

require_once "../includes/globals.php";

$xsltFile = XSLT_DIR . "list_documents.xsl";
$params = array();
$page = new Page($xsltFile);

$offset = 0;
$limit = 50;

do {
    // q should be a word
    if (!isset($_REQUEST["q"]) || "" == $_REQUEST["q"]) {
				$params["message"] = "No search query";
				$params["messageClass"] = "error";
				break;
    }

    // form data
    $offset = isset($_REQUEST["offset"]) && (int) $_REQUEST["offset"] ?
      (int) $_REQUEST["offset"] : $offset;
    $limit = isset($_REQUEST["limit"]) && (int) $_REQUEST["limit"] ?
      (int) $_REQUEST["limit"] : $limit;
    $query = isset($_REQUEST["q"]) ? $_REQUEST["q"] : "";

    // generate query string based on current query, but with offset removed
    if (isset($_GET["offset"])) {
				unset($_GET["offset"]);
    }

    $params["url"] = sprintf("%s?%s",
														 $_SERVER["PHP_SELF"],
														 http_build_query($_GET));
    $params["query"] = $query;
    $params["offset"] = $offset;
    $params["limit"] = $limit;
    $params["title"] = sprintf("Search for '%s'", $query);
    $params["search_type"] = "search";
		
		$searchParams = array("q" => $query);

    $solr = new Solr();
				
    $dom = $solr->simpleSearch($searchParams, $offset, $limit);

    $page->setDom($dom);
} while (false);

$page->setParams($params);
print $page;

?>

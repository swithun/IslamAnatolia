<?php

/****** /advanced_search.php
 * NAME
 * advanced_search.php
 * SYNOPSIS
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20120710
 * SEE ALSO
 *   * includes/globals.php
 *   * xslt/search.xsl
 * NOTES
 * http://localhost:8983/solr/select?q={!join+from=id+to=relation_bibliography}name:schmidt
 * returns documents which have a bibliographic relation to documents which match a name schmidt
 * http://localhost:8983/solr/select?q=text:two+AND+_query_:%22{!join+from=id+to=relation_authority}name:Muhammad%22
 * returns MS documents containing the word 'two' and which refer to an authority document containing the name Muhammad
 ******
 */

require_once "includes/globals.php";

$xsltFile = XSLT_DIR . "advanced_search.xsl";
$params = array();
$page = new Page($xsltFile);
$offset = 0;
$limit = 50;

do {
    // no form submitted, so break out
    if (!isset($_REQUEST["submit"])) {
        break;
    }

    // get form data
    $query_ms = isset($_REQUEST["query_ms"]) ? $_REQUEST["query_ms"] : "";
    $query_author = isset($_REQUEST["query_author"]) ? $_REQUEST["query_author"] : "";
    $query_authority = isset($_REQUEST["query_authority"]) ? $_REQUEST["query_authority"] : "";
    $query_bib = isset($_REQUEST["query_bib"]) ? $_REQUEST["query_bib"] : "";
    $return_type = isset($_REQUEST["return_type"]) ? $_REQUEST["return_type"] : MANUSCRIPT_TYPE;
    $offset = isset($_REQUEST["offset"]) && (int) $_REQUEST["offset"] ? (int) $_REQUEST["offset"] : $offset;
    $limit = isset($_REQUEST["limit"]) && (int) $_REQUEST["limit"] ? (int) $_REQUEST["limit"] : $limit;

    // put form params back into page params
    $params["query_ms"] = $query_ms;
    $params["query_author"] = $query_author;
    $params["query_authority"] = $query_authority;
    $params["query_bib"] = $query_bib;
    $params["return_type"] = $return_type;
    $params["offset"] = $offset;
    $params["limit"] = $limit;
    $params["search_type"] = "search";

    // generate query string based on current query, but with offset removed
    if (isset($_GET["offset"])) {
        unset($_GET["offset"]);
    }

    $params["url"] = sprintf("%s?%s",
                             $_SERVER["PHP_SELF"],
                             http_build_query($_GET));

    // sanity check - need a query
    if ("" == $query_ms && "" == $query_author && "" == $query_authority && "" == $query_bib) {
        $params["message"] = "need a query";
        $params["messageClass"] = "error";
        break;
    }

    // non-MS return types require a query for that document type
    if ((AUTHORITY_TYPE == $return_type && "" == $query_author && "" == $query_authority) ||
        (BIBLIOGRAPHY_TYPE == $return_type && "" == $query_bib)) {
        $params["message"] = "Wrong return type for query";
        $params["messageClass"] = "error";
        break;
    }

    $solr = new Solr();
    $dom = $solr->advancedSearch($query_ms,
                                 $query_author,
                                 $query_authority,
                                 $query_bib,
                                 $return_type,
                                 $offset);

    $page->setDom($dom);
} while (false);

$page->setParams($params);
print $page;

?>

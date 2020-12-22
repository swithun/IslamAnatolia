<?php

/****** /index.php
 * NAME
 * index.php
 * SYNOPSIS
 * Index page for showing options for the public, e.g. search or list documents.
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20120710
 * SEE ALSO
 *   * includes/globals.php
 *   * xslt/index.xsl
 ******
 */

require_once "includes/globals.php";
require_once "includes/searchFunctions.php";

$page = new Page(XSLT_DIR . "index.xsl");
$solr = new Solr();

// default number of hits
$hits = 10;

// params for search
$params = array();

// offset for search
$offset = offset();

$haveFacets = false;

// doctype and field are the main search params
$doctype = isset($_REQUEST["doctype"]) ? $_REQUEST["doctype"] : "work";
//$_REQUEST["field"] = isset($_REQUEST["field"]) ? $_REQUEST["field"] : "text";
$sortField = isset($_REQUEST["sort_field"]) ? $_REQUEST["sort_field"] : "relevance";
$sortDirection = isset($_REQUEST["sort_direction"]) ? $_REQUEST["sort_direction"] : "desc";

// modify doctype?
if (isset($_REQUEST["field"]) && in_array("people", $_REQUEST["field"])) {
    $doctype = "people";
}
else {
    if (isset($_REQUEST["field"]) && in_array("classmark", $_REQUEST["field"])) {
        $doctype = "ms";
    }
    
    // check for used facets and remove them from list and add them to params
    $haveFacets = removeFacets($params,
                               $solr->getDateFormat(),
                               $solr->getGap());
}

// hits per page
$solr->setRows(isset($_REQUEST["hits"]) ? (int) $_REQUEST["hits"] : $hits);

// handle text query
checkQuery($params);

// generate XSLT params and add them to page
$page->setParams(xsltParams($haveFacets, $doctype));

// can run Solr query now
$page->setDom(runQueries($params, $offset, $doctype, $sortField, $sortDirection));

saveSearchURI();

print $page;

?>

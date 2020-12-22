<?php

/****** admin/basket.php
 * NAME
 * basket.php
 * SYNOPSIS
 * Do things with a basket of documents - add to the basket, display the basket, remove from basket etc.
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20131011
 * SEE ALSO
 *   * includes/globals.php
 *   * includes/msFunctions.php
 ******
 */

require_once "../includes/globals.php";
require_once "../includes/msFunctions.php";

/****f* basket.php/addToBasket
 * NAME
 * addToBasket
 * SYNOPSIS
 * Add array of hits (selected documentNames) to session basket.
 * ARGUMENTS
 *   * hits - array - array of document names
 ******
 */
function addToBasket($hits) { //{{{
    if (!isset($_SESSION["basket"]) || !is_array($_SESSION["basket"])) {
        $_SESSION["basket"] = array();
    }
    
    foreach ($hits as $hit) {
        if (!in_array($hit, $_SESSION["basket"])) {
            $_SESSION["basket"][] = $hit;
        }
    }
}
//}}}

/****f* basket.php/downloadZip
 * NAME
 * downloadZip
 * SYNOPSIS
 * Creates a ZIP archive containing the documents identified by the hits array.
 * ARGUMENTS
 *   * hits - array - array of strings made up of document name | type
 ******
 */
function downloadZip($hits) { //{{{
    $zip = new Zip();
    $types = array("ms" => 1, "auth" => 2, "bib" => 3);
    $db = new DB();
    
    foreach ($hits as $hit) {
        list ($name, $type) = explode("|", $hit);
        $type = $types[$type];
        
        $db->getLatestVersionByName(bin2hex($name), $type);
        $results = $db->getResults();
        
        if (!$results) {
            continue;
        }
        
        $doc = $results[0];
        $versionName = getFilename($doc['versionPath'], $doc['versionUUID']);
        
        $zip->addFile($versionName, $doc['documentName']);
    }
    
    $zip->download();
}
//}}}

/****f* basket.php/viewBasket
 * NAME
 * viewBasket
 * SYNOPSIS
 * Gets a Solr DOM containing the results of searching for the documents in the basket.
 * RETURN VALUE
 * DOM - DOM from Solr containing search results
 ******
 */
function viewBasket() { //{{{
    $solr = new Solr();
    return $solr->basketSearch($_SESSION["basket"], 0);
}
//}}}

/****f* basket.php/deleteDocuments
 * NAME
 * deleteDocuments
 * SYNOPSIS
 * Delete document from basket, and optionally from the file system too.
 * ARGUMENTS
 *   * hitsRequest - array - array of document name|type
 *   * del - boolean - delete from file system too, if true, default false
 ******
 */
function deleteDocuments($hitsRequest, $del=false) { //{{{
    // hits to remove from basket
    $hits = array();
    
    // loop over items to delete, remembering document names
    foreach ($hitsRequest as $hit) {
        list($name, $type) = explode("|", $hit);
        if (!$type) {
            continue;
        }
        
        // delete from system?
        if ($del) {
            deleteDocumentByName($name, $type);
        }
        
        // add to list of ones to delete from basket
        $hits[] = $name;
    }
    
    // remove remembered document names from basket
    $_SESSION["basket"] = array_diff($_SESSION["basket"], $hits);
}
//}}}

$action = isset($_REQUEST["action"]) ? $_REQUEST["action"] : "view";
$basket_xslt = XSLT_DIR . "basket.xsl";
$url = $_SERVER["PHP_SELF"] . "?action=view";

do {
    switch ($action) {
        // add to basket and then go back to given URL
     case "add":
        if (isset($_REQUEST["hits"])) {
            addToBasket($_REQUEST["hits"]);
        }
        if (isset($_REQUEST["url"])) {
            $url = $_REQUEST["url"];
        }
        break;

        // delete items from system and basket
     case "delete":
        if (isset($_REQUEST["confirm"]) && 1 == $_REQUEST["confirm"]
            && isset($_REQUEST["hits"])) {
            deleteDocuments($_REQUEST["hits"], true);
        }
        break;
        
        // remove items from basket
     case "remove":
        if (isset($_REQUEST["hits"])) {
            deleteDocuments($_REQUEST["hits"]);
        }
        break;
        
        // download ZIP of selected items
     case "download":
        if (isset($_REQUEST["hits"])) {
            downloadZip($_REQUEST["hits"]);
        }
        break;

        // view basket is default
     case "view":
     default:
        $page = new Page($basket_xslt);
        $page->setDom(viewBasket());
        $page->setParams(array("search_type" => "basket"));
        print $page;
        $url = "";
        break;
    }
} while (false);

// redirect to $url if no headers sent yet (view/download)
if (!headers_sent() && $url) {
    header("Location: " . $url);
}

?>
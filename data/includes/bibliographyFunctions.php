<?php

/****** includes/bibliographyFunctions.php
 * NAME
 * bibliographyFunctions.php
 * SYNOPSIS
 * Various functions for dealing with bibliographies.
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20120710
 ******
 */

/****f* bibliographyFiles.php/addBook
 * NAME
 * addBook
 * SYNOPSIS
 * ARGUMENTS
 *   * bookNode - DOMNode - node from DOM containing data on single bibliographic record
 * RETURN VALUE
 * Boolean - true on success
 * BUGS
 * Not used
 ******
 */
function addBook($bookNode) { //{{{
    $success = false;
    
    do {
        // get node into new DOM
        $dom = new DomDocument();
        $bookNode = $dom->importNode($bookNode, true);
        $bookNode = $dom->appendChild($bookNode);
        
        // get ID of book from mods:classification
        $nodes = $dom->getElementsByTagName(//NS("http://www.loc.gov/mods/v3",
                                              "classification");
        if (!$nodes || 0 == $nodes->length) {
            break;
        }
        
        $bookID = $nodes->item(0)->nodeValue;
        
        // save book node as XML
        list ($path, $newName) = uniqueFileName();
        if (!$newName) {
            break;
        }
        
        $newPath = getFilename($path, $newName);
        if (!$dom->save($newPath)) {
            break;
        }
        
        // add to database
        $db = DB::getInstance();
        $db->addDocument($bookID, BIBLIOGRAPHY_TYPE,
                         $newName, $path, getUser());

        $success = true;
    } while (false);
    
    return $success;
}
//}}}

/****f* bibliographyFunctions.php/newBibliographicItem
 * NAME
 * newBibliographicItem
 * SYNOPSIS
 * Takes the DOM of a new bibliographic item, converts it to Solr XML, sends it to Solr and adds it to database.
 * The DOM is finally saved in its new location.
 * ARGUMENTS
 *   * dom - the bibliographic item in a DOM
 *   * message - string - holds any error message, passed by reference
 *   * index - boolean - if true, just index in Solr, but don't save DOM or add to database
 * RETURN VALUE
 * ID string on success, false otherwise
 ******
 */
function newBibliographicItem($modsDom, &$message, $index=false) { //{{{
    $success = false;

    $mods2solrFileName = XSLT_DIR . "mods2solr.xsl";
    
    do {
        // transform MODS to Solr
        $mods2solrXSLT = new XSLT($mods2solrFileName);
        $mods2solrXSLT->addParams(array("docType" => "bib"));
        $solrDoc = $mods2solrXSLT->transformToDom($modsDom);
        
        // check Solr Dom for field elements
        if (!$solrDoc->getElementsByTagName("field")->length) {
            //$message = "Solr DOM empty";
            break;
        }

        // send to Solr and get IDs of documents
        $solr = Solr::getInstance();
        if (!$solr) {
            $message = "Solr connection failed";
            break;
        }

        /*$db = null;
        if (!$index) {
            $db = DB::getInstance();
            if (!$db) {
                $message = "DB connection failed";
                break;
            }
        }*/
        
        $id = $solr->addDocument($solrDoc, $message);
        if (!$id) {
            break;
        }
        
        // just indexing, so can finish
        if ($index) {
            $success = true;
            break;
        }

        // get file name for authority file
        list ($path, $newName) = uniqueFileName();
        if (!$newName) {
            $message = "Problem creating file for bibliography";
            break;
        }

        // connect to DB
        $db = DB::getInstance();
        if (!$db) {
            $message = "DB connection failed";
            break;
        }

        // record it in database
        $db->addDocument($id, BIBLIOGRAPHY_TYPE,
                         $newName, $path, getUser());

        // save DOM
        $newPath = getFilename($path, $newName);
        if (!$modsDom->save($newPath)) {
            $message = "Problem saving bibliographic record";
            break;
        }
        
        $success = $id;
    } while (false);
    
    return $success;
}
//}}}

/****f* bibliographyFiles.php/bibliographyFile
 * NAME
 * bibliographyFile
 * SYNOPSIS
 * Called from within an XSLT script, when processing reaches bibl/ref/@target
 * ARGUMENTS
 *   * callNumber - string - ID of book
 * RETURN VALUE
 * DOMElement - the document node of a DOM containing the MODS XML of a bibliography file
 ******
 */
function bibliographyFile($callNumber) { //{{{
    // DOM to return document element of
    $returnDom = false;
    
    // get DB connection
    $db = DB::getInstance();
    
    // look for book document
    $db->getLatestVersionByName(bin2hex($callNumber), 
                                BIBLIOGRAPHY_TYPE);
    $results = $db->getResults();
    
    do {
        // book not in bibliography (yet)
        if (!$results) {
            break;
        }
        
        // look for file
        $returnDom = getDom($results[0]["versionPath"],
                            $results[0]["versionUUID"]);
        
        // load into DOM
        if (!$returnDom) {
            break;
        }
        
    } while (false);

    if (!$returnDom) {
        $returnDom = new DomDocument();
        $root = $returnDom->createElement("notFound");
        $root->setAttribute("id", $callNumber);
        $returnDom->appendChild($root);
    }
    
    return $returnDom->documentElement;
}
//}}}

/****f* authorityFilesFunctions.php/uploadBibliographyFile
 * NAME
 * uploadbibliographyFile
 * SYNOPSIS
 * Takes uploaded bibliography file and adds each item in the file to the system as a bibliographic record.
 * ARGUMENTS
 *   * message - string - passed by reference, to store any error message generated
 *   * contents - string - optional content of file, used when ZIP was uploaded
 *   * index - boolean - if true, just index in Solr, but don't save DOM or add to database
 * RETURN VALUE
 * Array of IDs, some of which may be false
 ******
 */
function uploadBibliographyFile(&$message, $bibDom, $index=false) { //{{{
    $success = false;
    
    do {
        $ids = array();
        
        // create singletons
        $solr = Solr::getInstance();
        $db = DB::getInstance();
        
        // loop over mods elements in DOM
        $mods = $bibDom->getElementsByTagNameNS(MODS_URI, "mods");
        foreach ($mods as $node) {
            // put node into new DOM
            $dom = new DomDocument();
            $root = $dom->importNode($node, true);
            $dom->appendChild($root);
            $root->setAttribute("xmlns", "http://www.loc.gov/mods/v3");
            
            // add bibliographic record
            $m = "";
            $id = newBibliographicItem($dom, $m, $index);
            if (!$id) {
                $message .= $m . " ";
            }
            else {
                $ids[] = $id;
            }
        }
        
        $success = count($ids) > 0;
    } while (false);
    
    return $success;
}
//}}}

?>

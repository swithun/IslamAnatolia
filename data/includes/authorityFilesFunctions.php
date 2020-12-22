<?php

/****** includes/authorityFilesFunctions.php
 * NAME
 * authorityFilesFunctions.php
 * SYNOPSIS
 * Various functions for dealing with authority files - fetching, storing, retrieving etc.
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20120710
 ******
 */

/****f* authorityFilesFunctions.php/myCurl
 * NAME
 * myCurl
 * SYNOPSIS
 * Fetches remote files using cURL and returns the contents.
 * get_file_content doesn't always work on remote files.
 * ARGUMENTS
 *   * url - string - the URL of the file to fetch
 * RETURN VALUE
 * String - the contents of the file, or empty string on failure
 ******
 */
function myCurl($url) { //{{{
    $data = "";
    $options = array(CURLOPT_URL => $url,
                     CURLOPT_RETURNTRANSFER => true,
                     CURLOPT_TIMEOUT => 5);

    do {
        if (!$url) {
            break;
        }

        $c = curl_init();
        if (!$c) {
            break;
        }

        if (!curl_setopt_array($c, $options)) {
            break;
        }

        $data = curl_exec($c);
        $code = (int) curl_getinfo($c, CURLINFO_HTTP_CODE);
        
        // discard responses which aren't successful (2xx)
        if ($code < 200 || $code >= 300) {
            $data = "";
        }
        curl_close($c);
    } while (false);

    return $data;
}
//}}}

/****f* authorityFilesFunctions.php/authorityFiles
 * NAME
 * authorityFiles
 * SYNOPSIS
 * Called from within XSLT scripts. It takes a list of URNs which identify authority files.
 * These files either already exist locally, or have to be fetched from remote sites and stored.
 * The function returns the root node of a document containing all the authority files identified.
 * This node can then be processed with an xslt:apply-templates.
 * ARGUMENTS
 *   * urns - string - space delimited list of URNs that identify authority files
 * RETURN VALUE
 * DOMElement - the document node of a DOM containing all the authority files
 ******
 */
function authorityFiles($urns) { //{{{
    // create DOM, will return root element
    $returnDOM = new DomDocument();
    $root = $returnDOM->createElement("root");
    $root = $returnDOM->appendChild($root);

    // connect to DB
    $db = DB::getInstance();

    // get list of URNs from space delimited list
    $urns = explode(" ", trim($urns));
    foreach ($urns as $urn) {
        if ("" == $urn) {
            continue;
        }
        
        // look up URN in database
        $db->getLatestVersionByName(bin2hex($urn),
                                    AUTHORITY_TYPE);
        $results = $db->getResults();

        // DOM for loading XML authority file into
        $dom = null;

        // have local file
        if ($results) {
            // load local file into DOM
            $dom = getDom($results[0]["versionPath"],
                          $results[0]["versionUUID"]);

            if (!$dom) {
                continue;
            }
            //printf("found local copy of %s\n", $urn);
        }
        else {
            //printf("looking for %s\n", $urn);
            continue; // don't bother trying to fetch files just now
            // fetch XML by transforming urn to URL
            $url = urn2url($urn);
            if (!$url) {
                continue;
            }
            
            $xml = myCurl($url);
            if (!$xml) {
                continue;
            }
            
            // put XML into DOM, process it and save it
            $dom = new DomDocument();
            if (!$dom->loadXml($xml)) {
                continue;
            }

            // put into system - Solr, file system and database
            $message = "";
            if (!newAuthorityFile($dom, $message)) {
                continue;
            }
            //printf("downloaded copy of %s\n", $urn);
        }
        
        // add to root
        $importedRoot = $returnDOM->importNode($dom->documentElement,
                                               true);
        $root->appendChild($importedRoot);
    }

    return $root;
}
//}}}

/****f* authorityFilesFunctions.php/newAuthorityFile
 * NAME
 * newAuthorityFile
 * SYNOPSIS
 * Takes the DOM of a new authority file, converts it to Solr XML, sends it to Solr and adds it to database.
 * ARGUMENTS
 *   * madsDom - the authority file in a DOM
 *   * message - string to hold any error messages, passed by reference
 *   * index - boolean - if true, just index in Solr, but don't save DOM or add to database
 * RETURN VALUE
 * The full path to the file to save the XML
 ******
 */
function newAuthorityFile($madsDom, &$message, $index=false) { //{{{
    $success = false;

    $mads2modsFileName = XSLT_DIR . "teiMs2mods.xsl";
    $mods2solrFileName = XSLT_DIR . "mods2solr.xsl";

    do {
        // transform MADS to MODS and then to Solr
        $mads2modsXSLT = new XSLT($mads2modsFileName);
        $mads2modsXSLT->addParams(array("mads" => "true"));
        $modsDoc = $mads2modsXSLT->transformToDom($madsDom);
        $mods2solrXSLT = new XSLT($mods2solrFileName);
        $mods2solrXSLT->addParams(array("docType" => "authority"));
        $solrDoc = $mods2solrXSLT->transformToDom($modsDoc);

        // send to Solr and get IDs of documents
        $solr = Solr::getInstance();
        if (!$solr) {
            $message = "Solr connection failed";
            break;
        }
        
        $db = null;
        if (!$index) {
            $db = DB::getInstance();
            if (!$db) {
                $message = "DB connection failed";
                break;
            }
        }
        
        $authID = $solr->addDocument($solrDoc, $message);
        if (!$authID) {
            $message = "Problem indexing authority file";
            break;
        }
        
        // just indexing, so finish
        if ($index) {
            $success = true;
            break;
        }

        // get file name for authority file
        list ($path, $newName) = uniqueFileName();
        if (!$newName) {
            $message = "Problem generating file name for authority file";
            break;
        }

        // save to file system
        $returnPath = getFilename($path, $newName);
        if (false === $madsDom->save($returnPath)) {
            $message = "Problem saving authority file";
            break;
        }

        // record it in database
        $db->addDocument($authID, AUTHORITY_TYPE,
                         $newName, $path, getUser());

        $success = true;
    } while (false);

    return $success;
}
//}}}

/****f* authorityFilesFunctions.php/urn2url
 * NAME
 * urn2url
 * SYNOPSIS
 * Maps a URN to a URL, based on the prefix of the URN.
 * ARGUMENTS
 *   * urn - string - a URN that identifies an authority file
 * RETURN VALUE
 * String - the URL identified by the URN or empty string on failure
 ******
 */
function urn2url($urn) { //{{{
    $url = "";
    
    do {
        // split urn into prefix and ID
        $fields = explode(":", $urn, 2);
        
        if (2 > count($fields)) {
            break;
        }
        
        switch ($fields[0]) {
            // Library of Congress
         case "lccn":
            $url = sprintf(LCCN_URL_FORMAT,
                           $fields[1]);
            break;
            // local identifier - should have been added already
         case "local":
            $url = "";
            break;
         default:
            break;
        }
    } while (false);

    return $url;
}
//}}}

/****f* authorityFilesFunctions.php/getURNFromAuthorityFile
 * NAME
 * getURNFromAuthorityFile
 * SYNOPSIS
 * Get the URN identifying the authority file. It will be something like lccn:n123456789 or local:cs2:123.
 * The suffix is located in a mads:identifier element, with the prefix in a @type attribute.
 * ARGUMENTS
 *   * fileName - string - location of authority file (probably where it has just been uploaded)
 * RETURN VALUE
 * String - the URN identifying the authority file
 ******
 */
function getURNFromAuthorityFile($fileName) { //{{{
    $urn = "";

    do {
        // load authority file into DOM
        $dom = DomDocument::load($fileName);
        if (!$dom) {
            break;
        }

        // get mads:identifier
        $ids = $dom->getElementsByTagNameNS("http://www.loc.gov/mads/v2",
                                            "identifier");
        if (!$ids || 0 == $ids->length) {
            break;
        }

        // mads:identifier must have @type attribute
        $node = $ids->item(0);
        if (!$node->hasAttribute("type")) {
            break;
        }

        $urn = sprintf("%s:%s",
                       $node->getAttribute("type"),
                       $node->nodeValue);
    } while (false);

    return $urn;
}
//}}}

/****f* authorityFilesFunctions.php/uploadAuthorityFile
 * NAME
 * uploadAuthorityFile
 * SYNOPSIS
 * Adds uploaded authority file to system (Solr, file system and database)
 * ARGUMENTS
 *   * message - string - passed by reference, to store any error message generated
 *   * contents - string - optional content of file, used when ZIP was uploaded
 *   * index - boolean - if true, just index in Solr, but don't save DOM or add to database
 * RETURN VALUE
 * boolean - true when addition of file has been successful
 ******
 */
function uploadAuthorityFile(&$message, $madsDom, $index=false) { //{{{
    return newAuthorityFile($madsDom, $message, $index);
}
//}}}

/****f* authorityFilesFunctions.php/getReferers
 * NAME
 * getReferers
 * SYNOPSIS
 * Find any MS documents which refer to the named authority file.
 * ARGUMENTS
 * name - string - name of authority file
 * dom - DomDocument - passed by reference, DOM containing authority file, to which Solr DOM of refering MS documents will be added
 * message - string - passed by reference, will hold any error message
 * RETURN VALUE
 * boolean - true on success
 ******
 */
function getReferers($name, &$dom, &$message) { //{{{
    $success = false;
    
    do {
        $solr = Solr::getInstance();
        if (!$refDom = $solr->referers($name)) {
            $message = "Couldn't query Solr for refering documents";
            break;
        }
        
        if (!$refDom = $dom->importNode($refDom->documentElement, true)) {
            $message = "Couldn't import Solr results";
            break;
        }
        
        if (!$dom->documentElement->appendChild($refDom)) {
            $message = "Couldn't append Solr results";
            break;
        }
        
        $success = true;
    } while (false);
    
    return $success;
}
//}}}

?>

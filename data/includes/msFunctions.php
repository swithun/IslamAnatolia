<?php

/****** includes/msFunctions.php
 * NAME
 * msFunctions.php
 * SYNOPSIS
 * Various functions for dealing with manuscript documents
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20121105
 ******
 */

/****f* msFunctions.php/workCopies
 * NAME
 * workCopies
 * SYNOPSIS
 * Given the author key and title of a work, it looks for other manuscripts with the same author and title.
 * The function returns the root node of a document containing all the manuscripts identified as copies of the same work.
 * This node can then be processed with an xslt:apply-templates.
 * ARGUMENTS
 *   * title - string - main title of manuscript
 *   * authorKey - string - key identifying author
 *   * currentID - string - ID of current manuscript to exclude
 * RETURN VALUE
 * DOMElement - the document node of a DOM containing all the matching manuscripts
 ******
 */
function workCopies($title, $authorKey, $currentID) { //{{{
    // create DOM, will return root element
    $returnDOM = new DomDocument();
    $root = $returnDOM->createElement("root");
    $returnDOM->appendChild($root);

    do {
        // connect to DBs
        $db = DB::getInstance();
        $solr = Solr::getInstance();

        // get Solr DOM from query
        $dom = $solr->workCopySearch($title, $authorKey);
        if (!$dom) {
            break;
        }

        // get result document IDs
        $strs = $dom->getElementsByTagName("str");
        foreach ($strs as $str) {
            // look for @name  = 'id'
            if (!$str->hasAttribute("name") ||
                "id" != $str->getAttribute("name")) {
                continue;
            }

            if ($str->nodeValue == $currentID) {
                continue;
            }

            $db->getLatestVersionByName(bin2hex($str->nodeValue),
                                        MANUSCRIPT_TYPE);
            $results = $db->getResults();

            if (!$results) {
                continue;
            }

            // put document into temporary DOM
            $tempDOM = getDom($results[0]["versionPath"],
                              $results[0]["versionUUID"]);
            if (!$tempDOM) {
                continue;
            }

            // import into DOM
            $doc = $returnDOM->importNode($tempDOM->documentElement,
                                          true);
            $root->appendChild($doc);
        }
    } while (false);

    return $root;
}
//}}}

/****f* msFunctions.php/findAuthorityFiles
 * NAME
 * findAuthorityFiles
 * SYNOPSIS
 * Takes a space delimited list of @key values, which are the ID strings for authority files.
 * Looks them up in the database and loads all that it finds into a DOM to send back.
 * The nodes can then be used in a XSLT stylesheet.
 * ARGUMENTS
 *   * keys - string - space delimited list of @key values
 * RETURN VALUE
 * DOMElement - the document node of a DOM containing all the matching authority files
 ******
 */
function findAuthorityFiles($keys) { //{{{
    // create DOM, will return root element
    $returnDOM = new DomDocument();
    $root = $returnDOM->createElement("root");
    $returnDOM->appendChild($root);

    do {
        // convert keys string into unique array
        $ids = array_unique(explode(" ", trim($keys)));
        if (!$ids) {
            break;
        }
        
        // connect to DB
        $db = DB::getInstance();

        // loop over IDs
        foreach ($ids as $id) {
            $db->getLatestVersionByName(bin2hex($id),
                                        AUTHORITY_TYPE);
            $results = $db->getResults();

            if (!$results) {
                continue;
            }

            // put document into temporary DOM
            $tempDOM = getDom($results[0]["versionPath"],
                              $results[0]["versionUUID"]);
            if (!$tempDOM) {
                continue;
            }

            // import into DOM
            $doc = $returnDOM->importNode($tempDOM->documentElement,
                                          true);
            $root->appendChild($doc);
        }
    } while (false);

    return $root;
}
//}}}

/****f* msFunctions.php/deleteDocument
 * NAME
 * deleteDocument
 * SYNOPSIS
 * Takes a document ID, and deletes it from Solr, the file system and the database.
 * ARGUMENTS
 * id - integer - ID of documents to delete
 * type - string - type of document to delete
 * RETURN VALUE
 * boolean - true when deletion has been successful
 * NOTES
 * Not only for manuscript documents, but for all document types.
 ******
 */
function deleteDocument($id, $type) { //{{{
    $success = false;

    do {
        $solr = Solr::getInstance();
        $db = DB::getInstance();

        // get all instances of document in file system
        $db->getVersionsByDocID($id);
        $results = $db->getResults();
        if (!$results) {
            break;
        }

        // Solr needs document name
        $documentName = $results[0]["documentName"];

        // delete from Solr
        if (!$solr->deleteDocument($documentName)) {
            break;
        }

        if ("ms" == $type &&
            !$solr->deleteDocument($documentName . "_record")) {
            break;
        }

        // delete from file system
        foreach ($results as $row) {
            $filename = getFilename($row["versionPath"], $row["versionUUID"]);
            if (!unlink($filename)) {
                break 2;
            }
        }

        // delete from database
        $db->deleteDocumentByDocID($id);

        $success = true;
    } while (false);

    return $success;
}
//}}}

/****f* msFunctions.php/deleteDocumentByName
 * NAME
 * deleteDocumentByName
 * SYNOPSIS
 * Takes a document name, and deletes it from Solr, the file system and the database.
 * ARGUMENTS
 * name - string - name of documents to delete
 * type - string - type of document to delete
 * RETURN VALUE
 * boolean - true when deletion has been successful
 * NOTES
 * Not only for manuscript documents, but for all document types.
 ******
 */
function deleteDocumentbyName($name, $type) { //{{{
    $success = false;

    do {
        $solr = Solr::getInstance();
        $db = DB::getInstance();

        // delete from Solr
        if (!$solr->deleteDocument($name)) {
            break;
        }

        // delete works of MS
        if ("work" == $type &&
            !$solr->deleteDocument($name . ";*")) {
            break;
        }

        // get all instances of document in file system
        $db->getVersionsByDocName(bin2hex($name));
        $results = $db->getResults();
        if (!$results) {
            break;
        }

        // delete from file system
        foreach ($results as $row) {
            $filename = getFilename($row["versionPath"], $row["versionUUID"]);
            if (!unlink($filename)) {
                break 2;
            }
        }

        // delete from database
        $db->deleteDocumentByDocName(bin2hex($name));

        $success = true;
    } while (false);

    return $success;
}
//}}}

/****f* msFunctions.php/uploadMS
 * NAME
 * uploadMS
 * SYNOPSIS
 * Adds uploaded MS document to system (Solr, file system and database)
 * ARGUMENTS
 *   * message - string - passed by reference, to store any error message generated
 *   * teiDom - DomDocument - DOM containing TEI document
 *   * index - boolean - if true, just index in Solr, but don't save DOM or add to database
 * RETURN VALUE
 * boolean - true when addition of file has been successful
 ******
 */
function uploadMS(&$message, $teiDom, $index=false) { //{{{
    $success = false;
    $debug = false;

    $tei2modsFileName = XSLT_DIR . "teiMs2mods.xsl";
    $mods2solrFileName = XSLT_DIR . "mods2solr.xsl";

    do {
        // connect to solr
        $solr = Solr::getInstance();
        if (!$solr) {
            $message = "Solr connection failed";
            break;
        }
        
        // merge msItems - disabled for now
        /*if (!mergeMsItems($teiDom, $message)) {
            break;
        }*/

        // transform TEI data to MODS
        $tei2modsXSLT = new XSLT($tei2modsFileName, $debug);
        $modsDom = $tei2modsXSLT->transformToDom($teiDom);

        // transform MODS to SOLR
        $mods2solrXSLT = new XSLT($mods2solrFileName, $debug);
        $mods2solrXSLT->addParams(array("docType" => "ms"));
        $dom = $mods2solrXSLT->transformToDom($modsDom);

        // send to Solr and get IDs of documents
        $msID = $solr->addDocument($dom, $message);
        // if array, then just first ID
        $msID = $msID && is_array($msID) ? $msID[0] : $msID;
        
        if (!$msID) {
            $message = "Indexing failed: msID " . $msID;
            break;
        }
        
        // if just indexing, can finish
        if ($index) {
            $success = true;
            break;
        }
        
        // generate unique filename for uploaded document
        list($path, $newName) = uniqueFileName();
        if (!$newName) {
            $message = "File name creation failed";
            break;
        }

        // save file
        $newPath = getFilename($path, $newName);
        if (false === $teiDom->save($newPath)) {
            $message = "File couldn't be saved";
            break;
        }

        // connect to DB
        $db = DB::getInstance();
        if (!$db) {
            $message = "DB connection failed";
            break;
        }

        // record this in database
        $db->addDocument($msID, MANUSCRIPT_TYPE,
                         $newName, $path, getUser());
        if (!$db->getResults()) {
            $message = "Database error";
            break;
        }

        $success = true;
    } while (false);

    return $success;
}
//}}}

/****f* msFunctions.php/mergeMsItems
 * NAME
 * mergeMsItems
 * SYNOPSIS
 * Check DB for already existing MS record. If one exists, get it and merge msItems.
 * msItems in old document but not in new one get added to new one.
 * Also looks for other elements with @corresp attributes and copies those which correspond to msItems which got moved from old to new.
 * ARGUMENTS
 *   * newDom - DomDocument - DOM containing new TEI document, passed by reference
 *   * message - string - passed by reference, to store any error message generated
 * RETURN VALUE
 * boolean - true when merger of files has been successful
 * BUG
 * After msItems have been added from old DOM to new DOM, the @xml:id on msDesc can't be
 * accessed as xml:id but only as id. Why is this? It shows up as @xml:id in the source.
 ******
 */
function mergeMsItems(&$newDom, &$message) { //{{{
    $success = false;
    
    do {
        // get ID of document
        $id = $newDom->getElementsByTagNameNS(TEI_URI, "msDesc")->item(0)->getAttribute("xml:id");
        if (!$id) {
            $message = "no ID";
            break;
        }
        
        // need DB
        $db = DB::getInstance();
        if (!$db) {
            $message = "couldn't get DB";
            break;
        }
        
        // look for older version
        if (!$db->getLatestVersionByName(bin2hex($id), MANUSCRIPT_TYPE)) {
            $message = "search for old document failed";
            break;
        }
        
        // look for results - OK if there aren't any
        $results = $db->getResults();
        if (!$results) {
            $success = true;
            break;
        }
        
        $oldDom = getDom($results[0]["versionPath"],
                         $results[0]["versionUUID"]);
        
        if (!$oldDom) {
            $message = "couldn't get old MS";
            break;
        }
        
        $oldMsItems = $oldDom->getElementsByTagNameNS(TEI_URI, "msItem");
        $newMsItems = $newDom->getElementsByTagNameNS(TEI_URI, "msItem");
        $newContents = $newDom->getElementsByTagNameNS(TEI_URI, "msContents")->item(0);
        
        $oldIDs = array();
        
        // check new DOM and add old items if they don't yet exist
        foreach ($oldMsItems as $oldItem) {
            $oldID = $oldItem->getAttribute("xml:id");

            // see if item from old doc is in new doc, skip if it is
            foreach ($newMsItems as $newItem) {
                $newID = $newItem->getAttribute("xml:id");
                if ($oldID == $newID) {
                    continue 2;
                }
            }
            
            $oldIDs[] = $oldID;
            
            // old item wasn't in list of new items, so add it
            $importedItem = $newDom->importNode($oldItem, true);
            if (!$importedItem) {
                $message = "failed to import node";
                break 2;
            }
            
            if (!$newContents->appendChild($importedItem)) {
                $message = "failed to append node";
                break 2;
            }
        }
        
        // OK if there are no nodes in old doc not in new doc
        if (!$oldIDs) {
            $success = true;
            break;
        }
        
        // locations which can have @corresp attributes
        $correspAble = array(array("", "tei:TEI", "tei:teiHeader", "tei:fileDesc", "tei:sourceDesc", "tei:msDesc", "tei:physDesc", "tei:objectDesc", "tei:supportDesc"),
                             array("", "tei:TEI", "tei:teiHeader", "tei:fileDesc", "tei:sourceDesc", "tei:msDesc", "tei:physDesc", "tei:objectDesc", "tei:supportDesc", "tei:extent", "tei:dimensions"),
                             array("", "tei:TEI", "tei:teiHeader", "tei:fileDesc", "tei:sourceDesc", "tei:msDesc", "tei:physDesc", "tei:objectDesc", "tei:layoutDesc"),
                             array("", "tei:TEI", "tei:teiHeader", "tei:fileDesc", "tei:sourceDesc", "tei:msDesc", "tei:physDesc", "tei:objectDesc", "tei:layoutDesc", "tei:layout"),
                             array("", "tei:TEI", "tei:teiHeader", "tei:fileDesc", "tei:sourceDesc", "tei:msDesc", "tei:physDesc", "tei:decoDesc", "tei:decoNote"),
                             array("", "tei:TEI", "tei:teiHeader", "tei:fileDesc", "tei:sourceDesc", "tei:msDesc", "tei:physDesc", "tei:handDesc", "tei:handNote"),
                             array("", "tei:TEI", "tei:teiHeader", "tei:fileDesc", "tei:sourceDesc", "tei:msDesc", "tei:physDesc", "tei:handDesc", "tei:handNote", "tei:p"),
                             array("", "tei:TEI", "tei:teiHeader", "tei:fileDesc", "tei:sourceDesc", "tei:msDesc", "tei:physDesc", "tei:sealDesc", "tei:p"),
                             array("", "tei:TEI", "tei:teiHeader", "tei:fileDesc", "tei:sourceDesc", "tei:msDesc", "tei:history", "tei:provenance", "tei:p[tei:persName/@role='owner']"),
                             array("", "tei:TEI", "tei:teiHeader", "tei:fileDesc", "tei:sourceDesc", "tei:msDesc", "tei:history", "tei:provenance"),
                             array("", "tei:TEI", "tei:teiHeader", "tei:fileDesc", "tei:sourceDesc", "tei:msDesc", "tei:history", "tei:acquisition"),
                             array("", "tei:TEI", "tei:teiHeader", "tei:fileDesc", "tei:sourceDesc", "tei:msDesc", "tei:history", "tei:origin"),
                             array("", "tei:TEI", "tei:teiHeader", "tei:fileDesc", "tei:sourceDesc", "tei:msDesc", "tei:history", "tei:origin", "tei:date"),
                             array("", "tei:TEI", "tei:teiHeader", "tei:fileDesc", "tei:sourceDesc", "tei:msDesc", "tei:history", "tei:origin", "tei:origPlace"));
        
        $oldXPath = new DOMXPath($oldDom);
        $oldXPath->registerNamespace("tei", TEI_URI);
        $newXPath = new DOMXPath($newDom);
        $newXPath->registerNamespace("tei", TEI_URI);

        // filter in nodes where @corresp isn't in msItem that has been copied
        $oldIDFilter = sprintf("[@corresp = '%s']",
                               implode("' or @corresp = '", $oldIDs));
        
        // look for elements in old DOM that should get added to new DOM
        foreach ($correspAble as $segments) {
            // put together path segments
            $xpath = implode("/", $segments);
            
            // find nodes in old DOM that need to be copied
            $oldNodes = $oldXPath->query(sprintf("%s[@corresp!='']%s", 
                                                 $xpath, $oldIDFilter));
            
            // no nodes to be copied from old to new, so go to next xpath
            if (0 == $oldNodes->length) {
                continue;
            }
            
            // find parent of nodes in new DOM - maybe have to go up tree
            $newNodes = $newXPath->query($xpath);
            $missing = array();
            
            while (0 == $newNodes->length) {
                if (!$segments) {
                    $message = "couldn't find nodes in new DOM";
                    break 3;
                }
                
                array_unshift($missing, array_pop($segments));
                $xpath = implode("/", $segments);
                $newNodes = $newXPath->query($xpath);
            }
            
            // parent to append copy of old node to
            $parent = $newNodes->item(0)->parentNode;
            // lose leaf node as this will be appended
            array_pop($missing);
            
            // need to recreate missing nodes to get right parent
            if ($missing) {
                $nn = $newNodes->item(0);
                foreach ($missing as $n) {
                    $newNode = $newDom->createElementNS(TEI_URI, 
                                                        substr($n, 4));
                    $nn = $nn->appendChild($newNode);
                }
                
                $parent = $nn;
            }
            
            // loop over nodes from old DOM
            foreach ($oldNodes as $oldNode) {
                // import into new DOM
                $importedItem = $newDom->importNode($oldNode, true);
                if (!$importedItem) {
                    $message = "failed to import node";
                    break 3;
                }
                
                // append to parent in new DOM
                if (!$parent->appendChild($importedItem)) {
                    $message = "failed to append node";
                    break 3;
                }
            }
        }
        
        $success = true;
    } while (false);
    
    return $success;
}
//}}}

?>

<?php

/****** admin/document_admin.php
 * NAME
 * document_admin.php
 * SYNOPSIS
 * Perform admin operations on documents.
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20121112
 * SEE ALSO
 *   * includes/globals.php
 *   * includes/msFunctions.php
 ******
 */

require_once "../includes/globals.php";
require_once "../includes/msFunctions.php";

$message = "";
$success = false;
$type = isset($_REQUEST["type"]) ? $_REQUEST["type"] : "ms";

do {
    // form not submitted
    if (!isset($_REQUEST["submitted"])) {
        $message = "no form data";
        break;
    }

    // need document ID
    $documentID = isset($_REQUEST["documentID"]) ? (int) $_REQUEST["documentID"] : 0;

    if (!$documentID) {
        $message = "need document ID";
        break;
    }

    // what to do
    $method = isset($_REQUEST["method"]) ? $_REQUEST["method"] : "";
    switch ($method) {
        // delete document from system
     case "delete":
        if (!isset($_REQUEST["confirm"]) || "" == $_REQUEST["confirm"]) {
            $message = "Need to confirm deletion";
            break;
        }

        if ($success = deleteDocument($documentID, $type)) {
            $message = "Document deleted";
        } else {
            $message = "Problem deleting document";
        }
        break;
        
        // rename document
     case "rename":
        if (isset($_REQUEST["rename"]) && "" != $_REQUEST["rename"]) {
            $success = renameDocument($documentID, $_REQUEST["rename"], $message);
        }
        break;
        
     case "download":
        break;
     default:
        $message = "need action";
        break;
    }
} while (false);

// already sent headers (download), so do nothing
if (!headers_sent()) {
    // redirect back to list_documents
    $url = "list_documents.php";
    $location = sprintf("Location: %s?type=%s&message=%s&messageClass=%s",
                        $url,
                        $type,
                        $message ? urlencode($message) : "",
                        $message ? ($success ? "success" : "error") : "");
    header($location);
}

?>

<?php

/****** admin/index.php
 * NAME
 * index.php
 * SYNOPSIS
 * Index page for admin area of site. It displays the options available to administrators.
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20120710
 * SEE ALSO
 *   * includes/globals.php
 *   * xslt/admin_index.xsl
 ******
 */

require_once "../includes/globals.php";
require_once "../includes/msFunctions.php";
require_once "../includes/authorityFilesFunctions.php";
require_once "../includes/bibliographyFunctions.php";

$params = array();

// block for handling uploads
do {
    // no upload
    if (!isset($_REQUEST["is_upload"])) {
        break;
    }

    $fileItem = "doc"; // name of file upload form element
    
    // no file uploaded
    if (!isset($_FILES[$fileItem])) {
        $params["message"] = "No file uploaded";
        $params["messageClass"] = "error";
    }

    // have file upload, so proceed
    $message = "";
    $success = handleUpload($_FILES[$fileItem], $message);
    
    $params["message"] = $message;
    $params["messageClass"] = $success ? "success" : "error";
} while (false);

$xsltFile = XSLT_DIR . "admin_index.xsl";

$page = new Page($xsltFile);

if ($params) {
    $page->setParams($params);
}

print $page;

?>

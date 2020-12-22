<?php

/****** admin/upload.php
 * NAME
 * upload.php
 * SYNOPSIS
 * Page for uploading new TEI documents.
 * When a new TEI document is uploaded, it is transformed to MODS and the to Solr XML.
 * The Solr XML document is indexed by Solr. The TEI document is stored on the local file system.
 * And the document name and file name are inserted into the database.
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20120710
 * SEE ALSO
 *   * includes/globals.php
 *   * includes/msFunctions.php
 *   * includes/authorityFilesFunctions.php
 *   * includes/bibliographyFunctions.php
 *   * xslt/admin_upload.xsl
 ******
 */

require_once "../includes/globals.php";
require_once "../includes/msFunctions.php";
require_once "../includes/authorityFilesFunctions.php";
require_once "../includes/bibliographyFunctions.php";

$xsltFile = XSLT_DIR . "admin_upload.xsl";

$fileItem = "doc"; // name of file upload form element
$message = "";

// have file upload, so proceed
$success = false;
if (isset($_FILES[$fileItem])) {
    $success = handleUpload($_FILES[$fileItem], $message);
}

$params = array("message" => $message,
                "messageClass" => $success ? "success" : "error");

// had success, so redirect to admin page with message
if ($success) {
    $query = http_build_query($params);
    header("Location: index.php?" . $query);
    exit;
}
else {
    // display form for upload
    $page = new Page($xsltFile);
    $params["file_item"] = $fileItem;
    $page->setParams($params);
    
    print $page;
}

?>
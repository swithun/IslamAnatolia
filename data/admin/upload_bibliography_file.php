<?php

/****** admin/upload_bibliography_file.php
 * NAME
 * upload_bibliography_file.php
 * SYNOPSIS
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20120710
 * SEE ALSO
 *   * includes/globals.php
 *   * includes/bibliographyFunctions.php
 ******
 */

require_once "../includes/globals.php";
require_once "../includes/bibliographyFunctions.php";

$fileItem = "bibliography_file";
$xsltFile = XSLT_DIR . "admin_upload_bibliography_file.xsl";

$success = false;
$message = "";

// have file upload, so proceed
if (isset($_FILES[$fileItem])) {
		$success = handleUpload("uploadBibliographyFile", 
														$_FILES[$fileItem], $message);
}

$params = array("message" => $message ? $message : "Document/s uploaded",
								"messageClass" => $success ? "success" : "error");

// had success, so redirect to admin page with message
if ($success) {
		$query = http_build_query($params);
		header("Location: index.php?" . $query);
		exit;
}

// display form for upload
$page = new Page($xsltFile);
$params["file_item"] = $fileItem;
$page->setParams($params);

print $page;

?>

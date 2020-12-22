<?php

/****** admin/upload_authority_file.php
 * NAME
 * upload_authority_file.php
 * SYNOPSIS
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20120710
 * SEE ALSO
 *   * includes/globals.php
 *   * includes/authorityFilesFunctions.php
 *   * xslt/mads2mods.xsl
 *   * xslt/mods2solr.xsl
 *   * xslt/admin_upload_authority_file.xsl
 ******
 */

require_once "../includes/globals.php";
require_once "../includes/authorityFilesFunctions.php";

$fileItem = "authority_file";
$xsltFile = XSLT_DIR . "admin_upload_authority_file.xsl";

$success = false;
$message = "";

// have file upload, so proceed
if (isset($_FILES[$fileItem])) {
		$success = handleUpload("uploadAuthorityFile", 
														$_FILES[$fileItem], $message);
}

$params = array("message" => $message ? $message : "Document/s uploaded",
								"messageClass" => $success ? "success" : "error");

// had success, so redirect to main admin page with message
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

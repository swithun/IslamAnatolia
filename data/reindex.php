<?php

/****** /reindex.php
 * NAME
 * reindex.php
 * SYNOPSIS
 * Force a reindex of all the latest versions of all documents in system.
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20131118
 ******
 */

require_once "includes/globals.php";

require_once "includes/msFunctions.php";
require_once "includes/authorityFilesFunctions.php";
require_once "includes/bibliographyFunctions.php";

$message = "";
$success = false;

do {
		// connect to databases
		$db = new DB();
		$solr = new Solr();
		
		if (!$db || !$solr) {
				$message = "Problem connecting to databases";
				break;
		}
		
		// get latest versions
		if (!$db->getLatestVersions()) {
				$message = "Problem getting latest versions from DB";
				break;
		}
		
		$results = $db->getResults();
		if (!$results) {
				$message = "No results";
				break;
		}
		
		// reindex each one
		foreach ($results as $doc) {
				$dom = getDom($doc["versionPath"], $doc["versionUUID"]);
				$error = "";
				if (!sniffDocument($error, $dom, true)) {
						print $error . "\n";
				}
		}
		
		$success = true;
} while (false);

if (!$success || $message) {
		die($message);
}

?>
<?php

/****** admin/download.php
 * NAME
 * download.php
 * SYNOPSIS
 * Create ZIP archive of most recent versions of documents and send it to client.
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20121218
 * SEE ALSO
 *   * includes/globals.php
 ******
 */

require_once '../includes/globals.php';

$message = '';

do {
		// connect to database
		$db = new DB();
		
		// get latest versions of all documents
		if (!$db->getLatestVersions()) {
				$message = 'Problem with stored procedure';
				break;
		}
		
		$results = $db->getResults();
		if (!$results) {
				$message = 'Problem getting results';
				break;
		}

		// create ZIP
		$zip = new Zip();
		
		// add documents to ZIP
		foreach ($results as $doc) {
				$versionName = getFilename($doc['versionPath'], $doc['versionUUID']);

				if (!$zip->addFile($versionName, $doc['documentName'])) {
						$message = 'Problem adding ' . $versionName;
						break 2;
				}
		}
		
		if (!$zip->download()) {
				$message = 'Problem sending ZIP for download';
				break;
		}
} while (false);

// error before headers were sent
if (!headers_sent()) {
		print $message;
}

?>

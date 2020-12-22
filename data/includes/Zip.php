<?php

class Zip {

		/****** includes/Zip.php
		 * NAME
		 * Zip.php
		 * SYNOPSIS
		 * Class for wrapping ZipArchive functionality.
		 * AUTHOR
		 * Swithun Crowe
		 * CREATION DATE
		 * 20131113
		 ******
		 */
		
		private $zip = null;
		private $filename;
		
		/****** Zip.php/__construct
		 * NAME
		 * __construct
		 * SYNOPSIS
		 * Create ZipArchive object, and throw exception if this can't be done.
		 ******
		 */
		public function __construct() { //{{{
				$this->zip = new ZipArchive();
				$this->filename = $this->zipName();
				$flags = ZIPARCHIVE::CREATE | ZIPARCHIVE::OVERWRITE;
				
				if (true !== $this->zip->open($this->filename, $flags)) {
						throw new Exception("Problem creating ZipArchive");
				}
		}
		//}}}
		
		/****** Zip.php/addFile
		 * NAME
		 * addFile
		 * SYNOPSIS
		 * Add file (given by $path), using $docName to generate name for file inside archive
		 * ARGUMENTS
		 *   * path - string - location of file to add
		 *   * docName - string - name of document
		 * RETURN VALUE
		 * Boolean - true on success, otherwise false
		 ******
		 */
		public function addFile($path, $docName) { //{{{
				$success = false;
				
				do {
						// ignore if file doesn't exist
						if (!file_exists($path)) {
								$success = true;
								break;
						}
						
						// change character set for ZIP name
						$docName = iconv('ISO-8859-1', 'IBM850', $docName);
						// replace : with _
						$docName = str_replace(':', '_', $docName);
						// add .xml
						$docName .= '.xml';

						// add file
						if (!$this->zip->addFile($path, $docName)) {
								break;
						}
						
						$success = true;
				} while (false);
				
				return $success;
		}
		//}}}

		/****** Zip.php/download
		 * NAME
		 * download
		 * SYNOPSIS
		 * Download zip when finished.
		 * OUTPUT
		 * Sends headers and contents of ZipArchive.
		 * RETURN VALUE
		 * Boolean - true on success
		 ******
		 */
		public function download() { //{{{
				$success = false;
				
				do {
						// close ZIP
						if (!$this->zip->close()) {
								break;
						}
				
						// send as download
						$filename = 'anatolia-' . date('Y-m-d') . '.zip';
						header('Content-type: application/zip');
						header('Content-disposition: attachment; filename=' . $filename);
						
						if (!readfile($this->filename)) {
								break;
						}
						
						$success = true;
				} while (false);
				
				return $success;
		}
		//}}}

		/****** Zip.php/__destruct
		 * NAME
		 * __destruct
		 * SYNOPSIS
		 * Delete ZIP from server file system when Zip object is destroyed.
		 ******
		 */
		public function __destruct() { //{{{
				do {
						// have ZIP to delete
						if (!file_exists($this->filename)) {
								break;
						}
						
						// delete
						if (!unlink($this->filename)) {
								break;
						}
				} while (false);
		}
		//}}}
		
		/****** Zip.php/zipName
		 * NAME
		 * zipName
		 * SYNOPSIS
		 * Generate temporary name for zip file on server.
		 * RETURN VALUE
		 * String - name to use for zip.
		 ******
		 */
		private function zipName() { //{{{
				$tmpDir = '/tmp';
				if (function_exists('sys_get_temp_dir')) {
						$tmpDir = sys_get_temp_dir();
				}
				
				return tempnam($tmpDir, 'anatolia');
		}
		//}}}
}

?>
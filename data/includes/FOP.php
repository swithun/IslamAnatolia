<?php

class FOP {
		private $xslt = "";
		private $name = "";
		private $params = null;
		
		public function __construct($name, $xsltFile = "") { //{{{
				$this->name = $name;
				$this->xslt = new XSLT($xsltFile);
				$this->params = array();
		}
		//}}}
		
		public function setParams($params) { //{{{
				$this->params = $params;
		}
		//}}}
		
		public function transform($dom) { //{{{
				$success = false;
				
				do {
						// need XSLT
						if (!$this->xslt) {
								break;
						}
						
						// pass params to XSLT
						$this->xslt->addParams($this->params);
						
						// transform and save FO to temp file
						$foDOM = $this->xslt->transformToDom($dom);
						$fo = tempnam("/tmp", "fop");
						if (!$foDOM->save($fo)) {
								break;
						}
						
						// need to make it readable for FOP server
						chmod($fo, 644);
						
						// create URL
						$url = sprintf("http://%s:%s%sfo=%s",
													 FOP_HOST,
													 FOP_PORT,
													 FOP_PATH,
													 $fo);
						
						// start buffering and send PDF to buffer
						ob_start();
						
						// check buffer before sending headers
						if ($this->curl($url)) {
								header("Content-type:application/pdf");
								header("Content-Disposition:attachment;filename='" . $this->name . ".pdf'");
								$success = true;
						}
						
						// send buffer
						ob_end_flush();
						
						// finished with temp FO
						unlink($fo);
				} while (false);
				
				return $success;
		}
		
		private function curl($url) { //{{{
				// curl options
				$curl_opts = array(CURLOPT_URL => $url,
													 CURLOPT_HEADER => 0);
				
				$ch = curl_init();
				curl_setopt_array($ch, $curl_opts);
				
				// sends output to buffer
				$success = curl_exec($ch);
				curl_close($ch);
				
				return $success;
		}
		//}}}
}

?>
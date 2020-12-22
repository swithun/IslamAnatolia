<?php

class Solr {

    /****** includes/Solr.php
     * NAME
     * Solr.php
     * SYNOPSIS
     * Class for communicating with the Solr server, via various Solr objects.
     * AUTHOR
     * Swithun Crowe
     * CREATION DATE
     * 20120710
     ******
     */

    private $client = null;
    private static $instance = null;
    private $response = "";
    private $rows = 10;
		private $fields = null;
		private $query = null;
		private $bigNumber = 10000;
		private $dateFormat = "%04d-01-01T00:00:00Z";
		private $gapFormat = "+%dYEARS";
		private $dateRange = array(0, 2100);
		private $gap = 50;
		private $useScore = false;
		private $sortFields = array(/*"type_of_resource" => SolrQuery::ORDER_DESC,
																"date_created_start_f" => SolrQuery::ORDER_ASC,
																"main_title" => SolrQuery::ORDER_ASC*/);

    /****f* Solr.php/__construct
     * NAME
     * __construct
     * SYNOPSIS
     * Constructor for the class. It connects to the Solr server using the defined credentials and details, and creates a Solr client object.
     ******
     */
    public function __construct() { //{{{
				$options = array("hostname" => SOLR_HOST,
												 "port" => SOLR_PORT,
												 "path" => SOLR_PATH);
				$this->client = new SolrClient($options);
				$this->newQuery();
    }
    //}}}

    /****f* Solr.php/newQuery
     * NAME
     * newQuery
     * SYNOPSIS
     * Creates a new query.
		 * Call this when you want to do a subsequent query with the same Solr object.
     ******
     */
    public function newQuery() { //{{{
				$this->query = new SolrQuery();
    }
    //}}}

    /****f* Solr.php/getInstance
     * NAME
     * getInstance
     * SYNOPSIS
     * Returns singleton instance of Solr client
     ******
     */
    public static function getInstance() { //{{{
				if (null == self::$instance) {
						self::$instance = new Solr();
				}

				return self::$instance;
    }
    //}}}

    /****f* Solr.php/getRows
     * NAME
     * getRows
     * SYNOPSIS
     * Returns number of rows that Solr will return
		 * RETURN VALUE
		 * Integer - rows member of object
     ******
     */
		public function getRows() { //{{{
				return $this->rows;
		}
		//}}}

    /****f* Solr.php/setRows
     * NAME
     * setRows
     * SYNOPSIS
     * Sets the number of rows which Solr will return
		 * ARGUMENTS
		 *   * rows - integer - number of rows for Solr to return, -1 for bigNumber
     ******
     */
		public function setRows($rows) { //{{{
				$this->rows = -1 == $rows ? $this->bigNumber : $rows;
		}
		//}}}

    /****f* Solr.php/setFields
     * NAME
     * setFields
     * SYNOPSIS
     * Sets the fields which Solr should return
		 * ARGUMENTS
		 *   * fields - array - array of fields which Solr should return
     ******
     */
		public function setFields($fields) { //{{{
				$this->fields = $fields;
		}
		//}}}

    /****f* Solr.php/setSortFields
     * NAME
     * setSortFields
     * SYNOPSIS
     * Sets the sort field/s for the query
		 * ARGUMENTS
		 *   * sortFields - array - associative array of fields and directions
     ******
     */
		public function setSortFields($sortFields) { //{{{
				$this->sortFields = $sortFields;
		}
		//}}}

    /****f* Solr.php/getDateRange
     * NAME
     * getDateRange
     * SYNOPSIS
     * Returns range for dates as array
		 * RETURN VALUE
		 * Array - the range of dates for queries
     ******
     */
		public function getDateRange() { //{{{
				return $this->dateRange;
		}
		//}}}

    /****f* Solr.php/getDateFormat
     * NAME
     * getDateFormat
     * SYNOPSIS
     * Returns format for converting years into Solr dates
		 * RETURN VALUE
		 * String - format for converting years to Sorl dates
     ******
     */
		public function getDateFormat() { //{{{
				return $this->dateFormat;
		}
		//}}}

    /****f* Solr.php/getGap
     * NAME
     * getGap
     * SYNOPSIS
     * Returns size of date buckets
		 * RETURN VALUE
		 * Integer - size of date buckets
     ******
     */
		public function getGap() { //{{{
				return $this->gap;
		}
		//}}}

    /****f* Solr.php/getResponse
     * NAME
     * getResponse
     * SYNOPSIS
     * Returns response (XML string) from adding a document
     ******
     */
    public function getResponse() { //{{{
				return $this->response;
    }
    //}}}

		/****f* Solr.php/useScore
     * NAME
     * useScore
     * SYNOPSIS
     * Call this if using score field in results
		 * ARGUMENTS
		 *   * useScore - boolean - default false
     ******
     */
		public function useScore($useScore = false) { //{{{
				$this->useScore = $useScore;
		}
		//}}}
		
    /****f* Solr.php/simpleSearch
     * NAME
     * simpleSearch
     * SYNOPSIS
     * Run a basic search of the text field for the given query.
     * ARGUMENTS
     *   * params - array - array of search params
     *   * offset - integer - optional offset at which to start search
		 *   * rows - integer - number of hits to return, default -1 which is bigNumber
     * RETURN VALUE
     * dom - a DOM object containing the response, or false on failure
     ******
     */
    public function simpleSearch($params, $offset=0, $rows=-1) { //{{{
				$q = array();
				
				$rows = -1 == $rows ? $this->bigNumber : $rows;
				
				foreach ($params as $name => $value) {
						switch ($name) {
						 case "q":
								$q[] = sprintf("doc_type:work AND (text:%s OR id:%s)", 
															 $value, $value);
								break;
								
						 default:
								// put quotes round these values
								$q[] = sprintf("%s:\"%s\"", $name, $value);
								break;
						}
				}
				
				$queryString = implode(" AND ", $q);
				return $this->search($queryString, $offset, $rows);
    }
    //}}}

    /****f* Solr.php/rawSearch
     * NAME
     * rawSearch
     * SYNOPSIS
     * Run a search using the preprepared query string
     * ARGUMENTS
     *   * query - string - Solr query string
		 *   * localParams - array - optional array of local params to set
     *   * offset - integer - optional offset at which to start search
		 *   * fields - array - optional array of fields to return
     * RETURN VALUE
     * dom - a DOM object containing the response, or false on failure
     ******
     */
		public function rawSearch($query, $localParams = array(), $offset = 0, $fields = null) { //{{{
				foreach ($localParams as $name => $value) {
						$this->query->add($name, $value);
				}
				
				// have particular fields to return
				$this->fields = $fields;
				
				return $this->search($query, $offset, $this->rows);
		}
		//}}}

    /****f* Solr.php/basketSearch
     * NAME
     * basketSearch
     * SYNOPSIS
     * Get results on items in basket
     * ARGUMENTS
		 *   * items - array - the items in the basket
		 *   * offset - int - offset to start search on
     * RETURN VALUE
     * dom - a DOM object containing the response, or false on failure
     ******
     */
    public function basketSearch($items, $offset) { //{{{
				$queryString = sprintf("id:%s", implode(" OR id:", $items));
				return $this->search($queryString, $offset, $this->rows);
    }
    //}}}

    /****f* Solr.php/authorityFileSearch
     * NAME
     * authorityFileSearch
     * SYNOPSIS
     * Get all authority files identified by array of IDs
     * ARGUMENTS
		 *   * ids - array - array of ID strings
     * RETURN VALUE
     * dom - a DOM object containing the response, or false on failure
     ******
     
    public function authorityFileSearch($ids) { //{{{
				$queryString = sprintf("(id:%s) AND type_of_resource:auth", implode(" OR id:", $ids));
				return $this->search($queryString, 0, $this->bigNumber);
    }
    //}}}
		*/

    /****f* Solr.php/referers
     * NAME
     * referers
     * SYNOPSIS
     * Get MS documents which refer to named authority file. Set max rows to 200 for this search.
     * ARGUMENTS
		 *   * name - string - id of authority file
     * RETURN VALUE
     * dom - a DOM object containing the response, or false on failure
     ******
     */
    public function referers($name) { //{{{
				// set rows and field list
				$this->rows = $this->bigNumber;
				$this->fields = array("id", "title", "auth_title", "doc_type", 
															"work_work_html_note",
															"work_auth_author_id", "work_auth_patron_id", "work_auth_dedication_id");

				// escape :s in document name
				$name = str_replace(":", "\\:", $name);
				
				// create query
				$queryString = sprintf('((work_auth_author_id:%1$s OR work_auth_patron_id:%1$s OR work_auth_dedication_id:%1$s) AND doc_type:work) OR (auth_auth_id: %1$s AND doc_type:auth)',
															 $name);
				
				return $this->search($queryString, 0, $this->rows);
    }
    //}}}

    /****f* Solr.php/getDocumentsByType
     * NAME
     * getDocumentsByType
     * SYNOPSIS
     * Get documents aaccording to their type
     * ARGUMENTS
     *   * type - string - type of document to get
     *   * offset - integer - optional offset at which to start search
		 *   * hits - integer - number of hits to return
     * RETURN VALUE
     * dom - a DOM object containing the response, or false on failure
     ******
     */
    public function getDocumentsByType($type, $offset=0, $hits) { //{{{
				$queryString = sprintf("doc_type:%s", $type);
				return $this->search($queryString, $offset, $hits);
    }
    //}}}

    /****f* Solr.php/advancedSearch
     * NAME
     * advancedSearch
     * SYNOPSIS
     * Perform advanced search on documents of different types
     * ARGUMENTS
     *   * query_ms - string - query for manuscript documents
     *   * query_author - string - query for author in authority files
     *   * query_authority - string - query other authority files
     *   * query_bib - string - query for bibliographic items
     *   * return_type - integer - type of document to search
     *   * offset - integer - where to start search, defaults to 0
     * RETURN VALUE
     * dom - a DOM object containing the response, or false on failure
     * NOTES
     * q={!join+from=id to=relation_bibliography}name:schmidt
     * returns documents which have a bibliographic relation to documents which match a name schmidt
     * q=text:two AND _query_:"{!join+from=id to=relation_authority}name:Muhammad"
     * returns MS documents containing the word 'two' and which refer to an authority document containing the name Muhammad
     ******
     */
    public function advancedSearch($query_ms, $query_author, $query_authority, $query_bib, $return_type, $offset = 0) { //{{{
				$queryString = "";

				switch ($return_type) {
						// manuscript type, so check all queries
				 case MANUSCRIPT_TYPE:
						$elements = array();

						if ($query_ms) {
								$elements[] = sprintf("(text:%s AND type_of_resource:ms)",
																			$query_ms);
						}
						if ($query_author) {
								$elements[] = sprintf("_query_:\"{!join from=id to=relation_author}text:%s\"",
																			$query_author);
						}
						if ($query_authority) {
								$elements[] = sprintf("_query_:\"{!join from=id to=relation_authority}text:%s\"",
																			$query_authority);
						}
						if ($query_bib) {
								$elements[] = sprintf("_query_:\"{!join from=id to=relation_bibliography}text:%s\"",
																			$query_bib);
						}

						$queryString = implode(" AND ", $elements);
						break;

						// authority type, so search authors and other authority files
				 case AUTHORITY_TYPE:
						$elements = array();
						if ($query_author) {
								$elements[] = sprintf("text:%s AND type_of_resource:auth",
																			$query_author);
						}
						if ($query_authority) {
								$elements[] = sprintf("text:%s AND type_of_resource:auth",
																			$query_authority);
						}
						$queryString = implode(" AND ", $elements);
						break;
						// bibliography type, so just use query_bib
				 case BIBLIOGRAPHY_TYPE:
						$queryString = sprintf("text:%s AND type_of_resource:bibliography",
																	 $query_bib);
						break;
				 default:
						break;
				}

				return $this->search($queryString, $offset, $this->rows);
    }
    //}}}

    /****f* Solr.php/workCopySearch
     * NAME
     * workCopySearch
     * SYNOPSIS
     * Return DOM containing MS records which match on title and author.
     * ARGUMENTS
     *   * title - string - title to match on
     *   * author - string - author key to match on
     * RETURN VALUE
     * dom - a DOM object containing the response, or false on failure
     * BUGS
     * There isn't a way to get all rows for a query, so need to pass in a high number, e.g. 100.
     ******
     */
    public function workCopySearch($title, $author) { //{{{
				$dom = false;
				
				do {
						$title = trim($title);
						if (!$title) {
								break;
						}
						
						$author = trim(str_replace(":", "\:", $author));
						if (!$author) {
								break;
						}
						
						$localParams = array("work" =>  sprintf("(title:\"%s\" AND work_auth_author_id:%s)",
																										$title, $author));
						
						$queryString = '_query_:"{!join from=work_parent_id to=ms_id v=$work}"';
						
						// run query
						$this->rows = $this->bigNumber;
						$dom = $this->rawSearch($queryString, $localParams, 0, array("id"));
				} while (false);
				
				return $dom;
    }
    //}}}

    /****f* Solr.php/addDocument
     * NAME
     * addDocument
     * SYNOPSIS
     * Adds a document to the Solr index. The DOM has to be converted to a Solr Document object.
     * ARGUMENTS
     *   * dom - DOM - DOM object of the document to index
		 *   * message - string - passed by reference, to hold any error message
     * RETURN VALUE
     * Array of ID strings when multiple documents in given DOM, otherwise single ID string, or empty string on failure
     ******
     */
    public function addDocument($dom, &$message) { //{{{
				$id = "";
				
				do {
						// convert DOM to Solr document
						$docs = $this->dom2doc($dom, $message);
						if (!$docs) {
								$message .= "problem converting DOM to doc";
								break;
						}
						
						$ids = array();
		
						// loop over input documents
						foreach ($docs as $doc) {
								if (!$doc) {
										//$ids[] = "";
										//continue;
										$message = "doc is null";
										break 2;
								}
								
								// send to Solr
								$response = $this->client->addDocument($doc);
								if (!$response || !$response->success()) {
										$message = "couldn't add document";
										break 2;
								}
								
								$this->response = $response->getRawResponse();
								
								// commit changes to index
								if (!$this->commit()) {
										$message = "couldn't commit";
										break 2;
								}

								// get ID field
								list ($docid) = $doc->getField("id")->values;
								$ids[] = $docid;
						}
						
						// return string of ID when there was just 1 input document
						if (1 == count($docs) && isset($ids[0]) && "" != $ids[0]) {
								$id = $ids[0];
						}
						// otherwise return array of IDs
						elseif (count($docs) > 1) {
								$id = $ids;
						}
				}
				while (false);

				return $id;
    }
    //}}}

    /****f* Solr.php/addFacet
     * NAME
     * addFacet
     * SYNOPSIS
		 * Add a field for faceting.
     * ARGUMENTS
     *   * facet - string - name of field for faceting
     ******
     */
		public function addFacet($facet) { //{{{
				// make sure facetting is turned on and ignore empty facet groups
				$this->query->setFacet(true);
				$this->query->setFacetMinCount(1);
				
				$this->query->addfacetField($facet);
		}
		//}}}

    /****f* Solr.php/addDateFacet
     * NAME
     * addDateFacet
     * SYNOPSIS
		 * Add a date field for faceting.
     * ARGUMENTS
     *   * facet - string - name of field for faceting
		 *   * dateRange - array - optional, should contain start and end years as ints
		 *   * gap - int - optional, size of date buckets, in years
     ******
     */
		public function addDateFacet($facet, $dateRange=null, $gap=0) { //{{{
				// make sure facetting is turned on and ignore empty facet groups
				$this->query->setFacet(true);
				$this->query->setFacetMinCount(1);

				// add as date field
				$this->query->addParam("facet.range", $facet);
				
				$dateRange = $dateRange ? $dateRange : $this->dateRange;
				$gap = $gap ? $gap : $this->gap;
				$facetParam = sprintf("f.%s.facet.range.", $facet);
				
				// set start/end and gap
				$this->query->setParam(sprintf("%sstart", $facetParam),
															 sprintf($this->dateFormat, $dateRange[0]));
				$this->query->setParam(sprintf("%send", $facetParam),
															 sprintf($this->dateFormat, $dateRange[1]));
				$this->query->setParam(sprintf("%sgap", $facetParam),
															 sprintf($this->gapFormat, $gap));
		}
		//}}}
		
    /****f* Solr.php/dom2doc
     * NAME
     * dom2doc
     * SYNOPSIS
     * Convert a DOM object to a SolrInputDocument object.
     * The DOM contains field elements with a name attribute and a text value. The names and values are added to a Solr document.
     * If there isn't a field with name "id", then this counts as failure.
     * ARGUMENTS
     *   * dom - DOM - DOM object of the document to index
		 *   * message - string - passed by reference, to hold any error message
     * RETURN VALUE
     * Array of SolrInputDocument with fields to index - failed items will be null
     ******
     */
    private function dom2doc($dom, &$message) { //{{{
				$inDocs = array();
				$docXPath = "/add/doc";
				$fieldXPath = "field";
				
				do {
						$xp = new DOMXPath($dom);
						if (!$xp) {
								break;
						}
						
						$docs = $xp->query($docXPath);
						if (!$docs->length) {
								break;
						}
						
						foreach ($docs as $doc) {
								$success = false;
								
								// add fields found in DOM
								$fields = $xp->query($fieldXPath, $doc);
								if (!$fields->length) {
										break 2;
								}
								
								$inDoc = new SolrInputDocument();
								
								foreach ($fields as $field) {
										$fieldName = $field->getAttribute("name");

										// need something
										if ("" == $field->nodeValue) {
												continue;
										}
										
										// need ID field
										if ("id" == $fieldName) {
												$success = true;
										}
										
										// text or XML content
										$val = "";
										foreach ($field->childNodes as $n) {
												switch ($n->nodeType) {
												 case XML_TEXT_NODE:
														$val .= $n->nodeValue;
														break;
												 case XML_ELEMENT_NODE:
														$val .= $dom->saveXml($n);
														break;
												}
										}
										
										$val = trim($val);    
										
										if (false !== strrpos($fielsName, "_geographic")) {
												$val = $this->deduplicate($val);
										}
										
										// problem adding field, so finished
										if (!$inDoc->addField($fieldName, $val)) {
												$message = "problem adding field to input document";
												$success = false;
												break 2;
										}
								}
								
								if (!$success) {
										$message = "missing id";
										break;
								}
								
								// add input document to array
								$inDocs[] = $inDoc;
						}
				} while (false);
				
				return $inDocs;
    }
    //}}}

    /****f* Solr.php/search
     * NAME
     * search
     * SYNOPSIS
     * Takes a query string generated by one of the other public search methods and runs the search.
     * On success it returns a DOM object containing the XML response from Solr.
     * ARGUMENTS
     *   * queryString - string - the query string to pass to Solr
     *   * offset - integer - offset at which to (re)start search, defaults to 0
     *   * rows - integer - number of rows to return in set, or 0 for default number (10)
     * RETURN VALUE
     * DomDocument containing the XML response from Solr, or false on failure
     ******
     */
    private function search($queryString, $offset = 0, $rows = 0) { //{{{
				$dom = false;

				try {
						$this->query->setQuery($queryString);
						$this->query->setHighlight(true);

						// have offset
						if ($offset) {
								$this->query->setStart($offset);
						}

						// have number of rows
						if ($rows) {
								$this->query->setRows($rows);
						}
						
						// have specific fields to return
						if ($this->fields) {
								foreach ($this->fields as $field) {
										$this->query->addField($field);
								}
						}

						// using score, so add it to field list
						if ($this->useScore) {
								$this->query->addField("*");
								$this->query->addField("score");
						}
						// not using score, so sort on these fields
						elseif (is_array($this->sortFields)) {
								foreach ($this->sortFields as $field => $direction) {
										$this->query->addSortField($field, $direction);
								}
						}

						$response = $this->client->query($this->query);
						$xml = $response->getRawResponse();
						$dom = new DomDocument();
						$dom->loadXml($xml);
				}
				catch (Exception $e) {
						$dom = false;
				}

				return $dom;
    }
    //}}}

    /****f* Solr.php/deleteDocument
     * NAME
     * deleteDocument
     * SYNOPSIS
     * Deletes a document from the Solr index.
     * ARGUMENTS
     *   * id - string - the ID of the document to delete
     * RETURN VALUE
     * boolean - true on success
     ******
     */
    public function deleteDocument($id) { //{{{
				$success = false;

				do {
						// use ID
						$query = sprintf("id:%s", $id);
						// delete from Solr
						$response = $this->client->deleteByQuery($query);
						
						// check for success and commit changes to index
						if (!$response->success() || !$this->commit()) {
								break;
						}

						$success = true;
				} while (false);

				return $success;
    }
    //}}}

    /****f* Solr.php/commit
     * NAME
     * commit
     * SYNOPSIS
     * Commit changes made to the Solr index.
     * RETURN VALUE
     * Boolean, true on success
     ******
     */
    private function commit() { //{{{
				return $this->client->commit()->success();
    }
    //}}}

    /****f* Solr.php/deduplicate
     * NAME
     * deduplicate
     * SYNOPSIS
     * Some field values are duplicated, e.g. IranIran, so remove duplicated value
		 * ARGUMENTS
		 *   * fieldValue - string - possibly duplicated field value
     * RETURN VALUE
     * String - input string with possible duplicate removed
     ******
     */
		private function deduplicate($fieldValue) { //{{{
				$retVal = $fieldValue;
				
				do {
						// ignore empty strings
						if (!$fieldValue) {
								break;
						}
						
						// ignore strings with an odd number of letters
						$l = strlen($fieldValue);
						if (1 == $l % 2) {
								break;
						}
						
						// ignore when the first half isn't the same as the second half
						list ($f1, $f2) = str_split($fieldValue, $l / 2);
						if ($f1 != $f2) {
								break;
						}
						
						$retVal = $f1;
				} while (false);
				
				return $retVal;
		}
		//}}}
}

?>

<?php

/****** includes/searchFunctions.php
 * NAME
 * searchFunctions.php
 * SYNOPSIS
 * Contains functions for searching
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20151203
 ******
 */

//require_once "fold.php";

// array of form field names and their corresponding Solr fields
$facets = array("author" => "work_author_s", 
								"date" => "work_date_created_start",
								"copying_date" => "work_date_copy_start",
								"creation_place" => "work_creation_place_s", 
								"copying_place" => "work_copy_place_s", 
								"subject_geographic" => "work_auth_geographic",
								"subject_topic" => "work_auth_topic", 
								//"subject_time" => "work_auth_temporal",
								"country" => "ms_physical_location_country", 
								"settlement" => "ms_physical_location_settlement",
								"institution" => "ms_physical_location_institution", 
								//"repository" => "ms_physical_location_repository",
								"collection" => "ms_physical_location_collection",
								"language" => "work_language",
								"script" => "work_script",
								"type" => "doc_type",
								"authtype" => "auth_type");

// fields which don't use quotes
$noQuoteFields = array("work_date_created_start", "work_date_copy_start", 
											 "text", "title", "author", "note", "work_author_main",
											 "author_note_place", "work_note_place",
											 "ms_identifier_idno", "place");

// fields to sort on
$sortFields = array("title" => "title_sort",
										"classmark" => "id",
										"relevance" => "score");

// used in joins
$joinFmt = '_query_:"{!join from=%s to=%s v=$%s}"';
$msID = "ms_id";
$workParentID = "work_parent_id";

/****f* searchFunctions.php/formatDates
 * NAME
 * formatDates
 * SYNOPSIS
 * Format dates for Solr queries.
 * E.g. converts 1600 to [1600-01-01T00:00:00Z+TO+1650-01-01T00:00:00Z]
 * ARGUMENTS
 *   * dates - array - list of dates (years)
 * RETURN VALUE
 * Input array with each year converted to Solr date range
 ******
 */
function formatDate($dates, $dateFormat, $gap) { //{{{
		foreach ($dates as $i => $d) {
				$dates[$i] = sprintf("[%s TO %s]",
														 sprintf($dateFormat, $dates[$i]),
														 sprintf($dateFormat, $dates[$i] + $gap));
		}
		
		return $dates;
}
//}}}

/****f* searchFunctions.php/formatField
 * NAME
 * formatField
 * SYNOPSIS
 * Format field and values for Solr.
 * ARGUMENTS
 *   * fields - array/string - name/s of Solr field and possible boost values
 *   * values - (possibly 2D) array - (list of) lists of values for this field/s
 *   * op - string - operator to use to join values, default OR
 * RETURN VALUE
 * String containing Solr queries joined using operator
 ******
 */
function formatField($fields, $values, $op = " AND ") { //{{{
		global $noQuoteFields;
		
		$format = "%s:%s%s%s^%d";
		
		$fields = is_array($fields) ? $fields : array($fields => 1);
		
		$valueTerms = array();

		// values is 2D array, so $op everything, disjoining on fields
		// used for text input queries
		if (isset($values[0]) && is_array($values[0])) {
				foreach ($values as $val) {
						foreach ((array) $val as $v) {
								$fieldTerms = array();
								
								// loop over fields, looking for value in each field
								foreach ($fields as $f => $b) {
										// don't quote *s or values in noQuoteFields
										$q = "*" == $v || in_array($f, $noQuoteFields) ? "" : '"';
										
										$fieldTerms[] = sprintf($format,
																						$f, $q, $v, $q, $b);
								}
								
								// disjoin searches for current value in each field
								$valueTerms[] = sprintf("(%s)", implode(" OR ", $fieldTerms));
						}
				}
		}
		// values is 1D array - assumes that fields only has 1 element
		// essentially disjoin values
		// used for facets
		else {
				$fieldTerms = array();
				foreach ($values as $val) {
						// loop over fields, looking for value in each field
						foreach ($fields as $f => $b) {
								// don't quote *s or values in noQuoteFields
								$q = "*" == $val || in_array($f, $noQuoteFields) ? "" : '"';
								
								$fieldTerms[] = sprintf($format,
																				$f, $q, $val, $q, $b);
						}
				}
				
				// disjoin searches for current value in each field
				$valueTerms[] = sprintf("(%s)", implode(" OR ", $fieldTerms));
		}

		// join groups of value queries using operator
		return sprintf("(%s)", implode($op, $valueTerms));
}
//}}}

/****f* searchFunctions.php/removeFacets
 * NAME
 * removeFacets
 * SYNOPSIS
 * If there is a facet field to remove from search, then remove it.
 * Check for facet fields in _REQUEST and remove them from the list of
 * possible facets to be used in the next search.
 * For the physical location fields, remove less specific fields if a
 * more specific field is being searched on.
 * For fields being searched, add these to the params array.
 * ARGUMENTS
 *   * params - array - associative array passed by reference, to hold search params for Solr
 *   * dateFormat - string - date format for Solr dates
 *   * gap - integer - size of date buckets in Solr
 * RETURN VALUE
 * Boolean, true if any facets got removed from the global facets array
 * NOTES
 * Modifies the global $_REQUEST array. Needs access to global $facets variable.
 ******
 */
function removeFacets(&$params, $dateFormat, $gap) { //{{{
		global $facets;
		
		$removed = false;

		// check for facet to remove from query
		if (isset($_REQUEST["remove_facet"])) {
				unset($_REQUEST[$_REQUEST["remove_facet"]]);
				unset($_REQUEST["remove_facet"]);
		}
		
		// can remove offset
		if (isset($_REQUEST["offset"])) {
				unset($_REQUEST["offset"]);
		}
		
		// check for facets being used
		foreach ($facets as $f => $field) {
				// not using this facet to search on, so skip
				if (!isset($_REQUEST[$f]) || "" == $_REQUEST[$f]) {
						continue;
				}
				
				// using this facet, so remove it from list
				unset($facets[$f]);
				
				// get value and cast as array
				$value = (array) $_REQUEST[$f];
				
				switch ($f) {
				 case "date":
				 case "copying_date":
						// convert year into Solr range
						$value = formatDate($value, $dateFormat, $gap);
						break;
						
						// physical location fields
						// if searching on more specific field, no longer interested in less specific ones
				 case "collection":
						unset($facets["repository"]);
				 case "repository":
						unset($facets["institution"]);
				 case "institution":
						unset($facets["settlement"]);
				 case "settlement":
						unset($facets["country"]);
				 default:
						break;
				}
				
				$params[$field] = $value;
				
				// have removed facet/s
				$removed = true;
		}
		
		return $removed;
}
//}}}

/****f* searchFunctions.php/addFacets
 * NAME
 * addFacets
 * SYNOPSIS
 * Adds remaining facets from global facets array to Solr.
 * NOTES
 * Needs access to global variables facets and solr.
 ******
 */
function addFacets() { //{{{
		global $facets, $solr;
		
		foreach ($facets as $f => $field) {
				foreach (explode(" ", $field) as $ff) {
						switch ($f) {
						 case "date":
						 case "copying_date":
								$solr->addDateFacet($ff);
								break;
						 default:
								$solr->addFacet($ff);
								break;
						}
				}
		}
}
//}}}

/****f* searchFunctions.php/checkQuery
 * NAME
 * checkQuery
 * SYNOPSIS
 * Checks global _REQUEST array for a text query.
 * Query defaults to * and field defaults to text.
 * Adds these as param if there are no other params or if there was a non-default query.
 * ARGUMENTS
 *   * params - associative array, passed by reference, to hold search params for Solr
 ******
 */
function checkQuery(&$params) { //{{{
		global $noQuoteFields;
		
		do {
				$qs = isset($_REQUEST["q"]) ? (array) $_REQUEST["q"] : array("*");
				$fields = isset($_REQUEST["field"]) ? (array) $_REQUEST["field"] : array("text");
				
				$c = min(count($qs), count($fields));
				for ($i = 0; $i < $c; ++ $i) {
						// if there are other params, then ignore dummy query
						if ($params && "*" == $qs[$i] && "text" == $fields[$i]) {
								continue;
						}
						
						// new field
						if (!isset($params[$fields[$i]])) {
								$params[$fields[$i]] = array();
						}
						
						// field not to be quoted as string, so parse
						if (in_array($fields[$i], $noQuoteFields)) {
								$params[$fields[$i]][] = parseQuery($qs[$i]);
						}
						// contains spaces, so quote
						elseif (false !== strpos($qs[$i], " ")) {
								$params[$fields[$i]][] = array(sprintf('"%s"', $qs[$i]));
						}
						// add as is
						else {
								$params[$fields[$i]][] = array($qs[$i]);
						}
				}
		} while (false);
}
//}}}

/****f* searchFunctions.php/paramsForDesiredDocs
 * NAME
 * paramsForDesiredDocs
 * SYNOPSIS
 * Turns params array from field=>value pairs to fragments of Solr search, e.g. field:value.
 * If there are joins needed, then it adds these to the array, add adds a localParam value.
 * This search is just for documents of the desired type.
 * ARGUMENTS
 *   * params - associative array - list of fields and values
 *   * doctype - string - the type of documents desired
 * RETURN VALUE
 * Array containing localParams (associative array to hold local param/s used in joins) and new params in string
 ******
 */
function paramsForDesiredDocs($params, $doctype) { //{{{
		global $facets, $noQuoteFields, $joinFmt, $msID, $workParentID;
		
		$localParams = array();
		$newParams = array();
		//print_r($params);
		
		// conjoin params for this doc type into single param
		$v = 0;
		foreach ($params as $field => $value) {
				$param = formatField($field, $value);
				
				$vv = sprintf('v%d', $v ++);
				
				switch (true) {
						// space in field, so split and only use one which matches desired doc type
				 case (false !== strpos($field, " ")):
						foreach (explode(" ", $field) as $f) {
								if (0 === strpos($f, $doctype)) {
										$newParams[$f] = $param;
										break;
								}
						}
						break;

						// boost some fields and fall through
				 case ("text" == $field):
						$param = formatField(array("title" => 20, "work_author_main" => 60, "author" => 40, "text" => 1), 
																 $value);
						
						// some fields which are the same in all doc types
				 case ("place" == $field):
				 case ("title" == $field):
				 case ("author" == $field):
				 case ("note" == $field):
				 case ("author_note_place" == $field):
				 case ("work_note_place" == $field):
						// search field in desired doc type
				 case (0 === strpos($field, $doctype)): 
						$newParams[$field] = $param;
						break;
						
						// searching for ms field in work doc, so join
				 case ("work" == $doctype):
						$newParams[$field] = sprintf($joinFmt, $msID, $workParentID, $vv);
						$localParams[$vv] = $param;
						break;
				
						// searching for work field in ms doc, so join
				 case ("ms" == $doctype):
						$newParams[$field] = sprintf($joinFmt, $workParentID, $msID, $vv);
						$localParams[$vv] = $param;
						break;
						
				 default:
						break;
				}
		}
		
		// add type
		switch ($doctype) {
		 case "work":
		 case "ms":
				$newParams["type"] = sprintf("%s:%s", $facets["type"], $doctype);
				break;
				
		 case "people":
				$newParams["type"] = sprintf("%s:person", $facets["authtype"]);
				break;
		}

		// conjoin query params
		$newParams = implode(" AND ", $newParams);

		return array($localParams, $newParams);
}
//}}}

/****f* searchFunctions.php/paramsForFacets
 * NAME
 * paramsForfacets
 * SYNOPSIS
 * Want to get facets for fields in both parent and child documents.
 * Use params to construct queries for each doc type and then put these together.
 * ARGUMENTS
 *   * params - associative array - list of fields and values
 * RETURN VALUE
 * Array containing list of local params and string with Solr query
 ******
 */
function paramsForFacets($params, $doctype) { //{{{
		global $noQuoteFields, $joinFmt, $msID, $workParentID;
		
		// generate new list of search params
		$newParams = array();
		foreach ($params as $f => $value) {
				if (!$value) {
						continue;
				}
				
				// decide on which doc type the field is for
				$d = "";
				switch ($f) {
						// ignore type field here
				 case "type":
						break;
						
						// search in docs of given type for text/title/author
				 case "text":
						$d = $doctype;
						break;
						
						// field is for work doc type
				 case "title":
				 case "author":
				 case "note":
				 case "author_note_place":
				 case "work_note_place":
				 case "place":
						$d = "work";
						break;
						
						// field is for ms doc type
				 case "ms_identifier_idno":
						$d = "ms";
						break;
						
				 default:
						if (0 === strpos($f, "work")) {
								$d = "work";
						}
						elseif (0 === strpos($f, "ms")) {
								$d = "ms";
						}
						break;
				}
				
				// invalid param
				if (!$d) {
						continue;
				}
				
				if (!isset($newParams[$d])) {
						$newParams[$d] = array();
				}
				
				$newParams[$d][] = formatField($f, $value);
		}
		
		$query = array();
		$localParams = array();
		
		// generate local params for join queries
		foreach ($newParams as $t => $n) {
				$localParams[$t] = implode(" AND ", $newParams[$t]);
		}
		
		// generate join queries using local params
		// if query for other doc type exists, then conjoin this to join query
		// if query for other doc type doesn't exist, then disjoin query for current doc type
		foreach ($newParams as $t => $n) {
				$q = "";
				switch ($t) {
				 case "work":
						// query to get parent MS docs which contain matching work docs
						$q = sprintf($joinFmt, $workParentID, $msID, $t);
						
						// have MS query, so restrict using it
						if (isset($localParams["ms"])) {
								$q = sprintf('(%s AND (%s))', $q, $localParams["ms"]);
						}
						
						$query[] = $q;
						
						// no MS query, so add disjunct for work query
						if (!isset($newParams["ms"])) {
								$query[] = $localParams["work"];
						}
						break;
						
				 case "ms":
						$q = sprintf($joinFmt, $msID, $workParentID, $t);
						if (isset($localParams["work"])) {
								$q = sprintf('(%s AND (%s))', $q, $localParams["work"]);
						}

						$query[] = $q;

						if (!isset($newParams["work"])) {
								$query[] = $localParams["ms"];
						}
						
						break;
						
				 default:
						break;
				}
				
		}
		
		// disjoin queries to get results for each doc type
		$query = sprintf("(%s)", implode(") OR (", $query));
		
		return array($localParams, $query);
}
//}}}

/****f* searchFunctions.php/paramsForParentChildDocs
 * NAME
 * paramsForParentChildDocs
 * SYNOPSIS
 * Get IDs from DOM returned by search for docs of desired type.
 * Use these to get all docs with these IDs and docs with parent/children with these IDs.
 * ARGUMENTS
 *   * dom - DOMDocument - DOM returned from Solr
 *   * doctype - string - desired type of document
 * RETURN VALUE
 * String - disjoined query for docs using IDs
 ******
 */
function paramsForParentChildDocs($dom, $doctype) { //{{{
		// XPath for getting IDs of documents in response
		$xpath = "/response/result[@name='response']/doc/str[@name='id']";
		$parentChildQuery = "-text:*";
		
		do {
				$xp = new DomXPath($dom);
				$results = $xp->evaluate($xpath);
				
				if (!$results || 0 == $results->length) {
						break;
				}
				
				// create query for these documents and parent/children ones too
				$ids = array();
				foreach ($results as $node) {
						// escape any :s in ID
						$id = str_replace(":", "\\:", $node->nodeValue);
						$ids[] = sprintf("id:%s", $id);
						
						switch ($doctype) {
								// get MS record containing work
						 case "work":
								$ids[] = sprintf("id:%s", substr($id, 0, strpos($id, ";")));
								break;
								
								// get work records contained in MS
						 case "ms":
								$ids[] = sprintf("work_parent_id:%s", $id);
								break;
								
								// person, so just this record
						 case "people":
								break;
								
						 default:
								break;
						}
				}

				// disjoin params
				$parentChildQuery = implode(" OR ", $ids);
		} while (false);
		
		return $parentChildQuery;
}
//}}}

/****f* searchFunctions.php/mergeDoms
 * NAME
 * mergeDoms
 * SYNOPSIS
 * ARGUMENTS
 *   * bothDom - DOMDocument - DOM containing both docs of desired type and parent/children
 *   * facetsDom - DOMDocument - DOM containing facets for desired type and parent/children, possibly null
 *   * idDom - DOMDocument - DOM containing docs of desired type (and appropriate stats attributes)
 * RETURN VALUE
 * DOMDocument bothDom, containing docs of both/all types, stats for just docs of desired type and facets from both types
 ******
 */
function mergeDoms($bothDom, $facetsDom, $idDom) { //{{{
		// stats attributes
		$attrs = array("start", "numFound");
		
		// XPath for facets node and results
		$facetCountXPath = "/response/lst[@name='facet_counts']";
		$resultsXPath = "/response/result";

		do {
				// get result node from idDom
				$idXP = new DomXPath($idDom);
				$idResult = $idXP->query($resultsXPath);
				if (!$idResult || 0 == $idResult->length) {
						break;
				}
				$idResult = $idResult->item(0);
				
				// get result node from bothDom
				$bothXP = new DomXPath($bothDom);
				$bothResult = $bothXP->query($resultsXPath);
				if (!$bothResult || 0 == $bothResult->length) {
						break;
				}
				$bothResult = $bothResult->item(0);
				
				// copy idDom results into bothDom
				$idResult = $bothDom->importNode($idResult, true);
				$bothDom->documentElement->appendChild($idResult);

				// finished if there are no facets
				if (null == $facetsDom) {
						break;
				}

				$facetXP = new DomXPath($facetsDom);
				$facets = $facetXP->query($facetCountXPath);
				
				if (!$facets || 0 == $facets->length) {
						break;
				}
				
				// add to document element in bothDom
				$facets = $bothDom->importNode($facets->item(0), true);
				$bothDom->documentElement->appendChild($facets);
		} while (false);
		
		return $bothDom;
}
//}}}

/****f* searchFunctions.php/setSortFields
 * NAME
 * setSortFields
 * SYNOPSIS
 * Sets Solr sort fields using sortBy argument
 * ARGUMENTS
 *   * sortBy - string - field to sort on
 *   * sortDir - string - direction to sort in
 ******
 */
function setSortFields($sortBy, $sortDir) { //{{{
		global $solr, $sortFields;
		
		if (isset($sortFields[$sortBy])) {
				$solr->setSortFields(array($sortFields[$sortBy] => 
																	 "asc" == $sortDir ? SolrQuery::ORDER_ASC : 
																	 SolrQuery::ORDER_DESC));
		}
}
//}}}

/****f* searchFunctions.php/runQueries
 * NAME
 * runQueries
 * SYNOPSIS
 * Need to run 3 Solr queries:
 * 1) Get IDs for documents of desired type using query params and offset
 * 2) Get all data on documents matching these IDs and their parent/children docs
 * 3) Get facet information based on the initial search params, but for all doc types
 * Merge information from these 3 queries.
 * ARGUMENTS
 *   * params - associative array - list of fields and values for search
 *   * offset - integer - offset for search
 *   * doctype - string - type of document to search for
 *   * sortBy - string - field to sort on, default is to sort on relevance
 *   * sortDir - string - direction to sort on, defaults to desc
 * RETURN VALUE
 * DomDocument containing merged data from the 3 searches
 * NOTES
 * Modifies the number of rows that Solr returns, so run this after accessing this Solr class member.
 ******
 */
function runQueries($params, $offset, $doctype, $sortBy="relevance", $sortDir="desc") { //{{{
		global $solr;
		
		$bothDom = null;

		do {
				// people query uses text field
				if ("people" == $doctype && isset($params["people"])) {
						$params["text"] = $params["people"];
						unset($params["people"]);
				}
				
				// rename classmark
				if (isset($params["classmark"])) {
						$params["ms_identifier_idno"] = $params["classmark"];
						unset($params["classmark"]);
				}
				
				// places search, so do dummy search and finished
				if (isset($params["places"])) {
						$bothDom = $solr->rawSearch("-doc_type:*");
						break;
				}
				
				// set sort field
				setSortFields($sortBy, $sortDir);
				
				// search for documents of desired type
				list ($localParams, $idQuery) = paramsForDesiredDocs($params, $doctype);
				
				// get IDs of documents matched with search for docs of desired type
				$idDom = $solr->rawSearch($idQuery, $localParams, $offset, array("id", "score"));
				if (!$idDom) {
						break;
				}
				
				// not interested in sorting anymore
				$solr->setSortFields(null);
				
				// use IDs to get both desired docs and their parents/children
				$bothQuery = paramsForParentChildDocs($idDom, $doctype);
				$solr->newQuery();
				$solr->setRows(-1); // big number to get all possible docs
				$bothDom = $solr->rawSearch($bothQuery);
				
				if (!$bothDom) {
						break;
				}
				
				// only need facets for ms/work queries
				$facetsDom = null;
				if ("work" == $doctype || "ms" == $doctype) {
						// create Solr params for getting facets for documents in search
						list($localParams, $facetsQuery) = paramsForFacets($params, $doctype);
						$solr->newQuery();
						$solr->setRows(0); // don't need rows to get facets
						addFacets(); // ask Solr to return these facets
						$facetsDom = $solr->rawSearch($facetsQuery, $localParams);
						
						if (!$facetsDom) {
								break;
						}
				}
						
				// need to inject facets into bothDom
				// and copy stats from idDom to bothDom
				$bothDom = mergeDoms($bothDom, $facetsDom, $idDom);
		} while (false);
		
		return $bothDom;
}
//}}}

/****f* searchFunctions.php/xsltParams
 * NAME
 * xsltParams
 * SYNOPSIS
 * Populate the array of params needed for the XSLT transform
 * ARGUMENTS
 *   * haveFacets - boolean - whether any facet fields were searched on
 *   * doctype - type of document to search for
 * RETURN VALUE
 * xsltParams - associative array of params
 ******
 */
function xsltParams($haveFacets, $doctype) { //{{{
		global $solr;
		
		$xsltParams = array();

		// tell XSLT if there was query and if any facets got search on
		$xsltParams["haveQuery"] = isset($_REQUEST["q"]) && "" != $_REQUEST["q"];
		$xsltParams["haveFacets"] = $haveFacets;

		// copy form data to XSLT
		foreach ($_REQUEST as $name => $value) {
				if ($value) {
						$xsltParams[$name] = is_array($value) ? 
							implode("|", $value) : $value;
				}
		}
		
		// add doctype
		$xsltParams["doctype"] = $doctype;
		
		// script and query string (remove [] from fields)
		$xsltParams["php_script"] = $_SERVER["SCRIPT_NAME"];
		$xsltParams["query_string"] = http_build_query($_REQUEST); /*preg_replace('/%5B[0-9]+%5D/simU', '', 
																							 http_build_query($_REQUEST));*/
		
		// Solr params
		$xsltParams["rows"] = $solr->getRows();
		$xsltParams["gap"] = $solr->getGap();
		
		return $xsltParams;
}
//}}}

/****f* searchFunctions.php/offset
 * NAME
 * offset
 * SYNOPSIS
 * Return the offset form param or 0 if not set
 * RETURN VALUE
 * Integer, either form param 'offset' or 0 if not set
 ******
 */
function offset() { //{{{
		return isset($_REQUEST["offset"]) && (int) $_REQUEST["offset"] ?
			(int) $_REQUEST["offset"] : 0;
}
//}}}

function saveSearchURI() { //{{{
		session_start();
		$_SESSION["search"] = sprintf("%s?%s",
																	$_SERVER["SCRIPT_NAME"],
																	http_build_query($_REQUEST));
}
//}}}

/****f* searchFunctions.php/utf8_to_unicode
 * NAME
 * utf8_to_unicode
 * SYNOPSIS
 * Return input string converted to ASCII string with unicode/special characters escaped for use in Javascript regexs.
 * Spaces are converted to |.
 * ARGUMENTS
 *   * str - string - string to convert
 * RETURN VALUE
 * String, Unicode characters converted to \uXXXX and other special chars converted to \xXX
 * NOTES
 * This function is called from XSLT, so the function has to be in the scope where the XSLT object is created.
 * BUGS
 * Is this still used?
 ******
 */
function utf8_to_unicode($str) { //{{{
		$hl = array(); // foldable words to highlight
		$hlu = array(); // unfoldable words to highlight
		
		$fromEnc = "UTF-8";
		$toEnc = "UCS-4BE";
		
		foreach (explode(" ", $str) as $w) {
				if (!$w || "*" == $w) {
						continue;
				}
				
				// non-Arabic words can just be added as is
				if (!preg_match("/\p{Arabic}/u", $w)) {
						$hl[] = $w;
						continue;
				}
				
				$word = "";
				$w = mb_convert_encoding($w, $toEnc, $fromEnc);
				$l = mb_strlen($w, $toEnc);
				
				// Visit each unicode character
				for($i = 0; $i < $l; ++ $i) {
						// Now we have 4 bytes. Find their total
						// numeric value.
						$s2 = mb_substr($w, $i, 1, $toEnc);
						$val = unpack("N", $s2);
						$word .= sprintf("\\u%04X", $val[1]);
				}
				
				$hlu[] = $word;
		}
		
		// join words with |
		return sprintf("hlu=%s&hl=%s", 
									 implode("|", $hlu), 
									 implode("|", $hl));
}
//}}}

/****f* searchFunctions.php/parseQuery
 * NAME
 * parseQuery
 * SYNOPSIS
 * Parse query into search terms.
 * Specifically, it handles quotes ('") round single or multiple words
 * ARGUMENTS
 *   * query - string - string to parse
 * RETURN VALUE
 * Array of search terms.
 * NOTES
 * Based on http://stackoverflow.com/questions/3811519/regular-expressions-for-google-operators
 ******
 */
function parseQuery($query) { //{{{
		// quotes
		$quotationMarks = '"\'';
		$terms = array();
		
		for ($q = strtok($query, ' '); $q !== false; $q = strtok(' ')) {
				// token doesn't start with quote
				if (false === strpos($quotationMarks, $q[0])) {
						$terms[] = $q;
						continue;
				}
				
				// token ends with quote
				if (false !== strpos($quotationMarks, $q[strlen($q)-1])) {
						$terms[] = sprintf('"%s"', substr($q, 1, -1));
						continue;
				}
				
				// token doesn't end with quote
				// so grab everything up to closing quote from query
				$terms[] = sprintf('"%s %s"', substr($q, 1), strtok($q[0]));
		}
		
		return $terms;
}
//}}}

/****f* searchFunctions.php/paging_list
 * NAME
 * paging_list
 * SYNOPSIS
 * Generate list of links to pages in search results.
 * ARGUMENTS
 *   * total - integer - total number of hits
 *   * offset - integer - current position in search results
 *   * rows - integer - number of hits per page
 *   * php_script - string - path to PHP script to use in link
 *   * query_string - string - GET params to use in link
 * RETURN VALUE
 * DomNode - documentElement from DOM containing list (ul)
 * NOTES
 * Called from XSLT.
 ******
 */
function paging_list($total, $offset, $rows, $php_script, $query_string) { //{{{
		// number of hits either side of current position
		$spread = 3 * $rows;
		$dots = "...";
		
		$dom = new DomDocument();
		$ul = $dom->createElement("ul");
		$ul->setAttribute("id", "paging");
		$ul = $dom->appendChild($ul);
		
		for ($i = 0; $i < $total; $i += $rows) {
				// difference between current position and start of search
				$diff = $i - $offset;
				
				// only want cases where current is first/last/within spread
				if (0 != $i && 
						($i + $rows) < $total && 
						($diff > $spread || $diff < 0 - $spread)) {
						continue;
				}
				
				// label for link
				$label = "";
				
				switch (true) {
				 case (0 == $i):
						$label = "First";
						break;
						
				 case ($i + $rows >= $total):
						$label = "Last";
						break;
						
				 case ($diff == $spread || $diff == 0 - $spread):
						$label = $dots;
						break;
						
				 default:
						$label = ($i / $rows) + 1;
						break;
				}
				
				$li = null;
				
				// plain text for current page or dots
				if ($i == $offset || $dots == $label) {
						$li = $dom->createElement("li", $label);
				}
				// link for first/last or numbered page
				else {
						$li = $dom->createElement("li");
						$a = $dom->createElement("a", $label);
						$a->setAttribute("href", sprintf("%s?%s&offset=%d",
																						 $php_script, $query_string, $i));
						$li->appendChild($a);
				}
				
				$ul->appendChild($li);
		}
		
		return $dom->documentElement;
}
//}}}

?>
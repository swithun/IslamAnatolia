<?php

class XSLT {

    /****** includes/XSLT.php
     * NAME
     * XSLT.php
     * SYNOPSIS
     * Class for simplifying access to the XSLTProcessor class.
     * AUTHOR
     * Swithun Crowe
     * CREATION DATE
     * 20120710
     ******
     */
    
    private $xslt = null;
    private $debug = false;
    
    /****f* XSLT.php/__construct
     * NAME
     * __construct
     * SYNOPSIS
     * Constructor for the XSLT class. It takes the name of the XSLT file as an argument, and creates the XSLTProcessor object.
     * registerPHPFunctions is called, so that PHP functions can be called from within XSLT scripts.
     * ARGUMENTS
     *   * filename - string giving location of XSLT file
     *   * debug - boolean - if true, then do debugging stuff, default false
     ******
     */
    public function __construct($filename, $debug = false) { //{{{
        $dom = new DomDocument;
        $dom->load($filename);
        
        $this->xslt = new XSLTProcessor();
        $this->debug = $debug;
        
        if ($this->debug) {
            $this->xslt->setProfiling(sprintf("/tmp/%s_%s.txt", 
                                              time(), basename($filename)));
        }
        
        $this->xslt->registerPHPFunctions();
        $this->xslt->importStyleSheet($dom);
    }
    //}}}
    
    /****f* XSLT.php/addParams
     * NAME
     * addParams
     * SYNOPSIS
     * Adds an associative array of name => value parameters to the XSLTProcessor.
     * ARGUMENTS
     *   * params - associative array of parameters to pass into transformation
     * RETURN VALUE
     * Boolean, true on success
     ******
     */
    public function addParams($params) { //{{{
        return $this->xslt->setParameter("", $params);
    }
    //}}}
    
    /****f* XSLT.php/transformToDom
     * NAME
     * transformToDom
     * SYNOPSIS
     * Transforms the given DOM object and returns a DOM of the transformation.
     * ARGUMENTS
     *   * dom - DOM object to be transformed
     * RETURN VALUE
     * DOM object, or false on error
     ******
     */
    public function transformToDom($dom) { //{{{
        if ($this->debug) {
            $dom->save(sprintf("/tmp/%s_%s.xml", time(), mt_rand()));
        }
        
        return $this->xslt->transformToDoc($dom);
    }
    //}}}
    
    /****f* XSLT.php/transformToXML
     * NAME
     * transformToXML
     * SYNOPSIS
     * Transforms the given DOM object and returns a string of the XML.
     * ARGUMENTS
     *   * dom - DOM object to be transformed
     * RETURN VALUE
     * String of XML, or false on failure
     ******
     */
    public function transformToXML($dom) { //{{{
        if ($this->debug) {
            $dom->save(sprintf("/tmp/%s_%s.xml", time(), mt_rand()));
        }
        return $this->xslt->transformToXml($dom);
    }
    //}}}
}

?>

<?php

class Page {

    /****** includes/Page.php
     * NAME
     * Page.php
     * SYNOPSIS
     * Class for the display of web pages using a stylesheet and a DOM.
     * AUTHOR
     * Swithun Crowe
     * CREATION DATE
     * 20120710
     ******
     */

    private $xsltFile = "";
    private $dom = null;
    private $params = null;
    private $raw = false;

    /****f* Page.php/__construct
     * NAME
     * __construct
     * SYNOPSIS
     * Constructor for class. All arguments are optional, and can be set by setter methods later.
     * If all arguments are known at construction time, then pass the arguments.
     * If you want to choose the XSLT file or the DOM or add params later, then use the setter methods.
     * ARGUMENTS
     *   * xsltFile - string - name of XSLT file to use for transforming DOM
     *   * dom - DOM object - DOM to transform
     *   * params - array - associative array of name => value parameters for transform
     ******
     */
    public function __construct($xsltFile = "", $dom = null, $params = null) { //{{{
        $this->xsltFile = $xsltFile;
        $this->dom = $dom;
        $this->params = $params;
    }
    //}}}

    /****f* Page.php/setXsltFile
     * NAME
     * setXsltFile
     * SYNOPSIS
     * Sets the name of the XSLT file to use for generating page.
     * ARGUMENTS
     *   * xsltFile - string - name of XSLT file to use for transforming DOM
     ******
     */
    public function setXsltFile($xsltFile) { //{{{
        $this->xsltFile = $xsltFile;
    }
    //}}}

    /****f* Page.php/setDom
     * NAME
     * setDom
     * SYNOPSIS
     * Sets the DOM for the page
     * ARGUMENTS
     *   * dom - DOM object - the DOM to use for generating the page
     ******
     */
    public function setDom($dom) { //{{{
        $this->dom = $dom;
    }
    //}}}

    /****f* Page.php/setParams
     * NAME
     * setParams
     * SYNOPSIS
     * Sets the DOM for the page.
     * ARGUMENTS
     *   * params - array - associative array of param names and values
     ******
     */
    public function setParams($params) { //{{{
        $this->params = $params;
    }
    //}}}

    /****f* Page.php/setRaw
     * NAME
     * setRaw
     * SYNOPSIS
     * If set, then __toString will return just the XML without the transform.
     * ARGUMENTS
     *   * raw - boolean - default true
     ******
     */
    public function setRaw($raw=true) { //{{{
        $this->raw = (boolean) $raw;
    }
    //}}}
    
    /****f* Page.php/__toString
     * NAME
     * __toString
     * SYNOPSIS
     * Requesting a string representation of the Page will cause the transform to be run.
     * The XSLT processor object is created and the params added.
     * Special params for the relative path, user name and message are added.
     * If no DOM is provided, then a dummy one is used.
     * RETURN VALUE
     * String - the output of the transformation.
     ******
     */
    public function __toString() { //{{{
        global $haveWP;

        $output = "";
        do {
            // check for DOM
            if (null == $this->dom) {
                $this->dummyDom();
            }
            // just raw XML
            if ($this->raw) {
                header("Content-type: text/xml");
                $output = $this->dom->saveXML();
                break;
            }

            // need xsltFile, or use default one
            if (!$this->xsltFile) {
                $this->xsltFile = XSLT_DIR . "templates.xsl";
            }

            // do transform
            $xslt = new XSLT($this->xsltFile);

            if ($this->params) {
                $xslt->addParams($this->params);
            }

            // inject path param for relative paths
            $path = $this->resolvePath($_SERVER["REQUEST_URI"]);
            if ($path) {
                $xslt->addParams(array("path" => $path));
            }

            // get user from Shibboleth
            $user = getUser();
            if ($user) {
                $xslt->addParams(array("user" => $user));
            }

            // get possible message
            $m = $this->getMessage();
            if ($m) {
                $xslt->addParams(array("message" => $m["message"],
                                       "messageClass" => $m["messageClass"]));
            }

            // transform
            $output = $xslt->transformToXML($this->dom);

            // merge with WordPress
            if ($haveWP) {
                // title
                if (isset($this->params["title"])) {
                    $title = $this->params["title"];
                    add_filter("wp_title", function () use ($title) { return $title . " | ";});
                }

                ob_start();
                get_header();
                //get_sidebar("left");
                print sprintf('<div id="content">%s</div>', $output);
                //get_sidebar("right");
                get_footer();

                $output = ob_get_clean();
            }

        } while (false);

        return $output;
    }
    //}}}

    /****f* Page.php/dummyDom
     * NAME
     * dummyDom
     * SYNOPSIS
     * Creates a dummy DOM object containing just a root element called table.
     * This is used when no real DOM containing proper data is provided, but the transform should still happen.
     ******
     */
    private function dummyDom() { //{{{
        $this->dom = new DomDocument();
        $root = $this->dom->createElement("table");
        $this->dom->appendChild($root);
    }
    //}}}

    /****f* Page.php/resolvePath
     * NAME
     * resolvePath
     * SYNOPSIS
     * Calculates the relative path from the given URI to a base one, which is assumed to be an ancestor of the given one.
     * This function works out the number of directories one needs to go up to get from the given URI to the base one.
     * ARGUMENTS
     *   * requestURI - string - the URI that is being requested and which should be below the base URI
     * RETURN VALUE
     * String, either empty, or one or more instances of "../"
     ******
     */
    private function resolvePath($requestURI) { //{{{
        $path = "";
        $dirNameOfBaseURI = dirname(BASE_URI);

        // if file name is missing, then don't remove last element of path
        $requestPath = "/" == substr($requestURI, -1) ?
          $requestURI : dirname($requestURI);

        // move down path until arriving at base path
        while ("/" != $requestPath &&
               $dirNameOfBaseURI != dirname($requestPath)) {
            $path .= "../";
            $requestPath = dirname($requestPath);
        }

        return $path;
    }
    //}}}

    /****f* Page.php/getMessage
     * NAME
     * getMessage
     * SYNOPSIS
     * Returns a message and CSS class name. These are passed from the previous page as GET parameters.
     * RETURN VALUE
     * An array containing the message and message class, or null if these were not present
     ******
     */
    private function getMessage() { //{{{
        $arr = null;

        do {
            if (!isset($_REQUEST["message"]) ||
                !isset($_REQUEST["messageClass"])) {
                break;
            }

            $arr = array ("message" => $_REQUEST["message"],
                          "messageClass" => $_REQUEST["messageClass"]);
        } while (false);

        return $arr;
    }
    //}}}

}

?>

<?php

class DB {

    /****** includes/DB.php
     * NAME
     * DB.php
     * SYNOPSIS
     * Class for communicating with relational database which stores data about documents in Solr index and kept on file system.
     * AUTHOR
     * Swithun Crowe
     * CREATION DATE
     * 20120710
     ******
     */
    
    private $pdo = null;
    private $results = null;
    private $errorMessage = "";
    private $errorCode = 0;
    private $isStatic = false;
    
    public static $instance = null;
    
    /****** DB.php/__construct
     * NAME
     * __construct
     * SYNOPSIS
     * Creates connection to database using defined DSN and credentials.
     * ARGUMENTS
     * isStatic - boolean - optional and false by default, but true when a static singleton object is being created
     ******
     */
    public function __construct($isStatic = false) { //{{{
        $this->pdo = new PDO(ANATOLIA_DB_DSN, ANATOLIA_DB_USER, ANATOLIA_DB_PASS);
        $this->pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        $this->pdo->exec("SET NAMES utf8");
        $this->pdo->exec("SET CHARACTER SET utf8");
        
        $this->isStatic = $isStatic;
    }
    //}}}
    
    /****** DB.php/getInstance
     * NAME
     * getInstance
     * SYNOPSIS
     * Creates and/or returns a singleton instance of a DB object.
     * RETURN VALUE
     * DB - a DB object
     ******
     */
    public static function getInstance() { //{{{
        if (null == self::$instance) {
            self::$instance = new DB(true);
        }
        
        return self::$instance;
    }
    //}}}
    
    /****** DB.php/__call
     * NAME
     * __call
     * SYNOPSIS
     * This method is called when a non-existant method is called on the DB object.
     * The method name is taken to be the name of a stored procedure and the arguments passed to the method are parameters for the procedure.
     * ARGUMENTS
     * name - string - the name of the stored procedure
     * args - array - array of arguments to pass as parameters to the procedure
     * RETURN VALUE
     * Boolean, true on success, if not called from static object, or an array/string if called from static object
     * NOTES
     * If the procedure name starts with "get", then the results are assumed to be an array of rows of columns.
     * If the procedure name starts with "add", then the results are assumed to be the ID of the last inserted row.
     ******
     */
    public function __call($name, $args) { //{{{
        $success = false;
        $this->freshStart();
        
        try {
            // generate SQL string, with ? for each argument
            $sql = sprintf("CALL %s(%s)",
                           $name,
                           substr(str_pad("", count($args) * 2, "?,"), 0, -1));
            
            // prepare statement
            $stmt = $this->pdo->prepare($sql);
            
            // bind procedure parameters
            foreach ($args as $i => $value) {
                $stmt->bindValue($i + 1, $value);
            }
            
            // execute procedure
            $stmt->execute();
            
            // what to get back from database
            switch (substr($name, 0, 3)) {
                // getting a row or more from the database
             case "get":
             case "add":
                $this->results = $stmt->fetchAll(PDO::FETCH_ASSOC);
                break;
                // added, so get a last insert id
             /*case "add":
                $this->results = $this->pdo->lastInsertId();
                break;*/
             default:
                break;
            }

            //$success =  $this->isStatic ? $this->results : true;
            $success = true;
        }
        catch (PDOException $e) {
            $this->errorMessage = $e->getMessage();
            $this->errorCode = $e->getCode();
        }
        
        return $success;
    }
    //}}}
    
    /****** DB.php/getResultsAsXML
     * NAME
     * getResultsAsXML
     * SYNOPSIS
     * Convert a two dimensional array of results from a query into a DOM object.
     * Should only be called when the query would produce such an array.
     * RETURN VALUE
     * DOM containing data from database query, or null on failure.
     ******
     */
    public function getResultsAsXML() { //{{{
        $results = null;
        
        do {
            if (!$this->results || 
                !is_array($this->results)) {
                break;
            }
            
            $results = new DomDocument();
            $table = $results->createElement("table");
            
            foreach ($this->results as $resultRow) {
                $row = $results->createElement("row");
                foreach ($resultRow as $cellName => $cellValue) {
                    $cell = $results->createElement($cellName, $cellValue);
                    $row->appendChild($cell);
                }
                $table->appendChild($row);
            }

            $results->appendChild($table);
        } while (false);
        
        return $results;
    }
    //}}}
    
    /****** DB.php/getResults
     * NAME
     * getResults
     * SYNOPSIS
     * Returns the results of a query of the database.
     * RETURN VALUE
     * A two dimensional array or a string containing the ID of the last inserted row, depending on the name of the procedure used in the query.
     ******
     */
    public function getResults() { //{{{
        return $this->results;
    }
    //}}}
    
    /****** DB.php/getError
     * NAME
     * getError
     * SYNOPSIS
     * Get the error code and message from a failed database call.
     * RETURN VALUE
     * An array containing the error code and error message
     ******
     */
    public function getError() { //{{{
        return array($this->errorCode,
                     $this->errorMessage);
    }
    //}}}

    /****** DB.php/freshStart
     * NAME
     * freshStart
     * SYNOPSIS
     * Reset some class members before running a new query.
     ******
     */
    private function freshStart() { //{{{
        $this->results = null;
        $this->errorMessage = "";
        $this->errorCode = 0;
    }
    //}}}
}

?>

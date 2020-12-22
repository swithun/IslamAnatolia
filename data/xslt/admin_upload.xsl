<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    >

  <!--****** xslt/admin_upload.xsl
 * NAME
 * admin_upload.xsl
 * SYNOPSIS
 * Templates for creating a page for uploading TEI documents.
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20120710
 * SEE ALSO
 *   * xslt/templates.xsl
 ****-->
  
  <xsl:include href="templates.xsl"/>
  <xsl:param name="file_item"/>
  
  <xsl:template match="table">
    <h2>Admin page</h2>
    <h3>Upload new/replacement documents</h3>
    
    <form method="post" enctype="multipart/form-data" action="index.php">
      <p>
        <label for="{$file_item}">Document</label>
        <input type="file" name="{$file_item}" id="{$file_item}"/>
      </p>
      <p>
        <input type="hidden" name="is_upload" value="1"/>
        <input type="submit" value="Upload"/>
      </p>
    </form>
    
    <p>
      <a href="index.php">Return to admin index</a>.
    </p>
  </xsl:template>
  
</xsl:stylesheet>

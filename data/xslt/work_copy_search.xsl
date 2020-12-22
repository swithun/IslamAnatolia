<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.w3.org/1999/xhtml"
    >

  <!--****** xslt/work_copy_search.xsl
 * NAME
 * work_copy_search.xsl
 * SYNOPSIS
 * XSLT document for showing results from work/copy search.
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20121029
 * SEE ALSO
 *   * xslt/search.xsl
 ****-->

  <xsl:include href="search.xsl"/>
  
  <xsl:template match="response">
    <xsl:apply-templates select="result"/>
    <xsl:apply-templates select="lst[@name='highlighting']"/>
  </xsl:template>

</xsl:stylesheet>

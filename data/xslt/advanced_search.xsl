<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.w3.org/1999/xhtml"
    >
  
  <!--****** xslt/advanced_search.xsl
 * NAME
 * advanced_search.xsl
 * SYNOPSIS
 * XSLT document for generating advanced search form. For listing results etc., search.xsl is used.
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20120710
 * SEE ALSO
 *   * xslt/search.xsl
 ****-->

  <xsl:include href="search.xsl"/>
  
  <xsl:param name="query_ms"/>
  <xsl:param name="query_author"/>
  <xsl:param name="query_authority"/>
  <xsl:param name="query_bib"/>
  <xsl:param name="return_type"/>
  
  <xsl:template match="table">
    <xsl:call-template name="advanced_form"/>
  </xsl:template>
  
  <xsl:template match="response">
    <xsl:apply-templates select="result" mode="header"/>
    <xsl:apply-templates select="lst[@name='highlighting']"/>
    <xsl:apply-templates select="result" mode="footer"/>
    <xsl:call-template name="advanced_form"/>
  </xsl:template>
  
  <xsl:template name="advanced_form">
    <h2>Advanced search</h2>
    <form action="advanced_search.php" method="get">
      <p>
  <label for="query_ms">Search manuscripts</label>
  <input type="text" name="query_ms" id="query_ms" value="{$query_ms}" class="keyboardInput"/>
      </p>
      <p>
  <label for="query_author">Search author authority files</label>
  <input type="text" name="query_author" id="query_author" value="{$query_author}" class="keyboardInput"/>
      </p>
      <p>
  <label for="query_authority">Search other authority files</label>
  <input type="text" name="query_authority" id="query_authority" value="{$query_authority}" class="keyboardInput"/>
      </p>
      <p>
  <label for="query_bib">Search bibliographic items</label>
  <input type="text" name="query_bib" id="query_bib" value="{$query_bib}" class="keyboardInput"/>
      </p>
      <p>
  <label for="return_type">Return documents of this type</label>
  <select id="return_type" name="return_type">
    <option value="1">
      <xsl:if test="$return_type = 1">
        <xsl:attribute name="selected">selected</xsl:attribute>
      </xsl:if>
      <xsl:text>Manuscripts</xsl:text>
    </option>
    <option value="2">
      <xsl:if test="$return_type = 2">
        <xsl:attribute name="selected">selected</xsl:attribute>
      </xsl:if>
      <xsl:text>Authority files</xsl:text>
    </option>
    <option value="3">
      <xsl:if test="$return_type = 3">
        <xsl:attribute name="selected">selected</xsl:attribute>
      </xsl:if>
      <xsl:text>Bibliographic items</xsl:text>
    </option>
  </select>
      </p>
      <p>
  <input type="hidden" name="submit" value="submit"/>
  <input type="submit" value="Search"/>
      </p>
    </form>
  </xsl:template>
  
</xsl:stylesheet>

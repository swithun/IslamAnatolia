<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.w3.org/1999/xhtml"
    >
  
  <!--****** xslt/list_documents_public.xsl
 * NAME
 * list_documents_public.xsl
 * SYNOPSIS
 * Templates for transforming database output into a page showing all documents in the system. This is the public view.
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20120710
 * SEE ALSO
 *   * xslt/templates.xsl
 ****-->

  <!-- params with defaults -->
  <xsl:param name="type">ms</xsl:param>
  <xsl:param name="offset">0</xsl:param>
  <xsl:param name="limit">50</xsl:param>
  <xsl:param name="url"/>
  
  <xsl:include href="templates.xsl"/>
  
  <xsl:template match="table">
    <h3>List of documents in system</h3>
    
    <ol>
      <!-- need start attribute -->
      <xsl:if test="$offset &gt; 0">
	<xsl:attribute name="start">
	  <xsl:value-of select="$offset + 1"/>
	</xsl:attribute>
      </xsl:if>
      <xsl:apply-templates/>
    </ol>
    <!-- page controls -->
    <xsl:call-template name="page_controls"/>
  </xsl:template>
  
  <xsl:template match="row">
    <li>
      <xsl:apply-templates select="documentName"/>
    </li>
  </xsl:template>
  
  <xsl:template match="documentName">
    <a href="documents/{$type}/{.}">
      <xsl:apply-templates/>
    </a>
  </xsl:template>
  
  <xsl:template name="page_controls">
    <p>
      <xsl:if test="$offset &gt; 0">
	<a href="{$url}&amp;offset={$offset - $limit}">
	  <xsl:text>Previous</xsl:text>
	</a>
	<xsl:text> </xsl:text>
      </xsl:if>
      <xsl:if test="count(/table/row) = $limit">
	<a href="{$url}&amp;offset={$offset + $limit}">
	  <xsl:text>Next</xsl:text>
	</a>
      </xsl:if>
    </p>
  </xsl:template>
  
</xsl:stylesheet>

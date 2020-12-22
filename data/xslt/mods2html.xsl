<?xml version="1.0" encoding="UTF-8"?><!-- -*- xml -*- -->
<xsl:stylesheet
    version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:php="http://php.net/xsl"
    xmlns:mads="http://www.loc.gov/mads/v2"
    xmlns:mods="http://www.loc.gov/mods/v3"
    xsl:extension-element-prefixes="php"
		exclude-result-prefixes="mods mads"
    >
  
  <!--****** xslt/mods2html.xsl
 * NAME
 * mods2html.xsl
 * SYNOPSIS
 * Stylesheet for transforming MODS (bibliographic data) into HTML.
 * Most templates are in mods2html_includes, which is shared by several XSLT scripts.
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20120710
 * SEE ALSO
 *   * xslt/templates.xsl
 *   * xslt/mods2html_include.xsl
 ****-->
  
  <xsl:include href="templates.xsl"/>
  <xsl:include href="mods2html_include.xsl"/>
  
  <xsl:template match="mods:mods">
    <h2>Bibliographic item</h2>
    <p>
      <xsl:apply-templates select="." mode="html_bib"/>
    </p>
  </xsl:template>
  
</xsl:stylesheet>

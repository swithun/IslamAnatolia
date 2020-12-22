<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.w3.org/1999/XSL/Format"
    xmlns:php="http://php.net/xsl"
    xmlns:mads="http://www.loc.gov/mads/v2"
    xmlns:mods="http://www.loc.gov/mods/v3"
    extension-element-prefixes="php"
    exclude-result-prefixes="mods mads php tei"
    >
  
  <!--****** xslt/tei2html.xsl
 * NAME
 * tei2html.xsl
 * SYNOPSIS
 * Stylesheet for transforming TEI into HTML.
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20120710
 * SEE ALSO
 *   * xslt/templates.xsl
 *   * xslt/mods2html_include.xsl
 * NOTES
 * The Fihrist manual (http://www.fihrist.org.uk/manual/) was used to understand how to display the TEI. The numbers in [square brackets] are chapter numbers from the manual.
 * PHP functions are called from several templates here. These are for getting authority files (from remote sites or locally stored copies) and converting URNs to URLs for these authority files.
 ****-->
  
  <xsl:template match="tei:TEI">
    <root xmlns:fo="http://www.w3.org/1999/XSL/Format">
      <layout-master-set>
        <simple-page-master master-name="my-page">
          <region-body margin="1in"/>
        </simple-page-master>
      </layout-master-set>
      
      <page-sequence master-reference="my-page">
        <flow flow-name="xsl-region-body">
          <block>Hello, world!</block>
        </flow>
      </page-sequence>
    </root>
  </xsl:template>
  
</xsl:stylesheet>
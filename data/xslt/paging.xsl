<?xml version="1.0" encoding="UTF-8"?><!-- -*- xml -*- -->
<xsl:stylesheet
    version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl"
    xmlns:data="urn:data"
    exclude-result-prefixes="tei data"
    >

  <!--****** xslt/paging.xsl
 * NAME
 * paging.xsl
 * SYNOPSIS
 * Templates for paging of results
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20151124
 ****-->
  
<!--/****f* paging.xsl/hits_stats
 * NAME
 * hits_stats
 * SYNOPSIS
 * Output paragraph about number of hits and how many are on this page.
 * ARGUMENTS
 *   * total - integer - total number of hits
 *   * offset - integer - number of first hit on page, 0 indexed
 *   * rows - integer - maximum number of hits to show on page, e.g. 10
 ******
 */-->
  <xsl:template name="hits_stats">
    <xsl:param name="total" select="number(0)"/>
    <xsl:param name="offset" select="number(0)"/>
    <xsl:param name="rows" select="number(0)"/>
    
    <p id="hits_stats">
      <xsl:choose>
        <!-- no hits -->
        <xsl:when test="$total = 0">
          <xsl:text>There were no results matching your query.</xsl:text>
        </xsl:when>
        <!-- 1 hit -->
        <xsl:when test="$total = 1">
          <xsl:text>Displaying the single result matching your query.</xsl:text>
        </xsl:when>
        <!-- more than 1 hit -->
        <xsl:otherwise>
          <xsl:value-of select="concat('There were ', $total, ' results matching your query. ')"/>
          <xsl:choose>
            <!-- hits fit on 1 page -->
            <xsl:when test="$total &lt;= $rows">
              <xsl:text>Displaying all of them.</xsl:text>
            </xsl:when>
            <!-- displaying first page -->
            <xsl:when test="$offset = 0">
              <xsl:text>Displaying first page.</xsl:text>
            </xsl:when>
            <!-- showing last page of hits -->
            <xsl:when test="$total &lt;= $offset + $rows">
              <xsl:text>Displaying last page.</xsl:text>
            </xsl:when>
            <!-- showing page of hits which isn't last page -->
            <xsl:otherwise>
              <xsl:value-of select="concat('Displaying page ', ($offset div $rows) + 1, '.')"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </p>
  </xsl:template>

</xsl:stylesheet>
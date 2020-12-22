<?xml version="1.0" encoding="UTF-8"?><!-- -*- xml -*- -->
<xsl:stylesheet
    version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="tei"
    >
  
  <!--****** xslt/search.xsl
 * NAME
 * search.xsl
 * SYNOPSIS
 * Templates for transforming a Solr query response into HTML.
 * Administrators' view.
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20120710
 * SEE ALSO
 *   * xslt/templates.xsl
 ****-->
  <xsl:import href="templates.xsl"/>
  
  <xsl:param name="query"/>
  <xsl:param name="offset">0</xsl:param>
  <xsl:param name="limit">50</xsl:param>
  <xsl:param name="url"/>
  <xsl:param name="search_type">search</xsl:param>
  <xsl:param name="ms_physical_location_country"/>
  <xsl:param name="ms_physical_location_settlement"/>
  <xsl:param name="ms_physical_location_institution"/>
  <xsl:param name="ms_physical_location_repository"/>
  <xsl:param name="ms_physical_location_collection"/>
  
  <xsl:template match="response">
    <xsl:apply-templates select="result" mode="header"/>
    
    <!-- show search results -->
    <xsl:apply-templates select="lst[@name='highlighting']"/>
    
    <!-- show facets, if there are any -->
    <xsl:apply-templates select="lst[@name='facet_counts'][lst[@name='facet_fields']/lst/int]"/>
    
    <xsl:apply-templates select="result" mode="footer"/>
    <xsl:if test="$search_type = 'search'">
      <xsl:call-template name="form"/>
    </xsl:if>
    <!--xsl:copy-of select="/"/-->
  </xsl:template>

  <!-- facets -->
  <xsl:template match="lst[@name='facet_counts']">
    <dl>
      <xsl:apply-templates select="lst[@name='facet_fields']/lst[int]"/>
    </dl>
  </xsl:template>
  
  <xsl:template match="lst[@name='ms_physical_location_country']">
    <dt>Country</dt>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="lst[@name='ms_physical_location_settlement']">
    <dt>Town</dt>
    <xsl:apply-templates/>
  </xsl:template>
  
  <xsl:template match="lst[@name='ms_physical_location_institution']">
    <dt>Institution</dt>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="lst[@name='ms_physical_location_repository']">
    <dt>Repository</dt>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="lst[@name='ms_physical_location_collection']">
    <dt>Collection</dt>
    <xsl:apply-templates/>
  </xsl:template>
  
  <xsl:template match="lst[@name='facet_fields']/lst/int">
    <dd>
      <a href="{$url}&amp;{parent::lst/@name}={@name}">
        <xsl:value-of select="concat(@name, ' (', ., ')')"/>
      </a>
    </dd>
  </xsl:template>
  
  <!-- result information at top of list of hits -->
  <xsl:template match="result" mode="header">
    <h2>
      <xsl:choose>
        <xsl:when test="$search_type = 'search'">
          <xsl:text>Search results</xsl:text>
        </xsl:when>
        <xsl:when test="$search_type = 'list'">
          <xsl:text>List of documents</xsl:text>
        </xsl:when>
        <xsl:when test="$search_type = 'basket'">
          <xsl:text>Basket</xsl:text>
        </xsl:when>
      </xsl:choose>
    </h2>
    <p>
      <xsl:if test="$search_type = 'search' and $query">
        <xsl:call-template name="searched_for"/>
      </xsl:if>
      
      <xsl:choose>
        <xsl:when test="@numFound = 0">
          <xsl:text>Nothing was found.</xsl:text>
        </xsl:when>
        <xsl:when test="@numFound = 1">
          <xsl:text>One document was found.</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="@numFound"/>
          <xsl:text> document were found. </xsl:text>
        </xsl:otherwise>
      </xsl:choose>
      
      <xsl:choose>
        <xsl:when test="@numFound &gt; 0 and @numFound &lt;= $limit">
          <xsl:text>Showing all documents.</xsl:text>
        </xsl:when>
        <xsl:when test="$offset + $limit &lt; @numFound">
          <xsl:value-of select="concat('Showing results ', $offset + 1, ' to ', $offset + $limit)"/>
        </xsl:when>
        <xsl:when test="@numFound &gt; 0">
          <xsl:value-of select="concat('Showing results ', $offset + 1, ' to ', @numFound)"/>
        </xsl:when>
      </xsl:choose>
    </p>
  </xsl:template>
  
  <!-- result information at bottom of list of hits -->
  <xsl:template match="result" mode="footer">
    <p>
      <xsl:if test="$offset &gt; 0">
        <a href="{$url}&amp;offset={$offset - $limit}">
          <xsl:text>Previous </xsl:text>
          <xsl:value-of select="$limit"/>
        </a>
        <xsl:text> </xsl:text>
      </xsl:if>
      <xsl:if test="$offset + $limit &lt; @numFound">
        <a href="{$url}&amp;offset={$offset + $limit}">
          <xsl:text>Next </xsl:text>
          <xsl:choose>
            <xsl:when test="@numFound &lt; $offset + $limit + $limit">
              <xsl:value-of select="@numFound - ($offset + $limit)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$limit"/>
            </xsl:otherwise>
          </xsl:choose>
        </a>
      </xsl:if>
    </p>
  </xsl:template>
  
  <xsl:template match="lst[@name='highlighting']">
    <dl class="hit_list">
      <xsl:apply-templates mode="hits"/>
    </dl>
  </xsl:template>
  
  <xsl:template match="lst" mode="hits">
    <xsl:apply-templates select="/response/result[@name='response']/doc[str[@name='id']=current()/@name]"/>
    <xsl:apply-templates select="arr[1]"/>
  </xsl:template>
  
  <xsl:template match="arr">
    <dd>
      <xsl:value-of select="." disable-output-escaping="yes"/>
    </dd>
  </xsl:template>
  
  <!-- display MS document hit -->
  <xsl:template match="doc[str[@name='doc_type'][. = 'work' or . = 'ms']]">
    <dt>
      <xsl:call-template name="number">
        <xsl:with-param name="pos" select="count(preceding-sibling::doc)"/>
      </xsl:call-template>
      <a href="{$path}documents/{str[@name='id']}">
        <xsl:value-of select="arr[starts-with(@name, 'work_title') or starts-with(@name, 'ms_title')]/str[1]"/>
      </a>
      <xsl:apply-templates select="str[@name='id']"/>
    </dt>
  </xsl:template>
  
  <!-- display authority file hit -->
  <xsl:template match="doc[str[@name='doc_type']='auth']">
    <dt>
      <xsl:call-template name="number">
        <xsl:with-param name="pos" select="count(preceding-sibling::doc)"/>
      </xsl:call-template>
      <a href="{$path}documents/auth/{str[@name='id']}">
        <xsl:value-of select="arr/str[1]"/>
      </a>
      <xsl:apply-templates select="str[@name='id']"/>
    </dt>
  </xsl:template>
  
  <!-- display bibliographic item hit -->
  <xsl:template match="doc[str[@name='doc_type']='bibliography']">
    <dt>
      <xsl:call-template name="number">
        <xsl:with-param name="pos" select="count(preceding-sibling::doc)"/>
      </xsl:call-template>
      <a href="{$path}documents/bib/{str[@name='id']}">
        <xsl:value-of select="arr[@name='title']/str[1]"/>
      </a>
      <xsl:apply-templates select="str[@name='id']"/>
    </dt>
  </xsl:template>
  
  <!-- put name of document in brackets -->
  <xsl:template match="str[@name='id']">
    <xsl:value-of select="concat(' (', ., ')')"/>
  </xsl:template>
  
  <xsl:template name="form">
    <h2>Search</h2>
    <form method="get" action="search.php">
      <p>
        <label for="q">Query</label>
        <input type="text" name="q" id="q" class="keyboardInput">
          <xsl:attribute name="value">
            <xsl:value-of select="$query" disable-output-escaping="yes"/>
          </xsl:attribute>
        </input>
      </p>
      <p>
        <input type="submit" value="Search"/>
      </p>
    </form>
  </xsl:template>
  
  <xsl:template name="number">
    <xsl:param name="pos"/>
    <xsl:value-of select="concat($pos + $offset + 1, '. ')"/>
  </xsl:template>
  
  <xsl:template name="footer">
    <p>
      <a href="index.php">Back to main page</a>
    </p>
  </xsl:template>

  <!-- generate phrase for what has been searched for -->
  <xsl:template name="searched_for">
    <xsl:text>Your search was for </xsl:text>
    
    <xsl:if test="$query">
      <em>
        <xsl:value-of select="$query" disable-output-escaping="yes"/>
      </em>
    </xsl:if>
    
    <!-- use 'with' if there has been a query -->
    <xsl:variable name="with">
      <xsl:if test="$query">
        <xsl:text> with </xsl:text>
      </xsl:if>
    </xsl:variable>
    
    <xsl:if test="$ms_physical_location_country">
      <!-- look for previous params -->
      <xsl:if test="$query">
        <xsl:text> and </xsl:text>
      </xsl:if>
      <xsl:value-of select="$with"/>
      <xsl:text> country </xsl:text>
      <em>
        <xsl:value-of select="$ms_physical_location_country"/>
      </em>
    </xsl:if>

    <xsl:if test="$ms_physical_location_settlement">
      <!-- look for previous params -->
      <xsl:if test="$query or $ms_physical_location_country">
        <xsl:text> and </xsl:text>
      </xsl:if>
      <xsl:value-of select="$with"/>
      <xsl:text> town </xsl:text>
      <em>
        <xsl:value-of select="$ms_physical_location_settlement"/>
      </em>
    </xsl:if>

    <xsl:if test="$ms_physical_location_institution">
      <!-- look for previous params -->
      <xsl:if test="$query or $ms_physical_location_country or $ms_physical_location_settlement">
        <xsl:text> and </xsl:text>
      </xsl:if>
      <xsl:value-of select="$with"/>
      <xsl:text> institution </xsl:text>
      <em>
        <xsl:value-of select="$ms_physical_location_institution"/>
      </em>
    </xsl:if>

    <xsl:if test="$ms_physical_location_repository">
      <!-- look for previous params -->
      <xsl:if test="$query or $ms_physical_location_country or $ms_physical_location_settlement or $ms_physical_location_institution">
        <xsl:text> and </xsl:text>
      </xsl:if>
      <xsl:value-of select="$with"/>
      <xsl:text> repository </xsl:text>
      <em>
        <xsl:value-of select="$ms_physical_location_repository"/>
      </em>
    </xsl:if>

    <xsl:if test="$ms_physical_location_collection">
      <!-- look for previous params -->
      <xsl:if test="$query or $ms_physical_location_country or $ms_physical_location_settlement or $ms_physical_location_institution or $ms_physical_location_repository">
        <xsl:text> and </xsl:text>
      </xsl:if>
      <xsl:value-of select="$with"/>
      <xsl:text> collection </xsl:text>
      <em>
        <xsl:value-of select="$ms_physical_location_collection"/>
      </em>
    </xsl:if>
    
    <xsl:text>. </xsl:text>
  </xsl:template>
  
</xsl:stylesheet>
<?xml version="1.0" encoding="UTF-8"?><!-- -*- xml -*- -->
<xsl:stylesheet
    version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:exsl="http://exslt.org/common"
    xmlns:php="http://php.net/xsl"
    extension-element-prefixes="exsl php"
    xmlns:data="urn:data"
    exclude-result-prefixes="tei data"
    >

  <!--****** xslt/index.xsl
 * NAME
 * index.xsl
 * SYNOPSIS
 * Templates for creating an index page for the public.
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20120710
 * SEE ALSO
 *   * xslt/params.xsl
 *   * xslt/templates.xsl
 *   * xslt/facets.xsl
 *   * xslt/hits.xsl
 ****-->
  
  <xsl:include href="params.xsl"/>
  <xsl:include href="templates.xsl"/>
  <xsl:include href="facets.xsl"/>
  <xsl:include href="hits.xsl"/>

  <xsl:template match="response">
    <div>
      <header class="entry-header">
        <h1 class="entry-title">Database of medieval Anatolian texts and manuscripts in Arabic, Persian and Turkish</h1>
      </header>
      
      <form method="get" action="{$php_script}">
        <xsl:choose>
          <!-- not place search and have have something to display -->
          <xsl:when test="$field != 'places' and $haveQuery or $haveFacets">
            <!-- show unused facets -->
            <div id="facets_left">
              <!-- list of used facets -->
              <xsl:if test="exsl:node-set($params)/data:params/data:param[@value != ''][@field != 'field']">
                <div class="facet_group">
                  <p>Current filters</p>
                  
                  <ul id="used_fields">
                    <xsl:apply-templates 
                        select="exsl:node-set($params)/data:params/data:param[@value != ''][@field != 'field']" 
                        mode="used_facet_list"
                        />
                  </ul>
                </div>
              </xsl:if>
              
              <xsl:choose>
                <!-- nothing found -->
                <xsl:when test="result/@numFound = 0">
                  <p>Nothing found</p>
                </xsl:when>
                
                <!-- facet list -->
                <xsl:when test="lst[@name='facet_counts'][descendant::int &gt; 1]">
                  <xsl:apply-templates select="exsl:node-set($params)/data:params/data:param[@solr]" mode="facet_list"/>
                </xsl:when>
                
                <!-- no facets left -->
                <xsl:otherwise>
                  <p>No further filtering possible</p>
                </xsl:otherwise>
              </xsl:choose>
            </div>
            
            <!-- have query, so show used facets & results -->
            <div id="resultset">
              <h3>Results</h3>
              <xsl:apply-templates select="result[1]"/>
            </div>
          </xsl:when>
          
          <!-- places search -->
          <xsl:when test="$field = 'places'">
            <div id="resultset">
              <xsl:call-template name="place_search"/>
            </div>
          </xsl:when>
          
        </xsl:choose>
        
        <div id="srch_manscrpts">
          <h3>Search</h3>
          
          <!-- generate query/field DIVs -->
          <xsl:call-template name="query_field_div">
            <xsl:with-param name="qs" select="$q"/>
            <xsl:with-param name="fs" select="$field"/>
          </xsl:call-template>
          
          <p>
            <label for="sort_field">Sort</label>
            <select id="sort_field" name="sort_field">
              <xsl:for-each select="exsl:node-set($sort_fields)/data:data/data:item">
                <option value="{@value}">
                  <xsl:if test="@value = $sort_field">
                    <xsl:attribute name="selected">selected</xsl:attribute>
                  </xsl:if>
                  <xsl:value-of select="."/>
                </option>
              </xsl:for-each>
            </select>
            
            <select id="sort_direction" name="sort_direction">
              <xsl:for-each select="exsl:node-set($sort_directions)/data:data/data:item">
                <option value="{@value}">
                  <xsl:if test="@value = $sort_direction">
                    <xsl:attribute name="selected">selected</xsl:attribute>
                  </xsl:if>
                  <xsl:value-of select="."/>
                </option>
              </xsl:for-each>
            </select>
          </p>
          
          <p>
            <!-- number of hits -->
            <label for="hits">Results</label>
            <select name="hits">
              <xsl:for-each select="exsl:node-set($number_of_hits)/data:data/data:item">
                <option value="{.}">
                  <xsl:if test=". = $rows">
                    <xsl:attribute name="selected">selected</xsl:attribute>
                  </xsl:if>
                  <xsl:value-of select="concat(., ' hits per page')"/>
                </option>
              </xsl:for-each>
            </select>
          </p>
          
          <p>
            <input type="submit" value="Search"/>
            <input type="button" value="Reset" class="reset"/>
          </p>
          
          <p>
            <a href="{$php_script}?q=*&amp;field[]=text&amp;doctype=work&amp;sort_field=title&amp;sort_direction=asc">Browse works</a>
            <br/>
            <xsl:text>Tips on </xsl:text>
            <a href="https://www.islam-anatolia.ac.uk/?page_id=321">searching the database</a>
          </p>
        </div>
      </form>
    </div>
    <!--xsl:copy-of select="/"/-->
  </xsl:template>
  
  <!-- template to generate multiple DIVs for query and field controls -->
  <xsl:template name="query_field_div">
    <xsl:param name="qs"/>
    <xsl:param name="fs"/>

    <!-- get current query/field -->
    <xsl:variable name="this_query">
      <xsl:choose>
        <xsl:when test="contains($qs, '|')">
          <xsl:value-of select="substring-before($qs, '|')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$qs"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="this_field">
      <xsl:choose>
        <xsl:when test="contains($fs, '|')">
          <xsl:value-of select="substring-before($fs, '|')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$fs"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <div>
      <p>
        <label for="q">Query</label>
        <input type="text" name="q[]" id="q" class="keyboardInput" value="{$this_query}"/>
      </p>
      
      <p>
        <label for="field">In</label>
        <select id="field" name="field[]">
          <xsl:for-each select="exsl:node-set($fields)/data:fields/data:option">
            <option value="{@value}">
              <xsl:if test="@value = $this_field">
                <xsl:attribute name="selected">selected</xsl:attribute>
              </xsl:if>
              <xsl:value-of select="."/>
            </option>
          </xsl:for-each>
        </select>
        
        <input type="button" value="Add" class="add_field"/>
        <input type="button" value="Remove" class="remove_field"/>
      </p>
    </div>

    <!-- have more queries/fields -->
    <xsl:if test="contains($qs, '|')">
      <xsl:call-template name="query_field_div">
        <xsl:with-param name="qs" select="substring-after($qs, '|')"/>
        <xsl:with-param name="fs" select="substring-after($fs, '|')"/>
      </xsl:call-template>
    </xsl:if>
    
  </xsl:template>
</xsl:stylesheet>

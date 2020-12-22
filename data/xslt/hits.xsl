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
 * 20151125
 ****-->
  
  <!-- highlight - query string to pass highlight text to Javascript -->
  <xsl:variable name="highlight">
    <xsl:variable name="hl">
      <xsl:for-each select="exsl:node-set($params)/data:params/data:param[@value != ''][@field != 'field' and @field != 'data']">
        <xsl:variable name="value">
          <xsl:choose>
            <xsl:when test="@field = 'language'">
              <xsl:value-of select="string(exsl:node-set($languages)/data:languages/data:item[@value=current()/@value])"/>
            </xsl:when>
            <xsl:when test="@field = 'script'">
              <xsl:value-of select="string(exsl:node-set($scripts)/data:languages/data:item[@value=current()/@value])"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="string(@value)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        
        <xsl:if test="$value != ''">
          <xsl:value-of select="concat(' ', $value)"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>
    <!-- have things to highlight, so run them through PHP function -->
    <xsl:if test="$hl">
      <xsl:value-of select="php:function('utf8_to_unicode', $hl)"/>
    </xsl:if>
  </xsl:variable>

  <!-- count of results, paging and list of results -->
  <xsl:template match="result">
    <!-- number of hits for given type -->
    <xsl:variable name="hits">
      <xsl:choose>
        <xsl:when test="following-sibling::result/@numFound">
          <xsl:value-of select="following-sibling::result/@numFound"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="number(0)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- offset of search -->
    <xsl:variable name="offset">
      <xsl:choose>
        <xsl:when test="following-sibling::result/@start">
          <xsl:value-of select="following-sibling::result/@start"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="number(0)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <!-- information about search results -->
    <xsl:call-template name="hits_stats">
      <xsl:with-param name="total" select="$hits"/>
      <xsl:with-param name="offset" select="$offset"/>
      <xsl:with-param name="rows" select="$rows"/>
    </xsl:call-template>
    
    <ul id="hits">
      <xsl:choose>
        <xsl:when test="$doctype = 'work' or $doctype = 'ms'">
          <xsl:apply-templates select="doc[str[@name='doc_type'] = 'work']">
            <xsl:sort 
                select="/response/result[2]/doc[str[@name='id'] = current()/str[@name='id']]/float[@name='score']" 
                order="{$sort_direction}ending"
                />
          </xsl:apply-templates>
        </xsl:when>
        <xsl:when test="$doctype = 'people'">
          <xsl:apply-templates select="doc[str[@name='auth_type'] = 'person']"/>
        </xsl:when>
      </xsl:choose>
    </ul>

    <!-- generate list of links to pages in results -->
    <xsl:if test="$hits &gt; $rows">
      <xsl:copy-of select="php:function('paging_list', $hits, $offset, $rows, $php_script, $query_string)"/>
    </xsl:if>
  </xsl:template>
  
  <!-- show result for work -->
  <xsl:template match="doc[str[@name='doc_type'] = 'work']">
    <xsl:variable name="title" select="string(arr[@name='title']/str[1])"/>
    
    <li>
      <!-- work title -->
      <div class="hit_title">
        <xsl:choose>
          <!-- have work title -->
          <xsl:when test="arr[(starts-with(@name, 'work_title_') or starts-with(@name, 'work_subTitle_')) and str[1] = $title]">
            <xsl:apply-templates 
                select="arr[(starts-with(@name, 'work_title_') or starts-with(@name, 'work_subTitle_')) and str[1] = $title]" 
                mode="latin_ara"
                />
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="href">
              <xsl:apply-templates select="." mode="doc_href"/>
            </xsl:variable>
            <a href="{$href}">
              <xsl:choose>
                <!-- any title is better than nothing -->
                <xsl:when test="$title != ''">
                  <xsl:value-of select="$title"/>
                </xsl:when>
                <!-- really untitled -->
                <xsl:otherwise>
                  <xsl:text>Untitled</xsl:text>
                </xsl:otherwise>
              </xsl:choose>
            </a>
          </xsl:otherwise>
        </xsl:choose>
      </div>
      
      <!-- author -->
      <div class="hit_author">
        <xsl:apply-templates select="arr[@name = 'work_author']" mode="latin_ara"/>
      </div>
      
      <!-- manuscript -->
      <div class="hit_ms">
        <xsl:apply-templates 
            select="parent::result/doc[str[@name='id'] = current()/str[@name='work_parent_id']]" 
            mode="ms_from_work"
            />
      </div>
    </li>
  </xsl:template>
  
  <!-- show result for authority file -->
  <xsl:template match="doc[str[@name='doc_type'] = 'auth']">
    <xsl:variable name="href">
      <xsl:apply-templates select="." mode="doc_href"/>
    </xsl:variable>
    <li>
      <div class="hit_title">
        <a href="{$href}">
          <xsl:apply-templates select="str[@name='auth_title']"/>
        </a>
      </div>
    </li>
  </xsl:template>

  <!-- MS information dislpayed in work field -->
  <xsl:template match="doc" mode="ms_from_work">
    <xsl:text>Manuscript </xsl:text>
    <xsl:apply-templates select="str[@name='ms_identifier_idno']"/>
    <xsl:text> (from </xsl:text>
    <xsl:apply-templates select="str[@name='ms_physical_location_collection']"/>
    <xsl:apply-templates select="str[@name='ms_physical_location_institution']"/>
    <xsl:apply-templates select="str[@name='ms_physical_location_settlement']"/>
    <xsl:apply-templates select="str[@name='ms_physical_location_country']"/>
    <xsl:text>)</xsl:text>
  </xsl:template>

  <xsl:template match="doc" mode="people">
    <li>
      <div class="hit_title">
        <xsl:apply-templates 
            select="arr[@name='name']" 
            mode="latin_ara"
            />
      </div>
    </li>
  </xsl:template>
  
  <!-- put text into latin/ara span -->
  <xsl:template match="arr" mode="latin_ara">
    <span>
      <xsl:attribute name="class">
        <xsl:choose>
          <xsl:when test="contains(@name, '-Latn-x-lc') or contains(@name, '_eng') or contains(@name, 'tur') or @name = 'work_author'">
            <xsl:text>latin</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>ara</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:apply-templates select="str[1]" mode="latin_ara"/>
    </span>
  </xsl:template>
  
  <!-- what to do with latin/ara text -->
  <xsl:template match="str" mode="latin_ara">
    <!-- is text foreign -->
    <xsl:variable 
        name="foreign" 
        select="contains(parent::arr/@name, '_') and not(contains(parent::arr/@name, '-Latn-x-lc')) and not(contains(parent::arr/@name, '_eng')) and not(contains(parent::arr/@name, 'tur')) and not(parent::arr/@name = 'work_author')"
        />
    
    <xsl:choose>
      <!-- title -->
      <xsl:when test="starts-with(parent::arr/@name, 'work_title_') or starts-with(parent::arr/@name, 'work_subTitle_')">
        <!-- determine href based on type of resource -->
        <xsl:variable name="href">
          <xsl:apply-templates select="ancestor::doc" mode="doc_href"/>
        </xsl:variable>
        <a href="{$href}">
          <xsl:if test="$foreign">
            <xsl:attribute name="class">foreign</xsl:attribute>
          </xsl:if>
          <xsl:apply-templates/>
        </a>
      </xsl:when>
      
      <!-- author -->
      <xsl:when test="starts-with(parent::arr/@name, 'work_author')">
        <!-- determine href based on type of resource -->
        <xsl:variable name="href">
          <xsl:apply-templates select="ancestor::doc" mode="author_href"/>
        </xsl:variable>
        
        <xsl:text>Author: </xsl:text>
        
        <a href="{$href}">
          <xsl:if test="$foreign">
            <xsl:attribute name="class">foreign</xsl:attribute>
          </xsl:if>
          
          <xsl:apply-templates/>
        </a>
      </xsl:when>
      
      <!-- person search -->
      <xsl:when test="parent::arr/@name = 'name'">
        <!-- determine href based on type of resource -->
        <xsl:variable name="href">
          <xsl:apply-templates select="ancestor::doc" mode="author_href"/>
        </xsl:variable>
        <xsl:text>Person: </xsl:text>
        <a href="{$href}">
          <xsl:if test="$foreign">
            <xsl:attribute name="class">foreign</xsl:attribute>
          </xsl:if>
          <xsl:apply-templates/>
        </a>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="str[@name='ms_physical_location_institution' or @name='ms_physical_location_collection' or @name='ms_physical_location_settlement' or @name='ms_physical_location_country']">
    <a href="{$php_script}?{substring-after(@name, 'physical_location_')}={.}&amp;doctype=work">
      <xsl:apply-templates/>
    </a>
    
    <xsl:if test="@name != 'ms_physical_location_country'">
      <xsl:text>, </xsl:text>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="str[@name='ms_identifier_idno']">
    <xsl:variable name="href">
      <xsl:apply-templates select="parent::doc" mode="doc_href"/>
    </xsl:variable>
    
    <a href="{$href}">
      <xsl:apply-templates/>
    </a>
  </xsl:template>
  
  <!-- generate link to document -->
  <xsl:template match="doc" mode="doc_href">
    <xsl:variable name="id" select="str[@name='id']"/>
    <xsl:variable name="type" select="str[@name='doc_type']"/>

    <!-- use work ID for #work_id -->
    <xsl:variable name="fragment">
      <xsl:if test="$type = 'work' and contains($id, ';')">
        <xsl:value-of select="concat('#', substring-after($id, ';'))"/>
      </xsl:if>
    </xsl:variable>

    <!-- extra dir for authority files -->
    <xsl:variable name="dir">
      <xsl:if test="$type = 'auth'">
        <xsl:text>auth/</xsl:text>
      </xsl:if>
    </xsl:variable>
    
    <!-- put it all together -->
    <xsl:value-of select="concat('documents/', $dir, $id, '?', $highlight, $fragment)"/>
  </xsl:template>
  
  <!-- generate link to author -->
  <xsl:template match="doc" mode="author_href">
    <xsl:choose>
      <xsl:when test="str[@name='doc_type'] = 'work'">
        <xsl:value-of select="concat('documents/auth/', arr[@name='work_auth_author_id']/str[1])"/>
      </xsl:when>
      <!--xsl:when test="str[@name='type_of_resource'] = 'auth'">
        <xsl:value-of select="concat('documents/auth/', str[@name='id'])"/>
      </xsl:when-->
    </xsl:choose>
  </xsl:template>

  <!--/****f* hits.xsl/hits_stats
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
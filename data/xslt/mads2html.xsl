<?xml version="1.0" encoding="UTF-8"?><!-- -*- xml -*- -->
<xsl:stylesheet
    version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:php="http://php.net/xsl"
    xmlns:mads="http://www.loc.gov/mads/v2"
    xmlns:exsl="http://exslt.org/common"
    xmlns:mods="http://www.loc.gov/mods/v3"
    xsl:extension-element-prefixes="php exsl"
    exclude-result-prefixes="mads mods tei mads php exsl"
    >
  
  <!--****** xslt/mads2html.xsl
 * NAME
 * mads2html.xsl
 * SYNOPSIS
 * Stylesheet for transforming MADS (authority files) into HTML.
 * Included by tei2html.xsl
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20120710
 * SEE ALSO
 *   * xslt/mods2html_include.xsl
 *   * xslt/tei2html.xsl
 ****-->

  <xsl:include href="mods2html_include.xsl"/>
  
  <!-- number of MS per title to show by default -->
  <xsl:variable name="ms_to_show" select="number(3)"/>

  <!-- need key to group refering manuscripts by title -->
  <xsl:key 
      name="ms"
      match="doc[str[@name='doc_type'] = 'work']"
      use="arr[@name='title']/str[1]"
      />

  <xsl:template match="mads:mads">
    <xsl:param name="render"/>
    
    <xsl:variable name="authID" select="concat(mads:identifier/@type, ':', translate(mads:identifier, ' ', ''))"/>
    
    <xsl:choose>
      <!-- showing authority file title in DL list -->
      <xsl:when test="$render = 'dd'">
        <xsl:apply-templates select="mads:authority" mode="title_dd"/>
      </xsl:when>
      
      <!-- regular showing of full record -->
      <xsl:otherwise>
        <xsl:variable name="id" select="generate-id(mads:variant[1])"/>
        
        <h3>
          <xsl:apply-templates select="mads:authority" mode="title"/>
        </h3>
        
        <p>
          <xsl:if test="$recent_search != ''">
            <a href="{$recent_search}">Back to most recent search</a>.
            <xsl:text> </xsl:text>
          </xsl:if>
          
          <a href="{$search_url}">Start new search.</a>
        </p>
        
        <div class="rel">
          <div class="list_container">
            <dl>
              <xsl:apply-templates select="mads:identifier"/>
              <xsl:apply-templates select="mads:authority"/>
              
              <xsl:if test="mads:extension/tei:note">
                <dt>Biographical notes</dt>
                <dd>
                  <!-- need TEI formatting for notes -->
                  <xsl:apply-templates select="mads:extension/tei:note"/>
                </dd>
              </xsl:if>
              
              <!-- bibliography -->
              <xsl:if test="mads:extension/tei:note/descendant::tei:ref">
                <dt>Bibliography</dt>
                <xsl:apply-templates select="mads:extension/tei:note/descendant::tei:ref" mode="bib_list">
                  <xsl:with-param name="key" select="$authID"/>
                </xsl:apply-templates>
              </xsl:if>
              
              <!-- variant names -->
              <xsl:if test="mads:variant[mads:name/mads:namePart != '']">
                <dt>
                  <a id="{$id}" class="auth_dt" href="#">Show variants</a>
                </dt>
                <dd>&#160;</dd>
                <dd class="{$id} following">
                  <ul>
                    <xsl:apply-templates select="mads:variant"/>
                  </ul>
                </dd>
              </xsl:if>
              
              <!-- related manuscripts -->
              <!-- author -->
              <xsl:apply-templates select="/mads:mads/response/result">
                <xsl:with-param name="authID" select="$authID"/>
                <xsl:with-param name="field">work_auth_author_id</xsl:with-param>
                <xsl:with-param name="title">Manuscripts by this author</xsl:with-param>
              </xsl:apply-templates>
              
              <!-- patron -->
              <xsl:apply-templates select="/mads:mads/response/result">
                <xsl:with-param name="authID" select="$authID"/>
                <xsl:with-param name="field">work_auth_patron_id</xsl:with-param>
                <xsl:with-param name="title">Manuscripts patronised by this person</xsl:with-param>
              </xsl:apply-templates>
              
              <!-- dedication -->
              <xsl:apply-templates select="/mads:mads/response/result">
                <xsl:with-param name="authID" select="$authID"/>
                <xsl:with-param name="field">work_auth_dedication_id</xsl:with-param>
                <xsl:with-param name="title">Manuscripts dedicated to this person</xsl:with-param>
              </xsl:apply-templates>
              
              <!-- referring authority files -->
              <xsl:if test="/mads:mads/response/result/doc/str[@name='doc_type'] = 'auth'">
                <dt>Referring authors</dt>
                <dd>
                  <ul>
                    <xsl:apply-templates select="/mads:mads/response/result/doc[str[@name='doc_type'] = 'auth']" mode="auth"/>
                  </ul>
                </dd>
              </xsl:if>
              
            </dl>
          </div>
        </div>
        <!--xsl:copy-of select="/"/-->
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- title -->
  <xsl:template match="mads:authority" mode="title">
    <xsl:apply-templates mode="title"/>
  </xsl:template>
  
  <xsl:template match="mads:authority" mode="title_dd">
    <dd>
      <xsl:apply-templates select="mads:topic" mode="title"/>
      <xsl:text> </xsl:text>
      <xsl:apply-templates select="mads:*[not(self::mads:topic)]" mode="title"/>
    </dd>
  </xsl:template>
  
  <xsl:template match="mads:topic" mode="title">
    <a href="{$search_url}?doctype=work&amp;subject_topic={.}">
      <xsl:apply-templates/>
    </a>
  </xsl:template>
  
  <xsl:template match="mads:genre|mads:title" mode="title">
    <xsl:text> (</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>)</xsl:text>
  </xsl:template>
  
  <xsl:template match="mads:name" mode="title">
    <xsl:apply-templates select="mads:namePart"/>
  </xsl:template>

  <!-- ID of authority file -->
  <xsl:template match="mads:identifier">
    <dt>
      <xsl:text>Identifier</xsl:text>
      <xsl:apply-templates select="@type"/>
    </dt>
    <dd>
      <xsl:apply-templates/>
    </dd>
  </xsl:template>
  
  <xsl:template match="mads:identifier/@type">
    <xsl:text> (</xsl:text>
    <xsl:value-of select="."/>
    <xsl:text>)</xsl:text>
  </xsl:template>

  <!-- primary name/subject heading -->
  <xsl:template match="mads:authority">
    <dt>Heading</dt>
    <dd>
      <xsl:apply-templates select="mads:*"/>
    </dd>
  </xsl:template>
  
  <!-- variant names/headings -->
  <xsl:template match="mads:variant">
    <li>
      <xsl:apply-templates/>
    </li>
  </xsl:template>
  
  <!-- source notes -->
  <xsl:template match="mads:note[@type='source']">
    <li>
      <xsl:apply-templates/>
    </li>
  </xsl:template>
  
  <!-- names -->
  <xsl:template match="mads:namePart">
    <!-- have foreign name? -->
    <xsl:variable name="foreign" select=". != '' and not(@type = 'date') and translate(., 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789?', '') = ."/>

    <!-- add comma? -->
    <xsl:choose>
      <!-- name is term of address -->
      <xsl:when test="@type = 'termsOfAddress' and . != ''">
        <xsl:text>, </xsl:text>
      </xsl:when>
      <!-- namePart is date and first namePart doesn't contain year -->
      <xsl:when test="@type = 'date' and . != '' and not(contains(translate(preceding-sibling::mads:namePart[not(@type)], '1234567890', '__________'), '___'))">
        <xsl:text>, </xsl:text>
      </xsl:when>
    </xsl:choose>
    
    <xsl:choose>
      <xsl:when test="$foreign">
        <span class="foreign">
          <xsl:apply-templates/>
        </span>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- refering documents -->
  <xsl:template match="doc" mode="first">
    <dt>
      <xsl:apply-templates select="arr[@name='title']/str[1]"/>
    </dt>
    
    <!-- work notes -->
    <xsl:apply-templates select="arr[@name='work_work_html_note']/str"/>
    
    <!-- list of manuscripts -->
    <dd>
      <ul>
        <xsl:apply-templates select="key('ms', arr[@name='title']/str[1])" mode="all"/>
      </ul>
    </dd>
  </xsl:template>

  <xsl:template match="doc" mode="all">
    <!-- first MS after top X -->
    <xsl:if test="position() = $ms_to_show + 1">
      <!-- find out how many in this list -->
      <xsl:variable name="total" select="count(key('ms', arr[@name='title']/str[1]))"/>
      
      <li>
        <a href="#" class="show_following">
          <xsl:value-of select="concat('Show ', $total - $ms_to_show, ' more')"/>
        </a>
      </li>
    </xsl:if>
    
    <li>
      <xsl:if test="position() &gt; $ms_to_show">
        <xsl:attribute name="class">following</xsl:attribute>
      </xsl:if>
      
      <a href="{$path}documents/{str[@name='id']}">
        <xsl:apply-templates select="str[@name='id']" mode="work"/>
      </a>
    </li>
  </xsl:template>
  
  <!-- remove work ID from MS ID -->
  <xsl:template match="str[@name='id']" mode="work">
    <xsl:value-of select="substring-before(., ';')"/>
  </xsl:template>
  
  <!-- referring authority file -->
  <xsl:template match="doc" mode="auth">
    <!-- local: might be missing -->
    <xsl:variable name="local">
      <xsl:if test="not(starts-with(str[@name='id'], 'lccn') or starts-with(str[@name='id'], 'local'))">
        <xsl:text>local:</xsl:text>
      </xsl:if>
    </xsl:variable>
    
    <li>
      <a href="./{$local}{str[@name='id']}">
        <xsl:apply-templates select="str[@name='auth_title']"/>
      </a>
    </li>
  </xsl:template>
  
  <xsl:template match="arr[@name='work_work_html_note']/str">
    <xsl:variable name="class">
      <xsl:text>work_note </xsl:text>
      <xsl:if test="preceding-sibling::str">
        <xsl:text>following</xsl:text>
      </xsl:if>
    </xsl:variable>
    
    <dd class="{$class}">
      <xsl:value-of select="." disable-output-escaping="yes"/>
      
      <xsl:if test="not(preceding-sibling::str) and following-sibling::str">
        <xsl:text> </xsl:text>
        <a href="#" class="show_next" title="see more from work notes">Show more</a>
      </xsl:if>
    </dd>
  </xsl:template>

  <!-- manuscripts related to person -->
  <xsl:template match="result">
    <xsl:param name="authID"/>
    <xsl:param name="field"/>
    <xsl:param name="title"/>
    
    <!-- any manuscripts by this author -->
    <xsl:if test="doc[arr[@name = $field]/str = $authID]">
      <dt>
        <xsl:value-of select="$title"/>
      </dt>
      <dd>
        <dl>
          <!-- show MS (works really) which are related to this person -->
          <xsl:apply-templates 
              select="doc[arr[@name = $field]/str = $authID][generate-id() = generate-id(key('ms', arr[@name='title']/str[1])[1])]"
              mode="first"
              >
            <!-- sort by title -->
            <xsl:sort select="arr[@name='title']/str[1]"/>
          </xsl:apply-templates>
        </dl>
      </dd>
    </xsl:if>
  </xsl:template>

  
</xsl:stylesheet>

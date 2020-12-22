<?xml version="1.0" encoding="UTF-8"?><!-- -*- xml -*- -->
<xsl:stylesheet
    version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:php="http://php.net/xsl"
    xmlns:exsl="http://exslt.org/common"
    xmlns:mads="http://www.loc.gov/mads/v2"
    xmlns:mods="http://www.loc.gov/mods/v3"
    extension-element-prefixes="php exsl"
    xmlns:data="urn:data"
    exclude-result-prefixes="mods mads php tei exsl data"
    >
  
  <!--****** xslt/templates.xsl
 * NAME
 * templates.xsl
 * SYNOPSIS
 * Templates used by all the XSLT scripts that generate HTML. The basic page layout and common functions are in this document.
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20120710
 ****-->
  
  <xsl:output
      method="xml"
      indent="yes"
      encoding="UTF-8"
      omit-xml-declaration="yes"
      />
  
  <xsl:param name="title">Islamisation of Anatolia</xsl:param>
  <xsl:param name="path"/>
  <xsl:param name="user"/>
  <xsl:param name="message"/>
  <xsl:param name="messageClass"/>
  
  <xsl:variable name="ltr">&#8206;</xsl:variable>
  
  <xsl:template match="/">
    <xsl:call-template name="body"/>
  </xsl:template>
  
  <xsl:template name="body">
    <!--<div id="content">-->
      <xsl:call-template name="header"/>
      <xsl:call-template name="message"/>
      <article>
        <div class="page type-page status-publish hentry article">
          <xsl:apply-templates/>
        </div>
      </article>
      <xsl:call-template name="footer"/>
    <!--</div> commented out to remove double use of div with id of content -->
  </xsl:template>
  
  <xsl:template name="header">
    <xsl:call-template name="user"/>
  </xsl:template>
  
  <xsl:template name="user">
    <p class="login">
      <xsl:choose>
        <xsl:when test="$user">
          <xsl:text>You are logged in as </xsl:text>
          <xsl:value-of select="$user"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>You are not </xsl:text>
          <a href="{$path}admin/">logged</a> 
          <xsl:text> in</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </p>
  </xsl:template>
  
  <xsl:template name="footer"/>
  
  <!-- have message to display -->
  <xsl:template name="message">
    <xsl:if test="$message">
      <p>
        <xsl:if test="$messageClass">
          <xsl:attribute name="class">
            <xsl:value-of select="$messageClass"/>
          </xsl:attribute>
        </xsl:if>
        <xsl:call-template name="message_split">
          <xsl:with-param name="text" select="$message"/>
        </xsl:call-template>
      </p>
    </xsl:if>
  </xsl:template>

  <!-- templates for formatting bib refs in templates.xsl -->
  <xsl:template match="tei:ref" mode="bib_list">
    <xsl:param name="key"/>
    
    <dd class="bib_list" id="{concat(@target, '_', $key)}">
      <xsl:apply-templates select=".">
        <xsl:with-param name="render">full</xsl:with-param>
      </xsl:apply-templates>
    </dd>
  </xsl:template>

  <!-- refs to books -->
  <xsl:template match="tei:ref">
    <xsl:param name="render">short</xsl:param>
    <xsl:variable name="target" select="@target"/>
    
    <xsl:variable name="author">
      <xsl:choose>
        <xsl:when test="ancestor::tei:msItem/tei:author">
          <xsl:value-of select="ancestor::tei:msItem/tei:author/@key"/>
        </xsl:when>
        <xsl:when test="ancestor::mads:mads">
          <xsl:value-of select="concat(ancestor::mads:mads/mads:identifier/@type, ':', translate(ancestor::mads:mads/mads:identifier, ' ', ''))"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:choose>
      <!-- short link to bibliography for page -->
      <xsl:when test="$render = 'short' and exsl:node-set($external_docs)/root/mods:mods/@id = $target">
        <a href="#{$target}_{$author}">
          <xsl:call-template name="resolve_uris">
            <xsl:with-param name="render" select="$render"/>
            <xsl:with-param name="uris" select="$target"/>
          </xsl:call-template>
        </a>
      </xsl:when>
      <!-- full render, so in bibliography context  -->
      <xsl:when test="$render = 'full' and exsl:node-set($external_docs)/root/mods:mods/@id = $target">
        <xsl:call-template name="resolve_uris">
          <xsl:with-param name="render" select="$render"/>
          <xsl:with-param name="uris" select="$target"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test=". != ''">
        <xsl:apply-templates/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>Bibliographic reference</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- names of places -->
  <xsl:template match="tei:name[@type='place' and @key != '']">
    <!-- get authorised name of place -->
    <xsl:variable name="key">
      <xsl:value-of select="exsl:node-set($external_docs)/root/mads:mads[@id = current()/@key]/mads:authority/mads:geographic"/>
    </xsl:variable>
    
    <xsl:choose>
      <xsl:when test="$key != ''">
        <a href="{$search_url}?doctype=work&amp;field=places&amp;q={$key}">
          <xsl:apply-templates/>
        </a>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- split message text on | using <br/>s -->
  <xsl:template name="message_split">
    <xsl:param name="text"/>
    <xsl:choose>
      <xsl:when test="contains($text, '|')">
        <xsl:value-of select="substring-before($text, '|')"/>
        <br/>
        <xsl:call-template name="message_split">
          <xsl:with-param name="text" select="substring-after($text, '|')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$text"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- convert language code to language -->
  <xsl:template name="resolve_lang">
    <xsl:param name="lang"/>
    <xsl:apply-templates select="exsl:node-set($languages)/data:languages/data:item[@value = $lang]"/>
  </xsl:template>

  <!-- convert script code to script -->
  <xsl:template name="resolve_script">
    <xsl:param name="script"/>
    <xsl:apply-templates select="exsl:node-set($scripts)/data:scripts/data:item[@value = $script]"/>
  </xsl:template>

  <!-- convert calendar to calendar code -->
  <xsl:template name="resolve_calendar">
    <xsl:param name="calendar"/>
    <xsl:apply-templates select="exsl:node-set($calendars)/data:calendars/data:item[@value = $calendar]"/>
  </xsl:template>
  
</xsl:stylesheet>

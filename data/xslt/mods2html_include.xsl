<?xml version="1.0" encoding="UTF-8"?><!-- -*- xml -*- -->
<xsl:stylesheet
    version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:mads="http://www.loc.gov/mads/v2"
    xmlns:mods="http://www.loc.gov/mods/v3"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="str"
    >
  
  <!--****** xslt/mods2html_include.xsl
 * NAME
 * mods2html_include.xsl
 * SYNOPSIS
 * This XSLT script is included by mods2html and tei2html. It contains the MODs to HTML templates.
 * mods:mods has mode=html_bib, so that mods:mods without a mode can be handled differently.
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20120710
 ****-->

  <!-- book -->
  <xsl:template match="mods:mods[mods:genre[@authority='local']='book']" mode="html_bib">
    <xsl:param name="render">full</xsl:param>
    <xsl:param name="pages"/>
    
    <xsl:if test="$render = 'full'">
      <!-- author/s -->
      <xsl:apply-templates select="mods:name[mods:role/mods:roleTerm='aut']" mode="html"/>
      
      <!-- if no author, then editor/translator goes first -->
      <xsl:apply-templates 
          select="mods:name[mods:role/mods:roleTerm='edt'][parent::mods:mods[not(mods:name[mods:role/mods:roleTerm='aut'])]]"
          mode="html"
          />
      <xsl:apply-templates 
          select="mods:name[mods:role/mods:roleTerm='trl'][parent::mods:mods[not(mods:name[mods:role/mods:roleTerm='aut'])]]"
          mode="html"
          />
    </xsl:if>
    
    <!-- title -->
    <xsl:apply-templates select="mods:titleInfo" mode="html_italicise"/>
    
    <xsl:if test="$render = 'full'">
      <!-- if author, then editor/translator goes after title -->
      <xsl:apply-templates 
          select="mods:name[mods:role/mods:roleTerm='edt'][parent::mods:mods/mods:name[mods:role/mods:roleTerm='aut']]"
          mode="html"
          />
      <xsl:apply-templates 
          select="mods:name[mods:role/mods:roleTerm='trl'][parent::mods:mods/mods:name[mods:role/mods:roleTerm='aut']]"
          mode="html"
          />
      
      <!-- publication info -->
      <xsl:apply-templates select="mods:originInfo" mode="html"/>
      
      <!-- pages -->
      <xsl:call-template name="pages">
        <xsl:with-param name="pages" select="$pages"/>
      </xsl:call-template>
    </xsl:if>

    <xsl:text>.</xsl:text>
    
    <xsl:apply-templates select="mods:note"/>
  </xsl:template>

  <!-- book section -->
  <xsl:template match="mods:mods[mods:genre[@authority='local']='bookSection']" mode="html_bib">
    <xsl:param name="render">full</xsl:param>
    <xsl:param name="pages"/>
    
    <xsl:if test="$render = 'full'">
      <!-- author/s -->
      <xsl:apply-templates select="mods:name[mods:role/mods:roleTerm='aut']" mode="html"/>
      
      <!-- if no author, then editor/translator goes first -->
      <xsl:apply-templates 
          select="descendant::mods:name[mods:role/mods:roleTerm='edt'][ancestor::mods:mods[not(mods:name[mods:role/mods:roleTerm='aut'])]]"
          mode="html"
          />
      <xsl:apply-templates 
          select="descendant::mods:name[mods:role/mods:roleTerm='trl'][ancestor::mods:mods[not(mods:name[mods:role/mods:roleTerm='aut'])]]"
          mode="html"
          />
    </xsl:if>
    
    <!-- title -->
    <xsl:apply-templates select="mods:titleInfo" mode="html_quote"/>
    
    <xsl:if test="mods:relatedItem/mods:titleInfo/mods:title != ''">
      <xsl:text> In </xsl:text>
      <xsl:apply-templates select="mods:relatedItem/mods:titleInfo" mode="html_italicise"/>
    </xsl:if>
    
    <xsl:if test="$render = 'full'">
      <!-- if author, then editor/translator goes after title -->
      <xsl:apply-templates 
          select="descendant::mods:name[mods:role/mods:roleTerm='edt'][ancestor::mods:mods/mods:name[mods:role/mods:roleTerm='aut']]"
          mode="html"
          />
      <xsl:apply-templates 
          select="descendant::mods:name[mods:role/mods:roleTerm='trl'][ancestor::mods:mods/mods:name[mods:role/mods:roleTerm='aut']]"
          mode="html"
          />
      
      <!-- publication info -->
      <xsl:apply-templates select="descendant::mods:originInfo" mode="html"/>

      <!-- pages -->
      <xsl:variable name="p">
        <xsl:choose>
          <xsl:when test="$pages != ''">
            <xsl:value-of select="$pages"/>
          </xsl:when>
          <xsl:when test="mods:relatedItem/mods:part/mods:extent[@unit='pages'][mods:start and mods:end]">
            <xsl:value-of select="concat(mods:relatedItem/mods:part/mods:extent[@unit='pages']/mods:start, '-', mods:relatedItem/mods:part/mods:extent[@unit='pages']/mods:end)"/>
          </xsl:when>
        </xsl:choose>
      </xsl:variable>
      <xsl:call-template name="pages">
        <xsl:with-param name="pages" select="$p"/>
      </xsl:call-template>
    </xsl:if>
    
    <xsl:text>.</xsl:text>
    
    <xsl:apply-templates select="mods:note"/>
  </xsl:template>
  
  <!-- journal article -->
  <xsl:template match="mods:mods[mods:genre[@authority='local'][. = 'journalArticle' or . = 'encyclopediaArticle' or . = 'conferencePaper' or . = 'newspaperArticle']]" mode="html_bib">
    <xsl:param name="render">full</xsl:param>
    <xsl:param name="pages"/>
    
    <xsl:if test="$render = 'full'">
      <!-- author/s -->
      <xsl:apply-templates select="mods:name[mods:role/mods:roleTerm='aut']" mode="html"/>
      
      <!-- if no author, then editor/translator goes first -->
      <xsl:apply-templates 
          select="mods:name[mods:role/mods:roleTerm='edt'][parent::mods:mods[not(mods:name[mods:role/mods:roleTerm='aut'])]]"
          mode="html"
          />
      <xsl:apply-templates 
          select="mods:name[mods:role/mods:roleTerm='trl'][parent::mods:mods[not(mods:name[mods:role/mods:roleTerm='aut'])]]"
          mode="html"
          />
    </xsl:if>
    
    <!-- article title -->
    <xsl:apply-templates select="mods:titleInfo" mode="html_quote"/>
    
    <xsl:if test="$render = 'full'">
      <!-- journal title -->
      <xsl:apply-templates select="self::mods:mods[mods:genre[@authority='local'][. = 'journalArticle' or . = 'encyclopediaArticle' or . = 'conferencePaper']]/mods:relatedItem[@type='host']/mods:titleInfo" mode="html_italicise"/>
      
      <!-- if author, then editor/translator goes after title -->
      <xsl:apply-templates 
          select="mods:name[mods:role/mods:roleTerm='edt'][parent::mods:mods/mods:name[mods:role/mods:roleTerm='aut']]"
          mode="html"
          />
      <xsl:apply-templates 
          select="mods:name[mods:role/mods:roleTerm='trl'][parent::mods:mods/mods:name[mods:role/mods:roleTerm='aut']]"
          mode="html"
          />
      
      <!-- publication info - volume no. issue  -->
      <xsl:apply-templates select="mods:relatedItem[@type='host']/mods:part/mods:detail" mode="html"/>

      <!-- publication info -->
      <xsl:apply-templates select="descendant::mods:originInfo" mode="html"/>
      
      <!-- publication info - volume no. issue  -->
      <xsl:apply-templates select="mods:relatedItem[@type='host']/mods:part/mods:extent" mode="html"/>
      
      <!-- location -->
      <xsl:apply-templates select="mods:location[mods:url]" mode="html"/>

      <!-- pages -->
      <xsl:call-template name="pages">
        <xsl:with-param name="pages" select="$pages"/>
      </xsl:call-template>
    </xsl:if>
    
    <xsl:text>.</xsl:text>
    
    <xsl:apply-templates select="mods:note"/>
  </xsl:template>

  <!-- thesis -->
  <xsl:template match="mods:mods[mods:genre[@authority='local'][. = 'thesis']]" mode="html_bib">
    <xsl:param name="render">full</xsl:param>
    <xsl:param name="pages"/>
    
    <xsl:if test="$render = 'full'">
      <!-- author/s -->
      <xsl:apply-templates select="mods:name[mods:role/mods:roleTerm='aut']" mode="html"/>
    </xsl:if>
    
    <!-- article title -->
    <xsl:apply-templates select="mods:titleInfo" mode="html_quote"/>
    
    <xsl:if test="$render = 'full'">
      <!-- thesis type -->
      <xsl:apply-templates select="mods:genre[not(@authority)][. != '']"/>
      <!-- publisher -->
      <xsl:apply-templates select="mods:originInfo" mode="html"/>

      <!-- pages -->
      <xsl:call-template name="pages">
        <xsl:with-param name="pages" select="$pages"/>
      </xsl:call-template>
    </xsl:if>
    
    <xsl:text>.</xsl:text>
    
    <xsl:apply-templates select="mods:note"/>
  </xsl:template>
  
  <!-- author/s -->
  <xsl:template match="mods:name[mods:role/mods:roleTerm='aut']" mode="html">
    <!-- output name -->
    <xsl:apply-templates select="." mode="html_name"/>
    
    <!-- last - . at end of names -->
    <xsl:if test="not(following-sibling::mods:name[mods:role/mods:roleTerm='aut'])">
      <xsl:text>. </xsl:text>
    </xsl:if>
  </xsl:template>
  
  <!-- editor/s and translator/s -->
  <xsl:template match="mods:name[mods:role/mods:roleTerm[.='edt' or .='trl']]" mode="html">
    <!-- remember role term -->
    <xsl:variable name="roleTerm" select="string(mods:role/mods:roleTerm)"/>
    
    <!-- first name and handle roleTerm before, when there is an author -->
    <xsl:if test="not(preceding-sibling::mods:name[mods:role/mods:roleTerm=$roleTerm]) and parent::mods:mods/mods:name/mods:role/mods:roleTerm='aut'">
      <xsl:choose>
        <xsl:when test="$roleTerm = 'edt'">
          <xsl:text> Edited by </xsl:text>
        </xsl:when>
        <xsl:when test="$roleTerm = 'trl'">
          <xsl:text> Translated by </xsl:text>
        </xsl:when>
      </xsl:choose>
    </xsl:if>
    
    <!-- output name -->
    <xsl:apply-templates select="." mode="html_name">
      <xsl:with-param 
          name="switchFirstName"
          select="boolean(parent::mods:mods/mods:name/mods:role/mods:roleTerm='aut')"
          />
    </xsl:apply-templates>
    
    <!-- last name and handle roleTerm afterwards, when there is no author -->
    <xsl:if test="not(following-sibling::mods:name[mods:role/mods:roleTerm=$roleTerm]) and not(parent::mods:mods/mods:name/mods:role/mods:roleTerm='aut')">
      <xsl:choose>
        <xsl:when test="$roleTerm = 'edt'">
          <xsl:text>, ed</xsl:text>
        </xsl:when>
        <xsl:when test="$roleTerm = 'trl'">
          <xsl:text>, trans</xsl:text>
        </xsl:when>
      </xsl:choose>
    </xsl:if>
    
    <!-- last name - . -->
    <xsl:if test="not(following-sibling::mods:name[mods:role/mods:roleTerm=$roleTerm])">
      <xsl:text>. </xsl:text>
    </xsl:if>
  </xsl:template>
  
  <!-- output name -->
  <xsl:template match="mods:name" mode="html_name">
    <xsl:param name="switchFirstName" select="false()"/>
    
    <xsl:variable
        name="roleTerm"
        select="string(mods:role/mods:roleTerm)"
        />
    
    <xsl:choose>
      <!-- first - family, given -->
      <xsl:when test="not($switchFirstName) and not(preceding-sibling::mods:name[mods:role/mods:roleTerm=$roleTerm])">
        <xsl:apply-templates select="mods:namePart[@type='family']" mode="html"/>
        <xsl:text>, </xsl:text>
        <xsl:apply-templates select="mods:namePart[@type='given']" mode="html"/>
      </xsl:when>
      <!-- first - given family -->
      <xsl:when test="$switchFirstName and not(preceding-sibling::mods:name[mods:role/mods:roleTerm=$roleTerm])">
        <xsl:apply-templates select="mods:namePart[@type='family']" mode="html"/>
        <xsl:text>, </xsl:text>
        <xsl:apply-templates select="mods:namePart[@type='given']" mode="html"/>
      </xsl:when>
      <!-- middle - , given family-->
      <xsl:when test="following-sibling::mods:name[mods:role/mods:roleTerm=$roleTerm]">
        <xsl:text>, </xsl:text>
        <xsl:apply-templates select="mods:namePart[@type='given']" mode="html"/>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="mods:namePart[@type='family']" mode="html"/>
      </xsl:when>
      <!-- last - and given family-->
      <xsl:otherwise>
        <xsl:text> and </xsl:text>
        <xsl:apply-templates select="mods:namePart[@type='given']" mode="html"/>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="mods:namePart[@type='family']" mode="html"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- title in italics -->
  <xsl:template match="mods:title" mode="html_italicise">
    <em>
      <xsl:apply-templates select="." mode="html"/>
    </em>
    
    <!-- add space unless newspaper title -->
    <xsl:if test="not(ancestor::mods:mods[mods:genre[@authority='local'][. = 'newspaperArticle']])">
      <xsl:text> </xsl:text>
    </xsl:if>
  </xsl:template>
  
  <!-- title in quotes -->
  <xsl:template match="mods:title" mode="html_quote">
    <xsl:text>&#34;</xsl:text>
    <xsl:apply-templates select="." mode="html"/>
    <xsl:text>&#34; </xsl:text>
  </xsl:template>
  
  <xsl:template match="mods:title" mode="html">
    <!-- get last character of title, and make empty if it is end punctuation -->
    <xsl:variable name="last" select="translate(substring(., string-length(.)), '.?!', '')"/>
    <xsl:apply-templates/>
    
    <!-- have removed punctuation, so put in . if not newspaper title -->
    <xsl:if test="$last !=  '' and not(ancestor::mods:mods[mods:genre[@authority='local'][. = 'newspaperArticle']])">
      <xsl:text>.</xsl:text>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="mods:originInfo" mode="html">
    <!-- place of publication -->
    <xsl:apply-templates select="mods:place" mode="html"/>

    <!-- publisher -->
    <xsl:apply-templates select="mods:publisher" mode="html"/>
    
    <!-- newspaper title -->
    <xsl:apply-templates select="ancestor::mods:mods[mods:genre[@authority='local'][. = 'newspaperArticle']]/mods:relatedItem[@type='host']/mods:titleInfo" mode="html_italicise"/>
    
    <!-- date or no date -->
    <xsl:apply-templates select="mods:copyrightDate | mods:dateCreated | mods:dateIssued" mode="html"/>
    <xsl:if test="not(mods:copyrightDate | mods:dateCreated | mods:dateIssued)">
      <xsl:text>, [n.d.]</xsl:text>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="mods:place" mode="html">
    <xsl:apply-templates select="mods:placeTerm" mode="html"/>
  </xsl:template>
  
  <xsl:template match="mods:placeTerm" mode="html">
    <!-- space before each placeTerm -->
    <xsl:if test="preceding-sibling::mods:placeTerm">
      <xsl:text> </xsl:text>
    </xsl:if>
    
    <!-- placeTerm -->
    <xsl:apply-templates mode="html"/>
    
    <!-- : after last placeTerm -->
    <xsl:if test="not(following-sibling::mods:placeTerm)">
      <xsl:text>: </xsl:text>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="mods:publisher" mode="html">
    <xsl:apply-templates mode="html"/>
    <xsl:text>, </xsl:text>
  </xsl:template>
  
  <xsl:template match="mods:copyrightDate | mods:dateCreated | mods:dateIssued" mode="html">
    <xsl:text> </xsl:text>
    <xsl:apply-templates mode="html"/>
  </xsl:template>
  
  <!-- part - journal details -->
  <xsl:template match="mods:part" mode="html">
    <xsl:apply-templates select="mods:detail[@type='volume']" mode="html"/>
    <xsl:apply-templates select="mods:detail[@type='issue']" mode="html"/>
    <xsl:apply-templates select="mods:extent[@unit='pages']" mode="html"/>
  </xsl:template>
  
  <xsl:template match="mods:detail[@type='volume']" mode="html">
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="mods:number" mode="html"/>
  </xsl:template>
  
  <xsl:template match="mods:detail[@type='issue']" mode="html">
    <xsl:text>, no. </xsl:text>
    <xsl:apply-templates select="mods:number" mode="html"/>
  </xsl:template>
  
  <xsl:template match="mods:extent[@unit='pages'][mods:start and mods:end]" mode="html">
    <xsl:text>: </xsl:text>
    <xsl:apply-templates select="mods:start" mode="html"/>
    <xsl:text>-</xsl:text>
    <xsl:apply-templates select="mods:end" mode="html"/>
  </xsl:template>
  
  <xsl:template match="mods:extent" mode="html"/>
  
  <xsl:template match="mods:location[mods:url]" mode="html">
    <xsl:text> </xsl:text>
    <a href="{mods:url}" target="_blank">
      <!-- show domain -->
      <xsl:value-of select="substring-before(substring-after(mods:url, '://'), '/')"/>
    </a>
  </xsl:template>
  
  <!-- type of thesis -->
  <xsl:template match="mods:genre[not(@authority)]">
    <xsl:apply-templates/>
    <xsl:text>, </xsl:text>
  </xsl:template>
  
  <!-- pages -->
  <xsl:template name="pages">
    <xsl:param name="pages"/>
    
    <xsl:if test="$pages != ''">
      <xsl:value-of select="concat(', ', $pages)"/>
    </xsl:if>
  </xsl:template>
  
  <!-- notes (extra) -->
  <xsl:template match="mods:note[. != '']">
    <xsl:text> (</xsl:text>
    <xsl:choose>
      <!-- note with document ID -->
      <xsl:when test="contains(., '_')">
        <xsl:call-template name="match_ids">
          <xsl:with-param name="text" select="."/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>)</xsl:text>
  </xsl:template>
  
  <!-- match document IDs and make them into links -->
  <xsl:template name="match_ids">
    <xsl:param name="text"/>
    
    <xsl:for-each select="str:tokenize($text, ' ')">
      <xsl:choose>
        <xsl:when test="contains(., '_')">
          <a href="{.}">
            <xsl:value-of select="."/>
          </a>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="."/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:text> </xsl:text>
    </xsl:for-each>
  </xsl:template>
  
</xsl:stylesheet>

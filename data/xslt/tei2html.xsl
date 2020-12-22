<?xml version="1.0" encoding="UTF-8"?><!-- -*- xml -*- -->
<xsl:stylesheet
    version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:php="http://php.net/xsl"
    xmlns:mads="http://www.loc.gov/mads/v2"
    xmlns:mods="http://www.loc.gov/mods/v3"
    xmlns:exsl="http://exslt.org/common"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="php exsl str"
    xmlns:data="urn:data"
    exclude-result-prefixes="mods mads php tei data"
    >
  
  <xsl:output omit-xml-declaration="yes" indent="yes"/>
  
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
 *   * xslt/params.xsl
 *   * xslt/mods2html_include.xsl
 *   * xslt/external_uris.xsl
 * NOTES
 * The Fihrist manual (http://www.fihrist.org.uk/manual/) was used to understand how to display the TEI. The numbers in [square brackets] are chapter numbers from the manual.
 * PHP functions are called from several templates here. These are for getting authority files (from remote sites or locally stored copies) and converting URNs to URLs for these authority files.
 ****-->

  <xsl:include href="external_uris.xsl"/>
  <xsl:include href="params.xsl"/>
  <xsl:include href="templates.xsl"/>
  <xsl:include href="mads2html.xsl"/>
  <xsl:include href="bibliography.xsl"/>
  
  <xsl:template match="tei:TEI">
    <xsl:apply-templates select="tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msContents/tei:msItem[1]/tei:title[. != ''][1]" mode="heading"/>
    
    <p>
      <xsl:if test="$recent_search != ''">
        <a href="{$recent_search}">Back to most recent search</a>.
        <xsl:text> </xsl:text>
      </xsl:if>
      
      <a href="{$search_url}">Start new search.</a>
      <xsl:text> </xsl:text>
      <a href="{$documentName}.xml">Download as XML</a>
    </p>

    <xsl:apply-templates select="tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc" mode="list"/>
    
    <!--xsl:copy-of select="/"/-->
  </xsl:template>
  
  <xsl:template match="tei:title" mode="heading">
    <h2>
      <xsl:apply-templates/>
    </h2>
  </xsl:template>

  <!-- main lists -->
  <xsl:template match="tei:msDesc" mode="list">
    <div class="rel">
      <div class="list_container">
        <h3>Summary View</h3>
        <dl>
          <xsl:apply-templates select="tei:msIdentifier"/>
          <xsl:apply-templates select="tei:summary[. != '']"/>
        </dl>

        <xsl:apply-templates select="tei:msContents" mode="list"/>
        
        <xsl:apply-templates select="tei:physDesc" mode="list"/>
        
        <xsl:apply-templates select="tei:history" mode="list"/>
      </div>
    </div>
  </xsl:template>
  
  <xsl:template match="tei:msContents" mode="list">
    <h3>Contents</h3>
    <dl id="accordion">
      <xsl:apply-templates select="tei:msItem"/>
    </dl>
  </xsl:template>
  
  <xsl:template match="tei:physDesc" mode="list">
    <xsl:if test="descendant::tei:*[not(tei:*)][not(ancestor-or-self::tei:*/@corresp)]">
      <h3>Physical Description</h3>
      <dl>
        <xsl:apply-templates select="tei:objectDesc" mode="physdesc"/>
        <xsl:apply-templates select="tei:bindingDesc" mode="binding"/>
        <xsl:apply-templates select="tei:decoDesc" mode="decoration"/>
        <xsl:apply-templates select="tei:additions" mode="additions"/>
        <xsl:apply-templates select="tei:handDesc" mode="hand"/>
        <xsl:apply-templates select="tei:sealDesc" mode="seal"/>
      </dl>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="tei:history" mode="list">
    <xsl:if test="descendant::tei:*[not(tei:*)][not(ancestor-or-self::tei:*/@corresp)]">
      <h3>History</h3>
      <dl>
        <xsl:apply-templates select="." mode="history"/>
        <xsl:apply-templates select="." mode="info"/>
        <!--xsl:apply-templates select="tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc" mode="bib"/-->
      </dl>
    </xsl:if>
  </xsl:template>

  <!-- Summary view -->
  <xsl:template match="tei:msIdentifier">
    <xsl:apply-templates select="tei:country[. != '']"/>
    <xsl:apply-templates select="tei:settlement[. != '']"/>
    <xsl:apply-templates select="tei:institution[. != '']"/>
    <xsl:apply-templates select="tei:repository[. != '']"/>
    <xsl:apply-templates select="tei:collection[. != '']"/>
    <xsl:apply-templates select="tei:idno[. != '']"/>
  </xsl:template>
  
  <xsl:template match="tei:country">
    <dt class="float">Country</dt>
    <dd class="float">
      <a href="{$search_url}?doctype=ms&amp;country={.}">
        <xsl:apply-templates/>
      </a>
    </dd>
  </xsl:template>
  
  <xsl:template match="tei:settlement">
    <dt class="float">City</dt>
    <dd class="float">
      <a href="{$search_url}?doctype=ms&amp;settlement={.}">
        <xsl:apply-templates/>
      </a>
    </dd>
  </xsl:template>

  <xsl:template match="tei:institution">
    <dt class="float">Institution</dt>
    <dd class="float">
      <a href="{$search_url}?doctype=ms&amp;institution={.}">
        <xsl:apply-templates/>
      </a>
    </dd>
  </xsl:template>

  <xsl:template match="tei:repository">
    <dt class="float">Repository</dt>
    <dd class="float">
      <a href="{$search_url}?doctype=ms&amp;repository={.}">
        <xsl:apply-templates/>
      </a>
    </dd>
  </xsl:template>

  <xsl:template match="tei:collection">
    <dt class="float">Collection</dt>
    <dd class="float">
      <a href="{$search_url}?doctype=ms&amp;collection={.}">
        <xsl:apply-templates/>
      </a>
    </dd>
  </xsl:template>

  <xsl:template match="tei:idno">
    <dt class="float">Shelfmark</dt>
    <dd class="float">
      <xsl:apply-templates/>
    </dd>
  </xsl:template>
  
  <xsl:template match="tei:summary">
    <dt class="float">Summary</dt>
    <dd class="float">
      <xsl:apply-templates/>
    </dd>
  </xsl:template>
  
  <xsl:template match="@corresp">
    <xsl:text> (work </xsl:text>
    <xsl:value-of select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msContents/tei:msItem[@xml:id=current()]/@n"/>
    <xsl:text>)</xsl:text>
  </xsl:template>
  
  <xsl:template match="tei:msItem">
    <xsl:variable name="dtid" select="generate-id()"/>

    <xsl:variable name="id">
      <xsl:apply-templates select="." mode="item_id"/>
    </xsl:variable>
    
    <!-- msItem label -->
    <dt>
      <!-- @class -->
      <xsl:attribute name="class">
        <xsl:text>accordion_header</xsl:text>
        <xsl:if test="$workID != '' and $workID = @n">
          <xsl:text> accordion_selected</xsl:text>
        </xsl:if>
      </xsl:attribute>
      
      <!-- @id -->
      <xsl:if test="$id != ''">
        <xsl:attribute name="id">
          <xsl:value-of select="$id"/>
        </xsl:attribute>
      </xsl:if>
      
      <!-- work label -->
      <xsl:choose>
        <!-- numbered work -->
        <xsl:when test="@n != ''">
          <xsl:value-of select="concat('Work ', @n, ': ')"/>
        </xsl:when>
        
        <!-- unnumbered work when there are multiple works -->
        <xsl:when test="preceding-sibling::tei:msItem or following-sibling::tei:msItem">
          <xsl:text>Unnumbered work: </xsl:text>
        </xsl:when>
      </xsl:choose>
      
      <!-- title -->
      <xsl:value-of select="tei:title[. != ''][not(@type='alt')][1]"/>

      <!-- author -->
      <xsl:text> (</xsl:text>
      <xsl:value-of select="tei:author/tei:persName[not(@type='alt')][1]"/>
      <xsl:text>)</xsl:text>
      
    </dt>
        
    <dd>
      <dl>
        <!-- subject headings -->
        <xsl:apply-templates select="@class[. != '']"/>
        <!-- author -->
        <xsl:apply-templates select="self::*[tei:author]" mode="author"/>
        <!-- titles -->
        <xsl:apply-templates select="self::*[tei:title]" mode="title"/>
        <!-- title notes -->
        <xsl:apply-templates select="." mode="note"/>
        <!-- language -->
        <xsl:apply-templates select="tei:textLang[@mainLang != '' or . != '']"/>
        <!-- foliation -->
        <xsl:apply-templates select="tei:locus[@from != '' or @to != '' or . != '']"/>
        
        <!-- stuff which is outside msItem, but @corresp(onnds) to this msItem -->
        <xsl:if test="$id != ''">
          <xsl:apply-templates select="ancestor::tei:msDesc/tei:physDesc/descendant::tei:*[@corresp][str:tokenize(@corresp, ' ') = $id][not(ancestor::tei:*/@corresp)]">
            <xsl:with-param name="item_id" select="$id"/>
          </xsl:apply-templates>
          <xsl:apply-templates select="ancestor::tei:msDesc/tei:history/descendant::tei:*[@corresp][str:tokenize(@corresp, ' ') = $id][not(ancestor::tei:*/@corresp)]">
            <xsl:with-param name="item_id" select="$id"/>
          </xsl:apply-templates>
        </xsl:if>

        <!-- bibliography -->
        <xsl:apply-templates select="descendant::tei:listBibl"/>
        
        <xsl:if test="tei:filiation">
          <dt>
            <a id="{$dtid}" class="auth_dt" href="#">Show filiations</a>
          </dt>
          <xsl:apply-templates select="tei:filiation">
            <xsl:with-param name="dtid" select="$dtid"/>
          </xsl:apply-templates>
        </xsl:if>
        
      </dl>
    </dd>
  </xsl:template>
  
  <xsl:template match="tei:msItem/@class[. != ''] | tei:msContents/@class[. != '']">
    <dt>LOC subject headings</dt>
    <xsl:call-template name="resolve_uris">
      <xsl:with-param name="uris" select="."/>
      <xsl:with-param name="render">dd</xsl:with-param>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template match="tei:textLang">
    <xsl:variable name="displayLabel">
      <xsl:choose>
        <xsl:when test=". != ''">
          <xsl:apply-templates/>
        </xsl:when>
        <xsl:when test="@mainLang != ''">
          <xsl:call-template name="resolve_lang">
            <xsl:with-param name="lang" select="@mainLang"/>
          </xsl:call-template>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    
    <dt class="float">Main language of text</dt>
    <dd class="float">
      <xsl:choose>
        <xsl:when test="@mainLang != ''">
          <a href="{$search_url}?doctype=ms&amp;language={@mainLang}">
            <xsl:value-of select="$displayLabel"/>
          </a>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$displayLabel"/>
        </xsl:otherwise>
      </xsl:choose>
    </dd>
  </xsl:template>
  
  <!-- locus -->
  <xsl:template match="tei:locus">
    <span title="{@n}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  
  <xsl:template match="tei:locus[not(ancestor::tei:note) and not(ancestor::tei:p) and not(ancestor::tei:summary) and not(ancestor::tei:provenance)]">
    <xsl:variable name="units">ff. </xsl:variable>
    
    <dt class="float">Foliation</dt>
    <dd class="float">
      <xsl:choose>
        <xsl:when test=". != ''">
          <xsl:apply-templates/>
        </xsl:when>
        <xsl:when test="@from != '' or @to != ''">
          <xsl:value-of select="concat($units, @from, '-', @to)"/>
        </xsl:when>
      </xsl:choose>
    </dd>
  </xsl:template>

  <!-- author -->
  <xsl:template match="tei:msItem" mode="author">
    <xsl:apply-templates select="tei:author"/>
  </xsl:template>
  
  <xsl:template match="tei:author">
    <xsl:variable name="key" select="@key"/>
    <xsl:variable name="id" select="generate-id()"/>

    <dl>
      <dt>
        <xsl:text>Author</xsl:text>
        
        <!-- is author a translator -->
        <xsl:if test="@role='translator'">
          <xsl:text> (translator)</xsl:text>
        </xsl:if>
      </dt>
      <!-- main names -->
      <xsl:apply-templates select="tei:persName[not(@type='alt')]"/>
      
      <!-- other names -->
      <xsl:if test="tei:persName[@type='alt'] or exsl:node-set($external_docs)/root/mads:mads[@id = $key]">
        <dt>
          <a id="{$id}" class="auth_dt" href="#">Show other names</a>
        </dt>
        <!-- alternative names -->
        <xsl:apply-templates select="tei:persName[@type='alt']">
          <xsl:with-param name="dtid" select="$id"/>
        </xsl:apply-templates>
        <!-- authority file names -->
        <xsl:apply-templates select="exsl:node-set($external_docs)/root/mads:mads[@id = $key]" mode="name">
          <xsl:with-param name="dtid" select="$id"/>
        </xsl:apply-templates>
      </xsl:if>
      
      <!-- notes on author -->
      <xsl:if test="tei:note or exsl:node-set($external_docs)/root/mads:mads[@id = $key]/mads:extension[tei:note]">
        <dt>Biographical notes</dt>
        <!-- need to only match only auth files in first root containing matching auth files - the auth file could be in more than one root -->
        <xsl:apply-templates select="exsl:node-set($external_docs)/root[mads:mads/@id = $key][1]/mads:mads[@id = $key]/mads:extension/tei:note"/>
        <!-- use local notes only if there are no notes in authority file -->
        <xsl:if test="not(exsl:node-set($external_docs)/root[mads:mads/@id = $key][1]/mads:mads[@id = $key]/mads:extension/tei:note)">
          <xsl:apply-templates select="tei:note"/>
        </xsl:if>
      </xsl:if>
    </dl>
  </xsl:template>
  
  <!-- person in note -->
  <xsl:template match="tei:persName[ancestor::tei:note or ancestor::tei:p]">
    <!-- local: might be missing -->
    <xsl:variable name="local">
      <xsl:if test="not(starts-with(@key, 'lccn') or starts-with(@key, 'local'))">
        <xsl:text>local:</xsl:text>
      </xsl:if>
    </xsl:variable>
    
    <xsl:apply-templates select="@role"/>

    <a href="{$path}documents/auth/{$local}{@key}">
      <xsl:apply-templates/>
    </a>
  </xsl:template>
  
  <!-- notes on author -->
  <xsl:template match="tei:author/tei:note | mads:extension/tei:note">
    <dd>
      <xsl:apply-templates/>
    </dd>
  </xsl:template>
  
  <xsl:template match="tei:author/tei:persName">
    <xsl:param name="dtid"/>
    
    <xsl:variable name="key" select="ancestor-or-self::tei:*[@key][1]/@key"/>
    
    <!-- no dtid, so main name and not alternative name -->
    <!--xsl:if test="not($dtid)">
      <dt class="float">
        <xsl:text>Author</xsl:text>
        
        <xsl:if test="@xml:lang != ''">
          <xsl:text> in </xsl:text>
          <xsl:call-template name="resolve_lang">
            <xsl:with-param name="lang" select="@xml:lang"/>
          </xsl:call-template>
        </xsl:if>
      </dt>
    </xsl:if-->
    
    <dd>
      <xsl:attribute name="class">
        <xsl:choose>
          <xsl:when test="$dtid">
            <xsl:value-of select="concat($dtid, ' following')"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>float</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      
      <xsl:choose>
        <xsl:when test="@type='standard' or @type='supplied'">
          <a href="{$path}documents/auth/{$key}">
            <xsl:apply-templates/>
          </a>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates/>
        </xsl:otherwise>
      </xsl:choose>
    </dd>
  </xsl:template>
  
  <!-- title -->
  <xsl:template match="tei:msItem" mode="title">
    <dt>Title</dt>
    <xsl:apply-templates select="tei:title[. != ''][not(@type='alt')]"/>
  </xsl:template>
  
  <xsl:template match="tei:msItem/tei:title">
    <xsl:variable name="lang">
      <xsl:if test="@xml:lang">
        <xsl:call-template name="resolve_lang">
          <xsl:with-param name="lang" select="@xml:lang"/>
        </xsl:call-template>
      </xsl:if>
    </xsl:variable>
    
    <!--dt class="float">
      <xsl:text>Title</xsl:text>
      <xsl:if test="$lang != ''">
        <xsl:text> in </xsl:text>
        <xsl:value-of select="$lang"/>
      </xsl:if>
    </dt-->
    <dd class="float">
      <xsl:apply-templates select="@xml:lang" mode="css_class"/>
      <xsl:apply-templates/>
    </dd>
  </xsl:template>
  
  <!-- use @xml:lang to generate @class -->
  <xsl:template match="@xml:lang" mode="css_class">
    <xsl:if test=". = 'per' or . = 'ara' or . = 'ota'">
      <xsl:attribute name="class">foreign</xsl:attribute>
    </xsl:if>
  </xsl:template>

  <xsl:template match="tei:msItem" mode="note">
    <dt>Notes</dt>
    <xsl:apply-templates select="tei:note"/>
  </xsl:template>
  
  <xsl:template match="tei:msItem/tei:note[. != '']">
    <dd>
      <xsl:apply-templates/>
    </dd>
  </xsl:template>
  
  <!-- links to places -->
  <xsl:template match="tei:placeName | tei:name[@type='place']">
    <a href="{$search_url}?doctype=ms&amp;q={.}&amp;field=places">
      <xsl:apply-templates/>
    </a>
  </xsl:template>

  <!-- elements in notes 
  <xsl:template match="tei:*[ancestor::tei:note or ancestor::tei:handNote or ancestor::tei:p]">
    <xsl:variable name="name" select="local-name()"/>
    <span>
      <xsl:attribute name="title">
        <xsl:choose>
          <xsl:when test="$name = 'persName'">
            <xsl:text>name of person</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$name"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:attribute name="class">
        <xsl:choose>
          <xsl:when test="$name = 'title'">
            <xsl:text>title</xsl:text>
          </xsl:when>
          <xsl:when test="not(self::tei:note/parent::mads:extension)">
            <xsl:text>note_element</xsl:text>
          </xsl:when>
        </xsl:choose>
      </xsl:attribute>
      <xsl:apply-templates/>
    </span>
  </xsl:template-->
    
  <!-- filiation -->
  <xsl:template match="tei:filiation">
    <xsl:param name="dtid"/>
    <dd class="{$dtid} following">
      <xsl:apply-templates select="tei:orgName"/>
      <xsl:text> </xsl:text>
      <xsl:apply-templates select="tei:ref"/>
    </dd>
  </xsl:template>
  
  <xsl:template match="tei:filiation/tei:orgName">
    <!--a href="{$search_url}?doctype=ms&amp;institution={.}"-->
      <xsl:apply-templates/>
    <!--/a-->
  </xsl:template>
  
  <xsl:template match="tei:ref[not(ancestor::tei:bibl)]">
    <!-- filiations are links to documents, everything else link to bibliography -->
    <xsl:variable name="bib">
      <xsl:if test="not(parent::tei:filiation) and not(translate(substring(@target, 1, 3), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ_', '') = '')">
        <xsl:text>bib/</xsl:text>
      </xsl:if>
    </xsl:variable>

    <xsl:choose>
      <!-- ref to bib item -->
      <xsl:when test="$bib != ''">
        <!-- bring in short citation -->
        <xsl:variable name="title">
          <xsl:call-template name="resolve_uris">
            <xsl:with-param name="render">full</xsl:with-param>
            <xsl:with-param name="uris" select="@target"/>
          </xsl:call-template>
        </xsl:variable>
        
        <a href="{$path}documents/{$bib}{@target}">
          <xsl:text> (</xsl:text>
          <xsl:value-of select="$title"/>
          <xsl:if test=". != ''">
            <xsl:value-of select="concat(', pp. ', .)"/>
          </xsl:if>
          <xsl:text>)</xsl:text>
        </a>
      </xsl:when>
      <!-- ref to MS -->
      <xsl:otherwise>
        <a href="{$path}documents/{@target}">
          <xsl:apply-templates/>
        </a>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- physical description -->
  <xsl:template match="tei:objectDesc" mode="physdesc">
    <!--xsl:apply-templates select="tei:supportDesc[@material != '']"/-->
    <xsl:apply-templates select="tei:supportDesc/tei:extent[text()]"/>
    <xsl:apply-templates select="tei:supportDesc/tei:foliation[text()][not(@corresp)]"/>
    <xsl:apply-templates select="tei:supportDesc//tei:dimensions[tei:height != '' or tei:width != ''][not(@corresp)]"/>
    <xsl:apply-templates select="tei:supportDesc/tei:condition[(not(tei:p) and . != '') or tei:p != ''][not(@corresp)]"/>
    <xsl:apply-templates select="tei:layoutDesc[tei:layout[@columns != '' or @ruledLines != '' or (not(descendant::tei:*) and . != '') or descendant::tei:* != '']]"/>
  </xsl:template>
  
  <!--xsl:template match="tei:supportDesc">
    <dt class="float">Support material</dt>
    <dd class="float">
      <xsl:value-of select="@material"/>
    </dd>
  </xsl:template-->
  
  <xsl:template match="tei:extent">
    <xsl:if test="parent::tei:supportDesc">
      <dt class="float">Number of folios</dt>
      <dd class="float">
        <xsl:apply-templates select="text()"/>
    </dd>
    </xsl:if>
  </xsl:template>

  <xsl:template match="tei:foliation">
    <dt class="float">Foliation</dt>
    <dd class="float">
      <xsl:apply-templates/>
    </dd>
  </xsl:template>
  
  <xsl:template match="tei:dimensions[tei:width != '' or tei:height != '']">
    <dt class="float">
      <xsl:text>Dimensions</xsl:text>
      <xsl:choose>
        <xsl:when test="@type = 'leaf'">
          <xsl:text> of folio</xsl:text>
        </xsl:when>
        <xsl:when test="@type = 'written'">
          <xsl:text> of written area</xsl:text>
        </xsl:when>
      </xsl:choose>
    </dt>
    <dd class="float">
      <xsl:apply-templates select="tei:width[. != '']"/>
      <xsl:if test="tei:width != '' and tei:height != ''">
        <xsl:text>, </xsl:text>
      </xsl:if>
      <xsl:apply-templates select="tei:height[. != '']"/>
    </dd>
  </xsl:template>
  
  <xsl:template match="tei:width">
    <xsl:value-of select="concat('width ', ., parent::tei:dimensions/@unit)"/>
  </xsl:template>
  
  <xsl:template match="tei:height">
    <xsl:value-of select="concat('height ', ., parent::tei:dimensions/@unit)"/>
  </xsl:template>
  
  <xsl:template match="tei:condition">
    <dt class="float">Condition</dt>
    <dd class="float">
      <xsl:apply-templates/>
    </dd>
  </xsl:template>

  <!-- layout -->
  <xsl:template match="tei:layoutDesc">
    <xsl:apply-templates select="tei:layout[@columns != '' or @ruledLines != '' or (not(descendant::tei:*) and . != '') or descendant::tei:* != ''][not(@corresp)]"/>
  </xsl:template>
  
  <xsl:template match="tei:layout">
    <!--dt>
      <xsl:text>Layout</xsl:text>
      <xsl:apply-templates select="@corresp"/>
    </dt-->
    <xsl:apply-templates select="@columns[. != '']"/>
    <xsl:apply-templates select="@ruledLines[. != '']"/>
    <xsl:apply-templates select="tei:locus[. != '']"/>
  </xsl:template>
  
  <xsl:template match="@columns">
    <dt class="float">
      <xsl:text>Columns</xsl:text>
      <!--xsl:apply-templates select="parent::tei:layout/@corresp"/-->
    </dt>
    <dd class="float">
      <xsl:value-of select="."/>
    </dd>
  </xsl:template>

  <xsl:template match="@ruledLines">
    <dt class="float">
      <xsl:text>Ruled lines</xsl:text>
      <!--xsl:apply-templates select="parent::tei:layout/@corresp"/-->
    </dt>
    <dd class="float">
      <xsl:value-of select="."/>
    </dd>
  </xsl:template>
  
  <!-- binding -->
  <xsl:template match="tei:bindingDesc" mode="binding">
    <dt class="float">Binding</dt>
    <xsl:apply-templates select="tei:p[. != '']"/>
  </xsl:template>
  
  <xsl:template match="tei:bindingDesc/tei:p">
    <dd class="float">
      <xsl:apply-templates/>
    </dd>
  </xsl:template>
  
  <!-- decoration -->
  <xsl:template match="tei:decoDesc" mode="decoration">
    <dt class="float">Decoration</dt>
    <xsl:apply-templates select="tei:decoNote[. != '']"/>
  </xsl:template>
  
  <xsl:template match="tei:decoNote">
    <dd class="float">
      <xsl:apply-templates/>
    </dd>
  </xsl:template>
  
  <!-- additions -->
  <xsl:template match="tei:additions" mode="additions">
    <xsl:apply-templates select="tei:p[. != '']"/>
  </xsl:template>
  
  <xsl:template match="tei:additions/tei:p">
    <dt class="float">Addition</dt>
    <dd class="float">
      <xsl:apply-templates/>
    </dd>
  </xsl:template>
  
  <!-- hand -->
  <xsl:template match="tei:handDesc" mode="hand">
    <xsl:apply-templates select="tei:handNote[@script != '' or . != ''][not(@corresp)]"/>
  </xsl:template>
  
  <xsl:template match="tei:handNote">
    <xsl:param name="item_id"/>
    
    <xsl:apply-templates select="tei:p[not($item_id) or not(@corresp) or str:tokenize(@corresp) = $item_id]"/>
  </xsl:template>
  
  <xsl:template match="tei:handNote/tei:p">
    <xsl:variable name="script" select="parent::tei:handNote/@script"/>
    
    <xsl:choose>
      <!-- first p is for script information -->
      <xsl:when test="not(preceding-sibling::tei:p)">
        <xsl:variable name="script_text">
          <xsl:choose>
            <xsl:when test=". != ''">
              <xsl:value-of select="."/>
            </xsl:when>
            <xsl:when test="$script = 'unknown'">
              <xsl:text>Written in an unknown script</xsl:text>
            </xsl:when>
            <xsl:when test="$script != ''">
              <xsl:text>Written in </xsl:text>
              <em>
                <xsl:call-template name="resolve_script">
                  <xsl:with-param name="script" select="$script"/>
                </xsl:call-template>
              </em>
              <xsl:text> script</xsl:text>
            </xsl:when>
          </xsl:choose>
        </xsl:variable>
        
        <dt class="float">
          <xsl:text>Hand</xsl:text>
        </dt>
        <dd class="float">
          <xsl:choose>
            <xsl:when test="$script != ''">
              <a href="{$search_url}?doctype=ms&amp;script={$script}">
                <xsl:copy-of select="$script_text"/>
              </a>
            </xsl:when>
            <xsl:otherwise>
              <xsl:copy-of select="$script_text"/>
            </xsl:otherwise>
          </xsl:choose>
        </dd>
      </xsl:when>
      <!-- following <p>s for copyists etc.. -->
      <xsl:otherwise>
        <dd>
          <xsl:apply-templates/>
        </dd>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- seal descriptions -->
  <xsl:template match="tei:sealDesc" mode="seal">
    <xsl:apply-templates select="tei:p[. != '']" mode="seal"/>
  </xsl:template>
  
  <xsl:template match="tei:sealDesc/tei:p" mode="seal">
    <dt class="float">
      <xsl:text>Seal</xsl:text>
    </dt>
    <dd class="float">
      <xsl:apply-templates/>
    </dd>
  </xsl:template>
  
  <!-- dates and provenance -->
  <xsl:template match="tei:history" mode="history">
    <xsl:apply-templates select="tei:origin[tei:* != '' or tei:*/@* != '']"/>
    <xsl:apply-templates select="tei:provenance[(not(descendant::tei:*) and . != '') or descendant::tei:* != ''][not(@corresp)]"/>
  </xsl:template>
  
  <xsl:template match="tei:origin">
    <xsl:apply-templates select="tei:*[. != '' or @* != ''][not(@corresp)]"/>
  </xsl:template>
  
  <xsl:template match="tei:origin/tei:origPlace">
    <dt class="float">
      <xsl:text>Place</xsl:text>
    </dt>
    <dd class="float">
      <a href="{$search_url}?doctype=ms&amp;field=places&amp;q={.}">
        <xsl:apply-templates/>
      </a>
    </dd>
  </xsl:template>

  <xsl:template match="tei:origin/tei:date">
    <dt class="float">
      <xsl:text>Date of copy</xsl:text>
    </dt>
    <dd class="float">
      <xsl:apply-templates select="." mode="century"/>
    </dd>
  </xsl:template>
  
  <xsl:template match="tei:provenance">
    <xsl:if test="not(tei:p/@corresp)">
      <dt class="float">Provenance</dt>
    </xsl:if>
    
    <!-- process paragraphs -->
    <xsl:apply-templates select="tei:p[not(@corresp)]"/>
    <!-- no paragraphs, so wrap contents in DD -->
    <xsl:if test="not(tei:p)">
      <dd class="float">
        <xsl:apply-templates/>
      </dd>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="tei:provenance/tei:p">
    <xsl:if test="@corresp">
      <dt class="float">Provenance</dt>
    </xsl:if>
    <dd class="float">
      <!--xsl:apply-templates select="@corresp"/-->
      <xsl:apply-templates/>
    </dd>
  </xsl:template>
  
  <!-- names in provenance -->
  <xsl:template match="tei:persName[ancestor::tei:provenance]">
    <xsl:apply-templates/>
    <xsl:apply-templates select="@role|parent::tei:name/@role"/>
  </xsl:template>
  
  <xsl:template match="@role">
    <xsl:text> (</xsl:text>
    <xsl:value-of select="."/>
    <xsl:text>)</xsl:text>
  </xsl:template>

  <!-- additional information -->
  <xsl:template match="tei:history" mode="info">
    <xsl:apply-templates select="tei:acquisition[(not(tei:*) and . != '') or tei:* != '']"/>
  </xsl:template>

  <xsl:template name="tei:acquisition">
    <dt class="float">Acquisition</dt>
    <dd class="float">
      <xsl:apply-templates/>
    </dd>
  </xsl:template>
  
  <!-- titles outside msItem -->
  <xsl:template match="tei:title[not(parent::tei:msItem)][. != '']">
    <em>
      <xsl:apply-templates/>
    </em>
  </xsl:template>
  
  <!-- bibliography -->
  <xsl:template match="tei:listBibl[tei:bibl/tei:ref/@target != '']">
    <xsl:variable name="key" select="parent::tei:msItem/tei:author/@key"/>
    <!-- put current node into variable, to access it from inside for-each loop -->
    <xsl:variable name="listBibl" select="."/>

    <dt>
      <xsl:text>Bibliography</xsl:text>
    </dt>
    
    <!-- collect bib refs, using order given by $groups -->
    <xsl:variable name="bib_refs">
      <xsl:for-each select="exsl:node-set($groups)/data:data/data:item">
        <xsl:apply-templates select="exsl:node-set($listBibl)/tei:bibl[@type = current()/@value]/tei:ref" mode="get_mods">
          <xsl:with-param name="key" select="$key"/>
          <xsl:with-param name="render">full</xsl:with-param>
        </xsl:apply-templates>
      </xsl:for-each>
    </xsl:variable>
    
    <!-- now output them grouped by @type and then by surname/forenames -->
    <xsl:apply-templates select="exsl:node-set($bib_refs)" mode="ordered_mods"/>
    
    <!-- bibliographic items in notes 
    <xsl:apply-templates 
        select="exsl:node-set($external_docs)/root[mads:mads/@id = $key][1]/mads:mads[@id = $key]/mads:extension/tei:note/descendant::tei:ref"
        mode="bib_list"
        >
      <xsl:with-param name="key" select="$key"/>
    </xsl:apply-templates-->
  </xsl:template>
  
  <xsl:template match="tei:date[not(parent::tei:origin)]">
    <xsl:apply-templates select="." mode="date"/>
  </xsl:template>
  
  <!-- display of dates -->
  <xsl:template match="tei:*" mode="date">
    <!-- see if text is just number or not -->
    <xsl:variable name="just_number" select="translate(., '0123456789', '') = ''"/>
    
    <xsl:apply-templates/>
    
    <!-- if just number then give calendar, otherwise don't -->
    <xsl:if test="$just_number">
      <xsl:call-template name="resolve_calendar">
        <xsl:with-param name="calendar" select="@calendar"/>
      </xsl:call-template>
    </xsl:if>

    <!-- don't show date when it is just notAfter 1900 (undated) -->
    <xsl:if test="not(not(@when) and not(@notBefore) and @notAfter = '1900')">
      <xsl:if test="@when or @notBefore or @notAfter">
        <xsl:text> [</xsl:text>
        
        <xsl:choose>
          <xsl:when test="@when">
            <xsl:value-of select="@when"/>
            <xsl:call-template name="resolve_calendar"/>
          </xsl:when>
          <xsl:when test="@notBefore and @notAfter">
            <xsl:value-of select="concat(@notBefore, '-', @notAfter)"/>
            <xsl:call-template name="resolve_calendar"/>
          </xsl:when>
          <xsl:when test="@notBefore">
            <xsl:value-of select="concat(@notBefore, '-')"/>
            <xsl:call-template name="resolve_calendar"/>
          </xsl:when>
          <xsl:when test="@notAfter">
            <xsl:value-of select="concat('-', @notAfter)"/>
            <xsl:call-template name="resolve_calendar"/>
          </xsl:when>
        </xsl:choose>

        <xsl:text>]</xsl:text>
      </xsl:if>
    </xsl:if>
  </xsl:template>
  
  <!-- just century -->
  <xsl:template match="tei:date" mode="century">
    <xsl:choose>
      <!-- contains century already, so leave as is -->
      <xsl:when test="contains(., 'entury')">
        <xsl:apply-templates/>
      </xsl:when>
      <xsl:otherwise>
        <!-- maybe do something with certainty -->
        <xsl:apply-templates select="tei:certainty" mode="century"/>
        
        <xsl:choose>
          <!-- use @notBefore/@notAfter/@when -->
          <xsl:when test="@notBefore">
            <xsl:call-template name="century">
              <xsl:with-param name="text" select="@notBefore"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:when test="@notAfter">
            <xsl:call-template name="century">
              <xsl:with-param name="text" select="@notAfter"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:when test="@when">
            <xsl:call-template name="century">
              <xsl:with-param name="text" select="@when"/>
            </xsl:call-template>
          </xsl:when>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="tei:certainty" mode="century">
    <xsl:choose>
      <xsl:when test="@cert = 'medium'">
        <xsl:text>possibly </xsl:text>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="century">
    <xsl:param name="text"/>
    
    <xsl:value-of select="concat(number(substring($text, 1, string-length($text) - 2)) + 1, 'th. century')"/>
  </xsl:template>
  
  <xsl:template match="mads:topic" mode="sh">
    <dd>
      <a href="{$search_url}?doctype=ms&amp;subject_topic={.}">
        <xsl:apply-templates/>
      </a>
    </dd>
  </xsl:template>
  
  <xsl:template match="mads:mads" mode="name">
    <xsl:param name="dtid"/>
    <xsl:apply-templates select="mads:authority" mode="name">
      <xsl:with-param name="dtid" select="$dtid"/>
    </xsl:apply-templates>
    <xsl:apply-templates select="mads:variant" mode="name">
      <xsl:with-param name="dtid" select="$dtid"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template match="mads:authority" mode="name">
    <xsl:param name="dtid"/>
    <dd class="{$dtid} following">
      <xsl:apply-templates select="mads:name" mode="name"/>
      <xsl:text> (authorised)</xsl:text>
    </dd>
  </xsl:template>

  <xsl:template match="mads:variant" mode="name">
    <xsl:param name="dtid"/>
    <dd class="{$dtid} following">
      <xsl:apply-templates select="mads:name" mode="name"/>
      <xsl:text> (variant)</xsl:text>
    </dd>
  </xsl:template>
  
  <xsl:template match="mads:name" mode="name">
    <xsl:apply-templates select="mads:namePart[not(@type)]"/>
    <xsl:apply-templates select="mads:namePart[@type='termsOfAddress']"/>
    <xsl:apply-templates select="mads:namePart[@type='date']"/>
  </xsl:template>
  
  <!-- get ID for msItem -->
  <xsl:template match="tei:msItem" mode="item_id">
    <xsl:choose>
      <xsl:when test="@xml:id != ''">
        <xsl:value-of select="@xml:id"/>
      </xsl:when>
      <xsl:when test="@n != ''">
        <xsl:value-of select="concat('a', @n)"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <!-- show role that person has -->
  <xsl:template match="tei:persName/@role">
    <xsl:choose>
      <xsl:when test=". = 'copyist'">
        <xsl:text>Copyist: </xsl:text>
      </xsl:when>
      <xsl:when test=". = 'patron'">
        <xsl:text>Patron: </xsl:text>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  
</xsl:stylesheet>

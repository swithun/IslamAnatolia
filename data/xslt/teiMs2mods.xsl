<?xml version="1.0" encoding="UTF-8"?><!-- -*- xml -*- -->
<xsl:stylesheet
    version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:php="http://php.net/xsl"
    xmlns:exsl="http://exslt.org/common"
    xmlns:str="http://exslt.org/strings"
    xmlns:mads="http://www.loc.gov/mads/v2"
    xmlns="http://www.loc.gov/mods/v3"
    xmlns:mods="http://www.loc.gov/mods/v3"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xsl:extension-element-prefixes="php exsl str"
    exclude-result-prefixes="str xlink"
    >
  
  <!--****** xslt/teiMs2mods.xsl
 * NAME
 * teiMs2mods.xsl
 * SYNOPSIS
 * Converts TEI to MODS XML. The purpose of this is to convert TEI to Solr.
 * TEI is rich and arbitrarily nested, so converting it first to a slightly simpler format (MODS), and then to the very simple and flat format (Solr) is sensible.
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20120710
 * SEE ALSO
 *   * xslt/mads2mods.xsl
 *   * xslt/external_uris.xsl
 ****-->
  
  <xsl:include href="external_uris.xsl"/>
  <xsl:include href="mads2mods.xsl"/>
  
  <xsl:output
      method="xml"
      indent="yes"
      encoding="UTF-8"
      />
  
  <!-- key of people (authors, editors etc.) -->
  <xsl:key
      name="people"
      match="tei:*"
      use="@key|@class"
      />

  <xsl:param name="mads"/>
  
  <xsl:template match="tei:TEI">
    <modsCollection>
      <!--xsl:copy-of select="exsl:node-set($external_docs)"/-->
      <!-- manuscript mods document -->
      <mods>
        <typeOfResource displayLabel="ms">text</typeOfResource>

        <!-- originInfo -->
        <xsl:apply-templates
            select="tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:history/tei:origin"
            mode="origin_info"
            />
        
        <!-- provenance -->
        <xsl:apply-templates
            select="tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:history/tei:provenance"
            mode="provenance"
            />

        <!-- physical description -->
        <xsl:apply-templates
            select="tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:physDesc"
            mode="physical_description"
            />
        
        <!-- table of contents 
        <xsl:apply-templates
            select="tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msContents"
            mode="table_of_contents"
            /-->

        <!-- record info -->
        <xsl:apply-templates
            select="tei:teiHeader/tei:fileDesc/tei:publicationStmt"
            mode="record_info"
            />

        <!-- identifier -->
        <xsl:apply-templates
            select="tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msIdentifier"
            mode="ms_identifier"
            />
        
        <!-- location -->
        <xsl:apply-templates
            select="tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msIdentifier"
            mode="location"
            />
        
        <!-- access condition -->
        <xsl:apply-templates
            select="tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:additional/tei:adminInfo/tei:availability"
            mode="access_condition"
            />
        
        <!-- classification -->
        <xsl:apply-templates
            select="tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msContents/@class"
            mode="classification"
            />
      </mods>
      
      <!-- work mods documents -->
      <xsl:apply-templates select="tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msContents/tei:msItem" mode="mods"/>
      
    </modsCollection>
  </xsl:template>
  
  <xsl:template match="tei:msItem" mode="mods">
    <mods>
      <!-- titles -->
      <xsl:apply-templates select="." mode="title_info"/>
      
      <!-- names or authors and editors 
      <xsl:apply-templates
          select="tei:*[local-name()='author' or local-name()='editor'][generate-id(.)=generate-id(key('people', @key)[1])]"
          mode="name"
          /-->
      <xsl:apply-templates select="tei:author|tei:editor" mode="name"/>
      
      <!-- other names in the work, which aren't in author/editor, or are in a note -->
      <xsl:apply-templates
          select="descendant::tei:persName[not(ancestor::tei:author or ancestor::tei:editor) or ancestor::tei:note]"
          mode="name"
          >
        <xsl:with-param name="role">related</xsl:with-param>
      </xsl:apply-templates>
      
      <!-- persNames -->
      <xsl:apply-templates select="descendant::tei:persName[@role or parent::tei:note/@type='dedication']" mode="name"/>
      
      <!-- place of composition - place in a note -->
      <xsl:apply-templates select="tei:note[@type='composition']/descendant::tei:placeName[@key != ''][1] | tei:note[@type='composition']/descendant::tei:name[@type = 'place'][@key != ''][1]" mode="composition"/>

      <!-- @xml:id or just one msItem -->
      <xsl:if test="@xml:id or count(parent::tei:msContents/tei:msItem) = 1">
        <!-- originInfo -->
        <xsl:apply-templates select="ancestor::tei:msDesc/tei:history/tei:origin" mode="origin_info">
          <xsl:with-param name="corresp" select="@xml:id"/>
        </xsl:apply-templates>
        
        <!-- provenance -->
        <xsl:apply-templates select="ancestor::tei:msDesc/tei:history/tei:provenance" mode="provenance">
          <xsl:with-param name="corresp" select="@xml:id"/>
        </xsl:apply-templates>
        
        <!-- physical description -->
        <xsl:apply-templates select="ancestor::tei:msDesc/tei:physDesc" mode="physical_description">
          <xsl:with-param name="corresp" select="@xml:id"/>
        </xsl:apply-templates>
      </xsl:if>
      
      <!-- type of resource -->
      <typeOfResource displayLabel="work">text</typeOfResource>
      
      <!-- language -->
      <xsl:apply-templates select="tei:textLang[. != '' or @mainLang != '']" mode="language"/>

      <!-- abstract -->
      <xsl:apply-templates select="." mode="abstract"/>
      
      <!-- target audience ? -->
      
      <!-- note -->
      <xsl:apply-templates select="tei:note" mode="note">
        <xsl:with-param name="type">
          <xsl:text>work</xsl:text>
        </xsl:with-param>
      </xsl:apply-templates>
      
      <!-- subject ? -->
      
      <!-- related items - use URNs in @key and @class, and MS @class too -->
      <xsl:apply-templates 
          select="descendant-or-self::tei:*/@key | descendant-or-self::tei:*/@class | ancestor::tei:msContents/@class"
          mode="classification"
          />
      
      <!-- part -->
      <xsl:apply-templates select="self::tei:msItem[@id or @xml:id or tei:locus]" mode="part"/>
      
      <!-- extension ? -->
      
      
      <!-- bibliography -->
      <xsl:apply-templates select="tei:listBibl/tei:bibl" mode="bibliography"/>
      
      <!-- identifier -->
      <xsl:apply-templates select="ancestor::tei:msDesc/tei:msIdentifier" mode="work_identifier">
        <xsl:with-param name="work">
          <xsl:text>;</xsl:text>
          <xsl:choose>
            <xsl:when test="@xml:id != ''">
              <xsl:value-of select="@xml:id"/>
            </xsl:when>
            <xsl:otherwise>
            <xsl:text>unnumbered_</xsl:text>
              <xsl:value-of select="count(preceding-sibling::tei:msItem) + 1"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:with-param>
      </xsl:apply-templates>
    </mods>
  </xsl:template>

  <!-- titleInfo -->
  <xsl:template match="tei:msItem" mode="title_info">
    <titleInfo>
      <xsl:apply-templates select="tei:title[string(.)]" mode="title"/>
    </titleInfo>
  </xsl:template>
  
  <xsl:template match="tei:title[not(preceding-sibling::tei:title)]" mode="title">
    <title>
      <xsl:apply-templates select="@xml:lang|@type"/>
      <xsl:apply-templates/>
    </title>
  </xsl:template>
  
  <xsl:template match="tei:title[preceding-sibling::tei:title]" mode="title">
    <subTitle>
      <xsl:apply-templates select="@xml:lang"/>
      <xsl:apply-templates/>
    </subTitle>
  </xsl:template>
  
  <!-- name -->
  <xsl:template match="tei:author|tei:editor" mode="name">
    <xsl:apply-templates mode="name"/>
  </xsl:template>
  
  <xsl:template match="tei:note" mode="name">
    <xsl:apply-templates select="." mode="note">
      <xsl:with-param name="type">
        <xsl:text>name</xsl:text>
      </xsl:with-param>
    </xsl:apply-templates>
  </xsl:template>
  
  <!-- place/date of composition -->
  <xsl:template match="tei:placeName | tei:name[@type='place']" mode="composition">
    <originInfo eventType="creation">
      <xsl:apply-templates select="." mode="mods_place"/>
      <xsl:apply-templates select="parent::tei:*/tei:date[1]" mode="mods_date"/>
    </originInfo>
  </xsl:template>

  <!-- personal names -->
  <xsl:template match="tei:persName" mode="name">
    <xsl:param name="role">
      <xsl:choose>
        <xsl:when test="@role">
          <xsl:value-of select="@role"/>
        </xsl:when>
        <xsl:when test="parent::tei:note/@type='dedication'">
          <xsl:value-of select="parent::tei:note/@type"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="local-name(parent::tei:*)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:param>
    
    <!-- is this persName first? -->
    <xsl:variable name="first" select="not(boolean(preceding-sibling::tei:persName))"/>
    
    <xsl:if test="string() or tei:*">
      <!-- look for @key -->
      <xsl:variable name="key">
        <!-- only use @key for first persName -->
        <xsl:if test="$first">
          <xsl:choose>
            <xsl:when test="@key != ''">
              <xsl:value-of select="@key"/>
            </xsl:when>
            <xsl:when test="parent::tei:*/@key and not(preceding-sibling::tei:persName)">
              <xsl:value-of select="parent::tei:*/@key"/>
            </xsl:when>
          </xsl:choose>
        </xsl:if>
      </xsl:variable>
      
      <name>
        <!-- only include @key in first persName -->
        <xsl:if test="$first and parent::tei:*/@key">
          <xsl:attribute name="authority">
            <xsl:value-of select="substring-before(parent::tei:*/@key, ':')"/>
          </xsl:attribute>
          <xsl:attribute name="valueURI">
            <xsl:value-of select="parent::tei:*/@key"/>
          </xsl:attribute>
        </xsl:if>
        
        <xsl:apply-templates select="@xml:lang"/>
        
        <!-- how to use this name -->
        <xsl:variable name="usage">
          <xsl:choose>
            <xsl:when test="@type = 'standard' or @type = 'supplied'">
              <xsl:text>primary</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>secondary</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        
        <xsl:if test="$usage != ''">
          <xsl:attribute name="usage">
            <xsl:value-of select="$usage"/>
          </xsl:attribute>
        </xsl:if>
        
        <!-- put text children into displayForm -->
        <xsl:if test="text()">
          <displayForm>
            <xsl:apply-templates select="text()"/>
          </displayForm>
        </xsl:if>
        
        <!-- put child elements into namePart -->
        <xsl:apply-templates select="tei:*" mode="name"/>
        
        <!-- person's role -->
        <xsl:if test="$role != ''">
          <role>
            <xsl:value-of select="$role"/>
          </role>
        </xsl:if>
      </name>
      
      <xsl:if test="$key != ''">
        <name usage="all" authority="{substring-before($key, ':')}" valueURI="{$key}">
          <displayForm>
            <xsl:apply-templates
                select="exsl:node-set($external_docs)//mads:mads[@id = $key]/mads:authority/mads:name/mads:namePart"
                mode="displayForm"
                />
          </displayForm>
          <xsl:if test="$role != ''">
            <role>
              <xsl:value-of select="$role"/>
            </role>
          </xsl:if>
        </name>
      </xsl:if>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="mads:namePart" mode="displayForm">
    <xsl:apply-templates/>
    
    <xsl:if test="following-sibling::mads:namePart">
      <xsl:text> </xsl:text>
    </xsl:if>
  </xsl:template>
  
  <!-- all names should go through here -->
  <xsl:template match="tei:persName" mode="nameKey">
    <xsl:variable name="key">
      <xsl:choose>
        <xsl:when test="@key != ''">
          <xsl:value-of select="@key"/>
        </xsl:when>
        <!-- parent has @key and this is first persName child -->
        <xsl:when test="parent::tei:*/@key and not(preceding-sibling::tei:persName)">
          <xsl:value-of select="parent::tei:*/@key"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:if test="$key != ''">
      <name usage="all" authority="{substring-before($key, ':')}" valueURI="{$key}">
        <displayForm>
          <xsl:apply-templates
              select="exsl:node-set($external_docs)/descendant::mads:mads[@id = $key]/mads:authority/mads:name/mads:namePart[1]"
              />
        </displayForm>
      </name>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="tei:surname|tei:forename|tei:addName" mode="name">
    <xsl:if test="string()">
      <namePart>
        <xsl:attribute name="type">
          <xsl:choose>
            <xsl:when test="@type">
              <xsl:value-of select="@type"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="local-name()"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
        <xsl:apply-templates/>
      </namePart>
    </xsl:if>
  </xsl:template>
  
  <!-- type of resource -->
  <xsl:template match="tei:objectDesc" mode="type_of_resource">
    <typeOfResource displayLabel="{@form}">text</typeOfResource>
  </xsl:template>
  
  <!-- origin info -->
  <xsl:template match="tei:origin" mode="origin_info">
    <xsl:param name="corresp"/>
    
    <originInfo eventType="copy">
      <xsl:apply-templates mode="origin_info">
        <xsl:with-param name="corresp" select="$corresp"/>
      </xsl:apply-templates>
    </originInfo>
  </xsl:template>
  
  <xsl:template match="tei:date" mode="origin_info">
    <xsl:param name="corresp"/>
    
    <xsl:if test="not(@corresp) or @corresp = $corresp">
      <xsl:apply-templates select="." mode="mods_date">
        <xsl:with-param name="date">dateOther</xsl:with-param>
        <xsl:with-param name="type">copy</xsl:with-param>
      </xsl:apply-templates>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="tei:origPlace" mode="origin_info">
    <xsl:param name="corresp"/>
    
    <xsl:if test="not(@corresp) or @corresp = $corresp">
      <xsl:apply-templates select="." mode="mods_place"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="mads:geographic" mode="placeTerm">
    <place>
      <placeTerm type="text">
        <xsl:apply-templates/>
      </placeTerm>
    </place>
  </xsl:template>
  
  <xsl:template match="tei:*" mode="mods_place">
    <xsl:choose>
      <!-- have @key, so use that for text and code of place -->
      <xsl:when test="@key != ''">
        <xsl:apply-templates 
            select="exsl:node-set($external_docs)/descendant::mads:mads[@id = current()/@key]/mads:authority/mads:geographic[. != '']"
            mode="placeTerm"
            />
        <place>
          <placeTerm 
              type="code" 
              authority="{substring-before(@key, ':')}" 
              valueURI="{@key}"
              />
        </place>
      </xsl:when>
      <!-- just have given text, so use that -->
      <xsl:when test=". != ''">
        <place>
          <placeTerm type="text">
            <xsl:apply-templates/>
          </placeTerm>
        </place>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
    
  <!-- create dates using @notBefore and @notAfter -->
  <xsl:template match="@notBefore" mode="mods_date">
    <xsl:param name="type"/>
    <xsl:param name="date">dateCreated</xsl:param>
    
    <xsl:element name="{$date}">
      <xsl:attribute name="point">start</xsl:attribute>
      
      <xsl:if test="$type != ''">
        <xsl:attribute name="type">
          <xsl:value-of select="$type"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:value-of select="."/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="@notAfter" mode="mods_date">
    <xsl:param name="type"/>
    <xsl:param name="date">dateCreated</xsl:param>
    
    <xsl:element name="{$date}">
      <xsl:attribute name="point">end</xsl:attribute>

      <xsl:if test="$type != ''">
        <xsl:attribute name="type">
          <xsl:value-of select="$type"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:value-of select="."/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="tei:date" mode="mods_date">
    <xsl:param name="type"/>
    <xsl:param name="date">dateCreated</xsl:param>
    
    <xsl:element name="{$date}">
      <xsl:if test="$type != ''">
        <xsl:attribute name="type">
          <xsl:value-of select="$type"/>
        </xsl:attribute>
      </xsl:if>
      
      <xsl:choose>
        <xsl:when test="@when != ''">
          <!-- @when is always CE -->
          <xsl:value-of select="@when"/>
        </xsl:when>
        <xsl:otherwise>
          <!-- put calendar into encoding attribute -->
          <xsl:if test="@calendar != ''">
            <xsl:attribute name="encoding">
              <xsl:value-of select="@calendar"/>
            </xsl:attribute>
          </xsl:if>
          
          <xsl:apply-templates/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:element>
    
    <xsl:apply-templates select="@notBefore|@notAfter" mode="mods_date">
      <xsl:with-param name="type" select="$type"/>
      <xsl:with-param name="date" select="$date"/>
    </xsl:apply-templates>
    
    <!-- get century for creation dates -->
    <xsl:if test="$date = 'dateCreated' and (@when or (@notBefore and @notAfter))">
      <dateOther type="century">
        <xsl:choose>
          <!-- replace last two digits in @when with 00 -->
          <xsl:when test="@when">
            <xsl:value-of select="concat(substring(@when, 1, string-length(@when) - 2), '00')"/>
          </xsl:when>
          <!-- have range, so take century of start -->
          <xsl:when test="@notBefore and @notAfter">
            <xsl:value-of select="concat(substring(@notBefore, 1, string-length(@notBefore) - 2), '00')"/>
          </xsl:when>
        </xsl:choose>
      </dateOther>
    </xsl:if>
  </xsl:template>
  
  <!-- provenance -->
  <xsl:template match="tei:provenance" mode="provenance">
    <xsl:param name="corresp"/>
    
    <xsl:if test="not(@corresp) or @corresp = $corresp">
      <!-- get people with roles -->
      <xsl:apply-templates select="descendant::tei:name[@role != '']" mode="provenance"/>
      <!-- put everything into notes -->
      <xsl:apply-templates select="tei:p"/>
      <xsl:if test="not(tei:p)">
        <note>
          <xsl:apply-templates/>
        </note>
      </xsl:if>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="tei:name" mode="provenance">
    <xsl:apply-templates select="tei:persName" mode="name">
      <xsl:with-param name="role" select="@role"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template match="tei:provenance/tei:p">
    <note>
      <xsl:apply-templates/>
    </note>
  </xsl:template>
  
  <!-- language -->
  <xsl:template match="tei:textLang" mode="language">
    <language>
      <xsl:if test=". != ''">
        <xsl:attribute name="displayLabel">
          <xsl:apply-templates/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@mainLang != ''">
        <xsl:attribute name="lang">
          <xsl:value-of select="@mainLang"/>
        </xsl:attribute>
      </xsl:if>
    </language>
  </xsl:template>
  
  <!-- physical description -->
  <xsl:template match="tei:physDesc" mode="physical_description">
    <xsl:param name="corresp"/>
    <physicalDescription>
      <xsl:apply-templates select="tei:objectDesc/tei:supportDesc/tei:extent|tei:objectDesc/tei:layoutDesc|tei:handDesc/tei:handNote[@script != '']" mode="physical_description">
        <xsl:with-param name="corresp" select="$corresp"/>
      </xsl:apply-templates>
    </physicalDescription>
  </xsl:template>
  
  <xsl:template match="tei:extent" mode="physical_description">
    <xsl:param name="corresp"/>
    
    <!-- no corresp, so assume MS -->
    <xsl:if test="not($corresp)">
      <extent>
        <xsl:apply-templates select="text()"/>
      </extent>
    </xsl:if>

    <!-- process children which have no @corresp or match given $corresp -->
    <xsl:apply-templates select="tei:dimensions[not(@corresp) or @corresp = $corresp]" mode="physical_description"/>
  </xsl:template>
  
  <xsl:template match="tei:dimensions" mode="physical_description">
    <xsl:if test="tei:*[string(.)]">
      <extent>
        <xsl:apply-templates select="tei:*" mode="physical_description"/>
      </extent>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="tei:height|tei:width|tei:depth|tei:dim" mode="physical_description">
    <xsl:value-of select="concat(local-name(), ' ', ., ' ', parent::tei:dimensions/@unit)"/>
    <xsl:if test="following-sibling::tei:*">
      <xsl:text>, </xsl:text>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="tei:layoutDesc" mode="physical_description">
    <xsl:param name="corresp"/>
    <xsl:apply-templates select="tei:layout[not(@corresp) or @corresp = $corresp]" mode="physical_description"/>
  </xsl:template>
  
  <xsl:template match="tei:layout" mode="physical_description">
    <xsl:if test="@columns != ''">
      <extent unit="columns">
        <xsl:value-of select="@columns"/>
      </extent>
    </xsl:if>
    <xsl:if test="@ruledLines != ''">
      <extent unit="ruledLines">
        <xsl:value-of select="@ruledLines"/>
      </extent>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="tei:handNote" mode="physical_description">
    <xsl:param name="corresp"/>
    <xsl:if test="not(@corresp) or @corresp = $corresp">
      <extent script="{@script}"/>
    </xsl:if>
  </xsl:template>
  
  <!-- abstract -->
  <xsl:template match="tei:msItem" mode="abstract">
    <xsl:apply-templates select="tei:incipit|tei:explicit" mode="abstract"/>
  </xsl:template>
  
  <xsl:template match="tei:incipit|tei:explicit" mode="abstract">
    <xsl:if test="string(.)">
      <abstract>
        <xsl:apply-templates select="@xml:lang"/>
        <xsl:attribute name="type">
          <xsl:value-of select="local-name()"/>
        </xsl:attribute>
        <xsl:apply-templates/>
      </abstract>
    </xsl:if>
  </xsl:template>
  
  <!-- table of contents -->
  <xsl:template match="tei:msContents" mode="table_of_contents">
    <tableOfContents>
      <xsl:apply-templates
          select="tei:msItem"
          mode="table_of_contents"
          />
    </tableOfContents>
  </xsl:template>
  
  <!-- table of contents item -->
  <xsl:template match="tei:msItem" mode="table_of_contents">
    <xsl:choose>
      <xsl:when test="@n != ''">
        <xsl:value-of select="concat('Work ', @n)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat('Unnumbered work ', count(preceding-sibling::tei:msItem) + 1)"/>
      </xsl:otherwise>
    </xsl:choose>
    
    <xsl:text>: </xsl:text>

    <!-- first useable title -->
    <xsl:apply-templates select="tei:title[string(.)][1]"/>
    
    <xsl:if test="following-sibling::tei:msItem">
      <xsl:text> -- </xsl:text>
    </xsl:if>
  </xsl:template>
  
  <!-- note -->
  <xsl:template match="tei:note" mode="note">
    <xsl:param name="depth" select="number(0)"/>
    <xsl:param name="type"/>
    
    <xsl:if test="string(.)">
      
      <!-- convert first work note's TEI to HTML -->
      <xsl:if test="$type = 'work'">
        <note type="work_html">
          <xsl:apply-templates select="@xml:lang"/>
          <xsl:apply-templates mode="html"/>
        </note>
      </xsl:if>
      
      <note type="{$type}">
        <xsl:apply-templates select="@xml:lang"/>
        <xsl:apply-templates mode="note"/>
      </note>
    </xsl:if>
    
    <xsl:if test="ancestor::mads:mads">
      <xsl:apply-templates select="descendant::tei:*/@key" mode="classification">
        <xsl:with-param name="depth" select="$depth + 1"/>
      </xsl:apply-templates>
    </xsl:if>
  </xsl:template>
  
  <!-- convert note's TEI to HTML -->
  <xsl:template match="tei:*" mode="html">
    <xsl:choose>
      <xsl:when test="@key">
        <a href="./{@key}" xmlns="">
          <xsl:apply-templates mode="html"/>
        </a>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates mode="html"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- strip out other markup from notes -->
  <xsl:template match="tei:*" mode="note">
    <xsl:apply-templates mode="note"/>
  </xsl:template>
  
  <!-- identifier -->
  <xsl:template match="tei:msIdentifier" mode="ms_identifier">
    <identifier type="local">
      <!-- BUG somewhere - why isn't @xml:id recognised after msItem elements have been added? -->
      <xsl:apply-templates
          select="parent::tei:msDesc/@xml:id|parent::tei:msDesc/@id"
          mode="identifier"
          />
    </identifier>
    <xsl:apply-templates select="tei:idno|tei:altIdentifier" mode="identifier"/>
  </xsl:template>

  <xsl:template match="tei:msIdentifier" mode="work_identifier">
    <xsl:param name="work"/>
    <identifier type="local">
      <!-- BUG somewhere - why isn't @xml:id recognised after msItem elements have been added? -->
      <xsl:apply-templates
          select="parent::tei:msDesc/@xml:id|parent::tei:msDesc/@id"
          mode="identifier"
          />
      <xsl:value-of select="$work"/>
    </identifier>
  </xsl:template>
  
  <xsl:template match="@xml:id|@id" mode="identifier">
    <xsl:value-of select="translate(., ' ', '')"/>
  </xsl:template>
  
  <xsl:template match="tei:*" mode="identifier">
    <xsl:if test="string(.)">
      <identifier type="{local-name()}">
        <xsl:apply-templates/>
      </identifier>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="tei:altIdentifier" mode="identifier">
    <xsl:if test="string(tei:idno)">
      <identifier type="{local-name()}">
        <xsl:apply-templates select="tei:idno"/>
      </identifier>
    </xsl:if>
  </xsl:template>
  
  <!-- location -->
  <xsl:template match="tei:msIdentifier" mode="location">
    <location>
      <!-- assume they are in reverse order -->
      <xsl:apply-templates select="tei:*[1]" mode="location"/>
    </location>
  </xsl:template>
  
  <xsl:template match="tei:country|tei:region|tei:settlement|tei:institution|tei:repository|tei:collection" mode="location">
    <!-- process next element before this one -->
    <xsl:apply-templates select="following-sibling::tei:*[1]" mode="location"/>
    
    <physicalLocation type="{local-name()}">
      <xsl:apply-templates/>
      
      <!-- add institution to collection -->
      <xsl:if test="local-name() = 'collection' and parent::tei:msIdentifier/tei:institution != ''">
        <xsl:value-of select="concat(' - ', parent::tei:msIdentifier/tei:institution)"/>
      </xsl:if>
    </physicalLocation>
  </xsl:template>
  
  <xsl:template match="tei:*" mode="location"/>
  
  <!-- access condition -->
  <xsl:template match="tei:availability" mode="access_condition">
    <accessCondition type="{@status}">
      <xsl:apply-templates/>
    </accessCondition>
  </xsl:template>
  
  <!-- part -->
  <xsl:template match="tei:msItem" mode="part">
    <xsl:variable name="id">
      <xsl:choose>
        <xsl:when test="@xml:id">
          <xsl:value-of select="@xml:id"/>
        </xsl:when>
        <xsl:when test="@id">
          <xsl:value-of select="@id"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    <part>
      <xsl:if test="$id">
        <xsl:attribute name="ID">
          <xsl:value-of select="$id"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates select="tei:locus" mode="part"/>
    </part>
  </xsl:template>
  
  <xsl:template match="tei:locus" mode="part">
    <extent>
      <xsl:apply-templates select="@from|@to" mode="part"/>
      <list>
        <xsl:apply-templates/>
      </list>
    </extent>
  </xsl:template>
  
  <xsl:template match="@from" mode="part">
    <start>
      <xsl:value-of select="."/>
    </start>
  </xsl:template>
  
  <xsl:template match="@to" mode="part">
    <end>
      <xsl:value-of select="."/>
    </end>
  </xsl:template>
  
  <!-- record info -->
  <xsl:template match="tei:publicationStmt" mode="record_info"/>
  
  <xsl:template match="tei:publisher" mode="record_info">
    <recordContentSource>
      <xsl:apply-templates/>
    </recordContentSource>
  </xsl:template>
  
  <xsl:template match="tei:date" mode="record_info">
    <recordCreationDate>
      <xsl:apply-templates/>
    </recordCreationDate>
  </xsl:template>
  
  <xsl:template match="@xml:lang">
    <xsl:copy-of select="."/>
  </xsl:template>
  
  <xsl:template match="@type">
    <xsl:attribute name="type">
      <xsl:choose>
        <xsl:when test=". = 'standard'">
          <xsl:text>uniform</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>alternative</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>
  </xsl:template>
  
  <!-- bibliographies are in MODS already, so just copy -->
  <xsl:template match="tei:bibl" mode="bibliography">
    <xsl:if test="tei:ref/@target != ''">
      <relatedItem otherType="bib" xlink:href="{tei:ref/@target}">
        <xsl:apply-templates 
            select="php:function('bibliographyFile', string(tei:ref/@target))/mods:*" 
            mode="bibliography"
            />
      </relatedItem>
    </xsl:if>
  </xsl:template>
  
  <!-- copy these bibliography elements -->
  <xsl:template match="mods:titleInfo|mods:name|mods:place|mods:publisher" mode="bibliography">
    <xsl:copy-of select="."/>
  </xsl:template>

  <!-- process a list of space delimited tokens -->
  <xsl:template name="tokens">
    <xsl:param name="list"/>
    
    <xsl:choose>
      <xsl:when test="contains($list, ' ')">
        <xsl:call-template name="token">
          <xsl:with-param name="token" select="substring-before($list, ' ')"/>
        </xsl:call-template>
        <xsl:call-template name="tokens">
          <xsl:with-param name="list" select="substring-after($list, ' ')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="token">
          <xsl:with-param name="token" select="$list"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- what to do with a token from @class -->
  <xsl:template name="token">
    <xsl:param name="token"/>
    
    <xsl:choose>
      <!-- #something points to element in same document -->
      <xsl:when test="starts-with($token, '#')">
        <xsl:variable name="id" select="substring-after($token, '#')"/>
        
        <classification authority="{id($id)/parent::tei:taxonomy/@xml:id}">
          <xsl:apply-templates select="id($id)"/>
        </classification>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <!-- load authority files in @class/@key attributes -->
  <xsl:template match="@*" mode="classification">
    <xsl:param name="depth" select="number(0)"/>
    
    <!-- where the element is -->
    <xsl:variable name="subtype">
      <xsl:choose>
        <xsl:when test="ancestor::tei:author or ancestor::mads:mads">
          <xsl:text>author</xsl:text>
        </xsl:when>
        <xsl:when test="ancestor::tei:note/parent::tei:msItem">
          <xsl:text>work</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="local-name(parent::*)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:for-each select="str:tokenize(., ' ')">
      <xsl:apply-templates select="exsl:node-set($external_docs)/descendant::mads:mads[@id = current()]" mode="related">
        <xsl:with-param name="type">authority</xsl:with-param>
        <xsl:with-param name="subtype" select="$subtype"/>
        <xsl:with-param name="depth" select="$depth"/>
      </xsl:apply-templates>
    </xsl:for-each>
  </xsl:template>
  
  <!-- don't process these bibliography elements -->
  <xsl:template match="mods:*" mode="bibliography"/>
  
</xsl:stylesheet>

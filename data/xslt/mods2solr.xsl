<?xml version="1.0" encoding="UTF-8"?><!-- -*- xml -*- -->
<xsl:stylesheet
    version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:mods="http://www.loc.gov/mods/v3"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    exclude-result-prefixes="mods xlink"
    >
  
  <xsl:strip-space elements="mods:*"/>

  
  <!--****** xslt/mods2solr.xsl
 * NAME
 * mods2solr.xsl
 * SYNOPSIS
 * Converts MODS XML to Solr XML.
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20120710
 * SEE ALSO
 *   * xslt/tei2mods.xsl
 ****-->
  
  <xsl:output
      method="xml"
      indent="yes"
      encoding="UTF-8"
      />
  
  <!-- what type of MODS document is being transformed -->
  <xsl:param name="docType"/>
  
  <xsl:template match="/">
    <add>
      <xsl:apply-templates/>
    </add>
  </xsl:template>
  
  <xsl:template match="mods:mods">
    <xsl:if test="$docType != 'bib' or descendant::mods:classification != ''">
      <doc>
        <!-- sort date -->
        <xsl:apply-templates 
            select="descendant::mods:*[self::mods:dateCreated or self::mods:dateOther][@point='start'][. != ''][1]"
            mode="sort_date"
            />
        
        <!-- everything but names and related items -->
        <xsl:apply-templates select="mods:*[local-name() != 'name' and local-name() != 'relatedItem']"/>
        
        <!-- primary names with Latin characters -->
        <xsl:apply-templates select="mods:name[@usage = 'primary' and (contains(@xml:lang, '-Latn-x-lc') or @xml:lang = 'eng' or @xml:lang = 'tur')]"/>
        <!-- primary names without Latin characters -->
        <xsl:apply-templates select="mods:name[@usage = 'primary' and not(contains(@xml:lang, '-Latn-x-lc') or @xml:lang = 'eng' or @xml:lang = 'tur')]"/>
        
        <!-- non primary names -->
        <xsl:apply-templates select="mods:name[not(@usage = 'primary')]"/>
        
        <!-- related items -->
        <xsl:apply-templates select="mods:relatedItem"/>
        
      </doc>
    </xsl:if>
  </xsl:template>

  <!-- TITLE -->
  <xsl:template match="mods:title|mods:subTitle">
    <!-- no titles from related documents -->
    <xsl:if test="not(ancestor::mods:relatedItem) and generate-id(parent::mods:titleInfo) = generate-id(ancestor::mods:mods/mods:titleInfo[1])">

      <!-- need to rewrite subTitle to sub_title -->
      <xsl:variable name="field">
        <xsl:choose>
          <xsl:when test="local-name() = 'subTitle'">
            <xsl:text>sub_title</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="local-name()"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <!-- doc type - either from in MODS document or use global param -->
      <xsl:variable name="doc_type">
        <xsl:choose>
          <xsl:when test="ancestor::mods:mods/mods:typeOfResource/@displayLabel">
            <xsl:value-of select="ancestor::mods:mods/mods:typeOfResource/@displayLabel"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$docType"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      
      <field>
        <xsl:call-template name="name">
          <xsl:with-param name="lang" select="@xml:lang"/>
          <xsl:with-param name="field" select="$field"/>
          <xsl:with-param name="type" select="$doc_type"/>
        </xsl:call-template>
        <xsl:apply-templates/>
      </field>
      
      <!-- use transliterated title for sorting -->
      <xsl:if test="self::mods:title and contains(@xml:lang, 'Latn-x-lc')">
        <field name="title_sort">
          <xsl:apply-templates/>
        </field>
      </xsl:if>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="mods:relatedItem/mods:titleInfo[@usage='primary']/mods:title">
    <!-- doc type - either from in MODS document or use global param -->
    <xsl:variable name="doc_type">
      <xsl:choose>
        <xsl:when test="ancestor::mods:mods/mods:typeOfResource/@displayLabel">
          <xsl:value-of select="ancestor::mods:mods/mods:typeOfResource/@displayLabel"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$docType"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <field name="{$doc_type}_auth_title">
      <xsl:apply-templates/>
    </field>
  </xsl:template>
  
  <!-- NAME -->
  <xsl:template match="mods:name">
    <!-- doc type - either from in MODS document or use global param -->
    <xsl:variable name="doc_type">
      <xsl:choose>
        <xsl:when test="ancestor::mods:mods/mods:typeOfResource/@displayLabel">
          <xsl:value-of select="ancestor::mods:mods/mods:typeOfResource/@displayLabel"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$docType"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- role -->
    <xsl:variable name="role">
      <xsl:choose>
        <xsl:when test="mods:role">
          <xsl:apply-templates select="mods:role"/>
        </xsl:when>
        <xsl:when test="ancestor::mods:mods/mods:name[@valueURI = current()/parent::mods:relatedItem/@xlink:href]/mods:role">
          <xsl:value-of select="ancestor::mods:mods/mods:name[@valueURI = current()/parent::mods:relatedItem/@xlink:href]/mods:role"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    
    <field>
      <xsl:call-template name="name">
        <xsl:with-param name="lang" select="@xml:lang"/>
        <xsl:with-param name="field">
          <xsl:choose>
            <!-- have role -->
            <xsl:when test="$role != ''">
              <xsl:value-of select="$role"/>
            </xsl:when>
            <!-- name in authority file -->
            <xsl:when test="$doc_type = 'auth'">
              <xsl:text>variant_person</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>name</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:with-param>
        <xsl:with-param name="type" select="$doc_type"/>
      </xsl:call-template>
      <xsl:choose>
        <!-- use displayForm if present -->
        <xsl:when test="mods:displayForm">
          <xsl:apply-templates select="mods:displayForm"/>
        </xsl:when>
        <!-- otherwise use namePart elements -->
        <xsl:otherwise>
          <xsl:apply-templates select="mods:namePart"/>
        </xsl:otherwise>
      </xsl:choose>
    </field>
    
    <!-- key for person -->
    <xsl:if test="@valueURI and ($doc_type = 'ms' or $doc_type = 'work') and not(preceding-sibling::mods:name/@valueURI = current()/@valueURI)">
      <xsl:choose>
        <xsl:when test="$role != ''">
          <!-- auth id -->
          <field name="{$doc_type}_auth_{$role}_id">
            <xsl:value-of select="@valueURI"/>
          </field>
        </xsl:when>
        <xsl:otherwise>
          <field name="{$doc_type}_auth_person_id">
            <xsl:value-of select="@valueURI"/>
          </field>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    
    <!-- name for facet -->
    <xsl:if test="@usage = 'all' and $role != ''">
      <!-- name for facet -->
      <field name="{$doc_type}_{$role}_s">
        <xsl:choose>
          <!-- use displayForm if present -->
          <xsl:when test="mods:displayForm">
            <xsl:apply-templates select="mods:displayForm"/>
          </xsl:when>
          <!-- otherwise use namePart elements -->
          <xsl:otherwise>
            <xsl:apply-templates select="mods:namePart"/>
          </xsl:otherwise>
        </xsl:choose>
        <!--xsl:apply-templates select="mods:displayForm"/-->
      </field>
      <field name="{$doc_type}_{$role}_main">
        <xsl:choose>
          <!-- use displayForm if present -->
          <xsl:when test="mods:displayForm">
            <xsl:apply-templates select="mods:displayForm"/>
          </xsl:when>
          <!-- otherwise use namePart elements -->
          <xsl:otherwise>
            <xsl:apply-templates select="mods:namePart"/>
          </xsl:otherwise>
        </xsl:choose>
        <!--xsl:apply-templates select="mods:displayForm"/-->
      </field>
    </xsl:if>
    
    <!-- authorised name in authority file -->
    <xsl:if test="$doc_type = 'auth' and @usage = 'authority'">
      <field name="auth_auth_person">
        <xsl:apply-templates/>
      </field>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="mods:namePart">
    <xsl:apply-templates/>
    <xsl:text> </xsl:text>
  </xsl:template>
  
  <xsl:template match="mods:role">
    <xsl:choose>
      <!-- use roleTerm if present -->
      <xsl:when test="mods:roleTerm">
        <xsl:apply-templates select="mods:roleTerm"/>
      </xsl:when>
      <!-- use role value -->
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="mods:roleTerm">
    <!-- rewrite roleTerm where necessary -->
    <xsl:choose>
      <xsl:when test=".='aut'">
        <xsl:text>author</xsl:text>
      </xsl:when>
      <xsl:when test=".='edt'">
        <xsl:text>editor</xsl:text>
      </xsl:when>
      <xsl:when test=".='trl'">
        <xsl:text>translator</xsl:text>
      </xsl:when>
      <xsl:when test=".='ctb'">
        <xsl:text>contributor</xsl:text>
      </xsl:when>
      <xsl:when test=".='pbd'">
        <xsl:text>designer</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- TYPE OF RESOURCE -->
  <xsl:template match="mods:typeOfResource">
    <field name="doc_type">
      <xsl:choose>
        <xsl:when test="@displayLabel">
          <xsl:value-of select="@displayLabel"/>
        </xsl:when>
        <xsl:when test="../mods:genre[@type='local']">
          <xsl:value-of select="../mods:genre[@type='local']"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$docType"/>
        </xsl:otherwise>
      </xsl:choose>
    </field>
    
    <!-- type of auth file -->
    <xsl:if test="@usage != ''">
      <field name="auth_type">
        <xsl:value-of select="@usage"/>
      </field>
    </xsl:if>
  </xsl:template>

  <!-- ORIGIN INFO -->
  <xsl:template match="mods:dateCreated[@point] | mods:dateOther[@point]">
    <xsl:variable name="date">
      <xsl:call-template name="date">
        <xsl:with-param name="text" select="."/>
        <xsl:with-param name="point">
          <xsl:value-of select="@point"/>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:variable>

    <!-- doc type - either from in MODS document or use global param -->
    <xsl:variable name="doc_type">
      <xsl:choose>
        <xsl:when test="ancestor::mods:mods/mods:typeOfResource/@displayLabel">
          <xsl:value-of select="ancestor::mods:mods/mods:typeOfResource/@displayLabel"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$docType"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="type">
      <xsl:choose>
        <xsl:when test="self::mods:dateCreated">
          <xsl:text>created</xsl:text>
        </xsl:when>
        <xsl:when test="self::mods:dateOther and @type != ''">
          <xsl:value-of select="@type"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>created</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <field name="{$doc_type}_date_{$type}_{@point}">
      <xsl:value-of select="$date"/>
    </field>
  </xsl:template>
  
  <xsl:template match="mods:dateCreated[not(@point)] | mods:dateOther[not(@point)]">
    <!-- doc type - either from in MODS document or use global param -->
    <xsl:variable name="doc_type">
      <xsl:choose>
        <xsl:when test="ancestor::mods:mods/mods:typeOfResource/@displayLabel">
          <xsl:value-of select="ancestor::mods:mods/mods:typeOfResource/@displayLabel"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$docType"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="type">
      <xsl:choose>
        <xsl:when test="self::mods:dateCreated">
          <xsl:text>created</xsl:text>
        </xsl:when>
        <xsl:when test="self::mods:dateOther and @type != ''">
          <xsl:value-of select="@type"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>created</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <field name="{$doc_type}_date_{$type}">
      <xsl:call-template name="date">
        <xsl:with-param name="text" select="."/>
        <xsl:with-param name="calendar" select="@encoding"/>
      </xsl:call-template>
    </field>
  </xsl:template>
  
  <!-- some copyright dates are ranges YYYY-YYYY -->
  <xsl:template match="mods:copyrightDate">
    <!-- doc type - either from in MODS document or use global param -->
    <xsl:variable name="doc_type">
      <xsl:choose>
        <xsl:when test="ancestor::mods:mods/mods:typeOfResource/@displayLabel">
          <xsl:value-of select="ancestor::mods:mods/mods:typeOfResource/@displayLabel"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$docType"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:choose>
      <xsl:when test="translate(., '0123456789', '__________') = '____-____'">
        <field name="{$doc_type}_date_created_start">
          <xsl:call-template name="date">
            <xsl:with-param name="text" select="substring-before(., '-')"/>
            <xsl:with-param name="point">start</xsl:with-param>
          </xsl:call-template>
        </field>
        <field name="{$doc_type}_date_created_end">
          <xsl:call-template name="date">
            <xsl:with-param name="text" select="substring-after(., '-')"/>
            <xsl:with-param name="point">end</xsl:with-param>
          </xsl:call-template>
        </field>
      </xsl:when>
      <xsl:otherwise>
        <field name="{$doc_type}_date_created">
          <xsl:call-template name="date">
            <xsl:with-param name="text" select="."/>
          </xsl:call-template>
        </field>
        <field name="{$doc_type}_date_created_start">
          <xsl:call-template name="date">
            <xsl:with-param name="text" select="."/>
            <xsl:with-param name="point">start</xsl:with-param>
          </xsl:call-template>
        </field>
        <field name="{$doc_type}_date_created_end">
          <xsl:call-template name="date">
            <xsl:with-param name="text" select="."/>
            <xsl:with-param name="point">end</xsl:with-param>
          </xsl:call-template>
        </field>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- date for sorting -->
  <xsl:template match="mods:dateCreated | mods:dateOther" mode="sort_date">
    <field name="date_sort">
      <xsl:call-template name="date">
        <xsl:with-param name="text" select="."/>
        <xsl:with-param name="point">
          <xsl:value-of select="@point"/>
        </xsl:with-param>
      </xsl:call-template>
    </field>
  </xsl:template>
  
  <!-- PHYSICAL DESCRIPTION -->
  <xsl:template match="mods:physicalDescription">
    <xsl:apply-templates select="mods:extent[@script]"/>
  </xsl:template>
  
  <xsl:template match="mods:extent[@script]">
    <!-- doc type - either from in MODS document or use global param -->
    <xsl:variable name="doc_type">
      <xsl:choose>
        <xsl:when test="ancestor::mods:mods/mods:typeOfResource/@displayLabel">
          <xsl:value-of select="ancestor::mods:mods/mods:typeOfResource/@displayLabel"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$docType"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <field name="{$doc_type}_script">
      <xsl:value-of select="@script"/>
    </field>
  </xsl:template>
  
  <!-- TABLE OF CONTENTS -->
  <xsl:template match="mods:tableOfContents[. != '']">
    <!-- doc type - either from in MODS document or use global param -->
    <xsl:variable name="doc_type">
      <xsl:choose>
        <xsl:when test="ancestor::mods:mods/mods:typeOfResource/@displayLabel">
          <xsl:value-of select="ancestor::mods:mods/mods:typeOfResource/@displayLabel"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$docType"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <field name="{$doc_type}_table_of_contents">
      <xsl:apply-templates/>
    </field>
  </xsl:template>
  
  <!-- not interested (here) -->
  <xsl:template match="mods:genre"/>
  
  <!-- LANGUAGE -->
  <xsl:template match="mods:language">
    <!-- doc type - either from in MODS document or use global param -->
    <xsl:variable name="doc_type">
      <xsl:choose>
        <xsl:when test="ancestor::mods:mods/mods:typeOfResource/@displayLabel">
          <xsl:value-of select="ancestor::mods:mods/mods:typeOfResource/@displayLabel"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$docType"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:if test="@lang and not(following-sibling::mods:language/@lang=current()/@lang)">
      <field name="{$doc_type}_language">
        <xsl:value-of select="@lang"/>
      </field>
    </xsl:if>
  </xsl:template>
  
  <!-- NOTE -->
  <xsl:template match="mods:note">
    <!-- doc type - either from in MODS document or use global param -->
    <xsl:variable name="doc_type">
      <xsl:choose>
        <xsl:when test="ancestor::mods:mods/mods:typeOfResource/@displayLabel">
          <xsl:value-of select="ancestor::mods:mods/mods:typeOfResource/@displayLabel"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$docType"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <!-- optional @type -->
    <xsl:variable name="type">
      <xsl:if test="@type != ''">
        <xsl:value-of select="concat('_', @type)"/>
      </xsl:if>
    </xsl:variable>
    
    <!-- output note in field -->
    <field name="{$doc_type}{$type}_note">
      <xsl:choose>
        <xsl:when test="@type = 'work_html'">
          <xsl:copy-of select="*|text()"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates/>
        </xsl:otherwise>
      </xsl:choose>
    </field>
  </xsl:template>

  <!-- CLASSIFICATION -->
  <xsl:template match="mods:classification">
    <!-- doc type - either from in MODS document or use global param -->
    <xsl:variable name="doc_type">
      <xsl:choose>
        <xsl:when test="ancestor::mods:mods/mods:typeOfResource/@displayLabel">
          <xsl:value-of select="ancestor::mods:mods/mods:typeOfResource/@displayLabel"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$docType"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <!-- bibliograpic items use classification for ID -->
    <xsl:choose>
      <xsl:when test="$docType = 'bib'">
        <field name="id">
          <xsl:value-of select="translate(., ' ', '')"/>
        </field>
      </xsl:when>
      <xsl:otherwise>
        <field name="{$doc_type}_classification">
          <xsl:apply-templates/>
        </field>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="mods:identifier">
    <!-- doc type - either from in MODS document or use global param -->
    <xsl:variable name="doc_type">
      <xsl:choose>
        <xsl:when test="ancestor::mods:mods/mods:typeOfResource/@displayLabel">
          <xsl:value-of select="ancestor::mods:mods/mods:typeOfResource/@displayLabel"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$docType"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:if test="@type != 'isbn'">
      <field name="{$doc_type}_identifier_{@type}">
        <xsl:apply-templates/>
      </field>
    </xsl:if>
  </xsl:template>
  
  <!-- IDENTIFIER -->
  <xsl:template match="mods:identifier[@type='local']">
    <xsl:variable name="id" select="translate(., ' ', '')"/>

    <!-- doc type - either from in MODS document or use global param -->
    <xsl:variable name="doc_type">
      <xsl:choose>
        <xsl:when test="ancestor::mods:mods/mods:typeOfResource/@displayLabel">
          <xsl:value-of select="ancestor::mods:mods/mods:typeOfResource/@displayLabel"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$docType"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <field name="{$doc_type}_id">
      <xsl:value-of select="$id"/>
    </field>

    <field name="id">
      <xsl:value-of select="$id"/>
    </field>
    
    <xsl:if test="contains(., ';')">
      <field name="{$doc_type}_parent_id">
        <xsl:value-of select="substring-before($id, ';')"/>
      </field>
    </xsl:if>
  </xsl:template>
  
  <!-- PHYSICAL LOCATION -->
  <xsl:template match="mods:physicalLocation[. != '']">
    <!-- doc type - either from in MODS document or use global param -->
    <xsl:variable name="doc_type">
      <xsl:choose>
        <xsl:when test="ancestor::mods:mods/mods:typeOfResource/@displayLabel">
          <xsl:value-of select="ancestor::mods:mods/mods:typeOfResource/@displayLabel"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$docType"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <field>
      <xsl:attribute name="name">
        <xsl:value-of select="concat($doc_type, '_physical_location_', @type)"/>
      </xsl:attribute>
      <xsl:apply-templates/>
    </field>
  </xsl:template>
  
  <!-- ignore URLs -->
  <xsl:template match="mods:url"/>

  <!-- MS item PARTs -->
  <xsl:template match="mods:part">
    <!-- doc type - either from in MODS document or use global param -->
    <xsl:variable name="doc_type">
      <xsl:choose>
        <xsl:when test="ancestor::mods:mods/mods:typeOfResource/@displayLabel">
          <xsl:value-of select="ancestor::mods:mods/mods:typeOfResource/@displayLabel"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$docType"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:if test="@ID != ''">
      <field name="{$doc_type}_item_id">
        <xsl:value-of select="@ID"/>
      </field>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="mods:recordContentSource">
    <!-- doc type - either from in MODS document or use global param -->
    <xsl:variable name="doc_type">
      <xsl:choose>
        <xsl:when test="ancestor::mods:mods/mods:typeOfResource/@displayLabel">
          <xsl:value-of select="ancestor::mods:mods/mods:typeOfResource/@displayLabel"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$docType"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <field name="{$doc_type}_holding_institution">
      <xsl:apply-templates/>
    </field>
  </xsl:template>
  
  <xsl:template match="mods:recordCreationDate">
    <!-- doc type - either from in MODS document or use global param -->
    <xsl:variable name="doc_type">
      <xsl:choose>
        <xsl:when test="ancestor::mods:mods/mods:typeOfResource/@displayLabel">
          <xsl:value-of select="ancestor::mods:mods/mods:typeOfResource/@displayLabel"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$docType"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <field name="{$doc_type}_record_creation_date">
      <xsl:call-template name="date">
        <xsl:with-param name="text" select="."/>
      </xsl:call-template>
    </field>
  </xsl:template>
  
  <!-- SUBJECT -->
  <xsl:template match="mods:subject">
    <xsl:apply-templates/>
  </xsl:template>
  
  <xsl:template match="mods:geographic|mods:topic|mods:temporal">
    <xsl:param name="subtype"/>
    
    <!-- doc type - either from in MODS document or use global param -->
    <xsl:variable name="doc_type">
      <xsl:choose>
        <xsl:when test="ancestor::mods:mods/mods:typeOfResource/@displayLabel">
          <xsl:value-of select="ancestor::mods:mods/mods:typeOfResource/@displayLabel"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$docType"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <field name="{$doc_type}_variant_{local-name()}">
      <xsl:apply-templates/>
    </field>
    
    <xsl:if test="@usage = 'authority'">
      <field name="{$doc_type}_auth_{local-name()}">
        <xsl:apply-templates/>
      </field>
    </xsl:if>
    
    <!-- special fields for places, to indicate where they were refered to -->
    <xsl:if test="self::mods:geographic">
      <xsl:choose>
        <xsl:when test="ancestor::mods:relatedItem/@type = 'work'">
          <field name="work_note_place">
            <xsl:apply-templates/>
          </field>
        </xsl:when>
        <xsl:when test="ancestor::mods:relatedItem/@type = 'author'">
          <field name="author_note_place">
            <xsl:apply-templates/>
          </field>
        </xsl:when>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  
  <!-- ORIGIN INFO -->
  <xsl:template match="mods:originInfo">
    <xsl:apply-templates select="mods:dateCreated|mods:copyrightDate|mods:dateOther"/>
    <xsl:apply-templates select="mods:publisher"/>
    <xsl:apply-templates select="mods:place"/>
  </xsl:template>
  
  <xsl:template match="mods:publisher">
    <!-- doc type - either from in MODS document or use global param -->
    <xsl:variable name="doc_type">
      <xsl:choose>
        <xsl:when test="ancestor::mods:mods/mods:typeOfResource/@displayLabel">
          <xsl:value-of select="ancestor::mods:mods/mods:typeOfResource/@displayLabel"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$docType"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <field name="{$doc_type}_publisher">
      <xsl:apply-templates/>
    </field>
  </xsl:template>
  
  <xsl:template match="mods:place[not(parent::mods:originInfo)]">
    <!-- doc type - either from in MODS document or use global param -->
    <xsl:variable name="doc_type">
      <xsl:choose>
        <xsl:when test="ancestor::mods:mods/mods:typeOfResource/@displayLabel">
          <xsl:value-of select="ancestor::mods:mods/mods:typeOfResource/@displayLabel"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$docType"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <field name="{$doc_type}_place">
      <xsl:apply-templates/>
    </field>
  </xsl:template>
  
  <xsl:template match="mods:originInfo/mods:place[mods:placeTerm/@type='text']">
    <!-- doc type - either from in MODS document or use global param -->
    <xsl:variable name="doc_type">
      <xsl:choose>
        <xsl:when test="ancestor::mods:mods/mods:typeOfResource/@displayLabel">
          <xsl:value-of select="ancestor::mods:mods/mods:typeOfResource/@displayLabel"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$docType"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="eventType">
      <xsl:if test="parent::mods:originInfo/@eventType != ''">
        <xsl:value-of select="concat('_', parent::mods:originInfo/@eventType)"/>
      </xsl:if>
    </xsl:variable>
    
    <field name="{$doc_type}{$eventType}_place">
      <xsl:apply-templates/>
    </field>
  </xsl:template>

  <!--xsl:template match="mods:originInfo/mods:place[mods:placeTerm/@type='code' and /mods:mods/mods:relatedItem/@xlink:href = mods:placeTerm/@valueURI]">
    <xsl:if test="/mods:mods/mods:relatedItem[@xlink:href=current()/mods:placeTerm/@valueURI]/mods:subject[1]/mods:geographic[1] != ''">
      <field name="creation_place_f">
        <xsl:value-of select="/mods:mods/mods:relatedItem[@xlink:href=current()/mods:placeTerm/@valueURI]/mods:subject[1]/mods:geographic[1]"/>
      </field>
      <field name="creation_place_f_alpha">
        <xsl:value-of select="/mods:mods/mods:relatedItem[@xlink:href=current()/mods:placeTerm/@valueURI]/mods:subject[1]/mods:geographic[1]"/>
      </field>
    </xsl:if>
  </xsl:template-->
  
  <!-- RELATED ITEM -->
  <xsl:template match="mods:relatedItem">
    <!-- doc type - either from in MODS document or use global param -->
    <xsl:variable name="doc_type">
      <xsl:choose>
        <xsl:when test="ancestor::mods:mods/mods:typeOfResource/@displayLabel">
          <xsl:value-of select="ancestor::mods:mods/mods:typeOfResource/@displayLabel"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$docType"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:choose>
      <!-- pass through relatedItems in MODS bib files -->
      <xsl:when test="$doc_type = 'bib'">
        <xsl:apply-templates/>
      </xsl:when>
      
      <xsl:when test="@otherType='bib'">
        <xsl:for-each select="descendant-or-self::mods:*[not(mods:*) and string(.) and not(self::mods:roleTerm)]">
          <field name="ms_bib">
            <xsl:apply-templates/>
          </field>
        </xsl:for-each>
      </xsl:when>
      <xsl:when test="not(preceding-sibling::mods:relatedItem[@xlink:href=current()/@xlink:href])">
        <xsl:variable name="type">
          <xsl:choose>
            <xsl:when test="descendant::mods:name">
              <xsl:text>person</xsl:text>
            </xsl:when>
            <xsl:when test="descendant::mods:topic">
              <xsl:text>topic</xsl:text>
            </xsl:when>
            <xsl:when test="descendant::mods:temporal">
              <xsl:text>temporal</xsl:text>
            </xsl:when>
            <xsl:when test="descendant::mods:geographic">
              <xsl:text>geographic</xsl:text>
            </xsl:when>
            <xsl:when test="descendant::mods:titleInfo">
              <xsl:text>title</xsl:text>
            </xsl:when>
          </xsl:choose>
        </xsl:variable>
        
        <xsl:if test="$type != ''">
          <field name="{$doc_type}_auth_{$type}_id">
            <xsl:value-of select="@xlink:href"/>
          </field>
          <xsl:apply-templates/>
        </xsl:if>
        
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <!-- ACCESS CONDITIONS -->
  <xsl:template match="mods:accessCondition">
    <!-- doc type - either from in MODS document or use global param -->
    <xsl:variable name="doc_type">
      <xsl:choose>
        <xsl:when test="ancestor::mods:mods/mods:typeOfResource/@displayLabel">
          <xsl:value-of select="ancestor::mods:mods/mods:typeOfResource/@displayLabel"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$docType"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:if test="@type">
      <field name="{$doc_type}_access_type">
        <xsl:value-of select="@type"/>
      </field>
    </xsl:if>
    <xsl:if test=". != ''">
      <field name="{ancestor::mods:mods/mods:typeOfResource/@displayLabel}_access">
        <xsl:apply-templates/>
      </field>
    </xsl:if>
  </xsl:template>
  
  <!-- ABSTRACT - put in note field -->
  <xsl:template match="mods:abstract">
    <!-- doc type - either from in MODS document or use global param -->
    <xsl:variable name="doc_type">
      <xsl:choose>
        <xsl:when test="ancestor::mods:mods/mods:typeOfResource/@displayLabel">
          <xsl:value-of select="ancestor::mods:mods/mods:typeOfResource/@displayLabel"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$docType"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:if test=". != ''">
      <field name="{$doc_type}_note">
        <xsl:value-of select="."/>
      </field>
    </xsl:if>
  </xsl:template>
    
  <!-- convert dates to Solr format -->
  <xsl:template name="date">
    <xsl:param name="text"/>
    <xsl:param name="point"/>
    <xsl:param name="calendar"/>
    
    <xsl:variable name="mask" select="translate($text, '0123456789', '__________')"/>
    <xsl:variable name="punc" select="translate($mask, '_', '')"/>

    <xsl:variable name="format">
      <xsl:choose>
        <xsl:when test="$point = 'start'">
          <xsl:text>0000-01-01T00:00:00Z</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>0000-12-31T23:59:59Z</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:choose>
      <!-- just year, but have point (start/end) -->
      <xsl:when test="$mask = '____' and $point != ''">
        <xsl:value-of select="concat($text, substring($format, 5))"/>
      </xsl:when>
      <!-- probably have date as there are 2 delimiting characters -->
      <xsl:when test="string-length($punc) = 2">
        <xsl:variable name="year" select="format-number(substring-before($text, substring($punc, 1, 1)), '0000')"/>
        <xsl:variable name="month" select="format-number(substring-before(substring-after($text, substring($punc, 1, 1)), substring($punc, 2, 1)), '00')"/>
        <xsl:variable name="day" select="format-number(substring-after(substring-after($text, substring($punc, 1, 1)), substring($punc, 2, 1)), '00')"/>
        
        <xsl:value-of select="concat($year, substring($format, 5, 1), $month, substring($format, 8, 1), $day, substring($format, 11))"/>
      </xsl:when>
      <!-- TODO other input date formats -->
      <xsl:otherwise>
        <xsl:value-of select="$text"/>
        <xsl:call-template name="calendar">
          <xsl:with-param name="calendar" select="$calendar"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- calendar -->
  <xsl:template name="calendar">
    <xsl:param name="calendar"/>
    <xsl:choose>
      <xsl:when test="$calendar = 'Hijri-qamari'">
        <xsl:text> (AH)</xsl:text>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="text()">
    <xsl:value-of select="normalize-space(.)"/>
  </xsl:template>

  <!-- generate @name attribute -->
  <xsl:template name="name">
    <xsl:param name="lang"/>
    <xsl:param name="field"/>
    <xsl:param name="type"/>
    
    <xsl:attribute name="name">
      <xsl:if test="$type != ''">
        <xsl:value-of select="concat($type, '_')"/>
      </xsl:if>
      
      <xsl:value-of select="$field"/>
      
      <xsl:if test="$lang != ''">
        <xsl:value-of select="concat('_', $lang)"/>
      </xsl:if>
    </xsl:attribute>
  </xsl:template>
  
  
</xsl:stylesheet>

<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:php="http://php.net/xsl"
    xmlns:mads="http://www.loc.gov/mads/v2"
    xmlns="http://www.loc.gov/mods/v3"
    xmlns:mods="http://www.loc.gov/mods/v3"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xsl:extension-element-prefixes="php"
    exclude-result-prefixes="xsl tei php mads mods xlink"
    >

  <!--****** xslt/teiRecord2mods.xsl
 * NAME
 * teiRecord2mods.xsl
 * SYNOPSIS
 * Converts TEI record data to MODS XML. The purpose of this is to convert TEI to Solr.
 * TEI is rich and arbitrarily nested, so converting it first to a slightly simpler format (MODS), and then to the very simple and flat format (Solr) is sensible.
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20120710
 * SEE ALSO
 *   * xslt/mods2solr.xsl
 ****-->
  
  <xsl:output
      method="xml"
      indent="yes"
      encoding="UTF-8"
      />
  
  <!-- true when reindexing -->
  <xsl:param name="reindex"/>
  
  <xsl:template match="tei:TEI">
    <mods>
      <!-- record title information -->
      <xsl:apply-templates select="tei:teiHeader/tei:fileDesc/tei:titleStmt"/>
      <!-- record publication information -->
      <xsl:apply-templates select="tei:teiHeader/tei:fileDesc/tei:publicationStmt"/>
      <!-- record revision information -->
      <xsl:apply-templates select="tei:teiHeader/tei:revisionDesc"/>
      <!-- record identification -->
      <xsl:apply-templates select="tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc"/>
      <!-- type of resource - record -->
      <typeOfResource displayLabel="record" usage="primary">text</typeOfResource>
    </mods>
  </xsl:template>

  <!-- record title -->
  <xsl:template match="tei:title[string(.)]">
    <titleInfo>
      <title>
        <xsl:apply-templates/>
      </title>
    </titleInfo>
  </xsl:template>
  
  <!-- funder -->
  <xsl:template match="tei:funder">
    <name type="corporate">
      <namePart>
        <xsl:apply-templates/>
      </namePart>
      <role>
        <roleTerm>funder</roleTerm>
      </role>
    </name>
  </xsl:template>
  
  <!-- principal -->
  <xsl:template match="tei:principal">
    <name type="personal">
      <namePart>
        <xsl:apply-templates/>
      </namePart>
      <role>
        <roleTerm>principal</roleTerm>
      </role>
    </name>
  </xsl:template>

  <!-- publication -->
  <xsl:template match="tei:publicationStmt">
    <originInfo>
      <xsl:apply-templates/>
    </originInfo>
  </xsl:template>

  <!-- place of publication -->
  <xsl:template match="tei:pubPlace">
    <place>
      <placeTerm>
        <xsl:apply-templates/>
      </placeTerm>
    </place>
  </xsl:template>
  
  <xsl:template match="tei:*[parent::tei:address/parent::tei:pubPlace]">
    <xsl:apply-templates/>
    <xsl:if test="following-sibling::tei:*">
      <xsl:text>, </xsl:text>
    </xsl:if>
  </xsl:template>
  
  <!-- date record created -->
  <xsl:template match="tei:date[parent::tei:publicationStmt]">
    <dateCreated>
      <xsl:apply-templates/>
    </dateCreated>
  </xsl:template>
  
  <!-- publisher of record -->
  <xsl:template match="tei:publisher">
    <publisher>
      <xsl:apply-templates/>
    </publisher>
  </xsl:template>
  
  <!-- don't use publisher idno -->
  <xsl:template match="tei:idno[parent::tei:publicationStmt]"/>
  
  <!-- person who made a change to the record -->
  <xsl:template match="tei:persName[parent::tei:change]">
    <name type="personal">
      <namePart>
        <xsl:apply-templates/>
      </namePart>
      <role>
        <roleTerm>
          <xsl:choose>
            <!-- not first change, so person is contributor -->
            <xsl:when test="parent::tei:change/preceding-sibling::tei:change">
              <xsl:text>contributor</xsl:text>
            </xsl:when>
            <!-- first change, so person is creator -->
            <xsl:otherwise>
              <xsl:text>creator</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </roleTerm>
      </role>
    </name>
  </xsl:template>
  
  <!-- record identifier -->
  <xsl:template match="tei:msDesc">
    <identifier type="local">
      <xsl:value-of select="concat(@xml:id, '_record')"/>
    </identifier>
    <relatedItem xlink:href="{@xml:id}" displayLabel="ms"/>
  </xsl:template>

  <!-- tidy up white space a bit -->
  <xsl:template match="text()">
    <xsl:value-of select="normalize-space(.)"/>
  </xsl:template>
  
</xsl:stylesheet>

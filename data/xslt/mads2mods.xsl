<?xml version="1.0" encoding="UTF-8"?><!-- -*- xml -*- -->
<xsl:stylesheet
		version="1.0" 
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:tei="http://www.tei-c.org/ns/1.0"
		xmlns:php="http://php.net/xsl"
		xmlns:mads="http://www.loc.gov/mads/v2"
		xmlns="http://www.loc.gov/mods/v3"
		xmlns:mods="http://www.loc.gov/mods/v3"
		xmlns:xlink="http://www.w3.org/1999/xlink"
		xmlns:exsl="http://exslt.org/common"
		xsl:extension-element-prefixes="php exsl"
		exclude-result-prefixes="tei php mads"
		>

	<!--****** xslt/mads2mods.xsl
 * NAME
 * mads2mods.xsl
 * SYNOPSIS
 * Templates for converting MADS to MODS, included from teiMs2mods.xsl.
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20120710
 * SEE ALSO
 *   * xslt/teiMs2mods.xsl
 ****-->
	
	<!-- MADS records can contain tei:note elements, which can refer to other MADS records. -->
	<!-- We want MADS records which are mentioned in notes which are in MADS records mentioned in TEI documents. -->
	<!-- But we don't want anything further removed. -->
	<xsl:variable name="depth_cutoff" select="number(2)"/>
	
	<xsl:template match="mads:mads">
		<mods>
			<xsl:apply-templates/>
			
			<typeOfResource displayLabel="auth">
				<!-- subtype of auth resource -->
				<xsl:attribute name="usage">
					<xsl:choose>
						<xsl:when test="mads:authority/mads:name">
							<xsl:text>person</xsl:text>
						</xsl:when>
						<xsl:when test="mads:authority/mads:geographic">
							<xsl:text>place</xsl:text>
						</xsl:when>
						<xsl:when test="mads:authority/mads:topic">
							<xsl:text>sh</xsl:text>
						</xsl:when>
					</xsl:choose>
				</xsl:attribute>
				<xsl:text>text</xsl:text>
			</typeOfResource>
			
			<xsl:apply-templates select="exsl:node-set($external_docs)/descendant::mads:mads" mode="related"/>

		</mods>
	</xsl:template>

	<!-- wrap children of mads:mads in mods:relatedItem -->
	<xsl:template match="mads:mads" mode="related">
		<xsl:param name="type"/>
		<xsl:param name="subtype"/>
		<xsl:param name="depth" select="number(0)"/>
		
		<!-- only process related items which haven't come from a note which came from an item which came from a note -->
		<xsl:if test="$depth &lt; $depth_cutoff">
			<relatedItem displayLabel="{$type}" type="{$subtype}">
				<!-- use mads:identifier to create xlink:href -->
				<xsl:apply-templates select="mads:identifier" mode="xlink"/>
				<!-- don't want to include mads:identifier here -->
				<xsl:apply-templates select="mads:*[local-name() != 'identifier']">
					<xsl:with-param name="depth" select="$depth"/>
				</xsl:apply-templates>
			</relatedItem>
		</xsl:if>
	</xsl:template>

	<!-- names found in MADS documents -->
	<xsl:template match="mads:name">
		<xsl:variable name="usage">
			<xsl:choose>
				<xsl:when test="ancestor::mads:authority">
					<xsl:text>authority</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>variant</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:if test="$usage = 'authority'">
			<titleInfo>
				<title>
					<xsl:value-of select="concat(mads:namePart[@type='termsOfAddress'], ' ', mads:namePart[not(@type)], ' ', mads:namePart[@type='date'])"/>
				</title>
			</titleInfo>
		</xsl:if>
		
		<name usage="{$usage}">
			<xsl:apply-templates/>
		</name>
	</xsl:template>
	
	<xsl:template match="mads:namePart">
		<xsl:choose>
			<xsl:when test=". = ''"/>
			<xsl:when test="@type = 'termsOfAddress'">
				<namePart type="termsOfAddress">
					<xsl:apply-templates/>
				</namePart>
				<xsl:text> </xsl:text>
			</xsl:when>
			<xsl:when test="@type = 'date'">
				<xsl:text> </xsl:text>
				<namePart type="date">
					<xsl:apply-templates/>
				</namePart>
			</xsl:when>
			<xsl:when test="not(@type)">
				<displayForm>
					<xsl:apply-templates/>
				</displayForm>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	
	<!-- subject headings found in MADS documents -->
	<xsl:template match="mads:geographic">
		<subject>
			<geographic>
				<xsl:if test="ancestor::mads:authority">
					<xsl:attribute name="usage">authority</xsl:attribute>
				</xsl:if>
				<xsl:apply-templates/>
			</geographic>
		</subject>
		<!-- use authority as title -->
		<xsl:if test="ancestor::mads:authority">
			<titleInfo>
				<title>
					<xsl:apply-templates/>
				</title>
			</titleInfo>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="mads:topic">
		<subject>
			<topic>
				<xsl:if test="ancestor::mads:authority">
					<xsl:attribute name="usage">authority</xsl:attribute>
				</xsl:if>
				<xsl:apply-templates/>
			</topic>
		</subject>
		<!-- use authority as title -->
		<xsl:if test="ancestor::mads:authority">
			<titleInfo>
				<title>
					<xsl:apply-templates/>
				</title>
			</titleInfo>
		</xsl:if>
	</xsl:template>

	<xsl:template match="mads:temporal">
		<subject>
			<temporal>
				<xsl:if test="ancestor::mads:authority">
					<xsl:attribute name="usage">authority</xsl:attribute>
				</xsl:if>
				<xsl:apply-templates/>
			</temporal>
		</subject>
		<!-- use authority as title -->
		<xsl:if test="ancestor::mads:authority">
			<titleInfo>
				<title>
					<xsl:apply-templates/>
				</title>
			</titleInfo>
		</xsl:if>
	</xsl:template>
	
	<!-- book title -->
	<xsl:template match="mads:titleInfo[ancestor::mads:authority]">
		<titleInfo usage="primary">
			<title>
				<xsl:apply-templates/>
			</title>
		</titleInfo>
	</xsl:template>
	
	<!-- identifier -->
	<xsl:template match="mads:identifier">
		<xsl:if test="not(@invalid='yes') and (@type='lccn' or @type='local')">
			<identifier type="local">
				<xsl:value-of select="concat(@type, ':', translate(., ' ', ''))"/>
			</identifier>
		</xsl:if>
	</xsl:template>

	<!-- generate @xlink:href when including MADS document as related item -->
	<xsl:template match="mads:identifier" mode="xlink">
		<xsl:attribute name="xlink:href">
			<xsl:value-of select="concat(@type, ':', translate(., ' ', ''))"/>
		</xsl:attribute>
	</xsl:template>
	
	<!-- trap any other MADS elements -->
	<xsl:template match="mads:note|mads:recordInfo|mads:genre|mads:classification|mads:fieldOfActivity"/>
	
	<!-- tei notes in extension -->
	<xsl:template match="mads:extension">
		<xsl:param name="depth"/>
		
		<xsl:apply-templates select="tei:note" mode="note">
			<xsl:with-param name="depth" select="$depth"/>
		</xsl:apply-templates>
	</xsl:template>
	
	<!--xsl:template match="mads:extension/tei:note">
		<note>
			<xsl:apply-templates/>
		</note>
	</xsl:template-->
		
</xsl:stylesheet>

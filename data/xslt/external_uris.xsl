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
    exclude-result-prefixes="mods mads php tei exsl data"
    >
	
	<xsl:output omit-xml-declaration="yes" indent="yes"/>
  
  <!--****** xslt/external_uris.xsl
 * NAME
 * external_uris.xsl
 * SYNOPSIS
 * Stylesheet for templates related to resolving external URIS and loading them into variable for processing with source document.
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20160212
 * NOTES
 * PHP functions are called from several templates here.
 ****-->

	<!-- dump URIs of external documents and then load these documents into variable -->
	<!-- do it once and then again to get documents referenced in these referenced documents -->
	<xsl:variable name="external_uris_1">
		<xsl:text>auth </xsl:text>
		<xsl:apply-templates select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msContents/tei:msItem/@class" mode="external_uris"/>
		<xsl:apply-templates select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msContents/@class" mode="external_uris"/>
		<xsl:apply-templates select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/descendant::tei:*/@key" mode="external_uris"/>
		<xsl:apply-templates select="/mads:mads/mads:extension/tei:note/descendant::tei:*/@key" mode="external_uris"/>
	</xsl:variable>

	<xsl:variable name="external_docs_1">
		<xsl:copy-of select="php:function('external_uris', $external_uris_1)"/>
	</xsl:variable>
	
	<xsl:variable name="external_uris">
		<xsl:text>auth </xsl:text>
		<xsl:apply-templates select="exsl:node-set($external_docs_1)/descendant::mads:extension/tei:note/descendant::tei:*/@key" mode="external_uris"/>
		<xsl:text>bib </xsl:text>
		<xsl:apply-templates select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/descendant::tei:ref/@target" mode="external_uris"/>
		<xsl:apply-templates select="exsl:node-set($external_docs_1)/descendant::mads:extension/tei:note/descendant::tei:*/@target" mode="external_uris"/>
	</xsl:variable>
	
	<!-- get external documents -->
	<xsl:variable name="external_docs">
		<xsl:copy-of select="$external_docs_1"/>
		<xsl:copy-of select="php:function('external_uris', $external_uris, $external_uris_1)"/>
	</xsl:variable>

	<!-- display document indicated by URI -->
	<xsl:template name="resolve_uris">
		<xsl:param name="uris"/>
		<xsl:param name="render"/>
		<xsl:param name="pages"/>
		
		<!--xsl:choose>
			<xsl:when test="contains($uris, ' ')">
				<xsl:call-template name="resolve_uri">
					<xsl:with-param name="uri" select="substring-before($uris, ' ')"/>
					<xsl:with-param name="render" select="$render"/>
					<xsl:with-param name="pages" select="$pages"/>
				</xsl:call-template>
				<xsl:text> </xsl:text>
				<xsl:call-template name="resolve_uris">
					<xsl:with-param name="uris" select="substring-after($uris, ' ')"/>
					<xsl:with-param name="render" select="$render"/>
					<xsl:with-param name="pages" select="$pages"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="$uris != ''">
				<xsl:call-template name="resolve_uri">
					<xsl:with-param name="uri" select="$uris"/>
					<xsl:with-param name="render" select="$render"/>
					<xsl:with-param name="pages" select="$pages"/>
				</xsl:call-template>
			</xsl:when>
		</xsl:choose-->
		<xsl:for-each select="str:tokenize($uris)">
			<xsl:call-template name="resolve_uri">
				<xsl:with-param name="uri" select="."/>
				<xsl:with-param name="render" select="$render"/>
				<xsl:with-param name="pages" select="$pages"/>
			</xsl:call-template>
			<xsl:if test="following-sibling::*">
				<xsl:text> </xsl:text>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template name="resolve_uri">
		<xsl:param name="uri"/>
		<xsl:param name="render">full</xsl:param>
		<xsl:param name="pages"/>
		
		<xsl:choose>
			<!-- bibl item -->
			<xsl:when test="exsl:node-set($external_docs)/root/mods:mods/@id = $uri">
				<xsl:apply-templates select="exsl:node-set($external_docs)/root/mods:mods[@id = $uri]" mode="html_bib">
					<xsl:with-param name="render" select="$render"/>
					<xsl:with-param name="pages" select="$pages"/>
				</xsl:apply-templates>
			</xsl:when>
			<!-- auth file -->
			<xsl:when test="exsl:node-set($external_docs)/root/mads:mads/@id = $uri">
				<xsl:apply-templates select="exsl:node-set($external_docs)/root/mads:mads[@id = $uri]">
					<xsl:with-param name="render" select="$render"/>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$uri"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- dump space delimited URIs of external documents -->
	<xsl:template match="tei:*|@*" mode="external_uris">
		<xsl:value-of select="."/>
		<xsl:text> </xsl:text>
	</xsl:template>

</xsl:stylesheet>
<?xml version="1.0" encoding="UTF-8"?><!-- -*- xml -*- -->
<xsl:stylesheet
		version="1.0" 
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:tei="http://www.tei-c.org/ns/1.0"
		xmlns="http://www.tei-c.org/ns/1.0"
		xmlns:php="http://php.net/xsl"
		xmlns:mads="http://www.loc.gov/mads/v2"
		xmlns:mods="http://www.loc.gov/mods/v3"
		xsl:extension-element-prefixes="php"
		exclude-result-prefixes="php mads mods tei"
		>
	
	<!--****** xslt/tei2tei.xsl
 * NAME
 * tei2tei.xsl
 * SYNOPSIS
 * Stylesheet for transforming TEI into TEI - adding stuff to existing documents.
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20121105
 ****-->
	
	<!-- match TEI elements -->
	<xsl:template match="tei:*">
		<xsl:element name="{name()}">
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>

	<!-- generate filiations -->
	<xsl:template match="tei:msItem">
		<xsl:element name="{name()}">
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates/>
			
			<!-- now generate filiations -->
			<xsl:apply-templates
					select="php:function('workCopies', string(tei:title[1]), string(tei:author[@key][1]/@key), string(ancestor::tei:msDesc/@xml:id))" 
					mode="filiation"
					/>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="tei:TEI" mode="filiation">
		<filiation>
			<xsl:text>There is another manuscript containing this work at </xsl:text>
			<tei:orgName>
				<xsl:value-of select="tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msIdentifier/tei:institution"/>
			</tei:orgName>
			<xsl:text> </xsl:text>
			<ref target="{tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/@xml:id}">
				<xsl:value-of select="tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msIdentifier/tei:idno"/>
			</ref>
		</filiation>
	</xsl:template>
	
</xsl:stylesheet>

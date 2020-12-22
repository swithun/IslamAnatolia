<?xml version="1.0" encoding="UTF-8"?><!-- -*- xml -*- -->
<xsl:stylesheet
    version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.tei-c.org/ns/1.0"
    >
	
	<!-- tidies up TEI, removing elements which are empty -->
	<xsl:template match="tei:*">
		<xsl:if test="(translate(., '&#10; ', '') != '') or (descendant-or-self::tei:ref[@target != '']) or (descendant-or-self::tei:layout[@* != ''] or descendant-or-self::tei:handNote[@script != ''] or descendant-or-self::tei:certainty)">
			<xsl:element name="{name()}">
				<xsl:copy-of select="@*"/>
				<xsl:apply-templates/>
			</xsl:element>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="text()">
		<xsl:if test=". != ' ' and translate(., ' &#10;', '') != ''">
			<xsl:value-of select="."/>
		</xsl:if>
	</xsl:template>
	
</xsl:stylesheet>
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:html="http://www.w3.org/1999/xhtml"
		xmlns="http://www.w3.org/1999/XSL/Format"
		xmlns:xmp="http://ns.adobe.com/xap/1.0/"
		xmlns:x="adobe:ns:meta/"
		xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
		xmlns:dc="http://purl.org/dc/elements/1.1/"
    >
  
  <!--****** xslt/html2fo.xsl
 * NAME
 * html2fo.xsl
 * SYNOPSIS
 * Stylesheet for transforming HTML to XSL-FO
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20140108
 ****-->

	<xsl:template match="/">
		<root>
			<!-- describe page layout-->
			<layout-master-set>
				<simple-page-master master-name="page">
					<region-body margin="1in"/>
				</simple-page-master>
			</layout-master-set>
			
			<!-- metadata -->
			<declarations>
				<x:xmpmeta>
					<rdf:RDF about="">
						<dc:creator>University of St Andrews</dc:creator>
						<dc:language>en</dc:language>
						<dc:title>
							<xsl:value-of select="descendant::html:h2[1]"/>
						</dc:title>
					</rdf:RDF>
				</x:xmpmeta>
			</declarations>
			
			<!-- article is what to put on page -->
			<xsl:apply-templates select="descendant::html:article"/>
		</root>
	</xsl:template>
	
	<xsl:template match="html:title">
		<dc:title>
			<xsl:apply-templates/>
		</dc:title>
	</xsl:template>
	
	<!-- article is page -->
	<xsl:template match="html:article">
		<page-sequence master-reference="page">
			<flow flow-name="xsl-region-body" font-size="10pt" font-family="DejaVuSerif">
				<xsl:apply-templates/>
			</flow>
		</page-sequence>
	</xsl:template>
	
	<!-- pass through DIV -->
	<xsl:template match="html:div">
		<xsl:apply-templates/>
	</xsl:template>
	
	<!-- block level elements -->
	<xsl:template match="html:p">
		<block xsl:use-attribute-sets="block" role="P">
			<xsl:apply-templates/>
		</block>
	</xsl:template>
	
	<xsl:template match="html:h1">
		<block font-size="18pt" xsl:use-attribute-sets="block heading" role="H1">
			<xsl:apply-templates/>
		</block>
	</xsl:template>

	<xsl:template match="html:h2">
		<block font-size="16pt" xsl:use-attribute-sets="block heading" role="H2">
			<xsl:apply-templates/>
		</block>
	</xsl:template>

	<xsl:template match="html:h3">
		<block font-size="14pt" xsl:use-attribute-sets="block heading" role="H3">
			<xsl:apply-templates/>
		</block>
	</xsl:template>

	<xsl:template match="html:h4">
		<block font-size="12pt" xsl:use-attribute-sets="block heading" role="H4">
			<xsl:apply-templates/>
		</block>
	</xsl:template>
	
	<xsl:template match="html:address">
		<block font-style="italic" xsl:use-attribute-sets="block">
			<xsl:apply-templates/>
		</block>
	</xsl:template>

	<!-- inline elements -->
	<xsl:template match="html:strong">
		<inline font-weight="bold">
			<xsl:apply-templates/>
		</inline>
	</xsl:template>

	<xsl:template match="html:em">
		<inline font-style="italic">
			<xsl:apply-templates/>
		</inline>
	</xsl:template>

	<xsl:template match="html:span">
		<inline>
			<xsl:apply-templates select="@lang"/>
			<xsl:apply-templates/>
		</inline>
	</xsl:template>
	
	<!-- lists -->

	<!-- UL and OL -->
	<xsl:template match="html:ul|html:ol">
		<!-- only proceed if there are children -->
		<xsl:if test="html:li">
			<list-block 
					provisional-distance-between-starts="18pt" 
					provisional-label-separation="3pt"
					xsl:use-attribute-sets="block"
					role="L"
					>
				<xsl:apply-templates/>
			</list-block>
		</xsl:if>
	</xsl:template>
	
	<!-- bullet point -->
	<xsl:template match="html:ul/html:li">
		<list-item>
			<list-item-label end-indent="label-end()">
				<block>&#x2022;</block>
			</list-item-label>
			<list-item-body start-indent="body-start()">
				<block>
					<xsl:apply-templates/>
				</block>
			</list-item-body>
		</list-item>
	</xsl:template>
	
	<!-- numbered item -->
	<xsl:template match="html:ol/html:li">
		<list-item>
			<list-item-label end-indent="label-end()">
				<block>
					<xsl:value-of select="count(preceding-sibling::html:li) + 1"/>
				</block>
			</list-item-label>
			<list-item-body start-indent="body-start()">
				<block>
					<xsl:apply-templates select="@lang"/>
					<xsl:apply-templates/>
				</block>
			</list-item-body>
		</list-item>
	</xsl:template>
	
	<!-- DL -->
	<xsl:template match="html:dl">
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match="html:dt">
		<xsl:if test=". != 'Filiation'">
			<block font-weight="bold" xsl:use-attribute-sets="block">
				<xsl:apply-templates/>
			</block>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="html:dd">
		<xsl:if test="preceding-sibling::html:dt[1][. != 'Filiation']">
			<block start-indent="24pt">
				<xsl:apply-templates select="@lang"/>
				<xsl:apply-templates/>
			</block>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="html:br">
		<xsl:text>&#xA;</xsl:text>
	</xsl:template>
	
	<xsl:template match="@lang">
		<xsl:if test=". = 'ota' or . = 'ara'">
			<xsl:attribute name="font-family">
				<xsl:text>DejaVuSans</xsl:text>
			</xsl:attribute>
		</xsl:if>
	</xsl:template>
	
	<!-- attribute sets -->
	<xsl:attribute-set name="block">
		<xsl:attribute name="space-before">12pt</xsl:attribute>
		<xsl:attribute name="linefeed-treatment">preserve</xsl:attribute>
	</xsl:attribute-set>
	
	<xsl:attribute-set name="heading">
		<xsl:attribute name="font-weight">bold</xsl:attribute>
	</xsl:attribute-set>
	
</xsl:stylesheet>
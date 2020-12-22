<?xml version="1.0" encoding="UTF-8"?><!-- -*- xml -*- -->
<xsl:stylesheet
    version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:php="http://php.net/xsl"
    xmlns:mads="http://www.loc.gov/mads/v2"
    xmlns:mods="http://www.loc.gov/mods/v3"
		xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="php exsl"
		xmlns:data="urn:data"
    exclude-result-prefixes="mods mads php tei exsl data"
    >
	
	<!-- code for bibliogrphies -->
	
	<xsl:output omit-xml-declaration="yes" indent="yes"/>
		
	<!-- get the MODS nodes for bib refs -->
	<xsl:template match="tei:ref" mode="get_mods">
		<xsl:param name="key"/>
		<xsl:param name="render">short</xsl:param>

		<!--xsl:variable name="author">
			<xsl:choose>
				<xsl:when test="ancestor::tei:msItem/tei:author">
					<xsl:value-of select="ancestor::tei:msItem/tei:author/@key"/>
				</xsl:when>
				<xsl:when test="ancestor::mads:mads">
					<xsl:value-of select="concat(ancestor::mads:mads/mads:identifier/@type, ':', translate(ancestor::mads:mads/mads:identifier, ' ', ''))"/>
				</xsl:when>
			</xsl:choose>
		</xsl:variable-->
		
		<tei:bibl type="{parent::tei:bibl/@type}" key="{$key}" rend="{$render}" n="{.}">
			<xsl:copy-of select="exsl:node-set($external_docs)/root/mods:mods[@id = current()/@target]"/>
		</tei:bibl>
	</xsl:template>
	
	<xsl:template match="tei:bibl" mode="ordered_mods">
		<xsl:variable name="type" select="@type"/>
		
		<!-- only work with first bib ref of that type -->
		<xsl:if test="not(preceding-sibling::tei:bibl) or preceding-sibling::tei:bibl[1]/@type != $type">
			<!-- break up list by sub-grouping -->
			<xsl:if test="@rend = 'full'">
				<xsl:apply-templates select="@type" mode="bib_type"/>
			</xsl:if>
			
			<xsl:apply-templates select="self::tei:bibl | following-sibling::tei:bibl[@type = $type]" mode="individual_mods">
				<xsl:with-param name="render" select="@rend"/>
				<xsl:with-param name="key" select="@key"/>
				<xsl:sort select="mods:mods/mods:name[mods:role/mods:roleTerm='aut' or mods:role/mods:roleTerm='edt'][1]/mods:namePart[@type='family']"/>
			</xsl:apply-templates>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="mods:mods" mode="individual_mods">
		<xsl:param name="render"/>
		<xsl:param name="key"/>
		<xsl:variable name="target" select="@id"/>
		
		<xsl:choose>
			<!-- short link to bibliography for page -->
			<xsl:when test="$render = 'short' and exsl:node-set($external_docs)/root/mods:mods/@id = $target">
				<a href="#{$target}_{$key}">
					<xsl:call-template name="resolve_uris">
						<xsl:with-param name="render" select="$render"/>
						<xsl:with-param name="uris" select="$target"/>
					</xsl:call-template>
				</a>
			</xsl:when>
			<!-- full render, so in bibliography context  -->
			<xsl:when test="$render = 'full' and exsl:node-set($external_docs)/root/mods:mods/@id = $target">
				<dd>
					<xsl:call-template name="resolve_uris">
						<xsl:with-param name="render" select="$render"/>
						<xsl:with-param name="uris" select="$target"/>
						<xsl:with-param name="pages" select="parent::tei:bibl/@n"/>
					</xsl:call-template>
				</dd>
			</xsl:when>
			<xsl:when test=". != ''">
				<xsl:apply-templates/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>Bibliographic reference</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- bibligraphic groupings -->
	<xsl:template match="@type" mode="bib_type">
		<dt class="bib_subheading">
			<xsl:choose>
				<xsl:when test="exsl:node-set($groups)/data:data/data:item[@value=current()]">
					<xsl:value-of select="exsl:node-set($groups)/data:data/data:item[@value=current()]"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>Unknown bibliogrphic grouping</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</dt>
	</xsl:template>
	
</xsl:stylesheet>
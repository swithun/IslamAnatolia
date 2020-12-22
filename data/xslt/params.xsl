<?xml version="1.0" encoding="UTF-8"?><!-- -*- xml -*- -->
<xsl:stylesheet
		version="1.0" 
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:tei="http://www.tei-c.org/ns/1.0"
		xmlns="http://www.w3.org/1999/xhtml"
		xmlns:data="urn:data"
		>

	<!--****** xslt/params.xsl
 * NAME
 * params.xsl
 * SYNOPSIS
 * XSLT file to hold names of search params
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20150902
 ****-->

	<xsl:param name="q"/><!-- search query -->
	<xsl:param name="field"/><!-- field to search -->
	<xsl:param name="author"/><!-- author facet -->
	<xsl:param name="date"/><!-- creation date facet -->
	<xsl:param name="copying_date"/><!-- copying date facet -->
	<xsl:param name="creation_place"/><!-- place of creation facet -->
	<xsl:param name="copying_place"/><!-- place of copying facet -->
	<xsl:param name="subject_geographic"/><!-- SH geographic facet -->
	<xsl:param name="subject_topic"/><!-- SH topic facet -->
	<xsl:param name="subject_temporal"/><!-- SH temporal facet -->
	<xsl:param name="country"/><!-- country facet -->
	<xsl:param name="settlement"/><!-- settlement facet -->
	<xsl:param name="institution"/><!-- institution facet -->
	<xsl:param name="repository"/><!-- repository facet -->
	<xsl:param name="collection"/><!-- collection facet -->
	<xsl:param name="language"/>
	<xsl:param name="script"/>
	<xsl:param name="doctype"/>
	
	<xsl:param name="documentName"/>
	<xsl:param name="workID"/>
	
	<!-- only show results if have query -->
	<xsl:param name="haveQuery"/>
	<xsl:param name="haveFacets"/>
	
	<!-- search string -->
	<xsl:param name="query_string"/>
	<!-- script name -->
	<xsl:param name="php_script"/>
	<!-- number of rows returned by Solr -->
	<xsl:param name="rows"/>
	<!-- size of date bucket in Solr -->
	<xsl:param name="gap"/>
	
	<!-- sort -->
	<xsl:param name="sort_field">relevance</xsl:param>
	<xsl:param name="sort_direction">desc</xsl:param>
	
	<!-- structure to hold information about fields -->
	<!-- @display - Display string for field -->
	<!-- @field - name of field to pass back to PHP, should match key in facets array -->
	<!-- @solr - name of field in Solr, should match value in facets array -->
	<!-- @value - value of field if any -->
	<xsl:variable name="params">
		<params xmlns="urn:data">
			<param display="Query" field="q" value="{$q}"/>
			<param display="Field" field="field" value="{$field}"/>
			<param display="Author" field="author" solr="work_author_s" value="{$author}"/>
			<param display="Main language" field="language" solr="work_language" value="{$language}"/>
			<param display="Date of creation" field="date" solr="work_date_created_start" value="{$date}"/>
			<param display="Date of copy" field="copying_date" solr="work_date_copy_start" value="{$copying_date}"/>
			<param display="Place of composition" field="creation_place" solr="work_creation_place_s" value="{$creation_place}"/>
			<param display="Place of copying" field="copying_place" solr="work_copy_place_s" value="{$copying_place}"/>
			<param display="Institution (location of manuscript)" field="institution" solr="ms_physical_location_institution" value="{$institution}"/>
			<!--param display="Repository (location of manuscript)" field="repository" solr="ms_physical_location_repository" value="{$repository}"/-->
			<param display="Collection (location of manuscript)" field="collection" solr="ms_physical_location_collection" value="{$collection}"/>
			<param display="Place (location of manuscript)" field="settlement" solr="ms_physical_location_settlement" value="{$settlement}"/>
			<param display="Country (location of manuscript)" field="country" solr="ms_physical_location_country" value="{$country}"/>
			<param display="Geographic subject heading" field="subject_geographic" solr="work_auth_geographic" value="{$subject_geographic}"/>
			<param display="Subject heading" field="subject_topic" solr="work_auth_topic" value="{$subject_topic}"/>
			<!--param display="Temporal subject heading" field="subject_temporal" solr="work_auth_temporal" value="{$subject_temporal}"/-->
			<param display="Script used" field="script" solr="work_script" value="{$script}"/>
		</params>
	</xsl:variable>

	<!-- put input document into variable, so it can be called from inside other documents -->
	<xsl:variable name="src">
		<xsl:copy-of select="/"/>
	</xsl:variable>
	
	<!-- fields -->
	<xsl:variable name="fields">
		<fields xmlns="urn:data">
			<option value="text">All work fields</option>
			<option value="title">Work titles</option>
			<option value="author">Authors</option>
			<option value="note">Work notes</option>
			<option value="classmark">Manuscript classmarks</option>
			<option value="people">People</option>
			<option value="places">Places</option>
		</fields>
	</xsl:variable>
	
	<!-- field names -->
	<xsl:variable name="field_names">
		<data xmlns="urn:data">
			<item field="text">All work fields</item>
			<item field="work_note_place">Places in work notes</item>
			<item field="author_note_place">Places in author notes</item>
			<item field="work_creation_place">Place of work composition</item>
			<item field="work_copy_place">Place of work copying</item>
			<item field="place">All place fields</item>
			<item field="title">Work titles</item>
			<item field="author">Author fields</item>
			<item field="note">Work notes</item>
			<item field="classmark">Manuscript classmarks</item>
			<item field="people">People</item>
		</data>
	</xsl:variable>
	
	<!-- sort fields -->
	<xsl:variable name="sort_fields">
		<data xmlns="urn:data">
			<item value="relevance">Relevance</item>
			<item value="title">Titles</item>
			<!--item value="date">Date</item-->
			<item value="classmark">Classmark</item>
		</data>
	</xsl:variable>
	
	<!-- sort directions -->
	<xsl:variable name="sort_directions">
		<data xmlns="urn:data">
			<item value="desc">Descending</item>
			<item value="asc">Ascending</item>
		</data>
	</xsl:variable>
	
	<!-- document types -->
	<xsl:variable name="doctypes">
		<doctypes xmlns="urn:data">
			<option value="work">Works</option>
			<!--option value="ms">Manuscripts</option-->
			<option value="people">People</option>
		</doctypes>
	</xsl:variable>

	<xsl:variable name="languages">
		<languages xmlns="urn:data">
			<item value="ara-Latn-x-lc">Arabic (transliterated)</item>
			<item value="per-Latn-x-lc">Persian (transliterated)</item>
			<item value="ota-Latn-x-lc">Ottoman Turkish (transliterated)</item>
			<item value="ara">Arabic</item>
			<item value="per">Persian</item>
			<item value="tur">Turkish</item>
			<item value="en">English</item>
			<item value="fr">French</item>
			<item value="ota">Ottoman Turkish</item>
			<item value="lat">Latin</item><!-- schema has lat instead of la -->
			<item value="unk">Unknown</item><!-- added for unknown -->
		</languages>
	</xsl:variable>
	
	<xsl:variable name="scripts">
		<scripts xmlns="urn:data">
			<item value="muhaqqaq">Muhaqqaq</item>
			<item value="rayhani">Rayhani</item>
			<item value="naskh">Naskh</item>
			<item value="maghribi">Maghribi</item>
			<item value="bihari">Bihari</item>
			<item value="nasta_liq">Nasta'liq</item>
			<item value="thuluth">Thuluth</item>
			<item value="tawqi_">Tawqi'</item>
			<item value="riqa_">Riqa'</item>
			<item value="ghubar">Ghubar</item>
			<item value="ta_liq">Ta'liq</item>
			<item value="diwani">Diwani</item>
			<item value="ruq_ah">Ruq'ah</item>
			<item value="siyaqah">Siyaqah</item>
			<item value="shikastah">Shikastah</item>
			<item value="kufic">Kufic</item>
			<item value="arabi">Arabi</item>
		</scripts>
	</xsl:variable>
	
	<xsl:variable name="calendars">
		<calendars xmlns="urn:data">
			<item value="Hijri-qamari"> AH</item>
			<item value=""> CE</item>
		</calendars>
	</xsl:variable>
	
	<xsl:variable name="number_of_hits">
		<data xmlns="urn:data">
			<item>10</item>
			<item>20</item>
			<item>50</item>
			<item>100</item>
		</data>
	</xsl:variable>
	
	<xsl:param name="recent_search"/>
	
	<xsl:param name="search_url"/>

	<xsl:variable name="groups">
		<data xmlns="urn:data">
			<item value="local:editions">Editions</item>
			<item value="local:translations">Translations</item>
			<item value="local:studies">Studies</item>
			<item value="local:mstudies">MS Studies</item>
			<item value="local:catalogue">Catalogue</item>
		</data>
	</xsl:variable>
	
</xsl:stylesheet>
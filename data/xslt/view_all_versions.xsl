<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
		version="1.0" 
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:tei="http://www.tei-c.org/ns/1.0"
		xmlns="http://www.w3.org/1999/xhtml"
		>

	<!--****** xslt/view_all_versions.xsl
 * NAME
 * view_all_versions.xsl
 * SYNOPSIS
 * Templates for transforming database output into a page showing all versions of a document.
 * This is for admins, not the public.
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20120710
 * SEE ALSO
 *   * xslt/templates.xsl
 ****-->

	<xsl:param name="docType"/>
	
	<xsl:include href="templates.xsl"/>
	
	<xsl:template match="table">
		<h2>Admin page</h2>
		<xsl:apply-templates select="row[1]/documentName"/>
		
		<ul>
			<xsl:apply-templates/>
		</ul>
		
		<xsl:apply-templates select="row[1]" mode="form"/>
		
	</xsl:template>
	
	<xsl:template match="row">
		<li>
			<a href="view_version.php?documentID={documentID}&amp;version={versionID}&amp;type={$docType}">
				<xsl:apply-templates select="versionDate"/>
				<xsl:apply-templates select="versionCreator"/>
			</a>
			<xsl:text> (</xsl:text>
			<a href="view_version.php?documentID={documentID}&amp;version={versionID}&amp;type={$docType}&amp;raw=true">
				<xsl:text>plain XML</xsl:text>
			</a>
			<xsl:text>)</xsl:text>
		</li>
	</xsl:template>
	
	<xsl:template match="documentName">
		<h3>
			<xsl:text>Versions of </xsl:text>
			<xsl:apply-templates/>
		</h3>
	</xsl:template>
	
	<xsl:template match="versionCreator">
		<xsl:text> (</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>)</xsl:text>
	</xsl:template>
	
	<xsl:template match="row" mode="form">
		<form method="post" action="document_admin.php">
			<h3>Admin actions</h3>
			<p>
				<label for="method">Action</label>
				<select name="method" id="method">
					<option value=""/>
					<!--option value="download">Download all versions</option-->
					<option value="delete">Delete all versions</option>
					<option value="rename">Rename document</option>
				</select>
			</p>
			<p>
				<label for="confirm">Confirm (deletion)</label>
				<input type="checkbox" name="confirm" id="confirm" value="1"/>
			</p>
			<p>
				<label for="rename">Rename to</label>
				<input name="rename" id="rename" type="text"/>
			</p>
			<p>
				<input type="submit" value="Submit"/>
				<input type="hidden" name="submitted" value="1"/>
				<input type="hidden" name="documentID" value="{documentID}"/>
				<input type="hidden" name="type" value="{$docType}"/>
			</p>
		</form>
	</xsl:template>
	
</xsl:stylesheet>

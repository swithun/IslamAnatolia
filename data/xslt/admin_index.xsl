<?xml version="1.0" encoding="UTF-8"?><!-- -*- xml -*- -->
<xsl:stylesheet
		version="1.0" 
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:tei="http://www.tei-c.org/ns/1.0"
		xmlns="http://www.w3.org/1999/xhtml"
		>

	<!--****** xslt/admin_index.xsl
 * NAME
 * admin_index.xsl
 * SYNOPSIS
 * Templates for creating an index page for administrators.
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20120710
 * SEE ALSO
 *   * xslt/templates.xsl
 ****-->
	
	<xsl:include href="templates.xsl"/>
	
	<xsl:template match="table">
		<h2>Admin page</h2>
		<dl>
			<dt>Upload</dt>
			<dd>
				<a href="upload.php">Upload documents</a>
			</dd>
			<dt>List</dt>
			<dd>
				<a href="list_documents.php?type=ms">List manuscript documents</a>
			</dd>
			<dd>
				<a href="list_documents.php?type=auth">List authority files</a>
			</dd>
			<dd>
				<a href="list_documents.php?type=bibliography">List bibliographic items</a>
			</dd>
			<dd>
				<a href="basket.php?action=view">Basket items</a>
			</dd>
			<dt>Search</dt>
			<dd>
				<form action="search.php" method="get">
					<p>
						<label for="q">Query</label>
						<input type="text" name="q" id="q"/>
					</p>
					<p>
						<input type="submit" value="Search"/>
					</p>
				</form>
			</dd>
			<dt>Download</dt>
			<dd>
				<a href="download.php">All records as ZIP</a>
			</dd>
		</dl>
	</xsl:template>
	
</xsl:stylesheet>

<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
		version="1.0" 
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:tei="http://www.tei-c.org/ns/1.0"
		xmlns="http://www.w3.org/1999/xhtml"
		>

	<!--****** xslt/admin_upload_authority_file.xsl
 * NAME
 * admin_upload_authority_file.xsl
 * SYNOPSIS
 * Templates for creating a page for uploading MADS authority files.
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20120710
 * SEE ALSO
 *   * xslt/templates.xsl
 ****-->
	
	<xsl:param name="file_item"/>
	
	<xsl:include href="templates.xsl"/>
	
	<xsl:template match="table">
		<h2>Admin page</h2>
		<h3>Upload new authority file</h3>
		<form method="post" enctype="multipart/form-data" action="upload_authority_file.php">
			<p>
				<label for="{$file_item}">Authority file</label>
				<input type="file" name="{$file_item}" id="{$file_item}"/>
			</p>
			<p>
				<input type="submit" value="Upload"/>
			</p>
		</form>
	</xsl:template>
	
</xsl:stylesheet>

<?xml version="1.0" encoding="UTF-8"?><!-- -*- xml -*- -->
<xsl:stylesheet
    version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="tei"
    >
  
  <!--****** xslt/basket.xsl
 * NAME
 * basket.xsl
 * SYNOPSIS
 * Templates for showing basket
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20131011
 * SEE ALSO
 *   * xslt/search.xsl
 ****-->
  
  <xsl:param name="type"/>
  
  <xsl:include href="search.xsl"/>

  <!-- override template in search.xsl -->
  <xsl:template match="lst[@name='highlighting']">
    <form action="basket.php" method="post">
      <p>
        <label for="select_all">Select all</label>
        <input type="checkbox" id="select_all" onclick="selectAll('hits[]');"/>
      </p>
      <dl class="hit_list">
        <xsl:apply-templates mode="hits"/>
      </dl>
      <p>
        <label for="action">Action</label>
        <select name="action" id="action">
          <option value=""/>
          <option value="delete">Delete from system</option>
          <option value="remove">Remove from basket</option>
          <option value="download">Download</option>
        </select>
      </p>
      <p>
        <label for="confirm">If delete, confirm</label>
        <input type="checkbox" id="confirm" name="confirm" value="1"/>
      </p>
      <p>
        <input type="submit" value="Apply action"/>
        <input type="reset" value="Clear selection"/>
      </p>
      <script src="select_all.js">
        <xsl:comment>code for selecting all checkboxes</xsl:comment>
      </script>
    </form>
  </xsl:template>
  
  <xsl:template match="lst" mode="hits">
    <!-- name of work -->
    <xsl:variable name="workName" select="@name"/>
    
    <!-- name of MS (without work ID) -->
    <xsl:variable name="msName">
      <xsl:choose>
        <xsl:when test="contains(@name, ';')">
          <xsl:value-of select="substring-before(@name, ';')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="@name"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <!-- document type -->
    <xsl:variable 
        name="doctype" 
        select="/response/result[@name='response']/doc[str[@name='id'] = $workName]/str[@name='doc_type']"
        />
    
    <!-- version URL -->
    <xsl:variable 
        name="versionURL"
        select="concat('view_version.php?documentName=', $msName, '&amp;type=', $doctype, '&amp;version=')"
        />
    
    <xsl:apply-templates select="/response/result[@name='response']/doc[str[@name='id'] = $workName]"/>

    <dd>
      <ul class="version_list">
        <li>
          <a href="{$versionURL}latest">View latest version</a>
        </li>
        <li>
          <a href="{$versionURL}first">View first version</a>
        </li>
        <li>
          <a href="{$versionURL}all">View all versions</a>
        </li>
        <li>
          <input type="checkbox" name="hits[]" value="{$msName}|{$doctype}" id="hit_{$msName}"/>
          <label for="hit_{$msName}">Add to selection</label>
        </li>
      </ul>
    </dd>
  </xsl:template>
  
</xsl:stylesheet>

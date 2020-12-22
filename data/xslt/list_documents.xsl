<?xml version="1.0" encoding="UTF-8"?><!-- -*- xml -*- -->
<xsl:stylesheet
    version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.w3.org/1999/xhtml"
    >
  
  <!--****** xslt/list_documents.xsl
 * NAME
 * list_documents.xsl
 * SYNOPSIS
 * Templates for transforming database output into a page showing all documents in the system. This is the administrators' view.
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20120710
 * SEE ALSO
 *   * xslt/search.xsl
 ****-->
  
  <xsl:param name="type"/>
  <xsl:param name="url"/>
  
  <xsl:include href="search.xsl"/>

  <!-- override template in search.xsl -->
  <xsl:template match="lst[@name='highlighting']">
    <form action="basket.php" method="post">
      <dl class="hit_list">
        <xsl:apply-templates mode="hits"/>
      </dl>
      <p>
        <input type="hidden" name="url" value="{$url}"/>
        <input type="hidden" name="action" value="add"/>
        <input type="submit" value="Add selected to basket"/>
        <input type="reset" value="Clear selection"/>
      </p>
    </form>
  </xsl:template>
  
  <xsl:template match="lst" mode="hits">
    <xsl:apply-templates select="/response/result[@name='response']/doc[str[@name='id']=current()/@name]"/>
    <dd>
      <ul class="version_list">
        <li>
          <a href="view_version.php?documentName={@name}&amp;version=latest&amp;type={$type}">View latest version</a>
        </li>
        <li>
          <a href="view_version.php?documentName={@name}&amp;version=first&amp;type={$type}">View first version</a>
        </li>
        <li>
          <a href="view_version.php?documentName={@name}&amp;version=all&amp;type={$type}">View all versions</a>
        </li>
        <li>
          <input type="checkbox" name="hits[]" value="{@name}" id="hit_{@name}"/>
          <label for="hit_{@name}">Add to basket</label>
        </li>
      </ul>
    </dd>
  </xsl:template>
  
</xsl:stylesheet>

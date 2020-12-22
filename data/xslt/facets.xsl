<?xml version="1.0" encoding="UTF-8"?><!-- -*- xml -*- -->
<xsl:stylesheet
    version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:exsl="http://exslt.org/common"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="exsl str"
    xmlns:data="urn:data"
    exclude-result-prefixes="tei data"
    >

  <!--****** xslt/index.xsl
 * NAME
 * index.xsl
 * SYNOPSIS
 * Templates for display of facets.
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20151125
 ****-->
  
  <!-- display facet values -->
  <xsl:template match="data:param" mode="facet_list">
    <!-- some @solr have spaces, so recursively split these -->
    <xsl:call-template name="split_solr_fields">
      <xsl:with-param name="display" select="@display"/>
      <xsl:with-param name="field_value" select="@value"/>
      <xsl:with-param name="field_name" select="@field"/>
      <xsl:with-param name="solr" select="@solr"/>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template name="split_solr_fields">
    <xsl:param name="display"/>
    <xsl:param name="field_value"/>
    <xsl:param name="field_name"/>
    <xsl:param name="solr"/>
    
    <xsl:choose>
      <!-- has ' ' so process field name before ' ' and then recurse -->
      <xsl:when test="contains($solr, ' ')">
        <xsl:apply-templates select="exsl:node-set($src)/response/lst[@name='facet_counts']/lst/lst[@name = substring-before($solr, ' ')][count(descendant::int) &gt; 1]" mode="facet_list">
          <xsl:with-param name="display" select="$display"/>
          <xsl:with-param name="field_value" select="$field_value"/>
          <xsl:with-param name="field_name" select="$field_name"/>
        </xsl:apply-templates>
        <xsl:call-template name="split_solr_fields">
          <xsl:with-param name="display" select="$display"/>
          <xsl:with-param name="field_value" select="$field_value"/>
          <xsl:with-param name="field_name" select="$field_name"/>
          <xsl:with-param name="solr" select="substring-after($solr, ' ')"/>
        </xsl:call-template>
      </xsl:when>
      <!-- no ' ', so process and finished -->
      <xsl:when test="$solr != ''">
        <xsl:apply-templates select="exsl:node-set($src)/response/lst[@name='facet_counts']/lst/lst[@name = $solr][count(descendant::int) &gt; 1]" mode="facet_list">
          <xsl:with-param name="display" select="$display"/>
          <xsl:with-param name="field_value" select="$field_value"/>
          <xsl:with-param name="field_name" select="$field_name"/>
        </xsl:apply-templates>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <!-- facet values -->
  <xsl:template match="lst" mode="facet_list">
    <xsl:param name="display"/>
    <xsl:param name="field_value"/>
    <xsl:param name="field_name"/>

    <!-- number of values for facet to show by default -->
    <xsl:variable name="facets_to_show" select="number(3)"/>

    <div class="facet_group">
      <p>
        <xsl:value-of select="$display"/>
        <xsl:choose>
          <!-- nothing for date! -->
          <xsl:when test="$field_name = 'date' or $field_name = 'copying_date'"/>
          
          <xsl:when test="count(descendant::int) &lt;= $facets_to_show">
            <xsl:value-of select="concat(' (top ', count(descendant::int), ')')"/>
          </xsl:when>
          
          <xsl:otherwise>
            <xsl:value-of select="concat(' (top ', $facets_to_show, ')')"/>
          </xsl:otherwise>
        </xsl:choose>
      </p>
      <ul>
        <xsl:choose>
          <xsl:when test="$field_name = 'date' or $field_name = 'copying_date'">
            <!-- show all values for facet -->
            <xsl:apply-templates select="descendant::int" mode="facet_value">
              <xsl:with-param name="selected" select="$field_value"/>
              <xsl:with-param name="field" select="$field_name"/>
              <xsl:sort select="@name" data-type="number" order="descending"/>
            </xsl:apply-templates>
          </xsl:when>
          <xsl:otherwise>
            <!-- show top values for facet -->
            <xsl:apply-templates select="descendant::int" mode="facet_value">
              <xsl:with-param name="selected" select="$field_value"/>
              <xsl:with-param name="field" select="$field_name"/>
              <xsl:with-param name="facets_to_show" select="$facets_to_show"/>
              <xsl:sort select="." data-type="number" order="descending"/>
            </xsl:apply-templates>
          </xsl:otherwise>
        </xsl:choose>
      </ul>
    </div>
  </xsl:template>

  <!-- facet value as option, possibly selected -->
  <xsl:template match="int" mode="facet_value">
    <xsl:param name="selected"/>
    <xsl:param name="field"/>
    <xsl:param name="facets_to_show"/>
    
    <!-- value to use for form -->
    <xsl:variable name="form_val">
      <xsl:choose>
        <xsl:when test="$field = 'date' or $field = 'copying_date'">
          <xsl:value-of select="substring(@name, 1, 4)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="@name"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <!-- value to display -->
    <xsl:variable name="display_val">
      <xsl:choose>
        <xsl:when test="$field = 'language' and exsl:node-set($languages)/data:languages/data:item[@value=current()/@name]">
          <xsl:value-of select="exsl:node-set($languages)/data:languages/data:item[@value=current()/@name]"/>
        </xsl:when>
        <xsl:when test="$field = 'script'">
          <!-- can be multiple scripts, so tokenise @name -->
          <xsl:for-each select="str:tokenize(@name, ' ')">
            <xsl:value-of select="exsl:node-set($scripts)/data:scripts/data:item[@value = current()]"/>
            <xsl:if test="following-sibling::*">
              <xsl:text> / </xsl:text>
            </xsl:if>
          </xsl:for-each>
        </xsl:when>
        <xsl:when test="$field = 'date' or $field = 'copying_date'">
          <xsl:variable name="year" select="substring(@name, 1, 4)"/>
          <xsl:value-of select="concat($year, ' to ', $year + $gap)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="@name"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="foreign">
      <!-- test @name to see if it contains all non-Latin characters -->
      <xsl:if test="$field != 'language' and $field != 'script' and $field != 'date' and $field != 'copying_date' and @name != '' and translate(@name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz', '') = @name and not(translate(@name, '0123456789-', '') = '')">
        <xsl:text>foreign</xsl:text>
      </xsl:if>
    </xsl:variable>

    <!-- first facet value after top X -->
    <xsl:if test="$facets_to_show &gt; 0 and position() = $facets_to_show + 1">
      <li>
        <a href="#" class="show_following">
          <xsl:value-of select="concat('Show ', count(parent::lst/int) - $facets_to_show, ' more')"/>
        </a>
      </li>
    </xsl:if>
    
    <!-- display facet value -->
    <li>
      <xsl:if test="$facets_to_show &gt; 0 and position() &gt; $facets_to_show">
        <xsl:attribute name="class">following</xsl:attribute>
      </xsl:if>

      <!-- checkbox -->
      <input type="checkbox" id="{generate-id()}" value="{$form_val}" name="{$field}[]"/>
      
      <!-- label -->
      <label for="{generate-id()}">
        <span>
          <xsl:if test="$foreign = 'foreign'">
            <xsl:attribute name="class">
              <xsl:value-of select="$foreign"/>
            </xsl:attribute>
          </xsl:if>
          <xsl:value-of select="$display_val"/>
        </span>
      
        <!-- after foreign text, force left to right -->
        <xsl:if test="$foreign = 'foreign'">
          <xsl:text>&#8237;</xsl:text>
        </xsl:if>
        
        <span class="facet_value_count">
          <xsl:value-of select="concat(' (', ., ')')"/>
        </span>
      </label>
    </li>
  </xsl:template>
  
  <!-- show values of used facets, with option to remove from query -->
  <xsl:template match="data:param" mode="used_facet_list">
    <!-- field value calculated differently for different fields -->
    <xsl:variable name="value">
      <xsl:choose>
        <xsl:when test="@field = 'date' or @field = 'copying_date'">
          <!-- might be multiple years, e.g. 1400|1450 -->
          <xsl:call-template name="display_years_with_gap">
            <xsl:with-param name="years" select="@value"/>
          </xsl:call-template>
          <!--xsl:value-of select="concat(@value, ' to ', @value + $gap)"/-->
        </xsl:when>
        <!-- replace fields with full names -->
        <xsl:when test="@field = 'q'">
          <xsl:value-of select="concat(@value, ' (', exsl:node-set($field_names)/data:data/data:item[current()/parent::*/data:param[@display='Field']/@value = @field], ') ')"/>
        </xsl:when>
        <!-- replace language code with full name -->
        <xsl:when test="@field = 'language'">
          <xsl:value-of select="exsl:node-set($languages)/data:languages/data:item[@value=current()/@value]"/>
        </xsl:when>
        <!-- replace script code with full name -->
        <xsl:when test="@field = 'script'">
          <xsl:value-of select="exsl:node-set($scripts)/data:scripts/data:item[@value=current()/@value]"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="@value"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <li>
      <!-- field display -->
      <xsl:value-of select="@display"/>
      <xsl:text>: </xsl:text>
      <!-- field value -->
      <em>
        <xsl:value-of select="$value"/>
      </em>
      <xsl:text> </xsl:text>
      
      <a class="remove_facet" href="{$php_script}?{$query_string}&amp;remove_facet={@field}">Remove</a>
      
      <!-- hidden form item for searching within results -->
      <xsl:if test="@field != 'q' and @value != ''">
        <xsl:call-template name="split_values">
          <xsl:with-param name="field" select="@field"/>
          <xsl:with-param name="value" select="@value"/>
        </xsl:call-template>
      </xsl:if>
    </li>
  </xsl:template>

  <!-- split values on | into multiple hidden fields -->
  <xsl:template name="split_values">
    <xsl:param name="field"/>
    <xsl:param name="value"/>
    
    <xsl:choose>
      <xsl:when test="contains($value, '|')">
        <input type="hidden" name="{$field}[]" value="{substring-before($value, '|')}"/>
        <xsl:call-template name="split_values">
          <xsl:with-param name="field" select="$field"/>
          <xsl:with-param name="value" select="substring-after($value, '|')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$value != ''">
        <input type="hidden" name="{$field}[]" value="{$value}"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <!-- handle multiple years, e.g. turn 1400|1450 into 1400 to 1450, 1450 to 1500 -->
  <xsl:template name="display_years_with_gap">
    <xsl:param name="years"/>
    
    <xsl:for-each select="str:tokenize($years, '|')">
      <xsl:variable name="year" select="substring($years, 1, 4)"/>
      <xsl:value-of select="concat($year, ' to ', $year + $gap)"/>
      
      <xsl:if test="position() != last()">
        <xsl:text>, </xsl:text>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>
  
  <!-- display this for places search -->
  <xsl:template name="place_search">
    <h3>Searching for places</h3>
    
    <p>
      <xsl:text>Search for </xsl:text>
      <em>
        <xsl:value-of select="$q"/>
      </em>
      <xsl:text> in</xsl:text>
    </p>
    
    <ul class="place_search">
      <li>
        <a href="{$php_script}?doctype=people&amp;field=author_note_place&amp;q={$q}">Biographical notes</a>
      </li>
      <li>
        <a href="{$php_script}?doctype=work&amp;field=work_note_place&amp;q={$q}">Work notes</a>
      </li>
      <li>
        <a href="{$php_script}?doctype=work&amp;field=work_creation_place&amp;q={$q}">Place of composition</a>
      </li>
      <li>
        <a href="{$php_script}?doctype=work&amp;field=work_copy_place&amp;q={$q}">Place of copying</a>
      </li>
      <li>
        <a href="{$php_script}?doctype=work&amp;field=place&amp;q={$q}">All fields</a>
      </li>
    </ul>
  </xsl:template>

</xsl:stylesheet>
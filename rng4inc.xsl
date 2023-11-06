<?xml version="1.0" encoding="UTF-8"?>
<!--
<h1>Schéma Relax-NG, résolution d'inclusions <a href="rng_inc.xsl">rng_inc.xsl</a></h1>

Copyright © 2009-2017 Frédéric Glorieux
license : APACHE 2.0 http://www.apache.org/licenses/LICENSE-2.0
<frederic.glorieux@fictif.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.


-->
<xsl:transform version="1.1"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:rng="http://relaxng.org/ns/structure/1.0"
  xmlns:h="http://www.w3.org/1999/xhtml"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0"
  exclude-result-prefixes="rng a h"
>
  <xsl:output indent="no" method="xml" encoding="UTF-8"/>
  <!-- for rng:include, do not include and parse but prefer an html link instead -->
  <xsl:param name="incAsLink"/>

  <xsl:template match="/">
    <xsl:apply-templates mode="inc"/>
  </xsl:template>
  <!-- Do not propagate PI like <?xml-model href="teibook.rng" type="application/xml"  schematypens="http://relaxng.org/ns/structure/1.0"?> -->
  <xsl:template match="processing-instruction()">
    <xsl:choose>
      <xsl:when test="starts-with(name(), 'xml')"/>
      <xsl:otherwise>
        <xsl:copy-of select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="node()|@*" mode="inc">
    <!-- log info on context file -->
    <xsl:param name="context"/>
    <xsl:copy>
      <xsl:apply-templates select="node()|@*" mode="inc">
        <xsl:with-param name="context" select="$context"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>

  <!-- An XML example to include from a file -->
  <xsl:template match="a:example[@href]" mode="inc">
    <xsl:param name="context"/>
    <xsl:choose>
      <xsl:when test="ancestor::a:example">
        <xsl:call-template name="incEx"/>
      </xsl:when>
      <xsl:otherwise>
        <a:example>
          <xsl:call-template name="incEx"/>
        </a:example>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Include an XML example from a file -->
  <xsl:template name="incEx">
    <xsl:param name="context"/>
    <xsl:comment>
      <xsl:value-of select="concat($context, @href)"/>
    </xsl:comment>
    <xsl:variable name="anchor" select="substring-after(@href, '#')"/>
    <xsl:choose>
      <xsl:when test="$anchor != ''">
        <xsl:copy-of select="document(substring-before(@href, '#'),.)//*[@xml:id= $anchor]"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="document(@href,.)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--
    RNG include.
    No recursivity test should be needed if it's RNG valid
    pass a file context to resolve relative links
    
  <rng:include href="../../schema/paratexte.rng"/>
  <rng:include href="../../schema/teiHeader.rng"/>
  -->
  <xsl:template match="rng:include" mode="inc">
    <xsl:param name="context"/>
    <xsl:choose>
      <!-- if include as a link -->
      <xsl:when test="$incAsLink != '' and @h:href">
        <h2>
          <xsl:attribute name="id">
            <xsl:call-template name="getFile"/>
          </xsl:attribute>
          <a href="{@h:href}">
            <xsl:choose>
              <xsl:when test="@h:title">
                <xsl:value-of select="@h:title"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="@href"/>
              </xsl:otherwise>
            </xsl:choose>
          </a>
        </h2>
      </xsl:when>
      <!-- inclusion -->
      <xsl:otherwise>
        <xsl:apply-templates select="document(@href, .)/*/node()" mode="inc">
          <xsl:with-param name="context">
            <xsl:call-template name="getFolder">
              <xsl:with-param name="path" select="concat($context, @href)"/>
            </xsl:call-template>
          </xsl:with-param>
        </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!-- get a folder path from a relative file path -->
  <xsl:template name="getFolder">
    <xsl:param name="path"/>
    <xsl:choose>
      <xsl:when test="contains($path, '/')">
        <xsl:value-of select="substring-before($path, '/')"/>
        <xsl:text>/</xsl:text>
        <xsl:call-template name="getFolder">
          <xsl:with-param name="path" select="substring-after($path, '/')"/>
        </xsl:call-template>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <!-- Get a folder name from a file path -->
  <xsl:template name="getFile">
    <xsl:param name="path" select="@href"/>
    <xsl:choose>
      <xsl:when test="contains($path, '/')">
        <xsl:call-template name="getFile">
          <xsl:with-param name="path" select="substring-after($path, '/')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$path"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


</xsl:transform>

<?xml version="1.0" encoding="UTF-8"?>
<!--
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


Part of RngDoc, documentation of Relax-NG schema 
multi-file split
-->
<xsl:transform version="1.1"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0"
  xmlns:rng="http://relaxng.org/ns/structure/1.0"
   
  exclude-result-prefixes="rng a"  
>
  <xsl:import href="rng2html.xsl"/>
  <!-- extension for links, allow clean uris under some server  -->
  <xsl:param name="_html">.html</xsl:param>
  <!-- folder where to generate the files -->
  <xsl:param name="dir"/>
  <!-- Other css -->
  <xsl:param name="css"/>
  <!-- Documentation du Schéma EAD avec transfromation des exemples -->
  <xsl:template match="/">
    <!-- frameset -->
    <xsl:document href="{$dir}index.html"  encoding="UTF-8" indent="yes" method="xml" cdata-section-elements="script">
      <html>
        <head>
          <title>
            <xsl:value-of select="$title"/>
          </title>
          <script type="text/javascript">
targetPage = "" + window.location.search;
if (targetPage != "") if (targetPage != "undefined") targetPage = targetPage.substring(1);
if (targetPage.indexOf(":") != -1) targetPage = "undefined";
function loadFrames() {
  if (targetPage != "") if(targetPage != "undefined") top.article.location = top.targetPage;
}
         </script>
        </head>
        <frameset cols="25%,*" onload="top.loadFrames()">
          <frame name="nav" src="nav.html" />
          <frame name="article" src="welcome.html"/>
        </frameset>
      </html>
    </xsl:document>
    <xsl:document href="{$dir}nav.html"  encoding="UTF-8" indent="yes" method="xml">
      <xsl:text disable-output-escaping='yes'>&lt;!DOCTYPE html>
</xsl:text>
      <html>
        <head>
          <meta charset="utf-8"/>
          <title>
            <xsl:call-template name="docmess">
              <xsl:with-param name="id">navigation</xsl:with-param>
            </xsl:call-template>
            <xsl:text>, </xsl:text>
            <xsl:value-of select="$title"/>
          </title>
          <base target="article"/>
          <link rel="stylesheet" type="text/css" href="xmldoc.css"/>
        </head>
        <body class="xmldoc nav rng">
          <h1><a href="index{$_html}" target="_top"><xsl:value-of select="$title"/></a></h1>
          <xsl:call-template name="index-els"/>
          <xsl:call-template name="index-atts"/>
          <xsl:call-template name="index-macros"/>
          <p> </p>
          <xsl:call-template name="docmess">
            <xsl:with-param name="id">powered</xsl:with-param>
          </xsl:call-template>
        </body>
      </html>
    </xsl:document>
    <!-- Collect html for a welcome page -->
    <xsl:variable name="html">
      <xsl:apply-templates select="/*/html:*"/>
    </xsl:variable>
    <xsl:call-template name="document">
      <xsl:with-param name="id">welcome</xsl:with-param>
      <xsl:with-param name="title" select="$title"/>
      <xsl:with-param name="html">
        <xsl:copy-of select="$html"/>
        <xsl:call-template name="index-els"/>
        <xsl:call-template name="index-atts"/>
        <xsl:call-template name="index-macros"/>
      </xsl:with-param>
    </xsl:call-template>
    <!-- Process schema content -->
    <xsl:apply-templates select="/rng:grammar/rng:*"/>
  </xsl:template>


  <!-- Link destination, multifile override (still buggy with attributes like xlink:*) -->
  <xsl:template name="href">
    <xsl:variable name="define" select="ancestor-or-self::rng:define[1]"/>
    <xsl:variable name="filename">
      <xsl:choose>
        <!-- Lets say, all elements should have an entry as a file -->
        <xsl:when test="ancestor-or-self::rng:element">
          <xsl:for-each select="ancestor-or-self::rng:element[1]">
            <xsl:call-template name="id"/>
          </xsl:for-each>
        </xsl:when>
        <!-- macro with only one element, link on the element -->
        <xsl:when test="count($define//rng:element[not(ancestor::rng:element)]) = 1">
          <xsl:for-each select="(ancestor-or-self::rng:define[1]//rng:element)[1]">
            <xsl:call-template name="id"/>
          </xsl:for-each>
        </xsl:when>
        <!-- Macro with only one global attribute -->
        <xsl:when test="count($define//rng:attribute[not(ancestor::rng:element)]) = 1">
          <xsl:for-each select="(ancestor-or-self::rng:define[1]//rng:attribute)[1]">
            <xsl:call-template name="id"/>
          </xsl:for-each>
        </xsl:when>
        <!-- Sadly, should for now replicate the logic of <xsl:template match="rng:attribute"> -->
        <xsl:when test="ancestor-or-self::rng:attribute[html:*]">
          <xsl:for-each select="ancestor-or-self::rng:attribute[1]">
            <xsl:call-template name="id"/>
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <xsl:for-each select="ancestor-or-self::rng:define[1]">
            <xsl:call-template name="id"/>
          </xsl:for-each>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="id">
      <xsl:call-template name="id"/>
    </xsl:variable>
    <xsl:variable name="href">
      <xsl:choose>
        <!-- The caller should have verify if this reference to a a macro can open an entry -->
        <xsl:when test="self::rng:ref">
          <xsl:call-template name="id"/>
          <xsl:value-of select="$_html"/>
        </xsl:when>
        <!-- Element inside an example -->
        <xsl:when test="ancestor::a:example">
          <xsl:value-of select="$id"/>
          <xsl:value-of select="$_html"/>
        </xsl:when>
        <!-- Common case (element, macro…) -->
        <xsl:otherwise>
          <xsl:value-of select="$filename"/>
          <xsl:value-of select="$_html"/>
          <xsl:if test="$filename != $id">
            <xsl:text>#</xsl:text>
            <xsl:value-of select="$id"/>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="$href != ''">
      <xsl:attribute name="href">
        <xsl:value-of select="$href"/>
      </xsl:attribute>
    </xsl:if>
  </xsl:template>
  
  <!-- Override the document template, to output an html file -->
  <xsl:template name="document">
    <xsl:param name="html"/>
    <xsl:param name="title">
      <xsl:choose>
        <xsl:when test="self::rng:attribute">@<xsl:value-of select="@name|rng:name"/><xsl:text> </xsl:text></xsl:when>
        <xsl:when test="self::rng:element">&lt;<xsl:value-of select="@name|rng:name"/>&gt; </xsl:when>
        <xsl:when test="self::rng:define"><xsl:value-of select="@name"/>() </xsl:when>
      </xsl:choose>
      <xsl:call-template name="title">
        <xsl:with-param name="type">text</xsl:with-param>
      </xsl:call-template>
      <xsl:text> </xsl:text>
      <!-- Global title of schema -->
      <xsl:value-of select="$title"/>
    </xsl:param>
    <xsl:param name="id">
      <xsl:call-template name="id"/>
    </xsl:param>
    <xsl:variable name="href">
      <xsl:value-of select="$id"/>
      <xsl:text>.html</xsl:text>
    </xsl:variable>
    <xsl:document href="{$dir}{$href}"  encoding="UTF-8" indent="yes" method="xml">
      <xsl:text disable-output-escaping='yes'>&lt;!DOCTYPE html>
</xsl:text>
      <html lang="fr">
        <head>
          <meta charset="utf-8"/>
          <script type="text/javascript" xml:space="preserve">
var uri=window.top.location.pathname;
uri=uri.substring(0, uri.lastIndexOf('/')+1);
if(window.top != window) {
  window.top.document.title=document.title 
  if (window.top.history.replaceState) {
    window.parent.history.replaceState("article", document.title, uri+'<xsl:value-of select="$href"/>?nav');
  }
} else if (window.location.search == "?nav") { // nav in frame requested
  window.location.replace(uri+'index.html?<xsl:value-of select="$href"/>');
}
          </script>
          <title><xsl:value-of select="$title"/></title>
          <link rel="stylesheet" type="text/css" href="xmldoc.css"/>
          <xsl:if test="$css != ''">
            <link rel="stylesheet" type="text/css" href="{$css}"/>
          </xsl:if>
        </head>
        <body class="xmldoc rng item">
          <header id="header"><a href="welcome.html">Présentation</a> | <a target="_top" href="index.html?{$href}">frames</a> | <a target="_top" href="{$href}">no frames</a></header>
          <!--
          <iframe height="100%" width="349" src="nav.html" frameborder="0" name="nav" id="iframe"><xsl:text> </xsl:text></iframe>
          -->
          <xsl:copy-of select="$html"/>
          <footer id="footer">
            <xsl:copy-of select="$title"/>
            <span style="float:right">
              <xsl:call-template name="docmess">
                <xsl:with-param name="id">powered</xsl:with-param>
              </xsl:call-template>
            </span>
          </footer>
        </body>
      </html>
    </xsl:document>
  </xsl:template>

</xsl:transform>

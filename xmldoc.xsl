<?xml version="1.0" encoding="UTF-8"?>
<!--
Xrem, common templates

Copyright © 2004-2017 Frédéric Glorieux
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
<xsl:transform
  version="1.1"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
  exclude-result-prefixes="rdf rdfs"


  xmlns:exslt="http://exslt.org/common"
  xmlns:saxon="http://icl.com/saxon"
  xmlns:date="http://exslt.org/dates-and-times"
  extension-element-prefixes="exslt saxon date"
>
  <!-- Generation date, maybe set by caller if no xslt -->
  <xsl:param name="modified">
    <xsl:choose>
      <xsl:when test="function-available('date:date')">
        <xsl:value-of select="date:date()"/>
      </xsl:when>
      <xsl:otherwise>2013</xsl:otherwise>
    </xsl:choose>
  </xsl:param>
  <!--  Base folder from which resolve some relative links, maybe infered from processing instruction <?xml-stylesheet. -->
  <xsl:param name="base">
    <xsl:call-template name="xsl_base"/>
  </xsl:param>
  <!-- Lien vers une css (surchargeable). Link for a CSS. -->
  <xsl:param name="css">
    <xsl:choose>
      <xsl:when test="/processing-instruction('css')">
        <xsl:value-of select="processing-instruction('css')"/>
      </xsl:when>
      <!--
      <xsl:when test="$base">
        <xsl:value-of select="$base"/>
        <xsl:text>xmldoc.css</xsl:text>
      </xsl:when>
      <xsl:otherwise>??? github ? xmldoc.css</xsl:otherwise>
      -->
    </xsl:choose>
  </xsl:param>
  <!-- Lang, for generated messages, or mayb to select docmentation -->
  <xsl:param name="lang" select="/*/@xml:lang"/>
  <!-- Files of messages  -->
  <xsl:variable name="xmldoc.rdfs" select="document('xmldoc.rdfs', document(''))/*/rdf:Property"/>
  <!-- A non breakable spaces bar -->
  <xsl:variable name="nbsp">                                                                                                     </xsl:variable>
  <!-- pour conversion -->
  <xsl:variable name="MAJ">AÀÂÄBCÇDEÉÈËÊFGHIÎÏJKLMNOÔÖPQRSTUÛÜVWXYZ_.-</xsl:variable>
  <xsl:variable name="min">aaaabccdeeeeefghiiijklmnooopqrstuuuvwxyz___</xsl:variable>
  <xsl:variable name="abc">_abcdefghijklmnopqrstuvwxyz</xsl:variable>
  <!-- Racine, créer un document HTML par défaut. Root, an HTML doc. -->
  <xsl:template match="/"><xsl:text disable-output-escaping='yes'>&lt;!DOCTYPE html>
</xsl:text>
    <html>
      <head>
        <meta http-equiv="Content-type" content="text/html; charset=UTF-8" />
        <xsl:choose>
          <xsl:when test="normalize-space($css) != ''">
            <link rel="stylesheet" type="text/css" href="{$css}"/>
          </xsl:when>
          <xsl:otherwise>
            <style type="text/css">
              <xsl:value-of select="document('xmldoc.css')/comment()"/>
            </style>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:call-template name="head"/>
      </head>
      <body>
        <xsl:attribute name="class">
          <xsl:text>xmldoc </xsl:text>
          <xsl:choose>
            <xsl:when test="namespace-uri(*)='http://relaxng.org/ns/structure/1.0'">rng</xsl:when>
            <xsl:when test="namespace-uri(*)='http://www.w3.org/1999/XSL/Transform'">xsl</xsl:when>
          </xsl:choose>
        </xsl:attribute>
        <xsl:apply-templates/>
      </body>
    </html>
  </xsl:template>

  <!-- Template à surcharger permettant d'ajouter du contenu dans l'entête -->
  <xsl:template name="head"/>

  <!-- pour obtenir un chemin relatif à l'XSLT appliquée -->
  <xsl:template name="xsl_base">
    <xsl:param name="path" select="/processing-instruction('xml-stylesheet')[1]"/>
    <xsl:choose>
      <xsl:when test="contains($path, 'href=&quot;')">
        <xsl:call-template name="xsl_base">
          <xsl:with-param name="path" select="substring-after($path, 'href=&quot;')"/>
        </xsl:call-template>
      </xsl:when>
      <!-- au cas où le type est après le href -->
      <xsl:when test="contains($path, '&quot;')">
        <xsl:call-template name="xsl_base">
          <xsl:with-param name="path" select="substring-before($path, '&quot;')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($path, '/')">
        <xsl:value-of select="substring-before($path, '/')"/>
        <xsl:text>/</xsl:text>
        <xsl:call-template name="xsl_base">
          <xsl:with-param name="path" select="substring-after($path, '/')"/>
        </xsl:call-template>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  
    <!-- Message, intitulé court d'un élément TEI lorsque disponible -->
  <xsl:template name="docmess">
    <xsl:param name="id" select="local-name()"/>
    <xsl:choose>
      <xsl:when test="$xmldoc.rdfs[@xml:id = $id]/rdfs:label[@xml:lang!=''][starts-with( $lang, @xml:lang)]">
        <xsl:copy-of select="$xmldoc.rdfs[@xml:id = $id]/rdfs:label[@xml:lang!=''][starts-with( $lang, @xml:lang)]/node()"/>
      </xsl:when>
      <xsl:when test="$xmldoc.rdfs[@xml:id = $id]/rdfs:label">
        <xsl:copy-of select="$xmldoc.rdfs[@xml:id = $id]/rdfs:label[1]/node()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$id"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


</xsl:transform>

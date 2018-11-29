<?xml version="1.0" encoding="UTF-8"?>
<!--

<h1>Relax-NG schema, documentation</h1>

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

This transformation is pure XSLT1, tested with xsltproc, saxon 6 and 9,
msxml 3 and 4. Xalan is working on little schemas but crash on big ones
(Null Pointer Exception, a Java developper knows it is bug).

A Relax-NG schema is written to validate, not always to be readable.
The work of a documentation tool is to make a schema useful for humans.
For example, it should give fast answers to questions like: 
Why an <epigraph> is not allowed at the end of a <chapter>? Where may 
I put an <epigraph>, or what should I choose instead of an <epigraph> 
at the end of a <chapter>?

So, each entry should show 
 * attributes (for elements)
 * content in a compact view 
 * usage in other elements  
But what is an entry? Elements  are probably entries, but what 
about attributes? There a local attributes only declared in the context 
of one element. It is quite delicate to tune something informative for 
humans, with not too much generated rubish.

The macros (<define>) and references (<ref>) produce a network which
is not natural to follow in the hierarchical logic of xpath. There
are here some XSLT1 hacks to follow this network forward (content) and
backward (usage). This network has been kept without preprocessing reduction 
to a tree, because of two reasons. Imagine one macro for xlink attributes
allowed in 385 elements? It is heavy in memory, it is docbook. And also,
such organisation of macros is probably significative of an
author, communicating his reflexion on his model. Here also, there are 
some delicate tests tuned on different major schemas style.


-->
<xsl:transform  version="1.1"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:rng="http://relaxng.org/ns/structure/1.0"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:s="http://www.ascc.net/xml/schematron" 
  exclude-result-prefixes="rng a html s"

  xmlns:msxsl="urn:schemas-microsoft-com:xslt"
  xmlns:exslt="http://exslt.org/common"
  xmlns:str="http://exslt.org/strings"
  xmlns:saxon="http://saxon.sf.net/"
  xmlns:date="http://exslt.org/dates-and-times"
  extension-element-prefixes="exslt str saxon date msxsl"
>
  <!-- pretty-print xml in html -->
  <xsl:import href="xml2html.xsl"/>
  <!-- shared templates (<html>, css) -->
  <xsl:import href="xmldoc.xsl"/>
  <!-- 3 indent spaces = +60% Kb saxon:indent-spaces="0" :  Requested feature (custom serialization) requires Saxon-PE -->
  <xsl:output encoding="UTF-8" indent="yes" method="xml"/>
  <!-- Has been useful in some environments -->
  <xsl:param name="message"/>
  <!-- find a title for the doc -->
  <xsl:param name="title">
    <xsl:choose>
      <xsl:when test="/*/a:documentation">
        <xsl:value-of select="normalize-space(/*/a:documentation)"/>
      </xsl:when>
      <xsl:otherwise>Documentation</xsl:otherwise>
    </xsl:choose>
  </xsl:param>
  <!-- handle on all elements by id -->
  <xsl:key name="id" match="*" use="generate-id()"/>
  <!-- Threshold after which show macro link instead of expanded short view (needed for big schemas like docbook macro for links attributes) -->
  <xsl:param name="expandMax">10</xsl:param>
  <!-- punctuation in compact expressions -->
  <xsl:variable name="ponct">()!*+| #160;&amp;</xsl:variable>
  <!-- Macros -->
  <xsl:key name="define" match="rng:define" use="@name"/>
  <xsl:key name="ref" match="rng:ref" use="@name"/>
  <!-- Saxon6.5.5: The expressions in xsl:key may not contain references to variables -->
  <xsl:key name="def-ABC" match="rng:define" use="translate(substring(normalize-space(@name), 1, 1),
   'AÀÂÄBCÇDEÉÈËÊFGHIÎÏJKLMNOÔÖPQRSTUÛÜVWXYZ_.-',
   'aaaabccdeeeeefghiiijklmnooopqrstuuuvwxyz___')"/>
  <!-- Elements -->
  <xsl:key name="element" match="rng:element" use="@name|rng:name"/>
  <!-- Key for elements index -->
  <xsl:key name="el-ABC" match="rng:element" use="translate(substring(normalize-space(@name|rng:name), 1, 1),
    'AÀÂÄBCÇDEÉÈËÊFGHIÎÏJKLMNOÔÖPQRSTUÛÜVWXYZ_.-',
    'aaaabccdeeeeefghiiijklmnooopqrstuuuvwxyz___')"/>
  <!-- A key to loop on all attributes in alphabetic order for the attribute list in element table  -->
  <xsl:key name="atts" match="rng:attribute" use="1"/>
  <!-- Global attributes, or atts with substantial doc -->
  <xsl:key name="attribute" match="rng:attribute[not(ancestor::rng:element|html:*)]" use="@name|rng:name"/>
  <!-- Key for attribute index -->
  <xsl:key name="att-ABC" match="rng:attribute[not(ancestor::rng:element)]" use="translate(substring(normalize-space(@name|rng:name), 1, 1),
    'AÀÂÄBCÇDEÉÈËÊFGHIÎÏJKLMNOÔÖPQRSTUÛÜVWXYZ_.-',
    'aaaabccdeeeeefghiiijklmnooopqrstuuuvwxyz___')"/>
  
  <!-- 
  <xsl:key name="defineDoc" match="rng:define[not(count(*)=1 and (local-name(*)='attribute' or local-name(*)='element'))]" use="@name|rng:name"/>

  -->
  <!-- Links to external documentations -->
  <xsl:template name="el-href">
    <xsl:variable name="name" select="@name|rng:name"/>
    <xsl:variable name="ns" select="ancestor::*[@ns][1]/@ns"/>
    <xsl:choose>
      <xsl:when test="$name = ''"/>
      <xsl:when test="$ns='http://docbook.org/ns/docbook'">
        <xsl:attribute name="href">
          <xsl:text>http://www.docbook.org/tdg51/en/html/</xsl:text>
          <xsl:value-of select="$name"/>
          <xsl:text>.html</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="target">TEI</xsl:attribute>
      </xsl:when>
      <xsl:when test="$ns='http://www.tei-c.org/ns/1.0'">
        <xsl:attribute name="href">
          <xsl:text>http://www.tei-c.org/release/doc/tei-p5-doc/fr/html/ref-</xsl:text>
          <xsl:value-of select="$name"/>
          <xsl:text>.html</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="target">TEI</xsl:attribute>
      </xsl:when>
      <xsl:when test="$ns='urn:isbn:1-931666-22-9' or $ns='urn:isbn:1-931666-22-9'">
        <xsl:attribute name="href">
          <xsl:text>http://www.loc.gov/ead/tglib/elements/</xsl:text>
          <xsl:value-of select="$name"/>
          <xsl:text>.html</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="target">EAD</xsl:attribute>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <!-- Check if current() should open a separate entry -->
  <xsl:template name="isEntry">
    <xsl:choose>
      <!-- Macro -->
      <xsl:when test="self::rng:define">
        <xsl:choose>
          <!-- Macro with only one reference, should be documented in caller only -->
          <xsl:when test="count(key('ref', @name)) = 1"/>
          <!-- Macro used as an handle on an element or an attribute, document the element or the attribute, not the macro -->
          <xsl:when test="count(rng:*) = 1 and rng:element or rng:attribute"/>
          <xsl:otherwise>
            <xsl:value-of select="1"/>
          </xsl:otherwise>
        </xsl:choose> 
      </xsl:when>
      <!-- Element -->
      <xsl:when test="self::rng:element">
        <xsl:choose>
          <!-- Local element should not open a new document but maybe an entry ? -->
          <xsl:when test="false()"/>
          <xsl:otherwise>
            <xsl:value-of select="1"/>
          </xsl:otherwise>
        </xsl:choose> 
      </xsl:when>
      <!-- Attribute -->
      <xsl:when test="self::rng:attribute">
        <xsl:choose>
          <!-- local att with no substantial doc -->
          <xsl:when test="ancestor::rng:element and not(html:*)"/>
          <!-- no intersting values -->
          <xsl:when test="not(*) or rng:value"/>
          <!-- alone in a macro called only 1 time, no complex data -->
          <xsl:when test="ancestor::rng:define and count(key('ref',ancestor::rng:define/@name) ) &lt; 1"/>
          <xsl:otherwise>
            <xsl:value-of select="1"/>
          </xsl:otherwise>
        </xsl:choose> 
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  <!-- Centralize generation of a link on a element, easier to tune perfomance -->
  <xsl:template name="a">
    <a>
      <xsl:call-template name="href"/>
      <!-- not qname
      <xsl:value-of select="@name|rng:name"/>
      <xsl:call-template name="title"/>
      -->
      <xsl:call-template name="qname"/>
    </a>
  </xsl:template>
  
  <xsl:template match="rng:include">
    <p>
      &lt;include href="<a href="{@href}"><xsl:value-of select="@href"/></a>"&gt;
    </p>
  </xsl:template>

  <!-- root element -->
  <xsl:template match="rng:grammar">
    <xsl:call-template name="nav"/>
    <article id="article" class="{local-name()}">
      <xsl:apply-templates/>
    </article>
    <script><xsl:text disable-output-escaping="yes">
var els = document.getElementsByTagName('a');
for(var i = 0, len = els.length; i &lt; len; i++) {
  if (els[i].title) continue;
  els[i].onmouseover = function () {
    var t0 = performance.now();
    if (this.title) return true;
    if (!this.hash) return true;
    var id = this.hash.substring(1);
    if (!id) return true;
    var div = document.getElementById(id);
    if (!div) return true;
    var header = div.getElementsByTagName('header');
    if (header.length == 0) return true;
    this.title = header[0].textContent;
    return true;
  }
}      
    </xsl:text></script>
  </xsl:template>
  <!-- Sometimes useful for override -->
  <xsl:template name="document">
    <xsl:param name="html"/>
    <xsl:copy-of select="$html"/>
  </xsl:template>
  <!-- TODO, Welcome page of documentation for multipage-doc -->
  <!-- Navigation -->
  <xsl:template name="nav">
    <nav id="nav">
      <p> </p>
      <a style="font-weight:bold; color:#000000;">
        <xsl:call-template name="href"/>
        <xsl:value-of select="$title"/>
      </a>
      <!-- Documentation of start element is not interesting for Docbook
      <section>
        <b>
          <xsl:call-template name="message">
            <xsl:with-param name="id">start</xsl:with-param>
          </xsl:call-template>
        </b>
        <xsl:call-template name="compact">
          <xsl:with-param name="mode">start</xsl:with-param>
        </xsl:call-template>
      </section>
      Start elements -->
      <!-- Schemas organized by <div>, a table of contents is possible -->
      <xsl:if test="/rng:grammar/rng:div[a:documentation]">
        <section>
          <xsl:apply-templates mode="toc"/>
        </section>
      </xsl:if>
      <xsl:call-template name="index-els"/>
      <xsl:call-template name="index-atts"/>
      <xsl:call-template name="index-macros"/>
      <p> </p>
    </nav>
  </xsl:template>  
  <!-- By default, control all text outputs -->
  <xsl:template match="text()" mode="toc"/>
  <!-- By default, go throw -->
  <xsl:template match="*" mode="toc">
    <xsl:apply-templates select="*" mode="toc"/>
  </xsl:template>
  <xsl:template match="rng:div" mode="toc">
    <xsl:variable name="level" select="count(ancestor-or-self::rng:div)"/>
    <div style="margin-left:{$level}em;">
      <a style="font-weight:bold; color:#000000;">
        <xsl:call-template name="href"/>
        <xsl:choose>
          <xsl:when test="a:documentation">
            <xsl:value-of select="a:documentation"/>
          </xsl:when>
          <xsl:when test="@xml:id">
            <xsl:value-of select="@xml:id"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:number format="1.1" level="multiple"/>
          </xsl:otherwise>
        </xsl:choose>
      </a>
    </div>
    <div>
      <xsl:apply-templates select="*" mode="toc"/>
    </div>
  </xsl:template>
  <xsl:template match="/*" mode="toc">
    <div>
      <a style="font-weight:bold; color:#000000;">
        <xsl:call-template name="href"/>
        <xsl:choose>
          <xsl:when test="a:documentation">
            <xsl:value-of select="a:documentation"/>
          </xsl:when>
          <xsl:when test="@xml:id">
            <xsl:value-of select="@xml:id"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>Documentation</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </a>
    </div>
    <div>
      <xsl:apply-templates select="*" mode="toc"/>
    </div>
  </xsl:template>
  <xsl:template match="rng:element" mode="toc">
    <a>
      <xsl:call-template name="href"/>
      <xsl:text>&lt;</xsl:text>
      <xsl:call-template name="qname"/>
      <xsl:text>&gt;</xsl:text>
    </a>
    <xsl:text> </xsl:text>
  </xsl:template>  
  <!-- For overriding, target for links inside schema -->
  <xsl:template name="href">
    <xsl:attribute name="href">
      <xsl:text>#</xsl:text>
      <xsl:call-template name="id"/>
    </xsl:attribute>
  </xsl:template>
  <!-- 
  Find the best relevant <a:documentation> for the context node
  Relax-NG documentation
  http://relaxng.org/compatibility-20011203.html#IDAC1YR

  -->
  <xsl:template name="a:documentation">
    <!-- no limit -->
    <xsl:param name="count">-1</xsl:param>
    <xsl:param name="lang" select="$lang"/>
    <xsl:choose>
      <!-- first child is doc, loop on it -->
      <xsl:when test="name(*[1])='a:documentation'">
        <xsl:for-each select="*[1]">
          <xsl:call-template name="doc-loop">
            <xsl:with-param name="count" select="$count"/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:when>
      <!-- otherwise, test following sibling -->
      <xsl:when test="name(following-sibling::*[1])='a:documentation'">
        <xsl:for-each select="following-sibling::*[1]">
          <xsl:call-template name="doc-loop">
            <xsl:with-param name="count" select="$count"/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="doc-loop">
    <xsl:param name="count"/>
    <xsl:choose>
      <!-- stop loop, not doc -->
      <xsl:when test="not(self::a:documentation)"/>
      <!-- no more desired, stop here -->
      <xsl:when test="$count = 0"></xsl:when>
      <!-- TODO, localize -->
      <xsl:otherwise>
        <xsl:if test=". != ''">
          <xsl:apply-templates select="."/>
        </xsl:if>
        <xsl:for-each select="following-sibling::*[1]">
          <xsl:call-template name="doc-loop">
            <xsl:with-param name="count" select="$count -1"/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!-- 
    For an html @title attribute
  -->
  <xsl:template name="title">
    <xsl:param name="mode">attribute</xsl:param>
    <xsl:param name="count">
      <xsl:if test="$mode = 'attribute'">1</xsl:if>
    </xsl:param>
    <xsl:variable name="title">
      <xsl:choose>
        <!-- Ref to an element, bubble the first doc text -->
        <xsl:when test="self::a:el">
          <xsl:for-each select="key('element', substring-before(concat(normalize-space(.),' '), ' '))[1]">
            <!-- infinite loop possible if rng:element[@name='A']/a:documentation/a:el[text()='B'] and 
              rng:element[@name='B']/a:documentation/a:el[text()='A']
            <xsl:call-template name="a:documentation">
              <xsl:with-param name="count" select="$count"/>
            </xsl:call-template>
            -->
          </xsl:for-each>
        </xsl:when>
        <!-- Ref to an attribute -->
        <xsl:when test="self::a:att">
          <xsl:for-each select="key('attribute', substring-before(concat(normalize-space(.),' '), ' '))[1]">
            <xsl:call-template name="a:documentation">
              <xsl:with-param name="count" select="$count"/>
            </xsl:call-template>
          </xsl:for-each>
        </xsl:when>
        <!-- Convenient macro for one element, take doc from element -->
        <xsl:when test="self::rng:define and count(*)=1">
          <xsl:for-each select="*">
            <xsl:call-template name="a:documentation">
              <xsl:with-param name="count" select="$count"/>
            </xsl:call-template>
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="a:documentation">
            <xsl:with-param name="count" select="$count"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$title = ''"/>
      <xsl:when test="$mode = 'html'">
        <xsl:copy-of select="$title"/>
      </xsl:when>
      <xsl:when test="$mode = 'attribute'">
        <xsl:attribute name="title">
          <xsl:value-of select="$title"/>
        </xsl:attribute>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$title"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Elements index -->
  <xsl:template name="index-els">
    <section class="index">
      <header>
        <xsl:call-template name="docmess">
          <xsl:with-param name="id">elements</xsl:with-param>
        </xsl:call-template>
        <xsl:variable name="count">
          <xsl:for-each select="//rng:element">
            <xsl:call-template name="isEntry"/>
          </xsl:for-each>
        </xsl:variable>
        <xsl:text> (</xsl:text>
        <xsl:value-of select="string-length($count)"/>
        <xsl:text>)</xsl:text>
      </header>
      <xsl:call-template name="alphaList">
        <xsl:with-param name="key">el-ABC</xsl:with-param>
      </xsl:call-template>
    </section>
  </xsl:template>


  <!-- Attributes index -->
  <xsl:template name="index-atts">
    <section class="index">
      <header>
        <xsl:call-template name="docmess">
          <xsl:with-param name="id">attributes</xsl:with-param>
        </xsl:call-template>
      </header>
      <xsl:call-template name="alphaList">
        <xsl:with-param name="key">att-ABC</xsl:with-param>
      </xsl:call-template>
    </section>
  </xsl:template>

  <!-- macros index -->
  <xsl:template name="index-macros">
    <xsl:variable name="content">
      <xsl:call-template name="alphaList">
        <xsl:with-param name="key">def-ABC</xsl:with-param>
      </xsl:call-template>
    </xsl:variable>
    <xsl:if test="$content != ''">
      <section class="index">
        <header>
          <xsl:call-template name="docmess">
            <xsl:with-param name="id">macros</xsl:with-param>
          </xsl:call-template>
        </header>
        <xsl:copy-of select="$content"/>
      </section>
    </xsl:if>
  </xsl:template>
  
  <!-- Alphabetic bar -->
  <xsl:template name="alphaList">
    <!-- A list of ids to filter -->
    <xsl:param name="idFilter"/>
    <!-- alphabetic key to explore -->
    <xsl:param name="key"/>
    <!-- the alphabet -->
    <xsl:param name="abc" select="$abc"/>
    <xsl:variable name="letter" select="substring($abc, 1, 1)"/>
    <xsl:variable name="list" select="key($key, $letter)"/>
    <xsl:choose>
      <!-- No more letter, stop -->
      <xsl:when test="$letter=''"/>
      <!-- Nothing for this letter, go next -->
      <xsl:when test="not($list)">
        <xsl:call-template name="alphaList">
          <xsl:with-param name="key" select="$key"/>
          <xsl:with-param name="abc" select="substring($abc, 2)"/>
          <xsl:with-param name="idFilter" select="$idFilter"/>
        </xsl:call-template>
      </xsl:when>
      <!-- We should have items, be careful in case of filtered macros -->
      <xsl:otherwise>
        <xsl:variable name="content">
          <xsl:for-each select="$list">
            <xsl:sort select="@name|rng:name"/>
            <xsl:variable name="isEntry">
              <xsl:call-template name="isEntry"/>
            </xsl:variable>
            <xsl:choose>
              <!-- filter ids -->
              <xsl:when test="$idFilter != '' and not(contains($idFilter, concat(' ',generate-id(), ' ')))"/>
              <!-- Not an entry, but let idFilter override isEntry -->
              <xsl:when test="$idFilter = '' and $isEntry=''"/>
              <xsl:otherwise>
                <xsl:text> </xsl:text>
                <xsl:choose>
                  <xsl:when test="self::rng:attribute">@</xsl:when>
                  <xsl:when test="self::rng:element">&lt;</xsl:when>
                </xsl:choose>
                <xsl:call-template name="a"/>
                <xsl:choose>
                  <xsl:when test="self::rng:attribute"/>
                  <xsl:when test="self::rng:element">&gt;</xsl:when>
                  <xsl:when test="self::rng:define">()</xsl:when>
                </xsl:choose>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
        </xsl:variable>
        <xsl:if test="$content != ''">
          <div>
            <b>
              <xsl:value-of select="translate($letter, $min, $MAJ)"/>
            </b>
            <xsl:text>.</xsl:text>
            <xsl:copy-of select="$content"/>
            <xsl:text>  </xsl:text>
          </div>
          <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:call-template name="alphaList">
          <xsl:with-param name="idFilter" select="$idFilter"/>
          <xsl:with-param name="key" select="$key"/>
          <xsl:with-param name="abc" select="substring($abc, 2)"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- html, just copy -->
  <xsl:template match="*[namespace-uri()= 'http://www.w3.org/1999/xhtml'] | *[namespace-uri()= 'http://www.w3.org/1999/xhtml']/@* ">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>
  <!-- TODO -->
  <xsl:template match="rng:anyName | rng:notAllowed | rng:start">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- Displayble qname for elements or attributes -->
  <xsl:template name="qname">
    <xsl:variable name="name">
      <xsl:choose>
        <xsl:when test="rng:anyName">*</xsl:when>
        <xsl:when test="@name">
          <xsl:value-of select="@name"/>
        </xsl:when>
        <xsl:when test="rng:name">
          <xsl:value-of select="rng:name"/>
        </xsl:when>
        <xsl:when test="self::a:el or self::a:att">
          <xsl:value-of select="."/>
        </xsl:when>
         <xsl:otherwise>
          <xsl:value-of select="local-name()"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <!--
      Buggy ?
    <xsl:variable name="nsuri" select="ancestor::*[@ns][1]/@ns"/>
    <xsl:variable name="nsprefix">
      <xsl:if test="$nsuri">
        <xsl:value-of select="name(namespace::*[.=$nsuri])"/>
      </xsl:if>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="rng:anyName">*</xsl:when>
      <xsl:when test="not($nsprefix='')"><xsl:value-of select="$nsprefix"/>:<xsl:value-of select="$name"/></xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$name"/>
      </xsl:otherwise>
    </xsl:choose>
    -->
    <xsl:value-of select="$name"/>
    <!-- if element with fixed attributes -->
    <xsl:for-each select="rng:attribute[rng:value]">
      <small class="att">
        <xsl:text> </xsl:text>
        <xsl:value-of select="@name|rng:name"/>
        <xsl:text>="</xsl:text>
        <xsl:value-of select="rng:value"/>
        <xsl:text>"</xsl:text>
      </small>
    </xsl:for-each>
    <xsl:if test="rng:value">
      <xsl:text>="</xsl:text>
      <xsl:value-of select="rng:value"/>
      <xsl:text>"</xsl:text>
    </xsl:if>
  </xsl:template>
  
  <!-- Element -->
  <xsl:template match="rng:element">
    <xsl:variable name="name" select="@name|name"/>
    <!-- Maybe needed to avoir timeout on a server -->
    <xsl:if test="$message">
      <xsl:message><xsl:value-of select="$message"/></xsl:message>
    </xsl:if>
    <xsl:variable name="html">
      <section class="element rng">
        <xsl:attribute name="id">
          <xsl:call-template name="id"/>
        </xsl:attribute>
        <xsl:variable name="level" select="count(ancestor-or-self::rng:element)"/>
        <header class="element rng">
          <xsl:text>&lt;</xsl:text>
          <a>
            <xsl:call-template name="el-href"/>
            <xsl:call-template name="qname"/>
          </a>
          <xsl:text>&gt; </xsl:text>
          <xsl:apply-templates select="a:documentation"/>
        </header>
        <table class="grammar">
          <xsl:variable name="atts">
            <xsl:call-template name="children">
              <xsl:with-param name="mode">attid</xsl:with-param>
            </xsl:call-template>
          </xsl:variable>
          <xsl:if test="normalize-space($atts) != ''">
            <tr>
              <th>
                <xsl:call-template name="docmess">
                  <xsl:with-param name="id">attributes</xsl:with-param>
                </xsl:call-template>
              </th>
              <td>
                <table class="attributes">
                  <xsl:variable name="element" select="."/>
                  <xsl:for-each select="key('atts', 1)">
                    <xsl:sort select="@name|rng:name"/>
                    <xsl:variable name="id" select="generate-id()"/>
                    <xsl:variable name="card">
                      <xsl:choose>
                        <xsl:when test="contains($atts, concat(' ',$id,' '))">REQUIRED</xsl:when>
                        <xsl:when test="contains($atts, concat(' ',$id,'? '))">IMPLIED</xsl:when>
                      </xsl:choose>
                    </xsl:variable>
                    <xsl:if test="$card != ''">
                      <tr>
                        <xsl:choose>
                          <xsl:when test="$card = 'REQUIRED'">
                            <td class="name">
                              <xsl:text>@</xsl:text>
                              <a class="required">
                                <xsl:call-template name="href"/>
                                <!-- maybe needed for <anyName> -->
                                <xsl:call-template name="qname"/>
                              </a>
                            </td>
                            <td/>
                          </xsl:when>
                          <xsl:otherwise>
                            <td class="name">
                              <xsl:text>@</xsl:text>
                              <a>
                                <xsl:call-template name="href"/>
                                <xsl:value-of select="@name|rng:name"/>
                              </a>
                            </td>
                            <td>?</td>
                          </xsl:otherwise>
                        </xsl:choose>
                        <td>
                          <xsl:if test="@a:defaultValue">
                            <xsl:value-of select="@a:defaultValue"/>
                            <xsl:text> | </xsl:text>
                          </xsl:if>
                          <xsl:variable name="value">
                            <xsl:apply-templates select="rng:*" mode="compact">
                              <xsl:with-param name="mode">value</xsl:with-param>
                            </xsl:apply-templates>
                          </xsl:variable>
                          <xsl:copy-of select="$value"/>
                          <!-- Do not duplicate doc for referenced attribute -->
                          <xsl:if test="count(ancestor::rng:element|$element)=1">
                            <xsl:if test="$value != ''">
                              <br/>
                            </xsl:if>
                            <xsl:call-template name="a:documentation"/>
                          </xsl:if>
                        </td>
                      </tr>
                    </xsl:if>
                  </xsl:for-each>
                </table>
              </td>
            </tr>
          </xsl:if>
          <!-- Element list -->
          <!-- get children ids -->
          <xsl:variable name="idFilter">
            <xsl:call-template name="children">
              <xsl:with-param name="mode">id</xsl:with-param>
            </xsl:call-template>
          </xsl:variable>
          <xsl:if test="$idFilter != ''">
            <tr>
              <th>
                <xsl:call-template name="docmess">
                  <xsl:with-param name="id">children</xsl:with-param>
                </xsl:call-template>
              </th>
              <td class="children">
                <xsl:call-template name="alphaList">
                  <xsl:with-param name="key">el-ABC</xsl:with-param>
                  <xsl:with-param name="idFilter" select="$idFilter"/>
                </xsl:call-template>
              </td>
            </tr>
          </xsl:if>
          <!-- Content model -->
          <tr>
            <th>
              <xsl:call-template name="docmess">
                <xsl:with-param name="id">model</xsl:with-param>
              </xsl:call-template>
            </th>
            <td class="model">
              <!-- process children, instead the element, to avoid a part of punctuation problems with attributes -->
              <xsl:call-template name="compact">
                <xsl:with-param name="mode">element</xsl:with-param>
              </xsl:call-template>
            </td>
          </tr>
          <!-- Parents -->
          <xsl:variable name="usage">
            <xsl:call-template name="usage"/>
          </xsl:variable>
          <tr>
            <th>
              <xsl:call-template name="docmess">
                <xsl:with-param name="id">usage</xsl:with-param>
              </xsl:call-template>
            </th>
            <td class="usage">
              <xsl:copy-of select="$usage"/>
              <xsl:if test="$usage = ''">
                <xsl:call-template name="docmess">
                  <xsl:with-param name="id">unused</xsl:with-param>
                </xsl:call-template>
              </xsl:if>
            </td>
          </tr>
          <!-- See also, references to the element in code example or in the doc -->
          <!--
          <xsl:variable name="seealso">
            <xsl:call-template name="seealso"/>
          </xsl:variable>
          <xsl:if test="$seealso != ''">
            <tr>
              <th>
                <xsl:call-template name="docmess">
                  <xsl:with-param name="id">seealso</xsl:with-param>
                </xsl:call-template>
              </th>
              <td class="seealso">
                <xsl:copy-of select="$seealso"/>
              </td>
            </tr>
          </xsl:if>
          -->
        </table>
        <xsl:apply-templates select="*[name() != 'a:documentation']"/>
      </section>
    </xsl:variable>
    <!-- rng:element//rng:element[rng:text and not(a:documentation|h:*) and not(.//rng:attribute)] -->
    <xsl:choose>
      <!-- local element with no doc -->
      <xsl:when test="ancestor::rng:element and rng:text and not(a:documentation|html:*) and not(.//rng:attribute)"/>
      <xsl:otherwise>
        <xsl:call-template name="document">
          <xsl:with-param name="html" select="$html"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Information should be inside the abstract table  -->
  <xsl:template match="rng:data | rng:value">
  </xsl:template>
  <!-- wrap long text -->
  <xsl:template name="snip">
    <xsl:param name="text" select="."/>
    <xsl:choose>
      <xsl:when test="contains($text, '|')">
        <xsl:call-template name="snip">
          <xsl:with-param name="text" select="substring-before($text, '|')"/>
        </xsl:call-template>
        <xsl:text> | </xsl:text>
        <xsl:call-template name="snip">
          <xsl:with-param name="text" select="substring-after($text, '|')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$text"/>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>


  <!-- Attribute -->
  <xsl:template match="rng:attribute">
    <xsl:variable name="isEntry">
      <xsl:call-template name="isEntry"/>
    </xsl:variable>
    <xsl:choose>
      <!-- not an entry, do nothing (ex: local attribute with quite nothing to doc) -->
      <xsl:when test="$isEntry=''"/>
      <!-- local attribute, do not create page, no one will link on it -->
      <xsl:when test="ancestor::rng:element">
        <xsl:call-template name="attribute"/>
      </xsl:when>
      <!-- Referred attribute -->
      <xsl:otherwise>
        <xsl:call-template name="document">
          <xsl:with-param name="html">
            <xsl:call-template name="attribute"/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!-- Attribute content -->
  <xsl:template name="attribute">
    <section class="attribute rng">
      <xsl:attribute name="id">
        <xsl:call-template name="id"/>
      </xsl:attribute>
      <header class="attribute rng">
        <xsl:text>@</xsl:text>
        <b>
        <xsl:call-template name="qname"/>
        </b>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="a:documentation"/>
      </header>
      <table class="grammar">
        <tr>
          <th>
            <xsl:call-template name="docmess">
              <xsl:with-param name="id">value</xsl:with-param>
            </xsl:call-template>
          </th>
          <td>
            <xsl:apply-templates select="rng:*" mode="compact"/>
            <xsl:if test="not(rng:*)">
              <i>{text}</i>
            </xsl:if>
          </td>
        </tr>
        <!-- Parents -->
        <xsl:variable name="usage">
          <xsl:call-template name="usage"/>
        </xsl:variable>
        <tr>
          <th>
            <xsl:call-template name="docmess">
              <xsl:with-param name="id">usage</xsl:with-param>
            </xsl:call-template>
          </th>
          <td class="usage">
            <xsl:copy-of select="$usage"/>
            <xsl:if test="$usage = ''">
              <xsl:call-template name="docmess">
                <xsl:with-param name="id">unused</xsl:with-param>
              </xsl:call-template>
            </xsl:if>
          </td>
        </tr>
      </table>
      <xsl:apply-templates select="*[not(self::a:documentation)]"/>
    </section>
  </xsl:template>
  <!-- division -->
  <xsl:template match="rng:div">
    <section class="{local-name()}">
      <xsl:attribute name="id">
        <xsl:call-template name="id"/>
      </xsl:attribute>
      <xsl:apply-templates/>
    </section>
  </xsl:template>
  <xsl:template match="rng:group">
    <div class="{local-name()}">
      <xsl:apply-templates/>
    </div>
  </xsl:template>
  <xsl:template match="rng:mixed">
    <span class="{local-name()}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  <!-- Stop -->
  <xsl:template match="rng:empty | rng:ref | rng:text"/>
  <!-- Cross to find other attributes or elements (but do not process a:doc or html:* -->
  <xsl:template match="rng:choice | rng:oneOrMore | rng:optional | rng:zeroOrMore ">
    <xsl:apply-templates select="rng:*"/>
  </xsl:template>


    <!-- Definition (macro) -->
  <xsl:template match="rng:define">
    <xsl:variable name="name" select="@name"/>
    <xsl:variable name="combined">
      <xsl:if test="@combine">
        <xsl:value-of select="following::rng:define[@name=$name]"/>
      </xsl:if>
      <xsl:if test="not(@combine)">
        <xsl:value-of select="//rng:define[@name=$name and @combine]"/>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="nsuri">
      <xsl:choose>
        <xsl:when test="ancestor::rng:div[@ns][1]">
          <xsl:value-of select="ancestor::rng:div[@ns][1]/@ns"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="ancestor::rng:grammar[@ns][1]/@ns"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="isEntry">
      <xsl:call-template name="isEntry"/>
    </xsl:variable>
    <xsl:choose>
      <!-- if <def> is not a quite empty contener -->
      <xsl:when test="$isEntry != ''">
        <xsl:call-template name="document">
          <xsl:with-param name="html">
            <section class="define rng">
              <xsl:attribute name="id">
                <xsl:call-template name="id"/>
              </xsl:attribute>
              <header class="define rng">
                <b>
                  <xsl:value-of select="@name"/>
                  <xsl:text>() </xsl:text>
                </b>
                <xsl:call-template name="a:documentation"/>
              </header>
              <table class="grammar">
                <tr>
                  <th>
                    <xsl:call-template name="docmess">
                      <xsl:with-param name="id">content</xsl:with-param>
                    </xsl:call-template>
                  </th>
                  <td>
                    <xsl:call-template name="compact"/>
                      <!-- display attributes and elements -->
                    <!-- TODO, combine
                    <xsl:if test="@combine">
                      <xsl:apply-templates select="following::rng:define[@name=$name]" mode="define-combine"/>
                    </xsl:if>
                    <xsl:if test="not(@combine)">
                      <xsl:apply-templates select="//rng:define[@name=$name and @combine]" mode="define-combine"/>
                    </xsl:if>
                    -->
                  </td>
                </tr>
                <xsl:variable name="usage">
                  <!-- call parents -->
                  <xsl:call-template name="usage"/>
                </xsl:variable>
                <tr>
                  <th>Usage</th>
                  <td>
                    <xsl:copy-of select="$usage"/>
                    <xsl:if test="$usage=''">
                      <xsl:call-template name="docmess">
                        <xsl:with-param name="id">unused</xsl:with-param>
                      </xsl:call-template>
                    </xsl:if>
                  </td>
                </tr>
              </table>
              <xsl:apply-templates select="*[local-name() != 'documentation']"/>
            </section>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="rng:*"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

<!--
  Create an id for schema components
  Should be optimized the bast as possible
-->
  <xsl:template name="id">
    <xsl:choose>
      <xsl:when test="@xml:id">
        <xsl:value-of select="@xml:id"/>
      </xsl:when>
      <xsl:when test="@id">
        <xsl:value-of select="@id"/>
      </xsl:when>
      <!-- link to a macro (@name should be unique) -->
      <xsl:when test="self::rng:ref">
        <xsl:text>def_</xsl:text>
        <xsl:value-of select="@name"/>
      </xsl:when>
      <!-- element in an XML example of code, point on the first element with this name -->
      <xsl:when test="ancestor::a:example and self::*">
        <xsl:text>el_</xsl:text>
        <xsl:value-of select="local-name()"/>
      </xsl:when>
      <!-- An example -->
      <xsl:when test="self::a:example ">
        <xsl:text>ex_</xsl:text>
        <xsl:number count="a:example" level="any"/>
      </xsl:when>
      <!-- XALAN 2.7.0, h:* => ArrayIndexOutOfBoundsException Exception ?? -->
      <xsl:when test="namespace-uri()='http://www.w3.org/1999/xhtml'">
        <xsl:value-of select="generate-id()"/>
      </xsl:when>
      <!-- a shorthand to point on elements, will bug on multiple elements declaration -->
      <xsl:when test="self::a:el">
        <xsl:text>el_</xsl:text>
        <xsl:value-of select="translate(substring-before(concat(normalize-space(.), ' '), ' '), ':', '-')"/>
      </xsl:when>
      <!-- a shorthand to point on elements, not always perfect -->
      <xsl:when test="self::a:att">
        <xsl:text>att_</xsl:text>
        <xsl:value-of select="translate(substring-before(concat(normalize-space(.), ' '), ' '), ':', '-')"/>
      </xsl:when>
      <!-- Attribute, let say it is not here to decide if it should have doc or not -->
      <xsl:when test="ancestor-or-self::rng:attribute">
        <xsl:text>att_</xsl:text>
        <xsl:variable name="att" select="ancestor-or-self::rng:attribute[1]"/>
        <xsl:variable name="name" select="$att/@name | $att/rng:name"/>
        <xsl:value-of select="translate($name, ':', '-')"/>
        <xsl:for-each select="key('attribute', $name)">
          <xsl:choose>
            <xsl:when test="position()=1"/>
            <xsl:when test="count(.|$att)=1">
              <xsl:text>_</xsl:text>
              <xsl:value-of select="position()"/>
            </xsl:when>
          </xsl:choose>
        </xsl:for-each>
      </xsl:when>
      <!-- An element, or something in an element -->
      <xsl:when test="ancestor-or-self::rng:element">
        <xsl:text>el_</xsl:text>
        <xsl:variable name="el" select="ancestor-or-self::rng:element[1]"/>
        <xsl:variable name="name" select="$el/@name | $el/rng:name"/>
        <xsl:value-of select="$name"/>
        <xsl:for-each select="key('element', $name)">
          <xsl:choose>
            <xsl:when test="position()=1"/>
            <xsl:when test="count(.|$el)=1">
              <xsl:text>_</xsl:text>
              <xsl:value-of select="position()"/>
            </xsl:when>
          </xsl:choose>
        </xsl:for-each>
        <!-- long!
        <xsl:variable name="num">
          <xsl:number count="rng:element[@name = $name or rng:name = $name]" level="any"/>
        </xsl:variable>
        <xsl:if test="$num &gt; 1">
          <xsl:text>_</xsl:text>
          <xsl:value-of select="$num"/>
        </xsl:if>
        -->
      </xsl:when>
      <!-- Inside a macro called only one time, give hand to the caller -->
      <xsl:when test="ancestor-or-self::rng:define and count(key('ref',ancestor-or-self::rng:define/@name ))=1">
        <xsl:for-each select="key('ref',ancestor-or-self::rng:define/@name )">
          <xsl:call-template name="id"/>
        </xsl:for-each>
      </xsl:when>
      <!-- last case, link to the macro container (@name should be unique) -->
      <xsl:when test="ancestor-or-self::rng:define">
        <xsl:text>def_</xsl:text>
        <xsl:value-of select="@name"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="generate-id()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!--
Short view, find parents.
The elements has to been collected 
Idea is to collect the ids 
-->
  <xsl:template name="usage">
    <xsl:variable name="idFilter">
      <!--  -->
      <xsl:choose>
        <!-- for macro, give hand to the right template -->
        <xsl:when test="self::rng:define">
          <xsl:apply-templates select="." mode="usage">
            <xsl:with-param name="nodelist" select="nonode"/>
          </xsl:apply-templates>
        </xsl:when>
        <!-- for element or attribute, give hand to container user -->
        <xsl:otherwise>
          <xsl:apply-templates select=".." mode="usage">
            <xsl:with-param name="nodelist" select="nonode"/>
          </xsl:apply-templates>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$idFilter = ''">
        <xsl:call-template name="docmess">
          <xsl:with-param name="id">unused</xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="contains($idFilter, ' start ')">start. </xsl:if>
        <xsl:call-template name="alphaList">
          <xsl:with-param name="key">att-ABC</xsl:with-param>
          <xsl:with-param name="idFilter" select="$idFilter"/>
        </xsl:call-template>
        <xsl:call-template name="alphaList">
          <xsl:with-param name="key">el-ABC</xsl:with-param>
          <xsl:with-param name="idFilter" select="$idFilter"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!-- From a macro, find users of the macro -->
  <xsl:template match="rng:define" mode="usage">
    <xsl:param name="nodelist"/>
    <xsl:variable name="name" select="@name"/>
    <xsl:choose>
      <!-- Already crossed, stop now (or infinite loop) -->
      <xsl:when test="count($nodelist | .) = count($nodelist)"/>
      <!-- go to all references -->
      <xsl:otherwise>
        <xsl:apply-templates select="key('ref', $name)" mode="usage">
          <xsl:with-param name="nodelist" select="$nodelist | ."/>
        </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="rng:element | rng:attribute" mode="usage">
    <xsl:text> </xsl:text>
    <xsl:value-of select="generate-id()"/>
    <xsl:text> </xsl:text>
  </xsl:template>
  <xsl:template match="rng:start" mode="usage">
    <xsl:text> start </xsl:text>
  </xsl:template>
  <!-- Default for parents scan, go up -->
  <xsl:template match="*" mode="usage">
    <xsl:param name="nodelist"/>
    <xsl:apply-templates select=".." mode="usage">
      <xsl:with-param name="nodelist" select="$nodelist"/>
    </xsl:apply-templates>
  </xsl:template>
  <!-- Parents scan, scan reference -->
  <!--
  <xsl:template match="rng:ref" mode="usage">
    <xsl:param name="nodelist"/>
    <xsl:variable name="name" select="@name"/>
    <xsl:variable name="count" select="ancestor::rng:element[1]//rng:ref[@name=$name]|ancestor::rng:define[1]//rng:ref[@name=$name]"/>
    <xsl:choose>
      <xsl:when test="
      count($count[1] | .) = 1
      ">
        <xsl:apply-templates select="ancestor::rng:*[1]" mode="usage">
          <xsl:with-param name="nodelist" select="$nodelist"/>
        </xsl:apply-templates>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  -->

  <xsl:template match="rng:choice | rng:define | rng:group | rng:interleave | rng:list | rng:mixed | rng:oneOrMore | rng:optional | rng:zeroOrMore" mode="compact" name="compact" >
    <!-- inside an attribute -->
    <xsl:param name="mode"/>
    <!-- inherited separator -->
    <xsl:param name="sep"/>
    <!-- inherited quantifier -->
    <xsl:param name="quant"/>
    <!-- Count the kind of children -->
    <xsl:variable name="children">
      <xsl:call-template name="children"/>
    </xsl:variable>
    <xsl:variable name="quant2">
      <xsl:choose>
        <xsl:when test="self::rng:optional"> ? </xsl:when>
        <xsl:when test="self::rng:zeroOrMore"> * </xsl:when>
        <xsl:when test="self::rng:oneOrMore"> + </xsl:when>
        <xsl:when test="self::rng:mixed"> * </xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="sep2">
      <xsl:choose>
        <xsl:when test="self::rng:list"> : </xsl:when>
        <xsl:when test="self::rng:choice"> | </xsl:when>
        <xsl:when test="self::rng:mixed"> | </xsl:when>
        <xsl:when test="self::rng:interleave"> - </xsl:when>
        <xsl:when test="self::rng:group">, </xsl:when>
        <xsl:when test="self::rng:define">, </xsl:when>
        <!-- A hack for sequence in a element, first separator is a problem with atts -->
        <xsl:when test="self::rng:element">
          <xsl:text> </xsl:text>
        </xsl:when>
        <xsl:when test="self::rng:attribute"> - </xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:choose>
      <!-- mode element, and no elements or values, stop here -->
      <xsl:when test="($mode='element') and translate($children, '*TVD', '')=$children"/>      
      <!-- mode attribute, and no attribute, stop here (probably element content) -->
      <xsl:when test="$mode='attribute' and translate($children, '@', '')=$children"/>      
      <!-- Ex: zeroOrMore[choice], choice[value[2]] -->
      <xsl:when test="(count(rng:*)=1 and not(self::rng:mixed))">
        <xsl:apply-templates select="rng:*[not(self::rng:notAllowed)]" mode="compact">
          <xsl:with-param name="mode" select="$mode"/>
          <!-- give the quantifier to the nested (ex: macro) -->
          <xsl:with-param name="quant" select="$quant2"/>
          <!-- transmit inherited separator, for start of block -->
          <xsl:with-param name="sep" select="$sep"/>
        </xsl:apply-templates>
        <xsl:copy-of select="$quant"/>
      </xsl:when>
      <xsl:when test="$mode='attribute'">
        <xsl:copy-of select="$sep"/>
        <xsl:for-each select="rng:*[not(self::rng:notAllowed)]">
          <xsl:apply-templates select="." mode="compact">
            <xsl:with-param name="mode" select="$mode"/>
            <xsl:with-param name="sep">
              <xsl:if test="position() != 1">
                <xsl:copy-of select="$sep2"/>
              </xsl:if>
            </xsl:with-param>
            <xsl:with-param name="quant" select="$quant2"/>
          </xsl:apply-templates>         
        </xsl:for-each>
        <xsl:copy-of select="$quant"/>
      </xsl:when>
      <!--
      <xsl:when test="(rng:value|rng:data) and not($mode='attribute')">
        <ul class="values">
          <xsl:apply-templates select="rng:*[not(self::rng:notAllowed)]" mode="compact"/>
        </ul>
      </xsl:when>
      -->
      <xsl:otherwise>
        <span class="compact {local-name()}">
          <xsl:copy-of select="$sep"/>
          <xsl:if test="not(self::rng:element)">( </xsl:if>
          <xsl:if test="self::rng:mixed">text() </xsl:if>
          <xsl:for-each select="rng:*[not(self::rng:notAllowed)][not(self::rng:attribute)]">
            <xsl:apply-templates select="." mode="compact">
              <xsl:with-param name="mode" select="$mode"/>
              <xsl:with-param name="sep">
                <xsl:if test="position() != 1">
                  <xsl:copy-of select="$sep2"/>
                </xsl:if>
              </xsl:with-param>
            </xsl:apply-templates>         
          </xsl:for-each>
          <xsl:if test="not(self::rng:element)"> )</xsl:if>
          <xsl:value-of select="$quant2"/>
          <xsl:copy-of select="$quant"/>
        </span>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!-- element -->
  <xsl:template match="rng:element" mode="compact">
    <xsl:param name="mode"/>
    <xsl:param name="quant"/>
    <xsl:param name="sep"/>
    <xsl:choose>
      <!-- Attribute view, do not display elements -->
      <xsl:when test="$mode = 'attribute'"/>
      <xsl:otherwise>
        <xsl:copy-of select="$sep"/>
        <xsl:call-template name="a"/>
        <xsl:copy-of select="$quant"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- attribute, hidden for an element (detailed in the atts view)  -->
  <xsl:template match="rng:attribute" mode="compact">
    <xsl:param name="mode">attribute</xsl:param>
    <xsl:param name="sep"/>
    <xsl:param name="quant"/>
    <xsl:variable name="name" select="@name|rng:name"/>
    <xsl:choose>
      <!-- do not describe attributes here for an element -->
      <xsl:when test="$mode = 'element'"/>
      <xsl:when test="$mode = 'start'"/>
      <xsl:when test="rng:*">
        <xsl:copy-of select="$sep"/>
        <xsl:text>@</xsl:text>
        <xsl:call-template name="a"/>
        <xsl:text>="</xsl:text>
        <xsl:apply-templates select="rng:*" mode="compact">
          <!-- say we want values -->
          <xsl:with-param name="mode">value</xsl:with-param>
        </xsl:apply-templates>         
        <xsl:text>"</xsl:text>
        <xsl:copy-of select="$quant"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="$sep"/>
        <xsl:text>@</xsl:text>
        <xsl:call-template name="a"/>
        <xsl:copy-of select="$quant"/>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>

  
  <xsl:template match="rng:value " mode="compact">
    <xsl:param name="sep"/>
    <xsl:param name="mode"/>
    <xsl:variable name="title">
      <xsl:call-template name="title">
        <xsl:with-param name="mode">html</xsl:with-param>
      </xsl:call-template>   
    </xsl:variable>
    <xsl:variable name="value">
      <xsl:choose>
        <xsl:when test="self::rng:data">{<xsl:value-of select="@type"/>}</xsl:when>
        <xsl:when test=".=''">""</xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="."/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:choose>
      <!-- Mode=value is set by an attribute, means we are inside -->
      <xsl:when test="$mode = 'value'">
        <xsl:copy-of select="$sep"/>
        <span class="value">
          <xsl:call-template name="title">
            <xsl:with-param name="mode">attribute</xsl:with-param>
          </xsl:call-template>   
          <xsl:copy-of select="$value"/>
        </span>
      </xsl:when>
      <!-- if mode=attribute, means it is a value inside an element, (inside attribute, mode=value) -->
      <xsl:when test="$mode = 'attribute'"/>
      <!-- documented view -->
      <xsl:when test="$title != ''">
        <li class="value">
          <b class="value">
            <xsl:copy-of select="$value"/>
          </b>
          <xsl:text> — </xsl:text>
          <xsl:copy-of select="$title"/>
        </li>
      </xsl:when>
      <!-- normal -->
      <xsl:otherwise>
        <xsl:copy-of select="$sep"/>
        <span class="value">
          <xsl:copy-of select="$value"/>
        </span>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="rng:data" mode="compact">
    <xsl:param name="sep"/>
    <xsl:param name="mode"/>
    <xsl:variable name="title">
      <xsl:call-template name="title">
        <xsl:with-param name="mode">html</xsl:with-param>
      </xsl:call-template>
    </xsl:variable>
    <xsl:choose>
      <!-- Mode=value is set by an attribute, means we are inside -->
      <xsl:when test="$mode = 'value'">
        <xsl:copy-of select="$sep"/>
        <em class="data">
          <xsl:attribute name="title">
            <xsl:call-template name="title">
              <!-- first a:doc -->
              <xsl:with-param name="count">1</xsl:with-param>
            </xsl:call-template>
            <xsl:apply-templates select="rng:*"/>
          </xsl:attribute>
          <xsl:text>{</xsl:text>
          <xsl:value-of select="@type"/>
          <xsl:text>}</xsl:text>
        </em>
      </xsl:when>
      <!-- if mode=attribute, means it is a value inside an element, (inside attribute, mode=value) -->
      <xsl:when test="$mode = 'attribute'"/>
      <!-- documented view -->
      <xsl:when test="$title != '' or rng:param">
        <li class="value">
          <em class="data">
            <xsl:text>{</xsl:text>
            <xsl:value-of select="@type"/>
            <xsl:text>}</xsl:text>
          </em>
          <xsl:text> — </xsl:text>
          <xsl:copy-of select="$title"/>   
          <!-- Params -->
          <xsl:apply-templates select="rng:*" mode="compact"/>
        </li>
      </xsl:when>
      <!-- normal -->
      <xsl:otherwise>
        <xsl:copy-of select="$sep"/>
        <em class="data">
          <xsl:text>{</xsl:text>
          <xsl:value-of select="@type"/>
          <xsl:text>}</xsl:text>
        </em>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!-- </> -->
  <xsl:template match="rng:empty" mode="compact">
    <i>empty()</i>
  </xsl:template>
  <xsl:template match="rng:notAllowed" mode="compact">
    <i>notAllowed()</i>
  </xsl:template>
  <!-- référence -->
  <xsl:template match="rng:ref" mode="compact">
    <!-- for an element, an attribute, a macro… -->
    <xsl:param name="mode"/>
    <!-- binary operator between members -->
    <xsl:param name="sep"/>
    <!-- unary operator for the  -->
    <xsl:param name="quant"/>
    <!-- expand or collapse the content model -->
    <xsl:param name="expand">
      <xsl:choose>
        <!-- Compact view for an element -->
        <xsl:when test="$mode='element'"/>
        <xsl:otherwise>
          <xsl:value-of select="true()"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:param>
    <xsl:variable name="children">
      <!-- be careful, do not call the childre inside the ref, but corresponding define -->
      <xsl:call-template name="child"/>
    </xsl:variable>
    <xsl:variable name="ref" select="@name"/>
    <!-- see if refered macro is an entry with its own link -->
    <xsl:variable name="isEntry">
      <xsl:for-each select="key('define', $ref)">
        <xsl:call-template name="isEntry"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:choose>
      <!-- mode attribute, and no attributes or values, probably an element content macro, stop here -->
      <xsl:when test="$mode = 'attribute' and translate($children, '@', '')=$children"/>
      <!-- mode element or start, no element or values found, probably an attribute content macro, stop here -->
      <xsl:when test="($mode ='element' or $mode='start') and translate($children, '*TVD', '')=$children"/>
      <!-- a macro for only one child -->
      <xsl:when test="string-length($children) = 1">
        <xsl:copy-of select="$sep"/>
        <xsl:apply-templates select="key('define', $ref)" mode="compact">
          <xsl:with-param name="mode" select="$mode"/>
        </xsl:apply-templates>
        <xsl:copy-of select="$quant"/>
      </xsl:when>     
      <!-- a macro which is not an entry, go throw and forget its name (docbook example of unique macro: db.prompt.attlist(), db.prompt.inlines()) -->
      <xsl:when test="$isEntry=''">
        <xsl:copy-of select="$sep"/>
        <!-- parenthesis if a quantifier inherited -->
        <xsl:if test="$quant != ''">(</xsl:if>
        <xsl:apply-templates select="key('define', $ref)" mode="compact">
          <xsl:with-param name="mode" select="$mode"/>
        </xsl:apply-templates>
        <xsl:if test="$quant != ''">)</xsl:if>
        <xsl:copy-of select="$quant"/>
      </xsl:when>     
      <!-- mode attribute, and too much repetitions of the macro, only a link (docbook example: db.common.attributes()) -->
      <xsl:when test="$mode = 'attribute' and count(key('ref', @name)) &gt; 10">
        <xsl:copy-of select="$sep"/>
        <a class="ref">
          <xsl:call-template name="href"/>
          <xsl:call-template name="title"/>
          <xsl:value-of select="@name"/>
          <xsl:text>()</xsl:text>
        </a>
        <xsl:copy-of select="$quant"/>
      </xsl:when>     
      <!-- value list and lots of repetitions, a link -->
      <xsl:when test="count(key('ref', @name)) &gt; 3 and translate($children, 'TVD', '')=''">
        <xsl:copy-of select="$sep"/>
        <a class="ref">
          <xsl:call-template name="href"/>
          <xsl:call-template name="title"/>
          <xsl:value-of select="@name"/>
          <xsl:text>()</xsl:text>
        </a>
        <xsl:copy-of select="$quant"/>
      </xsl:when>     
      <!-- value list -->
      <xsl:when test="string-length(translate($children, 'TVD', '')) = 0 and string-length(translate($children, '@*', '')) &gt; 1">
        <xsl:apply-templates select="key('define', $ref)" mode="compact">
          <xsl:with-param name="mode" select="$mode"/>
          <xsl:with-param name="sep" select="$sep"/>
        </xsl:apply-templates>
        <xsl:copy-of select="$quant"/>
      </xsl:when>
      <!-- Mode attribute, short view for attributes values -->
      <!-- more than one element, implement an hide/show -->
      <xsl:when test="(string-length($children) - string-length(translate($children, '*', ''))) &gt; 1">
        <span>
          <xsl:attribute name="class">
            <xsl:choose>
              <!-- Show -->
              <xsl:when test="$expand != ''">less</xsl:when>
              <!-- Hide -->
              <xsl:otherwise>more</xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:copy-of select="$sep"/>
          <a class="ref">
            <xsl:call-template name="href"/>
            <xsl:call-template name="title"/>
            <xsl:value-of select="@name"/>
          </a>
          <xsl:text> (</xsl:text>
          <a class="toggle">
            <xsl:attribute name="onclick">o=this.parentNode; if(o.className=='more'){o.className='less'; this.innerHTML='▽';} else {o.className='more';this.innerHTML='►'}</xsl:attribute>
            <!-- espace insécable <xsl:text> </xsl:text> -->
            <xsl:choose>
              <!-- Show -->
              <xsl:when test="$expand != ''">▽</xsl:when>
              <!-- hide -->
              <xsl:otherwise>►</xsl:otherwise>
            </xsl:choose>
          </a>
          <span class="refin">
            <xsl:apply-templates select="key('define', $ref)" mode="compact">
              <xsl:with-param name="mode" select="$mode"/>
            </xsl:apply-templates>
          </span>
          <xsl:text>)</xsl:text>
          <xsl:copy-of select="$quant"/>
        </span>
      </xsl:when>
      <!-- seems only one element -->
      <xsl:when test="contains($children, '*')">
        <!-- Output inherited sep now or transmit it ? -->
        <xsl:copy-of select="$sep"/>
        <xsl:apply-templates select="key('define', $ref)" mode="compact">
          <xsl:with-param name="mode" select="$mode"/>
        </xsl:apply-templates>
        <xsl:copy-of select="$quant"/>
      </xsl:when>
      <!-- more than one attribute, implement an hide/show -->
      <xsl:when test="$mode != 'element' and (string-length($children) - string-length(translate($children, '@', ''))) &gt; 1">
        <span class="more">
          <xsl:copy-of select="$sep"/>
          <a class="ref">
            <xsl:call-template name="href"/>
            <xsl:call-template name="title"/>
            <xsl:value-of select="@name"/>
          </a>
          <xsl:text> (</xsl:text>
          <a class="toggle">
            <xsl:attribute name="onclick">o=this.parentNode; if(o.className=='more'){o.className='less'; this.innerHTML='▽';} else {o.className='more';this.innerHTML='►'}</xsl:attribute>
            <!-- espace insécable <xsl:text> </xsl:text> -->
            <xsl:text>►</xsl:text>
          </a>
          <span class="refin">
            <xsl:apply-templates select="key('define', $ref)" mode="compact">
              <xsl:with-param name="mode" select="$mode"/>
            </xsl:apply-templates>
          </span>
          <xsl:text>)</xsl:text>
          <xsl:copy-of select="$quant"/>
        </span>
      </xsl:when>
      <!-- What is it here ? -->
      <xsl:otherwise>
        <xsl:apply-templates select="key('define', $ref)" mode="compact">
          <xsl:with-param name="mode" select="$mode"/>
        </xsl:apply-templates>
        <xsl:copy-of select="$quant"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!-- text -->
  <xsl:template match="rng:text" mode="compact">
    <xsl:param name="quant"/>
    <i>{text}</i>
    <xsl:copy-of select="$quant"/>
  </xsl:template>
  <!-- data type -->

  <xsl:template match="rng:param" mode="compact">
    <xsl:value-of select="@name"/>
    <xsl:text>: </xsl:text>
    <tt>
      <xsl:choose>
        <xsl:when test="string-length(.) &lt; 40">
          <xsl:value-of select="."/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="snip"/>
        </xsl:otherwise>
      </xsl:choose>
    </tt>
  </xsl:template>
  <!-- No doc -->
  <xsl:template match="a:*" mode="compact"/>
  <!-- défaut, nothing ? -->
  <xsl:template match="*" mode="compact"/>
  <xsl:template match="rng:*" mode="compact">
    <xsl:param name="quant"/>
    <xsl:param name="mode"/>
    <xsl:param name="sep"/>
    <xsl:apply-templates select="rng:*" mode="compact">
      <xsl:with-param name="sep" select="$sep"/>
      <xsl:with-param name="quant" select="$quant"/>
      <xsl:with-param name="mode" select="$mode"/>
    </xsl:apply-templates>
  </xsl:template>

  <!-- mode count, count children in a macro labyrinth -->
  <xsl:template name="children">
    <xsl:param name="mode">count</xsl:param>   
    <xsl:for-each select="rng:*">
      <xsl:call-template name="child">
        <xsl:with-param name="mode" select="$mode"/>
      </xsl:call-template>
    </xsl:for-each>
  </xsl:template>
  <!-- one child, do something -->
  <xsl:template name="child">
    <!-- A mode, to output ids instead of elements -->
    <xsl:param name="mode">count</xsl:param>
    <!-- First call, add the caller in the stop recursion -->
    <xsl:param name="stack" select=".."/>
    <!-- Keep a quantifier, for attributes -->
    <xsl:param name="required" select="1"/>
    <xsl:choose>
      <!-- things counted -->
      <xsl:when test="$mode='count' and self::rng:element">*</xsl:when>
      <xsl:when test="$mode='count' and self::rng:attribute">@</xsl:when>
      <xsl:when test="$mode='count' and self::rng:text">T</xsl:when>
      <xsl:when test="$mode='count' and self::rng:value">V</xsl:when>
      <xsl:when test="$mode='count' and self::rng:data">D</xsl:when>
      <!-- id of an element for a space separated list -->
      <xsl:when test="$mode='id' and self::rng:element">
        <xsl:value-of select="concat(' ', generate-id(), ' ')"/>
      </xsl:when>
      <!-- id of attribute -->
      <xsl:when test="$mode='attid' and self::rng:attribute">
        <xsl:text> </xsl:text>
        <xsl:value-of select="generate-id()"/>
        <xsl:if test="not($required)">?</xsl:if>
        <xsl:text> </xsl:text>
      </xsl:when>
      <!-- optional -->
      <xsl:when test="$mode='attid' and (self::rng:optional or self::rng:choice)">
        <xsl:for-each select="rng:*">
          <xsl:call-template name="child">
          <xsl:with-param name="stack" select="$stack"/>
            <xsl:with-param name="mode" select="$mode"/>
            <xsl:with-param name="required"/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:when>
      <!-- html and so on -->
      <xsl:when test=" namespace-uri()!='http://relaxng.org/ns/structure/1.0' "/>
      <!-- Reference to a macro, get children inside macro -->
      <xsl:when test="self::rng:ref">
        <xsl:for-each select="key('define', @name)[1]">
          <xsl:call-template name="child">
            <xsl:with-param name="stack" select="$stack"/>
            <xsl:with-param name="mode" select="$mode"/>
            <xsl:with-param name="required" select="$required"/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:when>
      <!-- link to a macro, seems already visited, maybe infinite loop, break here -->
      <xsl:when test="count(.|$stack)=count($stack)"/>
      <!-- macro, add it to the memory of recursion -->
      <xsl:when test="self::rng:define">
        <!-- keep that here, we need the <define> in the stack, not the children -->
        <xsl:variable name="define" select="."/>
        <xsl:for-each select="rng:*">
          <xsl:call-template name="child">
            <xsl:with-param name="stack" select="$stack|$define"/>
            <xsl:with-param name="mode" select="$mode"/>
            <xsl:with-param name="required" select="$required"/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:when>
      <!-- some quantifier, run inside -->
      <xsl:when test="self::rng:choice  | self::rng:list | self::rng:group | self::rng:interleave | self::rng:mixed | self::rng:oneOrMore | self::rng:optional | self::rng:zeroOrMore">
        <xsl:for-each select="rng:*">
          <xsl:call-template name="child">
            <xsl:with-param name="stack" select="$stack"/>
            <xsl:with-param name="mode" select="$mode"/>
            <xsl:with-param name="required" select="$required"/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <!-- Documentation -->
  <xsl:template match="a:documentation">
    <xsl:choose>
      <xsl:when test="parent::rng:grammar">
        <h1>
          <xsl:attribute name="id">
            <xsl:call-template name="id"/>
          </xsl:attribute>
          <xsl:apply-templates/>
        </h1>
      </xsl:when>
      <xsl:when test="parent::rng:div">
        <xsl:variable name="level" select="count(ancestor::rng:div)+1"/>
        <xsl:variable name="el">
          <xsl:choose>
            <xsl:when test="$level &gt; 0 and $level &lt;7 ">h<xsl:value-of select="$level"/></xsl:when>
            <xsl:otherwise>strong</xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:element name="{$el}">
          <xsl:value-of select="normalize-space(.)"/>
        </xsl:element>
      </xsl:when>
      <xsl:when test="parent::rng:element | parent::rng:attribute | parent::rng:define">
        <xsl:choose>
          <xsl:when test="name(preceding-sibling::*[1])='a:documentation' or name(following-sibling::*[1])='a:documentation'">
            <div>
              <xsl:apply-templates/>
            </div>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="name(preceding-sibling::*[1])='a:documentation'">
        <div class="documentation">
          <xsl:apply-templates/>
        </div>
      </xsl:when>
      <xsl:otherwise>
        <span class="documentation">
          <xsl:apply-templates/>
        </span>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- XML example  -->
  <xsl:template match="a:example[*]">
    <xsl:choose>
      <!-- inline xml -->
      <xsl:when test="ancestor::html:p">
        <xsl:apply-templates mode="xml2html">
          <xsl:with-param name="inline" select="true()"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
        <figure class="xml example">
          <xsl:attribute name="id">
            <xsl:call-template name="id"/>
          </xsl:attribute>
          <xsl:apply-templates mode="xml2html"/>
        </figure>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!-- Inclusion of examples should be resolved before, by rng4inc.xsl, to let  -->
  <xsl:template match="a:example[@href]">
   <a href="{@href}">
    <xsl:call-template name="docmess">
      <xsl:with-param name="id">example</xsl:with-param>
    </xsl:call-template>
   </a>
  </xsl:template>
  <xsl:template match="*" mode="xml_name">
    <a class="el">
      <xsl:call-template name="href"/>
      <xsl:call-template name="title"/>
      <xsl:value-of select="name()"/>
    </a>
  </xsl:template>
  <xsl:template match="a:el">
    <xsl:text>&lt;</xsl:text>
    <a class="el">
      <xsl:call-template name="href"/>
      <!-- infinite loop possible if rng:element[@name='A']/a:documentation/a:el[text()='B'] and 
      rng:element[@name='B']/a:documentation/a:el[text()='A'] -->
      <!--
      <xsl:variable name="title">
        <xsl:for-each select="key('element', substring-before(concat(normalize-space(.),' '), ' '))[1]">
          <xsl:value-of select="a:documentation"/>
        </xsl:for-each>
      </xsl:variable>
      <xsl:if test="$title != ''">
        <xsl:attribute name="title">
          <xsl:value-of select="$title"/>
        </xsl:attribute>
      </xsl:if>
      -->
      <xsl:value-of select="."/>
    </a>
    <xsl:text>&gt;</xsl:text>
  </xsl:template>
  <xsl:template match="a:att">
    <xsl:variable name="name" select="normalize-space(.)"/>
    <xsl:text>@</xsl:text>
    <a class="att">
      <xsl:choose>
        <xsl:when test="ancestor::rng:*[1]//rng:attribute[(@name|rng:name)=$name]">
          <xsl:for-each select="ancestor::rng:*[1]//rng:attribute[(@name|rng:name)=$name][1]">
            <xsl:call-template name="href"/>
          </xsl:for-each>
        </xsl:when>
        <xsl:when test="key('attribute', $name)">
          <xsl:for-each select="key('attribute', $name)[1]">
            <xsl:call-template name="href"/>
          </xsl:for-each>
        </xsl:when>
      </xsl:choose>
      <xsl:value-of select="."/>
    </a>
  </xsl:template>
  <xsl:template match="s:*">
    <!-- No support for schematron for now -->
  </xsl:template>

</xsl:transform>

<?xml version="1.0" encoding="UTF-8"?>
<!--

<h1>XSL, documentation <a href="xsl_html.xsl">xsl_html.xsl</a></h1>

Copyright © 2004-2017 Frédéric Glorieux
license : APACHE 2.0 http://www.apache.org/licenses/LICENSE-2.0
<frederic.glorieux@fictif.org>

<p>
Documenter une transformation XSL, afin d'en rendre la logique plus clairement visible,
en exploitant  le texte riche des commentaires XML standard du développeur,
(sans introduire un apareillage extérieur ou un espace de nom spécifique)
</p>

<h2> Présentation </h2>

<h3> Comment </h3>

<p>
À toute XSL, ajouter une déclaration vers cette transformation
<?xml-stylesheet type="text/xsl" href="xsl_html.xsl"?>
et regarder le résultat dans un navigateur. Une partie de la valeur ajoutée
provient de transformations importées :
</p>


<h3>fonctionnalités</h3>

<ul>
  <li>Une introduction textuelle (commentaire XML en racine)</li>
  <li>Index des nœuds matchés</li>
  <li>Index des nœuds générés</li>
  <li>Liste de tâches</li>
</ul>


<h3> Historique </h3>

<ul>
  <li>2010-03 [FG] Pour génération dynamique</li>
  <li>2009-07 [FG] Diple</li>
  <li>2007-12 [FG] cours de développement XML Master ID, Lille 3</li>
  <li>2004-11 [FG] creation (Transfolio)</li>
</ul>
-->
<xsl:transform version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"

  xmlns:exslt="http://exslt.org/common"
  xmlns:saxon="http://icl.com/saxon"
  xmlns:date="http://exslt.org/dates-and-times"
  extension-element-prefixes="exslt saxon date"
>
  <!-- liens vers des fonctions outil -->
  <xsl:import href="xmldoc.xsl"/>
  <!-- Pour présenter du XML -->
  <xsl:import href="xml2html.xsl"/>
  <!-- Pour enrichir le texte des commentaires -->
  <xsl:import href="text_html.xsl"/>
  <!-- This transformation -->
  <xsl:variable name="this">xsl_html.xsl</xsl:variable>
  <!-- Fichier à documenter -->
  <xsl:param name="filename">xsl</xsl:param>
  <!-- Extension pour les liens à d'autres xsl -->
  <xsl:param name="ext">.xsl</xsl:param>
  <!-- Type de fichier généré -->
  <xsl:param name="corpus">xsl</xsl:param>
  <!-- Titre de la documentation (surchargeable à l'appel) -->
  <xsl:param name="title"><xsl:value-of select="$filename"/>, documentation</xsl:param>
  <!-- Mise en page générale -->
  <xsl:template match="xsl:stylesheet | xsl:transform">
    <article class="transform">
      <nav id="nav">
        <div id="toc"/>
        <!-- index des éléments générés -->
        <xsl:call-template name="index-result"/>
        <!-- Index des templates nommés -->
        <xsl:call-template name="index-name"/>
        <!-- index des match -->
        <xsl:call-template name="index-match"/>
      </nav>
      <xsl:call-template name="xsl:global"/>
      <!-- task lists -->
      <xsl:call-template name="TODO"/>
      <!-- Liste des templates, boucle pour passer les éléments d'entête, et tout de même voir les commentaires intercalaires -->
      <xsl:variable name="top-els"> import include output strip-space preserve-space param variable key attribute-set namespace-alias </xsl:variable>
      <xsl:for-each select="node()">
        <xsl:choose>
          <!-- commentaire d'entête -->
          <xsl:when test="self::comment() and local-name(following-sibling::xsl:*[1]) != 'template'"/>
          <xsl:when test="self::comment()">
            <xsl:choose>
              <!-- commentaire de template, traité dans le template -->
              <xsl:when test="generate-id(following-sibling::xsl:template[1]/preceding-sibling::comment()[1]) = generate-id()"/>
              <xsl:otherwise>
                <xsl:apply-templates select="."/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:when test="local-name()=''"/>
          <!-- éléments d'entête -->
          <xsl:when test="contains($top-els, concat(' ',local-name(), ' '))"/>
          <xsl:otherwise>
            <xsl:apply-templates select="."/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </article>
  </xsl:template>

  <!-- Résumé court d'un template -->
  <xsl:template match="xsl:template">
    <xsl:param name="test"/>
    <xsl:variable name="id">
      <xsl:apply-templates select="." mode="id"/>
    </xsl:variable>
    <section class="template" id="{$id}">
      <!-- display source
TODO : pb Opera
      -->
      <details class="source">
        <summary class="but" onclick="
if(this.parentNode.className=='source minus') this.parentNode.className='source plus'; else this.parentNode.className='source minus';
        ">source</summary>
        <div class="xml">
          <xsl:apply-templates select="." mode="xml2html"/>
        </div>
      </details>
      <header>
        <xsl:if test="function-available('saxon:line-number')">
          <small>
            <xsl:text>(l. </xsl:text>
            <xsl:value-of select="saxon:line-number()"/>
            <xsl:text>)</xsl:text>
          </small>
        </xsl:if>
        <xsl:apply-templates select="@name"/>
        <xsl:apply-templates select="@match"/>
        <xsl:apply-templates select="@mode"/>
      </header>
      <xsl:call-template name="output"/>
      <xsl:if test="xsl:param">
        <ul>
          <xsl:for-each select="xsl:param">
            <li>
              <var>
                <xsl:text>$</xsl:text>
                <xsl:value-of select="@name"/>
              </var>
              <xsl:text> : </xsl:text>
              <xsl:apply-templates select="
preceding-sibling::comment()[1][generate-id(following-sibling::*)=generate-id(current())]
"/>
            </li>
          </xsl:for-each>
        </ul>
      </xsl:if>
      <xsl:if test="preceding-sibling::comment()[1][generate-id(following-sibling::*)=generate-id(current())]">
        <xsl:apply-templates select="
preceding-sibling::comment()[1][generate-id(following-sibling::*)=generate-id(current())]
"/>
      </xsl:if>
    </section>
  </xsl:template>
  <!-- Contenu généré par un template, liste des éléments et attributs, puis texte non vides générés -->
  <xsl:template name="output">
    <xsl:variable name="output">
      <xsl:for-each select="
.//*[namespace-uri() != 'http://www.w3.org/1999/XSL/Transform'] | .//xsl:element | .//xsl:attribute
">
        <xsl:sort select="@name"/>
        <xsl:sort select="name(.)"/>
        <xsl:choose>
          <xsl:when test="current()/@name and count(current()|ancestor::xsl:template/descendant::*[name()=name(current())][@name=current()/@name][1])=2"/>
          <!-- n'est pas le premier avec son nom, attention .// n'a pas le même effet descendant::* pour attraper le premier [1] -->
          <xsl:when test="count(current()|ancestor::xsl:template/descendant::*[name()=name(current())][1])=2"/>
          <xsl:when test="self::xsl:element">
            <xsl:text>, &lt;</xsl:text>
            <xsl:value-of select="@name"/>
            <xsl:text>&gt; </xsl:text>
          </xsl:when>
          <xsl:when test="self::xsl:attribute">
            <xsl:text>, @</xsl:text>
            <xsl:value-of select="@name"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>, &lt;</xsl:text>
            <xsl:apply-templates select="." mode="xml_name"/>
            <xsl:text>&gt;</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
      <xsl:for-each select="
.//text()[normalize-space(.)!= ''][not(contains(' with-param param variable ', concat(' ', local-name(./..), ' ')))]
">
        <xsl:text>, "</xsl:text>
          <xsl:choose>
            <xsl:when test="string-length(.) &lt; 51">
              <xsl:value-of select="."/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="substring(., 1, 50)"/>
              <xsl:text> […]</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        <xsl:text>"</xsl:text>
      </xsl:for-each>
      <xsl:for-each select=".//xsl:copy|.//xsl:copy-of|.//xsl:value-of">
        <xsl:sort select="name()"/>
        <xsl:text>, </xsl:text>
        <xsl:choose>
          <xsl:when test="@select">
            <xsl:value-of select="@select"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="ancestor::xsl:template/@match"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:variable>
    <xsl:if test="$output != ''">
      <div class="output">
        <xsl:value-of select="substring($output, 3)"/>
      </div>
    </xsl:if>
  </xsl:template>

<!--
Un tableau récapitulatif de la transformation

TODO attribute-set,
-->
  <xsl:template name="xsl:global">
    <xsl:if test="xsl:param">
      <strong>&lt;xsl:param…</strong>
      <xsl:apply-templates select="xsl:param"/>
    </xsl:if>
    <xsl:if test="xsl:variable">
      <strong>&lt;xsl:variable…</strong>
      <xsl:apply-templates select="xsl:variable"/>
    </xsl:if>
    <!-- xsl:apply-templates select="xsl:include | xsl:import"/ -->
    <xsl:if test="contains(.//@select, 'document(')">
      <strong>document()</strong>
      <xsl:for-each select=".//@select[contains(., 'document(')]">
        <xsl:variable name="uri">
          <xsl:value-of select="
normalize-space(
  substring-before (
    concat(
      substring-before(
        substring-after(. , 'document(' )
        , ')'
      )
      , ','
    )
    , ','
  )
)
"/>
        </xsl:variable>
        <xsl:if test="position() != 1">, </xsl:if>
        <a href='{translate($uri, "&apos;", "")}'>
          <xsl:value-of select="$uri"/>
        </a>
      </xsl:for-each>
    </xsl:if>
  </xsl:template>
  <!-- Inclusion et imports -->
  <xsl:template match="xsl:include | xsl:import">
    <tr>
      <th><xsl:value-of select="name()"/></th>
      <td>
        <a href="{@href}">
          <xsl:attribute name="href">
            <xsl:value-of select="substring-before(concat(@href, '.xsl'), '.xsl')"/>
            <xsl:value-of select="$ext"/>
          </xsl:attribute>
          <xsl:value-of select="@href"/>
        </a>
      </td>
      <td>
        <xsl:apply-templates select="
preceding-sibling::comment()[1][generate-id(following-sibling::*)=generate-id(current())]
"/>
      </td>
    </tr>
  </xsl:template>
  <!-- matching root variable or parameter, appears in a table -->
  <xsl:template match="
  xsl:stylesheet/xsl:param | xsl:transform/xsl:param
|  xsl:stylesheet/xsl:variable | xsl:transform/xsl:variable
  ">
    <xsl:variable name="name" select="@name"/>
    <xsl:variable name="refs">
      <xsl:text> </xsl:text>
      <xsl:for-each select="
../xsl:template[.//@*[contains(., concat('$', $name))]]">
        <xsl:if test="position()!=1">, </xsl:if>
        <xsl:apply-templates select="." mode="a"/>
      </xsl:for-each>
    </xsl:variable>
    <div class="xsl-var">
      <xsl:if test="preceding-sibling::comment()[1][generate-id(following-sibling::*)=generate-id(current())]">
        <div>
          <xsl:apply-templates select="
  preceding-sibling::comment()[1][generate-id(following-sibling::*)=generate-id(current())]
  "/>
          <xsl:if test="normalize-space($refs) != ''">
            <xsl:text> — </xsl:text>
            <i>cf.</i>
            <xsl:copy-of select="$refs"/>
          </xsl:if>
        </div>
      </xsl:if>
      <b>
        <xsl:text>$</xsl:text>
        <xsl:value-of select="@name"/>
      </b>
      <xsl:choose>
        <xsl:when test="*">
          <div class="xml">
            <xsl:apply-templates select="." mode="xml:html"/>
          </div>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>=</xsl:text>
          <xsl:value-of select="@select"/>
          <xsl:if test="text()">
            <samp>"<xsl:value-of select="."/>"</samp>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
    </div>
  </xsl:template>
    <!-- index des éléments créés
  -->
  <xsl:template name="index-result">
    <xsl:choose>
      <xsl:when test="function-available('exslt:node-set')">
        <xsl:variable name="set">
          <xsl:for-each select="
    .//*[namespace-uri() != 'http://www.w3.org/1999/XSL/Transform'] | .//xsl:element
    ">
            <xsl:choose>
              <xsl:when test="current()/@name and count(current()|ancestor::xsl:template/descendant::*[name()=name(current())][@name=current()/@name][1])=2"/>
              <!-- n'est pas le premier avec son nom, attention .// n'a pas le même effet descendant::* pour attraper le premier [1] -->
              <xsl:when test="count(current()|ancestor::xsl:template/descendant::*[name()=name(current())][1])=2"/>
              <xsl:when test="self::xsl:element">
                <a>
                  <xsl:attribute name="href">
                    <xsl:text>#</xsl:text>
                    <xsl:apply-templates select="ancestor::xsl:template" mode="id"/>
                  </xsl:attribute>
                  <!-- clé de tri -->
                  <xsl:attribute name="rev">
                    <xsl:variable name="name" select="translate(@name, $ABC, $abc)"/>
                    <xsl:choose>
                      <xsl:when test="contains(@name, '{')">
                        <xsl:value-of select="$name"/>
                      </xsl:when>
                      <xsl:when test="contains(@name, ':')">
                        <xsl:value-of select="substring-after($name, ':')"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="$name"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:attribute>
                  <xsl:value-of select="@name"/>
                </a>
              </xsl:when>
              <xsl:otherwise>
                <a>
                  <xsl:attribute name="href">
                    <xsl:text>#</xsl:text>
                    <xsl:apply-templates select="ancestor::xsl:template" mode="id"/>
                  </xsl:attribute>
                  <xsl:attribute name="rev">
                    <xsl:value-of select="translate(local-name(), $ABC, $abc)"/>
                  </xsl:attribute>
                  <xsl:value-of select="name()"/>
                </a>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="list">
          <xsl:for-each select="exslt:node-set($set)/*">
            <xsl:sort select="@rev"/>
            <xsl:sort select="."/>
            <xsl:copy-of select="."/>
          </xsl:for-each>
        </xsl:variable>
        <div class="result">
          <strong>&lt;xsl:element name="…</strong>
          <p>
            <b>
              <xsl:value-of select="translate(substring(exslt:node-set($list)/*[1]/@rev, 1, 1), $abc, $ABC)"/>
              <xsl:text> : </xsl:text>
            </b>
            <xsl:for-each select="exslt:node-set($list)/*">
              <xsl:variable name="rev" select="@rev"/>
              <xsl:variable name="count" select="count(preceding-sibling::*[@rev=$rev])"/>
              <a href="{@href}">
                <xsl:value-of select="."/>
                <!--
                <xsl:choose>
                  <xsl:when test="$count &gt; 0">
                    <xsl:text>(</xsl:text>
                    <xsl:value-of select="$count + 1"/>
                    <xsl:text>)</xsl:text>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="."/>
                  </xsl:otherwise>
                </xsl:choose>
                -->
              </a>
              <xsl:variable name="next" select="following-sibling::*[1][@rev]/@rev"/>
              <xsl:choose>
                <!-- Pas de suivant -->
                <xsl:when test="not($next)"/>
                <!-- suivant de meme nom -->
                <xsl:when test="$next = $rev">
                  <xsl:text>, </xsl:text>
                </xsl:when>
                <!-- suivant de meme initiale -->
                <xsl:when test="substring($next, 1, 1) = substring($rev, 1, 1)"> — </xsl:when>
                <!-- nouvelle lettre -->
                <xsl:otherwise><xsl:text disable-output-escaping="yes">&lt;/p>
          &lt;p></xsl:text>
                <b>
                  <xsl:value-of select="translate(substring($next, 1, 1), $abc, $ABC)"/>
                  <xsl:text> : </xsl:text>
                </b>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each>
          </p>
        </div>
      </xsl:when>
    </xsl:choose>
  </xsl:template>


  <!-- index (approximatif) des noeuds matchés
1. collecter les expressions matchées
2. découper
3. trier
4. imprimer
  -->
  <xsl:template name="index-match">
    <xsl:choose>
      <xsl:when test="function-available('exslt:node-set')">
        <div class="match">
          <strong>&lt;xsl:template match="…</strong>
          <xsl:variable name="set">
            <xsl:for-each select="/*/xsl:template[@match]">
              <xsl:call-template name="match-ana"/>
            </xsl:for-each>
          </xsl:variable>
          <xsl:variable name="list">
            <xsl:for-each select="exslt:node-set($set)/*">
              <xsl:sort select="@sort"/>
              <xsl:sort select="."/>
              <xsl:copy-of select="."/>
            </xsl:for-each>
          </xsl:variable>
          <p>
            <b>
              <xsl:value-of select="translate(substring(exslt:node-set($list)/*[1]/@sort, 1, 1), $abc, $ABC)"/>
              <xsl:text> : </xsl:text>
            </b>
            <xsl:for-each select="exslt:node-set($list)/*">
              <a href="{@href}">
                <xsl:value-of select="."/>
                <xsl:if test="@mode">
                  <sup>
                    <xsl:value-of select="@mode"/>
                  </sup>
                </xsl:if>
              </a>
              <xsl:choose>
                <xsl:when test="not(following-sibling::*[1]/@sort)"/>
                <xsl:when test="substring(following-sibling::*[1]/@sort, 1, 1) = substring(@sort, 1, 1)"> — </xsl:when>
                <xsl:otherwise><xsl:text disable-output-escaping="yes">&lt;/p>
          &lt;p></xsl:text>
                <b>
                  <xsl:value-of select="translate(substring(following-sibling::*[1]/@sort, 1, 1), $abc, $ABC)"/>
                  <xsl:text> : </xsl:text>
                </b>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each>
          </p>
        </div>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  <!-- index des templates nommé
  -->
  <xsl:template name="index-name">
    <div class="index">
      <strong>&lt;xsl:template name="…</strong>
      <xsl:for-each select="/*/xsl:template[@name]">
        <xsl:sort select="@name"/>
        <a>
          <xsl:attribute name="href">
            <xsl:text>#</xsl:text>
            <xsl:apply-templates select="." mode="id"/>
          </xsl:attribute>
          <xsl:value-of select="@name"/>
        </a>
        <xsl:choose>
          <xsl:when test="position() = last()">.</xsl:when>
          <xsl:otherwise>, </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </div>
  </xsl:template>

  <!-- découpe récursive d'une valeur de match pour produire un nodeset d'éléments trieable
       on distingue la clé pour le tri de l'expression complète de match -->
  <xsl:template name="match-ana">
    <xsl:param name="sort" select="@match"/>
    <xsl:param name="exp" select="$sort"/>
    <xsl:choose>
      <!-- arrêter à temps -->
      <xsl:when test="normalize-space($sort)=''"/>
      <!-- couper sur les disjonctions -->
      <xsl:when test="contains($sort, '|')">
        <xsl:call-template name="match-ana">
          <xsl:with-param name="sort" select="substring-before($sort, '|')"/>
        </xsl:call-template>
        <xsl:call-template name="match-ana">
          <xsl:with-param name="sort" select="substring-after($sort, '|')"/>
        </xsl:call-template>
      </xsl:when>
      <!-- supprimer le sélecteur entre crochets de la clé (à conserver dans l'expression) -->
      <xsl:when test="contains($sort, '[') and contains($sort, ']')">
        <xsl:call-template name="match-ana">
          <xsl:with-param name="sort" select="concat(substring-before($sort, '['), substring-after($sort, ']'))"/>
          <xsl:with-param name="exp" select="$exp"/>
        </xsl:call-template>
      </xsl:when>
      <!-- couper sur les /, pour trouver l'élément concerné, garder l'expression complète -->
      <xsl:when test="contains($sort, '/')">
        <xsl:call-template name="match-ana">
          <xsl:with-param name="sort" select="substring-after($sort, '/')"/>
          <xsl:with-param name="exp" select="$exp"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($sort, '@')">
        <xsl:call-template name="match-ana">
          <xsl:with-param name="sort" select="substring-after($sort, '@')"/>
          <xsl:with-param name="exp" select="$exp"/>
        </xsl:call-template>
      </xsl:when>
      <!-- clé de tri sans le ':' -->
      <xsl:when test="contains($sort, ':')">
        <xsl:call-template name="match-ana">
          <xsl:with-param name="sort" select="substring-after($sort, ':')"/>
          <xsl:with-param name="exp" select="$exp"/>
        </xsl:call-template>
      </xsl:when>
      <!-- sortir l'expression -->
      <xsl:otherwise>
        <xsl:text>
</xsl:text>
        <match sort="{normalize-space(translate($sort, $ABC, $abc)) }">
          <xsl:attribute name="href">
            <xsl:text>#</xsl:text>
            <xsl:apply-templates select="." mode="id"/>
          </xsl:attribute>
          <xsl:copy-of select="@name | @mode"/>
          <xsl:value-of select="normalize-space($exp)"/>
        </match>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!-- for nicer format -->
  <xsl:template name="break-string">
    <xsl:param name="text"/>
    <xsl:param name="width" select="20"/>
    <xsl:choose>
      <xsl:when test="normalize-space($text) =''"/>
      <xsl:when test="string-length($text) &lt; $width">
        <xsl:value-of select="$text"/>
      </xsl:when>
      <xsl:when test="string-length(substring-before(concat($text, ' '), ' ')) &lt; $width">
        <xsl:value-of select="substring-before(concat($text, ' '), ' ')"/>
        <xsl:value-of select="' '"/>
        <xsl:call-template name="break-string">
          <xsl:with-param name="text" select="substring-after(concat($text, ' '), ' ')"/>
          <xsl:with-param name="width" select="$width"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="substring($text, 1, $width)"/>
        <xsl:value-of select="' '"/>
        <xsl:call-template name="break-string">
          <xsl:with-param name="text" select="substring($text, $width + 1)"/>
          <xsl:with-param name="width" select="$width"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!-- lien pour <xsl:template> -->
  <xsl:template match="xsl:template" mode="a">
    <xsl:text>[</xsl:text>
    <a>
      <xsl:attribute name="href"><xsl:text>#</xsl:text><xsl:apply-templates select="." mode="id"/></xsl:attribute>
      <xsl:apply-templates select="." mode="id"/>
    </a>
    <xsl:text>]</xsl:text>
  </xsl:template>
  <!--

get a list of all templates

-->
  <!--
Liste de tâches, récupère tous les commentaires qui comporte le mot clé "todo"
 -->
  <xsl:template name="TODO">
    <xsl:if test=".//comment()[contains(., 'TODO')]">
      <!-- TODO, juste pour tester la fonctionnalités -->
      <strong>TODOs</strong>
      <ul class="tasks">
        <xsl:for-each select=".//comment()[contains(., 'TODO')]">
          <li class="TODO">
            <xsl:apply-templates select="following-sibling::xsl:template[1]|ancestor::xsl:template" mode="a"/>
            <xsl:call-template name="inlines">
              <xsl:with-param name="text" select="substring-after(., 'TODO')"/>
            </xsl:call-template>
          </li>
        </xsl:for-each>
      </ul>
    </xsl:if>
  </xsl:template>
  <!-- @test -->
  <xsl:template match="@test">
    <xsl:text> (</xsl:text>
    <xsl:value-of select="."/>
    <xsl:text>)? </xsl:text>
  </xsl:template>
  <!-- @select -->
  <xsl:template match="@select">
    <xsl:apply-templates select="." mode="xml:value"/>
  </xsl:template>
  <!-- handle xsl:template/@match values.
TODO ? some linking on match expressions ?
  -->
  <xsl:template match="@match">
    <xsl:text> </xsl:text>
    <b class="match">
      <xsl:value-of select="."/>
    </b>
  </xsl:template>
  <xsl:template match="@name">
    <xsl:text> </xsl:text>
    <b class="name">
      <xsl:text>[</xsl:text>
      <xsl:value-of select="."/>
      <xsl:text>]</xsl:text>
    </b>
  </xsl:template>
  <!-- @mode -->
  <xsl:template match="@mode">
    <xsl:text> (</xsl:text>
    <xsl:value-of select="."/>
    <xsl:text>) </xsl:text>
  </xsl:template>
  <!--
Vue compacte d'une XSLT, essai de syntaxe sans balise
=====================================================

Ces templates ne sont plus utilisés.

  -->
  <!-- xsl:template, generate compact view -->
  <xsl:template name="xsl:template">
    <div class="code">
      <xsl:if test="@match">
        <xsl:apply-templates select="@match"/>
        <xsl:text> &gt;&gt; </xsl:text>
      </xsl:if>
      <xsl:value-of select="@name"/>
      <xsl:if test="xsl:param">
        <xsl:text> (</xsl:text>
        <xsl:apply-templates select="
   xsl:param
 | comment()[name(following-sibling::*)='xsl:param']
        "/>
        <xsl:text>)</xsl:text>
      </xsl:if>
      <xsl:text> {</xsl:text>
      <xsl:apply-templates select="
        *[name() != 'xsl:param']
       | comment()[not(name(following-sibling::*)='xsl:param')]

        "/>
      <xsl:text> }</xsl:text>
    </div>
  </xsl:template>
  <!-- xsl:for-each, compact view -->
  <xsl:template match="xsl:for-each">
    <div class="code">
      <xsl:text>(</xsl:text>
      <xsl:apply-templates select="@select"/>
      <xsl:text>) * {</xsl:text>
      <xsl:apply-templates/>
      <xsl:text>}; </xsl:text>
    </div>
  </xsl:template>
  <!-- generated messages -->
  <xsl:template match="text() | xsl:text">
    <b>
      <xsl:value-of select="."/>
    </b>
  </xsl:template>
  <!-- Commentaire de documentation, si le commentaire commence par une balise, on
  suppose qu'il s'agit d'un texte formaté en html, on l'imprime tel quel, sinon,
  il est procédé par la transformation text_html.xsl -->
  <xsl:template match="comment()">
    <xsl:variable name="prefix" select="substring-before(concat(normalize-space(.), ' '), ' ')"/>
    <xsl:choose>
      <!-- commence par de l'xsl, probablement un reste en cours de travail, ne pas montrer -->
      <xsl:when test="contains($prefix, '&lt;xsl:')"/>
      <!-- parier qu'il s'agit de html -->
      <xsl:when test="contains(., '&lt;a ') or contains(., '&lt;p') or contains(., '&lt;h1') or contains(., '&lt;h2') or contains(., '&lt;h3')">
        <xsl:value-of disable-output-escaping="yes" select="."/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="." mode="text_html"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!-- xsl:if, compact view, may be shown as xsl:when -->
  <xsl:template match="xsl:if">
    <div class="code">
      <xsl:apply-templates select="@test"/>
      <xsl:text> {</xsl:text>
      <xsl:apply-templates/>
      <xsl:text>} </xsl:text>
    </div>
  </xsl:template>
  <!-- attribute -->
  <xsl:template match="xsl:attribute">
    <xsl:text> </xsl:text>
    <b class="att">
      <xsl:value-of select="@name"/>
    </b>
    <xsl:text>="</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>" </xsl:text>
  </xsl:template>
  <!-- generated attribute -->
  <xsl:template match="@*">
    <xsl:text> </xsl:text>
    <b class="att">
      <xsl:value-of select="name()"/>
    </b>
    <xsl:text>="</xsl:text>
    <xsl:value-of select="."/>
    <xsl:text>" </xsl:text>
  </xsl:template>
  <!-- generated element -->
  <xsl:template match="*">
    <div class="code">
      <xsl:text>&lt;</xsl:text>
      <b class="el">
        <xsl:value-of select="name()"/>
      </b>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates select="*[.//xsl:attribute] | xsl:attribute"/>
      <xsl:text>&gt;</xsl:text>
      <xsl:apply-templates select="node()[not(.//xsl:attribute or name()='xsl:attribute')]"/>
      <xsl:text>&lt;/</xsl:text>
      <b class="el">
        <xsl:value-of select="name()"/>
      </b>
      <xsl:text>&gt;</xsl:text>
    </div>
  </xsl:template>
  <!-- xsl:element, take care of name and generated attributes -->
  <xsl:template match="xsl:element">
    <div class="code">
      <xsl:text>&lt;</xsl:text>
      <b class="el">
        <xsl:value-of select="@name"/>
      </b>
      <xsl:apply-templates select="*[.//xsl:attribute] | xsl:attribute"/>
      <xsl:text>&gt;</xsl:text>
      <xsl:apply-templates select="node()[not(.//xsl:attribute or name()='xsl:attribute')]"/>
      <xsl:text>&lt;/</xsl:text>
      <b class="el">
        <xsl:value-of select="@name"/>
      </b>
      <xsl:text>&gt;</xsl:text>
    </div>
  </xsl:template>
  <!-- xsl:choose, pass to children -->
  <xsl:template match="xsl:choose">
    <xsl:apply-templates/>
  </xsl:template>
  <!-- xsl:value-of, xsl:copy-of ; compact view as {@select} -->
  <xsl:template match="xsl:copy-of | xsl:value-of">
    <xsl:apply-templates select="@select"/>
  </xsl:template>
  <!-- xsl:when, a compact view, like a test block -->
  <xsl:template match="xsl:when">
    <div class="code">
      <xsl:text> : </xsl:text>
      <xsl:apply-templates select="@test"/>
      <xsl:text> {</xsl:text>
      <xsl:apply-templates/>
      <xsl:text>}; </xsl:text>
    </div>
  </xsl:template>
  <!-- xsl:otherwise, a compact view -->
  <xsl:template match="xsl:otherwise">
    <div class="code">
      <xsl:text>: {</xsl:text>
      <xsl:apply-templates/>
      <xsl:text>}; </xsl:text>
    </div>
  </xsl:template>
  <!-- xsl:call-template, a compact view, like a function($param={.}) -->
  <xsl:template match="xsl:call-template">
    <div class="code">
      <a href="#{@name}">
        <xsl:value-of select="@name"/>
      </a>
      <xsl:text> (</xsl:text>
      <xsl:for-each select="xsl:with-param">
        <xsl:if test="position() != 1">, </xsl:if>
        <xsl:apply-templates select="."/>
      </xsl:for-each>
      <xsl:text>); </xsl:text>
    </div>
  </xsl:template>
  <!-- xsl:with-param, a compact view -->
  <xsl:template match="xsl:with-param">
    <xsl:value-of select="@name"/>
    <xsl:text>={</xsl:text>
    <xsl:apply-templates select="@select"/>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
  </xsl:template>
  <!-- xsl:param, a compact view  -->
  <xsl:template match="xsl:param">
    <div class="code">
      <xsl:text>$</xsl:text>
      <xsl:value-of select="@name"/>
      <xsl:text>={</xsl:text>
      <xsl:apply-templates select="@select"/>
      <xsl:apply-templates/>
      <xsl:text>}; </xsl:text>
    </div>
  </xsl:template>
  <!-- xsl:variable a compact view -->
  <xsl:template match="xsl:variable">
    <div class="code">
      <xsl:text>$</xsl:text>
      <xsl:value-of select="@name"/>
      <xsl:text>={</xsl:text>
      <xsl:apply-templates select="@select"/>
      <xsl:apply-templates/>
      <xsl:text>}; </xsl:text>
    </div>
  </xsl:template>
  <!-- xsl:copy, a compact view -->
  <xsl:template match="xsl:copy">
    <!-- TOTEST, may bu -->
    <xsl:variable name="name" select="ancestor::xsl:template/@match | ancestor::xsl:for-each/@select"/>
    <span class="tag">
      <xsl:text>&lt;</xsl:text>
      <span class="el">
        <xsl:text>{</xsl:text>
        <xsl:value-of select="$name"/>
        <xsl:text>}</xsl:text>
      </span>
      <xsl:text>&gt;</xsl:text>
    </span>
    <xsl:apply-templates/>
    <span class="tag">
      <xsl:text>&lt;/</xsl:text>
      <span class="el">
        <xsl:text>{</xsl:text>
        <xsl:value-of select="$name"/>
        <xsl:text>}</xsl:text>
      </span>
      <xsl:text>&gt;</xsl:text>
    </span>
  </xsl:template>
  <!-- apply-templates, a compact view -->
  <xsl:template match="xsl:apply-templates">
    <div class="code">
      <xsl:choose>
        <xsl:when test="@select">
          <xsl:apply-templates select="@select"/>
        </xsl:when>
        <xsl:otherwise>{node()}</xsl:otherwise>
      </xsl:choose>
      <xsl:text> &gt;&gt;</xsl:text>
    </div>
  </xsl:template>
  <xsl:template match="text()[normalize-space(.)='']"/>
  <!--
Mode id
=======

Ce mode permet de générer des identifiants différents
  -->
  <!-- default generate-id() for a node (used for anchor or target) -->
  <xsl:template match="node()|@*" mode="id">
    <xsl:value-of select="generate-id()"/>
  </xsl:template>
  <!-- <xsl:template name="..."> id=@name -->
  <xsl:template match="xsl:template[@name]" mode="id">
    <xsl:text>t</xsl:text>
    <xsl:value-of select="@name"/>
  </xsl:template>
  <!-- <xsl:template> id=numéro -->
  <xsl:template match="xsl:template[not(@name)]" mode="id">
    <xsl:text>t</xsl:text>
    <xsl:number count="xsl:template[not(@name)]" level="any"/>
  </xsl:template>
  <!-- no view-source for the sample input -->
  <xsl:template match="/*/xsl:template[@name='xsl:input']" mode="xml:html"/>
  <!-- link source of a template to its doc on @name -->
  <xsl:template match="xsl:template/@name" mode="xml:value">
    <xsl:variable name="id">
      <xsl:apply-templates select=".." mode="id"/>
    </xsl:variable>
    <a href="#{$id}" class="val">
      <xsl:value-of select="."/>
    </a>
  </xsl:template>
  <!-- link a call-template to its template documentation -->
  <xsl:template match="xsl:call-template/@name" mode="xml:value">
    <a href="#{.}" class="val">
      <xsl:value-of select="."/>
    </a>
  </xsl:template>
    <!--
override xml2html.xsl to provide an anchor on
xsl:template source output.
  <xsl:template match="xsl:template" mode="xml:html">
    <hr/>
    <xsl:call-template name="xml:element"/>
  </xsl:template>
  <xsl:template match="xsl:template" mode="xml:name">
    <xsl:variable name="id">
      <xsl:apply-templates select="." mode="id"/>
    </xsl:variable>
    <a class="template" href="#{$id}-" name="{$id}">
      <xsl:value-of select="name()"/>
    </a>
  </xsl:template>
 -->

</xsl:transform>

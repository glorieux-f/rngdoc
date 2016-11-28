<?php
/*
Xrem: XML documentation tools (cross remarks)

Copyright © 2012-2013 Algone
license : APACHE 2.0 http://www.apache.org/licenses/LICENSE-2.0
<frederic.glorieux@algone.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

*/

// translations available, in priority order
$langs=array("en"=>"English","fr"=>"Français");
// this piece of code is copied here to avoid dependances
// check browser request
$lang=false;
// http param, set a lang
if (isset($_GET['lang'])) {
  // empty value, reset cookie
  if(!$_GET['lang']) setcookie("lang", "", time() - 3600);
  // lang not available, do nothing
  else if (!isset($langs[$_GET['lang']]));
  // language requested should be available
  else {
    $lang=$_GET['lang'];
    setcookie ( "lang", $lang);
  }
}
// coookie persistancy
if (!$lang && isset($_COOKIE['lang'])) {
  // language in cookie is not available, maybe setted from elsewhere in the site, do nothing
  if(!isset($langs[$_COOKIE['lang']]));
  else $lang=$_COOKIE['lang'];
}
// browser request
if(!$lang) {
  $http_accept_language = isset($_SERVER['HTTP_ACCEPT_LANGUAGE']) ? $_SERVER['HTTP_ACCEPT_LANGUAGE'] : '';
  preg_match_all("/(\w\w)(-\w+)*/", $http_accept_language, $matches);
  // array_values() reindex the keys starting at 0
  $accepted=array_values(array_intersect(array_keys(array_flip($matches[1])), array_keys($langs)));
  if(isset($accepted[0])) $lang=$accepted[0];
}
// no lang found, take the first lang available
if(!$lang) {
  reset($langs);
  $lang=key($langs);
}
?>
<html>
  <head>
    <meta http-equiv="Content-type" content="text/html; charset=UTF-8"/>
    <link rel="stylesheet" href="http://svn.code.sf.net/p/algone/code/teipot/html.css"/>
    <title><?php
if ($lang=='fr') echo'Relax-NG/XML, documentation HTML (Algone)';
else echo 'Relax-NG/XML, documentation HTML (Algone)'
    ?></title>
  </head>
  <body>

<div>
<?php
if ($lang=='fr') echo '
  <span class="langBar">[ fr |<a href="?lang=en"> en </a>]</span> Xrem, <i>cross rem</i>, documenter les remarques
  <h1>schéma Relax-NG/XML, documentation HTML </h1>
  <p>
Cet outil en ligne transforme un schéma Relax-NG/XML en une vue navigable et documentée.
Il supporte les <a href="http://books.xmlschemata.org/relaxng/relax-CHP-13-SECT-2.html#relax-CHP-13-SECT-2.3">annotations XHTML</a>,
tel que décrit par Eric van der Vlist dans son livre O’Reilly sur <a href="http://oreilly.com/catalog/9780596004217/">RELAX-NG</a>.
  </p>';
else echo '
  <span class="langBar">[ en |<a href="?lang=fr"> fr </a>]</span> Xrem, <i>cross rem</i>, cross remarks
  <h1>Relax-NG/XML Documentation</h1>
  <p>
Submit a Relax-NG/XML schema to this online tool and get a human readable documentation of it (html). This tool supports <a href="http://books.xmlschemata.org/relaxng/relax-CHP-13-SECT-2.html#relax-CHP-13-SECT-2.3">XHTML annotations</a>, like described by Eric van der Vlist in the O’Reilly book on <a href="http://oreilly.com/catalog/9780596004217/">RELAX NG</a>.</p>
';

?>
  <form
    action="Xrem.php" enctype="multipart/form-data" method="POST" name="upload"
    onsubmit="var filename=this.file.value; var pos=filename.lastIndexOf('.'); if(pos) filename=filename.substring(0, pos); this.action= 'Xrem.php/'+filename+'.html'; " >
<?php
if ($lang=='fr') echo '<label><b>ou</b> envoyer un schéma Relax-NG/XML <small>(Choisir un fichier sur son ordinateur avec le bouton [Parcourir…], puis [Envoyer])</small></label>';
else echo '<label><b>or</b> send a local Relax-NG/XML file <small>([Browse…] choose a local Relax-NG/XML file on your disk [Submit] send it)</small></label>';
?>
    <br/>
    <input type="file" size="70" name="file"/>
    <input type="submit"/>
  </form>
  <br/>
  <form action="Xrem.php" name="uri">
<?php
/*
    onsubmit="
var filename=this.uri.value;
filename=filename.substring(('/'+filename).lastIndexOf('/'));
filename=filename.substring(0, filename.lastIndexOf('.'));
this.action= 'Xrem.php/'+filename+'.html';

*/

if ($lang=='fr') echo '<label><b>ou</b> schéma Relax-NG/XML en ligne <small>(Indiquer une URI absolue dans le champ texte, puis [Envoyer])</small></label>';
else echo '<label><b>or</b> URI of an online Relax-NG/XML file <small>(Write an absolute URI, [Submit] send it)</small></label>';
?>    
    <br/>
    <input size="70" name="uri" onfocus="this.select()" value="http://svn.code.sf.net/p/javacrim/code/littre/xml/littre.rng"/>
    <input type="submit"/>
  </form>
</div>

  </body>
</html>

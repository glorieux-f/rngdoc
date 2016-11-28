<?php
/*
RngDoc: XML documentation tools (cross remarks)

Copyright © 2012-2015 Frédéric Glorieux
license : APACHE 2.0 http://www.apache.org/licenses/LICENSE-2.0
<frederic.glorieux@ficitf.org>

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
set_time_limit(-1);
// included file, do nothing
if (isset($_SERVER['SCRIPT_FILENAME']) && basename($_SERVER['SCRIPT_FILENAME']) != basename(__FILE__));
else if (isset($_SERVER['ORIG_SCRIPT_FILENAME']) && realpath($_SERVER['ORIG_SCRIPT_FILENAME']) != realpath(__FILE__));
// direct command line call, work
else if (php_sapi_name() == "cli") RngDoc::doCli();
// direct http call, perhaps dowload file, work
else if($_SERVER['REQUEST_METHOD']=='POST') RngDoc::doPost();
else if(isset($_GET['uri'])) RngDoc::doGet($_GET['uri']);

class RngDoc {
  /** keep memory of original src FilePath */
  private $srcFile;
  /** A dom document to load an XSL */
  private $xsl;
  /** Current xsl proc */
  private $proc;
  /** Current dom document on which work each methods */
  private $doc;

  /**
   * Constructor, instanciations
   */
  function __construct($srcFile) {
    $this->srcFile=$srcFile;
    /*
    $pathinfo=pathinfo($odtFile);
    if ($destName) $this->destName=$destName;
    else $this->destName=$pathinfo['filename'];
    */

    $this->xsl = new DOMDocument("1.0", "UTF-8");
    // register functions ?
    $this->proc = new XSLTProcessor();
    // load source file as DOM doc
    $this->load($srcFile);
    // allow generation of <xsl:document>
    if (defined('XSL_SECPREFS_NONE')) $prefs = XSL_SECPREFS_NONE;
    else if (defined('XSL_SECPREF_NONE')) $prefs = XSL_SECPREF_NONE;
    else $prefs = 0;
    if(method_exists($this->proc, 'setSecurityPreferences')) $oldval = $this->proc->setSecurityPreferences( $prefs);
    else if(method_exists($this->proc, 'setSecurityPrefs')) $oldval = $this->proc->setSecurityPrefs( $prefs);
    else ini_set("xsl.security_prefs",  $prefs);
  }
  /**
   * Resolve inclusions of a loaded schema
   */
  public function rng4inc() {
    $this->xsl->load(dirname(__FILE__).'/'.'rng4inc.xsl');
    $this->proc->importStylesheet($this->xsl);
    // do not output errors like "parser warning : xmlParsePITarget: invalid name prefix 'xml'"
    $oldError=set_error_handler(array($this,"err"), E_WARNING);
    $this->doc=$this->proc->transformToDoc($this->doc);
    restore_error_handler();
  }
  /**
   * transform an RNG schema to dest html file
   * if no file provided, change the private dom
   * and let user output it as xml when he wants
   */
  public function rng2html($destFile=null, $inc=true) {
    // resolve inclusion, maybe optional
    if($inc) $this->rng4inc();
    $this->xsl->load(dirname(__FILE__).'/'.'rng2html.xsl');
    $this->proc->importStylesheet($this->xsl);
    if ($destFile) $this->proc->transformToUri($this->doc, $destFile);
    else return $this->proc->transformToXML($this->doc);
  }
  /**
   * transform an RNG schema as folder of html files
   */
  public function rng2frame($destDir, $inc=true) {
    $destDir=rtrim(strtr($destDir, '\\', '/'), '/\\').'/';
    // create and empty the dir
    self::newdir($destDir);
    copy(dirname(__FILE__).'/rngdoc.css', $destDir.'/rngdoc.css');
    // resolve inclusion, maybe optional
    if($inc) $this->rng4inc();
    $this->xsl->load(dirname(__FILE__).'/'.'rng2frame.xsl');
    $this->proc->importStylesheet($this->xsl);
    // set the dest folder (? absolute ?)
    $this->proc->setParameter('', 'dir', $destDir);
    // no direct output expected, except if messages are needed for timeout on a server
    $this->proc->transformToDoc($this->doc);

  }
  /**
   * Apply code from command line interface
   */
  public static function doCli() {
    $time_start = microtime(true);
    array_shift($_SERVER['argv']); // shift first arg, the script filepath
    if (!count($_SERVER['argv'])) exit('
    usage    : php -f RngDoc.php src.rng  (dest.html|dest/)?
');
    // src file
    $src=array_shift($_SERVER['argv']);
    $doc=new RngDoc($src);
    // dest file, or dest folder (for multi-file)
    $dest=array_shift($_SERVER['argv']);
    // if not dest, output to src.html
    if(!$dest) {
      $pathinfo=pathinfo($src);
      $dest=$pathinfo['dirname'].'/'.$pathinfo['filename'].'.html';
      $doc->rng2html($dest);
    }
    // if last char of dest is '/', multi-file generation desired
    if (substr($dest, -1)=="/") $doc->rng2frame($dest);
    else $doc->rng2html($dest);
    echo (microtime(true) - $time_start)," s.\n";
    exit;
  }
  /**
   * Apply code from http upload
   */
  public static function doPost() {
    // a file seems uploaded
    $fileName="test.rng";
    if(count($_FILES)) {
      reset($_FILES);
      $tmp=current($_FILES);
      if($tmp['tmp_name']) {
        $src=$tmp['tmp_name'];
        if ($tmp['name']) $fileName=substr($tmp['name'], 0, strrpos($tmp['name'], '.'));
      }
      else if($tmp['name']){
        echo $tmp['name'],' seems bigger than allowed size for upload in your php.ini : upload_max_filesize=',ini_get('upload_max_filesize'),', post_max_size=',ini_get('post_max_size');
        return false;
      }
      else return;
    } else {
      echo "No file ?";
    }
    // store the file submitted as a memory of activity
    if (is_writable($cache=dirname(__FILE__).'/cache/') && $tmp['name']) @copy($src, $cache.$tmp['name']);
    $doc=new RngDoc($src);
    // ? test extension of src for other format ?
    // $doc->rng2frame(); // zip multifile ?
    echo $doc->rng2html(null, false);
    exit;
  }
  /**
   * Apply code to an URI
   */
  public static function doGet($uri='') {
    if(!$uri) $uri=$_GET['uri'];
    $doc=new RngDoc($uri);
    echo $doc->rng2html();
    flush();
    // transform
    if (is_writable($cache=dirname(__FILE__).'/cache/')) {
      copy($uri, $src=$cache.basename($uri));
    }
    exit;
  }
  /**
   * Load xml as dom, with an error recorder
   */
  private function load($file) {
    $this->message=array();
    $oldError=set_error_handler(array($this,"err"), E_ALL);
    $this->doc = new DOMDocument("1.0", "UTF-8");
    $this->doc->recover=true;
    // if not set here, no indent possible for output
    $this->doc->preserveWhiteSpace = false;
    $this->doc->formatOutput=true;
    $this->doc->substituteEntities=true;

    // realpath is supposed to be useful on win but break absolute uris
    $this->doc->load($file, LIBXML_NOENT | LIBXML_NSCLEAN | LIBXML_NOCDATA | LIBXML_COMPACT);
    restore_error_handler();
    if (count($this->message)) {
      $this->doc->appendChild($this->doc->createComment("Error recovered in loaded XML document \n". implode("\n", $this->message)."\n"));
    }
    $this->message=array();
  }
  /**
   * Output the instance DOM doc
   */
  public function saveXML() {
    // check which one are needed
    // $this->doc->formatOutput=true;
    // $this->doc->substituteEntities=true;
    // $this->doc->normalize();
    return $this->doc->saveXML();
  }
  /** Array of messages */
  private $message;
  /** record errors in a log variable, need to be public to used by loadXML */
  public function err( $errno, $errstr, $errfile, $errline, $errcontext) {
    if(strpos($errstr, "xmlParsePITarget: invalid name prefix 'xml'") !== FALSE) return;
    $this->message[]=$errstr;
  }
  /**
   * Delete all files in a directory, create it if not exist
   */
  static public function newDir($dir, $depth=0) {
    if (is_file($dir)) return unlink($dir);
    // attempt to create the folder we want empty
    if (!$depth && !file_exists($dir)) {
      mkdir($dir, 0775, true);
      @chmod($dir, 0775);  // let @, if www-data is not owner but allowed to write
      return;
    }
    // should be dir here
    if (is_dir($dir)) {
      $handle=opendir($dir);
      while (false !== ($entry = readdir($handle))) {
        if ($entry == "." || $entry == "..") continue;
        self::newDir($dir.'/'.$entry, $depth+1);
      }
      closedir($handle);
      // do not delete the root dir
      if ($depth > 0) rmdir($dir);
      // timestamp newDir
      else touch($dir);
      return;
    }
  }
  /**
   * Zip folder to a zip file
   */
  static public function zip($zipFile, $dir) {
    $zip = new ZipArchive;
    if(!file_exists($zipFile)) $zip->open($zipFile, ZIPARCHIVE::CREATE);
    else $zip->open($zipFile);
    $dir=rtrim($dir, "/\\").'/';
    self::zipDir($zip, $dir);
    $zip->close();
  }
  /**
   * The recursive method to zip dir
   */
  static private function zipDir($zip, $dir, $entryDir="") {
    $handle=opendir($dir);
    while (false !== ($entry = readdir($handle))) {
      if ($entry == "." || $entry == "..") continue;
      $file=$dir.$entry; // the file to add
      $name=$entryDir.$entry; // the zip name for the file
      if (is_dir($file)) {
        $zip->addEmptyDir($name.'/');
        self::zipDir($zip, $file.'/', $name.'/');
      }
      else if (is_file($file)) {
        $zip->addFile($file, $name);
      }
    }
    closedir($handle);
  }
}

?>

RngDoc

# scenario

1) resolve inclusions rng4inc.html
(all XML element should be in same document for identifiers and linking)
2) one html file rng2html.xsl 
2 bis) multi-file rng2frame.html

# PHP command line version

$ php -f RngDoc.php src.rng (dest.html|dest/)?

# Java version (Xalan)

$ java RngDoc "http://svn.code.sf.net/p/algone/code/teibook/teibook.rng" teibook.html

## Java known issues

On a long schema you can have this error:
DTMException: No more DTM IDs are available
This is a bug of the default XSLT processor endorsed in Java <= 1.7, Xalan < 2.7.1

No index for elements, attributes, children, model...
Observed with OpenJDK 1.6

To verify which XSLT processor is working for you do
$>java Xrem
If you see
>> Tansformer class net.sf.saxon.TransformerFactoryImpl from Java Runtime
Your Java Virtual Machine is using the default buggy XSLT xalan processor

You can take good advantage to install a more robust XSLT processor: Saxon
1) download Saxon from https://sourceforge.net/projects/saxon/files/Saxon-HE/
2) find the file saxon9he.jar
3) create or find the folder {java-home}/lib/endorsed/ (see http://docs.oracle.com/javase/6/docs/technotes/guides/standards/)
4) copy saxon in it {java-home}/lib/endorsed/saxon9he.jar
5) $> java Xrem 
6) >> Tansformer class net.sf.saxon.TransformerFactoryImpl from Java Runtime

Test it with a quite complex schema
java Xrem "http://svn.code.sf.net/p/algone/code/teibook/teibook.rng" teibook.html

import java.io.File;
import java.io.PrintWriter;
import java.io.StringReader;
import java.security.CodeSource;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.transform.Source;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMResult;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;

import org.w3c.dom.Document;

import com.sun.org.apache.xalan.internal.xslt.EnvironmentCheck;

/**
 * A demo class to use the XSL resources in Xrem folder
 * TODO : generic object process with piping steps 
 * @author Frédéric Glorieux
 *
 */
public class Xrem {
	/** The XSLT processor */
	static TransformerFactory factory=TransformerFactory.newInstance();
	/** 
	 * Document RNG file as one HTML file.
	 * Transformation scenario
	 * 1) resolve includes (known limitation : overrides not greatly handled)
	 * 2) transform to html the entire schema 
	 * @throws TransformerException 
	 */
	public static void rng2html(String src, String dest) throws TransformerException {
		Transformer transformer;
		Source xslt;
		// getResourceAsStream() seems enough to resolve relative links, wait and see
		xslt = new StreamSource(Xrem.class.getResourceAsStream("rng4inc.xsl"));
		transformer=factory.newTransformer(xslt);
		DOMResult result= new DOMResult();
		transformer.transform(new StreamSource(src), result);
		xslt = new StreamSource(Xrem.class.getResourceAsStream("rng2html.xsl"));
		transformer=factory.newTransformer(xslt);
		// do not forget systemID, maybe useful to resolve links
		transformer.transform(new DOMSource(result.getNode(), src), new StreamResult(dest));
	}
	/** Command line */
	public static void main(String[] args) throws Exception {
		if (args==null || args.length==0 || args[0].equals("-h") || args[0].equals("-help")) {
			System.out.println(
			   "Xrem - cross remarks in XML file\n"
			 + "Usage: java Xrem src.rng dest.html\n"
			);
			Class cl=TransformerFactory.newInstance().getClass();
			CodeSource source =cl.getProtectionDomain().getCodeSource();
			System.out.println("Tansformer "+cl+" from "+ (source == null ? "Java Runtime" : source.getLocation()));
			System.exit(1);
		}
		rng2html(args[0], args[1]);
	}
}
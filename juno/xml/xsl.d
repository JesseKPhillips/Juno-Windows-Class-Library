/**
 * Provides support for Extensible Stylesheet Transformation (XSLT) transforms.
 */
module juno.xml.xsl;

private import juno.base.all,
  juno.com.core,
  juno.xml.core,
  juno.xml.dom,
  juno.xml.msxml;

/**
 * The exception thrown when an error occurs while processing an XSLT transformation.
 */
public class XsltException : Throwable {

  private int lineNumber_;
  private int linePosition_;
  private char[] message_;
  private char[] reason_;
  private char[] sourceUri_;

  /**
   * Creates a new instance of the XsltException class.
   * Params: message = The _message describing the error.
   */
  public this(char[] message = null) {
    super(message);
  }

  /**
   * Retrieves the line number indicating where the error occurred in the style sheet.
   */
  public int lineNumber() {
    return lineNumber_;
  }

  /**
   * Retrieves the line position indicating where the error occurred in the style sheet.
   */
  public int linePosition() {
    return linePosition_;
  }

  /**
   * Retrieves the location of the style sheet.
   */
  public char[] sourceUri() {
    return sourceUri_;
  }

  package this(char[] reason, int lineNumber, int linePosition, char[] sourceUri) {
    super(createMessage(reason, sourceUri, lineNumber, linePosition));
    reason_ = reason;
    lineNumber_ = lineNumber;
    linePosition_ = linePosition;
    sourceUri_ = sourceUri;
  }

  private static char[] createMessage(char[] reason, char[] sourceUri, int lineNumber, int linePosition) {
    char[] s = reason;
    if (lineNumber != 0)
      s ~= " " ~ format(S_XML_ERRORPOSITION, lineNumber, linePosition);
    return s;
  }

}

/**
 * Contains arguments that are XSLT parameters.
 */
public class XsltArgumentList {

  private VARIANT[XmlQualifiedName] parameters_;

  /**
   * Adds a parameter to the argument list and associates it with the namespace-qualified name.
   * Params:
   *        name = The name to associate with the _parameter.
   *        namespaceURI = The namespace URI to associate with the _parameter.
   *        parameter = The value to add to the list.
   */
  public final void addParam(T)(char[] name, char[] namespaceURI, T parameter) {
    auto qname = new XmlQualifiedName(name, namespaceURI);
    static if (is(T : XmlNode))
      parameters_[qname] = toVariant(parameter.nativeNode);
    else
      parameters_[qname] = toVariant(parameter);
  }

  /**
   * Returns the parameter associated with the namespace-qualified name.
   * Params:
   *        name = The _name associated with the _parameter.
   *        namespaceURI = The namespace URI associated with the _parameter.
   */
  public final T getParam(T)(char[] name, char[] namespaceURI) {
    VARIANT p = parameters_[new XmlQualifiedName(name, namespaceURI)];
    static if (is(T : XmlNode))
      return cast(T)getNodeShim(cast(IXMLDOMNode)p.pdispVal);
    else static if (is(T : Object))
      return cast(T)p.byref;
    else
      return com_cast!(T)(p);
  }

  /**
   * Removes the parameter.
   * Params:
   *        name = The _name associated with the _parameter.
   *        namespaceURI = The namespace URI associated with the _parameter.
   */
  public final T removeParam(T)(char[] name, char[] namespaceURI) {
    T result = T.init;
    VARIANT p = parameters_[new XmlQualifiedName(name, namespaceURI)];
    static if (is(T : XmlNode))
      result = cast(T)getNodeShim(cast(IXMLDOMNode)p.pdispVal);
    else static if (is(T : Object))
      result = cast(T)p.byref;
    else
      result = com_cast!(T)(p);
    parameters_.remove(qname);
    return result;
  }

  /**
   * Removes all parameters.
   */
  public final void clear() {
    parameters_ = null;
  }

}

/**
 * Specifies the XSLT features to support by the XSLT style sheet.
 */
public final class XsltSettings {

  /**
   * Creates a new instance with the specified settings.
   * Params:
   *        enableDocumentFunction = true to enable support for the XSLT document() function; otherwise, false.
   *        enableScript = true to enable support for embedded script block; otherwise, false.
   */
  public this(bool enableDocumentFunction = false, bool enableScript = false) {
    this.enableDocumentFunction = enableDocumentFunction;
    this.enableScript = enableScript;
  }

  /**
   * Indicates whether to enable support for the XSLT document() function. The default is false.
   */
  public bool enableDocumentFunction;
  /**
   * Indicates whether to enable support for embedded script blocks. The default is false.
   */
  public bool enableScript;

}

/**
 * Transforms XML data using an XSLT style sheet.
 */
public final class XslTransform {

  private class Processor {

    private XmlDocument document_;
    private XsltArgumentList args_;
    private IXSLTemplate template_;
    private IXSLProcessor processor_;

    private this(XmlDocument doc, XsltArgumentList args) {
      document_ = doc;
      args_ = args;

      try {
        template_ = XSLTemplate60.coCreate!(IXSLTemplate, true);
      }
      catch {
        try {
          template_ = XSLTemplate40.coCreate!(IXSLTemplate, true);
        }
        catch {
          template_ = XSLTemplate30.coCreate!(IXSLTemplate, true);
        }
      }

      template_.setref_stylesheet(this.outer.stylesheet_);
      template_.createProcessor(processor_);
    }

    ~this() {
      document_ = null;
      if (processor_ !is null) {
        processor_.Release();
        processor_ = null;
      }
      if (template_ !is null) {
        template_.Release();
        template_ = null;
      }
    }

    private void execute(std.stream.Stream stream) {
      if (args_ !is null) {
        foreach (qname, param; args_.parameters_) {
          wchar* bstrName = utf8ToBstr(qname.name);
          wchar* bstrNs = utf8ToBstr(qname.namespace);

          if (param.vt == VT_BYREF && param.byref != null)
            param.bstrVal = utf8ToBstr((cast(Object)param.byref).toString());

          processor_.addParameter(bstrName, param, bstrNs);

          freeBstr(bstrName);
          freeBstr(bstrNs);
        }
      }

      VARIANT input = toVariant(document_.nativeNode);
      clearAfter (input, {
        int hr = processor_.set_input(input);
        if (hr == S_OK) {
          VARIANT output = VARIANT(cast(IStream)(new COMOutputStream(stream)));
          clearAfter (output, {
            processor_.set_output(output);
            com_bool success;
            processor_.transform(success);
          });
        }
      });
    }

  }

  private IXMLDOMDocument2 stylesheet_;
  private int msxmlVersion_;

  /**
   * Creates a new instance of the XslTransform class.
   */
  public this() {
    // The style sheet must allow multiple threads to access it (free-threaded) or XSLTemplate will not work.
    try {
      stylesheet_ = cast(IXMLDOMDocument2)FreeThreadedDOMDocument60.coCreate!(IXMLDOMDocument3, true);
      msxmlVersion_ = 6;
    }
    catch (COMException) {
      try {
        stylesheet_ = FreeThreadedDOMDocument40.coCreate!(IXMLDOMDocument2, true);
        msxmlVersion_ = 4;
      }
      catch (COMException) {
        stylesheet_ = FreeThreadedDOMDocument30.coCreate!(IXMLDOMDocument2, true);
        msxmlVersion_ = 3;
      }
    }

    stylesheet_.set_async(com_false);
    stylesheet_.set_validateOnParse(com_false);
    if (msxmlVersion_ >= 4)
      stylesheet_.setProperty("NewParser", toVariant(true));
  }

  ~this() {
    if (stylesheet_ !is null) {
      stylesheet_.Release();
      stylesheet_ = null;
    }
  }

  /**
   * Loads the style sheet located at the specified URI.
   * Params: 
   *        stylesheetUri = The URI of the style sheet.
   *        settings = The _settings to apply to the style sheet.
   */
  public void load(char[] stylesheetUri, XsltSettings settings = null) {
    if (settings is null)
      settings = new XsltSettings(false, false);

    stylesheet_.setProperty("AllowDocumentFunction", toVariant(settings.enableDocumentFunction));
    stylesheet_.setProperty("AllowXsltScript", toVariant(settings.enableScript));

    com_bool success;

    VARIANT source = stylesheetUri.toVariant();
    clearAfter (source, {
      stylesheet_.load(source, success);
    });

    if (success != com_true)
      throw parsingException();
  }

  /**
   * Loads the style sheet contained in the XmlDocument.
   * Params:
   *        stylesheet = The XmlDocument containing the style sheet.
   *        settings = The _settings to apply to the style sheet.
   */
  public void load(XmlDocument stylesheet, XsltSettings settings = null) {
    if (settings is null)
      settings = new XsltSettings(false, false);

    stylesheet_.setProperty("AllowDocumentFunction", toVariant(settings.enableDocumentFunction));
    stylesheet_.setProperty("AllowXsltScript", toVariant(settings.enableScript));

    com_bool success;

    VARIANT source = toVariant(stylesheet.nativeNode);
    clearAfter (source, {
      stylesheet_.load(source, success);
    });

    if (success != com_true)
      throw parsingException();
  }

  /**
   * Executes the _transform using the input document specified by the URI and outputs the results to a file.
   * Params:
   *        inputUri = The URI of the input document.
   *        resultsFile = The URI of the output file.
   */
  public void transform(char[] inputUri, char[] resultsFile) {
    auto std.stream.File fs = new std.stream.File(resultsFile, std.stream.FileMode.OutNew);
    transform(inputUri, null, fs);
  }

  /**
   * Executes the _transform using the input document specified by the URI and outputs the _results to a stream.
   * Params:
   *        inputUri = The URI of the input document.
   *        arguments = The namespace-qualified parameters used as input to the _transform. This can be null.
   *        results = The stream to output.
   */
  public void transform(char[] inputUri, XsltArgumentList arguments, std.stream.Stream results) {
    auto XmlDocument doc = new XmlDocument;
    doc.load(inputUri);
    transform(doc, arguments, results);
  }

  /**
   * Executes the _transform using the _input document specified by the XmlDocument and outputs the _results to a stream.
   * Params:
   *        input = An XmlDocument containing the data to be transformed.
   *        arguments = The namespace-qualified parameters used as _input to the _transform. This can be null.
   *        results = The stream to output.
   */
  public void transform(XmlDocument input, XsltArgumentList arguments, std.stream.Stream results) {
    (new Processor(input, arguments)).execute(results);
  }

  private XsltException parsingException() {
    IXMLDOMParseError parseError;
    stylesheet_.get_parseError(parseError);

    wchar* bstrReason, bstrSourceUri;
    int lineNumber, linePosition;
    parseError.get_reason(bstrReason);
    parseError.get_url(bstrSourceUri);
    parseError.get_line(lineNumber);
    parseError.get_linepos(linePosition);

    tryRelease(parseError);

    char[] reason = bstrToUtf8(bstrReason);
    char[] sourceUri = bstrToUtf8(bstrSourceUri);
    if (reason[$ - 1] == '\n')
      reason = reason[0 .. $ - 2];

    return new XsltException(reason, lineNumber, linePosition, sourceUri);
  }

}
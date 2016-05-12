/**
 * Provides supprt for Extensible Stylesheet Transformation (XSLT) transforms.
 *
 * Copyright: (c) 2009 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.xml.xsl;

import juno.base.core,
  juno.base.string,
  juno.com.core,
  juno.xml.core,
  juno.xml.dom,
  juno.xml.msxml,
  std.stream;

/**
 * The exception thrown when an error occurs while processing an XSLT transformation.
 */
class XsltException : Exception {

  private int lineNumber_;
  private int linePosition_;
  private string sourceUri_;

  /**
   * Initializes a new instance.
   * Params:
   *   message = The description of the error.
   *   cause = The Exception that threw the XsltException.
   */
  this(string message = null, int lineNumber = 0, int linePosition = 0, string sourceUri = null) {
    super(createMessage(message, lineNumber, linePosition));
    lineNumber_ = lineNumber;
    linePosition_ = linePosition_;
    sourceUri_ = sourceUri;
  }

  /**
   * Gets the line number indicating where the error occurred.
   * Returns: The line number indicating where the error occurred.
   */
  final int lineNumber() {
    return lineNumber_;
  }

  /**
   * Gets the line position indicating where the error occurred.
   * Returns: The line position indicating where the error occurred.
   */
  final int linePosition() {
    return linePosition_;
  }

  /**
   * Gets the location path of the style sheet.
   * Returns: The location path of the style sheet.
   */
  public string sourceUri() {
    return sourceUri_;
  }

  private static string createMessage(string s, int lineNumber, int linePosition) {
    string result = s;
    if (lineNumber != 0)
      result ~= format(" Line {0}, position {1}.", lineNumber, linePosition);
    return result;
  }

}

/**
 * Specifies the XSLT features to support during execution of the style sheet.
 */
final class XsltSettings {

  /// Indicates whether to enable support for the XSLT document() function.
  bool enableDocumentFunction;

  /// Indicates whether to enable support for embedded script blocks.
  bool enableScript;

  this(bool enableDocumentFunction = false, bool enableScript = false) {
    this.enableDocumentFunction = enableDocumentFunction;
    this.enableScript = enableScript;
  }

}

/**
 * Contains a variable number of arguments that are either XSLT parameters or extension objects.
 */
final class XsltArgumentList {

  private VARIANT[XmlQualifiedName] parameters_;
  private Object[string] extensions_;

  /**
   * Adds a _parameter and associates it with the namespace-qualified _name.
   * Params:
   *   name = The _name to associate with the _parameter.
   *   namespaceUri = The namespace URI to associate with the _parameter.
   *   parameter = The _parameter value to add to the list.
   */
  void addParam(T)(string name, string namespaceUri, T parameter) {
    auto qname = new XmlQualifiedName(name, namespaceUri);
    static if (is(T : XmlNode))
      parameters_[qname] = VARIANT(parameter.impl);
    else
      parameters_[qname] = VARIANT(parameter);
  }

  /**
   * Gets the parameter associated with the namespace-qualified _name.
   * Params:
   *   name = The _name of the parameter.
   *   namespaceUri = The namespace URI associated with the parameter.
   * Returns: The parameter or $(B T.init) if one was not found.
   */
  T getParam(T)(string name, string namespaceUri) {
    T ret = T.init;

    auto qname = new XmlQualifiedName(name, namespaceUri);
    if (auto param = qname in parameters_) {
      static if (is(T : XmlNode))
        ret = cast(T)getNodeShim(cast(IXMLDOMNode)param.pdispVal);
      else static if (is(T : Object))
        ret = cast(T)param.byref;
      else
        ret = com_cast!(T)(*param);
    }

    return ret;
  }

  /**
   * Removes the parameter.
   * Params:
   *   name = The _name of the parameter to remove.
   *   namespaceUri = The namespace URI of the parameter to remove.
   * Returns: The parameter or $(B T.init) if one was not found.
   */
  T removeParam(T)(string name, string namespaceUri) {
    T ret = T.init;

    auto qname = new XmlQualifiedName(name, namespaceUri);

    if (auto param = qname in parameters_) {
      static if (is(T : XmlNode))
        ret = cast(T)getNodeShim(cast(IXMLDOMNode)param.pdispVal);
      else static if (is(T : Object))
        ret = cast(T)param.byref;
      else
        ret = com_cast!(T)(*param);
    }

    parameters_.remove(qname);

    return ret;
  }

  /**
   * Adds a new object and associates it with the namespace URI.
   * Params:
   *   namespaceUri = The namespace URI to associate with the object.
   *   extension = The object to add to the list.
   */
  void addExtensionObject(string namespaceUri, Object extension) {
    extensions_[namespaceUri] = extension;
  }

  /**
   * Gets the object associated with the specified namespace URI.
   * Params: namespaceUri = The namespace URI of the object.
   * Returns: The object or null if one was not found.
   */
  Object getExtensionObject(string namespaceUri) {
    if (auto extension = namespaceUri in extensions_)
      return *extension;
    return null;
  }

  /**
   * Removes the object associated with the specified namespace URI.
   * Params: namespaceUri = The namespace URI of the object.
   * Returns: The object or null if one was not found.
   */
  Object removeExtensionObject(string namespaceUri) {
    if (auto extension = namespaceUri in extensions_) {
      extensions_.remove(namespaceUri);
      return *extension;
    }
    return null;
  }

  /**
   * Removes all parameters and extension objects.
   */
  void clear() {
    foreach (key, value; parameters_)
      value.clear();

    parameters_ = null;
    extensions_ = null;
  }

}

/**
 * Transforms XML data using an XSLT style sheet.
 * Examples::
 * ---
 * // Load the style sheet.
 * scope stylesheet = new XslTransform;
 * stylesheet.load("output.xsl");
 *
 * // Execute the transform and output the results to a file.
 * stylesheet.transform("books.xml", "books.html");
 * ---
 */
final class XslTransform {

  private class XsltProcessor {

    private XmlDocument document_;
    private XsltArgumentList args_;
    private IXSLTemplate template_;
    private IXSLProcessor processor_;

    private this(XmlDocument doc, XsltArgumentList args) {
      document_ = doc;
      args_ = args;

      if ((template_ = XSLTemplate60.coCreate!(IXSLTemplate)()) is null) {
        if ((template_ = XSLTemplate40.coCreate!(IXSLTemplate)()) is null)
          template_ = XSLTemplate30.coCreate!(IXSLTemplate, ExceptionPolicy.Throw)();
      }

      template_.putref_stylesheet(this.outer.stylesheet_);
      template_.createProcessor(processor_);
    }

    ~this() {
      document_ = null;
      if (processor_ !is null) {
        tryRelease(processor_);
        processor_ = null;
      }
      if (template_ !is null) {
        tryRelease(template_);
        template_ = null;
      }
    }

    private void execute(Stream results) {
      if (args_ !is null) {
        foreach (qname, param; args_.parameters_) {
          wchar* bstrName = toBstr(qname.name);
          wchar* bstrNs = toBstr(qname.namespace);

          if (param.vt == VT_BYREF && param.byref != null) {
            if (auto obj = cast(Object)param.byref)
              param.bstrVal = toBstr(obj.toString());
          }

          processor_.addParameter(bstrName, param, bstrNs);

          freeBstr(bstrName);
          freeBstr(bstrNs);
        }

        foreach (name, extension; args_.extensions_) {
          if (auto disp = cast(IDispatch)extension) {
            wchar* bstrNs = toBstr(name);
            processor_.addObject(disp, bstrNs);
            freeBstr(bstrNs);
          }
        }
      }

      VARIANT input = document_.impl;
      scope(exit) input.clear();

      if (processor_.put_input(input) == S_OK) {
        VARIANT output = new COMStream(results);
        scope(exit) output.clear();

        processor_.put_output(output);

        VARIANT_BOOL success;
        processor_.transform(success);
      }
    }

  }

  private IXMLDOMDocument2 stylesheet_;

  /**
   * Initializes a new instance.
   */
  this() {
    if ((stylesheet_ = FreeThreadedDOMDocument60.coCreate!(IXMLDOMDocument3)()) is null) {
      if ((stylesheet_ = FreeThreadedDOMDocument40.coCreate!(IXMLDOMDocument2)()) is null)
        stylesheet_ = FreeThreadedDOMDocument30.coCreate!(IXMLDOMDocument2, ExceptionPolicy.Throw)();
    }

    stylesheet_.put_async(VARIANT_FALSE);
    stylesheet_.put_validateOnParse(VARIANT_FALSE);
    stylesheet_.setProperty(cast(wchar*)"NewParser", VARIANT(true));
  }

  ~this() {
    if (stylesheet_ !is null) {
      tryRelease(stylesheet_);
      stylesheet_ = null;
    }
  }

  /**
   * Loads the style sheet located at the specified URI.
   * Params:
   *   stylesheetUri = The URI of the style sheet.
   *   settings = The features to apply to the style sheet.
   * Throws: XsltException if the style sheet contains an error.
   */
  void load(string stylesheetUri, XsltSettings settings = null) {
    if (settings is null)
      settings = new XsltSettings;

    stylesheet_.setProperty(cast(wchar*)"AllowDocumentFunction", VARIANT(settings.enableDocumentFunction));
    stylesheet_.setProperty(cast(wchar*)"AllowXsltScript", VARIANT(settings.enableScript));

    VARIANT source = stylesheetUri;
    scope(exit) source.clear();

    VARIANT_BOOL success;
    stylesheet_.load(source, success);
    if (success != VARIANT_TRUE)
      parsingException();
  }

  /**
   * Executes the _transform using the input document specified by the URI and outputs the results to a file.
   * Params:
   *   inputUri = The URI of the input document.
   *   resultsFile = The URI of the output document.
   */
  void transform(string inputUri, string resultsFile) {
    scope fs = new File(resultsFile, FileMode.OutNew);
    transform(inputUri, null, fs);
  }

  /**
   * Executes the _transform using the input document specified by the URI and outputs the _results to a stream.
   * Params:
   *   inputUri = The URI of the input document.
   *   arguments = The namespace-qualified arguments used as input to the _transform.
   *   results = The stream to output.
   * Examples::
   *   The following example shows how to write the _results to an XmlDocument.
   * ---
   * // The resulting document.
   * scope resultDoc = new XmlDocument;
   * 
   * // Load the transform.
   * scope stylesheet = new XslTransform;
   * stylesheet.load("output.xsl");
   *
   * // Save the results to a MemoryStream.
   * scope ms = new MemoryStream;
   * stylesheet.transform("books.xml", null, ms);
   *
   * // Load the results into the document.
   * resultDoc.load(ms);
   * ---
   */
  void transform(string inputUri, XsltArgumentList arguments, Stream results) {
    scope doc = new XmlDocument;
    doc.load(inputUri);
    transform(doc, arguments, results);
  }

  /**
   * Executes the _transform using the specified _input document and outputs the _results to a stream.
   * Params:
   *   input = The document containing the data to be transformed.
   *   arguments = The namespace-qualified arguments used as input to the _transform.
   *   results = The stream to output.
   */
  void transform(XmlDocument input, XsltArgumentList arguments, Stream results) {
    if (results is null)
      throw new ArgumentNullException("results");

    scope processor = new XsltProcessor(input, arguments);
    processor.execute(results);
  }

  private void parsingException() {
    IXMLDOMParseError errorObj;
    if (stylesheet_.get_parseError(errorObj) == S_OK) {
      scope(exit) errorObj.Release();

      wchar* bstrReason, bstrUrl;
      int line, position;

      errorObj.get_reason(bstrReason);
      errorObj.get_url(bstrUrl);
      errorObj.get_line(line);
      errorObj.get_linepos(position);

      string reason = fromBstr(bstrReason);
      if (reason[$ - 1] == '\n')
        reason = reason[0 .. $ - 2];

      throw new XsltException(reason, line, position, fromBstr(bstrUrl));
    }
  }

}

/**
 * Provides standards-based support for processing XML.
 *
 * Copyright: (c) 2009 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.xml.dom;

import juno.base.core,
  juno.base.string,
  juno.com.core,
  juno.xml.core,
  juno.xml.msxml,
  std.stream,
  std.utf;

debug import std.stdio : writefln;

/**
 * Adds namespaces to a collection and provides scope management.
 *
 * Examples:
 * ---
 * scope mgr = new XmlNamespaceManager;
 * mgr.addNamespace("rdf", "http://www.w3.org/1999/02/22-rdf-syntax-ns#");
 * mgr.addNamespace("dc", "http://purl.org/dc/elements/1.1/");
 * mgr.addNamespace("rss", "http://purl.org/rss/1.0/");
 *
 * scope doc = new XmlDocument;
 * doc.load("http://del.icio.us/rss");
 * foreach (node; doc.documentElement.selectNodes("/rdf:RDF/rss:item", mgr)) {
 *   if (node !is null)
 *     writefln(node.text);
 * }
 * ---
 */
class XmlNamespaceManager {

  private IMXNamespaceManager nsmgrImpl_;

  this() {
    if ((nsmgrImpl_ = MXNamespaceManager60.coCreate!(IMXNamespaceManager)) is null) {
      if ((nsmgrImpl_ = MXNamespaceManager40.coCreate!(IMXNamespaceManager)) is null) {
        nsmgrImpl_ = MXNamespaceManager.coCreate!(IMXNamespaceManager, ExceptionPolicy.Throw);
      }
    }
  }

  /**
   * Adds the given namespace to the collection.
   * Params:
   *   prefix = The _prefix to associate with the namespace being added.
   *   uri = The namespace to add.
   */
  void addNamespace(string prefix, string uri) {
    nsmgrImpl_.declarePrefix(prefix.toUTF16z(), uri.toUTF16z());
  }

  /**
   * Retrieves a value indicating whether the supplied _prefix has a namespace for the current scope.
   * Params: prefix = The _prefix of the namespace to find.
   * Returns: true if a namespace is defined; otherwise, false.
   */
  bool hasNamespace(string prefix) {
    int cchUri;
    return (nsmgrImpl_.getURI(prefix.toUTF16z(), null, null, cchUri) == S_OK);
  }

  /**
   * Finds the prefix with the given namespace.
   * Params: uri = The namespace to resolve for the prefix.
   * Returns: The matching prefix.
   */
  string lookupPrefix(string uri) {
    wchar[100] pwchPrefix;
    int cchPrefix = pwchPrefix.length;
    if (nsmgrImpl_.getPrefix(uri.toUTF16z(), 0, pwchPrefix.ptr, cchPrefix) == S_OK)
      return toUtf8(pwchPrefix.ptr, 0, cchPrefix);
    return null;
  }

  /**
   * Finds the namespace for the specified _prefix.
   * Params: prefix = The _prefix whose namespace you want to resolve.
   * Returns: The namespace for prefix.
   */
  string lookupNamespace(string prefix) {
    wchar[100] pwchUri;
    int cchUri = pwchUri.length;
    if (nsmgrImpl_.getURI(prefix.toUTF16z(), null, pwchUri.ptr, cchUri) == S_OK)
      return toUtf8(pwchUri.ptr, 0, cchUri);
    return null;
  }

  /**
   * Pops a namespace scope off the stack.
   * Returns: true if there are namespace scopes left on the stack; otherwise, false.
   */
  bool popScope() {
    return (nsmgrImpl_.popContext() == S_OK);
  }

  /**
   * Pushes a namespace scope onto the stack.
   */
  void pushScope() {
    nsmgrImpl_.pushContext();
  }

  /**
   * Provides foreach-style iteratation through the prefixes stored.
   */
  int opApply(int delegate(ref string) action) {
    int result, index, hr;
    do {
      wchar[100] pwchPrefix;
      int cchPrefix = pwchPrefix.length;
      if ((hr = nsmgrImpl_.getDeclaredPrefix(index, pwchPrefix.ptr, cchPrefix)) == S_OK) {
        string s = toUtf8(pwchPrefix.ptr, 0, cchPrefix);
        if ((result = action(s)) != 0)
          break;
        index++;
      }
    } while (hr == S_OK);
    return result;
  }

  ~this() {
    if (nsmgrImpl_ !is null) {
      tryRelease(nsmgrImpl_);
      nsmgrImpl_ = null;
    }
  }

}

package XmlNode getNodeShim(IXMLDOMNode node) {

  bool isXmlDeclaration(IXMLDOMNode node) {
    wchar* bstrName;
    if (node.get_nodeName(bstrName) == S_OK)
      return (fromBstr(bstrName) == "xml");
    return false; 
  }

  bool parseXmlDeclaration(IXMLDOMNode node, out string xmlversion, out string encoding, out string standalone) {

    string getAttrValue(IXMLDOMNamedNodeMap attrs, string name) {
      string value;
      IXMLDOMNode namedItem;

      wchar* bstrName = toBstr(name);
      if (attrs.getNamedItem(bstrName, namedItem) == S_OK) {
        scope(exit) tryRelease(namedItem);
        VARIANT var;
        if (SUCCEEDED(namedItem.get_nodeValue(var))) {
          scope(exit) var.clear();
          value = var.toString();
        }
      }
      freeBstr(bstrName);
      return value;
    }

    xmlversion = null, encoding = null, standalone = null;
    IXMLDOMNamedNodeMap attrs;
    if (node.get_attributes(attrs) == S_OK) {
      scope(exit) tryRelease(attrs);

      xmlversion = getAttrValue(attrs, "version");
      encoding = getAttrValue(attrs, "encoding");
      standalone = getAttrValue(attrs, "standalone");

      return true;
    }
    return false;
  }

  if (node is null)
    return null;

  DOMNodeType nt;
  node.get_nodeType(nt);
  switch (nt) {
    case DOMNodeType.NODE_CDATA_SECTION:
      return new XmlCDataSection(node);
    case DOMNodeType.NODE_COMMENT:
      return new XmlComment(node);
    case DOMNodeType.NODE_TEXT:
      return new XmlText(node);
    case DOMNodeType.NODE_ATTRIBUTE:
      return new XmlAttribute(node);
    case DOMNodeType.NODE_ELEMENT:
      return new XmlElement(node);
    case DOMNodeType.NODE_PROCESSING_INSTRUCTION:
      // MSXML doesn't treat XML declarations as a distinct node type.
      if (isXmlDeclaration(node)) {
        string xmlversion, encoding, standalone;
        if (parseXmlDeclaration(node, xmlversion, encoding, standalone))
          return new XmlDeclaration(xmlversion, encoding, standalone, node);
      }
      return new XmlProcessingInstruction(node);
    case DOMNodeType.NODE_ENTITY:
      return new XmlEntity(node);
    case DOMNodeType.NODE_ENTITY_REFERENCE:
      return new XmlEntityReference(node);
    case DOMNodeType.NODE_NOTATION:
      return new XmlNotation(node);
    case DOMNodeType.NODE_DOCUMENT_FRAGMENT:
      return new XmlDocumentFragment(node);
    case DOMNodeType.NODE_DOCUMENT_TYPE:
      return new XmlDocumentType(node);
    case DOMNodeType.NODE_DOCUMENT:
      return new XmlDocument(node);
    default:
  }

  return null;
}

class XPathException : Exception {

  this(string message = null) {
    super(message);
  }

}

/**
 * Represents an ordered collection of nodes.
 */
abstract class XmlNodeList {

  /**
   * Retrieves the node at the given _index.
   * Params: index = The _index into the list of nodes.
   * Returns: The node in the collection at index.
   */
  abstract XmlNode item(int index);

  /**
   * ditto
   */
  XmlNode opIndex(int i) {
    return item(i);
  }

  /**
   * Gets the number of nodes in the collection.
   * Returns: The number of nodes.
   */
  abstract int size();

  /**
   * Provides foreach iteration over the collection of nodes.
   */
  abstract int opApply(int delegate(ref XmlNode) action);

  protected this() {
  }

}

private class XmlChildNodes : XmlNodeList {

  private IXMLDOMNodeList listImpl_;

  package this(IXMLDOMNodeList listImpl) {
    listImpl_ = listImpl;
  }

  ~this() {
    if (listImpl_ !is null) {
      tryRelease(listImpl_);
      listImpl_ = null;
    }
  }

  override XmlNode item(int index) {
    IXMLDOMNode node;
    if (SUCCEEDED(listImpl_.get_item(index, node)))
      return getNodeShim(node);
    return null;
  }

  override int opApply(int delegate(ref XmlNode) action) {
    int result;
    IXMLDOMNode node;
    do {
      if (SUCCEEDED(listImpl_.nextNode(node))) {
        XmlNode n = getNodeShim(node);
        if ((result = action(n)) != 0)
          break;
      }
    } while (node !is null);
    listImpl_.reset();
    return result;
  }

  override int size() {
    int length;
    return SUCCEEDED(listImpl_.get_length(length)) ? length : 0;
  }

}

private class XPathNodeList : XmlNodeList {

  private IXMLDOMSelection iterator_;

  this(IXMLDOMSelection iterator) {
    iterator_ = iterator;
  }

  ~this() {
    if (iterator_ !is null) {
      tryRelease(iterator_);
      iterator_ = null;
    }
  }

  override XmlNode item(int index) {
    IXMLDOMNode listItem;
    iterator_.get_item(index, listItem);
    return getNodeShim(listItem);
  }

  override int size() {
    int listLength;
    iterator_.get_length(listLength);
    return listLength;
  }

  override int opApply(int delegate(ref XmlNode) action) {
    int result = 0;

    int hr;
    IXMLDOMNode n;

    while ((hr = iterator_.nextNode(n)) == S_OK) {
      XmlNode node = getNodeShim(n);
      if ((result = action(node)) != 0)
        break;
    }

    iterator_.reset();
    return result;
  }

}

/**
 * Provides a way to navigate XML data.
 */
abstract class XPathNavigator {

  /**
   * Determines whether the current node _matches the specified XPath expression.
   */
  bool matches(string xpath) {
    return false;
  }

  /**
   * Selects a node set using the specified XPath expression.
   */
  XmlNodeList select(string xpath) {
    return null;
  }

  /**
   * Selects all the ancestor nodes of the current node.
   */
  XmlNodeList selectAncestors() {
    return select("./ancestor::node()");
  }

  /**
   * Selects all the descendant nodes of the current node.
   */
  XmlNodeList selectDescendants() {
    return select("./descendant::node()");
  }

  /**
   * Selects all the child nodes of the current node.
   */
  XmlNodeList selectChildren() {
    return select("./node()");
  }

}

private class DocumentXPathNavigator : XPathNavigator {

  private XmlDocument document_;
  private XmlNode node_;

  this(XmlDocument document, XmlNode node) {
    document_ = document;
    node_ = node;
  }

  override bool matches(string xpath) {
    wchar* bstrExpression = toBstr(xpath);
    scope(exit) freeBstr(bstrExpression);

    IXMLDOMNodeList nodeList;
    int hr;
    if (SUCCEEDED(hr = document_.nodeImpl_.selectNodes(bstrExpression, nodeList))) {
      scope(exit) tryRelease(nodeList);
      IXMLDOMNode n;
      if (SUCCEEDED((cast(IXMLDOMSelection)nodeList).matches(node_.nodeImpl_, n))) {
        scope(exit) tryRelease(n);
        return n !is null;
      }
    }
    else
      throw xpathException(hr);
    return false;
  }

  override XmlNodeList select(string xpath) { 
    wchar* bstrExpression = toBstr(xpath);
    scope(exit) freeBstr(bstrExpression);

    IXMLDOMNodeList nodeList;
    int hr;
    //if (SUCCEEDED(hr = document_.nodeImpl_.selectNodes(bstrExpression, nodeList)))
    if (SUCCEEDED(hr = node_.nodeImpl_.selectNodes(bstrExpression, nodeList)))
      return new XPathNodeList(cast(IXMLDOMSelection)nodeList);
    else
      throw xpathException(hr);
  }

  private Exception xpathException(int hr) {
    if (auto support = com_cast!(ISupportErrorInfo)(document_.nodeImpl_)) {
      scope(exit) tryRelease(support);
      if (SUCCEEDED(support.InterfaceSupportsErrorInfo(uuidof!(typeof(document_.nodeImpl_))))) {
        IErrorInfo errorInfo;
        if (SUCCEEDED(GetErrorInfo(0, errorInfo))) {
          scope(exit) tryRelease(errorInfo);

          wchar* bstrDesc;
          errorInfo.GetDescription(bstrDesc);
          string msg = fromBstr(bstrDesc);
          if (msg[$ - 1] == '\n')
            msg = msg[0 .. $ - 2];
          return new XPathException(msg);
        }
      }
    }
    return new COMException(hr);
  }

}

/**
 * Represents a collection of nodes that can be accessed by name or index.
 */
class XmlNamedNodeMap {

  private IXMLDOMNamedNodeMap mapImpl_;

  /**
   * Retrieves the node specified by name.
   * Params: name = The qualified _name of the node to retrieve.
   * Returns: The node with the specified _name.
   */
  XmlNode getNamedItem(string name) {
    IXMLDOMNode node;

    wchar* bstrName = toBstr(name);
    int hr = mapImpl_.getNamedItem(bstrName, node);
    freeBstr(bstrName);

    return (hr == S_OK) ? getNodeShim(node) : null;
  }

  /**
   * Retrieves the node with the matching _localName and _namespaceURI.
   * Params: 
   *   localName = The local name of the node to retrieve.
   *   namespaceURI = The namespace URI of the node to retrieve.
   * Returns: The node with the matching local name and namespace URI.
   */
  XmlNode getNamedItem(string localName, string namespaceURI) {
    IXMLDOMNode node;

    wchar* bstrName = toBstr(localName);
    wchar* bstrNs = toBstr(namespaceURI);

    int hr = mapImpl_.getQualifiedItem(bstrName, bstrNs, node);

    freeBstr(bstrName);
    freeBstr(bstrNs);

    return (hr == S_OK) ? getNodeShim(node) : null;
  }

  /**
   * Removes the node with the specified _name.
   * Params: name = The qualified _name of the node to remove.
   * Returns: The node removed.
   */
  XmlNode removeNamedItem(string name) {
    IXMLDOMNode node;

    wchar* bstrName = toBstr(name);
    int hr = mapImpl_.removeNamedItem(bstrName, node);
    freeBstr(bstrName);

    return (hr == S_OK) ? getNodeShim(node) : null;
  }

  /**
   * Removes the node with the matching _localName and _namespaceURI.
   * Params: 
   *   localName = The local name of the node to remove.
   *   namespaceURI = The namespace URI of the node to remove.
   * Returns: The node removed.
   */
  XmlNode removeNamedItem(string localName, string namespaceURI) {
    IXMLDOMNode node;

    wchar* bstrName = toBstr(localName);
    wchar* bstrNs = toBstr(namespaceURI);

    int hr = mapImpl_.removeQualifiedItem(bstrName, bstrNs, node);

    freeBstr(bstrName);
    freeBstr(bstrNs);

    return (hr == S_OK) ? getNodeShim(node) : null;
  }

  /**
   * Adds a _node using its _name property.
   * Params: node = The _node to store.
   * Returns: The old _node.
   */
  XmlNode setNamedItem(XmlNode node) {
    IXMLDOMNode namedItem;
    if (SUCCEEDED(mapImpl_.setNamedItem(node.nodeImpl_, namedItem)))
      return getNodeShim(namedItem);
    return null;
  }

  /**
   * Retrieves the node at the specified _index.
   * Params: index = The position of the node to retrieve.
   * Returns: The node at the specified _index.
   */
  XmlNode item(int index) {
    IXMLDOMNode node;
    if (SUCCEEDED(mapImpl_.get_item(index, node)))
      return getNodeShim(node);
    return null;
  }

  /**
   * Gets the number of nodes.
   * Returns: The number of nodes.
   */
  int size() {
    int length;
    return (SUCCEEDED(mapImpl_.get_length(length))) ? length : 0;
  }

  /**
   * Provides support for foreach iteration over the collection of nodes.
   */
  int opApply(int delegate(ref XmlNode) action) {
    int result;
    IXMLDOMNode node;

    do {
      if (SUCCEEDED(mapImpl_.nextNode(node))) {
        if (XmlNode currentNode = getNodeShim(node)) {
          if ((result = action(currentNode)) != 0)
            break;
        }
      }
    } while (node !is null);

    mapImpl_.reset();

    return result;
  }

  package this(XmlNode parent) {
    parent.nodeImpl_.get_attributes(mapImpl_);
  }

  package this(IXMLDOMNamedNodeMap mapImpl) {
    mapImpl_ = mapImpl;
  }

  ~this() {
    if (mapImpl_ !is null) {
      tryRelease(mapImpl_);
      mapImpl_ = null;
    }
  }

}

/**
 * Represents a collection of attributes that can be accessed by name or index.
 */
final class XmlAttributeCollection : XmlNamedNodeMap {

  /**
   * Gets the attribute at the specified _index.
   * Params: index = The _index of the attribute.
   * Returns: The attribute at the specified _index.
   */
  final XmlAttribute opIndex(int index) {
    return cast(XmlAttribute)item(index);
  }

  /**
   * Gets the attribute with the specified _name.
   * Params: name = The qualified _name of the attribute.
   * Returns: The attribute with the specified _name.
   */
  final XmlAttribute opIndex(string name) {
    return cast(XmlAttribute)getNamedItem(name);
  }

  /**
   * Gets the attribute with the specified local name and namespace URI.
   * Params: 
   *   localName = The local name of the attribute.
   *   namespaceURI = The namespace URI of the attribute.
   * Returns: The attribute with the specified local name and namespace URI.
   */
  final XmlAttribute opIndex(string localName, string namespaceURI) {
    return cast(XmlAttribute)getNamedItem(localName, namespaceURI);
  }

  package this(XmlNode parent) {
    super(parent);
  }

}

string TypedNode(string type, string field = "typedNodeImpl_") {
  return 
    "private " ~ type ~ " " ~ field ~ ";\n"

    "package this(IXMLDOMNode nodeImpl) {\n"
    "  super(nodeImpl);\n"
    "  " ~ field ~ " = com_cast!(" ~ type ~ ")(nodeImpl);\n"
    "}\n"

    "~this() {\n"
    "  if (" ~ field ~ " !is null) {\n"
    "    tryRelease(" ~ field ~ ");\n"
    "    " ~ field ~ " = null;\n"
    "  }\n"
    "}";
}

/**
 * Represents a single node in the XML document.
 */
class XmlNode {

  private IXMLDOMNode nodeImpl_;

  /**
   * Creates a duplicate of this node.
   * Returns: The cloned node.
   */
  XmlNode clone() {
    return cloneNode(true);
  }

  /**
   * Creates a duplicate of this node.
   * Params: deep = true to recursively clone the subtree under this node; false to clone only the node itself.
   * Returns: The cloned node.
   */
  XmlNode cloneNode(bool deep) {
    IXMLDOMNode cloneRoot;
    nodeImpl_.cloneNode(deep ? VARIANT_TRUE : VARIANT_FALSE, cloneRoot);
    return getNodeShim(cloneRoot);
  }

  /**
   * Adds the specified node to the end of the list of child nodes.
   * Params: newChild = The node to add.
   * Returns: The node added.
   */
  XmlNode appendChild(XmlNode newChild) {
    IXMLDOMNode newNode;
    nodeImpl_.appendChild(newChild.nodeImpl_, newNode);
    return getNodeShim(newNode);
  }

  /**
   * Inserts the specified node immediately before the specified reference node.
   * Params:
   *   newChild = The node to insert.
   *   refChild = The reference node. The newChild is placed before this node.
   * Returns: The inserted node.
   */
  XmlNode insertBefore(XmlNode newChild, XmlNode refChild) {
    if (refChild is null)
      return appendChild(newChild);

    if (newChild is refChild)
      return newChild;

    VARIANT refNode = refChild.nodeImpl_;
    IXMLDOMNode newNode;
    nodeImpl_.insertBefore(newChild.nodeImpl_, refNode, newNode);
    return getNodeShim(newNode);
  }

  /**
   * Inserts the specified node immediately after the specified reference node.
   * Params:
   *   newChild = The node to insert.
   *   refChild = The reference node. The newChild is placed after this node.
   * Returns: The inserted node.
   */
  XmlNode insertAfter(XmlNode newChild, XmlNode refChild) {
    if (refChild is null)
      return insertBefore(newChild, this.firstChild);

    if (newChild is refChild)
      return newChild;

    XmlNode next = refChild.nextSibling;
    if (next !is null)
      return insertBefore(newChild, next);

    return appendChild(newChild);
  }

  /**
   * Replaces the oldChild node with the newChild node.
   * Params:
   *   newChild = The new node to put in the child list.
   *   oldChild = The node being replaced in the child list.
   * Returns: The replaced node.
   */
  XmlNode replaceChild(XmlNode newChild, XmlNode oldChild) {
    XmlNode next = oldChild.nextSibling;
    removeChild(oldChild);
    insertBefore(newChild, next);
    return oldChild;
  }

  /**
   * Removes the specified child node.
   * Params: oldChild = The node being removed.
   * Returns: The removed node.
   */
  XmlNode removeChild(XmlNode oldChild) {
    IXMLDOMNode oldNode;
    nodeImpl_.removeChild(oldChild.nodeImpl_, oldNode);
    return getNodeShim(oldNode);
  }

  /**
   * Removes all the child nodes.
   */
  void removeAll() {
    IXMLDOMNode first, next;
    nodeImpl_.get_firstChild(first);

    while (first !is null) {
      nodeImpl_.get_nextSibling(next);

      IXMLDOMNode dummy;
      nodeImpl_.removeChild(first, dummy);

      if (dummy !is null)
        dummy.Release();
      if (first !is null)
        first.Release();

      first = next;
      if (next !is null)
        next.Release();
    }
  }

  /**
   * Creates an XPathNavigator for navigating this instance.
   */
  XPathNavigator createNavigator() {
    return ownerDocument.createNavigator(this);
  }

  /**
   * Selects the first node that matches the XPath expression.
   * Params: 
   *   xpath = The XPath expression.
   *   nsmgr = The namespace resolver to use.
   * Returns: The first XmlNode that matches the XPath query.
   */
  XmlNode selectSingleNode(string xpath, XmlNamespaceManager nsmgr = null) {
    auto list = selectNodes(xpath, nsmgr);
    if (list !is null && list.size > 0)
      return list[0];
    return null;
  }

  /**
   * Selects a list of nodes matching the XPath expression.
   * Params: 
   *   xpath = The XPath expression.
   *   nsmgr = The namespace resolver to use.
   * Returns: An XmlNodeList containing the nodes matching the XPath query.
   */
  XmlNodeList selectNodes(string xpath, XmlNamespaceManager nsmgr = null) {
    if (nsmgr !is null) {
      // Let MSXML know about any namespace declarations.
      // http://msdn2.microsoft.com/en-us/library/ms756048.aspx

      string sel;
      foreach (prefix; nsmgr) {
        if (prefix != "xmlns")
          sel ~= "xmlns:" ~ prefix ~ "='" ~ nsmgr.lookupNamespace(prefix) ~ "' ";
      }

      VARIANT selectionNs = sel;
      scope(exit) selectionNs.clear();

      IXMLDOMDocument doc;
      if (SUCCEEDED(nodeImpl_.get_ownerDocument(doc))) {
        scope(exit) tryRelease(doc);

        if (auto doc2 = com_cast!(IXMLDOMDocument2)(doc)) {
          scope(exit) tryRelease(doc2);

          wchar* bstrSelectionNamespaces = toBstr("SelectionNamespaces");
          doc2.setProperty(bstrSelectionNamespaces, selectionNs);
          freeBstr(bstrSelectionNamespaces);
        }
      }
    }

    auto nav = createNavigator();
    if (nav !is null)
      return nav.select(xpath);
    return null;
  }

  /**
   * Gets the type of the current node.
   * Returns: One of the XmlNodeType values.
   */
  abstract XmlNodeType nodeType();

  /**
   * Gets the namespace _prefix of this node.
   * Returns: The namespace _prefix for this node. For example, prefix is 'bk' for the element &lt;bk:book&gt;.
   */
  string prefix() {
    return "";
  }

  /**
   * Gets the local name of the node.
   * Returns: The name of the node with the prefix removed.
   */
  abstract string localName() {
    wchar* bstrName;
    if (nodeImpl_.get_baseName(bstrName) == S_OK)
      return fromBstr(bstrName);
    return null;
  }

  /**
   * Gets the qualified _name of the node.
   * Returns: The qualified _name of the node.
   */
  abstract string name() {
    wchar* bstrName;
    if (nodeImpl_.get_nodeName(bstrName) == S_OK)
      return fromBstr(bstrName);
    return null;
  }

  /**
   * Gets the namespace URI of the node.
   * Returns: The namespace URI of the node.
   */
  string namespaceURI() {
    return "";
  }

  /**
   * Gets or sets the values of the node and its child nodes.
   * Returns: The values of the node and its child nodes.
   */
  void text(string value) {
    wchar* bstrValue = toBstr(value);
    if (bstrValue != null) {
      nodeImpl_.put_text(bstrValue);
      freeBstr(bstrValue);
    }
  }

  /**
   * ditto
   */
  string text() {
    wchar* bstrValue;
    if (nodeImpl_.get_text(bstrValue) == S_OK)
      return fromBstr(bstrValue);
    return null;
  }

  /**
   * Gets or sets the markup representing the child nodes.
   * Returns: The markup of the child nodes.
   */
  void xml(string value) {
    throw new InvalidOperationException;
  }

  /**
   * ditto
   */
  string xml() {
    wchar* bstrXml;
    nodeImpl_.get_xml(bstrXml);
    return fromBstr(bstrXml).trim();
  }

  /**
   * Gets or sets the _value of this node.
   */
  void value(string value) {
    throw new InvalidOperationException;
  }

  /**
   * ditto
   */
  string value() {
    return null;
  }

  /**
   * Gets a value indicating whether this node has any child nodes.
   * Returns: true if the node has child nodes; otherwise, false.
   */
  bool hasChildNodes() {
    VARIANT_BOOL result;
    if (SUCCEEDED(nodeImpl_.hasChildNodes(result)))
      return result == VARIANT_TRUE;
    return false;
  }

  /**
   * Gets all the child nodes of the node.
   * Returns: An XmlNodeList containing all the child nodes of the node.
   */
  XmlNodeList childNodes() {
    IXMLDOMNodeList list;
    if (SUCCEEDED(nodeImpl_.get_childNodes(list)))
      return new XmlChildNodes(list);
    return null;
  }

  /** 
   * Gets the first child of the node.
   * Returns: The first child of the node. If there is no such node, null is returned.
   */
  XmlNode firstChild() {
    IXMLDOMNode node;
    if (SUCCEEDED(nodeImpl_.get_firstChild(node)))
      return getNodeShim(node);
    return null;
  }

  /**
   * Gets the last child of the node.
   * Returns: The last child of the node. If there is no such node, null is returned.
   */
  XmlNode lastChild() {
    IXMLDOMNode node;
    if (SUCCEEDED(nodeImpl_.get_lastChild(node)))
      return getNodeShim(node);
    return null;
  }

  /**
   * Gets the node immediately preceding this node.
   * Returns: The preceding XmlNode. If there is no such node, null is returned.
   */
  XmlNode previousSibling() {
    return null;
  }

  /**
   * Gets the node immediately following this node.
   * Returns: The following XmlNode. If there is no such node, null is returned.
   */
  XmlNode nextSibling() {
    return null;
  }

  /**
   * Gets the parent node of this node.
   * Returns: The XmlNode that is the parent of this node.
   */
  XmlNode parentNode() {
    IXMLDOMNode node;
    if (SUCCEEDED(nodeImpl_.get_parentNode(node)))
      return getNodeShim(node);
    return null;
  }

  /**
   * Gets the XmlDocument to which this node belongs.
   * Returns: The XmlDocument to which this node belongs.
   */
  XmlDocument ownerDocument() {
    IXMLDOMDocument doc;
    if (SUCCEEDED(nodeImpl_.get_ownerDocument(doc)))
      return cast(XmlDocument)getNodeShim(doc);
    return null;
  }

  /**
   * Gets an XmlAttributeCollection containing the _attributes of this node.
   * Returns: An XmlAttributeCollection containing the _attributes of this node.
   */
  XmlAttributeCollection attributes() {
    return null;
  }

  /**
   * Provides support for foreach iteration over the nodes.
   */
  final int opApply(int delegate(ref XmlNode) action) {
    int result = 0;

    IXMLDOMNodeList nodeList;
    if (SUCCEEDED(nodeImpl_.get_childNodes(nodeList))) {
      scope(exit) tryRelease(nodeList);

      int length = 0;
      nodeList.get_length(length);
      for (int i = 0; i < length; i++) {
        IXMLDOMNode node;
        nodeList.nextNode(node);

        XmlNode curNode = getNodeShim(node);
        if (curNode !is null && (result = action(curNode)) != 0)
          break;
      }
    }

    return result;
  }

  package this(IXMLDOMNode nodeImpl) {
    nodeImpl_ = nodeImpl;
  }

  ~this() {
    if (nodeImpl_ !is null) {
      tryRelease(nodeImpl_);
      nodeImpl_ = null;
    }
  }

  package IXMLDOMNode impl() {
    return nodeImpl_;
  }

  private static string constructQName(string prefix, string localName) {
    if (prefix.length == 0)
      return localName;
    return prefix ~ ":" ~ localName;
  }

  private static void splitName(string name, out string prefix, out string localName) {
    int i = name.indexOf(':');
    if (i == -1 || i == 0 || name.length - 1 == i) {
      prefix = "";
      localName = name;
    }
    else {
      prefix = name[0 .. i];
      localName = name[i + 1 .. $];
    }
  }

}

/**
 * Represents an attribute.
 */
class XmlAttribute : XmlNode {

  mixin(TypedNode("IXMLDOMAttribute", "attributeImpl_"));

  override XmlNodeType nodeType() {
    return XmlNodeType.Attribute;
  }

  override string localName() {
    return super.localName;
  }

  override string name() {
    return super.name;
  }

  override string namespaceURI() {
    wchar* bstrNs;
    if (nodeImpl_.get_namespaceURI(bstrNs) == S_OK)
      return fromBstr(bstrNs);
    return string.init;
  }

  override void value(string value) {
    VARIANT v = value;
    attributeImpl_.put_value(v);
    v.clear();
  }

  override string value() {
    VARIANT v;
    attributeImpl_.get_value(v);
    return v.toString();
  }

  override XmlNode parentNode() {
    return null;
  }

  XmlElement ownerElement() {
    return cast(XmlElement)super.parentNode;
  }

  /**
   * Gets a value indicating whether the attribute was explicitly set.
   * Returns: true if the attribute was explicitly set; otherwise, false.
   */
  bool specified() {
    VARIANT_BOOL result;
    nodeImpl_.get_specified(result);
    return result == VARIANT_TRUE;
  }

}

/**
 * Represents a node with child nodes immediately before and after this node.
 */
abstract class XmlLinkedNode : XmlNode {

  override XmlNode previousSibling() {
    IXMLDOMNode node;
    nodeImpl_.get_previousSibling(node);
    return getNodeShim(node);
  }

  override XmlNode nextSibling() {
    IXMLDOMNode node;
    nodeImpl_.get_nextSibling(node);
    return getNodeShim(node);
  }

  package this(IXMLDOMNode nodeImpl) {
    super(nodeImpl);
  }

}

/**
 * Provides text manipulation methods.
 */
abstract class XmlCharacterData : XmlLinkedNode {

  mixin(TypedNode("IXMLDOMCharacterData"));

  /**
   * Appends the specified string to the end of the character data.
   * Params: strData = The string to append to the existing string.
   */
  void appendData(string strData) {
    wchar* bstrValue = toBstr(strData);
    typedNodeImpl_.appendData(bstrValue);
    freeBstr(bstrValue);
  }

  /**
   * Inserts the specified string at the specified offset.
   * Params:
   *   offset = The position within the string to insert the specified string data.
   *   strData = The string data that is to be inserted into the existing string.
   */
  void insertData(int offset, string strData) {
    wchar* bstrValue = toBstr(strData);
    typedNodeImpl_.insertData(offset, bstrValue);
    freeBstr(bstrValue);
  }
  
  /**
   * Replaces the specified number of characters starting at the specified offset with the specified string.
   * Params:
   *   offset = The position within the string to start replacing.
   *   count = The number of characters to replace.
   *   strData = The new data that replaces the old data.
   */
  void replaceData(int offset, int count, string strData) {
    wchar* bstrValue = toBstr(strData);
    typedNodeImpl_.replaceData(offset, count, bstrValue);
    freeBstr(bstrValue);
  }

  /**
   * Removes a range of characters from the string data.
   * Params:
   *   offset = The position within the string to start deleting.
   *   count = The number of characters to delete.
   */
  void deleteData(int offset, int count) {
    typedNodeImpl_.deleteData(offset, count);
  }

  /**
   * Retrieves a _substring of the full string from the specified range.
   * Params:
   *   offset = The position within the string to start retrieving.
   *   count = The number of characters to retrieve.
   */
  string substring(int offset, int count) {
    wchar* bstrValue;
    if (typedNodeImpl_.substringData(offset, count, bstrValue) == S_OK)
      return fromBstr(bstrValue);
    return "";
  }

  /**
   * Gets the _length of the data.
   * Returns: The _length of the string data.
   */
  int length() {
    int result;
    typedNodeImpl_.get_length(result);
    return result;
  }

  /**
   * Gets or sets the _data of the node.
   * Returns: The _data of the node.
   */
  void data(string value) {
    wchar* bstrValue = toBstr(value);
    typedNodeImpl_.put_data(bstrValue);
    freeBstr(bstrValue);
  }

  /**
   * ditto
   */
  string data() {
    wchar* bstrValue;
    if (typedNodeImpl_.get_data(bstrValue) == S_OK)
      return fromBstr(bstrValue);
    return "";
  }

  override void value(string value) {
    data = value;
  }

  override string value() {
    return data;
  }

}

/**
 * Represents a CDATA section.
 */
class XmlCDataSection : XmlCharacterData {

  override XmlNodeType nodeType() {
    return XmlNodeType.CDATA;
  }

  override string localName() {
    return "#cdata-section";
  }

  override string name() {
    return localName;
  }

  package this(IXMLDOMNode nodeImpl) {
    super(nodeImpl);
  }

}

/**
 * Represents the content of an XML comment.
 */
class XmlComment : XmlCharacterData {

  override XmlNodeType nodeType() {
    return XmlNodeType.Comment;
  }

  override string localName() {
    return "#comment";
  }

  override string name() {
    return localName;
  }

  package this(IXMLDOMNode nodeImpl) {
    super(nodeImpl);
  }

}

/**
 * Represents the text content of an element or attribute.
 */
class XmlText : XmlCharacterData {

  mixin(TypedNode("IXMLDOMText"));

  override XmlNodeType nodeType() {
    return XmlNodeType.Text;
  }

  override string localName() {
    return super.localName;
  }

  override string name() {
    return super.name;
  }

  /**
   * Splits the node into two nodes at the specified _offset, keeping both in the tree as siblings.
   * Params: offset = The position at which to split the node.
   * Returns: The new node.
   */
  XmlText splitText(int offset) {
    IXMLDOMText node;
    if (typedNodeImpl_.splitText(offset, node) == S_OK)
      return cast(XmlText)getNodeShim(node);
    return null;
  }

}

/**
 * Represents an entity declaration, such as &lt;!ENTITY...&gt;.
 */
class XmlEntity : XmlNode {

  mixin(TypedNode("IXMLDOMEntity"));

  override XmlNodeType nodeType() {
    return XmlNodeType.Entity;
  }

  override string name() {
    return super.name;
  }

  override string localName() {
    return super.localName;
  }

  override void text(string value) {
    throw new InvalidOperationException;
  }

  override string text() {
    return super.text;
  }

  override void xml(string value) {
    throw new InvalidOperationException;
  }

  override string xml() {
    return "";
  }

  /**
   * Gets the value of the identifier on the entity declaration.
   * Returns: The identifier on the entity.
   */
  final string publicId() {
    VARIANT var;
    if (typedNodeImpl_.get_publicId(var) == S_OK) {
      scope(exit) var.clear();
      return var.toString();
    }
    return null;
  }

  /**
   * Gets the value of the system identifier on the entity declaration.
   * Returns: The system identifier on the entity.
   */
  final string systemId() {
    VARIANT var;
    if (typedNodeImpl_.get_systemId(var) == S_OK) {
      scope(exit) var.clear();
      return var.toString();
    }
    return null;
  }

  /**
   * Gets the name of the NDATA attribute on the entity declaration.
   * Returns: The name of the NDATA attribute.
   */
  final string notationName() {
    wchar* bstrName;
    if (typedNodeImpl_.get_notationName(bstrName) == S_OK)
      return fromBstr(bstrName);
    return null;
  }

}

/**
 * Represents an entity reference node.
 */
class XmlEntityReference : XmlLinkedNode {

  mixin(TypedNode("IXMLDOMEntityReference"));

  override XmlNodeType nodeType() {
    return XmlNodeType.EntityReference;
  }

  override string name() {
    return super.name;
  }

  override string localName() {
    return super.localName;
  }

  override void value(string value) {
    throw new InvalidOperationException;
  }

  override string value() {
    return "";
  }

}

/**
 * Represents a notation declaration such as &lt;!NOTATION...&gt;.
 */
class XmlNotation : XmlNode {

  mixin(TypedNode("IXMLDOMNotation"));

  override XmlNodeType nodeType() {
    return XmlNodeType.Notation;
  }

  override string name() {
    return super.name;
  }

  override string localName() {
    return super.localName;
  }

}

/**
 * Represents the document type declaration.
 */
class XmlDocumentType : XmlLinkedNode {

  mixin(TypedNode("IXMLDOMDocumentType"));

  override XmlNodeType nodeType() {
    return XmlNodeType.DocumentType;
  }

  override string name() {
    wchar* bstrName;
    typedNodeImpl_.get_name(bstrName);
    return fromBstr(bstrName);
  }

  override string localName() {
    return name;
  }

  /**
   * Gets the collection of XmlEntity nodes declared in the document type declaration.
   * Returns: An XmlNamedNodeMap containing the XmlEntity nodes.
   */
  final XmlNamedNodeMap entities() {
    IXMLDOMNamedNodeMap map;
    if (typedNodeImpl_.get_entities(map) == S_OK)
      return new XmlNamedNodeMap(map);
    return null;
  }

  /**
   * Gets the collection of XmlNotation nodes present in the document type declaration.
   * Returns: An XmlNamedNodeMap containing the XmlNotation nodes.
   */
  final XmlNamedNodeMap notations() {
    IXMLDOMNamedNodeMap map;
    if (typedNodeImpl_.get_notations(map) == S_OK)
      return new XmlNamedNodeMap(map);
    return null;
  }

}

/**
 * Represents a lightweight object useful for tree insert operations.
 */
class XmlDocumentFragment : XmlNode {

  mixin(TypedNode("IXMLDOMDocumentFragment"));

  override XmlNodeType nodeType() {
    return XmlNodeType.DocumentFragment;
  }

  override string name() {
    version(D_Version2) {
      return "#document-fragment".idup;
    }
    else {
      return "#document-fragment".dup;
    }
  }

  override string localName() {
    return name;
  }

  override XmlNode parentNode() {
    return null;
  }

  override XmlDocument ownerDocument() {
    return cast(XmlDocument)super.parentNode;
  }

}

/** 
 * Represents an element.
 */
class XmlElement : XmlLinkedNode {

  mixin(TypedNode("IXMLDOMElement", "elementImpl_"));

  /**
   * Returns the value for the attribute with the specified _name.
   * Params: name = The qualified _name of the attribute to retrieve.
   * Returns: The value of the specified attribute.
   */
  string getAttribute(string name) {
    wchar* bstrName = toBstr(name);
    scope(exit) freeBstr(bstrName);

    VARIANT value;
    elementImpl_.getAttribute(bstrName, value);
    return value.toString();
  }

  /**
   * Returns the value for the attribute with the specified local name and namespace URI.
   * Params: 
   *   localName = The local name of the attribute to retrieve.
   *   namespaceURI = The namespace URI of the attribute to retrieve.
   * Returns: The value of the specified attribute.
   */
  string getAttribute(string localName, string namespaceURI) {
    if (XmlAttribute attr = getAttributeNode(localName, namespaceURI))
      return attr.value;
    return null;
  }

  /**
   * Returns the attribute with the specified _name.
   * Params: name = The qualified _name of the attribute to retrieve.
   * Returns: The matching XmlAttribute.
   */
  XmlAttribute getAttributeNode(string name) {
    if (hasAttributes)
      return attributes[name];
    return null;
  }

  /**
   * Returns the attribute with the specified local name and namespace URI.
   * Params: 
   *   localName = The local name of the attribute to retrieve.
   *   namespaceURI = The namespace URI of the attribute to retrieve.
   * Returns: The matching XmlAttribute.
   */
  XmlAttribute getAttributeNode(string localName, string namespaceURI) {
    if (hasAttributes)
      return attributes[localName, namespaceURI];
    return null;
  }

  /**
   * Determines whether the node has an attribute with the specified _name.
   * Params: name = The qualified _name of the attribute to find.
   * Returns: true if the node has the specified attribute; otherwise, false.
   */
  bool hasAttribute(string name) {
    return getAttributeNode(name) !is null;
  }

  /**
   * Determines whether the node has an attribute with the specified local name and namespace URI.
   * Params: 
   *   localName = The local name of the attribute to find.
   *   namespaceURI = The namespace URI of the attribute to find.
   * Returns: true if the node has the specified attribute; otherwise, false.
   */
  bool hasAttribute(string localName, string namespaceURI) {
    return getAttributeNode(localName, namespaceURI) !is null;
  }

  /**
   * Sets the _value of the attribute with the specified _name.
   * Params:
   *   name = The qualified _name of the attribute to create or alter.
   *   value = The _value to set for the attribute.
   */
  void setAttribute(string name, string value) {
    wchar* bstrName = toBstr(name);
    scope(exit) freeBstr(bstrName);

    VARIANT v = value;
    elementImpl_.setAttribute(bstrName, v);
    v.clear();
  }

  /**
   * Adds the specified attribute.
   * Params: newAttr = The attribute to add to the attribute collection for this element.
   * Returns: If the attribute replaces an existing attribute with the same name, the old attribute is returned; otherwise, null is returned.
   */
  XmlAttribute setAttributeNode(XmlAttribute newAttr) {
    IXMLDOMAttribute attr;
    if (SUCCEEDED(elementImpl_.setAttributeNode(newAttr.attributeImpl_, attr)))
      return cast(XmlAttribute)getNodeShim(attr);
    return null;
  }

  /**
   * Removes an attribute by _name.
   * Params: name = The qualified _name of the attribute to remove.
   */
  void removeAttribute(string name) {
    if (hasAttributes)
      attributes.removeNamedItem(name);
  }

  /**
   * Removes an attribute with the specified local name and namespace URI.
   * Params: 
   *   localName = The local name of the attribute to remove.
   *   namespaceURI = The namespace URI of the attribute to remove.
   */
  void removeAttribute(string localName, string namespaceURI) {
    if (hasAttributes)
      attributes.removeNamedItem(localName, namespaceURI);
  }

  /**
   * Removes the specified attribute.
   * Params: oldAttr = The attribute to remove.
   * Returns: The removed attribute or null if oldAttr is not an attribute of the element.
   */
  XmlAttribute removeAttributeNode(XmlAttribute oldAttr) {
    IXMLDOMAttribute attr;
    if (SUCCEEDED((elementImpl_.removeAttributeNode(oldAttr.attributeImpl_, attr))))
      return cast(XmlAttribute)getNodeShim(attr);
    return null;
  }

  /**
   * Removes the attribute specified by the local name and namespace URI.
   * Params: 
   *   localName = The local name of the attribute.
   *   namespaceURI = The namespace URI of the attribute.
   * Returns: The removed attribute.
   */
  XmlAttribute removeAttributeNode(string localName, string namespaceURI) {
    if (hasAttributes) {
      if (XmlAttribute attr = getAttributeNode(localName, namespaceURI)) {
        removeAttributeNode(attr);
        return attr;
      }
    }
    return null;
  }

  /**
   * Collapses all adjacent XmlText nodes in the sub-tree.
   */
  void normalize() {
    elementImpl_.normalize();
  }

  /**
   * Returns an XmlNodeList containing the descendant elements with the specified _name.
   * Params: name = The qualified _name tag to match.
   * Returns: An XmlNodeList containing a list of matching nodes.
   */
  XmlNodeList getElementsByTagName(string name) {
    wchar* bstrName = toBstr(name);
    if (bstrName != null) {
      scope (exit) freeBstr(bstrName);
      IXMLDOMNodeList nodeList;
      if (SUCCEEDED(elementImpl_.getElementsByTagName(bstrName, nodeList)))
        return new XmlChildNodes(nodeList);
    }
    return null;
  }

  override XmlAttributeCollection attributes() {
    return new XmlAttributeCollection(this);
  }

  /**
   * Gets a value indicating whether the node has any attributes.
   * Returns: true if the node has attributes; otherwise, false.
   */
  bool hasAttributes() {
    IXMLDOMNamedNodeMap attrs;
    if (SUCCEEDED(nodeImpl_.get_attributes(attrs))) {
      scope (exit) tryRelease(attrs);

      int length;
      if (SUCCEEDED(attrs.get_length(length)))
        return length > 0;
      return false;
    }
    return false;
  }

  override XmlNodeType nodeType() {
    return XmlNodeType.Element;
  }

  override string localName() {
    return super.localName;
  }

  override string name() {
    return super.name;
  }

  override string namespaceURI() {
    wchar* bstrNs;
    if (SUCCEEDED(nodeImpl_.get_namespaceURI(bstrNs)))
      return fromBstr(bstrNs);
    return string.init;
  }

}

/**
 * Represents a processing instruction.
 */
class XmlProcessingInstruction : XmlLinkedNode {

  mixin(TypedNode("IXMLDOMProcessingInstruction"));

  override XmlNodeType nodeType() {
    return XmlNodeType.ProcessingInstruction;
  }

  override string name() {
    return super.name;
  }

  override string localName() {
    return super.localName;
  }

}

/**
 * Represents the XML declaration node.
 */
class XmlDeclaration : XmlLinkedNode {

  private const string VERSION = "1.0";

  mixin(TypedNode("IXMLDOMProcessingInstruction"));
  private string encoding_;
  private string standalone_;

  override XmlNodeType nodeType() {
    return XmlNodeType.XmlDeclaration;
  }

  override string name() {
    return localName;
  }

  override string localName() {
    return "xml";
  }

  final override void value(string value) {
    text = value;
  }

  override string value() {
    return text;
  }

  /**
   * Gets or sets the _encoding level of the XML document.
   * Returns: The character _encoding name.
   */
  final void encoding(string value) {
    encoding_ = value;
  }

  /**
   * ditto
   */
  final string encoding() {
    return encoding_;
  }

  /**
   * Gets or sets the _value of the _standalone attribute.
   * Returns: Valid values are "yes" if all entity declarations are contained within the document or "no" if an external DTD is required.
   */
  final void standalone(string value) {
    if (value == null || value == "yes" || value == "no")
      standalone_ = value;
  }

  /**
   * ditto
   */
  final string standalone() {
    return standalone_;
  }

  /**
   * Gets the XML version of the document.
   */
  final string xmlversion() {
    return VERSION;
  }

  package this(string xmlversion, string encoding, string standalone, IXMLDOMNode nodeImpl) {
    if (xmlversion != VERSION)
      throw new ArgumentException("Only XML version 1.0 is supported.");

    this(nodeImpl);
    this.encoding = encoding;
    this.standalone = standalone;
  }

}

/**
 * Provides methods that are independent of a particular instance of the Document Object Model.
 */
class XmlImplementation {

  private IXMLDOMImplementation impl_;

  /**
   * Tests if the specified feature is supported.
   * Params: 
   *   strFeature = The package name of the feature to test.
   *   strVersion = The version number of the package name to test.
   * Returns: true if the feature is implemented in the specified version; otherwise, false.
   */
  final bool hasFeature(string strFeature, string strVersion) {
    VARIANT_BOOL result;

    wchar* bstrFeature = toBstr(strFeature);
    wchar* bstrVersion = toBstr(strVersion);
    impl_.hasFeature(bstrFeature, bstrVersion, result);
    freeBstr(bstrFeature);
    freeBstr(bstrVersion);

    return result == VARIANT_TRUE;
  }

  private this(IXMLDOMImplementation impl) {
    impl_ = impl;
  }

  ~this() {
    if (impl_ !is null) {
      tryRelease(impl_);
      impl_ = null;
    }
  }

}

/**
 * Represents an XML document.
 */
class XmlDocument : XmlNode {

  mixin(TypedNode("IXMLDOMDocument2", "docImpl_"));
  private short msxmlVersion_;

  /**
   * Initializes a new instance.
   */
  this() {
    // MSXML 6.0 is the preferred implementation. According to MSDN, MSXML 4.0 is only suitable for legacy code, but we'll use if 
    // it's available on the system. MSXML 5.0 was part of Office 2003.
    IXMLDOMDocument2 doc;
    if ((doc = DOMDocument60.coCreate!(IXMLDOMDocument3)) !is null)
      msxmlVersion_ = 6;
    else if ((doc = DOMDocument40.coCreate!(IXMLDOMDocument2)) !is null)
      msxmlVersion_ = 4;
    else if ((doc = DOMDocument30.coCreate!(IXMLDOMDocument2, ExceptionPolicy.Throw)) !is null)
      msxmlVersion_ = 3;

    if (msxmlVersion_ >= 4)
    {
      wchar* bstrNewParser = toBstr("NewParser");
      doc.setProperty(bstrNewParser, VARIANT(true)); // Faster and more reliable; lacks async support and DTD validation (we don't support either, so that's OK).
      freeBstr(bstrNewParser);
    }
    if (msxmlVersion_ >= 6)
    {
      wchar* bstrMultipleError = toBstr("MultipleErrorMessages");
      doc.setProperty(bstrMultipleError, VARIANT(true));
      freeBstr(bstrMultipleError);
    }
    if (msxmlVersion_ < 4) {
      VARIANT var = "XPath";
      scope(exit) var.clear();
      wchar* bstrSelectionLanguage = toBstr("SelectionLanguage");
      doc.setProperty(bstrSelectionLanguage, var); // In MSXML 3.0, "SelectionLanguage" was "XPattern".
      freeBstr(bstrSelectionLanguage);
    }

    doc.put_async(VARIANT_FALSE);
    doc.put_validateOnParse(VARIANT_FALSE);

    this(doc);
  }

  /**
   * Creates an XPathNavigator for navigating this instance.
   */
  override XPathNavigator createNavigator() {
    return createNavigator(this);
  }

  /**
   * Creates an XmlNode with the specified _type, _name and _namespaceURI.
   * Params:
   *   type = The _type of the new node.
   *   name = The qualified _name of the new node.
   *   namespaceURI = The namespace URI of the new node.
   * Returns: The new XmlNode.
   */
  XmlNode createNode(XmlNodeType type, string name, string namespaceURI) {
    return createNode(type, null, name, namespaceURI);
  }

  /**
   * Creates an XmlNode with the specified _type, _prefix, _name and _namespaceURI.
   * Params:
   *   type = The _type of the new node.
   *   prefix = The _prefix of the new node.
   *   name = The local _name of the new node.
   *   namespaceURI = The namespace URI of the new node.
   * Returns: The new XmlNode.
   */
  XmlNode createNode(XmlNodeType type, string prefix, string name, string namespaceURI) {
    switch (type) {
      case XmlNodeType.EntityReference:
        return createEntityReference(name);
      case XmlNodeType.Element:
        if (prefix == null)
          return createElement(name, namespaceURI);
        return createElement(prefix, name, namespaceURI);
      case XmlNodeType.Attribute:
        if (prefix == null)
          return createAttribute(name, namespaceURI);
        return createAttribute(prefix, name, namespaceURI);
      case XmlNodeType.CDATA:
        return createCDataSection("");
      case XmlNodeType.Comment:
        return createComment("");
      case XmlNodeType.Text:
        return createTextNode("");
      case XmlNodeType.ProcessingInstruction:
        return createProcessingInstruction(name, "");
      case XmlNodeType.XmlDeclaration:
        return createXmlDeclaration("1.0", null, null);
      case XmlNodeType.DocumentFragment:
        return createDocumentFragment();
      case XmlNodeType.Document:
        return new XmlDocument;
      default:
    }
    throw new ArgumentException("Cannot create node of type '" ~ XmlNodeTypeString[type] ~ "'.");
  }

  /**
   * Creates an XmlElement with the specified _name.
   * Params: name = The qualified _name of the element.
   * Returns: The new XmlElement.
   */
  XmlElement createElement(string name) {
    string prefix, localName;
    XmlNode.splitName(name, prefix, localName);
    return createElement(prefix, localName, "");
  }

  /**
   * Creates an XmlElement with the specified name and _namespaceURI.
   * Params:
   *   qualifiedName = The qualified name of the element.
   *   namespaceURI = The namespace URI of the element.
   * Returns: The new XmlElement.
   */
  XmlElement createElement(string qualifiedName, string namespaceURI) {
    IXMLDOMNode node;

    wchar* bstrName = toBstr(qualifiedName);
    wchar* bstrNs = toBstr(namespaceURI);
    docImpl_.createNode(VARIANT(DOMNodeType.NODE_ELEMENT), bstrName, bstrNs, node);
    freeBstr(bstrName);
    freeBstr(bstrNs);

    return cast(XmlElement)getNodeShim(node);
  }

  /**
   * Creates an XmlElement with the specified _prefix, localName and _namespaceURI.
   * Params:
   *   prefix = The _prefix of the element.
   *   localName = The local name of the element.
   *   namespaceURI = The namespace URI of the element.
   * Returns: The new XmlElement.
   */
  XmlElement createElement(string prefix, string localName, string namespaceURI) {
    return createElement(XmlNode.constructQName(prefix, localName), namespaceURI);
  }

  /**
   * Creates an XmlAttribute with the specified _name.
   * Params: name = The qualified _name of the attribute.
   * Returns: The new XmlAttribute.
   */
  XmlAttribute createAttribute(string name) {
    string prefix, localName;
    XmlNode.splitName(name, prefix, localName);
    return createAttribute(prefix, localName, "");
  }

  /**
   * Creates an XmlAttribute with the specified name and _namespaceURI.
   * Params:
   *   qualifiedName = The qualified name of the attribute.
   *   namespaceURI = The namespace URI of the attribute.
   * Returns: The new XmlAttribute.
   */
  XmlAttribute createAttribute(string qualifiedName, string namespaceURI) {
    IXMLDOMNode node;

    wchar* bstrName = toBstr(qualifiedName);
    wchar* bstrNs = toBstr(namespaceURI);
    docImpl_.createNode(VARIANT(DOMNodeType.NODE_ATTRIBUTE), bstrName, bstrNs, node);
    freeBstr(bstrName);
    freeBstr(bstrNs);

    return cast(XmlAttribute)getNodeShim(node);
  }

  /**
   * Creates an XmlAttribute with the specified _prefix, localName and _namespaceURI.
   * Params:
   *   prefix = The _prefix of the attribute.
   *   localName = The local name of the attribute.
   *   namespaceURI = The namespace URI of the attribute.
   * Returns: The new XmlAttribute.
   */
  XmlAttribute createAttribute(string prefix, string localName, string namespaceURI) {
    return createAttribute(XmlNode.constructQName(prefix, localName), namespaceURI);
  }

  /**
   * Creates an XmlCDataSection node with the specified _data.
   * Params: text = The _data for the node.
   * Returns: The new XmlCDataSection node.
   */
  XmlCDataSection createCDataSection(string data) {
    IXMLDOMCDATASection node;

    wchar* bstrValue = toBstr(data);
    docImpl_.createCDATASection(bstrValue, node);
    freeBstr(bstrValue);

    return cast(XmlCDataSection)getNodeShim(node);
  }

  /**
   * Creates an XmlComment node with the specified _data.
   * Params: text = The _data for the node.
   * Returns: The new XmlComment node.
   */
  XmlComment createComment(string data) {
    IXMLDOMComment node;

    wchar* bstrValue = toBstr(data);
    docImpl_.createComment(bstrValue, node);
    freeBstr(bstrValue);

    return cast(XmlComment)getNodeShim(node);
  }

  /**
   * Creates an XmlText node with the specified _text.
   * Params: text = The _text for the node.
   * Returns: The new XmlText node.
   */
  XmlText createTextNode(string text) {
    IXMLDOMText node = null;

    wchar* bstrValue = toBstr(text);
    docImpl_.createTextNode(bstrValue, node);
    freeBstr(bstrValue);

    return cast(XmlText)getNodeShim(node);
  }

  /**
   * Creates an XmlProcessingInstruction node with the specified name and _data.
   * Params:
   *   target = the name of the processing instruction.
   *   data = The _data for the processing instruction.
   * Returns: The new XmlProcessingInstruction node.
   */
  XmlProcessingInstruction createProcessingInstruction(string target, string data) {
    IXMLDOMProcessingInstruction node;

    wchar* bstrTarget = toBstr(target);
    wchar* bstrData = toBstr(data);
    docImpl_.createProcessingInstruction(bstrTarget, bstrData, node);
    freeBstr(bstrTarget);
    freeBstr(bstrData);

    return cast(XmlProcessingInstruction)getNodeShim(node);
  }

  /**
   * Create an XmlDeclaration node with the specified values.
   * Params:
   *   xmlversion = The version must be "1.0".
   *   encoding = The value of the _encoding attribute.
   *   standalone = The value must be either "yes" or "no".
   * Returns: The new XmlDeclaration node.
   */
  XmlDeclaration createXmlDeclaration(string xmlversion, string encoding, string standalone) {
    string data = "version=\"" ~ xmlversion ~ "\"";
    if (encoding != null)
      data ~= " encoding=\"" ~ encoding ~ "\"";
    if (standalone != null)
      data ~= " standalone=\"" ~ standalone ~ "\"";

    IXMLDOMProcessingInstruction node;

    wchar* bstrTarget = toBstr("xml");
    wchar* bstrData = toBstr(data);
    docImpl_.createProcessingInstruction(bstrTarget, bstrData, node);
    freeBstr(bstrTarget);
    freeBstr(bstrData);

    return cast(XmlDeclaration)getNodeShim(node);
  }

  /**
   * Creates an XmlEntityReference with the specified _name.
   * Params: The _name of the entity reference.
   * Returns: The new XmlEntityReference.
   */
  XmlEntityReference createEntityReference(string name) {
    IXMLDOMEntityReference node;

    wchar* bstrName = toBstr(name);
    docImpl_.createEntityReference(bstrName, node);
    freeBstr(bstrName);

    return cast(XmlEntityReference)getNodeShim(node);
  }

  /**
   * Creates an XmlDocumentFragment.
   * Returns: The new XmlDocumentFragment.
   */
  XmlDocumentFragment createDocumentFragment() {
    IXMLDOMDocumentFragment node;
    docImpl_.createDocumentFragment(node);
    return cast(XmlDocumentFragment)getNodeShim(node);
  }

  /**
   * Loads the XML document from the specified URL.
   * Params: fileName = URL for the file containing the XML document to _load. The URL can be either a local file or a web address.
   * Throws: XmlException if there is a _load or parse error in the XML.
   */
  void load(string fileName) {
    VARIANT source = fileName;
    scope(exit) source.clear();

    VARIANT_BOOL success;
    docImpl_.load(source, success);
    if (success == VARIANT_FALSE)
      parsingException();
  }

  /**
   * Loads the XML document from the specified stream.
   * Params: input = The stream containing the XML document to _load.
   * Throws: XmlException if there is a _load or parse error in the XML.
   */
  void load(Stream input) {
    auto s = new COMStream(input);
    scope(exit) tryRelease(s);

    VARIANT source = s;
    scope(exit) source.clear();

    VARIANT_BOOL success;
    docImpl_.load(source, success);
    if (success == VARIANT_FALSE)
      parsingException();
  }

  /**
   * Loads the XML document from the specified string.
   * Params: xml = The string containing the XML document to load.
   * Throws: XmlException if there is a _load or parse error in the XML.
   */
  void loadXml(string xml) {
    VARIANT_BOOL success;

    wchar* bstrXml = toBstr(xml);
    docImpl_.loadXML(bstrXml, success);
    freeBstr(bstrXml);

    if (success == VARIANT_FALSE)
      parsingException();
  }

  /**
   * Saves the XML document to the specified file.
   * Params: fileName = The location of the file where you want to _save the document.
   * Throws: XmlException if there is no document element.
   */
  void save(string fileName) {
    if (documentElement is null)
      throw new XmlException("Invalid XML document. The document does not have a root element.");

    VARIANT dest = fileName;
    scope(exit) dest.clear();

    if (FAILED(docImpl_.save(dest)))
      throw new XmlException;
  }

  /**
   * Saves the XML document to the specified stream.
   * Params: output = The stream to which you want to _save.
   */
  void save(Stream output) {
    auto s = new COMStream(output);
    scope(exit) tryRelease(s);

    VARIANT dest = s;
    scope(exit) tryRelease(s);

    if (FAILED(docImpl_.save(dest)))
      throw new XmlException;
  }

  /**
   * Gets the XmlElement with the specified ID.
   * Params: elementId = The attribute ID to match.
   * Returns: The XmlElement with the matching ID.
   */
  XmlElement getElementByTagId(string elementId) {
    IXMLDOMNode node;

    wchar* bstrId = toBstr(elementId);
    docImpl_.nodeFromID(bstrId, node);
    freeBstr(bstrId);

    return cast(XmlElement)getNodeShim(node);
  }

  /** 
   * Gets the root element for the document.
   * Returns: The XmlElement representing the root of the XML document tree. If no root exists, null is returned.
   */
  XmlElement documentElement() {
    IXMLDOMElement docEl;
    docImpl_.get_documentElement(docEl);
    return cast(XmlElement)getNodeShim(docEl);
  }

  /**
   * Gets the type of the current node.
   * Returns: For XmlDocument nodes, the value is XmlNodeType.Document.
   */
  override XmlNodeType nodeType() {
    return XmlNodeType.Document;
  }

  /**
   * Gets the locale name of the node.
   * Returns: For XmlDocument nodes, the local name is #document.
   */
  override string localName() {
    version(D_Version2) {
      return "#document".idup;
    }
    else {
      return "#document".dup;
    }
  }

  /**
   * Gets the qualified _name of the node.
   * Returns: For XmlDocument nodes, the _name is #document.
   */
  override string name() {
    return localName;
  }

  /**
   * Gets the parent node.
   * Returns: For XmlDocument nodes, null is returned.
   */
  override XmlNode parentNode() {
    return null;
  }

  /**
   * Gets the XmlDocument to which the current node belongs.
   * Returns: For XmlDocument nodes, null is returned.
   */
  override XmlDocument ownerDocument() {
    return null;
  }

  /**
   * Gets or sets the markup representing the children of this node.
   * Returns: The markup of the children of this node.
   */
  override void xml(string value) {
    loadXml(value);
  }

  /**
   * ditto
   */
  override string xml() {
    return super.xml;
  }

  /**
   * Gets or sets a _value indicating whether to preserve white space in element content.
   * Params: value = true to preserve white space; otherwise, false.
   */
  final void preserveWhitespace(bool value) {
    docImpl_.put_preserveWhiteSpace(value ? VARIANT_TRUE : VARIANT_FALSE);
  }

  /**
   * ditto
   */
  final bool preserveWhitespace() {
    VARIANT_BOOL value;
    docImpl_.get_preserveWhiteSpace(value);
    return value == VARIANT_TRUE;
  }

  protected XPathNavigator createNavigator(XmlNode node) {
    switch (node.nodeType) {
      case XmlNodeType.EntityReference,
        XmlNodeType.Entity,
        XmlNodeType.DocumentType,
        XmlNodeType.Notation,
        XmlNodeType.XmlDeclaration:
        return null;
        default:
    }
    return new DocumentXPathNavigator(this, node);
  }

  private void parsingException() {
    IXMLDOMParseError errorObj;
    if (SUCCEEDED(docImpl_.get_parseError(errorObj))) {
      scope(exit) tryRelease(errorObj);

      wchar* bstrReason, bstrUrl;
      int lineNumber, linePosition;

      errorObj.get_reason(bstrReason);
      errorObj.get_url(bstrUrl);
      errorObj.get_line(lineNumber);
      errorObj.get_linepos(linePosition);

      string reason = fromBstr(bstrReason);
      if (reason[$ - 1] == '\n')
        reason = reason[0 .. $ - 2];

      throw new XmlException(reason, lineNumber, linePosition, fromBstr(bstrUrl));
    }
  }

}

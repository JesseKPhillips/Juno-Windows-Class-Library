 /*
 * Copyright (c) 2007 John Chapman
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

/**
 * Provides standards-based support for processing XML.
 */
module juno.xml.dom;

private import juno.base.core,
  juno.base.string,
  juno.com.core,
  juno.xml.constants,
  juno.xml.core,
  juno.xml.msxml;

/**
 * Adds namespaces to a collection and provides scope management.
 */
public class XmlNamespaceManager {

  private IMXNamespaceManager nsmgrImpl_;

  public this() {
    if ((nsmgrImpl_ = MXNamespaceManager60.coCreate!(IMXNamespaceManager)) is null) {
      if ((nsmgrImpl_ = MXNamespaceManager40.coCreate!(IMXNamespaceManager)) is null) {
        nsmgrImpl_ = MXNamespaceManager.coCreate!(IMXNamespaceManager, ExceptionPolicy.ThrowIfNull);
      }
    }
  }

  /**
   * Adds the given namespace to the collection.
   * Params:
   *   prefix = The _prefix to associate with the namespace being added.
   *   uri = The namespace to add.
   */
  public void addNamespace(string prefix, string uri) {
    nsmgrImpl_.declarePrefix(prefix.toUtf16z(), uri.toUtf16z());
  }

  /**
   * Retrieves a value indicating whether the supplied _prefix has a namespace for the current scope.
   * Params: prefix = The _prefix of the namespace to find.
   * Returns: true if a namespace is defined; otherwise, false.
   */
  public bool hasNamespace(string prefix) {
    int cchUri;
    return (nsmgrImpl_.getURI(prefix.toUtf16z(), null, null, cchUri) == S_OK);
  }

  /**
   * Finds the prefix with the given namespace.
   * Params: uri = The namespace to resolve for the prefix.
   * Returns: The matching prefix.
   */
  public string lookupPrefix(string uri) {
    wchar[100] pwchPrefix;
    int cchPrefix = pwchPrefix.length;
    if (nsmgrImpl_.getPrefix(uri.toUtf16z(), 0, pwchPrefix.ptr, cchPrefix) == S_OK)
      return toUtf8(pwchPrefix.ptr, 0, cchPrefix);
    return null;
  }

  /**
   * Finds the namespace for the specified _prefix.
   * Params: prefix = The _prefix whose namespace you want to resolve.
   * Returns: The namespace for prefix.
   */
  public string lookupNamespace(string prefix) {
    wchar[100] pwchUri;
    int cchUri = pwchUri.length;
    if (nsmgrImpl_.getURI(prefix.toUtf16z(), null, pwchUri.ptr, cchUri) == S_OK)
      return toUtf8(pwchUri.ptr, 0, cchUri);
    return null;
  }

  /**
   * Pops a namespace scope off the stack.
   * Returns: true if there are namespace scopes left on the stack; otherwise, false.
   */
  public bool popScope() {
    return (nsmgrImpl_.popContext() == S_OK);
  }

  /**
   * Pushes a namespace scope onto the stack.
   */
  public void pushScope() {
    nsmgrImpl_.pushContext();
  }

  /**
   * Provides foreach-style iteratation through the prefixes stored.
   */
  public int opApply(int delegate(ref string) action) {
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
      nsmgrImpl_.Release();
      nsmgrImpl_ = null;
    }
  }

}

package XmlNode getNodeShim(IXMLDOMNode node) {

  bool isXmlDeclaration(IXMLDOMNode node) {
    wchar* bstr;
    if (node.get_nodeName(bstr) == S_OK)
      return (fromBStr(bstr) == "xml");
    return false; 
  }

  bool parseXmlDeclaration(IXMLDOMNode node, out string xmlversion, out string encoding, out string standalone) {

    string getAttrValue(IXMLDOMNamedNodeMap attrs, string name) {
      string value;
      IXMLDOMNode namedItem;

      wchar* bstr = name.toBStr();
      if (attrs.getNamedItem(bstr, namedItem) == S_OK) {
        scope(exit) namedItem.Release();
        VARIANT var;
        if (namedItem.get_nodeValue(var) == S_OK)
          value = var.toString();
      }
      freeBStr(bstr);
      return value;
    }

    xmlversion = null, encoding = null, standalone = null;
    IXMLDOMNamedNodeMap attrs;
    if (node.get_attributes(attrs) == S_OK) {
      scope(exit) attrs.Release();

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

public string[XmlNodeType.max + 1] XmlNodeTypeString = [
  XmlNodeType.None : "None",
  XmlNodeType.Element : "Element",
  XmlNodeType.Attribute : "Attribute",
  XmlNodeType.Text : "Text",
  XmlNodeType.CDATA : "CDATA",
  XmlNodeType.EntityReference : "EntityReference",
  XmlNodeType.Entity : "Entity",
  XmlNodeType.ProcessingInstruction : "ProcessingInstruction",
  XmlNodeType.Comment : "Comment",
  XmlNodeType.Document : "Document",
  XmlNodeType.DocumentType : "DocumentType",
  XmlNodeType.DocumentFragment : "DocumentFragment",
  XmlNodeType.Notation : "Notation",
  XmlNodeType.Whitespace : "Whitespace",
  XmlNodeType.XmlDeclaration : "XmlDeclaration"
];

/**
 * Represents an ordered collection of nodes.
 */
public abstract class XmlNodeList {

  /**
   * Retrieves the node at the given _index.
   * Params: index = The _index into the list of nodes.
   * Returns: The node in the collection at index.
   */
  public abstract XmlNode item(int index);

  /**
   * Ditto
   */
  public XmlNode opIndex(int index) {
    return item(index);
  }

  /**
   * Provides foreach iteration over the collection of nodes.
   */
  public abstract int opApply(int delegate(ref XmlNode) action);

  /**
   * Gets the number of nodes in the collection.
   * Returns: The number of nodes.
   */
  public abstract int count();

  protected this() {
  }

}

private class XmlNodes : XmlNodeList {

  private IXMLDOMNodeList listImpl_;

  package this(IXMLDOMNodeList listImpl) {
    listImpl_ = listImpl;
  }

  ~this() {
    if (listImpl_ !is null) {
      listImpl_.Release();
      listImpl_ = null;
    }
  }

  public override XmlNode item(int index) {
    IXMLDOMNode node;
    if (listImpl_.get_item(index, node) == S_OK)
      return getNodeShim(node);
    return null;
  }

  public override int opApply(int delegate(ref XmlNode) action) {
    int result;
    IXMLDOMNode node;
    do {
      if (listImpl_.nextNode(node) == S_OK) {
        XmlNode n = getNodeShim(node);
        if ((result = action(n)) != 0)
          break;
      }
    } while (node !is null);
    listImpl_.reset();
    return result;
  }

  public override int count() {
    int length;
    return (listImpl_.get_length(length) == S_OK) ? length : 0;
  }

}

/+

  scope mgr = new XmlNamespaceManager;
  mgr.addNamespace("rdf", "http://www.w3.org/1999/02/22-rdf-syntax-ns#");
  mgr.addNamespace("dc", "http://purl.org/dc/elements/1.1/");
  mgr.addNamespace("rss", "http://purl.org/rss/1.0/");

  scope doc = new XmlDocument;
  doc.load("Guardian Unlimited UK Latest.xml");
  foreach (node; doc.documentElement.selectNodes("/rdf:RDF/rss:item", mgr)) {
   if (node !is null)
      writefln(node.text);
  }
  +/

private class XPathNodeList : XmlNodeList {

  private IXMLDOMSelection selection_;

  private bool finished_;
  private XmlNode[] list_;

  public this(XmlNode container, string expression, XmlNamespaceManager nsmgr) {
    if (nsmgr !is null) {
      string str;
      foreach (prefix; nsmgr) {
        if (prefix != "xmlns")
          str ~= "xmlns:" ~ prefix ~ "='" ~ nsmgr.lookupNamespace(prefix) ~ "' ";
      }

      VARIANT selectionNs = str;
      container.ownerDocument.docImpl_.setProperty(cast(wchar*)"SelectionNamespaces", selectionNs);
      selectionNs.clear();
    }

    wchar* bstrExpression = expression.toBStr();
    IXMLDOMNodeList nodeList;
    if (container.nodeImpl_.selectNodes(bstrExpression, nodeList) == S_OK) {
      scope(exit) tryRelease(nodeList);
      selection_ = com_cast!(IXMLDOMSelection)(nodeList);
      freeBStr(bstrExpression);
    }
    else
      finished_ = true;
  }

  ~this() {
    list_ = null;

    if (selection_ !is null) {
      tryRelease(selection_);
      selection_ = null;
    }
  }

  public override XmlNode item(int index) {
    if (index >= list_.length)
      read(index);
    if (index >= list_.length || index < 0)
      return null;
    return list_[index];
  }

  public override int opApply(int delegate(ref XmlNode) action) {
    int index = -1;

    bool hasNext() {
      index++;
      int n = read(index + 1);
      if (index > n - 1)
        return false;
      return (list_[index] !is null);
    }

    int result = 0;
    while (hasNext()) {
      XmlNode node = list_[index];
      if ((result = action(node)) != 0)
        break;
    }
    return result;
  }

  public override int count() {
    if (!finished_)
      read(int.max);
    return list_.length;
  }

  private int read(int until) {
    int n = list_.length;
    while (!finished_ && until >= n) {
      IXMLDOMNode node = null;
      selection_.get_item(n, node);
      if (node !is null) {
        list_ ~= getNodeShim(node);
        n++;
      }
      else {
        selection_.reset();
        tryRelease(selection_);
        selection_ = null;
        finished_ = true;
        break;
      }
    }
    return n;
  }

}

/**
 * Represents a collection of nodes that can be accessed by name or index.
 */
public class XmlNamedNodeMap {

  private IXMLDOMNamedNodeMap mapImpl_;

  /**
   * Retrieves the node specified by name.
   * Params: name = The qualified _name of the node to retrieve.
   * Returns: The node with the specified _name.
   */
  public XmlNode getNamedItem(string name) {
    IXMLDOMNode node;

    wchar* bstr = name.toBStr();
    int hr = mapImpl_.getNamedItem(bstr, node);
    freeBStr(bstr);

    return (hr == S_OK) ? getNodeShim(node) : null;
  }

  /**
   * Retrieves the node with the matching _localName and _namespaceURI.
   * Params: 
   *   localName = The local name of the node to retrieve.
   *   namespaceURI = The namespace URI of the node to retrieve.
   * Returns: The node with the matching local name and namespace URI.
   */
  public XmlNode getNamedItem(string localName, string namespaceURI) {
    IXMLDOMNode node;

    wchar* bstrName = localName.toBStr();
    wchar* bstrNs = namespaceURI.toBStr();

    int hr = mapImpl_.getQualifiedItem(bstrName, bstrNs, node);

    freeBStr(bstrName);
    freeBStr(bstrNs);

    return (hr == S_OK) ? getNodeShim(node) : null;
  }

  /**
   * Removes the node with the specified _name.
   * Params: name = The qualified _name of the node to remove.
   * Returns: The node removed.
   */
  public XmlNode removeNamedItem(string name) {
    IXMLDOMNode node;

    wchar* bstr = name.toBStr();
    int hr = mapImpl_.removeNamedItem(bstr, node);
    freeBStr(bstr);

    return (hr == S_OK) ? getNodeShim(node) : null;
  }

  /**
   * Removes the node with the matching _localName and _namespaceURI.
   * Params: 
   *   localName = The local name of the node to remove.
   *   namespaceURI = The namespace URI of the node to remove.
   * Returns: The node removed.
   */
  public XmlNode removeNamedItem(string localName, string namespaceURI) {
    IXMLDOMNode node;

    wchar* bstrName = localName.toBStr();
    wchar* bstrNs = namespaceURI.toBStr();

    int hr = mapImpl_.removeQualifiedItem(bstrName, bstrNs, node);

    freeBStr(bstrName);
    freeBStr(bstrNs);

    return (hr == S_OK) ? getNodeShim(node) : null;
  }

  /**
   * Adds a _node using its _name property.
   * Params: node = The _node to store.
   * Returns: The old _node.
   */
  public XmlNode setNamedItem(XmlNode node) {
    IXMLDOMNode namedItem;
    if (mapImpl_.setNamedItem(node.nodeImpl_, namedItem) == S_OK)
      return getNodeShim(namedItem);
    return null;
  }

  /**
   * Retrieves the node at the specified _index.
   * Params: index = The position of the node to retrieve.
   * Returns: The node at the specified _index.
   */
  public XmlNode item(int index) {
    IXMLDOMNode node;
    if (mapImpl_.get_item(index, node) == S_OK)
      return getNodeShim(node);
    return null;
  }

  /**
   * Gets the number of nodes.
   * Returns: The number of nodes.
   */
  public int count() {
    int length;
    return (mapImpl_.get_length(length) == S_OK) ? length : 0;
  }

  /**
   * Provides support for foreach iteration over the collection of nodes.
   */
  public int opApply(int delegate(ref XmlNode) action) {
    int result;
    IXMLDOMNode node;

    do {
      if (mapImpl_.nextNode(node) == S_OK) {
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
      mapImpl_.Release();
      mapImpl_ = null;
    }
  }

}

/**
 * Represents a collection of attributes that can be accessed by name or index.
 */
public final class XmlAttributeCollection : XmlNamedNodeMap {

  /**
   * Gets the attribute at the specified _index.
   * Params: index = The _index of the attribute.
   * Returns: The attribute at the specified _index.
   */
  public final XmlAttribute opIndex(int index) {
    return cast(XmlAttribute)item(index);
  }

  /**
   * Gets the attribute with the specified _name.
   * Params: name = The qualified _name of the attribute.
   * Returns: The attribute with the specified _name.
   */
  public final XmlAttribute opIndex(string name) {
    return cast(XmlAttribute)getNamedItem(name);
  }

  /**
   * Gets the attribute with the specified local name and namespace URI.
   * Params: 
   *   localName = The local name of the attribute.
   *   namespaceURI = The namespace URI of the attribute.
   * Returns: The attribute with the specified local name and namespace URI.
   */
  public final XmlAttribute opIndex(string localName, string namespaceURI) {
    return cast(XmlAttribute)getNamedItem(localName, namespaceURI);
  }

  package this(XmlNode parent) {
    super(parent);
  }

}

/**
 * Represents a single node in the XML document.
 */
public abstract class XmlNode {

  private IXMLDOMNode nodeImpl_;

  public XmlNode clone() {
    return cloneNode(true);
  }

  public XmlNode cloneNode(bool deep) {
    IXMLDOMNode cloneRoot;
    nodeImpl_.cloneNode(deep ? VARIANT_TRUE : VARIANT_FALSE, cloneRoot);
    return getNodeShim(cloneRoot);
  }

  public XmlNode appendChild(XmlNode newChild) {
    IXMLDOMNode newNode;
    nodeImpl_.appendChild(newChild.nodeImpl_, newNode);
    return getNodeShim(newNode);
  }

  public XmlNode insertBefore(XmlNode newChild, XmlNode refChild) {
    if (refChild is null)
      return appendChild(newChild);

    if (newChild is refChild)
      return newChild;

    VARIANT refNode = refChild.nodeImpl_;
    IXMLDOMNode newNode;
    nodeImpl_.insertBefore(newChild.nodeImpl_, refNode, newNode);
    return getNodeShim(newNode);
  }

  public XmlNode insertAfter(XmlNode newChild, XmlNode refChild) {
    if (refChild is null)
      return insertBefore(newChild, this.firstChild);

    if (newChild is refChild)
      return newChild;

    XmlNode next = refChild.nextSibling;
    if (next !is null)
      return insertBefore(newChild, next);

    return appendChild(newChild);
  }

  public XmlNode replaceChild(XmlNode newChild, XmlNode oldChild) {
    XmlNode next = oldChild.nextSibling;
    removeChild(oldChild);
    insertBefore(newChild, next);
    return oldChild;
  }

  public XmlNode removeChild(XmlNode oldChild) {
    IXMLDOMNode oldNode;
    nodeImpl_.removeChild(oldChild.nodeImpl_, oldNode);
    return getNodeShim(oldNode);
  }

  public void removeAll() {
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
   * Selects a list of nodes matching the XPath expression.
   * Params: 
   *   xpath = The XPath expression.
   *   nsmgr = The namespace resolver to use.
   * Returns: An XmlNodeList containing the nodes matching the XPath query.
   */
  public final XmlNodeList selectNodes(string xpath, XmlNamespaceManager nsmgr = null) {
    return new XPathNodeList(this, xpath, nsmgr);
  }

  /**
   * Selects the first node that matches the XPath expression.
   * Params: 
   *   xpath = The XPath expression.
   *   nsmgr = The namespace resolver to use.
   * Returns: The first XmlNode that matches the XPath query.
   */
  public final XmlNode selectSingleNode(string xpath, XmlNamespaceManager nsmgr = null) {
    auto list = selectNodes(xpath, nsmgr);
    if (list !is null && list.count > 0)
      return list[0];
    return null;
  }

  /**
   * Gets the type of the current node.
   * Returns: One of the XmlNodeType values.
   */
  public abstract XmlNodeType nodeType();

  /**
   * Gets the namespace _prefix of this node.
   * Returns: The namespace _prefix for this node. For example, prefix is 'bk' for the element &lt;bk:book&gt;.
   */
  public string prefix() {
    return "";
  }

  /**
   *
   */
  public abstract string localName() {
    wchar* bstr;
    if (nodeImpl_.get_baseName(bstr) == S_OK)
      return fromBStr(bstr);
    return null;
  }

  /**
   *
   */
  public abstract string name() {
    wchar* bstr;
    if (nodeImpl_.get_nodeName(bstr) == S_OK)
      return fromBStr(bstr);
    return null;
  }

  /**
   *
   */
  public string namespaceURI() {
    return "";
  }

  /**
   *
   */
  public void text(string value) {
    wchar* bstr = value.toBStr();
    if (bstr != null) {
      nodeImpl_.set_text(bstr);
      freeBStr(bstr);
    }
  }

  /**
   * Ditto
   */
  public string text() {
    wchar* bstr;
    if (nodeImpl_.get_text(bstr) == S_OK)
      return fromBStr(bstr);
    return null;
  }

  public void xml(string value) {
    throw new InvalidOperationException;
  }

  /**
   *
   */
  public string xml() {
    wchar* bstr;
    if (nodeImpl_.get_xml(bstr) == S_OK)
      return fromBStr(bstr);
    return null;
  }

  public void value(string value) {
    throw new InvalidOperationException;
  }

  public string value() {
    return null;
  }

  public bool hasChildNodes() {
    VARIANT_BOOL result;
    if (nodeImpl_.hasChildNodes(result) == S_OK)
      return result == VARIANT_TRUE;
    return false;
  }

  public XmlNodeList childNodes() {
    IXMLDOMNodeList list;
    if (nodeImpl_.get_childNodes(list) == S_OK)
      return new XmlNodes(list);
    return null;
  }

  public XmlNode firstChild() {
    IXMLDOMNode node;
    if (nodeImpl_.get_firstChild(node) == S_OK)
      return getNodeShim(node);
    return null;
  }

  public XmlNode lastChild() {
    IXMLDOMNode node;
    if (nodeImpl_.get_lastChild(node) == S_OK)
      return getNodeShim(node);
    return null;
  }

  public XmlNode previousSibling() {
    return null;
  }

  public XmlNode nextSibling() {
    return null;
  }

  public XmlNode parentNode() {
    IXMLDOMNode node;
    if (nodeImpl_.get_parentNode(node) == S_OK)
      return getNodeShim(node);
    return null;
  }

  public XmlDocument ownerDocument() {
    IXMLDOMDocument doc;
    if (nodeImpl_.get_ownerDocument(doc) == S_OK)
      return cast(XmlDocument)getNodeShim(doc);
    return null;
  }

  public XmlAttributeCollection attributes() {
    return null;
  }

  /**
   *
   */
  public final int opApply(int delegate(ref XmlNode) action) {
    int result = 0;

    IXMLDOMNodeList nodeList;
    if (nodeImpl_.get_childNodes(nodeList) == S_OK) {
      scope (exit) nodeList.Release();

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

  package static string constructQName(string prefix, string localName) {
    if (prefix.length == 0)
      return localName;
    return prefix ~ ":" ~ localName;
  }

  package static void splitName(string name, out string prefix, out string localName) {
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

template TypedNodeImpl(string Type, string Field = "typedNodeImpl_") {

  const string TypedNodeImpl = 
    "private " ~ Type ~ " " ~ Field ~ ";"

    "package this(IXMLDOMNode nodeImpl) {"
    "  super(nodeImpl);"
    "  " ~ Field ~ " = com_cast!(" ~ Type ~ ")(nodeImpl);"
    "}"

    "~this() {"
    "  if (" ~ Field ~ " !is null) {"
    "    tryRelease(" ~ Field ~ ");"
    "    " ~ Field ~ " = null;"
    "  }"
    "}";
}

public class XmlAttribute : XmlNode {

  mixin(TypedNodeImpl!("IXMLDOMAttribute"));

  public override XmlNodeType nodeType() {
    return XmlNodeType.Attribute;
  }

  public override string localName() {
    return super.localName;
  }

  public override string name() {
    return super.name;
  }

  public override string namespaceURI() {
    wchar* bstr;
    if (nodeImpl_.get_namespaceURI(bstr) == S_OK)
      return fromBStr(bstr);
    return string.init;
  }

  public override void value(string value) {
    VARIANT v = value;
    typedNodeImpl_.set_value(v);
    v.clear();
  }

  public override string value() {
    VARIANT v;
    typedNodeImpl_.get_value(v);
    return v.toString();
  }

  public override XmlNode parentNode() {
    return null;
  }

  public XmlElement ownerElement() {
    return cast(XmlElement)super.parentNode;
  }

  public bool specified() {
    com_bool result;
    nodeImpl_.get_specified(result);
    return result == com_true;
  }

}

/**
 *
 */
public abstract class XmlLinkedNode : XmlNode {

  public override XmlNode previousSibling() {
    IXMLDOMNode node;
    nodeImpl_.get_previousSibling(node);
    return getNodeShim(node);
  }

  public override XmlNode nextSibling() {
    IXMLDOMNode node;
    nodeImpl_.get_nextSibling(node);
    return getNodeShim(node);
  }

  package this(IXMLDOMNode nodeImpl) {
    super(nodeImpl);
  }

}


/**
 *
 */
public abstract class XmlCharacterData : XmlLinkedNode {

  mixin(TypedNodeImpl!("IXMLDOMCharacterData"));

  public void appendData(string strData) {
    wchar* bstr = strData.toBStr();
    typedNodeImpl_.appendData(bstr);
    freeBStr(bstr);
  }

  public void insertData(int offset, string strData) {
    wchar* bstr = strData.toBStr();
    typedNodeImpl_.insertData(offset, bstr);
    freeBStr(bstr);
  }

  public void replaceData(int offset, int count, string strData) {
    wchar* bstr = strData.toBStr();
    typedNodeImpl_.replaceData(offset, count, bstr);
    freeBStr(bstr);
  }

  public void deleteData(int offset, int count) {
    typedNodeImpl_.deleteData(offset, count);
  }

  public string substring(int offset, int count) {
    wchar* bstr;
    if (typedNodeImpl_.substringData(offset, count, bstr) == S_OK)
      return fromBStr(bstr);
    return "";
  }

  public int length() {
    int result;
    typedNodeImpl_.get_length(result);
    return result;
  }

  public void data(string value) {
    wchar* bstr = value.toBStr();
    typedNodeImpl_.set_data(bstr);
    freeBStr(bstr);
  }

  public string data() {
    wchar* bstr;
    if (typedNodeImpl_.get_data(bstr) == S_OK)
      return fromBStr(bstr);
    return "";
  }

  public override void value(string value) {
    data = value;
  }

  public override string value() {
    return data;
  }

}

/**
 */
public class XmlCDataSection : XmlCharacterData {

  public override XmlNodeType nodeType() {
    return XmlNodeType.CDATA;
  }

  public override string localName() {
    return "#cdata-section";
  }

  public override string name() {
    return localName;
  }

  package this(IXMLDOMNode nodeImpl) {
    super(nodeImpl);
  }

}

/**
 */
public class XmlComment : XmlCharacterData {

  public override XmlNodeType nodeType() {
    return XmlNodeType.Comment;
  }

  public override string localName() {
    return "#comment";
  }

  public override string name() {
    return localName;
  }

  package this(IXMLDOMNode nodeImpl) {
    super(nodeImpl);
  }

}

/**
 */
public class XmlText : XmlCharacterData {

  mixin(TypedNodeImpl!("IXMLDOMText"));

  public override XmlNodeType nodeType() {
    return XmlNodeType.Text;
  }

  public override string localName() {
    return super.localName;
  }

  public override string name() {
    return super.name;
  }

  public XmlText splitText(int offset) {
    IXMLDOMText node;
    if (typedNodeImpl_.splitText(offset, node) == S_OK)
      return cast(XmlText)getNodeShim(node);
    return null;
  }

}

public class XmlEntity : XmlNode {

  mixin(TypedNodeImpl!("IXMLDOMEntity"));

  public override XmlNodeType nodeType() {
    return XmlNodeType.Entity;
  }

  public override string name() {
    return super.name;
  }

  public override string localName() {
    return super.localName;
  }

  public override void text(string value) {
    throw new InvalidOperationException;
  }

  public override string text() {
    return super.text;
  }

  public override void xml(string value) {
    throw new InvalidOperationException;
  }

  public override string xml() {
    return "";
  }

  public final string publicId() {
    VARIANT var;
    if (typedNodeImpl_.get_publicId(var) == S_OK) {
      scope(exit) var.clear();
      return var.toString();
    }
    return null;
  }

  public final string systemId() {
    VARIANT var;
    if (typedNodeImpl_.get_systemId(var) == S_OK) {
      scope(exit) var.clear();
      return var.toString();
    }
    return null;
  }

}

public class XmlEntityReference : XmlLinkedNode {

  mixin(TypedNodeImpl!("IXMLDOMEntityReference"));

  public override XmlNodeType nodeType() {
    return XmlNodeType.EntityReference;
  }

  public override string name() {
    return super.name;
  }

  public override string localName() {
    return super.localName;
  }

  public override void value(string value) {
    throw new InvalidOperationException;
  }

  public override string value() {
    return "";
  }

}

public class XmlNotation : XmlNode {

  mixin(TypedNodeImpl!("IXMLDOMNotation"));

  public override XmlNodeType nodeType() {
    return XmlNodeType.Notation;
  }

  public override string name() {
    return super.name;
  }

  public override string localName() {
    return super.localName;
  }

}

public class XmlDocumentType : XmlLinkedNode {

  mixin(TypedNodeImpl!("IXMLDOMDocumentType"));

  public override XmlNodeType nodeType() {
    return XmlNodeType.DocumentType;
  }

  public override string name() {
    wchar* bstr;
    typedNodeImpl_.get_name(bstr);
    return fromBStr(bstr);
  }

  public override string localName() {
    return name;
  }

  public final XmlNamedNodeMap entities() {
    IXMLDOMNamedNodeMap map;
    if (typedNodeImpl_.get_entities(map) == S_OK)
      return new XmlNamedNodeMap(map);
    return null;
  }

  public final XmlNamedNodeMap notations() {
    IXMLDOMNamedNodeMap map;
    if (typedNodeImpl_.get_notations(map) == S_OK)
      return new XmlNamedNodeMap(map);
    return null;
  }

}

public class XmlDocumentFragment : XmlNode {

  mixin(TypedNodeImpl!("IXMLDOMDocumentFragment"));

  public override XmlNodeType nodeType() {
    return XmlNodeType.DocumentFragment;
  }

  public override string name() {
    return "#document-fragment".dup;
  }

  public override string localName() {
    return name;
  }

  public override XmlNode parentNode() {
    return null;
  }

  public override XmlDocument ownerDocument() {
    return cast(XmlDocument)super.parentNode;
  }

}

/**
 *
 */
public class XmlElement : XmlLinkedNode {

  mixin(TypedNodeImpl!("IXMLDOMElement"));

  /**
   *
   */
  public override XmlNodeType nodeType() {
    return XmlNodeType.Element;
  }

  /**
   *
   */
  public override string localName() {
    return super.localName;
  }

  /**
   *
   */
  public override string name() {
    return super.name;
  }

  public override string namespaceURI() {
    wchar* bstr;
    if (nodeImpl_.get_namespaceURI(bstr) == S_OK)
      return fromBStr(bstr);
    return string.init;
  }

  public string getAttribute(string name) {
    wchar* bstr = name.toBStr();
    VARIANT value;
    typedNodeImpl_.getAttribute(bstr, value);
    return value.toString();
  }

  public string getAttribute(string localName, string namespaceURI) {
    if (XmlAttribute attr = getAttributeNode(localName, namespaceURI))
      return attr.value;
    return null;
  }

  public XmlAttribute getAttributeNode(string name) {
    if (hasAttributes)
      return attributes[name];
    return null;
  }

  public XmlAttribute getAttributeNode(string localName, string namespaceURI) {
    if (hasAttributes)
      return attributes[localName, namespaceURI];
    return null;
  }

  public bool hasAttribute(string name) {
    return getAttributeNode(name) !is null;
  }

  public bool hasAttribute(string localName, string namespaceURI) {
    return getAttributeNode(localName, namespaceURI) !is null;
  }

  public void setAttribute(string name, string value) {
    wchar* bstr = name.toBStr();
    VARIANT v = value;
    typedNodeImpl_.setAttribute(bstr, v);
    v.clear();
    freeBStr(bstr);
  }

  public XmlAttribute setAttributeNode(XmlAttribute newAttr) {
    IXMLDOMAttribute attr;
    if (typedNodeImpl_.setAttributeNode(newAttr.typedNodeImpl_, attr) == S_OK)
      return cast(XmlAttribute)getNodeShim(attr);
    return null;
  }

  public void removeAttribute(string name) {
    if (hasAttributes)
      attributes.removeNamedItem(name);
  }

  public void removeAttribute(string localName, string namespaceURI) {
    if (hasAttributes)
      attributes.removeNamedItem(localName, namespaceURI);
  }

  public XmlAttribute removeAttributeNode(XmlAttribute oldAttr) {
    IXMLDOMAttribute attr;
    if (typedNodeImpl_.removeAttributeNode(oldAttr.typedNodeImpl_, attr) == S_OK)
      return cast(XmlAttribute)getNodeShim(attr);
    return null;
  }

  public XmlAttribute removeAttributeNode(string localName, string namespaceURI) {
    if (hasAttributes) {
      if (XmlAttribute attr = getAttributeNode(localName, namespaceURI)) {
        removeAttributeNode(attr);
        return attr;
      }
    }
    return null;
  }

  public void normalize() {
    typedNodeImpl_.normalize();
  }

  public XmlNodeList getElementsByTagName(string name) {
    wchar* bstr = name.toBStr();
    if (bstr != null) {
      scope (exit) freeBStr(bstr);
      IXMLDOMNodeList list;
      if (typedNodeImpl_.getElementsByTagName(bstr, list))
        return new XmlNodes(list);
    }
    return null;
  }

  public override XmlAttributeCollection attributes() {
    return new XmlAttributeCollection(this);
  }

  public bool hasAttributes() {
    IXMLDOMNamedNodeMap attrs;
    if (nodeImpl_.get_attributes(attrs) == S_OK) {
      scope (exit) tryRelease(attrs);

      int length;
      if (attrs.get_length(length) == S_OK)
        return length > 0;
      return false;
    }
    return false;
  }

}

/**
 */
public class XmlProcessingInstruction : XmlLinkedNode {

  mixin(TypedNodeImpl!("IXMLDOMProcessingInstruction"));

  public override XmlNodeType nodeType() {
    return XmlNodeType.ProcessingInstruction;
  }

  public override string name() {
    return super.name;
  }

  public override string localName() {
    return super.localName;
  }

}

/**
 */
public class XmlDeclaration : XmlLinkedNode {

  private const string VERSION = "1.0";

  mixin(TypedNodeImpl!("IXMLDOMProcessingInstruction"));
  private string encoding_;
  private string standalone_;

  public override XmlNodeType nodeType() {
    return XmlNodeType.XmlDeclaration;
  }

  public override string name() {
    return localName;
  }

  public override string localName() {
    return "xml";
  }

  public final void value(string value) {
    text = value;
  }

  public override string value() {
    return text;
  }

  public final void encoding(string value) {
    encoding_ = value;
  }

  public final string encoding() {
    return encoding_;
  }

  public final void standalone(string value) {
    if (value == null || value == "yes" || value == "no")
      standalone_ = value;
  }

  public final string standalone() {
    return standalone_;
  }

  public final string xmlversion() {
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

/*public class ValidationEventArgs {

  private XmlException ex_;

  package this(XmlException ex) {
    ex_ = ex;
  }

  public XmlException exception() {
    return ex_;
  }

  public string message() {
    return ex_.message;
  }

}

alias void delegate(Object, ValidationEventArgs) ValidationEventHandler;*/

public class XmlImplementation {

  private IXMLDOMImplementation impl_;

  public final bool hasFeature(string strFeature, string strVersion) {
    com_bool result = com_false;

    wchar* bstrFeature = strFeature.toBStr();
    wchar* bstrVersion = strVersion.toBStr();
    impl_.hasFeature(bstrFeature, bstrVersion, result);
    freeBStr(bstrFeature);
    freeBStr(bstrVersion);

    return result == com_true;
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
public class XmlDocument : XmlNode {

  mixin(TypedNodeImpl!("IXMLDOMDocument2", "docImpl_"));
  private int msxmlVersion_;

  /**
   * Initializes a new instance.
   */
  public this() {
    IXMLDOMDocument2 doc = null;
    if ((doc = cast(IXMLDOMDocument2)DOMDocument60.coCreate!(IXMLDOMDocument3)) !is null)
      msxmlVersion_ = 6;
    else if ((doc = DOMDocument40.coCreate!(IXMLDOMDocument2)) !is null)
      msxmlVersion_ = 4;
    else if ((doc = DOMDocument30.coCreate!(IXMLDOMDocument2, ExceptionPolicy.ThrowIfNull)) !is null)
      msxmlVersion_ = 3;

    if (msxmlVersion_ >= 4)
      doc.setProperty(cast(wchar*)"NewParser", VARIANT(true));
    if (msxmlVersion_ >= 6)
      doc.setProperty(cast(wchar*)"MultipleErrorMessages", VARIANT(true));
    if (msxmlVersion_ < 4) {
      VARIANT var = "XPath";
      clearAfter (var, {
        doc.setProperty(cast(wchar*)"SelectionLanguage", var);
      });
    }

    doc.set_async(VARIANT_FALSE);
    doc.set_validateOnParse(VARIANT_FALSE);

    this(doc);
  }

  /**
   * Creates an XmlNode with the specified _type, _name and _namespaceURI.
   * Params:
   *   type = The _type of the new node.
   *   name = The qualified _name of the new node.
   *   namespaceURI = The namespace URI of the new node.
   * Returns: The new XmlNode.
   */
  public XmlNode createNode(XmlNodeType type, string name, string namespaceURI) {
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
  public XmlNode createNode(XmlNodeType type, string prefix, string name, string namespaceURI) {
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
  public XmlElement createElement(string name) {
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
  public XmlElement createElement(string qualifiedName, string namespaceURI) {
    IXMLDOMNode node;

    wchar* bstrName = qualifiedName.toBStr();
    wchar* bstrNs = namespaceURI.toBStr();
    docImpl_.createNode(VARIANT(DOMNodeType.NODE_ELEMENT), bstrName, bstrNs, node);
    freeBStr(bstrName);
    freeBStr(bstrNs);

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
  public XmlElement createElement(string prefix, string localName, string namespaceURI) {
    return createElement(XmlNode.constructQName(prefix, localName), namespaceURI);
  }

  /**
   * Creates an XmlAttribute with the specified _name.
   * Params: name = The qualified _name of the attribute.
   * Returns: The new XmlAttribute.
   */
  public XmlAttribute createAttribute(string name) {
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
  public XmlAttribute createAttribute(string qualifiedName, string namespaceURI) {
    IXMLDOMNode node;

    wchar* bstrName = qualifiedName.toBStr();
    wchar* bstrNs = namespaceURI.toBStr();
    docImpl_.createNode(VARIANT(DOMNodeType.NODE_ATTRIBUTE), bstrName, bstrNs, node);
    freeBStr(bstrName);
    freeBStr(bstrNs);

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
  public XmlAttribute createAttribute(string prefix, string localName, string namespaceURI) {
    return createAttribute(XmlNode.constructQName(prefix, localName), namespaceURI);
  }

  /**
   * Creates an XmlCDataSection node with the specified _data.
   * Params: text = The _data for the node.
   * Returns: The new XmlCDataSection node.
   */
  public XmlCDataSection createCDataSection(string data) {
    IXMLDOMCDATASection node;

    wchar* bstr = data.toBStr();
    docImpl_.createCDATASection(bstr, node);
    freeBStr(bstr);

    return cast(XmlCDataSection)getNodeShim(node);
  }

  /**
   * Creates an XmlComment node with the specified _data.
   * Params: text = The _data for the node.
   * Returns: The new XmlComment node.
   */
  public XmlComment createComment(string data) {
    IXMLDOMComment node;

    wchar* bstr = data.toBStr();
    docImpl_.createComment(bstr, node);
    freeBStr(bstr);

    return cast(XmlComment)getNodeShim(node);
  }

  /**
   * Creates an XmlText node with the specified _text.
   * Params: text = The _text for the node.
   * Returns: The new XmlText node.
   */
  public XmlText createTextNode(string text) {
    IXMLDOMText node = null;

    wchar* bstr = text.toBStr();
    docImpl_.createTextNode(bstr, node);
    freeBStr(bstr);

    return cast(XmlText)getNodeShim(node);
  }

  /**
   * Creates an XmlProcessingInstruction node with the specified name and _data.
   * Params:
   *   target = the name of the processing instruction.
   *   data = The _data for the processing instruction.
   * Returns: The new XmlProcessingInstruction node.
   */
  public XmlProcessingInstruction createProcessingInstruction(string target, string data) {
    IXMLDOMProcessingInstruction node;

    wchar* bstrTarget = target.toBStr();
    wchar* bstrData = data.toBStr();
    docImpl_.createProcessingInstruction(bstrTarget, bstrData, node);
    freeBStr(bstrTarget);
    freeBStr(bstrData);

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
  public XmlDeclaration createXmlDeclaration(string xmlversion, string encoding, string standalone) {
    string data = "version=\"" ~ xmlversion ~ "\"";
    if (encoding != null)
      data ~= " encoding=\"" ~ encoding ~ "\"";
    if (standalone != null)
      data ~= " standalone=\"" ~ standalone ~ "\"";

    IXMLDOMProcessingInstruction node;

    wchar* bstrTarget = "xml".toBStr();
    wchar* bstrData = data.toBStr();
    docImpl_.createProcessingInstruction(bstrTarget, bstrData, node);
    freeBStr(bstrTarget);
    freeBStr(bstrData);

    return cast(XmlDeclaration)getNodeShim(node);
  }

  public XmlEntityReference createEntityReference(string name) {
    IXMLDOMEntityReference node;

    wchar* bstr = name.toBStr();
    docImpl_.createEntityReference(bstr, node);
    freeBStr(bstr);

    return cast(XmlEntityReference)getNodeShim(node);
  }

  public XmlDocumentFragment createDocumentFragment() {
    IXMLDOMDocumentFragment node;
    docImpl_.createDocumentFragment(node);
    return cast(XmlDocumentFragment)getNodeShim(node);
  }

  /**
   * Gets the type of the current node.
   * Returns: For XmlDocument nodes, the value is XmlNodeType.Document.
   */
  public override XmlNodeType nodeType() {
    return XmlNodeType.Document;
  }

  /**
   * Gets the locale name of the node.
   * Returns: For XmlDocument nodes, the local name is #document.
   */
  public override string localName() {
    return "#document".dup;
  }

  /**
   * Gets the qualified _name of the node.
   * Returns: For XmlDocument nodes, the _name is #document.
   */
  public override string name() {
    return localName;
  }

  /**
   * Gets the parent node.
   * Returns: For XmlDocument nodes, null is returned.
   */
  public override XmlNode parentNode() {
    return null;
  }

  /**
   * Gets the XmlDocument to which the current node belongs.
   * Returns: For XmlDocument nodes, null is returned.
   */
  public override XmlDocument ownerDocument() {
    return null;
  }

  public override void xml(string value) {
    loadXml(value);
  }
  
  public override string xml() {
    return super.xml;
  }

  /** 
   * Gets the root element for the document.
   * Returns: The XmlElement representing the root of the XML document tree. If no root exists, null is returned.
   */
  public final XmlElement documentElement() {
    IXMLDOMElement element;
    if (docImpl_.get_documentElement(element) == S_OK)
      return cast(XmlElement)getNodeShim(element);
    return null;
  }

  public final XmlDocumentType documentType() {
    IXMLDOMDocumentType doctype;
    if (docImpl_.get_doctype(doctype) == S_OK)
      return cast(XmlDocumentType)getNodeShim(doctype);
    return null;
  }

  public final XmlImplementation implementation() {
    IXMLDOMImplementation impl;
    if (docImpl_.get_implementation(impl) == S_OK)
      return new XmlImplementation(impl);
    return null;
  }

  /**
   * Loads the XML document from the specified URL.
   * Params: fileName = URL for the file containing the XML document to _load. The URL can be either a local file or a web address.
   * Throws: XmlException if there is a _load or parse error in the XML.
   */
  public void load(string fileName) {
    VARIANT source = fileName;
    scope(exit) source.clear();

    com_bool success;
    docImpl_.load(source, success);
    if (success != com_true)
      parsingException();
  }

  /**
   * Loads the XML document from the specified stream.
   * Params: input = The stream containing the XML document to _load.
   * Throws: XmlException if there is a _load or parse error in the XML.
   */
  public void load(Stream input) {
    auto s = new COMStream(input);
    scope(exit) tryRelease(s);

    VARIANT source = s;
    scope(exit) source.clear();

    com_bool success;
    docImpl_.load(source, success);
    if (success != com_true)
      parsingException();
  }

  /**
   * Loads the XML document from the specified string.
   * Params: xml = The string containing the XML document to load.
   * Throws: XmlException if there is a _load or parse error in the XML.
   */
  public void loadXml(string xml) {
    com_bool success;

    wchar* bstr = xml.toBStr();
    docImpl_.loadXML(bstr, success);
    freeBStr(bstr);

    if (success != com_true)
      parsingException();
  }

  /**
   * Saves the XML document to the specified file.
   * Params: fileName = The location of the file where you want to _save the document.
   * Throws: XmlException if there is no document element.
   */
  public void save(string fileName) {
    if (documentElement is null)
      throw new XmlException("Invalid XML document. The document does not have a root element.");
 
    VARIANT dest = fileName;
    scope(exit) dest.clear();

    if (docImpl_.save(dest) != S_OK)
      throw new XmlException;
  }

  /**
   * Saves the XML document to the specified stream.
   * Params: output = The stream to which you want to _save.
   */
  public void save(Stream output) {
    auto s = new COMStream(output);
    scope(exit) tryRelease(s);

    VARIANT dest = s;
    scope(exit) dest.clear();

    if (docImpl_.save(dest) != S_OK)
      throw new XmlException;
  }

  public XmlElement getElementByTagName(string elementId) {
    IXMLDOMNode node;

    wchar* bstr = elementId.toBStr();
    docImpl_.nodeFromID(bstr, node);
    freeBStr(bstr);

    return cast(XmlElement)getNodeShim(node);
  }

  public XmlNodeList getElementsByTagName(string name) {
    IXMLDOMNodeList list;

    wchar* bstr = name.toBStr();
    docImpl_.getElementsByTagName(bstr, list);
    freeBStr(bstr);

    return new XmlNodes(list);
  }

  /*public final void validate(ValidationEventHandler validationHandler, XmlNode nodeToValidate = null) {
    if (nodeToValidate is null)
      nodeToValidate = this;

    if (validationHandler == null)
      throw new ArgumentNullException("validationHandler");

    IXMLDOMParseError error;
    if (msxmlVersion_ < 5)
      docImpl_.validate(error);
    else {
      if (nodeToValidate.nodeType == XmlNodeType.Document)
        nodeToValidate = (cast(XmlDocument)nodeToValidate).documentElement;
      auto doc3 = com_cast!(IXMLDOMDocument3)(docImpl_);
      releaseAfter (doc3, {
        doc3.validateNode(nodeToValidate.impl, error);
      });
    }

    if (error !is null) {
      releaseAfter (error, {
        bool useV4Error = (msxmlVersion_ < 5);

        if (msxmlVersion_ > 4) {
          auto error2 = com_cast!(IXMLDOMParseError2)(error);
          if (error2 is null)
            useV4Error = true;
          else {
            releaseAfter (error2, {
              IXMLDOMParseErrorCollection errors;
              if (error2.get_allErrors(errors) != S_OK)
                useV4Error = true;
              else {
                IXMLDOMParseError2 err;
                wchar* bstrReason, bstrSourceUri;
                int lineNumber, linePosition;
                int errorCode;

                do {
                  errors.get_next(err);
                  if (err is null)
                    break;
                  releaseAfter (err, {
                    err.get_errorCode(errorCode);
                    if (errorCode != S_OK) {
                      err.get_reason(bstrReason);
                      err.get_url(bstrSourceUri);
                      err.get_line(lineNumber);
                      err.get_linepos(linePosition);

                      string reason = fromBStr(bstrReason);
                      if (reason[$ - 1] == '\n')
                        reason = reason[0 .. $ - 2];

                      auto ex = new XmlException(reason, lineNumber, linePosition, fromBStr(bstrSourceUri));
                      validationHandler(this, new ValidationEventArgs(ex));
                    }
                  });
                } while (err !is null);
              }
            });
          }
        }
        if (useV4Error) {
          wchar* bstrReason, bstrSourceUri;
          int lineNumber, linePosition;
          int errorCode;

          error.get_errorCode(errorCode);
          if (errorCode != S_OK) {
            error.get_reason(bstrReason);
            error.get_url(bstrSourceUri);
            error.get_line(lineNumber);
            error.get_linepos(linePosition);

            string reason = fromBStr(bstrReason);
            if (reason[$ - 1] == '\n')
              reason = reason[0 .. $ - 2];

            auto ex = new XmlException(reason, lineNumber, linePosition, fromBStr(bstrSourceUri));
            validationHandler(this, new ValidationEventArgs(ex));
          }
        }
      });
    }
  }*/

  private void parsingException() {
    IXMLDOMParseError errorObj;
    if (docImpl_.get_parseError(errorObj) == S_OK) {
      wchar* bstrReason, bstrUrl;
      int line, position;

      errorObj.get_reason(bstrReason);
      errorObj.get_url(bstrUrl);
      errorObj.get_line(line);
      errorObj.get_linepos(position);

      errorObj.Release();

      string reason = fromBStr(bstrReason);
      if (reason[$ - 1] == '\n')
        reason = reason[0 .. $ - 2];

      throw new XmlException(reason, line, position, fromBStr(bstrUrl));
    }
  }

}
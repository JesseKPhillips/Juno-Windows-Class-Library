/**
 * Provides support for processing XML documents.
 */
module juno.xml.dom;

private import juno.base.all,
  juno.com.core,
  juno.xml.core,
  juno.xml.msxml;
private import std.stream : Stream;

private XmlNode getNodeShim(IXMLDOMNode node) {

  bool isXmlDeclaration(IXMLDOMNode node) {
    bool result = false;
    wchar* bstr;
    if (node.get_nodeName(bstr) == S_OK)
      result = (bstrToUtf8(bstr) == "xml");
    return result;
  }

  bool parseXmlDeclaration(IXMLDOMNode node, out char[] xmlversion, out char[] encoding, out char[] standalone) {

    char[] getValue(IXMLDOMNamedNodeMap attrs, char[] name) {
      char[] value;
      IXMLDOMNode n = null;
      wchar* bstr = utf8ToBstr(name);
      if (attrs.getNamedItem(bstr, n) == S_OK) {
        VARIANT var;
        if (n.get_nodeValue(var) == S_OK)
          value = var.toString();
        n.Release();
      }
      freeBstr(bstr);
      return value;
    }

    xmlversion, encoding, standalone = null;
    IXMLDOMNamedNodeMap attrs;
    if (node.get_attributes(attrs) == S_OK) {
      xmlversion = getValue(attrs, "version");
      encoding = getValue(attrs, "encoding");
      standalone = getValue(attrs, "standalone");

      attrs.Release();
      return true;
    }
    return false;
  }

  /* Return a shim for each type of IXMLDOMNode.*/
  if (node is null)
    return null;

  DOMNodeType nodeType;
  node.get_nodeType(nodeType);

  switch (nodeType) {
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
      try {
        if (isXmlDeclaration(node)) {
          char[] xmlversion, encoding, standalone;
          if (parseXmlDeclaration(node, xmlversion, encoding, standalone))
            return new XmlDeclaration(xmlversion, encoding, standalone, node);
        }
      }
      catch {
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

/**
 * Represents a collection of nodes.
 */
public abstract class XmlNodeList {

  /**
   * Retrieves the node at the specified _index.
   */
  public abstract XmlNode item(int index);

  /**
   * <i>Property.</i>
   * Retrieves the number of nodes.
   */
  public abstract int count();

  /**
   * <i>Property.</i>
   * Retrieves the node at the specified _index.
   */
  public XmlNode opIndex(int index) {
    return item(index);
  }

  /**
   * Provides foreach iteration over the collection of nodes.
   */
  public abstract int opApply(int delegate(inout XmlNode) action);

  protected this() {
  }

}

/**
 * Represents a collection of nodes that can be accessed by name or index.
 */
public class XmlNamedNodeMap {

  private IXMLDOMNamedNodeMap mapImpl_;

  /**
   * Returns an XmlNode with the matching _name.
   */
  public XmlNode getNamedItem(char[] name) {
    IXMLDOMNode node = null;

    wchar* bstr = utf8ToBstr(name);
    mapImpl_.getNamedItem(bstr, node);
    freeBstr(bstr);

    return getNodeShim(node);
  }

  /**
   * Returns an XmlNode with the matching local name and namespace URI.
   */
  public XmlNode getNamedItem(char[] localName, char[] namespaceURI) {
    IXMLDOMNode node = null;

    wchar* bstrName = utf8ToBstr(localName);
    wchar* bstrNs = utf8ToBstr(namespaceURI);

    mapImpl_.getQualifiedItem(bstrName, bstrNs, node);

    freeBstr(bstrName);
    freeBstr(bstrNs);

    return getNodeShim(node);
  }

  /**
   * Removes a node with the matching _name.
   */
  public XmlNode removeNamedItem(char[] name) {
    IXMLDOMNode node = null;

    wchar* bstr = utf8ToBstr(name);
    int hr = mapImpl_.removeNamedItem(bstr, node);
    freeBstr(bstr);

    return getNodeShim(node);
  }

  /**
   * Removes a node with the matching local name and namespace URI.
   */
  public XmlNode removeNamedItem(char[] localName, char[] namespaceURI) {
    IXMLDOMNode node = null;

    wchar* bstrName = utf8ToBstr(localName);
    wchar* bstrNs = utf8ToBstr(namespaceURI);

    mapImpl_.removeQualifiedItem(bstrName, bstrNs, node);

    freeBstr(bstrName);
    freeBstr(bstrNs);

    return getNodeShim(node);
  }

  /**
   * Adds an XmlNode.
   */
  public XmlNode setNamedItem(XmlNode node) {
    IXMLDOMNode namedItem = null;
    mapImpl_.setNamedItem(node.nodeImpl_, namedItem);
    return getNodeShim(namedItem);
  }

  /**
   * Retrieves the node at the specified _index.
   */
  public XmlNode item(int index) {
    IXMLDOMNode node = null;
    mapImpl_.get_item(index, node);
    return getNodeShim(node);
  }

  /**
   * <i>Property.</i>
   * Retrieves the number of nodes.
   */
  public int count() {
    int value;
    mapImpl_.get_length(value);
    return value;
  }

  /**
   * Provides foreach iteration over the collection of nodes.
   */
  public int opApply(int delegate(inout XmlNode) action) {
    int r;
    IXMLDOMNode node = null;

    do {
      mapImpl_.nextNode(node);
      XmlNode currentNode = getNodeShim(node);
      if (currentNode !is null) {
        if ((r = action(currentNode)) != 0)
          break;
      }
    } while (node !is null);

    mapImpl_.reset();

    return r;
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
   * Retrieves the attributes at the specified _index.
   * Params: index = The _index of the attribute.
   */
  public final XmlAttribute opIndex(int index) {
    return cast(XmlAttribute)item(index);
  }

  /**
   * Retrieves the attributes with the specified _name.
   * Params: name = The _name of the attribute.
   */
  public final XmlAttribute opIndex(char[] name) {
    return cast(XmlAttribute)getNamedItem(name);
  }

  /**
   * Retrieves the attributes with the specified local name and namespace URI.
   * Params: 
   *        localName = The local name of the attribute.
   *        namespaceURI = The namespace URI of the attribute.
   */
  public final XmlAttribute opIndex(char[] localName, char[] namespaceURI) {
    return cast(XmlAttribute)getNamedItem(localName, namespaceURI);
  }

  package this(XmlNode parent) {
    super(parent);
  }

}

private class XmlChildNodeList : XmlNodeList {

  private IXMLDOMNodeList nodeList_;

  ~this() {
    if (nodeList_ !is null) {
      nodeList_.Release();
      nodeList_ = null;
    }
  }

  public override XmlNode item(int index) {
    IXMLDOMNode node;
    nodeList_.get_item(index, node);
    return getNodeShim(node);
  }

  public override int count() {
    int value;
    nodeList_.get_length(value);
    return value;
  }

  public override int opApply(int delegate(inout XmlNode) action) {
    int r;
    IXMLDOMNode node;

    do {
      nodeList_.nextNode(node);
      if (node !is null) {
        XmlNode curNode = getNodeShim(node);
        if ((r = action(curNode)) != 0)
          break;
      }
    } while (node !is null);

    nodeList_.reset();
    return r;
  }

  package this(XmlNode container) {
    container.nodeImpl_.get_childNodes(nodeList_);
  }

}

private class XPathNodeList : XmlNodeList {

  private bool finished_;
  private XmlNode[] list_;
  private IXMLDOMSelection selection_;

  ~this() {
    list_ = null;
    if (selection_ !is null) {
      selection_.Release();
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

  public override int count() {
    if (!finished_)
      read(int.max);
    return list_.length;
  }

  public override int opApply(int delegate(inout XmlNode) action) {
    int index = -1;

    bool hasNext() {
      index++;
      int n = read(index + 1);
      if (index > n - 1)
        return false;
      return (list_[index] !is null);
    }

    int r;
    while (hasNext()) {
      XmlNode node = list_[index];
      if ((r = action(node)) != 0)
        break;
    }
    return r;
  }

  package this(XmlNode container, char[] expression) {
    // Validate the characters in the XPath expression.
    foreach (c; expression) {
      switch (c) {
        case '[': case ']': case '|': case '#': case '$': case '(': case ')': 
        case '*': case '+': case ',': case '-': case '=': case '@': case '!':
        case '"': case '\'': case '.': case '/': case '<': case '>': case ':':
        case '\0':
          break;
        default:
          if (std.ctype.isdigit(c))
            break;
          if (std.ctype.isalpha(c))
            break;
          throw new XPathException("'" ~ expression ~ "' has an invalid token.");
      }
    }

    wchar* bstr = utf8ToBstr(expression);
    IXMLDOMNodeList nodeList;
    container.nodeImpl_.selectNodes(bstr, nodeList);
    selection_ = com_release_cast!(IXMLDOMSelection)(nodeList);
    freeBstr(bstr);
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
        selection_.Release();
        selection_ = null;
        finished_ = true;
        break;
      }
    }
    return n;
  }

}

/**
 * <a name="XmlNode" />
 * Represents a single node in the XML document.
 *
 * $(MEMBERS)
 * <table width="100%">
 * <tr><td width="20%">$(LINK2 #XmlNode_clone, clone)</td><td>Creates a duplicate of the node.</td></tr>
 * <tr><td>$(LINK2 #XmlNode_cloneNode, cloneNode)</td><td>Creates a duplicate of the node.</td></tr>
 * <tr><td>$(LINK2 #XmlNode_appendChild, appendChild)</td><td>Adds the specified node to the end of the child list of this node.</td></tr>
 * <tr><td>$(LINK2 #XmlNode_prependChild, prependChild)</td><td>Adds the specified node to the beginning of the child list of this node.</td></tr>
 * </table>
 */
public abstract class XmlNode {

  private IXMLDOMNode nodeImpl_;

  /**
   * Creates a duplicate of the node.
   */
  public XmlNode clone() {
    return cloneNode(true);
  }

  /**
   * Creates a duplicate of the node.
   * Params: deep = true to recursively clone the subtree under the node; false to clone only the node itself.
   */
  public abstract XmlNode cloneNode(bool deep) {
    IXMLDOMNode cloneRoot;
    nodeImpl_.cloneNode(cast(com_bool)(deep ? com_true : com_false), cloneRoot);
    return getNodeShim(cloneRoot);
  }

  /**
   * Adds the specified node to the end of the child list of this node.
   * Params: newChild = The node to add.
   * Returns: The added node.
   */
  public XmlNode appendChild(XmlNode newChild) {
    IXMLDOMNode newNode = null;
    nodeImpl_.appendChild(newChild.nodeImpl_, newNode);
    return getNodeShim(newNode);
  }

  /**
   * Adds the specified node to the beginning of the child list of this node.
   * Params: newChild = The node to add.
   * Returns: The added node.
   */
  public XmlNode prependChild(XmlNode newChild) {
    return insertBefore(newChild, firstChild);
  }

  /**
   * Inserts the specified node immediately before the specified reference node.
   * Params:
   *        newChild = The node to insert.
   *        refChild = The node that is the reference node. The newChild is placed before this node.
   * Returns: The inserted node.
   */
  public XmlNode insertBefore(XmlNode newChild, XmlNode refChild) {
    if (refChild is null)
      return appendChild(newChild);

    if (newChild is refChild)
      return newChild;

    VARIANT refNode = .toVariant(refChild.nodeImpl_);
    IXMLDOMNode newNode = null;
    nodeImpl_.insertBefore(newChild.nodeImpl_, refNode, newNode);
    return getNodeShim(newNode);
  }

  /**
   * Inserts the specified node immediately after the specified reference node.
   * Params:
   *        newChild = The node to insert.
   *        refChild = The node that is the reference node. The newChild is placed after this node.
   * Returns: The inserted node.
   */
  public XmlNode insertAfter(XmlNode newChild, XmlNode refChild) {

    if (refChild is null)
      return prependChild(newChild);

    if (newChild is refChild)
      return newChild;

    XmlNode next = refChild.nextSibling;
    if (next !is null)
      return insertBefore(newChild, next);

    return appendChild(newChild);
  }

  /**
   * Replaces one node with another node.
   * Params: 
   *        newChild = The new node to put in the child list.
   *        oldChild = The node to replace in the list.
   * Returns: The node that was replaced.
   */
  public XmlNode replaceChild(XmlNode newChild, XmlNode oldChild) {
    XmlNode next = oldChild.nextSibling;
    removeChild(oldChild);
    insertBefore(newChild, next);
    return oldChild;
  }

  /**
   * Removes the specified child node.
   * Params: oldChild = The node to remove.
   * Returns: The node that was removed.
   */
  public XmlNode removeChild(XmlNode oldChild) {
    IXMLDOMNode oldNode = null;
    nodeImpl_.removeChild(oldChild.nodeImpl_, oldNode);
    return getNodeShim(oldNode);
  }

  /**
   * Removes all the child nodes of the current node.
   */
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

  public final XmlNodeList selectNodes(char[] xpath) {
    return new XPathNodeList(this, xpath);
  }

  /**
   * Selects the first XmlNode that matched the XPath expression.
   * Params: xpath = The XPath expression.
   */
  public final XmlNode selectSingleNode(char[] xpath) {
    XmlNodeList list = selectNodes(xpath);
    if (list !is null && list.count > 0)
      return list[0];
    return null;
  }

  /**
   * <i>Property.</i>
   * Retrieves the type of the node.
   */
  public abstract XmlNodeType nodeType();

  /**
   * Retrieves the namespace _prefix of this node.
   */
  public char[] prefix() {
    wchar* bstr;
    nodeImpl_.get_prefix(bstr);
    return bstrToUtf8(bstr);
  }

  /**
   * <i>Property.</i>
   * Retrieves the local name of the node.
   */
  public char[] localName() {
    wchar* bstr;
    nodeImpl_.get_baseName(bstr);
    return bstrToUtf8(bstr);
  }

  /**
   * <i>Property.</i>
   * Retrieves the qualified name of the node.
   */
  public char[] name() {
    wchar* bstr;
    nodeImpl_.get_nodeName(bstr);
    return bstrToUtf8(bstr);
  }

  /**
   * <i>Property.</i>
   * Retrieves the namespace URI of the node.
   */
  public char[] namespaceURI() {
    wchar* bstr;
    nodeImpl_.get_namespaceURI(bstr);
    return bstrToUtf8(bstr);
  }

  /**
   * Retrieves or assigns the _value of the node.
   */
  public char[] value() {
    return null;
  }
  /**
   * Ditto
   */
  public void value(char[] value) {
  }

  /**
   * Retrieves or assigns the _text content of the node and its child nodes.
   */
  public char[] text() {
    wchar* bstr;
    nodeImpl_.get_text(bstr);
    return bstrToUtf8(bstr);
  }
  /**
   * Ditto
   */
  public void text(char[] value) {
    wchar* bstr = utf8ToBstr(value);
    nodeImpl_.set_text(bstr);
    freeBstr(bstr);
  }

  /**
   * Retrieves the markup representing this node.
   */
  public char[] xml() {
    wchar* bstr;
    nodeImpl_.get_xml(bstr);
    return bstrToUtf8(bstr);
  }

  /** 
   * <i>Property.</i>
   * Retrieves a value indicating whether the node has any child nodes.
   */
  public bool hasChildNodes() {
    com_bool value;
    nodeImpl_.hasChildNodes(value);
    return value == com_true;
  }

  /**
   * <i>Property.</i>
   * Retrieves all the child nodes of the node.
   */
  public XmlNodeList childNodes() {
    return new XmlChildNodeList(this);
  }

  /**
   * <i>Property.</i>
   * Retrieves the first child of the node.
   */
  public XmlNode firstChild() {
    IXMLDOMNode node;
    nodeImpl_.get_firstChild(node);
    return getNodeShim(node);
  }

  /**
   * <i>Property.</i>
   * Retrieves the last child of the node.
   */
  public XmlNode lastChild() {
    IXMLDOMNode node;
    nodeImpl_.get_lastChild(node);
    return getNodeShim(node);
  }

  /**
   * <i>Property.</i>
   * Retrieves the node immediate preceding this node.
   */
  public XmlNode previousSibling() {
    return null;
  }

  /**
   * <i>Property.</i>
   * Retrieves the node immediate following this node.
   */
  public XmlNode nextSibling() {
    return null;
  }

  /**
   * <i>Property.</i>
   * Retrieves the collection of _attributes of this node.
   */
  public XmlAttributeCollection attributes() {
    return null;
  }

  /**
   * <i>Property.</i>
   * Retrieves the parent of this node.
   */
  public XmlNode parentNode() {
    IXMLDOMNode node;
    nodeImpl_.get_parentNode(node);
    return getNodeShim(node);
  }

  /**
   * <i>Property.</i>
   * Retrieves the XmlDocument to which the node belongs.
   */
  public XmlDocument ownerDocument() {
    IXMLDOMDocument doc;
    nodeImpl_.get_ownerDocument(doc);
    return cast(XmlDocument)getNodeShim(doc);
  }

  /**
   * Provides foreach iteration over the child nodes.
   */
  public int opApply(int delegate(inout XmlNode) action) {
    IXMLDOMNodeList nodeList;
    if (nodeImpl_.get_childNodes(nodeList) != S_OK)
      return 0;

    int r;
    IXMLDOMNode node;

    do {
      nodeList.nextNode(node);
      if (node !is null) {
        XmlNode curNode = getNodeShim(node);
        if ((r = action(curNode)) != 0)
          break;
      }
    } while (node !is null);

    nodeList.Release();
    return r;
  }

  package this(IXMLDOMNode nodeImpl) {
    nodeImpl_ = nodeImpl;
  }

  ~this() {
    if (nodeImpl_ !is null) {
      nodeImpl_.Release();
      nodeImpl_ = null;
    }
  }

  package IXMLDOMNode nativeNode() {
    return nodeImpl_;
  }

  private static char[] constructQName(char[] prefix, char[] localName) {
    if (prefix.length == 0)
      return localName;
    return prefix ~ ":" ~ localName;
  }

  private static void splitName(char[] name, out char[] prefix, out char[] localName) {
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
public class XmlAttribute : XmlNode {

  private IXMLDOMAttribute attrImpl_;

  public override XmlNodeType nodeType() {
    return XmlNodeType.Attribute;
  }

  public override XmlNode parentNode() {
    return null;
  }

  public override char[] name() {
    wchar* bstr;
    attrImpl_.get_name(bstr);
    return bstrToUtf8(bstr);
  }

  public override char[] value() {
    VARIANT var;
    attrImpl_.get_value(var);
    return var.toString();
  }

  public XmlElement ownerElement() {
    return cast(XmlElement)super.parentNode;
  }

  package this(IXMLDOMNode nodeImpl) {
    super(nodeImpl);
    attrImpl_ = com_cast!(IXMLDOMAttribute)(nodeImpl);
  }

  ~this() {
    if (attrImpl_ !is null) {
      attrImpl_.Release();
      attrImpl_ = null;
    }
  }

}

/**
 * <a name="XmlLinkedNode" />
 * Represents a node with sibling nodes.
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
 * <a name="XmlElement" />
 * Represents an element.
 */
public class XmlElement : XmlLinkedNode {

  private IXMLDOMElement elementImpl_;

  public override XmlNodeType nodeType() {
    return XmlNodeType.Element;
  }

  /**
   * Returns the value for the attribute with the specified _name.
   */
  public char[] getAttribute(char[] name) {
    XmlAttribute attr = getAttributeNode(name);
    if (attr !is null)
      return attr.value;
    return "";
  }

  /**
   * Returns the value for the attribute with the specified local name and namespace URI.
   */
  public char[] getAttribute(char[] localName, char[] namespaceURI) {
    XmlAttribute attr = getAttributeNode(localName, namespaceURI);
    if (attr !is null)
      return attr.value;
    return "";
  }

  /**
   * Returns the attribute with the specified _name.
   */
  public XmlAttribute getAttributeNode(char[] name) {
    if (hasAttributes)
      return attributes[name];
    return null;
  }

  /**
   * Returns the attribute with the specified local name and namespace URI.
   */
  public XmlAttribute getAttributeNode(char[] localName, char[] namespaceURI) {
    if (hasAttributes)
      return attributes[localName, namespaceURI];
    return null;
  }

  /**
   * Determines whether the element has an attribute with the specified _name.
   */
  public bool hasAttribute(char[] name) {
    return getAttributeNode(name) !is null;
  }

  /**
   * Determines whether the element has an attribute with the specified local name and namespace URI.
   */
  public bool hasAttribute(char[] localName, char[] namespaceURI) {
    return getAttributeNode(localName, namespaceURI) !is null;
  }

  /**
   * Sets the _value of the attribute with the specified _name.
   */
  public void setAttribute(char[] name, char[] value) {
    wchar* bstrName = utf8ToBstr(name);
    VARIANT var = value.toVariant();
    clearAfter (var, {
      elementImpl_.setAttribute(bstrName, var);
    });
    freeBstr(bstrName);
  }

  /**
   * Adds the specified attribute.
   */
  public XmlAttribute setAttributeNode(XmlAttribute newAttr) {
    IXMLDOMAttribute attr = null;
    elementImpl_.setAttributeNode(newAttr.attrImpl_, attr);
    return cast(XmlAttribute)getNodeShim(attr);
  }

  /**
   * Removes an attribute with the specified _name.
   */
  public void removeAttribute(char[] name) {
    if (hasAttributes)
      attributes.removeNamedItem(name);
  }

  /**
   * Removes an attribute with the specified local name and namespace URI.
   */
  public void removeAttribute(char[] localName, char[] namespaceURI) {
    if (hasAttributes)
      attributes.removeNamedItem(localName, namespaceURI);
  }

  /**
   * Removes the specified attribute.
   */
  public XmlAttribute removeAttributeNode(XmlAttribute oldAttr) {
    IXMLDOMAttribute attr;
    elementImpl_.removeAttributeNode(oldAttr.attrImpl_, attr);
    return cast(XmlAttribute)getNodeShim(attr);
  }

  /**
   * Removes the attribute specified by the local name and namespace URI.
   */
  public XmlAttribute removeAttributeNode(char[] localName, char[] namespaceURI) {
    if (hasAttributes) {
      XmlAttribute attr = getAttributeNode(localName, namespaceURI);
      removeAttributeNode(attr);
      return attr;
    }
    return null;
  }

  /**
   * Puts all XmlText nodes in the subtree underneath this element into a form where there are no adjacent XmlText nodes.
   */
  public void normalize() {
    elementImpl_.normalize();
  }

  public override XmlAttributeCollection attributes() {
    return new XmlAttributeCollection(this);
  }

  /**
   * Retrieves a value indicating whether the element has any attributes.
   */
  public bool hasAttributes() {
    IXMLDOMNamedNodeMap attrs;
    if (elementImpl_.get_attributes(attrs) == S_OK) {
      int count = 0;
      attrs.get_length(count);
      attrs.Release();
      return count > 0;
    }
    return false;
  }

  package this(IXMLDOMNode nodeImpl) {
    super(nodeImpl);
    elementImpl_ = com_cast!(IXMLDOMElement)(nodeImpl);
  }

  ~this() {
    if (elementImpl_ !is null) {
      elementImpl_.Release();
      elementImpl_ = null;
    }
  }

}

/**
 * Provides text manipulation methods used by several classes.
 */
public abstract class XmlCharacterData : XmlLinkedNode {

  private IXMLDOMCharacterData characterDataImpl_;

  /**
   * Appends the specified string to the end of the character _data.
   */
  public void appendData(char[] data) {
    wchar* bstr = utf8ToBstr(data);
    characterDataImpl_.appendData(bstr);
    freeBstr(bstr);
  }

  /**
   * Removes a range of characters from the node.
   */
  public void deleteData(int offset, int count) {
    characterDataImpl_.deleteData(offset, count);
  }

  /**
   * Inserts the specified string at the specified character _offset.
   */
  public void insertData(int offset, char[] data) {
    wchar* bstr = utf8ToBstr(data);
    characterDataImpl_.insertData(offset, bstr);
    freeBstr(bstr);
  }

  /**
   * Replaces the specified number of characters starting at the specified _offset with the specified string.
   */
  public void replaceData(int offset, int count, char[] data) {
    wchar* bstr = utf8ToBstr(data);
   characterDataImpl_.replaceData(offset, count, bstr);
    freeBstr(bstr);
  }

  /**
   * Returns a _substring of the full string from the specified range.
   */
  public char[] substring(int offset, int count) {
    wchar* bstr;
    characterDataImpl_.substringData(offset, count, bstr);
    return bstrToUtf8(bstr);
  }

  /**
   * Retrieves or assigns the _data of the node.
   */
  public char[] data() {
    wchar* bstr;
    characterDataImpl_.get_data(bstr);
    return bstrToUtf8(bstr);
  }
  /**
   * Ditto
   */
  public void data(char[] value) {
    wchar* bstr = utf8ToBstr(value);
    characterDataImpl_.set_data(bstr);
    freeBstr(bstr);
  }

  /**
   * Retrieves _length of the data.
   */
  public int length() {
    int value = 0;
    characterDataImpl_.get_length(value);
    return value;
  }

  public override char[] value() {
    VARIANT var;
    characterDataImpl_.get_nodeValue(var);
    return var.toString();
  }
  public override void value(char[] value) {
    VARIANT var = value.toVariant();
    clearAfter (var, {
      characterDataImpl_.set_nodeValue(var);
    });
  }

  package this(IXMLDOMNode nodeImpl) {
    super(nodeImpl);
    characterDataImpl_ = com_cast!(IXMLDOMCharacterData)(nodeImpl);
  }

  ~this() {
    if (characterDataImpl_ !is null) {
      characterDataImpl_.Release();
      characterDataImpl_ = null;
    }
  }

}

/**
 * Represents a CDATA section.
 */
public class XmlCDataSection : XmlCharacterData {

  public override XmlNodeType nodeType() {
    return XmlNodeType.CDATA;
  }

  package this(IXMLDOMNode nodeImpl) {
    super(nodeImpl);
  }

}

/**
 * Represents an XML comment.
 */
public class XmlComment : XmlCharacterData {

  public override XmlNodeType nodeType() {
    return XmlNodeType.Comment;
  }

  package this(IXMLDOMNode nodeImpl) {
    super(nodeImpl);
  }

}

/**
 * Represents the text content of an element or attribute.
 */
public class XmlText : XmlCharacterData {

  private IXMLDOMText textImpl_;

  public override XmlNodeType nodeType() {
    return XmlNodeType.Text;
  }

  /**
   * Splits the node into two nodes at the specified _offset, keeping both in the tree as siblings.
   */
  public XmlText splitText(int offset) {
    IXMLDOMText rightHandNode = null;
    textImpl_.splitText(offset, rightHandNode);
    return cast(XmlText)getNodeShim(rightHandNode);
  }

  package this(IXMLDOMNode nodeImpl) {
    super(nodeImpl);
    textImpl_ = com_cast!(IXMLDOMText)(nodeImpl);
  }

  ~this() {
    if (textImpl_ !is null) {
      textImpl_.Release();
      textImpl_ = null;
    }
  }

}

/**
 * Represents an entity declaration, such as &lt;!ENTITY...&gt;.
 */
public class XmlEntity : XmlNode {

  private IXMLDOMEntity entityImpl_;

  /**
   * Retrieves the value of the public identifier of the entity declaration.
   */
  public final char[] publicId() {
    VARIANT var;
    entityImpl_.get_publicId(var);
    return var.toString();
  }

  /**
   * Retrieves the value of the system identifier of the entity declaration.
   */
  public final char[] systemId() {
    VARIANT var;
    entityImpl_.get_systemId(var);
    return var.toString();
  }

  /**
   * Retrieves the name of the NDATA attribute.
   */
  public final char[] notationName() {
    wchar* bstr;
    entityImpl_.get_notationName(bstr);
    return bstrToUtf8(bstr);
  }

  public override XmlNodeType nodeType() {
    return XmlNodeType.Entity;
  }

  public override char[] localName() {
    return name;
  }

  public override char[] text() {
    return super.text;
  }
  public override void text(char[] value) {
    throw new InvalidOperationException("The 'text' of an 'Entity' node is read-only.");
  }

  public override char[] xml() {
    return "";
  }

  package this(IXMLDOMNode nodeImpl) {
    super(nodeImpl);
    entityImpl_ = com_cast!(IXMLDOMEntity)(nodeImpl);
  }

  ~this() {
    if (entityImpl_ !is null) {
      entityImpl_.Release();
      entityImpl_ = null;
    }
  }

}

/**
 * Represents an entity reference node.
 */
public class XmlEntityReference : XmlLinkedNode {

  public override XmlNodeType nodeType() {
    return XmlNodeType.EntityReference;
  }

  public override char[] value() {
    return null;
  }
  public override void value(char[] value) {
    throw new InvalidOperationException("'EntityReference' nodes do not support setting value.");
  }

  package this(IXMLDOMNode nodeImpl) {
    super(nodeImpl);
  }

}

/**
 * Represents a notation declaration, such as &lt;!NOTATION...&gt;.
 */
public class XmlNotation : XmlNode {

  private IXMLDOMNotation notationImpl_;

  /**
   * Retrieves the value of the public identifier on the notation declaration.
   */
  public final char[] publicId() {
    VARIANT var;
    notationImpl_.get_publicId(var);
    return var.toString();
  }

  /**
   * Retrieves the value of the system identifier on the notation declaration.
   */
  public final char[] systemId() {
    VARIANT var;
    notationImpl_.get_systemId(var);
    return var.toString();
  }

  public override XmlNodeType nodeType() {
    return XmlNodeType.Notation;
  }

  public override char[] xml() {
    return "";
  }

  package this(IXMLDOMNode nodeImpl) {
    super(nodeImpl);
    notationImpl_ = com_cast!(IXMLDOMNotation)(nodeImpl);
  }

  ~this() {
    if (notationImpl_ !is null) {
      notationImpl_.Release();
      notationImpl_ = null;
    }
  }

}

/**
 * Represents a processing instruction, which keeps processor-specific information in the text of the document.
 */
public class XmlProcessingInstruction : XmlLinkedNode {

  private IXMLDOMProcessingInstruction piImpl_;

  public override XmlNodeType nodeType() {
    return XmlNodeType.ProcessingInstruction;
  }

  /**
   * Retrieves or assigns the content of the processing instruction, exclusing the target.
   */
  public final char[] data() {
    wchar* bstr;
    piImpl_.get_data(bstr);
    return bstrToUtf8(bstr);
  }
  /**
   * Ditto
   */
  public final void data(char[] value) {
    wchar* bstr = utf8ToBstr(value);
    piImpl_.set_data(bstr);
    freeBstr(bstr);
  }

  /**
   * Retrieves the _target of the processing instruction.
   */
  public final char[] target() {
    wchar* bstr;
    piImpl_.get_target(bstr);
    return bstrToUtf8(bstr);
  }

  package this(IXMLDOMNode nodeImpl) {
    super(nodeImpl);
    piImpl_ = com_cast!(IXMLDOMProcessingInstruction)(nodeImpl);
  }

  ~this() {
    if (piImpl_ !is null) {
      tryRelease(piImpl_);
      piImpl_ = null;
    }
  }

}

/**
 * Represents the document type declaration.
 */
public class XmlDocumentType : XmlLinkedNode {

  private IXMLDOMDocumentType doctypeImpl_;

  public override XmlNodeType nodeType() {
    return XmlNodeType.DocumentType;
  }

  public override char[] name() {
    wchar* bstr;
    doctypeImpl_.get_name(bstr);
    return bstrToUtf8(bstr);
  }

  public override char[] localName() {
    return name;
  }

  /**
   * <i>Property.</i>
   * Retrieves the collection of XmlEntity nodes declared in the document type declaration.
   */
  public final XmlNamedNodeMap entities() {
    IXMLDOMNamedNodeMap map;
    doctypeImpl_.get_entities(map);
    return new XmlNamedNodeMap(map);
  }

  /**
   * <i>Property.</i>
   * Retrieves the collection of XmlNotation nodes declared in the document type declaration.
   */
  public final XmlNamedNodeMap notations() {
    IXMLDOMNamedNodeMap map;
    doctypeImpl_.get_notations(map);
    return new XmlNamedNodeMap(map);
  }

  package this(IXMLDOMNode nodeImpl) {
    super(nodeImpl);
    doctypeImpl_ = com_cast!(IXMLDOMDocumentType)(nodeImpl);
  }

  ~this() {
    if (doctypeImpl_ !is null) {
      tryRelease(doctypeImpl_);
      doctypeImpl_ = null;
    }
  }

}

/**
 * Represents the XML declaration node &lt;?xml version='1.0'...?&gt;.
 */
public class XmlDeclaration : XmlNode {

  private const char[] VERSION = "1.0";
  private const char[] YES = "yes";
  private const char[] NO = "no";

  private char[] encoding_;
  private char[] standalone_;

  public override XmlNodeType nodeType() {
    return XmlNodeType.XmlDeclaration;
  }

  public override char[] value() {
    return text;
  }
  public override void value(char[] value) {
    text = value;
  }

  /**
   * Retrieves or assigns the _encoding of the XML document.
   */
  public final char[] encoding() {
    return encoding_;
  }
  /**
   * Ditto
   */
  public final void encoding(char[] value) {
    encoding_ = value;
  }

  /**
   * Retrieves or assigns the _standalone attribute.
   */
  public final char[] standalone() {
    return standalone_;
  }
  /**
   * Ditto
   */
  public final void standalone(char[] value) {
    if (value == null || value == YES || value == NO)
      standalone_ = value;
  }

  /**
   * Retrieves the XML version of the document.
   * Returns: This value is always 1.0.
   */
  public final char[] xmlversion() {
    return VERSION;
  }

  package this(IXMLDOMNode nodeImpl) {
    super(nodeImpl);
  }

  package this(char[] xmlversion, char[] encoding, char[] standalone, IXMLDOMNode nodeImpl) {
    if (xmlversion != VERSION)
      throw new ArgumentException("Only XML version 1.0 is supported.");

    this(nodeImpl);
    this.encoding = encoding;
    this.standalone = standalone;
  }

}

/**
 * Represents a lightweight object useful for tree insert operations.
 */
public class XmlDocumentFragment : XmlNode {

  public override XmlNodeType nodeType() {
    return XmlNodeType.DocumentFragment;
  }

  public override XmlDocument ownerDocument() {
    return cast(XmlDocument)super.parentNode;
  }

  public override XmlNode parentNode() {
    return null;
  }

  package this(IXMLDOMNode nodeImpl) {
    super(nodeImpl);
  }

}

/**
 * <a name="XmlDocument" />
 * Represents an XML document.
 */
public class XmlDocument : XmlNode {

  private IXMLDOMDocument2 docImpl_;
  private int msxmlVersion_;

  public this() {
    IXMLDOMDocument2 doc = null;
    try {
      // MSXML 6.0 is the preferred implementation.
      doc = cast(IXMLDOMDocument2)DOMDocument60.coCreate!(IXMLDOMDocument3, true);
      msxmlVersion_ = 6;
    }
    catch (COMException) {
      try {
        // Fallback to MSXML 4.0.
        // According to Microsoft, MSXML 4.0 is only suitable for legacy code, but we'll use it if it's available.
        // Note the missing version 5.0. MSXML 5.0 was only released as part of Office 2003.
        doc = DOMDocument40.coCreate!(IXMLDOMDocument2, true);
        msxmlVersion_ = 4;
      }
      catch (COMException) {
        // Last-chance fallback is to MSXML 3.0.
        // Available natively on all Windows systems since Windows 2000 SP4.
        doc = DOMDocument30.coCreate!(IXMLDOMDocument2, true);
        msxmlVersion_ = 3;
      }
    }

    doc.set_async(com_false);
    doc.set_validateOnParse(com_false);
    if (msxmlVersion_ >= 4)
      doc.setProperty("NewParser", toVariant(true)); // Faster and more reliable, but lacks async support and DTD validation.
    if (msxmlVersion_ < 4) {
      VARIANT var = "XPath".toVariant();
      clearAfter (var, {
        doc.setProperty("SelectionLanguage", var); // In MSXML 3.0, "SelectionLanguage" was "XPattern".
      });
    }
    if (msxmlVersion_ >= 6)
      doc.setProperty("MultipleErrorMessages", toVariant(true)); // Turn on detailed error messages.

    this(doc);
  }

  /**
   * Creates an XmlNode with the specified XmlNodeType, name and namespaceURI.
   * Params:
   *        type = The XmlNodeType of the new node.
   *        name = The qualified _name of the new node.
   *        namespaceURI = The namespace URI of the new node.
   */
  public XmlNode createNode(XmlNodeType type, char[] name, char[] namespaceURI) {
    return createNode(type, "", name, namespaceURI);
  }

  /**
   * Creates an XmlNode with the specified XmlNodeType, prefix, localName and namespaceURI.
   * Params:
   *        type = The XmlNodeType of the new node.
   *        prefix = The _prefix of the new element.
   *        localName = The local name of the new element.
   *        namespaceURI = The namespace URI of the new element.
   */
  public XmlNode createNode(XmlNodeType type, char[] prefix, char[] localName, char[] namespaceURI) {
    switch (type) {
      case XmlNodeType.Text:
        return createTextNode("");
      case XmlNodeType.CDATA:
        return createCDataSection("");
      case XmlNodeType.Comment:
        return createComment("");
      case XmlNodeType.Element:
        if (prefix != null)
          return createElement(prefix, localName, namespaceURI);
        return createElement(localName, namespaceURI);
      case XmlNodeType.Attribute:
        if (prefix != null)
          return createAttribute(prefix, localName, namespaceURI);
        return createAttribute(localName, namespaceURI);
      case XmlNodeType.ProcessingInstruction:
        return createProcessingInstruction(localName, "");
      case XmlNodeType.XmlDeclaration:
        return createXmlDeclaration("1.0", null, null);
      case XmlNodeType.Document:
        return new XmlDocument;
      default:
    }
    throw new ArgumentException;
  }

  /**
   * Creates an XmlCDataSection containing the specified _data.
   * Params: data = The content of the new XmlCDataSection.
   */
  public XmlCDataSection createCDataSection(char[] data) {
    IXMLDOMCDATASection cdata;

    wchar* bstr = utf8ToBstr(data);
    docImpl_.createCDATASection(bstr, cdata);
    freeBstr(bstr);

    return cast(XmlCDataSection)getNodeShim(cdata);
  }

  /**
   * Creates an XmlComment containing the specified _data.
   * Params: data = The content of the new XmlComment.
   */
  public XmlComment createComment(char[] data) {
    IXMLDOMComment comment;

    wchar* bstr = utf8ToBstr(data);
    docImpl_.createComment(bstr, comment);
    freeBstr(bstr);

    return cast(XmlComment)getNodeShim(comment);
  }

  /**
   * Creates an XmlText containing the specified _text.
   * Params: text = The _text of the new XmlText node.
   */
  public XmlText createTextNode(char[] text) {
    IXMLDOMText node;

    wchar* bstr = utf8ToBstr(text);
    docImpl_.createTextNode(bstr, node);
    freeBstr(bstr);

    return cast(XmlText)getNodeShim(node);
  }

  /**
   * Creates an XmlAttribute with the specified name.
   * Params: name = The qualified _name of the new attribute.
   */
  public XmlAttribute createAttribute(char[] name) {
    char[] prefix, localName;
    XmlNode.splitName(name, prefix, localName);
    return createAttribute(prefix, localName, "");
  }

  /**
   * Creates an XmlAttribute with the qualified _name and namespaceURI.
   * Params:
   *        qualifiedName = The qualified name of the new attribute.
   *        namespaceURI = The namespace URI of the new attribute.
   */
  public XmlAttribute createAttribute(char[] qualifiedName, char[] namespaceURI) {
    wchar* bstrName = utf8ToBstr(qualifiedName);
    wchar* bstrNs = utf8ToBstr(namespaceURI);

    IXMLDOMNode node;
    docImpl_.createNode(toVariant(DOMNodeType.NODE_ATTRIBUTE), bstrName, bstrNs, node);

    freeBstr(bstrName);
    freeBstr(bstrNs);

    return cast(XmlAttribute)getNodeShim(node);
  }

  /**
   * Creates an XmlAttribute with the specified prefix, localName and namespaceURI.
   * Params:
   *        prefix = The _prefix of the new attribute.
   *        localName = The local name of the new attribute.
   *        namespaceURI = The namespace URI of the new attribute.
   */
  public XmlAttribute createAttribute(char[] prefix, char[] localName, char[] namespaceURI) {
    return createAttribute(XmlNode.constructQName(prefix, localName), namespaceURI);
  }

  /**
   * Creates an XmlElement with the specified name.
   * Params: name = The qualified _name of the new element.
   */
  public XmlElement createElement(char[] name) {
    char[] prefix, localName;
    XmlNode.splitName(name, prefix, localName);
    return createElement(prefix, localName, "");
  }

  /**
   * Creates an XmlElement with the qualified _name and namespaceURI.
   * Params:
   *        qualifiedName = The qualified name of the new element.
   *        namespaceURI = The namespace URI of the new element.
   */
  public XmlElement createElement(char[] qualifiedName, char[] namespaceURI) {
    wchar* bstrName = utf8ToBstr(qualifiedName);
    wchar* bstrNs = utf8ToBstr(namespaceURI);

    IXMLDOMNode node;
    int hr = docImpl_.createNode(toVariant(DOMNodeType.NODE_ELEMENT), bstrName, bstrNs, node);

    freeBstr(bstrName);
    freeBstr(bstrNs);

    return cast(XmlElement)getNodeShim(node);
  }

  /**
   * Creates an XmlElement with the specified prefix, localName and namespaceURI.
   * Params:
   *        prefix = The _prefix of the new element.
   *        localName = The local name of the new element.
   *        namespaceURI = The namespace URI of the new element.
   */
  public XmlElement createElement(char[] prefix, char[] localName, char[] namespaceURI) {
    return createElement(XmlNode.constructQName(prefix, localName), namespaceURI);
  }

  /**
   * Creates an XmlProcessingInstruction with the specified name and _data.
   * Params:
   *        target = The name of the processing instruction.
   *        data = The _data for the processing instruction.
   */
  public XmlProcessingInstruction createProcessingInstruction(char[] target, char[] data) {
    IXMLDOMProcessingInstruction pi;

    wchar* bstrTarget = utf8ToBstr(target);
    wchar* bstrData = utf8ToBstr(data);

    docImpl_.createProcessingInstruction(bstrTarget, bstrData, pi);

    freeBstr(bstrTarget);
    freeBstr(bstrData);

    return cast(XmlProcessingInstruction)getNodeShim(pi);
  }

  /**
   * Creates an XmlDeclaration with the specified values.
   * Params:
   *        xmlversion = The version must be "1.0".
   *        encoding = The value of the _encoding attribute.
   *        standalone = The value must be "yes", "no" or an empty (null) string.
   */
  public XmlDeclaration createXmlDeclaration(char[] xmlversion, char[] encoding, char[] standalone) {
    char[] data = "version=\"" ~ xmlversion ~ "\"";
    if (encoding != null)
      data ~= " encoding=\"" ~ encoding ~ "\"";
    if (standalone != null)
      data ~= " standalone=\"" ~ standalone ~ "\"";

    wchar* bstrTarget = utf8ToBstr("xml");
    wchar* bstrData = utf8ToBstr(data);

    IXMLDOMProcessingInstruction pi;
    docImpl_.createProcessingInstruction(bstrTarget, bstrData, pi);

    freeBstr(bstrTarget);
    freeBstr(bstrData);

    return cast(XmlDeclaration)getNodeShim(pi);
  }

  /**
   * Returns the XmlElement with the specified ID.
   * Params: elementId = The attribute ID to match.
   */
  public XmlElement getElementById(char[] elementId) {
    IXMLDOMNode node;

    wchar* bstr = utf8ToBstr(elementId);
    docImpl_.nodeFromID(bstr, node);
    freeBstr(bstr);

    return cast(XmlElement)getNodeShim(node);
  }

  /**
   * Imports a _node from another document to the current document.
   * Params:
   *        node = The _node to import.
   *        deep = true to perform a _deep clone; otherwise, false.
   * Throws: NotSupportedException if the method is not supported by the underlying MSXML implementation.
   */
  public XmlNode importNode(XmlNode node, bool deep) {
    XmlNode result = null;

    IXMLDOMDocument3 doc = com_cast!(IXMLDOMDocument3)(docImpl_);
    if (doc !is null) {
      releaseAfter (doc, {
        IXMLDOMNode n;
        doc.importNode(node.nodeImpl_, (deep ? com_true : com_false), n);
        result = getNodeShim(n);
      });
    }
    else
      throw new NotSupportedException;

    return result;
  }

  /**
   * Loads the XML document from the specified URL.
   * Params: fileName = URL for the file containing the XML document to _load.
   * Throws: XmlException if there is a _load or parse error in the XML.
   */
  public void load(char[] fileName) {
    com_bool success;

    VARIANT source = fileName.toVariant();
    clearAfter (source, {
      docImpl_.load(source, success);
    });

    if (success != com_true)
      throw parsingException();
  }

  /**
   * Loads the XML document from the specified stream.
   * Params: input = The stream containing the XML document to _load.
   * Throws: XmlException if there is a _load or parse error in the XML.
   */
  public void load(Stream input) {
    com_bool success;

    IStream s = new COMInputStream(input);
    releaseAfter (s, {
      VARIANT source = toVariant(s);
      clearAfter (source, {
        docImpl_.load(source, success);
      });
    });

    if (success != com_true)
      throw parsingException();
  }

  /**
   * Loads the XML document from the specified string.
   * Params: xml = A string containing the XML document to load.
   * Throws: XmlException if there is a _load or parse error in the XML.
   */
  public void loadXml(char[] xml) {
    wchar* bstr = utf8ToBstr(xml);
    com_bool success;
    docImpl_.loadXML(bstr, success);
    freeBstr(bstr);

    if (success != com_true)
      throw parsingException();
  }

  /**
   * Saves the XML document to the specified file.
   * Params: fileName = The location of the file.
   */
  public void save(char[] fileName) {
    VARIANT dest = fileName.toVariant();
    clearAfter (dest, {
      docImpl_.save(dest);
    });
  }

  /**
   * Saves the XML document to the specified stream.
   * Params: output = The stream to _save to.
   */
  public void save(Stream output) {
    IStream s = new COMOutputStream(output);
    releaseAfter (s, {
      VARIANT dest = toVariant(s);
      clearAfter (dest, {
        docImpl_.save(dest);
      });
    });
  }

  public override XmlNodeType nodeType() {
    return XmlNodeType.Document;
  }

  public override char[] localName() {
    return name;
  }

  public override XmlNode parentNode() {
    return null;
  }

  public override XmlDocument ownerDocument() {
    return null;
  }

  /**
   * <i>Property.</i>
   * Retrieves the root XmlElement for the document.
   */
  public final XmlElement documentElement() {
    IXMLDOMElement element;
    docImpl_.get_documentElement(element);
    return cast(XmlElement)getNodeShim(element);
  }

  /**
   * <i>Property.</i>
   * Retrieves or assigns a value indicating whether to preserve white space in element content.
   */
  public final bool preserveWhitespace() {
    com_bool value;
    docImpl_.get_preserveWhiteSpace(value);
    return value == com_true;
  }
  /**
   * Ditto
   */
  public final void preserveWhitespace(bool value) {
    docImpl_.set_preserveWhiteSpace(value ? com_true : com_false);
  }

  package this(IXMLDOMNode nodeImpl) {
    super(nodeImpl);
    // Keep a reference to the IXMLDOMDocument2 to save on QI casts.
    docImpl_ = com_cast!(IXMLDOMDocument2)(nodeImpl);
  }

  ~this() {
    if (docImpl_ !is null) {
      tryRelease(docImpl_);
      docImpl_ = null;
    }
  }

  private XmlException parsingException() {
    IXMLDOMParseError parseError;
    docImpl_.get_parseError(parseError);

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

    return new XmlException(reason, lineNumber, linePosition, sourceUri);
  }

}
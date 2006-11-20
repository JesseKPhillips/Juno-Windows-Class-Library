// Microsoft XML, v6.0
// Version 6.0

/*[uuid("f5078f18-c551-11d3-89b9-0000f81fe221")]*/
module juno.xml.msxml;

/*[importlib("stdole2.tlb")];*/

private import juno.com.core;

// Enums

// Constants that define a node's type
enum tagDOMNodeType {
  NODE_INVALID = 0x00000000,
  NODE_ELEMENT = 0x00000001,
  NODE_ATTRIBUTE = 0x00000002,
  NODE_TEXT = 0x00000003,
  NODE_CDATA_SECTION = 0x00000004,
  NODE_ENTITY_REFERENCE = 0x00000005,
  NODE_ENTITY = 0x00000006,
  NODE_PROCESSING_INSTRUCTION = 0x00000007,
  NODE_COMMENT = 0x00000008,
  NODE_DOCUMENT = 0x00000009,
  NODE_DOCUMENT_TYPE = 0x0000000a,
  NODE_DOCUMENT_FRAGMENT = 0x0000000b,
  NODE_NOTATION = 0x0000000c,
}

// Schema Object Model Item Types
enum _SOMITEMTYPE {
  SOMITEM_SCHEMA = 0x00001000,
  SOMITEM_ATTRIBUTE = 0x00001001,
  SOMITEM_ATTRIBUTEGROUP = 0x00001002,
  SOMITEM_NOTATION = 0x00001003,
  SOMITEM_ANNOTATION = 0x00001004,
  SOMITEM_IDENTITYCONSTRAINT = 0x00001100,
  SOMITEM_KEY = 0x00001101,
  SOMITEM_KEYREF = 0x00001102,
  SOMITEM_UNIQUE = 0x00001103,
  SOMITEM_ANYTYPE = 0x00002000,
  SOMITEM_DATATYPE = 0x00002100,
  SOMITEM_DATATYPE_ANYTYPE = 0x00002101,
  SOMITEM_DATATYPE_ANYURI = 0x00002102,
  SOMITEM_DATATYPE_BASE64BINARY = 0x00002103,
  SOMITEM_DATATYPE_BOOLEAN = 0x00002104,
  SOMITEM_DATATYPE_BYTE = 0x00002105,
  SOMITEM_DATATYPE_DATE = 0x00002106,
  SOMITEM_DATATYPE_DATETIME = 0x00002107,
  SOMITEM_DATATYPE_DAY = 0x00002108,
  SOMITEM_DATATYPE_DECIMAL = 0x00002109,
  SOMITEM_DATATYPE_DOUBLE = 0x0000210a,
  SOMITEM_DATATYPE_DURATION = 0x0000210b,
  SOMITEM_DATATYPE_ENTITIES = 0x0000210c,
  SOMITEM_DATATYPE_ENTITY = 0x0000210d,
  SOMITEM_DATATYPE_FLOAT = 0x0000210e,
  SOMITEM_DATATYPE_HEXBINARY = 0x0000210f,
  SOMITEM_DATATYPE_ID = 0x00002110,
  SOMITEM_DATATYPE_IDREF = 0x00002111,
  SOMITEM_DATATYPE_IDREFS = 0x00002112,
  SOMITEM_DATATYPE_INT = 0x00002113,
  SOMITEM_DATATYPE_INTEGER = 0x00002114,
  SOMITEM_DATATYPE_LANGUAGE = 0x00002115,
  SOMITEM_DATATYPE_LONG = 0x00002116,
  SOMITEM_DATATYPE_MONTH = 0x00002117,
  SOMITEM_DATATYPE_MONTHDAY = 0x00002118,
  SOMITEM_DATATYPE_NAME = 0x00002119,
  SOMITEM_DATATYPE_NCNAME = 0x0000211a,
  SOMITEM_DATATYPE_NEGATIVEINTEGER = 0x0000211b,
  SOMITEM_DATATYPE_NMTOKEN = 0x0000211c,
  SOMITEM_DATATYPE_NMTOKENS = 0x0000211d,
  SOMITEM_DATATYPE_NONNEGATIVEINTEGER = 0x0000211e,
  SOMITEM_DATATYPE_NONPOSITIVEINTEGER = 0x0000211f,
  SOMITEM_DATATYPE_NORMALIZEDSTRING = 0x00002120,
  SOMITEM_DATATYPE_NOTATION = 0x00002121,
  SOMITEM_DATATYPE_POSITIVEINTEGER = 0x00002122,
  SOMITEM_DATATYPE_QNAME = 0x00002123,
  SOMITEM_DATATYPE_SHORT = 0x00002124,
  SOMITEM_DATATYPE_STRING = 0x00002125,
  SOMITEM_DATATYPE_TIME = 0x00002126,
  SOMITEM_DATATYPE_TOKEN = 0x00002127,
  SOMITEM_DATATYPE_UNSIGNEDBYTE = 0x00002128,
  SOMITEM_DATATYPE_UNSIGNEDINT = 0x00002129,
  SOMITEM_DATATYPE_UNSIGNEDLONG = 0x0000212a,
  SOMITEM_DATATYPE_UNSIGNEDSHORT = 0x0000212b,
  SOMITEM_DATATYPE_YEAR = 0x0000212c,
  SOMITEM_DATATYPE_YEARMONTH = 0x0000212d,
  SOMITEM_DATATYPE_ANYSIMPLETYPE = 0x000021ff,
  SOMITEM_SIMPLETYPE = 0x00002200,
  SOMITEM_COMPLEXTYPE = 0x00002400,
  SOMITEM_PARTICLE = 0x00004000,
  SOMITEM_ANY = 0x00004001,
  SOMITEM_ANYATTRIBUTE = 0x00004002,
  SOMITEM_ELEMENT = 0x00004003,
  SOMITEM_GROUP = 0x00004100,
  SOMITEM_ALL = 0x00004101,
  SOMITEM_CHOICE = 0x00004102,
  SOMITEM_SEQUENCE = 0x00004103,
  SOMITEM_EMPTYPARTICLE = 0x00004104,
  SOMITEM_NULL = 0x00000800,
  SOMITEM_NULL_TYPE = 0x00002800,
  SOMITEM_NULL_ANY = 0x00004801,
  SOMITEM_NULL_ANYATTRIBUTE = 0x00004802,
  SOMITEM_NULL_ELEMENT = 0x00004803,
}

// Schema Object Model Filters
enum _SCHEMADERIVATIONMETHOD {
  SCHEMADERIVATIONMETHOD_EMPTY = 0x00000000,
  SCHEMADERIVATIONMETHOD_SUBSTITUTION = 0x00000001,
  SCHEMADERIVATIONMETHOD_EXTENSION = 0x00000002,
  SCHEMADERIVATIONMETHOD_RESTRICTION = 0x00000004,
  SCHEMADERIVATIONMETHOD_LIST = 0x00000008,
  SCHEMADERIVATIONMETHOD_UNION = 0x00000010,
  SCHEMADERIVATIONMETHOD_ALL = 0x000000ff,
  SCHEMADERIVATIONMETHOD_NONE = 0x00000100,
}

// Schema Object Model Type variety values
enum _SCHEMATYPEVARIETY {
  SCHEMATYPEVARIETY_NONE = -1,
  SCHEMATYPEVARIETY_ATOMIC = 0x00000000,
  SCHEMATYPEVARIETY_LIST = 0x00000001,
  SCHEMATYPEVARIETY_UNION = 0x00000002,
}

// Schema Object Model Whitespace facet values
enum _SCHEMAWHITESPACE {
  SCHEMAWHITESPACE_NONE = -1,
  SCHEMAWHITESPACE_PRESERVE = 0x00000000,
  SCHEMAWHITESPACE_REPLACE = 0x00000001,
  SCHEMAWHITESPACE_COLLAPSE = 0x00000002,
}

// Schema Object Model Process Contents
enum _SCHEMAPROCESSCONTENTS {
  SCHEMAPROCESSCONTENTS_NONE = 0x00000000,
  SCHEMAPROCESSCONTENTS_SKIP = 0x00000001,
  SCHEMAPROCESSCONTENTS_LAX = 0x00000002,
  SCHEMAPROCESSCONTENTS_STRICT = 0x00000003,
}

// Schema Object Model Content Types
enum _SCHEMACONTENTTYPE {
  SCHEMACONTENTTYPE_EMPTY = 0x00000000,
  SCHEMACONTENTTYPE_TEXTONLY = 0x00000001,
  SCHEMACONTENTTYPE_ELEMENTONLY = 0x00000002,
  SCHEMACONTENTTYPE_MIXED = 0x00000003,
}

// Schema Object Model Attribute Uses
enum _SCHEMAUSE {
  SCHEMAUSE_OPTIONAL = 0x00000000,
  SCHEMAUSE_PROHIBITED = 0x00000001,
  SCHEMAUSE_REQUIRED = 0x00000002,
}

// Options for ServerXMLHTTPRequest Option property
enum _SERVERXMLHTTP_OPTION {
  SXH_OPTION_URL = -1,
  SXH_OPTION_URL_CODEPAGE = 0x00000000,
  SXH_OPTION_ESCAPE_PERCENT_IN_URL = 0x00000001,
  SXH_OPTION_IGNORE_SERVER_SSL_CERT_ERROR_FLAGS = 0x00000002,
  SXH_OPTION_SELECT_CLIENT_SSL_CERT = 0x00000003,
}

// Flags for SXH_OPTION_IGNORE_SERVER_SSL_CERT_ERROR_FLAGS option
enum _SXH_SERVER_CERT_OPTION {
  SXH_SERVER_CERT_IGNORE_UNKNOWN_CA = 0x00000100,
  SXH_SERVER_CERT_IGNORE_WRONG_USAGE = 0x00000200,
  SXH_SERVER_CERT_IGNORE_CERT_CN_INVALID = 0x00001000,
  SXH_SERVER_CERT_IGNORE_CERT_DATE_INVALID = 0x00002000,
  SXH_SERVER_CERT_IGNORE_ALL_SERVER_ERRORS = 0x00003300,
}

// Settings for setProxy
enum _SXH_PROXY_SETTING {
  SXH_PROXY_SET_DEFAULT = 0x00000000,
  SXH_PROXY_SET_PRECONFIG = 0x00000000,
  SXH_PROXY_SET_DIRECT = 0x00000001,
  SXH_PROXY_SET_PROXY = 0x00000002,
}

// Aliases

// Constants that define a node's type
alias tagDOMNodeType DOMNodeType;

// Schema Object Model Item Types
alias _SOMITEMTYPE SOMITEMTYPE;

// Schema Object Model Filters
alias _SCHEMADERIVATIONMETHOD SCHEMADERIVATIONMETHOD;

// Schema Object Model Type variety values
alias _SCHEMATYPEVARIETY SCHEMATYPEVARIETY;

// Schema Object Model Whitespace facet values
alias _SCHEMAWHITESPACE SCHEMAWHITESPACE;

// Schema Object Model Process Contents
alias _SCHEMAPROCESSCONTENTS SCHEMAPROCESSCONTENTS;

// Schema Object Model Content Types
alias _SCHEMACONTENTTYPE SCHEMACONTENTTYPE;

// Schema Object Model Attribute Uses
alias _SCHEMAUSE SCHEMAUSE;

// Options for ServerXMLHTTPRequest Option property
alias _SERVERXMLHTTP_OPTION SERVERXMLHTTP_OPTION;

// Flags for SXH_OPTION_IGNORE_SERVER_SSL_CERT_ERROR_FLAGS option
alias _SXH_SERVER_CERT_OPTION SXH_SERVER_CERT_OPTION;

// Settings for setProxy
alias _SXH_PROXY_SETTING SXH_PROXY_SETTING;

// Interfaces

interface IXMLDOMImplementation : IDispatch {
  /*[uuid("2933bf8f-7b36-11d2-b20e-00c04f983e60")]*/
  static GUID IID = { 0x2933bf8f, 0x7b36, 0x11d2, 0xb2, 0x0e, 0x00, 0xc0, 0x4f, 0x98, 0x3e, 0x60 };
  /*[id(0x00000091)]*/ int hasFeature(in wchar* feature, in wchar* versionParam, out short hasFeature);
}

// Core DOM node interface
interface IXMLDOMNode : IDispatch {
  /*[uuid("2933bf80-7b36-11d2-b20e-00c04f983e60")]*/
  static GUID IID = { 0x2933bf80, 0x7b36, 0x11d2, 0xb2, 0x0e, 0x00, 0xc0, 0x4f, 0x98, 0x3e, 0x60 };
  // name of the node
  /*[id(0x00000002)]*/ int get_nodeName(out wchar* name);
  // value stored in the node
  /*[id(0x00000003)]*/ int get_nodeValue(out VARIANT value);
  // value stored in the node
  /*[id(0x00000003)]*/ int set_nodeValue(in VARIANT value);
  // the node's type
  /*[id(0x00000004)]*/ int get_nodeType(out DOMNodeType type);
  // parent of the node
  /*[id(0x00000006)]*/ int get_parentNode(out IXMLDOMNode parent);
  // the collection of the node's children
  /*[id(0x00000007)]*/ int get_childNodes(out IXMLDOMNodeList childList);
  // first child of the node
  /*[id(0x00000008)]*/ int get_firstChild(out IXMLDOMNode firstChild);
  // last child of the node
  /*[id(0x00000009)]*/ int get_lastChild(out IXMLDOMNode lastChild);
  // left sibling of the node
  /*[id(0x0000000a)]*/ int get_previousSibling(out IXMLDOMNode previousSibling);
  // right sibling of the node
  /*[id(0x0000000b)]*/ int get_nextSibling(out IXMLDOMNode nextSibling);
  // the collection of the node's attributes
  /*[id(0x0000000c)]*/ int get_attributes(out IXMLDOMNamedNodeMap attributeMap);
  // insert a child node
  /*[id(0x0000000d)]*/ int insertBefore(in IXMLDOMNode newChild, in VARIANT refChild, out IXMLDOMNode outNewChild);
  // replace a child node
  /*[id(0x0000000e)]*/ int replaceChild(in IXMLDOMNode newChild, in IXMLDOMNode oldChild, out IXMLDOMNode outOldChild);
  // remove a child node
  /*[id(0x0000000f)]*/ int removeChild(in IXMLDOMNode childNode, out IXMLDOMNode oldChild);
  // append a child node
  /*[id(0x00000010)]*/ int appendChild(in IXMLDOMNode newChild, out IXMLDOMNode outNewChild);
  /*[id(0x00000011)]*/ int hasChildNodes(out short hasChild);
  // document that contains the node
  /*[id(0x00000012)]*/ int get_ownerDocument(out IXMLDOMDocument DOMDocument);
  /*[id(0x00000013)]*/ int cloneNode(in short deep, out IXMLDOMNode cloneRoot);
  // the type of node in string form
  /*[id(0x00000015)]*/ int get_nodeTypeString(out wchar* nodeType);
  // text content of the node and subtree
  /*[id(0x00000018)]*/ int get_text(out wchar* text);
  // text content of the node and subtree
  /*[id(0x00000018)]*/ int set_text(in wchar* value);
  // indicates whether node is a default value
  /*[id(0x00000016)]*/ int get_specified(out short isSpecified);
  // pointer to the definition of the node in the DTD or schema
  /*[id(0x00000017)]*/ int get_definition(out IXMLDOMNode definitionNode);
  // get the strongly typed value of the node
  /*[id(0x00000019)]*/ int get_nodeTypedValue(out VARIANT typedValue);
  // get the strongly typed value of the node
  /*[id(0x00000019)]*/ int set_nodeTypedValue(in VARIANT value);
  // the data type of the node
  /*[id(0x0000001a)]*/ int get_dataType(out VARIANT dataTypeName);
  // the data type of the node
  /*[id(0x0000001a)]*/ int set_dataType(in wchar* value);
  // return the XML source for the node and each of its descendants
  /*[id(0x0000001b)]*/ int get_xml(out wchar* xmlString);
  // apply the stylesheet to the subtree
  /*[id(0x0000001c)]*/ int transformNode(in IXMLDOMNode stylesheet, out wchar* xmlString);
  // execute query on the subtree
  /*[id(0x0000001d)]*/ int selectNodes(in wchar* queryString, out IXMLDOMNodeList resultList);
  // execute query on the subtree
  /*[id(0x0000001e)]*/ int selectSingleNode(in wchar* queryString, out IXMLDOMNode resultNode);
  // has sub-tree been completely parsed
  /*[id(0x0000001f)]*/ int get_parsed(out short isParsed);
  // the URI for the namespace applying to the node
  /*[id(0x00000020)]*/ int get_namespaceURI(out wchar* namespaceURI);
  // the prefix for the namespace applying to the node
  /*[id(0x00000021)]*/ int get_prefix(out wchar* prefixString);
  // the base name of the node (nodename with the prefix stripped off)
  /*[id(0x00000022)]*/ int get_baseName(out wchar* nameString);
  // apply the stylesheet to the subtree, returning the result through a document or a stream
  /*[id(0x00000023)]*/ int transformNodeToObject(in IXMLDOMNode stylesheet, in VARIANT outputObject);
}

interface IXMLDOMNodeList : IDispatch {
  /*[uuid("2933bf82-7b36-11d2-b20e-00c04f983e60")]*/
  static GUID IID = { 0x2933bf82, 0x7b36, 0x11d2, 0xb2, 0x0e, 0x00, 0xc0, 0x4f, 0x98, 0x3e, 0x60 };
  // collection of nodes
  /*[id(0x00000000)]*/ int get_item(in int index, out IXMLDOMNode listItem);
  // number of nodes in the collection
  /*[id(0x0000004a)]*/ int get_length(out int listLength);
  // get next node from iterator
  /*[id(0x0000004c)]*/ int nextNode(out IXMLDOMNode nextItem);
  // reset the position of iterator
  /*[id(0x0000004d)]*/ int reset();
  /*[id(0xfffffffc)]*/ int get__newEnum(out IUnknown ppUnk);
}

interface IXMLDOMNamedNodeMap : IDispatch {
  /*[uuid("2933bf83-7b36-11d2-b20e-00c04f983e60")]*/
  static GUID IID = { 0x2933bf83, 0x7b36, 0x11d2, 0xb2, 0x0e, 0x00, 0xc0, 0x4f, 0x98, 0x3e, 0x60 };
  // lookup item by name
  /*[id(0x00000053)]*/ int getNamedItem(in wchar* name, out IXMLDOMNode namedItem);
  // set item by name
  /*[id(0x00000054)]*/ int setNamedItem(in IXMLDOMNode newItem, out IXMLDOMNode nameItem);
  // remove item by name
  /*[id(0x00000055)]*/ int removeNamedItem(in wchar* name, out IXMLDOMNode namedItem);
  // collection of nodes
  /*[id(0x00000000)]*/ int get_item(in int index, out IXMLDOMNode listItem);
  // number of nodes in the collection
  /*[id(0x0000004a)]*/ int get_length(out int listLength);
  // lookup the item by name and namespace
  /*[id(0x00000057)]*/ int getQualifiedItem(in wchar* baseName, in wchar* namespaceURI, out IXMLDOMNode qualifiedItem);
  // remove the item by name and namespace
  /*[id(0x00000058)]*/ int removeQualifiedItem(in wchar* baseName, in wchar* namespaceURI, out IXMLDOMNode qualifiedItem);
  // get next node from iterator
  /*[id(0x00000059)]*/ int nextNode(out IXMLDOMNode nextItem);
  // reset the position of iterator
  /*[id(0x0000005a)]*/ int reset();
  /*[id(0xfffffffc)]*/ int get__newEnum(out IUnknown ppUnk);
}

interface IXMLDOMDocument : IXMLDOMNode {
  /*[uuid("2933bf81-7b36-11d2-b20e-00c04f983e60")]*/
  static GUID IID = { 0x2933bf81, 0x7b36, 0x11d2, 0xb2, 0x0e, 0x00, 0xc0, 0x4f, 0x98, 0x3e, 0x60 };
  // node corresponding to the DOCTYPE
  /*[id(0x00000026)]*/ int get_doctype(out IXMLDOMDocumentType documentType);
  // info on this DOM implementation
  /*[id(0x00000027)]*/ int get_implementation(out IXMLDOMImplementation impl);
  // the root of the tree
  /*[id(0x00000028)]*/ int get_documentElement(out IXMLDOMElement DOMElement);
  // the root of the tree
  /*[id(0x00000028)]*/ int setref_documentElement(in IXMLDOMElement value);
  // create an Element node
  /*[id(0x00000029)]*/ int createElement(in wchar* tagName, out IXMLDOMElement element);
  // create a DocumentFragment node
  /*[id(0x0000002a)]*/ int createDocumentFragment(out IXMLDOMDocumentFragment docFrag);
  // create a text node
  /*[id(0x0000002b)]*/ int createTextNode(in wchar* data, out IXMLDOMText text);
  // create a comment node
  /*[id(0x0000002c)]*/ int createComment(in wchar* data, out IXMLDOMComment comment);
  // create a CDATA section node
  /*[id(0x0000002d)]*/ int createCDATASection(in wchar* data, out IXMLDOMCDATASection cdata);
  // create a processing instruction node
  /*[id(0x0000002e)]*/ int createProcessingInstruction(in wchar* target, in wchar* data, out IXMLDOMProcessingInstruction pi);
  // create an attribute node
  /*[id(0x0000002f)]*/ int createAttribute(in wchar* name, out IXMLDOMAttribute attribute);
  // create an entity reference node
  /*[id(0x00000031)]*/ int createEntityReference(in wchar* name, out IXMLDOMEntityReference entityRef);
  // build a list of elements by name
  /*[id(0x00000032)]*/ int getElementsByTagName(in wchar* tagName, out IXMLDOMNodeList resultList);
  // create a node of the specified node type and name
  /*[id(0x00000036)]*/ int createNode(in VARIANT type, in wchar* name, in wchar* namespaceURI, out IXMLDOMNode node);
  // retrieve node from it's ID
  /*[id(0x00000038)]*/ int nodeFromID(in wchar* idString, out IXMLDOMNode node);
  // load document from the specified XML source
  /*[id(0x0000003a)]*/ int load(in VARIANT xmlSource, out short isSuccessful);
  // get the state of the XML document
  /*[id(0xfffffdf3)]*/ int get_readyState(out int value);
  // get the last parser error
  /*[id(0x0000003b)]*/ int get_parseError(out IXMLDOMParseError errorObj);
  // get the URL for the loaded XML document
  /*[id(0x0000003c)]*/ int get_url(out wchar* urlString);
  // flag for asynchronous download
  /*[id(0x0000003d)]*/ int get_async(out short isAsync);
  // flag for asynchronous download
  /*[id(0x0000003d)]*/ int set_async(in short value);
  // abort an asynchronous download
  /*[id(0x0000003e)]*/ int abort();
  // load the document from a string
  /*[id(0x0000003f)]*/ int loadXML(in wchar* bstrXML, out short isSuccessful);
  // save the document to a specified destination
  /*[id(0x00000040)]*/ int save(in VARIANT destination);
  // indicates whether the parser performs validation
  /*[id(0x00000041)]*/ int get_validateOnParse(out short isValidating);
  // indicates whether the parser performs validation
  /*[id(0x00000041)]*/ int set_validateOnParse(in short value);
  // indicates whether the parser resolves references to external DTD/Entities/Schema
  /*[id(0x00000042)]*/ int get_resolveExternals(out short isResolving);
  // indicates whether the parser resolves references to external DTD/Entities/Schema
  /*[id(0x00000042)]*/ int set_resolveExternals(in short value);
  // indicates whether the parser preserves whitespace
  /*[id(0x00000043)]*/ int get_preserveWhiteSpace(out short isPreserving);
  // indicates whether the parser preserves whitespace
  /*[id(0x00000043)]*/ int set_preserveWhiteSpace(in short value);
  // register a readystatechange event handler
  /*[id(0x00000044)]*/ int set_onreadystatechange(in VARIANT value);
  // register an ondataavailable event handler
  /*[id(0x00000045)]*/ int set_ondataavailable(in VARIANT value);
  // register an ontransformnode event handler
  /*[id(0x00000046)]*/ int set_ontransformnode(in VARIANT value);
}

interface IXMLDOMDocumentType : IXMLDOMNode {
  /*[uuid("2933bf8b-7b36-11d2-b20e-00c04f983e60")]*/
  static GUID IID = { 0x2933bf8b, 0x7b36, 0x11d2, 0xb2, 0x0e, 0x00, 0xc0, 0x4f, 0x98, 0x3e, 0x60 };
  // name of the document type (root of the tree)
  /*[id(0x00000083)]*/ int get_name(out wchar* rootName);
  // a list of entities in the document
  /*[id(0x00000084)]*/ int get_entities(out IXMLDOMNamedNodeMap entityMap);
  // a list of notations in the document
  /*[id(0x00000085)]*/ int get_notations(out IXMLDOMNamedNodeMap notationMap);
}

interface IXMLDOMElement : IXMLDOMNode {
  /*[uuid("2933bf86-7b36-11d2-b20e-00c04f983e60")]*/
  static GUID IID = { 0x2933bf86, 0x7b36, 0x11d2, 0xb2, 0x0e, 0x00, 0xc0, 0x4f, 0x98, 0x3e, 0x60 };
  // get the tagName of the element
  /*[id(0x00000061)]*/ int get_tagName(out wchar* tagName);
  // look up the string value of an attribute by name
  /*[id(0x00000063)]*/ int getAttribute(in wchar* name, out VARIANT value);
  // set the string value of an attribute by name
  /*[id(0x00000064)]*/ int setAttribute(in wchar* name, in VARIANT value);
  // remove an attribute by name
  /*[id(0x00000065)]*/ int removeAttribute(in wchar* name);
  // look up the attribute node by name
  /*[id(0x00000066)]*/ int getAttributeNode(in wchar* name, out IXMLDOMAttribute attributeNode);
  // set the specified attribute on the element
  /*[id(0x00000067)]*/ int setAttributeNode(in IXMLDOMAttribute DOMAttribute, out IXMLDOMAttribute attributeNode);
  // remove the specified attribute
  /*[id(0x00000068)]*/ int removeAttributeNode(in IXMLDOMAttribute DOMAttribute, out IXMLDOMAttribute attributeNode);
  // build a list of elements by name
  /*[id(0x00000069)]*/ int getElementsByTagName(in wchar* tagName, out IXMLDOMNodeList resultList);
  // collapse all adjacent text nodes in sub-tree
  /*[id(0x0000006a)]*/ int normalize();
}

interface IXMLDOMAttribute : IXMLDOMNode {
  /*[uuid("2933bf85-7b36-11d2-b20e-00c04f983e60")]*/
  static GUID IID = { 0x2933bf85, 0x7b36, 0x11d2, 0xb2, 0x0e, 0x00, 0xc0, 0x4f, 0x98, 0x3e, 0x60 };
  // get name of the attribute
  /*[id(0x00000076)]*/ int get_name(out wchar* attributeName);
  // string value of the attribute
  /*[id(0x00000078)]*/ int get_value(out VARIANT attributeValue);
  // string value of the attribute
  /*[id(0x00000078)]*/ int set_value(in VARIANT value);
}

interface IXMLDOMDocumentFragment : IXMLDOMNode {
  /*[uuid("3efaa413-272f-11d2-836f-0000f87a7782")]*/
  static GUID IID = { 0x3efaa413, 0x272f, 0x11d2, 0x83, 0x6f, 0x00, 0x00, 0xf8, 0x7a, 0x77, 0x82 };
}

interface IXMLDOMText : IXMLDOMCharacterData {
  /*[uuid("2933bf87-7b36-11d2-b20e-00c04f983e60")]*/
  static GUID IID = { 0x2933bf87, 0x7b36, 0x11d2, 0xb2, 0x0e, 0x00, 0xc0, 0x4f, 0x98, 0x3e, 0x60 };
  // split the text node into two text nodes at the position specified
  /*[id(0x0000007b)]*/ int splitText(in int offset, out IXMLDOMText rightHandTextNode);
}

interface IXMLDOMCharacterData : IXMLDOMNode {
  /*[uuid("2933bf84-7b36-11d2-b20e-00c04f983e60")]*/
  static GUID IID = { 0x2933bf84, 0x7b36, 0x11d2, 0xb2, 0x0e, 0x00, 0xc0, 0x4f, 0x98, 0x3e, 0x60 };
  // value of the node
  /*[id(0x0000006d)]*/ int get_data(out wchar* data);
  // value of the node
  /*[id(0x0000006d)]*/ int set_data(in wchar* value);
  // number of characters in value
  /*[id(0x0000006e)]*/ int get_length(out int dataLength);
  // retrieve substring of value
  /*[id(0x0000006f)]*/ int substringData(in int offset, in int count, out wchar* data);
  // append string to value
  /*[id(0x00000070)]*/ int appendData(in wchar* data);
  // insert string into value
  /*[id(0x00000071)]*/ int insertData(in int offset, in wchar* data);
  // delete string within the value
  /*[id(0x00000072)]*/ int deleteData(in int offset, in int count);
  // replace string within the value
  /*[id(0x00000073)]*/ int replaceData(in int offset, in int count, in wchar* data);
}

interface IXMLDOMComment : IXMLDOMCharacterData {
  /*[uuid("2933bf88-7b36-11d2-b20e-00c04f983e60")]*/
  static GUID IID = { 0x2933bf88, 0x7b36, 0x11d2, 0xb2, 0x0e, 0x00, 0xc0, 0x4f, 0x98, 0x3e, 0x60 };
}

interface IXMLDOMCDATASection : IXMLDOMText {
  /*[uuid("2933bf8a-7b36-11d2-b20e-00c04f983e60")]*/
  static GUID IID = { 0x2933bf8a, 0x7b36, 0x11d2, 0xb2, 0x0e, 0x00, 0xc0, 0x4f, 0x98, 0x3e, 0x60 };
}

interface IXMLDOMProcessingInstruction : IXMLDOMNode {
  /*[uuid("2933bf89-7b36-11d2-b20e-00c04f983e60")]*/
  static GUID IID = { 0x2933bf89, 0x7b36, 0x11d2, 0xb2, 0x0e, 0x00, 0xc0, 0x4f, 0x98, 0x3e, 0x60 };
  // the target
  /*[id(0x0000007f)]*/ int get_target(out wchar* name);
  // the data
  /*[id(0x00000080)]*/ int get_data(out wchar* value);
  // the data
  /*[id(0x00000080)]*/ int set_data(in wchar* value);
}

interface IXMLDOMEntityReference : IXMLDOMNode {
  /*[uuid("2933bf8e-7b36-11d2-b20e-00c04f983e60")]*/
  static GUID IID = { 0x2933bf8e, 0x7b36, 0x11d2, 0xb2, 0x0e, 0x00, 0xc0, 0x4f, 0x98, 0x3e, 0x60 };
}

// structure for reporting parser errors
interface IXMLDOMParseError : IDispatch {
  /*[uuid("3efaa426-272f-11d2-836f-0000f87a7782")]*/
  static GUID IID = { 0x3efaa426, 0x272f, 0x11d2, 0x83, 0x6f, 0x00, 0x00, 0xf8, 0x7a, 0x77, 0x82 };
  // the error code
  /*[id(0x00000000)]*/ int get_errorCode(out int errorCode);
  // the URL of the XML document containing the error
  /*[id(0x000000b3)]*/ int get_url(out wchar* urlString);
  // the cause of the error
  /*[id(0x000000b4)]*/ int get_reason(out wchar* reasonString);
  // the data where the error occurred
  /*[id(0x000000b5)]*/ int get_srcText(out wchar* sourceString);
  // the line number in the XML document where the error occurred
  /*[id(0x000000b6)]*/ int get_line(out int lineNumber);
  // the character position in the line containing the error
  /*[id(0x000000b7)]*/ int get_linepos(out int linePosition);
  // the absolute file position in the XML document containing the error
  /*[id(0x000000b8)]*/ int get_filepos(out int filePosition);
}

interface IXMLDOMDocument2 : IXMLDOMDocument {
  /*[uuid("2933bf95-7b36-11d2-b20e-00c04f983e60")]*/
  static GUID IID = { 0x2933bf95, 0x7b36, 0x11d2, 0xb2, 0x0e, 0x00, 0xc0, 0x4f, 0x98, 0x3e, 0x60 };
  // A collection of all namespaces for this document
  /*[id(0x000000c9)]*/ int get_namespaces(out IXMLDOMSchemaCollection namespaceCollection);
  // The associated schema cache
  /*[id(0x000000ca)]*/ int get_schemas(out VARIANT otherCollection);
  // The associated schema cache
  /*[id(0x000000ca)]*/ int setref_schemas(in VARIANT value);
  // perform runtime validation on the currently loaded XML document
  /*[id(0x000000cb)]*/ int validate(out IXMLDOMParseError errorObj);
  // set the value of the named property
  /*[id(0x000000cc)]*/ int setProperty(in wchar* name, in VARIANT value);
  // get the value of the named property
  /*[id(0x000000cd)]*/ int getProperty(in wchar* name, out VARIANT value);
}

// XML Schemas Collection
interface IXMLDOMSchemaCollection : IDispatch {
  /*[uuid("373984c8-b845-449b-91e7-45ac83036ade")]*/
  static GUID IID = { 0x373984c8, 0xb845, 0x449b, 0x91, 0xe7, 0x45, 0xac, 0x83, 0x03, 0x6a, 0xde };
  // add a new schema
  /*[id(0x00000003)]*/ int add(in wchar* namespaceURI, in VARIANT var);
  // lookup schema by namespaceURI
  /*[id(0x00000004)]*/ int get(in wchar* namespaceURI, out IXMLDOMNode schemaNode);
  // remove schema by namespaceURI
  /*[id(0x00000005)]*/ int remove(in wchar* namespaceURI);
  // number of schemas in collection
  /*[id(0x00000006)]*/ int get_length(out int length);
  // Get namespaceURI for schema by index
  /*[id(0x00000000)]*/ int get_namespaceURI(in int index, out wchar* length);
  // copy & merge other collection into this one
  /*[id(0x00000008)]*/ int addCollection(in IXMLDOMSchemaCollection otherCollection);
  /*[id(0xfffffffc)]*/ int get__newEnum(out IUnknown ppUnk);
}

interface IXMLDOMDocument3 : IXMLDOMDocument2 {
  /*[uuid("2933bf96-7b36-11d2-b20e-00c04f983e60")]*/
  static GUID IID = { 0x2933bf96, 0x7b36, 0x11d2, 0xb2, 0x0e, 0x00, 0xc0, 0x4f, 0x98, 0x3e, 0x60 };
  // perform runtime validation on the currently loaded XML document node
  /*[id(0x000000d0)]*/ int validateNode(in IXMLDOMNode node, out IXMLDOMParseError errorObj);
  // clone node such that clones ownerDocument is this document
  /*[id(0x000000d1)]*/ int importNode(in IXMLDOMNode node, in short deep, out IXMLDOMNode clone);
}

interface IXMLDOMNotation : IXMLDOMNode {
  /*[uuid("2933bf8c-7b36-11d2-b20e-00c04f983e60")]*/
  static GUID IID = { 0x2933bf8c, 0x7b36, 0x11d2, 0xb2, 0x0e, 0x00, 0xc0, 0x4f, 0x98, 0x3e, 0x60 };
  // the public ID
  /*[id(0x00000088)]*/ int get_publicId(out VARIANT publicId);
  // the system ID
  /*[id(0x00000089)]*/ int get_systemId(out VARIANT systemId);
}

interface IXMLDOMEntity : IXMLDOMNode {
  /*[uuid("2933bf8d-7b36-11d2-b20e-00c04f983e60")]*/
  static GUID IID = { 0x2933bf8d, 0x7b36, 0x11d2, 0xb2, 0x0e, 0x00, 0xc0, 0x4f, 0x98, 0x3e, 0x60 };
  // the public ID
  /*[id(0x0000008c)]*/ int get_publicId(out VARIANT publicId);
  // the system ID
  /*[id(0x0000008d)]*/ int get_systemId(out VARIANT systemId);
  // the name of the notation
  /*[id(0x0000008e)]*/ int get_notationName(out wchar* name);
}

// structure for reporting parser errors
interface IXMLDOMParseError2 : IXMLDOMParseError {
  /*[uuid("3efaa428-272f-11d2-836f-0000f87a7782")]*/
  static GUID IID = { 0x3efaa428, 0x272f, 0x11d2, 0x83, 0x6f, 0x00, 0x00, 0xf8, 0x7a, 0x77, 0x82 };
  /*[id(0x000000be)]*/ int get_errorXPath(out wchar* xpathexpr);
  /*[id(0x000000bb)]*/ int get_allErrors(out IXMLDOMParseErrorCollection allErrors);
  /*[id(0x000000bc)]*/ int errorParameters(in int index, out wchar* param);
  /*[id(0x000000bd)]*/ int get_errorParametersCount(out int count);
}

// structure for reporting parser errors
interface IXMLDOMParseErrorCollection : IDispatch {
  /*[uuid("3efaa429-272f-11d2-836f-0000f87a7782")]*/
  static GUID IID = { 0x3efaa429, 0x272f, 0x11d2, 0x83, 0x6f, 0x00, 0x00, 0xf8, 0x7a, 0x77, 0x82 };
  /*[id(0x00000000)]*/ int get_item(in int index, out IXMLDOMParseError2 error);
  /*[id(0x000000c1)]*/ int get_length(out int length);
  /*[id(0x000000c2)]*/ int get_next(out IXMLDOMParseError2 error);
  /*[id(0x000000c3)]*/ int reset();
  /*[id(0xfffffffc)]*/ int get__newEnum(out IUnknown ppUnk);
}

// XTL runtime object
interface IXTLRuntime : IXMLDOMNode {
  /*[uuid("3efaa425-272f-11d2-836f-0000f87a7782")]*/
  static GUID IID = { 0x3efaa425, 0x272f, 0x11d2, 0x83, 0x6f, 0x00, 0x00, 0xf8, 0x7a, 0x77, 0x82 };
  /*[id(0x000000bb)]*/ int uniqueID(in IXMLDOMNode pNode, out int pID);
  /*[id(0x000000bc)]*/ int depth(in IXMLDOMNode pNode, out int pDepth);
  /*[id(0x000000bd)]*/ int childNumber(in IXMLDOMNode pNode, out int pNumber);
  /*[id(0x000000be)]*/ int ancestorChildNumber(in wchar* bstrNodeName, in IXMLDOMNode pNode, out int pNumber);
  /*[id(0x000000bf)]*/ int absoluteChildNumber(in IXMLDOMNode pNode, out int pNumber);
  /*[id(0x000000c0)]*/ int formatIndex(in int lIndex, in wchar* bstrFormat, out wchar* pbstrFormattedString);
  /*[id(0x000000c1)]*/ int formatNumber(in double dblNumber, in wchar* bstrFormat, out wchar* pbstrFormattedString);
  /*[id(0x000000c2)]*/ int formatDate(in VARIANT varDate, in wchar* bstrFormat, VARIANT varDestLocale, out wchar* pbstrFormattedString);
  /*[id(0x000000c3)]*/ int formatTime(in VARIANT varTime, in wchar* bstrFormat, VARIANT varDestLocale, out wchar* pbstrFormattedString);
}

// IXSLTemplate Interface
interface IXSLTemplate : IDispatch {
  /*[uuid("2933bf93-7b36-11d2-b20e-00c04f983e60")]*/
  static GUID IID = { 0x2933bf93, 0x7b36, 0x11d2, 0xb2, 0x0e, 0x00, 0xc0, 0x4f, 0x98, 0x3e, 0x60 };
  // stylesheet to use with processors
  /*[id(0x00000002)]*/ int setref_stylesheet(in IXMLDOMNode value);
  // stylesheet to use with processors
  /*[id(0x00000002)]*/ int get_stylesheet(out IXMLDOMNode stylesheet);
  // create a new processor object
  /*[id(0x00000003)]*/ int createProcessor(out IXSLProcessor ppProcessor);
}

// IXSLProcessor Interface
interface IXSLProcessor : IDispatch {
  /*[uuid("2933bf92-7b36-11d2-b20e-00c04f983e60")]*/
  static GUID IID = { 0x2933bf92, 0x7b36, 0x11d2, 0xb2, 0x0e, 0x00, 0xc0, 0x4f, 0x98, 0x3e, 0x60 };
  // XML input tree to transform
  /*[id(0x00000002)]*/ int set_input(in VARIANT value);
  // XML input tree to transform
  /*[id(0x00000002)]*/ int get_input(out VARIANT pVar);
  // template object used to create this processor object
  /*[id(0x00000003)]*/ int get_ownerTemplate(out IXSLTemplate ppTemplate);
  // set XSL mode and it's namespace
  /*[id(0x00000004)]*/ int setStartMode(in wchar* mode, wchar* namespaceURI);
  // starting XSL mode
  /*[id(0x00000005)]*/ int get_startMode(out wchar* mode);
  // namespace of starting XSL mode
  /*[id(0x00000006)]*/ int get_startModeURI(out wchar* namespaceURI);
  // custom stream object for transform output
  /*[id(0x00000007)]*/ int set_output(in VARIANT value);
  // custom stream object for transform output
  /*[id(0x00000007)]*/ int get_output(out VARIANT pOutput);
  // start/resume the XSL transformation process
  /*[id(0x00000008)]*/ int transform(out short pDone);
  // reset state of processor and abort current transform
  /*[id(0x00000009)]*/ int reset();
  // current state of the processor
  /*[id(0x0000000a)]*/ int get_readyState(out int pReadyState);
  // set <xsl:param> values
  /*[id(0x0000000b)]*/ int addParameter(in wchar* baseName, in VARIANT parameter, wchar* namespaceURI);
  // pass object to stylesheet
  /*[id(0x0000000c)]*/ int addObject(in IDispatch obj, in wchar* namespaceURI);
  // current stylesheet being used
  /*[id(0x0000000d)]*/ int get_stylesheet(out IXMLDOMNode stylesheet);
}

// ISAXXMLReader interface
interface ISAXXMLReader : IUnknown {
  /*[uuid("a4f96ed0-f829-476e-81c0-cdc7bd2a0802")]*/
  static GUID IID = { 0xa4f96ed0, 0xf829, 0x476e, 0x81, 0xc0, 0xcd, 0xc7, 0xbd, 0x2a, 0x08, 0x02 };
  /*[id(0x60010000)]*/ int getFeature(in wchar* pwchName, out short pvfValue);
  /*[id(0x60010001)]*/ int putFeature(in wchar* pwchName, in short vfValue);
  /*[id(0x60010002)]*/ int getProperty(in wchar* pwchName, out VARIANT pvarValue);
  /*[id(0x60010003)]*/ int putProperty(in wchar* pwchName, in VARIANT varValue);
  /*[id(0x60010004)]*/ int getEntityResolver(out ISAXEntityResolver ppResolver);
  /*[id(0x60010005)]*/ int putEntityResolver(in ISAXEntityResolver pResolver);
  /*[id(0x60010006)]*/ int getContentHandler(out ISAXContentHandler ppHandler);
  /*[id(0x60010007)]*/ int putContentHandler(in ISAXContentHandler pHandler);
  /*[id(0x60010008)]*/ int getDTDHandler(out ISAXDTDHandler ppHandler);
  /*[id(0x60010009)]*/ int putDTDHandler(in ISAXDTDHandler pHandler);
  /*[id(0x6001000a)]*/ int getErrorHandler(out ISAXErrorHandler ppHandler);
  /*[id(0x6001000b)]*/ int putErrorHandler(in ISAXErrorHandler pHandler);
  /*[id(0x6001000c)]*/ int getBaseURL(out wchar* ppwchBaseUrl);
  /*[id(0x6001000d)]*/ int putBaseURL(in wchar* pwchBaseUrl);
  /*[id(0x6001000e)]*/ int getSecureBaseURL(out wchar* ppwchSecureBaseUrl);
  /*[id(0x6001000f)]*/ int putSecureBaseURL(in wchar* pwchSecureBaseUrl);
  /*[id(0x60010010)]*/ int parse(VARIANT varInput);
  /*[id(0x60010011)]*/ int parseURL(in wchar* pwchUrl);
}

// ISAXEntityResolver interface
interface ISAXEntityResolver : IUnknown {
  /*[uuid("99bca7bd-e8c4-4d5f-a0cf-6d907901ff07")]*/
  static GUID IID = { 0x99bca7bd, 0xe8c4, 0x4d5f, 0xa0, 0xcf, 0x6d, 0x90, 0x79, 0x01, 0xff, 0x07 };
  /*[id(0x60010000)]*/ int resolveEntity(in wchar* pwchPublicId, in wchar* pwchSystemId, out VARIANT pvarInput);
}

// ISAXContentHandler interface
interface ISAXContentHandler : IUnknown {
  /*[uuid("1545cdfa-9e4e-4497-a8a4-2bf7d0112c44")]*/
  static GUID IID = { 0x1545cdfa, 0x9e4e, 0x4497, 0xa8, 0xa4, 0x2b, 0xf7, 0xd0, 0x11, 0x2c, 0x44 };
  /*[id(0x60010000)]*/ int putDocumentLocator(in ISAXLocator pLocator);
  /*[id(0x60010001)]*/ int startDocument();
  /*[id(0x60010002)]*/ int endDocument();
  /*[id(0x60010003)]*/ int startPrefixMapping(in wchar* pwchPrefix, in int cchPrefix, in wchar* pwchUri, in int cchUri);
  /*[id(0x60010004)]*/ int endPrefixMapping(in wchar* pwchPrefix, in int cchPrefix);
  /*[id(0x60010005)]*/ int startElement(in wchar* pwchNamespaceUri, in int cchNamespaceUri, in wchar* pwchLocalName, in int cchLocalName, in wchar* pwchQName, in int cchQName, in ISAXAttributes pAttributes);
  /*[id(0x60010006)]*/ int endElement(in wchar* pwchNamespaceUri, in int cchNamespaceUri, in wchar* pwchLocalName, in int cchLocalName, in wchar* pwchQName, in int cchQName);
  /*[id(0x60010007)]*/ int characters(in wchar* pwchChars, in int cchChars);
  /*[id(0x60010008)]*/ int ignorableWhitespace(in wchar* pwchChars, in int cchChars);
  /*[id(0x60010009)]*/ int processingInstruction(in wchar* pwchTarget, in int cchTarget, in wchar* pwchData, in int cchData);
  /*[id(0x6001000a)]*/ int skippedEntity(in wchar* pwchName, in int cchName);
}

// ISAXLocator interface
interface ISAXLocator : IUnknown {
  /*[uuid("9b7e472a-0de4-4640-bff3-84d38a051c31")]*/
  static GUID IID = { 0x9b7e472a, 0x0de4, 0x4640, 0xbf, 0xf3, 0x84, 0xd3, 0x8a, 0x05, 0x1c, 0x31 };
  /*[id(0x60010000)]*/ int getColumnNumber(out int pnColumn);
  /*[id(0x60010001)]*/ int getLineNumber(out int pnLine);
  /*[id(0x60010002)]*/ int getPublicId(out wchar* ppwchPublicId);
  /*[id(0x60010003)]*/ int getSystemId(out wchar* ppwchSystemId);
}

// ISAXAttributes interface
interface ISAXAttributes : IUnknown {
  /*[uuid("f078abe1-45d2-4832-91ea-4466ce2f25c9")]*/
  static GUID IID = { 0xf078abe1, 0x45d2, 0x4832, 0x91, 0xea, 0x44, 0x66, 0xce, 0x2f, 0x25, 0xc9 };
  /*[id(0x60010000)]*/ int getLength(out int pnLength);
  /*[id(0x60010001)]*/ int getURI(in int nIndex, out wchar* ppwchUri, out int pcchUri);
  /*[id(0x60010002)]*/ int getLocalName(in int nIndex, out wchar* ppwchLocalName, out int pcchLocalName);
  /*[id(0x60010003)]*/ int getQName(in int nIndex, out wchar* ppwchQName, out int pcchQName);
  /*[id(0x60010004)]*/ int getName(in int nIndex, out wchar* ppwchUri, out int pcchUri, out wchar* ppwchLocalName, out int pcchLocalName, out wchar* ppwchQName, out int pcchQName);
  /*[id(0x60010005)]*/ int getIndexFromName(in wchar* pwchUri, in int cchUri, in wchar* pwchLocalName, in int cchLocalName, out int pnIndex);
  /*[id(0x60010006)]*/ int getIndexFromQName(in wchar* pwchQName, in int cchQName, out int pnIndex);
  /*[id(0x60010007)]*/ int getType(in int nIndex, out wchar* ppwchType, out int pcchType);
  /*[id(0x60010008)]*/ int getTypeFromName(in wchar* pwchUri, in int cchUri, in wchar* pwchLocalName, in int cchLocalName, out wchar* ppwchType, out int pcchType);
  /*[id(0x60010009)]*/ int getTypeFromQName(in wchar* pwchQName, in int cchQName, out wchar* ppwchType, out int pcchType);
  /*[id(0x6001000a)]*/ int getValue(in int nIndex, out wchar* ppwchValue, out int pcchValue);
  /*[id(0x6001000b)]*/ int getValueFromName(in wchar* pwchUri, in int cchUri, in wchar* pwchLocalName, in int cchLocalName, out wchar* ppwchValue, out int pcchValue);
  /*[id(0x6001000c)]*/ int getValueFromQName(in wchar* pwchQName, in int cchQName, out wchar* ppwchValue, out int pcchValue);
}

// ISAXDTDHandler interface
interface ISAXDTDHandler : IUnknown {
  /*[uuid("e15c1baf-afb3-4d60-8c36-19a8c45defed")]*/
  static GUID IID = { 0xe15c1baf, 0xafb3, 0x4d60, 0x8c, 0x36, 0x19, 0xa8, 0xc4, 0x5d, 0xef, 0xed };
  /*[id(0x60010000)]*/ int notationDecl(in wchar* pwchName, in int cchName, in wchar* pwchPublicId, in int cchPublicId, in wchar* pwchSystemId, in int cchSystemId);
  /*[id(0x60010001)]*/ int unparsedEntityDecl(in wchar* pwchName, in int cchName, in wchar* pwchPublicId, in int cchPublicId, in wchar* pwchSystemId, in int cchSystemId, in wchar* pwchNotationName, in int cchNotationName);
}

// ISAXErrorHandler interface
interface ISAXErrorHandler : IUnknown {
  /*[uuid("a60511c4-ccf5-479e-98a3-dc8dc545b7d0")]*/
  static GUID IID = { 0xa60511c4, 0xccf5, 0x479e, 0x98, 0xa3, 0xdc, 0x8d, 0xc5, 0x45, 0xb7, 0xd0 };
  /*[id(0x60010000)]*/ int error(in ISAXLocator pLocator, in wchar* pwchErrorMessage, in int hrErrorCode);
  /*[id(0x60010001)]*/ int fatalError(in ISAXLocator pLocator, in wchar* pwchErrorMessage, in int hrErrorCode);
  /*[id(0x60010002)]*/ int ignorableWarning(in ISAXLocator pLocator, in wchar* pwchErrorMessage, in int hrErrorCode);
}

// ISAXXMLFilter interface
interface ISAXXMLFilter : ISAXXMLReader {
  /*[uuid("70409222-ca09-4475-acb8-40312fe8d145")]*/
  static GUID IID = { 0x70409222, 0xca09, 0x4475, 0xac, 0xb8, 0x40, 0x31, 0x2f, 0xe8, 0xd1, 0x45 };
  /*[id(0x60020000)]*/ int getParent(out ISAXXMLReader ppReader);
  /*[id(0x60020001)]*/ int putParent(in ISAXXMLReader pReader);
}

// ISAXLexicalHandler interface
interface ISAXLexicalHandler : IUnknown {
  /*[uuid("7f85d5f5-47a8-4497-bda5-84ba04819ea6")]*/
  static GUID IID = { 0x7f85d5f5, 0x47a8, 0x4497, 0xbd, 0xa5, 0x84, 0xba, 0x04, 0x81, 0x9e, 0xa6 };
  /*[id(0x60010000)]*/ int startDTD(in wchar* pwchName, in int cchName, in wchar* pwchPublicId, in int cchPublicId, in wchar* pwchSystemId, in int cchSystemId);
  /*[id(0x60010001)]*/ int endDTD();
  /*[id(0x60010002)]*/ int startEntity(in wchar* pwchName, in int cchName);
  /*[id(0x60010003)]*/ int endEntity(in wchar* pwchName, in int cchName);
  /*[id(0x60010004)]*/ int startCDATA();
  /*[id(0x60010005)]*/ int endCDATA();
  /*[id(0x60010006)]*/ int comment(in wchar* pwchChars, in int cchChars);
}

// ISAXDeclHandler interface
interface ISAXDeclHandler : IUnknown {
  /*[uuid("862629ac-771a-47b2-8337-4e6843c1be90")]*/
  static GUID IID = { 0x862629ac, 0x771a, 0x47b2, 0x83, 0x37, 0x4e, 0x68, 0x43, 0xc1, 0xbe, 0x90 };
  /*[id(0x60010000)]*/ int elementDecl(in wchar* pwchName, in int cchName, in wchar* pwchModel, in int cchModel);
  /*[id(0x60010001)]*/ int attributeDecl(in wchar* pwchElementName, in int cchElementName, in wchar* pwchAttributeName, in int cchAttributeName, in wchar* pwchType, in int cchType, in wchar* pwchValueDefault, in int cchValueDefault, in wchar* pwchValue, in int cchValue);
  /*[id(0x60010002)]*/ int internalEntityDecl(in wchar* pwchName, in int cchName, in wchar* pwchValue, in int cchValue);
  /*[id(0x60010003)]*/ int externalEntityDecl(in wchar* pwchName, in int cchName, in wchar* pwchPublicId, in int cchPublicId, in wchar* pwchSystemId, in int cchSystemId);
}

// IVBSAXXMLReader interface
interface IVBSAXXMLReader : IDispatch {
  /*[uuid("8c033caa-6cd6-4f73-b728-4531af74945f")]*/
  static GUID IID = { 0x8c033caa, 0x6cd6, 0x4f73, 0xb7, 0x28, 0x45, 0x31, 0xaf, 0x74, 0x94, 0x5f };
  // Look up the value of a feature.
  /*[id(0x00000502)]*/ int getFeature(in wchar* strName, out short fValue);
  // Set the state of a feature.
  /*[id(0x00000503)]*/ int putFeature(in wchar* strName, in short fValue);
  // Look up the value of a property.
  /*[id(0x00000504)]*/ int getProperty(in wchar* strName, out VARIANT varValue);
  // Set the value of a property.
  /*[id(0x00000505)]*/ int putProperty(in wchar* strName, in VARIANT varValue);
  // Allow an application to register an entity resolver or look up the current entity resolver.
  /*[id(0x00000506)]*/ int get_entityResolver(out IVBSAXEntityResolver oResolver);
  // Allow an application to register an entity resolver or look up the current entity resolver.
  /*[id(0x00000506)]*/ int setref_entityResolver(in IVBSAXEntityResolver value);
  // Allow an application to register a content event handler or look up the current content event handler.
  /*[id(0x00000507)]*/ int get_contentHandler(out IVBSAXContentHandler oHandler);
  // Allow an application to register a content event handler or look up the current content event handler.
  /*[id(0x00000507)]*/ int setref_contentHandler(in IVBSAXContentHandler value);
  // Allow an application to register a DTD event handler or look up the current DTD event handler.
  /*[id(0x00000508)]*/ int get_dtdHandler(out IVBSAXDTDHandler oHandler);
  // Allow an application to register a DTD event handler or look up the current DTD event handler.
  /*[id(0x00000508)]*/ int setref_dtdHandler(in IVBSAXDTDHandler value);
  // Allow an application to register an error event handler or look up the current error event handler.
  /*[id(0x00000509)]*/ int get_errorHandler(out IVBSAXErrorHandler oHandler);
  // Allow an application to register an error event handler or look up the current error event handler.
  /*[id(0x00000509)]*/ int setref_errorHandler(in IVBSAXErrorHandler value);
  // Set or get the base URL for the document.
  /*[id(0x0000050a)]*/ int get_baseURL(out wchar* strBaseURL);
  // Set or get the base URL for the document.
  /*[id(0x0000050a)]*/ int set_baseURL(in wchar* value);
  // Set or get the secure base URL for the document.
  /*[id(0x0000050b)]*/ int get_secureBaseURL(out wchar* strSecureBaseURL);
  // Set or get the secure base URL for the document.
  /*[id(0x0000050b)]*/ int set_secureBaseURL(in wchar* value);
  // Parse an XML document.
  /*[id(0x0000050c)]*/ int parse(VARIANT varInput);
  // Parse an XML document from a system identifier (URI).
  /*[id(0x0000050d)]*/ int parseURL(in wchar* strURL);
}

// IVBSAXEntityResolver interface
interface IVBSAXEntityResolver : IDispatch {
  /*[uuid("0c05d096-f45b-4aca-ad1a-aa0bc25518dc")]*/
  static GUID IID = { 0x0c05d096, 0xf45b, 0x4aca, 0xad, 0x1a, 0xaa, 0x0b, 0xc2, 0x55, 0x18, 0xdc };
  // Allow the application to resolve external entities.
  /*[id(0x00000527)]*/ int resolveEntity(inout wchar* strPublicId, inout wchar* strSystemId, out VARIANT varInput);
}

// IVBSAXContentHandler interface
interface IVBSAXContentHandler : IDispatch {
  /*[uuid("2ed7290a-4dd5-4b46-bb26-4e4155e77faa")]*/
  static GUID IID = { 0x2ed7290a, 0x4dd5, 0x4b46, 0xbb, 0x26, 0x4e, 0x41, 0x55, 0xe7, 0x7f, 0xaa };
  // Receive an object for locating the origin of SAX document events.
  /*[id(0x0000052a)]*/ int setref_documentLocator(in IVBSAXLocator value);
  // Receive notification of the beginning of a document.
  /*[id(0x0000052b)]*/ int startDocument();
  // Receive notification of the end of a document.
  /*[id(0x0000052c)]*/ int endDocument();
  // Begin the scope of a prefix-URI Namespace mapping.
  /*[id(0x0000052d)]*/ int startPrefixMapping(inout wchar* strPrefix, inout wchar* strURI);
  // End the scope of a prefix-URI mapping.
  /*[id(0x0000052e)]*/ int endPrefixMapping(inout wchar* strPrefix);
  // Receive notification of the beginning of an element.
  /*[id(0x0000052f)]*/ int startElement(inout wchar* strNamespaceURI, inout wchar* strLocalName, inout wchar* strQName, in IVBSAXAttributes oAttributes);
  // Receive notification of the end of an element.
  /*[id(0x00000530)]*/ int endElement(inout wchar* strNamespaceURI, inout wchar* strLocalName, inout wchar* strQName);
  // Receive notification of character data.
  /*[id(0x00000531)]*/ int characters(inout wchar* strChars);
  // Receive notification of ignorable whitespace in element content.
  /*[id(0x00000532)]*/ int ignorableWhitespace(inout wchar* strChars);
  // Receive notification of a processing instruction.
  /*[id(0x00000533)]*/ int processingInstruction(inout wchar* strTarget, inout wchar* strData);
  // Receive notification of a skipped entity.
  /*[id(0x00000534)]*/ int skippedEntity(inout wchar* strName);
}

// IVBSAXLocator interface
interface IVBSAXLocator : IDispatch {
  /*[uuid("796e7ac5-5aa2-4eff-acad-3faaf01a3288")]*/
  static GUID IID = { 0x796e7ac5, 0x5aa2, 0x4eff, 0xac, 0xad, 0x3f, 0xaa, 0xf0, 0x1a, 0x32, 0x88 };
  // Get the column number where the current document event ends.
  /*[id(0x00000521)]*/ int get_columnNumber(out int nColumn);
  // Get the line number where the current document event ends.
  /*[id(0x00000522)]*/ int get_lineNumber(out int nLine);
  // Get the public identifier for the current document event.
  /*[id(0x00000523)]*/ int get_publicId(out wchar* strPublicId);
  // Get the system identifier for the current document event.
  /*[id(0x00000524)]*/ int get_systemId(out wchar* strSystemId);
}

// IVBSAXAttributes interface
interface IVBSAXAttributes : IDispatch {
  /*[uuid("10dc0586-132b-4cac-8bb3-db00ac8b7ee0")]*/
  static GUID IID = { 0x10dc0586, 0x132b, 0x4cac, 0x8b, 0xb3, 0xdb, 0x00, 0xac, 0x8b, 0x7e, 0xe0 };
  // Get the number of attributes in the list.
  /*[id(0x00000540)]*/ int get_length(out int nLength);
  // Look up an attribute's Namespace URI by index.
  /*[id(0x00000541)]*/ int getURI(in int nIndex, out wchar* strURI);
  // Look up an attribute's local name by index.
  /*[id(0x00000542)]*/ int getLocalName(in int nIndex, out wchar* strLocalName);
  // Look up an attribute's XML 1.0 qualified name by index.
  /*[id(0x00000543)]*/ int getQName(in int nIndex, out wchar* strQName);
  // Look up the index of an attribute by Namespace name.
  /*[id(0x00000544)]*/ int getIndexFromName(in wchar* strURI, in wchar* strLocalName, out int nIndex);
  // Look up the index of an attribute by XML 1.0 qualified name.
  /*[id(0x00000545)]*/ int getIndexFromQName(in wchar* strQName, out int nIndex);
  // Look up an attribute's type by index.
  /*[id(0x00000546)]*/ int getType(in int nIndex, out wchar* strType);
  // Look up an attribute's type by Namespace name.
  /*[id(0x00000547)]*/ int getTypeFromName(in wchar* strURI, in wchar* strLocalName, out wchar* strType);
  // Look up an attribute's type by XML 1.0 qualified name.
  /*[id(0x00000548)]*/ int getTypeFromQName(in wchar* strQName, out wchar* strType);
  // Look up an attribute's value by index.
  /*[id(0x00000549)]*/ int getValue(in int nIndex, out wchar* strValue);
  // Look up an attribute's value by Namespace name.
  /*[id(0x0000054a)]*/ int getValueFromName(in wchar* strURI, in wchar* strLocalName, out wchar* strValue);
  // Look up an attribute's value by XML 1.0 qualified name.
  /*[id(0x0000054b)]*/ int getValueFromQName(in wchar* strQName, out wchar* strValue);
}

// IVBSAXDTDHandler interface
interface IVBSAXDTDHandler : IDispatch {
  /*[uuid("24fb3297-302d-4620-ba39-3a732d850558")]*/
  static GUID IID = { 0x24fb3297, 0x302d, 0x4620, 0xba, 0x39, 0x3a, 0x73, 0x2d, 0x85, 0x05, 0x58 };
  // Receive notification of a notation declaration event.
  /*[id(0x00000537)]*/ int notationDecl(inout wchar* strName, inout wchar* strPublicId, inout wchar* strSystemId);
  // Receive notification of an unparsed entity declaration event.
  /*[id(0x00000538)]*/ int unparsedEntityDecl(inout wchar* strName, inout wchar* strPublicId, inout wchar* strSystemId, inout wchar* strNotationName);
}

// IVBSAXErrorHandler interface
interface IVBSAXErrorHandler : IDispatch {
  /*[uuid("d963d3fe-173c-4862-9095-b92f66995f52")]*/
  static GUID IID = { 0xd963d3fe, 0x173c, 0x4862, 0x90, 0x95, 0xb9, 0x2f, 0x66, 0x99, 0x5f, 0x52 };
  // Receive notification of a recoverable error.
  /*[id(0x0000053b)]*/ int error(in IVBSAXLocator oLocator, inout wchar* strErrorMessage, in int nErrorCode);
  // Receive notification of a non-recoverable error.
  /*[id(0x0000053c)]*/ int fatalError(in IVBSAXLocator oLocator, inout wchar* strErrorMessage, in int nErrorCode);
  // Receive notification of an ignorable warning.
  /*[id(0x0000053d)]*/ int ignorableWarning(in IVBSAXLocator oLocator, inout wchar* strErrorMessage, in int nErrorCode);
}

// IVBSAXXMLFilter interface
interface IVBSAXXMLFilter : IDispatch {
  /*[uuid("1299eb1b-5b88-433e-82de-82ca75ad4e04")]*/
  static GUID IID = { 0x1299eb1b, 0x5b88, 0x433e, 0x82, 0xde, 0x82, 0xca, 0x75, 0xad, 0x4e, 0x04 };
  // Set or get the parent reader
  /*[id(0x0000051d)]*/ int get_parent(out IVBSAXXMLReader oReader);
  // Set or get the parent reader
  /*[id(0x0000051d)]*/ int setref_parent(in IVBSAXXMLReader value);
}

// IVBSAXLexicalHandler interface
interface IVBSAXLexicalHandler : IDispatch {
  /*[uuid("032aac35-8c0e-4d9d-979f-e3b702935576")]*/
  static GUID IID = { 0x032aac35, 0x8c0e, 0x4d9d, 0x97, 0x9f, 0xe3, 0xb7, 0x02, 0x93, 0x55, 0x76 };
  // Report the start of DTD declarations, if any.
  /*[id(0x0000054e)]*/ int startDTD(inout wchar* strName, inout wchar* strPublicId, inout wchar* strSystemId);
  // Report the end of DTD declarations.
  /*[id(0x0000054f)]*/ int endDTD();
  // Report the beginning of some internal and external XML entities.
  /*[id(0x00000550)]*/ int startEntity(inout wchar* strName);
  // Report the end of an entity.
  /*[id(0x00000551)]*/ int endEntity(inout wchar* strName);
  // Report the start of a CDATA section.
  /*[id(0x00000552)]*/ int startCDATA();
  // Report the end of a CDATA section.
  /*[id(0x00000553)]*/ int endCDATA();
  // Report an XML comment anywhere in the document.
  /*[id(0x00000554)]*/ int comment(inout wchar* strChars);
}

// IVBSAXDeclHandler interface
interface IVBSAXDeclHandler : IDispatch {
  /*[uuid("e8917260-7579-4be1-b5dd-7afbfa6f077b")]*/
  static GUID IID = { 0xe8917260, 0x7579, 0x4be1, 0xb5, 0xdd, 0x7a, 0xfb, 0xfa, 0x6f, 0x07, 0x7b };
  // Report an element type declaration.
  /*[id(0x00000557)]*/ int elementDecl(inout wchar* strName, inout wchar* strModel);
  // Report an attribute type declaration.
  /*[id(0x00000558)]*/ int attributeDecl(inout wchar* strElementName, inout wchar* strAttributeName, inout wchar* strType, inout wchar* strValueDefault, inout wchar* strValue);
  // Report an internal entity declaration.
  /*[id(0x00000559)]*/ int internalEntityDecl(inout wchar* strName, inout wchar* strValue);
  // Report a parsed external entity declaration.
  /*[id(0x0000055a)]*/ int externalEntityDecl(inout wchar* strName, inout wchar* strPublicId, inout wchar* strSystemId);
}

// IMXWriter interface
interface IMXWriter : IDispatch {
  /*[uuid("4d7ff4ba-1565-4ea8-94e1-6e724a46f98d")]*/
  static GUID IID = { 0x4d7ff4ba, 0x1565, 0x4ea8, 0x94, 0xe1, 0x6e, 0x72, 0x4a, 0x46, 0xf9, 0x8d };
  // Set or get the output.
  /*[id(0x00000569)]*/ int set_output(in VARIANT value);
  // Set or get the output.
  /*[id(0x00000569)]*/ int get_output(out VARIANT varDestination);
  // Set or get the output encoding.
  /*[id(0x0000056b)]*/ int set_encoding(in wchar* value);
  // Set or get the output encoding.
  /*[id(0x0000056b)]*/ int get_encoding(out wchar* strEncoding);
  // Determine whether or not to write the byte order mark
  /*[id(0x0000056c)]*/ int set_byteOrderMark(in short value);
  // Determine whether or not to write the byte order mark
  /*[id(0x0000056c)]*/ int get_byteOrderMark(out short fWriteByteOrderMark);
  // Enable or disable auto indent mode.
  /*[id(0x0000056d)]*/ int set_indent(in short value);
  // Enable or disable auto indent mode.
  /*[id(0x0000056d)]*/ int get_indent(out short fIndentMode);
  // Set or get the standalone document declaration.
  /*[id(0x0000056e)]*/ int set_standalone(in short value);
  // Set or get the standalone document declaration.
  /*[id(0x0000056e)]*/ int get_standalone(out short fValue);
  // Determine whether or not to omit the XML declaration.
  /*[id(0x0000056f)]*/ int set_omitXMLDeclaration(in short value);
  // Determine whether or not to omit the XML declaration.
  /*[id(0x0000056f)]*/ int get_omitXMLDeclaration(out short fValue);
  // Set or get the xml version info.
  /*[id(0x00000570)]*/ int set_version(in wchar* value);
  // Set or get the xml version info.
  /*[id(0x00000570)]*/ int get_version(out wchar* strVersion);
  // When enabled, the writer no longer escapes out its input when writing it out.
  /*[id(0x00000571)]*/ int set_disableOutputEscaping(in short value);
  // When enabled, the writer no longer escapes out its input when writing it out.
  /*[id(0x00000571)]*/ int get_disableOutputEscaping(out short fValue);
  // Flushes all writer buffers forcing the writer to write to the underlying output object
  /*[id(0x00000572)]*/ int flush();
}

// IMXAttributes interface
interface IMXAttributes : IDispatch {
  /*[uuid("f10d27cc-3ec0-415c-8ed8-77ab1c5e7262")]*/
  static GUID IID = { 0xf10d27cc, 0x3ec0, 0x415c, 0x8e, 0xd8, 0x77, 0xab, 0x1c, 0x5e, 0x72, 0x62 };
  // Add an attribute to the end of the list.
  /*[id(0x0000055d)]*/ int addAttribute(in wchar* strURI, in wchar* strLocalName, in wchar* strQName, in wchar* strType, in wchar* strValue);
  // Add an attribute, whose value is equal to the indexed attribute in the input attributes object, to the end of the list.
  /*[id(0x00000567)]*/ int addAttributeFromIndex(in VARIANT varAtts, in int nIndex);
  // Clear the attribute list for reuse.
  /*[id(0x0000055e)]*/ int clear();
  // Remove an attribute from the list.
  /*[id(0x0000055f)]*/ int removeAttribute(in int nIndex);
  // Set an attribute in the list.
  /*[id(0x00000560)]*/ int setAttribute(in int nIndex, in wchar* strURI, in wchar* strLocalName, in wchar* strQName, in wchar* strType, in wchar* strValue);
  // Copy an entire Attributes object.
  /*[id(0x00000561)]*/ int setAttributes(in VARIANT varAtts);
  // Set the local name of a specific attribute.
  /*[id(0x00000562)]*/ int setLocalName(in int nIndex, in wchar* strLocalName);
  // Set the qualified name of a specific attribute.
  /*[id(0x00000563)]*/ int setQName(in int nIndex, in wchar* strQName);
  // Set the type of a specific attribute.
  /*[id(0x00000564)]*/ int setType(in int nIndex, in wchar* strType);
  // Set the Namespace URI of a specific attribute.
  /*[id(0x00000565)]*/ int setURI(in int nIndex, in wchar* strURI);
  // Set the value of a specific attribute.
  /*[id(0x00000566)]*/ int setValue(in int nIndex, in wchar* strValue);
}

// IMXReaderControl interface
interface IMXReaderControl : IDispatch {
  /*[uuid("808f4e35-8d5a-4fbe-8466-33a41279ed30")]*/
  static GUID IID = { 0x808f4e35, 0x8d5a, 0x4fbe, 0x84, 0x66, 0x33, 0xa4, 0x12, 0x79, 0xed, 0x30 };
  // Abort the reader
  /*[id(0x00000576)]*/ int abort();
  // Resume the reader
  /*[id(0x00000577)]*/ int resume();
  // Suspend the reader
  /*[id(0x00000578)]*/ int suspend();
}

// IMXSchemaDeclHandler interface
interface IMXSchemaDeclHandler : IDispatch {
  /*[uuid("fa4bb38c-faf9-4cca-9302-d1dd0fe520db")]*/
  static GUID IID = { 0xfa4bb38c, 0xfaf9, 0x4cca, 0x93, 0x02, 0xd1, 0xdd, 0x0f, 0xe5, 0x20, 0xdb };
  // Access schema element declaration
  /*[id(0x0000057b)]*/ int schemaElementDecl(in ISchemaElement oSchemaElement);
}

// XML Schema Element
interface ISchemaElement : ISchemaParticle {
  /*[uuid("50ea08b7-dd1b-4664-9a50-c2f40f4bd79a")]*/
  static GUID IID = { 0x50ea08b7, 0xdd1b, 0x4664, 0x9a, 0x50, 0xc2, 0xf4, 0x0f, 0x4b, 0xd7, 0x9a };
  /*[id(0x000005c4)]*/ int get_type(out ISchemaType type);
  /*[id(0x000005bd)]*/ int get_scope(out ISchemaComplexType scopeParam);
  /*[id(0x00000597)]*/ int get_defaultValue(out wchar* defaultValue);
  /*[id(0x0000059e)]*/ int get_fixedValue(out wchar* fixedValue);
  /*[id(0x000005a3)]*/ int get_isNillable(out short nillable);
  /*[id(0x000005a1)]*/ int get_identityConstraints(out ISchemaItemCollection constraints);
  /*[id(0x000005bf)]*/ int get_substitutionGroup(out ISchemaElement element);
  /*[id(0x000005c0)]*/ int get_substitutionGroupExclusions(out SCHEMADERIVATIONMETHOD exclusions);
  /*[id(0x00000599)]*/ int get_disallowedSubstitutions(out SCHEMADERIVATIONMETHOD disallowed);
  /*[id(0x000005a2)]*/ int get_isAbstract(out short abstractParam);
  /*[id(0x000005a4)]*/ int get_isReference(out short reference);
}

// XML Schema Particle
interface ISchemaParticle : ISchemaItem {
  /*[uuid("50ea08b5-dd1b-4664-9a50-c2f40f4bd79a")]*/
  static GUID IID = { 0x50ea08b5, 0xdd1b, 0x4664, 0x9a, 0x50, 0xc2, 0xf4, 0x0f, 0x4b, 0xd7, 0x9a };
  /*[id(0x000005af)]*/ int get_minOccurs(out VARIANT minOccurs);
  /*[id(0x000005ab)]*/ int get_maxOccurs(out VARIANT maxOccurs);
}

// XML Schema Item
interface ISchemaItem : IDispatch {
  /*[uuid("50ea08b3-dd1b-4664-9a50-c2f40f4bd79a")]*/
  static GUID IID = { 0x50ea08b3, 0xdd1b, 0x4664, 0x9a, 0x50, 0xc2, 0xf4, 0x0f, 0x4b, 0xd7, 0x9a };
  /*[id(0x000005b1)]*/ int get_name(out wchar* name);
  /*[id(0x000005b3)]*/ int get_namespaceURI(out wchar* namespaceURI);
  /*[id(0x000005bb)]*/ int get_schema(out ISchema schema);
  /*[id(0x000005a0)]*/ int get_id(out wchar* id);
  /*[id(0x000005a6)]*/ int get_itemType(out SOMITEMTYPE itemType);
  /*[id(0x000005c6)]*/ int get_unhandledAttributes(out IVBSAXAttributes attributes);
  /*[id(0x000005cb)]*/ int writeAnnotation(in IUnknown annotationSink, out short isWritten);
}

// XML Schema
interface ISchema : ISchemaItem {
  /*[uuid("50ea08b4-dd1b-4664-9a50-c2f40f4bd79a")]*/
  static GUID IID = { 0x50ea08b4, 0xdd1b, 0x4664, 0x9a, 0x50, 0xc2, 0xf4, 0x0f, 0x4b, 0xd7, 0x9a };
  /*[id(0x000005c2)]*/ int get_targetNamespace(out wchar* targetNamespace);
  /*[id(0x000005c9)]*/ int get_version(out wchar* versionParam);
  /*[id(0x000005c5)]*/ int get_types(out ISchemaItemCollection types);
  /*[id(0x0000059a)]*/ int get_elements(out ISchemaItemCollection elements);
  /*[id(0x00000593)]*/ int get_attributes(out ISchemaItemCollection attributes);
  /*[id(0x00000592)]*/ int get_attributeGroups(out ISchemaItemCollection attributeGroups);
  /*[id(0x000005b0)]*/ int get_modelGroups(out ISchemaItemCollection modelGroups);
  /*[id(0x000005b4)]*/ int get_notations(out ISchemaItemCollection notations);
  /*[id(0x000005bc)]*/ int get_schemaLocations(out ISchemaStringCollection schemaLocations);
}

// XML Schema Item Collection
interface ISchemaItemCollection : IDispatch {
  /*[uuid("50ea08b2-dd1b-4664-9a50-c2f40f4bd79a")]*/
  static GUID IID = { 0x50ea08b2, 0xdd1b, 0x4664, 0x9a, 0x50, 0xc2, 0xf4, 0x0f, 0x4b, 0xd7, 0x9a };
  /*[id(0x00000000)]*/ int get_item(in int index, out ISchemaItem item);
  /*[id(0x0000058f)]*/ int itemByName(in wchar* name, out ISchemaItem item);
  /*[id(0x00000590)]*/ int itemByQName(in wchar* name, in wchar* namespaceURI, out ISchemaItem item);
  /*[id(0x000005a7)]*/ int get_length(out int length);
  /*[id(0xfffffffc)]*/ int get__newEnum(out IUnknown ppUnk);
}

// XML Schema String Collection
interface ISchemaStringCollection : IDispatch {
  /*[uuid("50ea08b1-dd1b-4664-9a50-c2f40f4bd79a")]*/
  static GUID IID = { 0x50ea08b1, 0xdd1b, 0x4664, 0x9a, 0x50, 0xc2, 0xf4, 0x0f, 0x4b, 0xd7, 0x9a };
  /*[id(0x00000000)]*/ int get_item(in int index, out wchar* bstr);
  /*[id(0x000005a7)]*/ int get_length(out int length);
  /*[id(0xfffffffc)]*/ int get__newEnum(out IUnknown ppUnk);
}

// XML Schema Type
interface ISchemaType : ISchemaItem {
  /*[uuid("50ea08b8-dd1b-4664-9a50-c2f40f4bd79a")]*/
  static GUID IID = { 0x50ea08b8, 0xdd1b, 0x4664, 0x9a, 0x50, 0xc2, 0xf4, 0x0f, 0x4b, 0xd7, 0x9a };
  /*[id(0x00000594)]*/ int get_baseTypes(out ISchemaItemCollection baseTypes);
  /*[id(0x0000059d)]*/ int get_final(out SCHEMADERIVATIONMETHOD finalParam);
  /*[id(0x000005c8)]*/ int get_variety(out SCHEMATYPEVARIETY variety);
  /*[id(0x00000598)]*/ int get_derivedBy(out SCHEMADERIVATIONMETHOD derivedBy);
  /*[id(0x000005a5)]*/ int isValid(in wchar* data, out short valid);
  /*[id(0x000005ac)]*/ int get_minExclusive(out wchar* minExclusive);
  /*[id(0x000005ad)]*/ int get_minInclusive(out wchar* minInclusive);
  /*[id(0x000005a8)]*/ int get_maxExclusive(out wchar* maxExclusive);
  /*[id(0x000005a9)]*/ int get_maxInclusive(out wchar* maxInclusive);
  /*[id(0x000005c3)]*/ int get_totalDigits(out VARIANT totalDigits);
  /*[id(0x0000059f)]*/ int get_fractionDigits(out VARIANT fractionDigits);
  /*[id(0x000005a7)]*/ int get_length(out VARIANT length);
  /*[id(0x000005ae)]*/ int get_minLength(out VARIANT minLength);
  /*[id(0x000005aa)]*/ int get_maxLength(out VARIANT maxLength);
  /*[id(0x0000059b)]*/ int get_enumeration(out ISchemaStringCollection enumeration);
  /*[id(0x000005ca)]*/ int get_whitespace(out SCHEMAWHITESPACE whitespace);
  /*[id(0x000005b6)]*/ int get_patterns(out ISchemaStringCollection patterns);
}

// XML Schema Complex Type
interface ISchemaComplexType : ISchemaType {
  /*[uuid("50ea08b9-dd1b-4664-9a50-c2f40f4bd79a")]*/
  static GUID IID = { 0x50ea08b9, 0xdd1b, 0x4664, 0x9a, 0x50, 0xc2, 0xf4, 0x0f, 0x4b, 0xd7, 0x9a };
  /*[id(0x000005a2)]*/ int get_isAbstract(out short abstractParam);
  /*[id(0x00000591)]*/ int get_anyAttribute(out ISchemaAny anyAttribute);
  /*[id(0x00000593)]*/ int get_attributes(out ISchemaItemCollection attributes);
  /*[id(0x00000596)]*/ int get_contentType(out SCHEMACONTENTTYPE contentType);
  /*[id(0x00000595)]*/ int get_contentModel(out ISchemaModelGroup contentModel);
  /*[id(0x000005b8)]*/ int get_prohibitedSubstitutions(out SCHEMADERIVATIONMETHOD prohibited);
}

// XML Schema Any
interface ISchemaAny : ISchemaParticle {
  /*[uuid("50ea08bc-dd1b-4664-9a50-c2f40f4bd79a")]*/
  static GUID IID = { 0x50ea08bc, 0xdd1b, 0x4664, 0x9a, 0x50, 0xc2, 0xf4, 0x0f, 0x4b, 0xd7, 0x9a };
  /*[id(0x000005b2)]*/ int get_namespaces(out ISchemaStringCollection namespaces);
  /*[id(0x000005b7)]*/ int get_processContents(out SCHEMAPROCESSCONTENTS processContents);
}

// XML Schema Type
interface ISchemaModelGroup : ISchemaParticle {
  /*[uuid("50ea08bb-dd1b-4664-9a50-c2f40f4bd79a")]*/
  static GUID IID = { 0x50ea08bb, 0xdd1b, 0x4664, 0x9a, 0x50, 0xc2, 0xf4, 0x0f, 0x4b, 0xd7, 0x9a };
  /*[id(0x000005b5)]*/ int get_particles(out ISchemaItemCollection particles);
}

// IMXXMLFilter interface
interface IMXXMLFilter : IDispatch {
  /*[uuid("c90352f7-643c-4fbc-bb23-e996eb2d51fd")]*/
  static GUID IID = { 0xc90352f7, 0x643c, 0x4fbc, 0xbb, 0x23, 0xe9, 0x96, 0xeb, 0x2d, 0x51, 0xfd };
  /*[id(0x0000058f)]*/ int getFeature(in wchar* strName, out short fValue);
  /*[id(0x00000591)]*/ int putFeature(in wchar* strName, in short fValue);
  /*[id(0x00000590)]*/ int getProperty(in wchar* strName, out VARIANT varValue);
  /*[id(0x00000592)]*/ int putProperty(in wchar* strName, in VARIANT varValue);
  /*[id(0x0000058d)]*/ int get_entityResolver(out IUnknown oResolver);
  /*[id(0x0000058d)]*/ int setref_entityResolver(in IUnknown value);
  /*[id(0x0000058b)]*/ int get_contentHandler(out IUnknown oHandler);
  /*[id(0x0000058b)]*/ int setref_contentHandler(in IUnknown value);
  /*[id(0x0000058c)]*/ int get_dtdHandler(out IUnknown oHandler);
  /*[id(0x0000058c)]*/ int setref_dtdHandler(in IUnknown value);
  /*[id(0x0000058e)]*/ int get_errorHandler(out IUnknown oHandler);
  /*[id(0x0000058e)]*/ int setref_errorHandler(in IUnknown value);
}

// XML Schemas Collection 2
interface IXMLDOMSchemaCollection2 : IXMLDOMSchemaCollection {
  /*[uuid("50ea08b0-dd1b-4664-9a50-c2f40f4bd79a")]*/
  static GUID IID = { 0x50ea08b0, 0xdd1b, 0x4664, 0x9a, 0x50, 0xc2, 0xf4, 0x0f, 0x4b, 0xd7, 0x9a };
  /*[id(0x0000058b)]*/ int validate();
  /*[id(0x0000058c)]*/ int set_validateOnLoad(in short value);
  /*[id(0x0000058c)]*/ int get_validateOnLoad(out short validateOnLoad);
  /*[id(0x0000058d)]*/ int getSchema(in wchar* namespaceURI, out ISchema schema);
  /*[id(0x0000058e)]*/ int getDeclaration(in IXMLDOMNode node, out ISchemaItem item);
}

// XML Schema Attribute
interface ISchemaAttribute : ISchemaItem {
  /*[uuid("50ea08b6-dd1b-4664-9a50-c2f40f4bd79a")]*/
  static GUID IID = { 0x50ea08b6, 0xdd1b, 0x4664, 0x9a, 0x50, 0xc2, 0xf4, 0x0f, 0x4b, 0xd7, 0x9a };
  /*[id(0x000005c4)]*/ int get_type(out ISchemaType type);
  /*[id(0x000005bd)]*/ int get_scope(out ISchemaComplexType scopeParam);
  /*[id(0x00000597)]*/ int get_defaultValue(out wchar* defaultValue);
  /*[id(0x0000059e)]*/ int get_fixedValue(out wchar* fixedValue);
  /*[id(0x000005c7)]*/ int get_use(out SCHEMAUSE use);
  /*[id(0x000005a4)]*/ int get_isReference(out short reference);
}

// XML Schema Attribute Group
interface ISchemaAttributeGroup : ISchemaItem {
  /*[uuid("50ea08ba-dd1b-4664-9a50-c2f40f4bd79a")]*/
  static GUID IID = { 0x50ea08ba, 0xdd1b, 0x4664, 0x9a, 0x50, 0xc2, 0xf4, 0x0f, 0x4b, 0xd7, 0x9a };
  /*[id(0x00000591)]*/ int get_anyAttribute(out ISchemaAny anyAttribute);
  /*[id(0x00000593)]*/ int get_attributes(out ISchemaItemCollection attributes);
}

// XML Schema Any
interface ISchemaIdentityConstraint : ISchemaItem {
  /*[uuid("50ea08bd-dd1b-4664-9a50-c2f40f4bd79a")]*/
  static GUID IID = { 0x50ea08bd, 0xdd1b, 0x4664, 0x9a, 0x50, 0xc2, 0xf4, 0x0f, 0x4b, 0xd7, 0x9a };
  /*[id(0x000005be)]*/ int get_selector(out wchar* selector);
  /*[id(0x0000059c)]*/ int get_fields(out ISchemaStringCollection fields);
  /*[id(0x000005ba)]*/ int get_referencedKey(out ISchemaIdentityConstraint key);
}

// XML Schema Notation
interface ISchemaNotation : ISchemaItem {
  /*[uuid("50ea08be-dd1b-4664-9a50-c2f40f4bd79a")]*/
  static GUID IID = { 0x50ea08be, 0xdd1b, 0x4664, 0x9a, 0x50, 0xc2, 0xf4, 0x0f, 0x4b, 0xd7, 0x9a };
  /*[id(0x000005c1)]*/ int get_systemIdentifier(out wchar* uri);
  /*[id(0x000005b9)]*/ int get_publicIdentifier(out wchar* uri);
}

interface IXMLDOMSelection : IXMLDOMNodeList {
  /*[uuid("aa634fc7-5888-44a7-a257-3a47150d3a0e")]*/
  static GUID IID = { 0xaa634fc7, 0x5888, 0x44a7, 0xa2, 0x57, 0x3a, 0x47, 0x15, 0x0d, 0x3a, 0x0e };
  // selection expression
  /*[id(0x00000051)]*/ int get_expr(out wchar* expression);
  // selection expression
  /*[id(0x00000051)]*/ int set_expr(in wchar* value);
  // nodes to apply selection expression to
  /*[id(0x00000052)]*/ int get_context(out IXMLDOMNode ppNode);
  // nodes to apply selection expression to
  /*[id(0x00000052)]*/ int setref_context(in IXMLDOMNode value);
  // gets the next node without advancing the list position
  /*[id(0x00000053)]*/ int peekNode(out IXMLDOMNode ppNode);
  // checks to see if the node matches the pattern
  /*[id(0x00000054)]*/ int matches(in IXMLDOMNode pNode, out IXMLDOMNode ppNode);
  // removes the next node
  /*[id(0x00000055)]*/ int removeNext(out IXMLDOMNode ppNode);
  // removes all the nodes that match the selection
  /*[id(0x00000056)]*/ int removeAll();
  // clone this object with the same position and context
  /*[id(0x00000057)]*/ int clone(out IXMLDOMSelection ppNode);
  // get the value of the named property
  /*[id(0x00000058)]*/ int getProperty(in wchar* name, out VARIANT value);
  // set the value of the named property
  /*[id(0x00000059)]*/ int setProperty(in wchar* name, in VARIANT value);
}

interface XMLDOMDocumentEvents : IDispatch {
  /*[uuid("3efaa427-272f-11d2-836f-0000f87a7782")]*/
  static GUID IID = { 0x3efaa427, 0x272f, 0x11d2, 0x83, 0x6f, 0x00, 0x00, 0xf8, 0x7a, 0x77, 0x82 };
  /+/*[id(0x000000c6)]*/ int ondataavailable();+/
  /+/*[id(0xfffffd9f)]*/ int onreadystatechange();+/
}

// IXMLHTTPRequest Interface
interface IXMLHTTPRequest : IDispatch {
  /*[uuid("ed8c108d-4349-11d2-91a4-00c04f7969e8")]*/
  static GUID IID = { 0xed8c108d, 0x4349, 0x11d2, 0x91, 0xa4, 0x00, 0xc0, 0x4f, 0x79, 0x69, 0xe8 };
  // Open HTTP connection
  /*[id(0x00000001)]*/ int open(in wchar* bstrMethod, in wchar* bstrUrl, VARIANT varAsync, VARIANT bstrUser, VARIANT bstrPassword);
  // Add HTTP request header
  /*[id(0x00000002)]*/ int setRequestHeader(in wchar* bstrHeader, in wchar* bstrValue);
  // Get HTTP response header
  /*[id(0x00000003)]*/ int getResponseHeader(in wchar* bstrHeader, out wchar* pbstrValue);
  // Get all HTTP response headers
  /*[id(0x00000004)]*/ int getAllResponseHeaders(out wchar* pbstrHeaders);
  // Send HTTP request
  /*[id(0x00000005)]*/ int send(VARIANT varBody);
  // Abort HTTP request
  /*[id(0x00000006)]*/ int abort();
  // Get HTTP status code
  /*[id(0x00000007)]*/ int get_status(out int plStatus);
  // Get HTTP status text
  /*[id(0x00000008)]*/ int get_statusText(out wchar* pbstrStatus);
  // Get response body
  /*[id(0x00000009)]*/ int get_responseXML(out IDispatch ppBody);
  // Get response body
  /*[id(0x0000000a)]*/ int get_responseText(out wchar* pbstrBody);
  // Get response body
  /*[id(0x0000000b)]*/ int get_responseBody(out VARIANT pvarBody);
  // Get response body
  /*[id(0x0000000c)]*/ int get_responseStream(out VARIANT pvarBody);
  // Get ready state
  /*[id(0x0000000d)]*/ int get_readyState(out int plState);
  // Register a complete event handler
  /*[id(0x0000000e)]*/ int set_onreadystatechange(in IDispatch value);
}

// IServerXMLHTTPRequest Interface
interface IServerXMLHTTPRequest : IXMLHTTPRequest {
  /*[uuid("2e9196bf-13ba-4dd4-91ca-6c571f281495")]*/
  static GUID IID = { 0x2e9196bf, 0x13ba, 0x4dd4, 0x91, 0xca, 0x6c, 0x57, 0x1f, 0x28, 0x14, 0x95 };
  // Specify timeout settings (in milliseconds)
  /*[id(0x0000000f)]*/ int setTimeouts(in int resolveTimeout, in int connectTimeout, in int sendTimeout, in int receiveTimeout);
  // Wait for asynchronous send to complete, with optional timeout (in seconds)
  /*[id(0x00000010)]*/ int waitForResponse(VARIANT timeoutInSeconds, out short isSuccessful);
  // Get an option value
  /*[id(0x00000011)]*/ int getOption(in SERVERXMLHTTP_OPTION option, out VARIANT value);
  // Set an option value
  /*[id(0x00000012)]*/ int setOption(in SERVERXMLHTTP_OPTION option, in VARIANT value);
}

// IServerXMLHTTPRequest2 Interface
interface IServerXMLHTTPRequest2 : IServerXMLHTTPRequest {
  /*[uuid("2e01311b-c322-4b0a-bd77-b90cfdc8dce7")]*/
  static GUID IID = { 0x2e01311b, 0xc322, 0x4b0a, 0xbd, 0x77, 0xb9, 0x0c, 0xfd, 0xc8, 0xdc, 0xe7 };
  // Specify proxy configuration
  /*[id(0x00000013)]*/ int setProxy(in SXH_PROXY_SETTING proxySetting, VARIANT varProxyServer, VARIANT varBypassList);
  // Specify proxy authentication credentials
  /*[id(0x00000014)]*/ int setProxyCredentials(in wchar* bstrUserName, in wchar* bstrPassword);
}

// IMXNamespacePrefixes interface
interface IMXNamespacePrefixes : IDispatch {
  /*[uuid("c90352f4-643c-4fbc-bb23-e996eb2d51fd")]*/
  static GUID IID = { 0xc90352f4, 0x643c, 0x4fbc, 0xbb, 0x23, 0xe9, 0x96, 0xeb, 0x2d, 0x51, 0xfd };
  /*[id(0x00000000)]*/ int get_item(in int index, out wchar* prefix);
  /*[id(0x00000588)]*/ int get_length(out int length);
  /*[id(0xfffffffc)]*/ int get__newEnum(out IUnknown ppUnk);
}

// IVBMXNamespaceManager interface
interface IVBMXNamespaceManager : IDispatch {
  /*[uuid("c90352f5-643c-4fbc-bb23-e996eb2d51fd")]*/
  static GUID IID = { 0xc90352f5, 0x643c, 0x4fbc, 0xbb, 0x23, 0xe9, 0x96, 0xeb, 0x2d, 0x51, 0xfd };
  /*[id(0x0000057e)]*/ int set_allowOverride(in short value);
  /*[id(0x0000057e)]*/ int get_allowOverride(out short fOverride);
  /*[id(0x0000057f)]*/ int reset();
  /*[id(0x00000580)]*/ int pushContext();
  /*[id(0x00000581)]*/ int pushNodeContext(in IXMLDOMNode contextNode, short fDeep);
  /*[id(0x00000582)]*/ int popContext();
  /*[id(0x00000583)]*/ int declarePrefix(in wchar* prefix, in wchar* namespaceURI);
  /*[id(0x00000584)]*/ int getDeclaredPrefixes(out IMXNamespacePrefixes prefixes);
  /*[id(0x00000585)]*/ int getPrefixes(in wchar* namespaceURI, out IMXNamespacePrefixes prefixes);
  /*[id(0x00000586)]*/ int getURI(in wchar* prefix, out VARIANT uri);
  /*[id(0x00000587)]*/ int getURIFromNode(in wchar* strPrefix, in IXMLDOMNode contextNode, out VARIANT uri);
}

// IMXNamespaceManager interface
interface IMXNamespaceManager : IUnknown {
  /*[uuid("c90352f6-643c-4fbc-bb23-e996eb2d51fd")]*/
  static GUID IID = { 0xc90352f6, 0x643c, 0x4fbc, 0xbb, 0x23, 0xe9, 0x96, 0xeb, 0x2d, 0x51, 0xfd };
  /*[id(0x60010000)]*/ int putAllowOverride(in short fOverride);
  /*[id(0x60010001)]*/ int getAllowOverride(out short fOverride);
  /*[id(0x60010002)]*/ int reset();
  /*[id(0x60010003)]*/ int pushContext();
  /*[id(0x60010004)]*/ int pushNodeContext(in IXMLDOMNode contextNode, in short fDeep);
  /*[id(0x60010005)]*/ int popContext();
  /*[id(0x60010006)]*/ int declarePrefix(in wchar* prefix, in wchar* namespaceURI);
  /*[id(0x60010007)]*/ int getDeclaredPrefix(in int nIndex, inout wchar* pwchPrefix, inout int pcchPrefix);
  /*[id(0x60010008)]*/ int getPrefix(in wchar* pwszNamespaceURI, in int nIndex, inout wchar* pwchPrefix, inout int pcchPrefix);
  /*[id(0x60010009)]*/ int getURI(in wchar* pwchPrefix, in IXMLDOMNode pContextNode, inout wchar* pwchUri, inout int pcchUri);
}

// CoClasses

// W3C-DOM XML Document (Apartment)
abstract class DOMDocument {
  /*[uuid("f6d90f11-9c73-11d3-b32e-00c04f990bb4")]*/
  static GUID CLSID = { 0xf6d90f11, 0x9c73, 0x11d3, 0xb3, 0x2e, 0x00, 0xc0, 0x4f, 0x99, 0x0b, 0xb4 };
  mixin CoInterfaces!(/*[default]*/ IXMLDOMDocument2);
}

// W3C-DOM XML Document (Apartment)
abstract class DOMDocument26 {
  /*[uuid("f5078f1b-c551-11d3-89b9-0000f81fe221")]*/
  static GUID CLSID = { 0xf5078f1b, 0xc551, 0x11d3, 0x89, 0xb9, 0x00, 0x00, 0xf8, 0x1f, 0xe2, 0x21 };
  mixin CoInterfaces!(/*[default]*/ IXMLDOMDocument2);
}

// W3C-DOM XML Document (Apartment)
abstract class DOMDocument30 {
  /*[uuid("f5078f32-c551-11d3-89b9-0000f81fe221")]*/
  static GUID CLSID = { 0xf5078f32, 0xc551, 0x11d3, 0x89, 0xb9, 0x00, 0x00, 0xf8, 0x1f, 0xe2, 0x21 };
  mixin CoInterfaces!(/*[default]*/ IXMLDOMDocument2);
}

// W3C-DOM XML Document (Apartment)
abstract class DOMDocument40 {
  /*[uuid("88d969c0-f192-11d4-a65f-0040963251e5")]*/
  static GUID CLSID = { 0x88d969c0, 0xf192, 0x11d4, 0xa6, 0x5f, 0x00, 0x40, 0x96, 0x32, 0x51, 0xe5 };
  mixin CoInterfaces!(/*[default]*/ IXMLDOMDocument2);
}

// W3C-DOM XML Document 6.0 (Apartment)
abstract class DOMDocument60 {
  /*[uuid("88d96a05-f192-11d4-a65f-0040963251e5")]*/
  static GUID CLSID = { 0x88d96a05, 0xf192, 0x11d4, 0xa6, 0x5f, 0x00, 0x40, 0x96, 0x32, 0x51, 0xe5 };
  mixin CoInterfaces!(/*[default]*/ IXMLDOMDocument3);
}

// W3C-DOM XML Document (Free threaded)
abstract class FreeThreadedDOMDocument {
  /*[uuid("f6d90f12-9c73-11d3-b32e-00c04f990bb4")]*/
  static GUID CLSID = { 0xf6d90f12, 0x9c73, 0x11d3, 0xb3, 0x2e, 0x00, 0xc0, 0x4f, 0x99, 0x0b, 0xb4 };
  mixin CoInterfaces!(/*[default]*/ IXMLDOMDocument2);
}

// W3C-DOM XML Document (Free threaded)
abstract class FreeThreadedDOMDocument26 {
  /*[uuid("f5078f1c-c551-11d3-89b9-0000f81fe221")]*/
  static GUID CLSID = { 0xf5078f1c, 0xc551, 0x11d3, 0x89, 0xb9, 0x00, 0x00, 0xf8, 0x1f, 0xe2, 0x21 };
  mixin CoInterfaces!(/*[default]*/ IXMLDOMDocument2);
}

// W3C-DOM XML Document (Free threaded)
abstract class FreeThreadedDOMDocument30 {
  /*[uuid("f5078f33-c551-11d3-89b9-0000f81fe221")]*/
  static GUID CLSID = { 0xf5078f33, 0xc551, 0x11d3, 0x89, 0xb9, 0x00, 0x00, 0xf8, 0x1f, 0xe2, 0x21 };
  mixin CoInterfaces!(/*[default]*/ IXMLDOMDocument2);
}

// W3C-DOM XML Document (Free threaded)
abstract class FreeThreadedDOMDocument40 {
  /*[uuid("88d969c1-f192-11d4-a65f-0040963251e5")]*/
  static GUID CLSID = { 0x88d969c1, 0xf192, 0x11d4, 0xa6, 0x5f, 0x00, 0x40, 0x96, 0x32, 0x51, 0xe5 };
  mixin CoInterfaces!(/*[default]*/ IXMLDOMDocument2);
}

// W3C-DOM XML Document 6.0 (Free threaded)
abstract class FreeThreadedDOMDocument60 {
  /*[uuid("88d96a06-f192-11d4-a65f-0040963251e5")]*/
  static GUID CLSID = { 0x88d96a06, 0xf192, 0x11d4, 0xa6, 0x5f, 0x00, 0x40, 0x96, 0x32, 0x51, 0xe5 };
  mixin CoInterfaces!(/*[default]*/ IXMLDOMDocument3);
}

// XML Schema Cache
abstract class XMLSchemaCache {
  /*[uuid("373984c9-b845-449b-91e7-45ac83036ade")]*/
  static GUID CLSID = { 0x373984c9, 0xb845, 0x449b, 0x91, 0xe7, 0x45, 0xac, 0x83, 0x03, 0x6a, 0xde };
  mixin CoInterfaces!(/*[default]*/ IXMLDOMSchemaCollection);
}

// XML Schema Cache 2.6
abstract class XMLSchemaCache26 {
  /*[uuid("f5078f1d-c551-11d3-89b9-0000f81fe221")]*/
  static GUID CLSID = { 0xf5078f1d, 0xc551, 0x11d3, 0x89, 0xb9, 0x00, 0x00, 0xf8, 0x1f, 0xe2, 0x21 };
  mixin CoInterfaces!(/*[default]*/ IXMLDOMSchemaCollection);
}

// XML Schema Cache 3.0
abstract class XMLSchemaCache30 {
  /*[uuid("f5078f34-c551-11d3-89b9-0000f81fe221")]*/
  static GUID CLSID = { 0xf5078f34, 0xc551, 0x11d3, 0x89, 0xb9, 0x00, 0x00, 0xf8, 0x1f, 0xe2, 0x21 };
  mixin CoInterfaces!(/*[default]*/ IXMLDOMSchemaCollection);
}

// XML Schema Cache 4.0
abstract class XMLSchemaCache40 {
  /*[uuid("88d969c2-f192-11d4-a65f-0040963251e5")]*/
  static GUID CLSID = { 0x88d969c2, 0xf192, 0x11d4, 0xa6, 0x5f, 0x00, 0x40, 0x96, 0x32, 0x51, 0xe5 };
  mixin CoInterfaces!(/*[default]*/ IXMLDOMSchemaCollection2);
}

// XML Schema Cache 6.0
abstract class XMLSchemaCache60 {
  /*[uuid("88d96a07-f192-11d4-a65f-0040963251e5")]*/
  static GUID CLSID = { 0x88d96a07, 0xf192, 0x11d4, 0xa6, 0x5f, 0x00, 0x40, 0x96, 0x32, 0x51, 0xe5 };
  mixin CoInterfaces!(/*[default]*/ IXMLDOMSchemaCollection2);
}

// Compiled XSL Stylesheet Cache
abstract class XSLTemplate {
  /*[uuid("2933bf94-7b36-11d2-b20e-00c04f983e60")]*/
  static GUID CLSID = { 0x2933bf94, 0x7b36, 0x11d2, 0xb2, 0x0e, 0x00, 0xc0, 0x4f, 0x98, 0x3e, 0x60 };
  mixin CoInterfaces!(/*[default]*/ IXSLTemplate);
}

// Compiled XSL Stylesheet Cache 2.6
abstract class XSLTemplate26 {
  /*[uuid("f5078f21-c551-11d3-89b9-0000f81fe221")]*/
  static GUID CLSID = { 0xf5078f21, 0xc551, 0x11d3, 0x89, 0xb9, 0x00, 0x00, 0xf8, 0x1f, 0xe2, 0x21 };
  mixin CoInterfaces!(/*[default]*/ IXSLTemplate);
}

// Compiled XSL Stylesheet Cache 3.0
abstract class XSLTemplate30 {
  /*[uuid("f5078f36-c551-11d3-89b9-0000f81fe221")]*/
  static GUID CLSID = { 0xf5078f36, 0xc551, 0x11d3, 0x89, 0xb9, 0x00, 0x00, 0xf8, 0x1f, 0xe2, 0x21 };
  mixin CoInterfaces!(/*[default]*/ IXSLTemplate);
}

// Compiled XSL Stylesheet Cache 4.0
abstract class XSLTemplate40 {
  /*[uuid("88d969c3-f192-11d4-a65f-0040963251e5")]*/
  static GUID CLSID = { 0x88d969c3, 0xf192, 0x11d4, 0xa6, 0x5f, 0x00, 0x40, 0x96, 0x32, 0x51, 0xe5 };
  mixin CoInterfaces!(/*[default]*/ IXSLTemplate);
}

// XSL Stylesheet Cache 6.0
abstract class XSLTemplate60 {
  /*[uuid("88d96a08-f192-11d4-a65f-0040963251e5")]*/
  static GUID CLSID = { 0x88d96a08, 0xf192, 0x11d4, 0xa6, 0x5f, 0x00, 0x40, 0x96, 0x32, 0x51, 0xe5 };
  mixin CoInterfaces!(/*[default]*/ IXSLTemplate);
}

// XML HTTP Request class.
abstract class XMLHTTP {
  /*[uuid("f6d90f16-9c73-11d3-b32e-00c04f990bb4")]*/
  static GUID CLSID = { 0xf6d90f16, 0x9c73, 0x11d3, 0xb3, 0x2e, 0x00, 0xc0, 0x4f, 0x99, 0x0b, 0xb4 };
  mixin CoInterfaces!(/*[default]*/ IXMLHTTPRequest);
}

// XML HTTP Request class.
abstract class XMLHTTP26 {
  /*[uuid("f5078f1e-c551-11d3-89b9-0000f81fe221")]*/
  static GUID CLSID = { 0xf5078f1e, 0xc551, 0x11d3, 0x89, 0xb9, 0x00, 0x00, 0xf8, 0x1f, 0xe2, 0x21 };
  mixin CoInterfaces!(/*[default]*/ IXMLHTTPRequest);
}

// XML HTTP Request class.
abstract class XMLHTTP30 {
  /*[uuid("f5078f35-c551-11d3-89b9-0000f81fe221")]*/
  static GUID CLSID = { 0xf5078f35, 0xc551, 0x11d3, 0x89, 0xb9, 0x00, 0x00, 0xf8, 0x1f, 0xe2, 0x21 };
  mixin CoInterfaces!(/*[default]*/ IXMLHTTPRequest);
}

// XML HTTP Request class.
abstract class XMLHTTP40 {
  /*[uuid("88d969c5-f192-11d4-a65f-0040963251e5")]*/
  static GUID CLSID = { 0x88d969c5, 0xf192, 0x11d4, 0xa6, 0x5f, 0x00, 0x40, 0x96, 0x32, 0x51, 0xe5 };
  mixin CoInterfaces!(/*[default]*/ IXMLHTTPRequest);
}

// XML HTTP Request class 6.0
abstract class XMLHTTP60 {
  /*[uuid("88d96a0a-f192-11d4-a65f-0040963251e5")]*/
  static GUID CLSID = { 0x88d96a0a, 0xf192, 0x11d4, 0xa6, 0x5f, 0x00, 0x40, 0x96, 0x32, 0x51, 0xe5 };
  mixin CoInterfaces!(/*[default]*/ IXMLHTTPRequest);
}

// Server XML HTTP Request class.
abstract class ServerXMLHTTP {
  /*[uuid("afba6b42-5692-48ea-8141-dc517dcf0ef1")]*/
  static GUID CLSID = { 0xafba6b42, 0x5692, 0x48ea, 0x81, 0x41, 0xdc, 0x51, 0x7d, 0xcf, 0x0e, 0xf1 };
  mixin CoInterfaces!(/*[default]*/ IServerXMLHTTPRequest);
}

// Server XML HTTP Request class.
abstract class ServerXMLHTTP30 {
  /*[uuid("afb40ffd-b609-40a3-9828-f88bbe11e4e3")]*/
  static GUID CLSID = { 0xafb40ffd, 0xb609, 0x40a3, 0x98, 0x28, 0xf8, 0x8b, 0xbe, 0x11, 0xe4, 0xe3 };
  mixin CoInterfaces!(/*[default]*/ IServerXMLHTTPRequest);
}

// Server XML HTTP Request class.
abstract class ServerXMLHTTP40 {
  /*[uuid("88d969c6-f192-11d4-a65f-0040963251e5")]*/
  static GUID CLSID = { 0x88d969c6, 0xf192, 0x11d4, 0xa6, 0x5f, 0x00, 0x40, 0x96, 0x32, 0x51, 0xe5 };
  mixin CoInterfaces!(/*[default]*/ IServerXMLHTTPRequest2);
}

// Server XML HTTP Request 6.0 
abstract class ServerXMLHTTP60 {
  /*[uuid("88d96a0b-f192-11d4-a65f-0040963251e5")]*/
  static GUID CLSID = { 0x88d96a0b, 0xf192, 0x11d4, 0xa6, 0x5f, 0x00, 0x40, 0x96, 0x32, 0x51, 0xe5 };
  mixin CoInterfaces!(/*[default]*/ IServerXMLHTTPRequest2);
}

// SAX XML Reader (version independent) coclass
abstract class SAXXMLReader {
  /*[uuid("079aa557-4a18-424a-8eee-e39f0a8d41b9")]*/
  static GUID CLSID = { 0x079aa557, 0x4a18, 0x424a, 0x8e, 0xee, 0xe3, 0x9f, 0x0a, 0x8d, 0x41, 0xb9 };
  mixin CoInterfaces!(/*[default]*/ IVBSAXXMLReader, ISAXXMLReader, IMXReaderControl);
}

// SAX XML Reader 3.0 coclass
abstract class SAXXMLReader30 {
  /*[uuid("3124c396-fb13-4836-a6ad-1317f1713688")]*/
  static GUID CLSID = { 0x3124c396, 0xfb13, 0x4836, 0xa6, 0xad, 0x13, 0x17, 0xf1, 0x71, 0x36, 0x88 };
  mixin CoInterfaces!(/*[default]*/ IVBSAXXMLReader, ISAXXMLReader, IMXReaderControl);
}

// SAX XML Reader 4.0 coclass
abstract class SAXXMLReader40 {
  /*[uuid("7c6e29bc-8b8b-4c3d-859e-af6cd158be0f")]*/
  static GUID CLSID = { 0x7c6e29bc, 0x8b8b, 0x4c3d, 0x85, 0x9e, 0xaf, 0x6c, 0xd1, 0x58, 0xbe, 0x0f };
  mixin CoInterfaces!(/*[default]*/ IVBSAXXMLReader, ISAXXMLReader);
}

// SAX XML Reader 6.0
abstract class SAXXMLReader60 {
  /*[uuid("88d96a0c-f192-11d4-a65f-0040963251e5")]*/
  static GUID CLSID = { 0x88d96a0c, 0xf192, 0x11d4, 0xa6, 0x5f, 0x00, 0x40, 0x96, 0x32, 0x51, 0xe5 };
  mixin CoInterfaces!(/*[default]*/ IVBSAXXMLReader, ISAXXMLReader);
}

// Microsoft XML Writer (version independent) coclass
abstract class MXXMLWriter {
  /*[uuid("fc220ad8-a72a-4ee8-926e-0b7ad152a020")]*/
  static GUID CLSID = { 0xfc220ad8, 0xa72a, 0x4ee8, 0x92, 0x6e, 0x0b, 0x7a, 0xd1, 0x52, 0xa0, 0x20 };
  mixin CoInterfaces!(/*[default]*/ IMXWriter, ISAXContentHandler, ISAXErrorHandler, ISAXDTDHandler, ISAXLexicalHandler, ISAXDeclHandler, IVBSAXContentHandler, IVBSAXDeclHandler, IVBSAXDTDHandler, IVBSAXErrorHandler, IVBSAXLexicalHandler);
}

// Microsoft XML Writer 3.0 coclass
abstract class MXXMLWriter30 {
  /*[uuid("3d813dfe-6c91-4a4e-8f41-04346a841d9c")]*/
  static GUID CLSID = { 0x3d813dfe, 0x6c91, 0x4a4e, 0x8f, 0x41, 0x04, 0x34, 0x6a, 0x84, 0x1d, 0x9c };
  mixin CoInterfaces!(/*[default]*/ IMXWriter, ISAXContentHandler, ISAXDeclHandler, ISAXDTDHandler, ISAXErrorHandler, ISAXLexicalHandler, IVBSAXContentHandler, IVBSAXDeclHandler, IVBSAXDTDHandler, IVBSAXErrorHandler, IVBSAXLexicalHandler);
}

// Microsoft XML Writer 4.0 coclass
abstract class MXXMLWriter40 {
  /*[uuid("88d969c8-f192-11d4-a65f-0040963251e5")]*/
  static GUID CLSID = { 0x88d969c8, 0xf192, 0x11d4, 0xa6, 0x5f, 0x00, 0x40, 0x96, 0x32, 0x51, 0xe5 };
  mixin CoInterfaces!(/*[default]*/ IMXWriter, ISAXContentHandler, ISAXDeclHandler, ISAXDTDHandler, ISAXErrorHandler, ISAXLexicalHandler, IVBSAXContentHandler, IVBSAXDeclHandler, IVBSAXDTDHandler, IVBSAXErrorHandler, IVBSAXLexicalHandler);
}

// Microsoft XML Writer 6.0
abstract class MXXMLWriter60 {
  /*[uuid("88d96a0f-f192-11d4-a65f-0040963251e5")]*/
  static GUID CLSID = { 0x88d96a0f, 0xf192, 0x11d4, 0xa6, 0x5f, 0x00, 0x40, 0x96, 0x32, 0x51, 0xe5 };
  mixin CoInterfaces!(/*[default]*/ IMXWriter, ISAXContentHandler, ISAXDeclHandler, ISAXDTDHandler, ISAXErrorHandler, ISAXLexicalHandler, IVBSAXContentHandler, IVBSAXDeclHandler, IVBSAXDTDHandler, IVBSAXErrorHandler, IVBSAXLexicalHandler);
}

// Microsoft HTML Writer (version independent) coclass
abstract class MXHTMLWriter {
  /*[uuid("a4c23ec3-6b70-4466-9127-550077239978")]*/
  static GUID CLSID = { 0xa4c23ec3, 0x6b70, 0x4466, 0x91, 0x27, 0x55, 0x00, 0x77, 0x23, 0x99, 0x78 };
  mixin CoInterfaces!(/*[default]*/ IMXWriter, ISAXContentHandler, ISAXErrorHandler, ISAXDTDHandler, ISAXLexicalHandler, ISAXDeclHandler, IVBSAXContentHandler, IVBSAXDeclHandler, IVBSAXDTDHandler, IVBSAXErrorHandler, IVBSAXLexicalHandler);
}

// Microsoft HTML Writer 3.0 coclass
abstract class MXHTMLWriter30 {
  /*[uuid("853d1540-c1a7-4aa9-a226-4d3bd301146d")]*/
  static GUID CLSID = { 0x853d1540, 0xc1a7, 0x4aa9, 0xa2, 0x26, 0x4d, 0x3b, 0xd3, 0x01, 0x14, 0x6d };
  mixin CoInterfaces!(/*[default]*/ IMXWriter, ISAXContentHandler, ISAXDeclHandler, ISAXDTDHandler, ISAXErrorHandler, ISAXLexicalHandler, IVBSAXContentHandler, IVBSAXDeclHandler, IVBSAXDTDHandler, IVBSAXErrorHandler, IVBSAXLexicalHandler);
}

// Microsoft HTML Writer 4.0 coclass
abstract class MXHTMLWriter40 {
  /*[uuid("88d969c9-f192-11d4-a65f-0040963251e5")]*/
  static GUID CLSID = { 0x88d969c9, 0xf192, 0x11d4, 0xa6, 0x5f, 0x00, 0x40, 0x96, 0x32, 0x51, 0xe5 };
  mixin CoInterfaces!(/*[default]*/ IMXWriter, ISAXContentHandler, ISAXDeclHandler, ISAXDTDHandler, ISAXErrorHandler, ISAXLexicalHandler, IVBSAXContentHandler, IVBSAXDeclHandler, IVBSAXDTDHandler, IVBSAXErrorHandler, IVBSAXLexicalHandler);
}

// Microsoft HTML Writer 6.0
abstract class MXHTMLWriter60 {
  /*[uuid("88d96a10-f192-11d4-a65f-0040963251e5")]*/
  static GUID CLSID = { 0x88d96a10, 0xf192, 0x11d4, 0xa6, 0x5f, 0x00, 0x40, 0x96, 0x32, 0x51, 0xe5 };
  mixin CoInterfaces!(/*[default]*/ IMXWriter, ISAXContentHandler, ISAXDeclHandler, ISAXDTDHandler, ISAXErrorHandler, ISAXLexicalHandler, IVBSAXContentHandler, IVBSAXDeclHandler, IVBSAXDTDHandler, IVBSAXErrorHandler, IVBSAXLexicalHandler);
}

// SAX Attributes (version independent) coclass
abstract class SAXAttributes {
  /*[uuid("4dd441ad-526d-4a77-9f1b-9841ed802fb0")]*/
  static GUID CLSID = { 0x4dd441ad, 0x526d, 0x4a77, 0x9f, 0x1b, 0x98, 0x41, 0xed, 0x80, 0x2f, 0xb0 };
  mixin CoInterfaces!(/*[default]*/ IMXAttributes, IVBSAXAttributes, ISAXAttributes);
}

// SAX Attributes 3.0 coclass
abstract class SAXAttributes30 {
  /*[uuid("3e784a01-f3ae-4dc0-9354-9526b9370eba")]*/
  static GUID CLSID = { 0x3e784a01, 0xf3ae, 0x4dc0, 0x93, 0x54, 0x95, 0x26, 0xb9, 0x37, 0x0e, 0xba };
  mixin CoInterfaces!(/*[default]*/ IMXAttributes, IVBSAXAttributes, ISAXAttributes);
}

// SAX Attributes 4.0 coclass
abstract class SAXAttributes40 {
  /*[uuid("88d969ca-f192-11d4-a65f-0040963251e5")]*/
  static GUID CLSID = { 0x88d969ca, 0xf192, 0x11d4, 0xa6, 0x5f, 0x00, 0x40, 0x96, 0x32, 0x51, 0xe5 };
  mixin CoInterfaces!(/*[default]*/ IMXAttributes, IVBSAXAttributes, ISAXAttributes);
}

// SAX Attributes 6.0
abstract class SAXAttributes60 {
  /*[uuid("88d96a0e-f192-11d4-a65f-0040963251e5")]*/
  static GUID CLSID = { 0x88d96a0e, 0xf192, 0x11d4, 0xa6, 0x5f, 0x00, 0x40, 0x96, 0x32, 0x51, 0xe5 };
  mixin CoInterfaces!(/*[default]*/ IMXAttributes, IVBSAXAttributes, ISAXAttributes);
}

// MX Namespace Manager coclass
abstract class MXNamespaceManager {
  /*[uuid("88d969d5-f192-11d4-a65f-0040963251e5")]*/
  static GUID CLSID = { 0x88d969d5, 0xf192, 0x11d4, 0xa6, 0x5f, 0x00, 0x40, 0x96, 0x32, 0x51, 0xe5 };
  mixin CoInterfaces!(/*[default]*/ IVBMXNamespaceManager, IMXNamespaceManager);
}

// MX Namespace Manager 4.0 coclass
abstract class MXNamespaceManager40 {
  /*[uuid("88d969d6-f192-11d4-a65f-0040963251e5")]*/
  static GUID CLSID = { 0x88d969d6, 0xf192, 0x11d4, 0xa6, 0x5f, 0x00, 0x40, 0x96, 0x32, 0x51, 0xe5 };
  mixin CoInterfaces!(/*[default]*/ IVBMXNamespaceManager, IMXNamespaceManager);
}

// MX Namespace Manager 6.0
abstract class MXNamespaceManager60 {
  /*[uuid("88d96a11-f192-11d4-a65f-0040963251e5")]*/
  static GUID CLSID = { 0x88d96a11, 0xf192, 0x11d4, 0xa6, 0x5f, 0x00, 0x40, 0x96, 0x32, 0x51, 0xe5 };
  mixin CoInterfaces!(/*[default]*/ IVBMXNamespaceManager, IMXNamespaceManager);
}
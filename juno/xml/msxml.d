// Microsoft XML, v6.0
// Version 6.0

/*[uuid("f5078f18-c551-11d3-89b9-0000f81fe221")]*/
module juno.xml.msxml;

/*[importlib("stdole2.tlb")]*/
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
  NODE_DOCUMENT_TYPE = 0x0000000A,
  NODE_DOCUMENT_FRAGMENT = 0x0000000B,
  NODE_NOTATION = 0x0000000C,
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
  SOMITEM_DATATYPE_DOUBLE = 0x0000210A,
  SOMITEM_DATATYPE_DURATION = 0x0000210B,
  SOMITEM_DATATYPE_ENTITIES = 0x0000210C,
  SOMITEM_DATATYPE_ENTITY = 0x0000210D,
  SOMITEM_DATATYPE_FLOAT = 0x0000210E,
  SOMITEM_DATATYPE_HEXBINARY = 0x0000210F,
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
  SOMITEM_DATATYPE_NCNAME = 0x0000211A,
  SOMITEM_DATATYPE_NEGATIVEINTEGER = 0x0000211B,
  SOMITEM_DATATYPE_NMTOKEN = 0x0000211C,
  SOMITEM_DATATYPE_NMTOKENS = 0x0000211D,
  SOMITEM_DATATYPE_NONNEGATIVEINTEGER = 0x0000211E,
  SOMITEM_DATATYPE_NONPOSITIVEINTEGER = 0x0000211F,
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
  SOMITEM_DATATYPE_UNSIGNEDLONG = 0x0000212A,
  SOMITEM_DATATYPE_UNSIGNEDSHORT = 0x0000212B,
  SOMITEM_DATATYPE_YEAR = 0x0000212C,
  SOMITEM_DATATYPE_YEARMONTH = 0x0000212D,
  SOMITEM_DATATYPE_ANYSIMPLETYPE = 0x000021FF,
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
  SCHEMADERIVATIONMETHOD_ALL = 0x000000FF,
  SCHEMADERIVATIONMETHOD_NONE = 0x00000100,
}

// Schema Object Model Type variety values
enum _SCHEMATYPEVARIETY {
  SCHEMATYPEVARIETY_NONE = 0xFFFFFFFF,
  SCHEMATYPEVARIETY_ATOMIC = 0x00000000,
  SCHEMATYPEVARIETY_LIST = 0x00000001,
  SCHEMATYPEVARIETY_UNION = 0x00000002,
}

// Schema Object Model Whitespace facet values
enum _SCHEMAWHITESPACE {
  SCHEMAWHITESPACE_NONE = 0xFFFFFFFF,
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
  SXH_OPTION_URL = 0xFFFFFFFF,
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
  mixin(uuid("2933bf8f-7b36-11d2-b20e-00c04f983e60"));
  /*[id(0x00000091)]*/ int hasFeature(wchar* feature, wchar* versionParam, out short hasFeature);
}

// Core DOM node interface
interface IXMLDOMNode : IDispatch {
  mixin(uuid("2933bf80-7b36-11d2-b20e-00c04f983e60"));
  // name of the node
  /*[id(0x00000002)]*/ int get_nodeName(out wchar* name);
  // value stored in the node
  /*[id(0x00000003)]*/ int get_nodeValue(out VARIANT value);
  // value stored in the node
  /*[id(0x00000003)]*/ int put_nodeValue(VARIANT value);
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
  /*[id(0x0000000A)]*/ int get_previousSibling(out IXMLDOMNode previousSibling);
  // right sibling of the node
  /*[id(0x0000000B)]*/ int get_nextSibling(out IXMLDOMNode nextSibling);
  // the collection of the node's attributes
  /*[id(0x0000000C)]*/ int get_attributes(out IXMLDOMNamedNodeMap attributeMap);
  // insert a child node
  /*[id(0x0000000D)]*/ int insertBefore(IXMLDOMNode newChild, VARIANT refChild, out IXMLDOMNode outNewChild);
  // replace a child node
  /*[id(0x0000000E)]*/ int replaceChild(IXMLDOMNode newChild, IXMLDOMNode oldChild, out IXMLDOMNode outOldChild);
  // remove a child node
  /*[id(0x0000000F)]*/ int removeChild(IXMLDOMNode childNode, out IXMLDOMNode oldChild);
  // append a child node
  /*[id(0x00000010)]*/ int appendChild(IXMLDOMNode newChild, out IXMLDOMNode outNewChild);
  /*[id(0x00000011)]*/ int hasChildNodes(out short hasChild);
  // document that contains the node
  /*[id(0x00000012)]*/ int get_ownerDocument(out IXMLDOMDocument DOMDocument);
  /*[id(0x00000013)]*/ int cloneNode(short deep, out IXMLDOMNode cloneRoot);
  // the type of node in string form
  /*[id(0x00000015)]*/ int get_nodeTypeString(out wchar* nodeType);
  // text content of the node and subtree
  /*[id(0x00000018)]*/ int get_text(out wchar* text);
  // text content of the node and subtree
  /*[id(0x00000018)]*/ int put_text(wchar* text);
  // indicates whether node is a default value
  /*[id(0x00000016)]*/ int get_specified(out short isSpecified);
  // pointer to the definition of the node in the DTD or schema
  /*[id(0x00000017)]*/ int get_definition(out IXMLDOMNode definitionNode);
  // get the strongly typed value of the node
  /*[id(0x00000019)]*/ int get_nodeTypedValue(out VARIANT typedValue);
  // get the strongly typed value of the node
  /*[id(0x00000019)]*/ int put_nodeTypedValue(VARIANT typedValue);
  // the data type of the node
  /*[id(0x0000001A)]*/ int get_dataType(out VARIANT dataTypeName);
  // the data type of the node
  /*[id(0x0000001A)]*/ int put_dataType(wchar* dataTypeName);
  // return the XML source for the node and each of its descendants
  /*[id(0x0000001B)]*/ int get_xml(out wchar* xmlString);
  // apply the stylesheet to the subtree
  /*[id(0x0000001C)]*/ int transformNode(IXMLDOMNode stylesheet, out wchar* xmlString);
  // execute query on the subtree
  /*[id(0x0000001D)]*/ int selectNodes(wchar* queryString, out IXMLDOMNodeList resultList);
  // execute query on the subtree
  /*[id(0x0000001E)]*/ int selectSingleNode(wchar* queryString, out IXMLDOMNode resultNode);
  // has sub-tree been completely parsed
  /*[id(0x0000001F)]*/ int get_parsed(out short isParsed);
  // the URI for the namespace applying to the node
  /*[id(0x00000020)]*/ int get_namespaceURI(out wchar* namespaceURI);
  // the prefix for the namespace applying to the node
  /*[id(0x00000021)]*/ int get_prefix(out wchar* prefixString);
  // the base name of the node (nodename with the prefix stripped off)
  /*[id(0x00000022)]*/ int get_baseName(out wchar* nameString);
  // apply the stylesheet to the subtree, returning the result through a document or a stream
  /*[id(0x00000023)]*/ int transformNodeToObject(IXMLDOMNode stylesheet, VARIANT outputObject);
}

interface IXMLDOMNodeList : IDispatch {
  mixin(uuid("2933bf82-7b36-11d2-b20e-00c04f983e60"));
  // collection of nodes
  /*[id(0x00000000)]*/ int get_item(int index, out IXMLDOMNode listItem);
  // number of nodes in the collection
  /*[id(0x0000004A)]*/ int get_length(out int listLength);
  // get next node from iterator
  /*[id(0x0000004C)]*/ int nextNode(out IXMLDOMNode nextItem);
  // reset the position of iterator
  /*[id(0x0000004D)]*/ int reset();
  /*[id(0xFFFFFFFC)]*/ int get__newEnum(out IUnknown ppUnk);
}

interface IXMLDOMNamedNodeMap : IDispatch {
  mixin(uuid("2933bf83-7b36-11d2-b20e-00c04f983e60"));
  // lookup item by name
  /*[id(0x00000053)]*/ int getNamedItem(wchar* name, out IXMLDOMNode namedItem);
  // set item by name
  /*[id(0x00000054)]*/ int setNamedItem(IXMLDOMNode newItem, out IXMLDOMNode nameItem);
  // remove item by name
  /*[id(0x00000055)]*/ int removeNamedItem(wchar* name, out IXMLDOMNode namedItem);
  // collection of nodes
  /*[id(0x00000000)]*/ int get_item(int index, out IXMLDOMNode listItem);
  // number of nodes in the collection
  /*[id(0x0000004A)]*/ int get_length(out int listLength);
  // lookup the item by name and namespace
  /*[id(0x00000057)]*/ int getQualifiedItem(wchar* baseName, wchar* namespaceURI, out IXMLDOMNode qualifiedItem);
  // remove the item by name and namespace
  /*[id(0x00000058)]*/ int removeQualifiedItem(wchar* baseName, wchar* namespaceURI, out IXMLDOMNode qualifiedItem);
  // get next node from iterator
  /*[id(0x00000059)]*/ int nextNode(out IXMLDOMNode nextItem);
  // reset the position of iterator
  /*[id(0x0000005A)]*/ int reset();
  /*[id(0xFFFFFFFC)]*/ int get__newEnum(out IUnknown ppUnk);
}

interface IXMLDOMDocument : IXMLDOMNode {
  mixin(uuid("2933bf81-7b36-11d2-b20e-00c04f983e60"));
  // node corresponding to the DOCTYPE
  /*[id(0x00000026)]*/ int get_doctype(out IXMLDOMDocumentType documentType);
  // info on this DOM implementation
  /*[id(0x00000027)]*/ int get_implementation(out IXMLDOMImplementation impl);
  // the root of the tree
  /*[id(0x00000028)]*/ int get_documentElement(out IXMLDOMElement DOMElement);
  // the root of the tree
  /*[id(0x00000028)]*/ int putref_documentElement(IXMLDOMElement DOMElement);
  // create an Element node
  /*[id(0x00000029)]*/ int createElement(wchar* tagName, out IXMLDOMElement element);
  // create a DocumentFragment node
  /*[id(0x0000002A)]*/ int createDocumentFragment(out IXMLDOMDocumentFragment docFrag);
  // create a text node
  /*[id(0x0000002B)]*/ int createTextNode(wchar* data, out IXMLDOMText text);
  // create a comment node
  /*[id(0x0000002C)]*/ int createComment(wchar* data, out IXMLDOMComment comment);
  // create a CDATA section node
  /*[id(0x0000002D)]*/ int createCDATASection(wchar* data, out IXMLDOMCDATASection cdata);
  // create a processing instruction node
  /*[id(0x0000002E)]*/ int createProcessingInstruction(wchar* target, wchar* data, out IXMLDOMProcessingInstruction pi);
  // create an attribute node
  /*[id(0x0000002F)]*/ int createAttribute(wchar* name, out IXMLDOMAttribute attribute);
  // create an entity reference node
  /*[id(0x00000031)]*/ int createEntityReference(wchar* name, out IXMLDOMEntityReference entityRef);
  // build a list of elements by name
  /*[id(0x00000032)]*/ int getElementsByTagName(wchar* tagName, out IXMLDOMNodeList resultList);
  // create a node of the specified node type and name
  /*[id(0x00000036)]*/ int createNode(VARIANT type, wchar* name, wchar* namespaceURI, out IXMLDOMNode node);
  // retrieve node from it's ID
  /*[id(0x00000038)]*/ int nodeFromID(wchar* idString, out IXMLDOMNode node);
  // load document from the specified XML source
  /*[id(0x0000003A)]*/ int load(VARIANT xmlSource, out short isSuccessful);
  // get the state of the XML document
  /*[id(0xFFFFFDF3)]*/ int get_readyState(out int value);
  // get the last parser error
  /*[id(0x0000003B)]*/ int get_parseError(out IXMLDOMParseError errorObj);
  // get the URL for the loaded XML document
  /*[id(0x0000003C)]*/ int get_url(out wchar* urlString);
  // flag for asynchronous download
  /*[id(0x0000003D)]*/ int get_async(out short isAsync);
  // flag for asynchronous download
  /*[id(0x0000003D)]*/ int put_async(short isAsync);
  // abort an asynchronous download
  /*[id(0x0000003E)]*/ int abort();
  // load the document from a string
  /*[id(0x0000003F)]*/ int loadXML(wchar* bstrXML, out short isSuccessful);
  // save the document to a specified destination
  /*[id(0x00000040)]*/ int save(VARIANT destination);
  // indicates whether the parser performs validation
  /*[id(0x00000041)]*/ int get_validateOnParse(out short isValidating);
  // indicates whether the parser performs validation
  /*[id(0x00000041)]*/ int put_validateOnParse(short isValidating);
  // indicates whether the parser resolves references to external DTD/Entities/Schema
  /*[id(0x00000042)]*/ int get_resolveExternals(out short isResolving);
  // indicates whether the parser resolves references to external DTD/Entities/Schema
  /*[id(0x00000042)]*/ int put_resolveExternals(short isResolving);
  // indicates whether the parser preserves whitespace
  /*[id(0x00000043)]*/ int get_preserveWhiteSpace(out short isPreserving);
  // indicates whether the parser preserves whitespace
  /*[id(0x00000043)]*/ int put_preserveWhiteSpace(short isPreserving);
  // register a readystatechange event handler
  /*[id(0x00000044)]*/ int put_onreadystatechange(VARIANT value);
  // register an ondataavailable event handler
  /*[id(0x00000045)]*/ int put_ondataavailable(VARIANT value);
  // register an ontransformnode event handler
  /*[id(0x00000046)]*/ int put_ontransformnode(VARIANT value);
}

interface IXMLDOMDocumentType : IXMLDOMNode {
  mixin(uuid("2933bf8b-7b36-11d2-b20e-00c04f983e60"));
  // name of the document type (root of the tree)
  /*[id(0x00000083)]*/ int get_name(out wchar* rootName);
  // a list of entities in the document
  /*[id(0x00000084)]*/ int get_entities(out IXMLDOMNamedNodeMap entityMap);
  // a list of notations in the document
  /*[id(0x00000085)]*/ int get_notations(out IXMLDOMNamedNodeMap notationMap);
}

interface IXMLDOMElement : IXMLDOMNode {
  mixin(uuid("2933bf86-7b36-11d2-b20e-00c04f983e60"));
  // get the tagName of the element
  /*[id(0x00000061)]*/ int get_tagName(out wchar* tagName);
  // look up the string value of an attribute by name
  /*[id(0x00000063)]*/ int getAttribute(wchar* name, out VARIANT value);
  // set the string value of an attribute by name
  /*[id(0x00000064)]*/ int setAttribute(wchar* name, VARIANT value);
  // remove an attribute by name
  /*[id(0x00000065)]*/ int removeAttribute(wchar* name);
  // look up the attribute node by name
  /*[id(0x00000066)]*/ int getAttributeNode(wchar* name, out IXMLDOMAttribute attributeNode);
  // set the specified attribute on the element
  /*[id(0x00000067)]*/ int setAttributeNode(IXMLDOMAttribute DOMAttribute, out IXMLDOMAttribute attributeNode);
  // remove the specified attribute
  /*[id(0x00000068)]*/ int removeAttributeNode(IXMLDOMAttribute DOMAttribute, out IXMLDOMAttribute attributeNode);
  // build a list of elements by name
  /*[id(0x00000069)]*/ int getElementsByTagName(wchar* tagName, out IXMLDOMNodeList resultList);
  // collapse all adjacent text nodes in sub-tree
  /*[id(0x0000006A)]*/ int normalize();
}

interface IXMLDOMAttribute : IXMLDOMNode {
  mixin(uuid("2933bf85-7b36-11d2-b20e-00c04f983e60"));
  // get name of the attribute
  /*[id(0x00000076)]*/ int get_name(out wchar* attributeName);
  // string value of the attribute
  /*[id(0x00000078)]*/ int get_value(out VARIANT attributeValue);
  // string value of the attribute
  /*[id(0x00000078)]*/ int put_value(VARIANT attributeValue);
}

interface IXMLDOMDocumentFragment : IXMLDOMNode {
  mixin(uuid("3efaa413-272f-11d2-836f-0000f87a7782"));
}

interface IXMLDOMText : IXMLDOMCharacterData {
  mixin(uuid("2933bf87-7b36-11d2-b20e-00c04f983e60"));
  // split the text node into two text nodes at the position specified
  /*[id(0x0000007B)]*/ int splitText(int offset, out IXMLDOMText rightHandTextNode);
}

interface IXMLDOMCharacterData : IXMLDOMNode {
  mixin(uuid("2933bf84-7b36-11d2-b20e-00c04f983e60"));
  // value of the node
  /*[id(0x0000006D)]*/ int get_data(out wchar* data);
  // value of the node
  /*[id(0x0000006D)]*/ int put_data(wchar* data);
  // number of characters in value
  /*[id(0x0000006E)]*/ int get_length(out int dataLength);
  // retrieve substring of value
  /*[id(0x0000006F)]*/ int substringData(int offset, int count, out wchar* data);
  // append string to value
  /*[id(0x00000070)]*/ int appendData(wchar* data);
  // insert string into value
  /*[id(0x00000071)]*/ int insertData(int offset, wchar* data);
  // delete string within the value
  /*[id(0x00000072)]*/ int deleteData(int offset, int count);
  // replace string within the value
  /*[id(0x00000073)]*/ int replaceData(int offset, int count, wchar* data);
}

interface IXMLDOMComment : IXMLDOMCharacterData {
  mixin(uuid("2933bf88-7b36-11d2-b20e-00c04f983e60"));
}

interface IXMLDOMCDATASection : IXMLDOMText {
  mixin(uuid("2933bf8a-7b36-11d2-b20e-00c04f983e60"));
}

interface IXMLDOMProcessingInstruction : IXMLDOMNode {
  mixin(uuid("2933bf89-7b36-11d2-b20e-00c04f983e60"));
  // the target
  /*[id(0x0000007F)]*/ int get_target(out wchar* name);
  // the data
  /*[id(0x00000080)]*/ int get_data(out wchar* value);
  // the data
  /*[id(0x00000080)]*/ int put_data(wchar* value);
}

interface IXMLDOMEntityReference : IXMLDOMNode {
  mixin(uuid("2933bf8e-7b36-11d2-b20e-00c04f983e60"));
}

// structure for reporting parser errors
interface IXMLDOMParseError : IDispatch {
  mixin(uuid("3efaa426-272f-11d2-836f-0000f87a7782"));
  // the error code
  /*[id(0x00000000)]*/ int get_errorCode(out int errorCode);
  // the URL of the XML document containing the error
  /*[id(0x000000B3)]*/ int get_url(out wchar* urlString);
  // the cause of the error
  /*[id(0x000000B4)]*/ int get_reason(out wchar* reasonString);
  // the data where the error occurred
  /*[id(0x000000B5)]*/ int get_srcText(out wchar* sourceString);
  // the line number in the XML document where the error occurred
  /*[id(0x000000B6)]*/ int get_line(out int lineNumber);
  // the character position in the line containing the error
  /*[id(0x000000B7)]*/ int get_linepos(out int linePosition);
  // the absolute file position in the XML document containing the error
  /*[id(0x000000B8)]*/ int get_filepos(out int filePosition);
}

interface IXMLDOMDocument2 : IXMLDOMDocument {
  mixin(uuid("2933bf95-7b36-11d2-b20e-00c04f983e60"));
  // A collection of all namespaces for this document
  /*[id(0x000000C9)]*/ int get_namespaces(out IXMLDOMSchemaCollection namespaceCollection);
  // The associated schema cache
  /*[id(0x000000CA)]*/ int get_schemas(out VARIANT otherCollection);
  // The associated schema cache
  /*[id(0x000000CA)]*/ int putref_schemas(VARIANT otherCollection);
  // perform runtime validation on the currently loaded XML document
  /*[id(0x000000CB)]*/ int validate(out IXMLDOMParseError errorObj);
  // set the value of the named property
  /*[id(0x000000CC)]*/ int setProperty(wchar* name, VARIANT value);
  // get the value of the named property
  /*[id(0x000000CD)]*/ int getProperty(wchar* name, out VARIANT value);
}

// XML Schemas Collection
interface IXMLDOMSchemaCollection : IDispatch {
  mixin(uuid("373984c8-b845-449b-91e7-45ac83036ade"));
  // add a new schema
  /*[id(0x00000003)]*/ int add(wchar* namespaceURI, VARIANT var);
  // lookup schema by namespaceURI
  /*[id(0x00000004)]*/ int get(wchar* namespaceURI, out IXMLDOMNode schemaNode);
  // remove schema by namespaceURI
  /*[id(0x00000005)]*/ int remove(wchar* namespaceURI);
  // number of schemas in collection
  /*[id(0x00000006)]*/ int get_length(out int length);
  // Get namespaceURI for schema by index
  /*[id(0x00000000)]*/ int get_namespaceURI(int index, out wchar* length);
  // copy & merge other collection into this one
  /*[id(0x00000008)]*/ int addCollection(IXMLDOMSchemaCollection otherCollection);
  /*[id(0xFFFFFFFC)]*/ int get__newEnum(out IUnknown ppUnk);
}

interface IXMLDOMDocument3 : IXMLDOMDocument2 {
  mixin(uuid("2933bf96-7b36-11d2-b20e-00c04f983e60"));
  // perform runtime validation on the currently loaded XML document node
  /*[id(0x000000D0)]*/ int validateNode(IXMLDOMNode node, out IXMLDOMParseError errorObj);
  // clone node such that clones ownerDocument is this document
  /*[id(0x000000D1)]*/ int importNode(IXMLDOMNode node, short deep, out IXMLDOMNode clone);
}

interface IXMLDOMNotation : IXMLDOMNode {
  mixin(uuid("2933bf8c-7b36-11d2-b20e-00c04f983e60"));
  // the public ID
  /*[id(0x00000088)]*/ int get_publicId(out VARIANT publicId);
  // the system ID
  /*[id(0x00000089)]*/ int get_systemId(out VARIANT systemId);
}

interface IXMLDOMEntity : IXMLDOMNode {
  mixin(uuid("2933bf8d-7b36-11d2-b20e-00c04f983e60"));
  // the public ID
  /*[id(0x0000008C)]*/ int get_publicId(out VARIANT publicId);
  // the system ID
  /*[id(0x0000008D)]*/ int get_systemId(out VARIANT systemId);
  // the name of the notation
  /*[id(0x0000008E)]*/ int get_notationName(out wchar* name);
}

// structure for reporting parser errors
interface IXMLDOMParseError2 : IXMLDOMParseError {
  mixin(uuid("3efaa428-272f-11d2-836f-0000f87a7782"));
  /*[id(0x000000BE)]*/ int get_errorXPath(out wchar* xpathexpr);
  /*[id(0x000000BB)]*/ int get_allErrors(out IXMLDOMParseErrorCollection allErrors);
  /*[id(0x000000BC)]*/ int errorParameters(int index, out wchar* param);
  /*[id(0x000000BD)]*/ int get_errorParametersCount(out int count);
}

// structure for reporting parser errors
interface IXMLDOMParseErrorCollection : IDispatch {
  mixin(uuid("3efaa429-272f-11d2-836f-0000f87a7782"));
  /*[id(0x00000000)]*/ int get_item(int index, out IXMLDOMParseError2 error);
  /*[id(0x000000C1)]*/ int get_length(out int length);
  /*[id(0x000000C2)]*/ int get_next(out IXMLDOMParseError2 error);
  /*[id(0x000000C3)]*/ int reset();
  /*[id(0xFFFFFFFC)]*/ int get__newEnum(out IUnknown ppUnk);
}

// XTL runtime object
interface IXTLRuntime : IXMLDOMNode {
  mixin(uuid("3efaa425-272f-11d2-836f-0000f87a7782"));
  /*[id(0x000000BB)]*/ int uniqueID(IXMLDOMNode pNode, out int pID);
  /*[id(0x000000BC)]*/ int depth(IXMLDOMNode pNode, out int pDepth);
  /*[id(0x000000BD)]*/ int childNumber(IXMLDOMNode pNode, out int pNumber);
  /*[id(0x000000BE)]*/ int ancestorChildNumber(wchar* bstrNodeName, IXMLDOMNode pNode, out int pNumber);
  /*[id(0x000000BF)]*/ int absoluteChildNumber(IXMLDOMNode pNode, out int pNumber);
  /*[id(0x000000C0)]*/ int formatIndex(int lIndex, wchar* bstrFormat, out wchar* pbstrFormattedString);
  /*[id(0x000000C1)]*/ int formatNumber(double dblNumber, wchar* bstrFormat, out wchar* pbstrFormattedString);
  /*[id(0x000000C2)]*/ int formatDate(VARIANT varDate, wchar* bstrFormat, VARIANT varDestLocale, out wchar* pbstrFormattedString);
  /*[id(0x000000C3)]*/ int formatTime(VARIANT varTime, wchar* bstrFormat, VARIANT varDestLocale, out wchar* pbstrFormattedString);
}

// IXSLTemplate Interface
interface IXSLTemplate : IDispatch {
  mixin(uuid("2933bf93-7b36-11d2-b20e-00c04f983e60"));
  // stylesheet to use with processors
  /*[id(0x00000002)]*/ int putref_stylesheet(IXMLDOMNode stylesheet);
  // stylesheet to use with processors
  /*[id(0x00000002)]*/ int get_stylesheet(out IXMLDOMNode stylesheet);
  // create a new processor object
  /*[id(0x00000003)]*/ int createProcessor(out IXSLProcessor ppProcessor);
}

// IXSLProcessor Interface
interface IXSLProcessor : IDispatch {
  mixin(uuid("2933bf92-7b36-11d2-b20e-00c04f983e60"));
  // XML input tree to transform
  /*[id(0x00000002)]*/ int put_input(VARIANT pVar);
  // XML input tree to transform
  /*[id(0x00000002)]*/ int get_input(out VARIANT pVar);
  // template object used to create this processor object
  /*[id(0x00000003)]*/ int get_ownerTemplate(out IXSLTemplate ppTemplate);
  // set XSL mode and it's namespace
  /*[id(0x00000004)]*/ int setStartMode(wchar* mode, wchar* namespaceURI);
  // starting XSL mode
  /*[id(0x00000005)]*/ int get_startMode(out wchar* mode);
  // namespace of starting XSL mode
  /*[id(0x00000006)]*/ int get_startModeURI(out wchar* namespaceURI);
  // custom stream object for transform output
  /*[id(0x00000007)]*/ int put_output(VARIANT pOutput);
  // custom stream object for transform output
  /*[id(0x00000007)]*/ int get_output(out VARIANT pOutput);
  // start/resume the XSL transformation process
  /*[id(0x00000008)]*/ int transform(out short pDone);
  // reset state of processor and abort current transform
  /*[id(0x00000009)]*/ int reset();
  // current state of the processor
  /*[id(0x0000000A)]*/ int get_readyState(out int pReadyState);
  // set <xsl:param> values
  /*[id(0x0000000B)]*/ int addParameter(wchar* baseName, VARIANT parameter, wchar* namespaceURI);
  // pass object to stylesheet
  /*[id(0x0000000C)]*/ int addObject(IDispatch obj, wchar* namespaceURI);
  // current stylesheet being used
  /*[id(0x0000000D)]*/ int get_stylesheet(out IXMLDOMNode stylesheet);
}

// ISAXXMLReader interface
interface ISAXXMLReader : IUnknown {
  mixin(uuid("a4f96ed0-f829-476e-81c0-cdc7bd2a0802"));
  /*[id(0x60010000)]*/ int getFeature(wchar* pwchName, out short pvfValue);
  /*[id(0x60010001)]*/ int putFeature(wchar* pwchName, short vfValue);
  /*[id(0x60010002)]*/ int getProperty(wchar* pwchName, out VARIANT pvarValue);
  /*[id(0x60010003)]*/ int putProperty(wchar* pwchName, VARIANT varValue);
  /*[id(0x60010004)]*/ int getEntityResolver(out ISAXEntityResolver ppResolver);
  /*[id(0x60010005)]*/ int putEntityResolver(ISAXEntityResolver pResolver);
  /*[id(0x60010006)]*/ int getContentHandler(out ISAXContentHandler ppHandler);
  /*[id(0x60010007)]*/ int putContentHandler(ISAXContentHandler pHandler);
  /*[id(0x60010008)]*/ int getDTDHandler(out ISAXDTDHandler ppHandler);
  /*[id(0x60010009)]*/ int putDTDHandler(ISAXDTDHandler pHandler);
  /*[id(0x6001000A)]*/ int getErrorHandler(out ISAXErrorHandler ppHandler);
  /*[id(0x6001000B)]*/ int putErrorHandler(ISAXErrorHandler pHandler);
  /*[id(0x6001000C)]*/ int getBaseURL(out wchar* ppwchBaseUrl);
  /*[id(0x6001000D)]*/ int putBaseURL(wchar* pwchBaseUrl);
  /*[id(0x6001000E)]*/ int getSecureBaseURL(out wchar* ppwchSecureBaseUrl);
  /*[id(0x6001000F)]*/ int putSecureBaseURL(wchar* pwchSecureBaseUrl);
  /*[id(0x60010010)]*/ int parse(VARIANT varInput);
  /*[id(0x60010011)]*/ int parseURL(wchar* pwchUrl);
}

// ISAXEntityResolver interface
interface ISAXEntityResolver : IUnknown {
  mixin(uuid("99bca7bd-e8c4-4d5f-a0cf-6d907901ff07"));
  /*[id(0x60010000)]*/ int resolveEntity(wchar* pwchPublicId, wchar* pwchSystemId, out VARIANT pvarInput);
}

// ISAXContentHandler interface
interface ISAXContentHandler : IUnknown {
  mixin(uuid("1545cdfa-9e4e-4497-a8a4-2bf7d0112c44"));
  /*[id(0x60010000)]*/ int putDocumentLocator(ISAXLocator pLocator);
  /*[id(0x60010001)]*/ int startDocument();
  /*[id(0x60010002)]*/ int endDocument();
  /*[id(0x60010003)]*/ int startPrefixMapping(wchar* pwchPrefix, int cchPrefix, wchar* pwchUri, int cchUri);
  /*[id(0x60010004)]*/ int endPrefixMapping(wchar* pwchPrefix, int cchPrefix);
  /*[id(0x60010005)]*/ int startElement(wchar* pwchNamespaceUri, int cchNamespaceUri, wchar* pwchLocalName, int cchLocalName, wchar* pwchQName, int cchQName, ISAXAttributes pAttributes);
  /*[id(0x60010006)]*/ int endElement(wchar* pwchNamespaceUri, int cchNamespaceUri, wchar* pwchLocalName, int cchLocalName, wchar* pwchQName, int cchQName);
  /*[id(0x60010007)]*/ int characters(wchar* pwchChars, int cchChars);
  /*[id(0x60010008)]*/ int ignorableWhitespace(wchar* pwchChars, int cchChars);
  /*[id(0x60010009)]*/ int processingInstruction(wchar* pwchTarget, int cchTarget, wchar* pwchData, int cchData);
  /*[id(0x6001000A)]*/ int skippedEntity(wchar* pwchName, int cchName);
}

// ISAXLocator interface
interface ISAXLocator : IUnknown {
  mixin(uuid("9b7e472a-0de4-4640-bff3-84d38a051c31"));
  /*[id(0x60010000)]*/ int getColumnNumber(out int pnColumn);
  /*[id(0x60010001)]*/ int getLineNumber(out int pnLine);
  /*[id(0x60010002)]*/ int getPublicId(out wchar* ppwchPublicId);
  /*[id(0x60010003)]*/ int getSystemId(out wchar* ppwchSystemId);
}

// ISAXAttributes interface
interface ISAXAttributes : IUnknown {
  mixin(uuid("f078abe1-45d2-4832-91ea-4466ce2f25c9"));
  /*[id(0x60010000)]*/ int getLength(out int pnLength);
  /*[id(0x60010001)]*/ int getURI(int nIndex, out wchar* ppwchUri, out int pcchUri);
  /*[id(0x60010002)]*/ int getLocalName(int nIndex, out wchar* ppwchLocalName, out int pcchLocalName);
  /*[id(0x60010003)]*/ int getQName(int nIndex, out ushort ppwchQName, out int pcchQName);
  /*[id(0x60010004)]*/ int getName(int nIndex, out wchar* ppwchUri, out int pcchUri, out wchar* ppwchLocalName, out int pcchLocalName, out wchar* ppwchQName, out int pcchQName);
  /*[id(0x60010005)]*/ int getIndexFromName(wchar* pwchUri, int cchUri, wchar* pwchLocalName, int cchLocalName, out int pnIndex);
  /*[id(0x60010006)]*/ int getIndexFromQName(ushort* pwchQName, int cchQName, out int pnIndex);
  /*[id(0x60010007)]*/ int getType(int nIndex, out wchar* ppwchType, out int pcchType);
  /*[id(0x60010008)]*/ int getTypeFromName(wchar* pwchUri, int cchUri, wchar* pwchLocalName, int cchLocalName, out wchar* ppwchType, out int pcchType);
  /*[id(0x60010009)]*/ int getTypeFromQName(wchar* pwchQName, int cchQName, out wchar* ppwchType, out int pcchType);
  /*[id(0x6001000A)]*/ int getValue(int nIndex, out wchar* ppwchValue, out int pcchValue);
  /*[id(0x6001000B)]*/ int getValueFromName(wchar* pwchUri, int cchUri, wchar* pwchLocalName, int cchLocalName, out wchar* ppwchValue, out int pcchValue);
  /*[id(0x6001000C)]*/ int getValueFromQName(wchar* pwchQName, int cchQName, out wchar* ppwchValue, out int pcchValue);
}

// ISAXDTDHandler interface
interface ISAXDTDHandler : IUnknown {
  mixin(uuid("e15c1baf-afb3-4d60-8c36-19a8c45defed"));
  /*[id(0x60010000)]*/ int notationDecl(wchar* pwchName, int cchName, wchar* pwchPublicId, int cchPublicId, wchar* pwchSystemId, int cchSystemId);
  /*[id(0x60010001)]*/ int unparsedEntityDecl(wchar* pwchName, int cchName, wchar* pwchPublicId, int cchPublicId, wchar* pwchSystemId, int cchSystemId, wchar* pwchNotationName, int cchNotationName);
}

// ISAXErrorHandler interface
interface ISAXErrorHandler : IUnknown {
  mixin(uuid("a60511c4-ccf5-479e-98a3-dc8dc545b7d0"));
  /*[id(0x60010000)]*/ int error(ISAXLocator pLocator, wchar* pwchErrorMessage, int hrErrorCode);
  /*[id(0x60010001)]*/ int fatalError(ISAXLocator pLocator, wchar* pwchErrorMessage, int hrErrorCode);
  /*[id(0x60010002)]*/ int ignorableWarning(ISAXLocator pLocator, wchar* pwchErrorMessage, int hrErrorCode);
}

// ISAXXMLFilter interface
interface ISAXXMLFilter : ISAXXMLReader {
  mixin(uuid("70409222-ca09-4475-acb8-40312fe8d145"));
  /*[id(0x60020000)]*/ int getParent(out ISAXXMLReader ppReader);
  /*[id(0x60020001)]*/ int putParent(ISAXXMLReader pReader);
}

// ISAXLexicalHandler interface
interface ISAXLexicalHandler : IUnknown {
  mixin(uuid("7f85d5f5-47a8-4497-bda5-84ba04819ea6"));
  /*[id(0x60010000)]*/ int startDTD(wchar* pwchName, int cchName, wchar* pwchPublicId, int cchPublicId, wchar* pwchSystemId, int cchSystemId);
  /*[id(0x60010001)]*/ int endDTD();
  /*[id(0x60010002)]*/ int startEntity(wchar* pwchName, int cchName);
  /*[id(0x60010003)]*/ int endEntity(wchar* pwchName, int cchName);
  /*[id(0x60010004)]*/ int startCDATA();
  /*[id(0x60010005)]*/ int endCDATA();
  /*[id(0x60010006)]*/ int comment(wchar* pwchChars, int cchChars);
}

// ISAXDeclHandler interface
interface ISAXDeclHandler : IUnknown {
  mixin(uuid("862629ac-771a-47b2-8337-4e6843c1be90"));
  /*[id(0x60010000)]*/ int elementDecl(wchar* pwchName, int cchName, wchar* pwchModel, int cchModel);
  /*[id(0x60010001)]*/ int attributeDecl(wchar* pwchElementName, int cchElementName, wchar* pwchAttributeName, int cchAttributeName, wchar* pwchType, int cchType, wchar* pwchValueDefault, int cchValueDefault, wchar* pwchValue, int cchValue);
  /*[id(0x60010002)]*/ int internalEntityDecl(wchar* pwchName, int cchName, wchar* pwchValue, int cchValue);
  /*[id(0x60010003)]*/ int externalEntityDecl(wchar* pwchName, int cchName, wchar* pwchPublicId, int cchPublicId, wchar* pwchSystemId, int cchSystemId);
}

// IVBSAXXMLReader interface
interface IVBSAXXMLReader : IDispatch {
  mixin(uuid("8c033caa-6cd6-4f73-b728-4531af74945f"));
  // Look up the value of a feature.
  /*[id(0x00000502)]*/ int getFeature(wchar* strName, out short fValue);
  // Set the state of a feature.
  /*[id(0x00000503)]*/ int putFeature(wchar* strName, short fValue);
  // Look up the value of a property.
  /*[id(0x00000504)]*/ int getProperty(wchar* strName, out VARIANT varValue);
  // Set the value of a property.
  /*[id(0x00000505)]*/ int putProperty(wchar* strName, VARIANT varValue);
  // Allow an application to register an entity resolver or look up the current entity resolver.
  /*[id(0x00000506)]*/ int get_entityResolver(out IVBSAXEntityResolver oResolver);
  // Allow an application to register an entity resolver or look up the current entity resolver.
  /*[id(0x00000506)]*/ int putref_entityResolver(IVBSAXEntityResolver oResolver);
  // Allow an application to register a content event handler or look up the current content event handler.
  /*[id(0x00000507)]*/ int get_contentHandler(out IVBSAXContentHandler oHandler);
  // Allow an application to register a content event handler or look up the current content event handler.
  /*[id(0x00000507)]*/ int putref_contentHandler(IVBSAXContentHandler oHandler);
  // Allow an application to register a DTD event handler or look up the current DTD event handler.
  /*[id(0x00000508)]*/ int get_dtdHandler(out IVBSAXDTDHandler oHandler);
  // Allow an application to register a DTD event handler or look up the current DTD event handler.
  /*[id(0x00000508)]*/ int putref_dtdHandler(IVBSAXDTDHandler oHandler);
  // Allow an application to register an error event handler or look up the current error event handler.
  /*[id(0x00000509)]*/ int get_errorHandler(out IVBSAXErrorHandler oHandler);
  // Allow an application to register an error event handler or look up the current error event handler.
  /*[id(0x00000509)]*/ int putref_errorHandler(IVBSAXErrorHandler oHandler);
  // Set or get the base URL for the document.
  /*[id(0x0000050A)]*/ int get_baseURL(out wchar* strBaseURL);
  // Set or get the base URL for the document.
  /*[id(0x0000050A)]*/ int put_baseURL(wchar* strBaseURL);
  // Set or get the secure base URL for the document.
  /*[id(0x0000050B)]*/ int get_secureBaseURL(out wchar* strSecureBaseURL);
  // Set or get the secure base URL for the document.
  /*[id(0x0000050B)]*/ int put_secureBaseURL(wchar* strSecureBaseURL);
  // Parse an XML document.
  /*[id(0x0000050C)]*/ int parse(VARIANT varInput);
  // Parse an XML document from a system identifier (URI).
  /*[id(0x0000050D)]*/ int parseURL(wchar* strURL);
}

// IVBSAXEntityResolver interface
interface IVBSAXEntityResolver : IDispatch {
  mixin(uuid("0c05d096-f45b-4aca-ad1a-aa0bc25518dc"));
  // Allow the application to resolve external entities.
  /*[id(0x00000527)]*/ int resolveEntity(ref wchar* strPublicId, ref wchar* strSystemId, out VARIANT varInput);
}

// IVBSAXContentHandler interface
interface IVBSAXContentHandler : IDispatch {
  mixin(uuid("2ed7290a-4dd5-4b46-bb26-4e4155e77faa"));
  // Receive an object for locating the origin of SAX document events.
  /*[id(0x0000052A)]*/ int putref_documentLocator(IVBSAXLocator value);
  // Receive notification of the beginning of a document.
  /*[id(0x0000052B)]*/ int startDocument();
  // Receive notification of the end of a document.
  /*[id(0x0000052C)]*/ int endDocument();
  // Begin the scope of a prefix-URI Namespace mapping.
  /*[id(0x0000052D)]*/ int startPrefixMapping(ref wchar* strPrefix, ref wchar* strURI);
  // End the scope of a prefix-URI mapping.
  /*[id(0x0000052E)]*/ int endPrefixMapping(ref wchar* strPrefix);
  // Receive notification of the beginning of an element.
  /*[id(0x0000052F)]*/ int startElement(ref wchar* strNamespaceURI, ref wchar* strLocalName, ref wchar* strQName, IVBSAXAttributes oAttributes);
  // Receive notification of the end of an element.
  /*[id(0x00000530)]*/ int endElement(ref wchar* strNamespaceURI, ref wchar* strLocalName, ref wchar* strQName);
  // Receive notification of character data.
  /*[id(0x00000531)]*/ int characters(ref wchar* strChars);
  // Receive notification of ignorable whitespace in element content.
  /*[id(0x00000532)]*/ int ignorableWhitespace(ref wchar* strChars);
  // Receive notification of a processing instruction.
  /*[id(0x00000533)]*/ int processingInstruction(ref wchar* strTarget, ref wchar* strData);
  // Receive notification of a skipped entity.
  /*[id(0x00000534)]*/ int skippedEntity(ref wchar* strName);
}

// IVBSAXLocator interface
interface IVBSAXLocator : IDispatch {
  mixin(uuid("796e7ac5-5aa2-4eff-acad-3faaf01a3288"));
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
  mixin(uuid("10dc0586-132b-4cac-8bb3-db00ac8b7ee0"));
  // Get the number of attributes in the list.
  /*[id(0x00000540)]*/ int get_length(out int nLength);
  // Look up an attribute's Namespace URI by index.
  /*[id(0x00000541)]*/ int getURI(int nIndex, out wchar* strURI);
  // Look up an attribute's local name by index.
  /*[id(0x00000542)]*/ int getLocalName(int nIndex, out wchar* strLocalName);
  // Look up an attribute's XML 1.0 qualified name by index.
  /*[id(0x00000543)]*/ int getQName(int nIndex, out wchar* strQName);
  // Look up the index of an attribute by Namespace name.
  /*[id(0x00000544)]*/ int getIndexFromName(wchar* strURI, wchar* strLocalName, out int nIndex);
  // Look up the index of an attribute by XML 1.0 qualified name.
  /*[id(0x00000545)]*/ int getIndexFromQName(wchar* strQName, out int nIndex);
  // Look up an attribute's type by index.
  /*[id(0x00000546)]*/ int getType(int nIndex, out wchar* strType);
  // Look up an attribute's type by Namespace name.
  /*[id(0x00000547)]*/ int getTypeFromName(wchar* strURI, wchar* strLocalName, out wchar* strType);
  // Look up an attribute's type by XML 1.0 qualified name.
  /*[id(0x00000548)]*/ int getTypeFromQName(wchar* strQName, out wchar* strType);
  // Look up an attribute's value by index.
  /*[id(0x00000549)]*/ int getValue(int nIndex, out wchar* strValue);
  // Look up an attribute's value by Namespace name.
  /*[id(0x0000054A)]*/ int getValueFromName(wchar* strURI, wchar* strLocalName, out wchar* strValue);
  // Look up an attribute's value by XML 1.0 qualified name.
  /*[id(0x0000054B)]*/ int getValueFromQName(wchar* strQName, out wchar* strValue);
}

// IVBSAXDTDHandler interface
interface IVBSAXDTDHandler : IDispatch {
  mixin(uuid("24fb3297-302d-4620-ba39-3a732d850558"));
  // Receive notification of a notation declaration event.
  /*[id(0x00000537)]*/ int notationDecl(ref wchar* strName, ref wchar* strPublicId, ref wchar* strSystemId);
  // Receive notification of an unparsed entity declaration event.
  /*[id(0x00000538)]*/ int unparsedEntityDecl(ref wchar* strName, ref wchar* strPublicId, ref wchar* strSystemId, ref wchar* strNotationName);
}

// IVBSAXErrorHandler interface
interface IVBSAXErrorHandler : IDispatch {
  mixin(uuid("d963d3fe-173c-4862-9095-b92f66995f52"));
  // Receive notification of a recoverable error.
  /*[id(0x0000053B)]*/ int error(IVBSAXLocator oLocator, ref wchar* strErrorMessage, int nErrorCode);
  // Receive notification of a non-recoverable error.
  /*[id(0x0000053C)]*/ int fatalError(IVBSAXLocator oLocator, ref wchar* strErrorMessage, int nErrorCode);
  // Receive notification of an ignorable warning.
  /*[id(0x0000053D)]*/ int ignorableWarning(IVBSAXLocator oLocator, ref wchar* strErrorMessage, int nErrorCode);
}

// IVBSAXXMLFilter interface
interface IVBSAXXMLFilter : IDispatch {
  mixin(uuid("1299eb1b-5b88-433e-82de-82ca75ad4e04"));
  // Set or get the parent reader
  /*[id(0x0000051D)]*/ int get_parent(out IVBSAXXMLReader oReader);
  // Set or get the parent reader
  /*[id(0x0000051D)]*/ int putref_parent(IVBSAXXMLReader oReader);
}

// IVBSAXLexicalHandler interface
interface IVBSAXLexicalHandler : IDispatch {
  mixin(uuid("032aac35-8c0e-4d9d-979f-e3b702935576"));
  // Report the start of DTD declarations, if any.
  /*[id(0x0000054E)]*/ int startDTD(ref wchar* strName, ref wchar* strPublicId, ref wchar* strSystemId);
  // Report the end of DTD declarations.
  /*[id(0x0000054F)]*/ int endDTD();
  // Report the beginning of some internal and external XML entities.
  /*[id(0x00000550)]*/ int startEntity(ref wchar* strName);
  // Report the end of an entity.
  /*[id(0x00000551)]*/ int endEntity(ref wchar* strName);
  // Report the start of a CDATA section.
  /*[id(0x00000552)]*/ int startCDATA();
  // Report the end of a CDATA section.
  /*[id(0x00000553)]*/ int endCDATA();
  // Report an XML comment anywhere in the document.
  /*[id(0x00000554)]*/ int comment(ref wchar* strChars);
}

// IVBSAXDeclHandler interface
interface IVBSAXDeclHandler : IDispatch {
  mixin(uuid("e8917260-7579-4be1-b5dd-7afbfa6f077b"));
  // Report an element type declaration.
  /*[id(0x00000557)]*/ int elementDecl(ref wchar* strName, ref wchar* strModel);
  // Report an attribute type declaration.
  /*[id(0x00000558)]*/ int attributeDecl(ref wchar* strElementName, ref wchar* strAttributeName, ref wchar* strType, ref wchar* strValueDefault, ref wchar* strValue);
  // Report an internal entity declaration.
  /*[id(0x00000559)]*/ int internalEntityDecl(ref wchar* strName, ref wchar* strValue);
  // Report a parsed external entity declaration.
  /*[id(0x0000055A)]*/ int externalEntityDecl(ref wchar* strName, ref wchar* strPublicId, ref wchar* strSystemId);
}

// IMXWriter interface
interface IMXWriter : IDispatch {
  mixin(uuid("4d7ff4ba-1565-4ea8-94e1-6e724a46f98d"));
  // Set or get the output.
  /*[id(0x00000569)]*/ int put_output(VARIANT varDestination);
  // Set or get the output.
  /*[id(0x00000569)]*/ int get_output(out VARIANT varDestination);
  // Set or get the output encoding.
  /*[id(0x0000056B)]*/ int put_encoding(wchar* strEncoding);
  // Set or get the output encoding.
  /*[id(0x0000056B)]*/ int get_encoding(out wchar* strEncoding);
  // Determine whether or not to write the byte order mark
  /*[id(0x0000056C)]*/ int put_byteOrderMark(short fWriteByteOrderMark);
  // Determine whether or not to write the byte order mark
  /*[id(0x0000056C)]*/ int get_byteOrderMark(out short fWriteByteOrderMark);
  // Enable or disable auto indent mode.
  /*[id(0x0000056D)]*/ int put_indent(short fIndentMode);
  // Enable or disable auto indent mode.
  /*[id(0x0000056D)]*/ int get_indent(out short fIndentMode);
  // Set or get the standalone document declaration.
  /*[id(0x0000056E)]*/ int put_standalone(short fValue);
  // Set or get the standalone document declaration.
  /*[id(0x0000056E)]*/ int get_standalone(out short fValue);
  // Determine whether or not to omit the XML declaration.
  /*[id(0x0000056F)]*/ int put_omitXMLDeclaration(short fValue);
  // Determine whether or not to omit the XML declaration.
  /*[id(0x0000056F)]*/ int get_omitXMLDeclaration(out short fValue);
  // Set or get the xml version info.
  /*[id(0x00000570)]*/ int put_version(wchar* strVersion);
  // Set or get the xml version info.
  /*[id(0x00000570)]*/ int get_version(out wchar* strVersion);
  // When enabled, the writer no longer escapes out its input when writing it out.
  /*[id(0x00000571)]*/ int put_disableOutputEscaping(short fValue);
  // When enabled, the writer no longer escapes out its input when writing it out.
  /*[id(0x00000571)]*/ int get_disableOutputEscaping(out short fValue);
  // Flushes all writer buffers forcing the writer to write to the underlying output object
  /*[id(0x00000572)]*/ int flush();
}

// IMXAttributes interface
interface IMXAttributes : IDispatch {
  mixin(uuid("f10d27cc-3ec0-415c-8ed8-77ab1c5e7262"));
  // Add an attribute to the end of the list.
  /*[id(0x0000055D)]*/ int addAttribute(wchar* strURI, wchar* strLocalName, wchar* strQName, wchar* strType, wchar* strValue);
  // Add an attribute, whose value is equal to the indexed attribute in the input attributes object, to the end of the list.
  /*[id(0x00000567)]*/ int addAttributeFromIndex(VARIANT varAtts, int nIndex);
  // Clear the attribute list for reuse.
  /*[id(0x0000055E)]*/ int clear();
  // Remove an attribute from the list.
  /*[id(0x0000055F)]*/ int removeAttribute(int nIndex);
  // Set an attribute in the list.
  /*[id(0x00000560)]*/ int setAttribute(int nIndex, wchar* strURI, wchar* strLocalName, wchar* strQName, wchar* strType, wchar* strValue);
  // Copy an entire Attributes object.
  /*[id(0x00000561)]*/ int setAttributes(VARIANT varAtts);
  // Set the local name of a specific attribute.
  /*[id(0x00000562)]*/ int setLocalName(int nIndex, wchar* strLocalName);
  // Set the qualified name of a specific attribute.
  /*[id(0x00000563)]*/ int setQName(int nIndex, wchar* strQName);
  // Set the type of a specific attribute.
  /*[id(0x00000564)]*/ int setType(int nIndex, wchar* strType);
  // Set the Namespace URI of a specific attribute.
  /*[id(0x00000565)]*/ int setURI(int nIndex, wchar* strURI);
  // Set the value of a specific attribute.
  /*[id(0x00000566)]*/ int setValue(int nIndex, wchar* strValue);
}

// IMXReaderControl interface
interface IMXReaderControl : IDispatch {
  mixin(uuid("808f4e35-8d5a-4fbe-8466-33a41279ed30"));
  // Abort the reader
  /*[id(0x00000576)]*/ int abort();
  // Resume the reader
  /*[id(0x00000577)]*/ int resume();
  // Suspend the reader
  /*[id(0x00000578)]*/ int suspend();
}

// IMXSchemaDeclHandler interface
interface IMXSchemaDeclHandler : IDispatch {
  mixin(uuid("fa4bb38c-faf9-4cca-9302-d1dd0fe520db"));
  // Access schema element declaration
  /*[id(0x0000057B)]*/ int schemaElementDecl(ISchemaElement oSchemaElement);
}

// XML Schema Element
interface ISchemaElement : ISchemaParticle {
  mixin(uuid("50ea08b7-dd1b-4664-9a50-c2f40f4bd79a"));
  /*[id(0x000005C4)]*/ int get_type(out ISchemaType type);
  /*[id(0x000005BD)]*/ int get_scope(out ISchemaComplexType scopeParam);
  /*[id(0x00000597)]*/ int get_defaultValue(out wchar* defaultValue);
  /*[id(0x0000059E)]*/ int get_fixedValue(out wchar* fixedValue);
  /*[id(0x000005A3)]*/ int get_isNillable(out short nillable);
  /*[id(0x000005A1)]*/ int get_identityConstraints(out ISchemaItemCollection constraints);
  /*[id(0x000005BF)]*/ int get_substitutionGroup(out ISchemaElement element);
  /*[id(0x000005C0)]*/ int get_substitutionGroupExclusions(out SCHEMADERIVATIONMETHOD exclusions);
  /*[id(0x00000599)]*/ int get_disallowedSubstitutions(out SCHEMADERIVATIONMETHOD disallowed);
  /*[id(0x000005A2)]*/ int get_isAbstract(out short abstractParam);
  /*[id(0x000005A4)]*/ int get_isReference(out short reference);
}

// XML Schema Particle
interface ISchemaParticle : ISchemaItem {
  mixin(uuid("50ea08b5-dd1b-4664-9a50-c2f40f4bd79a"));
  /*[id(0x000005AF)]*/ int get_minOccurs(out VARIANT minOccurs);
  /*[id(0x000005AB)]*/ int get_maxOccurs(out VARIANT maxOccurs);
}

// XML Schema Item
interface ISchemaItem : IDispatch {
  mixin(uuid("50ea08b3-dd1b-4664-9a50-c2f40f4bd79a"));
  /*[id(0x000005B1)]*/ int get_name(out wchar* name);
  /*[id(0x000005B3)]*/ int get_namespaceURI(out wchar* namespaceURI);
  /*[id(0x000005BB)]*/ int get_schema(out ISchema schema);
  /*[id(0x000005A0)]*/ int get_id(out wchar* id);
  /*[id(0x000005A6)]*/ int get_itemType(out SOMITEMTYPE itemType);
  /*[id(0x000005C6)]*/ int get_unhandledAttributes(out IVBSAXAttributes attributes);
  /*[id(0x000005CB)]*/ int writeAnnotation(IUnknown annotationSink, out short isWritten);
}

// XML Schema
interface ISchema : ISchemaItem {
  mixin(uuid("50ea08b4-dd1b-4664-9a50-c2f40f4bd79a"));
  /*[id(0x000005C2)]*/ int get_targetNamespace(out wchar* targetNamespace);
  /*[id(0x000005C9)]*/ int get_version(out wchar* versionParam);
  /*[id(0x000005C5)]*/ int get_types(out ISchemaItemCollection types);
  /*[id(0x0000059A)]*/ int get_elements(out ISchemaItemCollection elements);
  /*[id(0x00000593)]*/ int get_attributes(out ISchemaItemCollection attributes);
  /*[id(0x00000592)]*/ int get_attributeGroups(out ISchemaItemCollection attributeGroups);
  /*[id(0x000005B0)]*/ int get_modelGroups(out ISchemaItemCollection modelGroups);
  /*[id(0x000005B4)]*/ int get_notations(out ISchemaItemCollection notations);
  /*[id(0x000005BC)]*/ int get_schemaLocations(out ISchemaStringCollection schemaLocations);
}

// XML Schema Item Collection
interface ISchemaItemCollection : IDispatch {
  mixin(uuid("50ea08b2-dd1b-4664-9a50-c2f40f4bd79a"));
  /*[id(0x00000000)]*/ int get_item(int index, out ISchemaItem item);
  /*[id(0x0000058F)]*/ int itemByName(wchar* name, out ISchemaItem item);
  /*[id(0x00000590)]*/ int itemByQName(wchar* name, wchar* namespaceURI, out ISchemaItem item);
  /*[id(0x000005A7)]*/ int get_length(out int length);
  /*[id(0xFFFFFFFC)]*/ int get__newEnum(out IUnknown ppUnk);
}

// XML Schema String Collection
interface ISchemaStringCollection : IDispatch {
  mixin(uuid("50ea08b1-dd1b-4664-9a50-c2f40f4bd79a"));
  /*[id(0x00000000)]*/ int get_item(int index, out wchar* bstr);
  /*[id(0x000005A7)]*/ int get_length(out int length);
  /*[id(0xFFFFFFFC)]*/ int get__newEnum(out IUnknown ppUnk);
}

// XML Schema Type
interface ISchemaType : ISchemaItem {
  mixin(uuid("50ea08b8-dd1b-4664-9a50-c2f40f4bd79a"));
  /*[id(0x00000594)]*/ int get_baseTypes(out ISchemaItemCollection baseTypes);
  /*[id(0x0000059D)]*/ int get_final(out SCHEMADERIVATIONMETHOD finalParam);
  /*[id(0x000005C8)]*/ int get_variety(out SCHEMATYPEVARIETY variety);
  /*[id(0x00000598)]*/ int get_derivedBy(out SCHEMADERIVATIONMETHOD derivedBy);
  /*[id(0x000005A5)]*/ int isValid(wchar* data, out short valid);
  /*[id(0x000005AC)]*/ int get_minExclusive(out wchar* minExclusive);
  /*[id(0x000005AD)]*/ int get_minInclusive(out wchar* minInclusive);
  /*[id(0x000005A8)]*/ int get_maxExclusive(out wchar* maxExclusive);
  /*[id(0x000005A9)]*/ int get_maxInclusive(out wchar* maxInclusive);
  /*[id(0x000005C3)]*/ int get_totalDigits(out VARIANT totalDigits);
  /*[id(0x0000059F)]*/ int get_fractionDigits(out VARIANT fractionDigits);
  /*[id(0x000005A7)]*/ int get_length(out VARIANT length);
  /*[id(0x000005AE)]*/ int get_minLength(out VARIANT minLength);
  /*[id(0x000005AA)]*/ int get_maxLength(out VARIANT maxLength);
  /*[id(0x0000059B)]*/ int get_enumeration(out ISchemaStringCollection enumeration);
  /*[id(0x000005CA)]*/ int get_whitespace(out SCHEMAWHITESPACE whitespace);
  /*[id(0x000005B6)]*/ int get_patterns(out ISchemaStringCollection patterns);
}

// XML Schema Complex Type
interface ISchemaComplexType : ISchemaType {
  mixin(uuid("50ea08b9-dd1b-4664-9a50-c2f40f4bd79a"));
  /*[id(0x000005A2)]*/ int get_isAbstract(out short abstractParam);
  /*[id(0x00000591)]*/ int get_anyAttribute(out ISchemaAny anyAttribute);
  /*[id(0x00000593)]*/ int get_attributes(out ISchemaItemCollection attributes);
  /*[id(0x00000596)]*/ int get_contentType(out SCHEMACONTENTTYPE contentType);
  /*[id(0x00000595)]*/ int get_contentModel(out ISchemaModelGroup contentModel);
  /*[id(0x000005B8)]*/ int get_prohibitedSubstitutions(out SCHEMADERIVATIONMETHOD prohibited);
}

// XML Schema Any
interface ISchemaAny : ISchemaParticle {
  mixin(uuid("50ea08bc-dd1b-4664-9a50-c2f40f4bd79a"));
  /*[id(0x000005B2)]*/ int get_namespaces(out ISchemaStringCollection namespaces);
  /*[id(0x000005B7)]*/ int get_processContents(out SCHEMAPROCESSCONTENTS processContents);
}

// XML Schema Type
interface ISchemaModelGroup : ISchemaParticle {
  mixin(uuid("50ea08bb-dd1b-4664-9a50-c2f40f4bd79a"));
  /*[id(0x000005B5)]*/ int get_particles(out ISchemaItemCollection particles);
}

// IMXXMLFilter interface
interface IMXXMLFilter : IDispatch {
  mixin(uuid("c90352f7-643c-4fbc-bb23-e996eb2d51fd"));
  /*[id(0x0000058F)]*/ int getFeature(wchar* strName, out short fValue);
  /*[id(0x00000591)]*/ int putFeature(wchar* strName, short fValue);
  /*[id(0x00000590)]*/ int getProperty(wchar* strName, out VARIANT varValue);
  /*[id(0x00000592)]*/ int putProperty(wchar* strName, VARIANT varValue);
  /*[id(0x0000058D)]*/ int get_entityResolver(out IUnknown oResolver);
  /*[id(0x0000058D)]*/ int putref_entityResolver(IUnknown oResolver);
  /*[id(0x0000058B)]*/ int get_contentHandler(out IUnknown oHandler);
  /*[id(0x0000058B)]*/ int putref_contentHandler(IUnknown oHandler);
  /*[id(0x0000058C)]*/ int get_dtdHandler(out IUnknown oHandler);
  /*[id(0x0000058C)]*/ int putref_dtdHandler(IUnknown oHandler);
  /*[id(0x0000058E)]*/ int get_errorHandler(out IUnknown oHandler);
  /*[id(0x0000058E)]*/ int putref_errorHandler(IUnknown oHandler);
}

// XML Schemas Collection 2
interface IXMLDOMSchemaCollection2 : IXMLDOMSchemaCollection {
  mixin(uuid("50ea08b0-dd1b-4664-9a50-c2f40f4bd79a"));
  /*[id(0x0000058B)]*/ int validate();
  /*[id(0x0000058C)]*/ int put_validateOnLoad(short validateOnLoad);
  /*[id(0x0000058C)]*/ int get_validateOnLoad(out short validateOnLoad);
  /*[id(0x0000058D)]*/ int getSchema(wchar* namespaceURI, out ISchema schema);
  /*[id(0x0000058E)]*/ int getDeclaration(IXMLDOMNode node, out ISchemaItem item);
}

// XML Schema Attribute
interface ISchemaAttribute : ISchemaItem {
  mixin(uuid("50ea08b6-dd1b-4664-9a50-c2f40f4bd79a"));
  /*[id(0x000005C4)]*/ int get_type(out ISchemaType type);
  /*[id(0x000005BD)]*/ int get_scope(out ISchemaComplexType scopeParam);
  /*[id(0x00000597)]*/ int get_defaultValue(out wchar* defaultValue);
  /*[id(0x0000059E)]*/ int get_fixedValue(out wchar* fixedValue);
  /*[id(0x000005C7)]*/ int get_use(out SCHEMAUSE use);
  /*[id(0x000005A4)]*/ int get_isReference(out short reference);
}

// XML Schema Attribute Group
interface ISchemaAttributeGroup : ISchemaItem {
  mixin(uuid("50ea08ba-dd1b-4664-9a50-c2f40f4bd79a"));
  /*[id(0x00000591)]*/ int get_anyAttribute(out ISchemaAny anyAttribute);
  /*[id(0x00000593)]*/ int get_attributes(out ISchemaItemCollection attributes);
}

// XML Schema Any
interface ISchemaIdentityConstraint : ISchemaItem {
  mixin(uuid("50ea08bd-dd1b-4664-9a50-c2f40f4bd79a"));
  /*[id(0x000005BE)]*/ int get_selector(out wchar* selector);
  /*[id(0x0000059C)]*/ int get_fields(out ISchemaStringCollection fields);
  /*[id(0x000005BA)]*/ int get_referencedKey(out ISchemaIdentityConstraint key);
}

// XML Schema Notation
interface ISchemaNotation : ISchemaItem {
  mixin(uuid("50ea08be-dd1b-4664-9a50-c2f40f4bd79a"));
  /*[id(0x000005C1)]*/ int get_systemIdentifier(out wchar* uri);
  /*[id(0x000005B9)]*/ int get_publicIdentifier(out wchar* uri);
}

interface IXMLDOMSelection : IXMLDOMNodeList {
  mixin(uuid("aa634fc7-5888-44a7-a257-3a47150d3a0e"));
  // selection expression
  /*[id(0x00000051)]*/ int get_expr(out wchar* expression);
  // selection expression
  /*[id(0x00000051)]*/ int put_expr(wchar* expression);
  // nodes to apply selection expression to
  /*[id(0x00000052)]*/ int get_context(out IXMLDOMNode ppNode);
  // nodes to apply selection expression to
  /*[id(0x00000052)]*/ int putref_context(IXMLDOMNode ppNode);
  // gets the next node without advancing the list position
  /*[id(0x00000053)]*/ int peekNode(out IXMLDOMNode ppNode);
  // checks to see if the node matches the pattern
  /*[id(0x00000054)]*/ int matches(IXMLDOMNode pNode, out IXMLDOMNode ppNode);
  // removes the next node
  /*[id(0x00000055)]*/ int removeNext(out IXMLDOMNode ppNode);
  // removes all the nodes that match the selection
  /*[id(0x00000056)]*/ int removeAll();
  // clone this object with the same position and context
  /*[id(0x00000057)]*/ int clone(out IXMLDOMSelection ppNode);
  // get the value of the named property
  /*[id(0x00000058)]*/ int getProperty(wchar* name, out VARIANT value);
  // set the value of the named property
  /*[id(0x00000059)]*/ int setProperty(wchar* name, VARIANT value);
}

interface XMLDOMDocumentEvents : IDispatch {
  mixin(uuid("3efaa427-272f-11d2-836f-0000f87a7782"));
  /+/*[id(0x000000C6)]*/ int ondataavailable();+/
  /+/*[id(0xFFFFFD9F)]*/ int onreadystatechange();+/
}

// DSO Control
interface IDSOControl : IDispatch {
  mixin(uuid("310afa62-0575-11d2-9ca9-0060b0ec3d39"));
  /*[id(0x00010001)]*/ int get_XMLDocument(out IXMLDOMDocument ppDoc);
  /*[id(0x00010001)]*/ int put_XMLDocument(IXMLDOMDocument ppDoc);
  /*[id(0x00010002)]*/ int get_JavaDSOCompatible(out int fJavaDSOCompatible);
  /*[id(0x00010002)]*/ int put_JavaDSOCompatible(int fJavaDSOCompatible);
  /*[id(0xFFFFFDF3)]*/ int get_readyState(out int state);
}

// IXMLHTTPRequest Interface
interface IXMLHTTPRequest : IDispatch {
  mixin(uuid("ed8c108d-4349-11d2-91a4-00c04f7969e8"));
  // Open HTTP connection
  /*[id(0x00000001)]*/ int open(wchar* bstrMethod, wchar* bstrUrl, VARIANT varAsync, VARIANT bstrUser, VARIANT bstrPassword);
  // Add HTTP request header
  /*[id(0x00000002)]*/ int setRequestHeader(wchar* bstrHeader, wchar* bstrValue);
  // Get HTTP response header
  /*[id(0x00000003)]*/ int getResponseHeader(wchar* bstrHeader, out wchar* pbstrValue);
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
  /*[id(0x0000000A)]*/ int get_responseText(out wchar* pbstrBody);
  // Get response body
  /*[id(0x0000000B)]*/ int get_responseBody(out VARIANT pvarBody);
  // Get response body
  /*[id(0x0000000C)]*/ int get_responseStream(out VARIANT pvarBody);
  // Get ready state
  /*[id(0x0000000D)]*/ int get_readyState(out int plState);
  // Register a complete event handler
  /*[id(0x0000000E)]*/ int put_onreadystatechange(IDispatch value);
}

// IServerXMLHTTPRequest Interface
interface IServerXMLHTTPRequest : IXMLHTTPRequest {
  mixin(uuid("2e9196bf-13ba-4dd4-91ca-6c571f281495"));
  // Specify timeout settings (in milliseconds)
  /*[id(0x0000000F)]*/ int setTimeouts(int resolveTimeout, int connectTimeout, int sendTimeout, int receiveTimeout);
  // Wait for asynchronous send to complete, with optional timeout (in seconds)
  /*[id(0x00000010)]*/ int waitForResponse(VARIANT timeoutInSeconds, out short isSuccessful);
  // Get an option value
  /*[id(0x00000011)]*/ int getOption(SERVERXMLHTTP_OPTION option, out VARIANT value);
  // Set an option value
  /*[id(0x00000012)]*/ int setOption(SERVERXMLHTTP_OPTION option, VARIANT value);
}

// IServerXMLHTTPRequest2 Interface
interface IServerXMLHTTPRequest2 : IServerXMLHTTPRequest {
  mixin(uuid("2e01311b-c322-4b0a-bd77-b90cfdc8dce7"));
  // Specify proxy configuration
  /*[id(0x00000013)]*/ int setProxy(SXH_PROXY_SETTING proxySetting, VARIANT varProxyServer, VARIANT varBypassList);
  // Specify proxy authentication credentials
  /*[id(0x00000014)]*/ int setProxyCredentials(wchar* bstrUserName, wchar* bstrPassword);
}

// IMXNamespacePrefixes interface
interface IMXNamespacePrefixes : IDispatch {
  mixin(uuid("c90352f4-643c-4fbc-bb23-e996eb2d51fd"));
  /*[id(0x00000000)]*/ int get_item(int index, out wchar* prefix);
  /*[id(0x00000588)]*/ int get_length(out int length);
  /*[id(0xFFFFFFFC)]*/ int get__newEnum(out IUnknown ppUnk);
}

// IVBMXNamespaceManager interface
interface IVBMXNamespaceManager : IDispatch {
  mixin(uuid("c90352f5-643c-4fbc-bb23-e996eb2d51fd"));
  /*[id(0x0000057E)]*/ int put_allowOverride(short fOverride);
  /*[id(0x0000057E)]*/ int get_allowOverride(out short fOverride);
  /*[id(0x0000057F)]*/ int reset();
  /*[id(0x00000580)]*/ int pushContext();
  /*[id(0x00000581)]*/ int pushNodeContext(IXMLDOMNode contextNode, short fDeep);
  /*[id(0x00000582)]*/ int popContext();
  /*[id(0x00000583)]*/ int declarePrefix(wchar* prefix, wchar* namespaceURI);
  /*[id(0x00000584)]*/ int getDeclaredPrefixes(out IMXNamespacePrefixes prefixes);
  /*[id(0x00000585)]*/ int getPrefixes(wchar* namespaceURI, out IMXNamespacePrefixes prefixes);
  /*[id(0x00000586)]*/ int getURI(wchar* prefix, out VARIANT uri);
  /*[id(0x00000587)]*/ int getURIFromNode(wchar* strPrefix, IXMLDOMNode contextNode, out VARIANT uri);
}

// IMXNamespaceManager interface
interface IMXNamespaceManager : IUnknown {
  mixin(uuid("c90352f6-643c-4fbc-bb23-e996eb2d51fd"));
  /*[id(0x60010000)]*/ int putAllowOverride(short fOverride);
  /*[id(0x60010001)]*/ int getAllowOverride(out short fOverride);
  /*[id(0x60010002)]*/ int reset();
  /*[id(0x60010003)]*/ int pushContext();
  /*[id(0x60010004)]*/ int pushNodeContext(IXMLDOMNode contextNode, short fDeep);
  /*[id(0x60010005)]*/ int popContext();
  /*[id(0x60010006)]*/ int declarePrefix(in wchar* prefix, in wchar* namespaceURI);
  /*[id(0x60010007)]*/ int getDeclaredPrefix(int nIndex, in wchar* pwchPrefix, ref int pcchPrefix);
  /*[id(0x60010008)]*/ int getPrefix(in wchar* pwszNamespaceURI, int nIndex, wchar* pwchPrefix, ref int pcchPrefix);
  /*[id(0x60010009)]*/ int getURI(in wchar* pwchPrefix, IXMLDOMNode pContextNode, wchar* pwchUri, ref int pcchUri);
}

// CoClasses

// W3C-DOM XML Document (Apartment)
abstract final class DOMDocument {
  mixin(uuid("f6d90f11-9c73-11d3-b32e-00c04f990bb4"));
  mixin Interfaces!(IXMLDOMDocument2);
}

// W3C-DOM XML Document (Apartment)
abstract final class DOMDocument26 {
  mixin(uuid("f5078f1b-c551-11d3-89b9-0000f81fe221"));
  mixin Interfaces!(IXMLDOMDocument2);
}

// W3C-DOM XML Document (Apartment)
abstract final class DOMDocument30 {
  mixin(uuid("f5078f32-c551-11d3-89b9-0000f81fe221"));
  mixin Interfaces!(IXMLDOMDocument2);
}

// W3C-DOM XML Document (Apartment)
abstract final class DOMDocument40 {
  mixin(uuid("88d969c0-f192-11d4-a65f-0040963251e5"));
  mixin Interfaces!(IXMLDOMDocument2);
}

// W3C-DOM XML Document 6.0 (Apartment)
abstract final class DOMDocument60 {
  mixin(uuid("88d96a05-f192-11d4-a65f-0040963251e5"));
  mixin Interfaces!(IXMLDOMDocument3);
}

// W3C-DOM XML Document (Free threaded)
abstract final class FreeThreadedDOMDocument {
  mixin(uuid("f6d90f12-9c73-11d3-b32e-00c04f990bb4"));
  mixin Interfaces!(IXMLDOMDocument2);
}

// W3C-DOM XML Document (Free threaded)
abstract final class FreeThreadedDOMDocument26 {
  mixin(uuid("f5078f1c-c551-11d3-89b9-0000f81fe221"));
  mixin Interfaces!(IXMLDOMDocument2);
}

// W3C-DOM XML Document (Free threaded)
abstract final class FreeThreadedDOMDocument30 {
  mixin(uuid("f5078f33-c551-11d3-89b9-0000f81fe221"));
  mixin Interfaces!(IXMLDOMDocument2);
}

// W3C-DOM XML Document (Free threaded)
abstract final class FreeThreadedDOMDocument40 {
  mixin(uuid("88d969c1-f192-11d4-a65f-0040963251e5"));
  mixin Interfaces!(IXMLDOMDocument2);
}

// W3C-DOM XML Document 6.0 (Free threaded)
abstract final class FreeThreadedDOMDocument60 {
  mixin(uuid("88d96a06-f192-11d4-a65f-0040963251e5"));
  mixin Interfaces!(IXMLDOMDocument3);
}

// XML Schema Cache
abstract final class XMLSchemaCache {
  mixin(uuid("373984c9-b845-449b-91e7-45ac83036ade"));
  mixin Interfaces!(IXMLDOMSchemaCollection);
}

// XML Schema Cache 2.6
abstract final class XMLSchemaCache26 {
  mixin(uuid("f5078f1d-c551-11d3-89b9-0000f81fe221"));
  mixin Interfaces!(IXMLDOMSchemaCollection);
}

// XML Schema Cache 3.0
abstract final class XMLSchemaCache30 {
  mixin(uuid("f5078f34-c551-11d3-89b9-0000f81fe221"));
  mixin Interfaces!(IXMLDOMSchemaCollection);
}

// XML Schema Cache 4.0
abstract final class XMLSchemaCache40 {
  mixin(uuid("88d969c2-f192-11d4-a65f-0040963251e5"));
  mixin Interfaces!(IXMLDOMSchemaCollection2);
}

// XML Schema Cache 6.0
abstract final class XMLSchemaCache60 {
  mixin(uuid("88d96a07-f192-11d4-a65f-0040963251e5"));
  mixin Interfaces!(IXMLDOMSchemaCollection2);
}

// Compiled XSL Stylesheet Cache
abstract final class XSLTemplate {
  mixin(uuid("2933bf94-7b36-11d2-b20e-00c04f983e60"));
  mixin Interfaces!(IXSLTemplate);
}

// Compiled XSL Stylesheet Cache 2.6
abstract final class XSLTemplate26 {
  mixin(uuid("f5078f21-c551-11d3-89b9-0000f81fe221"));
  mixin Interfaces!(IXSLTemplate);
}

// Compiled XSL Stylesheet Cache 3.0
abstract final class XSLTemplate30 {
  mixin(uuid("f5078f36-c551-11d3-89b9-0000f81fe221"));
  mixin Interfaces!(IXSLTemplate);
}

// Compiled XSL Stylesheet Cache 4.0
abstract final class XSLTemplate40 {
  mixin(uuid("88d969c3-f192-11d4-a65f-0040963251e5"));
  mixin Interfaces!(IXSLTemplate);
}

// XSL Stylesheet Cache 6.0
abstract final class XSLTemplate60 {
  mixin(uuid("88d96a08-f192-11d4-a65f-0040963251e5"));
  mixin Interfaces!(IXSLTemplate);
}

// XML Data Source Object
abstract final class DSOControl {
  mixin(uuid("f6d90f14-9c73-11d3-b32e-00c04f990bb4"));
  mixin Interfaces!(IDSOControl);
}

// XML Data Source Object
abstract final class DSOControl26 {
  mixin(uuid("f5078f1f-c551-11d3-89b9-0000f81fe221"));
  mixin Interfaces!(IDSOControl);
}

// XML Data Source Object
abstract final class DSOControl30 {
  mixin(uuid("f5078f39-c551-11d3-89b9-0000f81fe221"));
  mixin Interfaces!(IDSOControl);
}

// XML Data Source Object
abstract final class DSOControl40 {
  mixin(uuid("88d969c4-f192-11d4-a65f-0040963251e5"));
  mixin Interfaces!(IDSOControl);
}

// XML HTTP Request class.
abstract final class XMLHTTP {
  mixin(uuid("f6d90f16-9c73-11d3-b32e-00c04f990bb4"));
  mixin Interfaces!(IXMLHTTPRequest);
}

// XML HTTP Request class.
abstract final class XMLHTTP26 {
  mixin(uuid("f5078f1e-c551-11d3-89b9-0000f81fe221"));
  mixin Interfaces!(IXMLHTTPRequest);
}

// XML HTTP Request class.
abstract final class XMLHTTP30 {
  mixin(uuid("f5078f35-c551-11d3-89b9-0000f81fe221"));
  mixin Interfaces!(IXMLHTTPRequest);
}

// XML HTTP Request class.
abstract final class XMLHTTP40 {
  mixin(uuid("88d969c5-f192-11d4-a65f-0040963251e5"));
  mixin Interfaces!(IXMLHTTPRequest);
}

// XML HTTP Request class 6.0
abstract final class XMLHTTP60 {
  mixin(uuid("88d96a0a-f192-11d4-a65f-0040963251e5"));
  mixin Interfaces!(IXMLHTTPRequest);
}

// Server XML HTTP Request class.
abstract final class ServerXMLHTTP {
  mixin(uuid("afba6b42-5692-48ea-8141-dc517dcf0ef1"));
  mixin Interfaces!(IServerXMLHTTPRequest);
}

// Server XML HTTP Request class.
abstract final class ServerXMLHTTP30 {
  mixin(uuid("afb40ffd-b609-40a3-9828-f88bbe11e4e3"));
  mixin Interfaces!(IServerXMLHTTPRequest);
}

// Server XML HTTP Request class.
abstract final class ServerXMLHTTP40 {
  mixin(uuid("88d969c6-f192-11d4-a65f-0040963251e5"));
  mixin Interfaces!(IServerXMLHTTPRequest2);
}

// Server XML HTTP Request 6.0 
abstract final class ServerXMLHTTP60 {
  mixin(uuid("88d96a0b-f192-11d4-a65f-0040963251e5"));
  mixin Interfaces!(IServerXMLHTTPRequest2);
}

// SAX XML Reader (version independent) coclass
abstract final class SAXXMLReader {
  mixin(uuid("079aa557-4a18-424a-8eee-e39f0a8d41b9"));
  mixin Interfaces!(IVBSAXXMLReader, ISAXXMLReader, IMXReaderControl);
}

// SAX XML Reader 3.0 coclass
abstract final class SAXXMLReader30 {
  mixin(uuid("3124c396-fb13-4836-a6ad-1317f1713688"));
  mixin Interfaces!(IVBSAXXMLReader, ISAXXMLReader, IMXReaderControl);
}

// SAX XML Reader 4.0 coclass
abstract final class SAXXMLReader40 {
  mixin(uuid("7c6e29bc-8b8b-4c3d-859e-af6cd158be0f"));
  mixin Interfaces!(IVBSAXXMLReader, ISAXXMLReader);
}

// SAX XML Reader 6.0
abstract final class SAXXMLReader60 {
  mixin(uuid("88d96a0c-f192-11d4-a65f-0040963251e5"));
  mixin Interfaces!(IVBSAXXMLReader, ISAXXMLReader);
}

// Microsoft XML Writer (version independent) coclass
abstract final class MXXMLWriter {
  mixin(uuid("fc220ad8-a72a-4ee8-926e-0b7ad152a020"));
  mixin Interfaces!(IMXWriter, ISAXContentHandler, ISAXErrorHandler, ISAXDTDHandler, ISAXLexicalHandler, ISAXDeclHandler, IVBSAXContentHandler, IVBSAXDeclHandler, IVBSAXDTDHandler, IVBSAXErrorHandler, IVBSAXLexicalHandler);
}

// Microsoft XML Writer 3.0 coclass
abstract final class MXXMLWriter30 {
  mixin(uuid("3d813dfe-6c91-4a4e-8f41-04346a841d9c"));
  mixin Interfaces!(IMXWriter, ISAXContentHandler, ISAXDeclHandler, ISAXDTDHandler, ISAXErrorHandler, ISAXLexicalHandler, IVBSAXContentHandler, IVBSAXDeclHandler, IVBSAXDTDHandler, IVBSAXErrorHandler, IVBSAXLexicalHandler);
}

// Microsoft XML Writer 4.0 coclass
abstract final class MXXMLWriter40 {
  mixin(uuid("88d969c8-f192-11d4-a65f-0040963251e5"));
  mixin Interfaces!(IMXWriter, ISAXContentHandler, ISAXDeclHandler, ISAXDTDHandler, ISAXErrorHandler, ISAXLexicalHandler, IVBSAXContentHandler, IVBSAXDeclHandler, IVBSAXDTDHandler, IVBSAXErrorHandler, IVBSAXLexicalHandler);
}

// Microsoft XML Writer 6.0
abstract final class MXXMLWriter60 {
  mixin(uuid("88d96a0f-f192-11d4-a65f-0040963251e5"));
  mixin Interfaces!(IMXWriter, ISAXContentHandler, ISAXDeclHandler, ISAXDTDHandler, ISAXErrorHandler, ISAXLexicalHandler, IVBSAXContentHandler, IVBSAXDeclHandler, IVBSAXDTDHandler, IVBSAXErrorHandler, IVBSAXLexicalHandler);
}

// Microsoft HTML Writer (version independent) coclass
abstract final class MXHTMLWriter {
  mixin(uuid("a4c23ec3-6b70-4466-9127-550077239978"));
  mixin Interfaces!(IMXWriter, ISAXContentHandler, ISAXErrorHandler, ISAXDTDHandler, ISAXLexicalHandler, ISAXDeclHandler, IVBSAXContentHandler, IVBSAXDeclHandler, IVBSAXDTDHandler, IVBSAXErrorHandler, IVBSAXLexicalHandler);
}

// Microsoft HTML Writer 3.0 coclass
abstract final class MXHTMLWriter30 {
  mixin(uuid("853d1540-c1a7-4aa9-a226-4d3bd301146d"));
  mixin Interfaces!(IMXWriter, ISAXContentHandler, ISAXDeclHandler, ISAXDTDHandler, ISAXErrorHandler, ISAXLexicalHandler, IVBSAXContentHandler, IVBSAXDeclHandler, IVBSAXDTDHandler, IVBSAXErrorHandler, IVBSAXLexicalHandler);
}

// Microsoft HTML Writer 4.0 coclass
abstract final class MXHTMLWriter40 {
  mixin(uuid("88d969c9-f192-11d4-a65f-0040963251e5"));
  mixin Interfaces!(IMXWriter, ISAXContentHandler, ISAXDeclHandler, ISAXDTDHandler, ISAXErrorHandler, ISAXLexicalHandler, IVBSAXContentHandler, IVBSAXDeclHandler, IVBSAXDTDHandler, IVBSAXErrorHandler, IVBSAXLexicalHandler);
}

// Microsoft HTML Writer 6.0
abstract final class MXHTMLWriter60 {
  mixin(uuid("88d96a10-f192-11d4-a65f-0040963251e5"));
  mixin Interfaces!(IMXWriter, ISAXContentHandler, ISAXDeclHandler, ISAXDTDHandler, ISAXErrorHandler, ISAXLexicalHandler, IVBSAXContentHandler, IVBSAXDeclHandler, IVBSAXDTDHandler, IVBSAXErrorHandler, IVBSAXLexicalHandler);
}

// SAX Attributes (version independent) coclass
abstract final class SAXAttributes {
  mixin(uuid("4dd441ad-526d-4a77-9f1b-9841ed802fb0"));
  mixin Interfaces!(IMXAttributes, IVBSAXAttributes, ISAXAttributes);
}

// SAX Attributes 3.0 coclass
abstract final class SAXAttributes30 {
  mixin(uuid("3e784a01-f3ae-4dc0-9354-9526b9370eba"));
  mixin Interfaces!(IMXAttributes, IVBSAXAttributes, ISAXAttributes);
}

// SAX Attributes 4.0 coclass
abstract final class SAXAttributes40 {
  mixin(uuid("88d969ca-f192-11d4-a65f-0040963251e5"));
  mixin Interfaces!(IMXAttributes, IVBSAXAttributes, ISAXAttributes);
}

// SAX Attributes 6.0
abstract final class SAXAttributes60 {
  mixin(uuid("88d96a0e-f192-11d4-a65f-0040963251e5"));
  mixin Interfaces!(IMXAttributes, IVBSAXAttributes, ISAXAttributes);
}

// MX Namespace Manager coclass
abstract final class MXNamespaceManager {
  mixin(uuid("88d969d5-f192-11d4-a65f-0040963251e5"));
  mixin Interfaces!(IVBMXNamespaceManager, IMXNamespaceManager);
}

// MX Namespace Manager 4.0 coclass
abstract final class MXNamespaceManager40 {
  mixin(uuid("88d969d6-f192-11d4-a65f-0040963251e5"));
  mixin Interfaces!(IVBMXNamespaceManager, IMXNamespaceManager);
}

// MX Namespace Manager 6.0
abstract final class MXNamespaceManager60 {
  mixin(uuid("88d96a11-f192-11d4-a65f-0040963251e5"));
  mixin Interfaces!(IVBMXNamespaceManager, IMXNamespaceManager);
}

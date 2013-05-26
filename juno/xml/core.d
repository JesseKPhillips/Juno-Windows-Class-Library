/**
 * Copyright: (c) 2009 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.xml.core;

import juno.base.string;

/// Specifies the type of the node.
enum XmlNodeType {
  None,                   /// An unsupported node.
  Element,                /// An element (for example, <code>&lt;item&gt;</code>).
  Attribute,              /// An attribute (for example, <code>id='123'</code>).
  Text,                   /// The text content of a node.
  CDATA,                  /// A _CDATA section (for example, <code>&lt;![_CDATA[my escaped text]]&gt;</code>).
  EntityReference,        /// A reference to an entity (for example, <code>&num;</code>).
  Entity,                 /// An entity declaration (for example, <code>&lt;!ENTITY...&gt;</code>).
  ProcessingInstruction,  /// A processing instruction (for example, <code>&lt;?pi test?&gt;</code>).
  Comment,                /// A comment (for example, <code>&lt;!-- my comment --&gt;</code>).
  Document,               /// A document object that provides access to the entire XML document.
  DocumentType,           /// The doucment type declaration (for example, <code>&lt;!DOCTYPE...&gt;</code>).
  DocumentFragment,       /// A document fragment.
  Notation,               /// A notation in the document type declaration (for example, <code>&lt;!NOTATION...&gt;</code>).
  Whitespace,             /// White space between markup.
  SignificantWhitespace,  /// White space between markup in a mixed content model.
  EndElement,             /// An end element tag (for example, <code>&lt;/item&gt;</code>).
  EndEntity,              /// The end of an entity.
  XmlDeclaration          /// The XML declaration (for example, <code>&lt;?xml version='1.0'?&gt;</code>).
}

string[XmlNodeType.max + 1] XmlNodeTypeString = [
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

enum XmlConformanceLevel {
  Auto,
  Fragment,
  Document
}

enum XmlReadState {
  Initial,
  Interactive,
  Error,
  EndOfFile,
  Closed
}

enum XmlStandalone {
  Omit,
  Yes,
  No
}

/**
 * Detailed information about the last exception.
 */
class XmlException : Exception {

  private int lineNumber_;
  private int linePosition_;
  private string sourceUri_;

  /**
   * Initializes a new instance with a specified error _message, line number, line position and XML file location.
   */
  public this(string message = null, int lineNumber = 0, int linePosition = 0, string sourceUri = null) {
    super(createMessage(message, lineNumber, linePosition));
    lineNumber_ = lineNumber;
    linePosition_ = linePosition_;
    sourceUri_ = sourceUri;
  }

  /**
   * Gets the line number indicating where the error occurred.
   */
  final int lineNumber() {
    return lineNumber_;
  }

  /**
   * Gets the line position indicating where the error occurred.
   */
  final int linePosition() {
    return linePosition_;
  }

  private static string createMessage(string s, int lineNumber, int linePosition) {
    string result = s;
    if (lineNumber != 0)
      result ~= format(" Line {0}, position {1}.", lineNumber, linePosition);
    return result;
  }

}

class XmlQualifiedName {

  private string name_;
  private string ns_;

  this(string name = "", string ns = "") {
    name_ = name;
    ns_ = ns;
  }

  override bool opEquals(Object other) {
    if (this is other)
      return true;
    if (auto qname = cast(XmlQualifiedName)other) {
      if (name_ == qname.name_)
        return ns_ == qname.ns_;
    }
    return false;
  }

  override int opCmp(Object other) {
    if (other is null)
      return 1;
    if (auto qname = cast(XmlQualifiedName)other) {
      int ret = typeid(string).compare(&ns_, &qname.ns_);
      if (ret == 0)
        ret = typeid(string).compare(&name_, &qname.name_);
      return ret;
    }
    return 1;
  }

  override hash_t toHash() {
    return typeid(string).getHash(&name_);
  }

  override string toString() {
    if (namespace != null)
      return namespace ~ ":" ~ name;
    return name;
  }

  final @property string name() {
    return name_;
  }

  final @property string namespace() {
    return ns_;
  }

}

/**
 * Copyright: (c) 2008 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.xml.core;

private import std.string : format;

/**
 */
enum XmlNodeType {
  None,
  Element,
  Attribute,
  Text,
  CDATA,
  EntityReference,
  Entity,
  ProcessingInstruction,
  Comment,
  Document,
  DocumentType,
  DocumentFragment,
  Notation,
  Whitespace,
  SignificantWhitespace,
  EndElement,
  EndEntity,
  XmlDeclaration
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

class XmlException : Exception {

  private int lineNumber_;
  private int linePosition_;
  private string sourceUri_;

  public this(string message = null, int lineNumber = 0, int linePosition = 0, string sourceUri = null) {
    super(createMessage(message, lineNumber, linePosition));
    lineNumber_ = lineNumber;
    linePosition_ = linePosition_;
    sourceUri_ = sourceUri;
  }

  final int lineNumber() {
    return lineNumber_;
  }

  final int linePosition() {
    return linePosition_;
  }

  private static string createMessage(string s, int lineNumber, int linePosition) {
    string result = s;
    if (lineNumber != 0)
      result ~= format(" Line %s, position %s.", lineNumber, linePosition);
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

  final string name() {
    return name_;
  }

  final string namespace() {
    return ns_;
  }

}

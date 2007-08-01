module juno.xml.constants;

public enum XmlNodeType {
  None,                     // MSXML, XmlLite
  Element,                  // MSXML, XmlLite
  Attribute,                // MSXML, XmlLite
  Text,                     // MSXML, XmlLite
  CDATA,                    // MSXML, XmlLite
  EntityReference,          // MSXML
  Entity,                   // MSXML
  ProcessingInstruction,    // MSXML, XmlLite
  Comment,                  // MSXML, XmlLite
  Document,                 // MSXML
  DocumentType,             // MSXML, XmlLite
  DocumentFragment,         // MSXML
  Notation,                 // MSXML
  Whitespace,               // XmlLite
  SignificantWhitespace,
  EndElement,
  EndEntity,
  XmlDeclaration            // XmlLite
}
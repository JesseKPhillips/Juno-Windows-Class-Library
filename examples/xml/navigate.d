module juno.examples.xml.navigate;

import juno.xml.all;
import std.stdio : writefln;

void main()
{
  XmlDocument xmlDocument = new XmlDocument();
  xmlDocument.load("book.xml");
  
  XPathNavigator xmlNavigator = xmlDocument.createNavigator();
  XmlNodeList nodeList = xmlNavigator.select("/books/book/author");
  
  writefln("Found %s nodes", nodeList.size);
  foreach (XmlNode aNode; nodeList)
  {
    writefln("node text: %s", aNode.text);
    writefln("node is author: %s", aNode.createNavigator.matches("/books/book/author"));
    writefln("node is price: %s", aNode.createNavigator.matches("/books/book/price"));
  }
}

module juno.examples.xml.write;

import juno.xml.all;

void main() {
  auto settings = new XmlWriterSettings;
  settings.indent = true;

  scope writer = XmlWriter.create("book.xml", settings);

  writer.writeStartDocument();
  writer.writeStartElement("books");
  writer.writeStartElement("book");
  writer.writeElementString("title", "Villette");
  writer.writeElementString("author", "Charlotte Brontë");
  writer.writeElementString("publisher", "Penguin");
  writer.writeElementString("price", "£7.99");
}
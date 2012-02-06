module juno.examples.xml.read;

import juno.xml.core, juno.xml.streaming;
import std.stdio : writefln;

void read() {
  scope reader = XmlReader.create("book.xml");

  while (reader.read()) {
    switch (reader.nodeType) {
      case XmlNodeType.Element:
        writefln("<%s>", reader.name);
        break;

      case XmlNodeType.Text:
        writefln(reader.value);
        break;

      case XmlNodeType.CDATA:
        writefln("<![CDATA[%s]]>", reader.value);
        break;

      case XmlNodeType.ProcessingInstruction:
        writefln("<?%s %s?>", reader.name, reader.value);
        break;

      case XmlNodeType.EndElement:
        writefln("</%s>", reader.name);
        break;

      default:
    }
  }    
}


void main() {
  if (juno.com.core.initAsClient())
  {
    scope(exit) juno.com.core.shutdown();
    read();
  }
}

module juno.examples.com.events;

import juno.com.core, juno.com.client, juno.xml.msxml;
import std.stdio : writefln;

void main() {
  auto doc = DOMDocument60.coCreate!(IXMLDOMDocument3);
  scope(exit) tryRelease(doc);

  auto events = new EventProvider!(XMLDOMDocumentEvents)(doc);
  scope(exit) tryRelease(events);

  events.bind("onReadyStateChange", {
    writefln("stage changed");
  });
  events.bind("onDataAvailable", {
    writefln("data available");
  });

  doc.put_async(com_true);

  com_bool result;
  doc.load("test.xml".toVariant(true), result);
}

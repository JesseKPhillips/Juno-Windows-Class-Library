module client;

import juno.com.core, hello;

import std.exception;

void main() {
  enforce(initAsClient());
  scope(exit) juno.com.core.shutdown();

  ISaysHello saysHello = SaysHello.coCreate!(ISaysHello);
  saysHello.sayHello(); // Prints "Hello there!"
  saysHello.Release();
}

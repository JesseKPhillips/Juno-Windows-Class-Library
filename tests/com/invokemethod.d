import juno.com.core;
import std.exception;

void main() {
  enforce(juno.com.core.initAsClient());
  scope(exit) juno.com.core.shutdown();

  auto ieApp = coCreate!(IDispatch, ExceptionPolicy.Throw)("InternetExplorer.Application");

  invokeMethod(ieApp, "Navigate", "http://www.amazon.com");
}

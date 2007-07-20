module juno.xml.core;

private import juno.base.core,
  juno.base.string,
  juno.io.core;

public class XmlException : BaseException {

  private int lineNumber_;
  private int linePosition_;
  private string sourceUri_;

  public this(string message = null) {
    this(message, 0, 0);
  }

  public this(string message, int lineNumber, int linePosition, string sourceUri = null) {
    super(createMessage(message, lineNumber, linePosition));
    lineNumber_ = lineNumber;
    linePosition_ = linePosition;
    sourceUri_ = sourceUri;
  }

  public final int lineNumber() {
    return lineNumber_;
  }

  public final int linePosition() {
    return linePosition_;
  }

  public final string sourceUri() {
    return sourceUri_;
  }

  private static string createMessage(string s, int lineNumber, int linePosition) {
    string result = s;
    if (lineNumber != 0)
      result = format(" Line {0}, position {1}.", lineNumber, linePosition);
    return result;
  }

}

public class XmlQualifiedName {

  private string name_;
  private string ns_;

  public this(string name = "", string ns = "") {
    name_ = name;
    ns_ = ns;
  }

  public override int opEquals(Object other) {
    if (this is other)
      return true;
    if (auto qname = cast(XmlQualifiedName)other) {
      if (name_ == qname.name_)
        return ns_ == qname.ns_;
    }
    return false;
  }

  public override int opCmp(Object other) {
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

  public override hash_t toHash() {
    return typeid(string).getHash(&name_);
  }

  public override string toString() {
    if (namespace != null)
      return namespace ~ ":" ~ name;
    return name;
  }

  public final string name() {
    return name_;
  }

  public final string namespace() {
    return ns_;
  }

}
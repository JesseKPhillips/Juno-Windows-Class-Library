/**
 * Contains classes used to send electronic _mail to a Simple Mail Transfer Protocol (SMTP) server for delivery.
 *
 * Copyright: (c) 2009 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.net.mail;

import juno.base.core,
  juno.base.string,
  juno.base.text,
  juno.base.collections,
  juno.com.core,
  juno.net.core;

/**
 * The exception thrown when the SmtpClient is unable to complete a send operation.
 */
class SmtpException : Exception {

  this(string message) {
    super(message);
  }

}

/**
 */
enum SmtpDeliveryMethod {
  Network,        ///
  PickupDirectory ///
}

/**
 * Allows applications to send e-mail using the Simple Mail Transfer Protocol (SMTP).
 * Examples:
 * ---
 * string from = `"Ben" ben@btinternet.com`;
 * string to = `"John" john@gmail.com`;
 * 
 * auto message = new MailMessage(from, to);
 * message.subject = "Re: Last Night";
 * message.bodyText = "Had a blast! Best, Ben.";
 *
 * string host = "smtp.btinternet.com";
 * auto client = new SmtpClient(host);
 *
 * auto credentials = new CredentialCache;
 * credentials.add(client.host, client.port, "Basic", userName, password);
 *
 * client.credentials = credentials;
 *
 * try {
 *   client.send(message);
 * }
 * catch (Exception e) {
 *   writefln("Couldn't send the message: " ~ e.toString());
 * }
 * ---
 */
class SmtpClient {

  private static const defaultPort_ = 25;

  @property {
    /// Gets or sets the name or IP address of the host used to send an e-mail message.
    string host;
    /// Gets or sets the port used to send an e-mail message. The default is 25.
    int port;
    /// Specifies how outgoing e-mail messages will be handled.
    SmtpDeliveryMethod deliveryMethod;
    /// Gets or sets the folder where applications save mail messages.
    string pickupDirectoryLocation;
    /// Gets or sets the credentials used to authenticate the sender.
    ICredentialsByHost credentials;
    /// Specifies whether to use Secure Sockets Layer (SSL) to encrypt the connection.
    bool enableSsl;
    /// Gets or sets the amount of time after which a send call times out.
    int timeout;
  }

  ///
  this() {
    initialize();
  }

  ///
  this(string host) {
    this.host = host;
    initialize();
  }

  ///
  this(string host, int port) {
    this.host = host;
    this.port = port;
    initialize();
  }

  /**
   * Sends an e-mail _message to an SMTP server for delivery.
   *
   * Throws:
   *    I do not think this should, but may throw MissingMemberException.
   * If it does I am interested in hearing about it as it may indicate a
   * bug or will improve my understanding of how this works. (So file
   * a bug report).
   */
  final void send(MailMessage message) {
    auto m = coCreate!(IDispatch)("CDO.Message");
    scope(exit) tryRelease(m);

    if (message.from !is null)
      setProperty(m, "From", message.from.toString());

    if (message.sender !is null)
      setProperty(m, "Sender", message.sender.toString());

    if (message.replyTo !is null)
      setProperty(m, "ReplyTo", message.replyTo.toString());

    if (message.to.length > 0)
      setProperty(m, "To", message.to.toString());

    if (message.cc.length > 0)
      setProperty(m, "Cc", message.cc.toString());

    if (message.bcc.length > 0)
      setProperty(m, "Bcc", message.bcc.toString());

    if (message.subject != null)
      setProperty(m, "Subject", message.subject);

    if (message.priority != MailPriority.Normal) {
      string importance;
      switch (message.priority) {
        case MailPriority.Normal: 
          importance = "normal"; 
          break;
        case MailPriority.Low: 
          importance = "low"; 
          break;
        case MailPriority.High:
          importance = "high";
          break;
        default: 
          break;
      }
      if (importance != null) {
        setProperty(m, "Fields", "urn:schemas:mailheader:importance", importance);

        if (auto fields = getProperty!(IDispatch)(m, "Fields")) {
          invokeMethod(fields, "Update");
          fields.Release();
        }
      }
    }

    if (message.bodyEncoding !is null) {
      if (auto bodyPart = getProperty!(IDispatch)(m, "BodyPart")) {
        setProperty(bodyPart, "Charset", message.bodyEncoding.bodyName);
        bodyPart.Release();
      }
    }

    if (message.headers.count > 0) {
      foreach (key; message.headers) {
        setProperty(m, "Fields", "urn:schemas:mailheader:" ~ key, message.headers[key]);
      }
      auto fields = getProperty!(IDispatch)(m, "Fields");
      invokeMethod(fields, "Update");
      fields.Release();
    }

    if (message.isBodyHtml)
      setProperty(m, "HtmlBody", message.bodyText);
    else
      setProperty(m, "TextBody", message.bodyText);

    foreach (attachment; message.attachments) {
      if (auto bodyPart = invokeMethod!(IDispatch)(m, "AddAttachment", attachment.fileName)) {
        scope(exit) tryRelease(bodyPart);

        switch (attachment.transferEncoding) {
          case TransferEncoding.QuotedPrintable:
            setProperty(bodyPart, "ContentTransferEncoding", "quoted-printable");
            break;
          case TransferEncoding.Base64:
            setProperty(bodyPart, "ContentTransferEncoding", "base64");
            break;
          case TransferEncoding.SevenBit:
            setProperty(bodyPart, "ContentTransferEncoding", "7bit");
            break;
          default:
        }
      }
    }

    if (auto config = getProperty!(IDispatch)(m, "Configuration")) {
      scope(exit) tryRelease(config);

      //invokeMethod(config, "Load", 2);

      if (deliveryMethod == SmtpDeliveryMethod.Network) {
        setProperty(config, "Fields", "http://schemas.microsoft.com/cdo/configuration/sendusing", 2);
        setProperty(config, "Fields", "http://schemas.microsoft.com/cdo/configuration/smtpusessl", enableSsl);
      }
      else if (deliveryMethod == SmtpDeliveryMethod.PickupDirectory) {
        setProperty(config, "Fields", "http://schemas.microsoft.com/cdo/configuration/sendusing", 1);
        if (pickupDirectoryLocation != null)
          setProperty(config, "Fields", "http://schemas.microsoft.com/cdo/configuration/smtpserverpickupdirectory", pickupDirectoryLocation);
      }

      if (host != null)
        setProperty(config, "Fields", "http://schemas.microsoft.com/cdo/configuration/smtpserver", host);
      if (port != 0)
        setProperty(config, "Fields", "http://schemas.microsoft.com/cdo/configuration/smtpserverport", port);

      if (credentials !is null) {
        if (auto credential = credentials.getCredential(host, port, "Basic")) {
          setProperty(config, "Fields", "http://schemas.microsoft.com/cdo/configuration/smtpauthenticate", 1);
          setProperty(config, "Fields", "http://schemas.microsoft.com/cdo/configuration/sendusername", credential.userName);
          setProperty(config, "Fields", "http://schemas.microsoft.com/cdo/configuration/sendpassword", credential.password);
        }
      }

      setProperty(config, "Fields", "http://schemas.microsoft.com/cdo/configuration/smtpconnectiontimeout", timeout / 1000);

      if (auto fields = getProperty!(IDispatch)(config, "Fields")) {
        invokeMethod(fields, "Update");
        fields.Release();
      }
    }

    invokeMethod(m, "Send");

    // Sync message headers so user can query them.
    static const string URN_SCHEMAS_MAILHEADER = "urn:schemas:mailheader:";

    if (auto fields = getProperty!(IDispatch)(m, "Fields")) {
      scope(exit) tryRelease(fields);

      if (auto fieldsEnum = invokeMethod!(IEnumVARIANT)(fields, "_NewEnum")) {
        scope(exit) tryRelease(fieldsEnum);

        uint fetched;
        VARIANT field;

        while (SUCCEEDED(fieldsEnum.Next(1, &field, fetched)) && fetched == 1) {
          scope(exit) field.clear();

          string name = getProperty!(string)(field.value!(IDispatch), "Name");
          if (name.startsWith(URN_SCHEMAS_MAILHEADER)) {
            name = name[URN_SCHEMAS_MAILHEADER.length .. $];
            string value = getProperty!(string)(field.value!(IDispatch), "Value");

            message.headers.set(name, value);
          }
        }
      }
    }
  }

  /// ditto
  final void send(string from, string recipients, string subject, string bodyText) {
    send(new MailMessage(from, recipients, subject, bodyText));
  }

  private void initialize() {
    timeout = 100000;
    if (port == 0)
      port = defaultPort_;
  }

}

/**
 * Represents the address of an electronic mail sender or recipient.
 */
class MailAddress {

  private string address_;
  private string displayName_;
  private string host_;
  private string user_;

  /// Initializes a new instance.
  this(string address) {
    this(address, null);
  }

  /// ditto
  this(string address, string displayName) {
    address_ = address;
    displayName_ = displayName;

    parse(address);
  }

  bool equals(Object value) {
    if (value is null)
      return false;
    import std.string;
    return (std.string.icmp(this.toString(), value.toString()) == 0);
  }

  override string toString() {
    return address;
  }

  @property
  {
    /// Gets the e-mail _address specified.
    final string address() {
      return address_;
    }
    
    /// Gets the display name specified.
    final string displayName() {
      return displayName_;
    }
    
    /// Gets the user information from the address specified.
    final string user() {
      return user_;
    }
    
    /// Gets the host portion of the address specified.
    final string host() {
      return host_;
    }
  } //@property

  private void parse(string address) {
    string display;
    int i = address.indexOf('\"');
    if (i > 0)
      throw new FormatException("The string is not in the form required for an e-mail address.");

    if (i == 0) {
      i = address.indexOf('\"', 1);
      if (i < 0)
        throw new FormatException("The string is not in the form required for an e-mail address.");
      display = address[1 .. i];
      if (address.length == i + 1)
        throw new FormatException("The string is not in the form required for an e-mail address.");
      address = address[i + 1 .. $];
    }
    /*if (display == null) {
      i = address.indexOf('<');
      if (i > 0) {
        display = address[0 .. i];
        address = address[i .. $];
      }
    }*/

    if (displayName_ == null)
      displayName_ = display;

    address = address.trim();

    i = address.indexOf('@');
    if (i < 0)
      throw new FormatException("The string is not in the form required for an e-mail address.");
    user_ = address[0 .. i];
    host_ = address[i + 1 .. $];
  }

}

  string toString(MailAddress[] ma) {
    string s;

    bool first = true;
    foreach (address; ma) {
      if (!first)
        s ~= ", ";
      s ~= address.toString();
      first = false;
    }

    return s;
  }


/**
 * Stores e-mail addresses associated with an e-mail message.
 */
deprecated
class MailAddressCollection : Collection!(MailAddress) {

  override string toString() {
    string s;

    bool first = true;
    foreach (address; this) {
      if (!first)
        s ~= ", ";
      s ~= address.toString();
      first = false;
    }

    return s;
  }

}

/**
 * TODO: Deprecate
 */
class NameValueCollection {

  private string[string] nameAndValue_;

  void add(string name, string value) {
    nameAndValue_[name] = value;
  }

  string get(string name) {
    if (auto value = name in nameAndValue_)
      return *value;
    return null;
  }

  void set(string name, string value) {
    nameAndValue_[name] = value;
  }

  @property int count() {
    return nameAndValue_.keys.length;
  }

  void opIndexAssign(string value, string name) {
    set(name, value);
  }
  string opIndex(string name) {
    return get(name);
  }

  int opApply(int delegate(ref string) action) {
    int r;

    foreach (key; nameAndValue_.keys) {
      if ((r = action(key)) != 0)
        break;
    }

    return r;
  }

  int opApply(int delegate(ref string, ref string) action) {
    int r;

    foreach (key, value; nameAndValue_) {
      if ((r = action(key, value)) != 0)
        break;
    }

    return r;
  }

}

enum TransferEncoding {
  Unknown = -1,
  QuotedPrintable = 0,
  Base64 = 1,
  SevenBit = 2
}

/**
 * Represents an e-mail attachment.
 */
class Attachment {

  @property {
    /// Gets or sets the name of the attachment file.
    string fileName;
    /// Gets or sets the type of encoding of this attachment.
    TransferEncoding transferEncoding = TransferEncoding.Unknown;
  }

  /// Initializes a new instance.
  this(string fileName) {
    this.fileName = fileName;
  }
}

/**
 * Stores attachments to be sent as part of an e-mail message.
 */
deprecated
class AttachmentCollection : Collection!(Attachment) {
}

/**
 */
enum MailPriority {
  Normal, ///
  Low,    ///
  High    ///
}

/**
 * Represents an e-mail message that can be sent using the SmtpClient class.
 */
class MailMessage {

  ///
  @property {
    MailAddress from;
    MailAddress sender;
    MailAddress replyTo;
    MailAddress[] to;
    MailAddress[] cc;
    MailAddress[] bcc;
    MailPriority priority;
    string subject;
    NameValueCollection headers;
    string bodyText;
    bool isBodyHtml;
    Encoding bodyEncoding;
    Attachment[] attachments;
  }

  /// Initializes a new instance.
  this() {
  }

  /// ditto
  this(string from, string to) {
    if (from == null)
      throw new ArgumentException("The parameter 'from' cannot be an empty string.", "from");
    if (to == null)
      throw new ArgumentException("The parameter 'to' cannot be an empty string.", "to");

    this.from = new MailAddress(from);
    this.to ~= new MailAddress(to);
  }

  /// ditto
  this(string from, string to, string subject, string bodyText) {
    this(from, to);
    this.subject = subject;
    this.bodyText = bodyText;
  }

  /// ditto
  this(MailAddress from, MailAddress to) {
    if (from is null)
      throw new ArgumentNullException("from");
    if (to is null)
      throw new ArgumentNullException("to");

    this.from = from;
    this.to ~= to;
  }
}

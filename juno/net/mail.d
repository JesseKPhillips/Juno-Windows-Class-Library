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
debug import std.stdio : writefln;

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

// Wrap any exception in SmtpException.
private R invokeMethod(R = VARIANT)(IDispatch target, string name, ...) {
  try {
    return juno.com.core.invokeMethod!(R)(target, name, _arguments, _argptr);
  }
  catch (Exception e) {
    throw new SmtpException(e.msg);
  }
}

private R getProperty(R = VARIANT)(IDispatch target, string name, ...) {
  try {
    return juno.com.core.getProperty!(R)(target, name, _arguments, _argptr);
  }
  catch (Exception e) {
    throw new SmtpException(e.msg);
  }
}

private void setProperty(IDispatch target, string name, ...) {
  try {
    juno.com.core.setProperty(target, name, _arguments, _argptr);
  }
  catch (Exception e) {
    throw new SmtpException(e.msg);
  }
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

  private static int defaultPort_ = 25;

  private string host_;
  private int port_;
  private SmtpDeliveryMethod deliveryMethod_;
  private string pickupDirectoryLocation_;
  private ICredentialsByHost credentials_;
  private bool enableSsl_;
  private int timeout_;

  ///
  this() {
    initialize();
  }

  ///
  this(string host) {
    host_ = host;
    initialize();
  }

  ///
  this(string host, int port) {
    host_ = host;
    port_ = port;
    initialize();
  }

  /// Sends an e-mail _message to an SMTP server for delivery.
  final void send(MailMessage message) {
    auto m = coCreate!(IDispatch)("CDO.Message");
    scope(exit) tryRelease(m);

    if (message.from !is null)
      setProperty(m, "From", message.from.toString());

    if (message.sender !is null)
      setProperty(m, "Sender", message.sender.toString());

    if (message.replyTo !is null)
      setProperty(m, "ReplyTo", message.replyTo.toString());

    if (message.to.count > 0)
      setProperty(m, "To", message.to.toString());

    if (message.cc.count > 0)
      setProperty(m, "Cc", message.cc.toString());

    if (message.bcc.count > 0)
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

      if (deliveryMethod_ == SmtpDeliveryMethod.Network) {
        setProperty(config, "Fields", "http://schemas.microsoft.com/cdo/configuration/sendusing", 2);
        setProperty(config, "Fields", "http://schemas.microsoft.com/cdo/configuration/smtpusessl", enableSsl_);
      }
      else if (deliveryMethod_ == SmtpDeliveryMethod.PickupDirectory) {
        setProperty(config, "Fields", "http://schemas.microsoft.com/cdo/configuration/sendusing", 1);
        if (pickupDirectoryLocation_ != null)
          setProperty(config, "Fields", "http://schemas.microsoft.com/cdo/configuration/smtpserverpickupdirectory", pickupDirectoryLocation_);
      }

      if (host_ != null)
        setProperty(config, "Fields", "http://schemas.microsoft.com/cdo/configuration/smtpserver", host_);
      if (port_ != 0)
        setProperty(config, "Fields", "http://schemas.microsoft.com/cdo/configuration/smtpserverport", port_);

      if (credentials_ !is null) {
        if (auto credential = credentials_.getCredential(host_, port_, "Basic")) {
          setProperty(config, "Fields", "http://schemas.microsoft.com/cdo/configuration/smtpauthenticate", 1);
          setProperty(config, "Fields", "http://schemas.microsoft.com/cdo/configuration/sendusername", credential.userName);
          setProperty(config, "Fields", "http://schemas.microsoft.com/cdo/configuration/sendpassword", credential.password);
        }
      }

      setProperty(config, "Fields", "http://schemas.microsoft.com/cdo/configuration/smtpconnectiontimeout", timeout_ / 1000);

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

  /// Gets or sets the name or IP address of the _host used to send an e-mail message.
  final void host(string value) {
    host_ = value;
  }
  /// ditto
  final string host() {
    return host_;
  }

  /// Gets or sets the _port used to send an e-mail message. The default is 25.
  final void port(int value) {
    port_ = value;
  }
  /// ditto
  final int port() {
    return port_;
  }

  /// Specifies how outgoing e-mail messages will be handled.
  final void deliveryMethod(SmtpDeliveryMethod value) {
    deliveryMethod_ = value;
  }
  /// ditto
  final SmtpDeliveryMethod deliveryMethod() {
    return deliveryMethod_;
  }

  /// Gets or sets the folder where applications save mail messages.
  final void pickupDirectoryLocation(string value) {
    pickupDirectoryLocation_ = value;
  }
  /// ditto
  final string pickupDirectoryLocation() {
    return pickupDirectoryLocation_;
  }

  /// Gets or sets the _credentials used to authenticate the sender.
  final void credentials(ICredentialsByHost value) {
    credentials_ = value;
  }
  /// ditto
  final ICredentialsByHost credentials() {
    return credentials_;
  }

  /// Specifies whether to use Secure Sockets Layer (SSL) to encrypt the connection.
  final void enableSsl(bool value) {
    enableSsl_ = value;
  }
  /// ditto
  final bool enableSsl() {
    return enableSsl_;
  }

  /// Gets or sets the amount of time after which a send call times out.
  final void timeout(int value) {
    timeout_ = value;
  }
  /// ditto
  final int timeout() {
    return timeout_;
  }

  private void initialize() {
    timeout_ = 100000;
    if (port_ == 0)
      port_ = defaultPort_;
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

/**
 * Stores e-mail addresses associated with an e-mail message.
 */
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

  private string fileName_;
  private TransferEncoding transferEncoding_ = TransferEncoding.Unknown;

  /// Initializes a new instance.
  this(string fileName) {
    fileName_ = fileName;
  }

  @property
  {
    /// Gets or sets the name of the attachment file.
    final void fileName(string value) {
      fileName_ = value;
    }
    /// ditto
    final string fileName() {
      return fileName_;
    }
    
    /// Gets or sets the type of encoding of this attachment.
    final void transferEncoding(TransferEncoding value) {
      transferEncoding_ = value;
    }
    /// ditto
    final TransferEncoding transferEncoding() {
      return transferEncoding_;
    }
  } //@property

}

/**
 * Stores attachments to be sent as part of an e-mail message.
 */
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

  private MailAddress from_;
  private MailAddress sender_;
  private MailAddress replyTo_;
  private MailAddressCollection to_;
  private MailAddressCollection cc_;
  private MailAddressCollection bcc_;
  private MailPriority priority_;
  private string subject_;
  private NameValueCollection headers_;
  private string bodyText_;
  private bool isBodyHtml_;
  private Encoding bodyEncoding_;
  private AttachmentCollection attachments_;

  /// Initializes a new instance.
  this() {
  }

  /// ditto
  this(string from, string to) {
    if (from == null)
      throw new ArgumentException("The parameter 'from' cannot be an empty string.", "from");
    if (to == null)
      throw new ArgumentException("The parameter 'to' cannot be an empty string.", "to");

    from_ = new MailAddress(from);
    this.to.add(new MailAddress(to));
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

    from_ = from;
    this.to.add(to);
  }

  @property
  {
    /// Gets or sets the _from address.
    final void from(MailAddress value) {
      if (value is null)
        throw new ArgumentNullException("value");
      from_ = value;
    }
    /// ditto
    final MailAddress from() {
      return from_;
    }
    
    /// Gets or sets the sender's address.
    final void sender(MailAddress value) {
      sender_ = value;
    }
    /// ditto
    final MailAddress sender() {
      return sender_;
    }
    
    /// Gets or sets the ReplyTo address.
    final void replyTo(MailAddress value) {
      replyTo_ = value;
    }
    /// ditto
    final MailAddress replyTo() {
      return replyTo_;
    }

    /// Gets the address collection containing the recipients.
    final MailAddressCollection to() {
      if (to_ is null)
        to_ = new MailAddressCollection;
      return to_;
    }
    
    /// Gets the address collection containing the carbon copy (CC) recipients.
    final MailAddressCollection cc() {
      if (cc_ is null)
        cc_ = new MailAddressCollection;
      return cc_;
    }
    
    /// Gets the address collection containing the blind carbon copy (BCC) recipients.
    final MailAddressCollection bcc() {
      if (bcc_ is null)
        bcc_ = new MailAddressCollection;
      return bcc_;
    }
    
    /// Gets or sets the _priority.
    final void priority(MailPriority value) {
      priority_ = value;
    }
    /// ditto
    final MailPriority priority() {
      return priority_;
    }

    /// Gets or sets the _subject line.
    final void subject(string value) {
      subject_ = value;
    }
    /// ditto
    final string subject() {
      return subject_;
    }
    
    /// Gets the e-mail _headers.
    final NameValueCollection headers() {
      if (headers_ is null)
        headers_ = new NameValueCollection;
      return headers_;
    }

    /// Gets or sets the message body.
    final void bodyText(string value) {
    
      bool isAscii(string value) {
        foreach (ch; value) {
          if (ch > 0x7f)
            return false;
        }
        return true;
      }
    
      bodyText_ = value;
      if (bodyEncoding_ is null && bodyText_ != null) {
        if (isAscii(bodyText_))
          bodyEncoding_ = Encoding.ASCII();
        else
          bodyEncoding_ = Encoding.UTF8();
      }
    }
    /// ditto
    final string bodyText() {
      return bodyText_;
    }

    /// Gets or sets whether the mail message body is in HTML.
    final void isBodyHtml(bool value) {
      isBodyHtml_ = value;
    }
    /// ditto
    final bool isBodyHtml() {
      return isBodyHtml_;
    }
    
    /// Gets or sets the encoding used to encode the message body.
    final void bodyEncoding(Encoding value) {
      bodyEncoding_ = value;
    }
    /// ditto
    final Encoding bodyEncoding() {
      return bodyEncoding_;
    }
    
    /// Gets the attachment collection used to store data attached to this e-mail message.
    final AttachmentCollection attachments() {
      if (attachments_ is null)
        attachments_ = new AttachmentCollection;
      return attachments_;
    }

  } //@property
}

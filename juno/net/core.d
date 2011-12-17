/**
 * Copyright: (c) 2009 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.net.core;

import juno.base.core,
  juno.base.string,
  juno.base.text,
  juno.base.environment,
  juno.base.native,
  juno.locale.convert,
  std.c.windows.winsock,
  std.socket;
debug import std.stdio : writefln;

pragma(lib, "ws2_32.lib");

/**
 * The exception that is thrown when an error occurs while accessing a network.
 */
class NetException : Exception {

  this() {
    super(getErrorMessage(GetLastError()));
  }

  this(string message) {
    super(message);
  }

  private static string getErrorMessage(uint errorCode) {
    static Handle moduleHandle;

    if (moduleHandle == Handle.init)
      moduleHandle = LoadLibrary("wininet.dll");

    // Try to get the error message from Wininet.dll.
    wchar[256] buffer;
    uint result = FormatMessage(FORMAT_MESSAGE_FROM_HMODULE, moduleHandle, errorCode, 0, buffer.ptr, buffer.length + 1, null);
    if (result != 0)
      return .toUTF8(buffer[0 .. result]);

    // Otherwise, get the error message from Windows.
    result = FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM, null, errorCode, 0, buffer.ptr, buffer.length + 1, null);
    if (result != 0)
      return .toUTF8(buffer[0 .. result]);

    return std.string.format("Unspecified error (0x%08X)", errorCode);
  }

}

/// Defines the parts of a URI.
enum UriPartial {
  Scheme,    /// The scheme segment of the URI.
  Authority, /// The scheme and authority segemnts of the URI.
  Path,      /// The scheme, authority and path segments of the URI.
  Query      /// The scheme, authority, path and query segments of the URI.
}

/// Specifies the parts of a URI.
enum UriComponents {
  Scheme          = 0x1,                                                        /// The scheme data.
  UserInfo        = 0x2,                                                        /// The userInfo data.
  Host            = 0x4,                                                        /// The host data.
  Port            = 0x8,                                                        /// The port data.
  Path            = 0x10,                                                       /// The localPath data.
  Query           = 0x20,                                                       /// The query data.
  Fragment        = 0x40,                                                       /// The fragment data.
  StrongPort      = 0x80,                                                       /// The port data. If no port data is in the Uri and a default port has been assigned to the scheme, the default port is returned.
  AbsoluteUri     = Scheme | UserInfo | Host | Port | Path | Query | Fragment,  /// The scheme, userInfo, host, port, localPath, query and fragment data.
  HostAndPort     = Host | StrongPort,                                          /// The host and port data. If no port data is in the Uri and a default port has been assigned to the scheme, the default port is returned.
  StrongAuthority = UserInfo | Host | StrongPort,                               /// The userInfo, host and port data. If no port data is in the Uri and a default port has been assigned to the scheme, the default port is returned.
  SchemeAndServer = Scheme | Host | Port,                                       /// The scheme, host and port data.
  PathAndQuery    = Path | Query,                                               /// The localPath and query data.
  KeepDelimiter   = 0x40000000                                                  /// Specifies that the delimiter should be included.
}

/**
 * Represents a uniform resource identifier (URI).
 */
class Uri {

  private struct UriScheme {
    string schemeName;
    int defaultPort;
  }

  const string uriSchemeHttp = "http";      /// Specifies that the URI is accessed through HTTP.
  const string uriSchemeHttps = "https";    /// Specifies that the URI is accessed through HTTPS.
  const string uriSchemeFtp = "ftp";        /// Specifies that the URI is accessed through FTP.
  const string uriSchemeFile = "file";      /// Specifies that the URI is a pointer to a file.
  const string uriSchemeNews = "news";      /// Specifies that the URI is a news groups and is accessed through NNTP.
  const string uriSchemeMailTo = "mailto";  /// Specifies that the URI is an e-mail address and is accessed through SMTP.
  const string schemeDelimiter = "://";

  private const UriScheme httpScheme = { uriSchemeHttp, 80 };
  private const UriScheme httpsScheme = { uriSchemeHttps, 443 };
  private const UriScheme ftpScheme = { uriSchemeFtp, 21 };
  private const UriScheme fileScheme = { uriSchemeFile, -1 };
  private const UriScheme newsScheme = { uriSchemeNews, -1 };
  private const UriScheme mailtoScheme = { uriSchemeMailTo, 25 };

  private string string_;
  private string cache_;
  private string scheme_;
  private string path_;
  private string query_;
  private string fragment_;
  private string userInfo_;
  private string host_;
  private int port_ = -1;

  /**
   * Initializes a new instance with the specified URI.
   * Params: s = A URI.
   */
  this(string s) {
    string_ = s;

    parseUri(s);
  }

  /**
   * Compares two Uri instances for equality.
   */
  final bool equals(Object obj) {
    if (obj is null)
      return false;

    if (this is obj)
      return true;

    if (auto other = cast(Uri)obj) {
      if (string_ == other.string_)
        return true;
      if (std.string.icmp(string_, other.string_) == 0)
        return true;
      if (std.string.cmp(string_, other.string_) == 0)
        return true;
    }

    return false;
  }

  /// ditto
  override typeof(super.opEquals(Object)) opEquals(Object obj) {
    return cast(typeof(super.opEquals(Object)))equals(obj);
  }

  /**
   * Gets a string representation of the URI.
   */
  override string toString() {
    if (!isAbsolute)
      return string_;
    return absoluteUri;
  }

  override uint toHash() {
    string hashString = getComponents(UriComponents.SchemeAndServer | UriComponents.PathAndQuery);
    return typeid(string).getHash(&hashString);
  }

  /**
   * Determines the difference between two Uri instances.
   */
  final Uri makeRelative(Uri uri) {

    string getDifference(string path1, string path2) {
      int i;
      int slash = -1;

      for (i = 0; i < path1.length && i < path2.length; i++) {
        if (path1[i] != path2[i])
          break;
        else if (path1[i] == '/')
          slash = i;
      }

      if (i == 0)
        return path2;

      if (i == path1.length 
        && i == path2.length)
        return null;

      string relativePath;
      for (; i < path1.length; i++) {
        if (path1[i] == '/')
          relativePath ~= "../";
      }

      return relativePath ~ path2[slash + 1 .. $];
    }

    if (scheme == uri.scheme && host == uri.host && port == uri.port)
      return new Uri(getDifference(absolutePath, uri.absolutePath) ~ uri.getComponents(UriComponents.Fragment | UriComponents.Query));
    return uri;
  }

  /**
   * Gets the specified _components.
   * Params: components = Specifies which parts of the URI to return.
   */
  final string getComponents(UriComponents components) {
    if (!isAbsolute)
      throw new InvalidOperationException("This operation is not supported for a relative URI.");

    if (components == UriComponents.Scheme)
      return scheme_;

    if (components == UriComponents.Host)
      return host_;

    if (components == UriComponents.Port || components == UriComponents.StrongPort) {
      if (!isDefaultPort || (components == UriComponents.StrongPort && getDefaultPort(scheme_) != -1))
        return .toString(port_);
    }

    if ((components & UriComponents.StrongPort) != 0)
      components |= UriComponents.Port;

    UriComponents parts = components & ~UriComponents.KeepDelimiter;

    string result;

    // Scheme
    if ((parts & UriComponents.Scheme) != 0) {
      result ~= scheme_;
      if (parts != UriComponents.Scheme) {
        result ~= ':';
        if (host_ != null && port_ != -1)
          result ~= "//";
      }
    }

    // UserInfo
    if ((parts & UriComponents.UserInfo) != 0 && userInfo_ != null) {
      result ~= userInfo_;
      if (components != UriComponents.UserInfo)
        result ~= '@';
    }

    // Host
    if ((parts & UriComponents.Host) != 0 && host_ != null) {
      result ~= host_;
    }

    // Port
    if ((parts & UriComponents.Port) != 0) {
      if (!isDefaultPort || (parts & UriComponents.StrongPort) != 0) {
        result ~= ':';
        result ~= .toString(port_);
      }
    }

    // Path
    if ((parts & UriComponents.Path) != 0) {
      result ~= path_;
      if (components == UriComponents.Path) {
        if (result[0] == '/')
          return result[1 .. $];
        else
          return result;
      }
    }

    // Query
    if ((parts & UriComponents.Query) != 0) {
      result ~= query_;
      if (components == UriComponents.Query) {
        if (result[0] == '?')
          return result[1 .. $];
        else
          return result;
      }
    }

    // Fragment
    if ((parts & UriComponents.Fragment) != 0) {
      result ~= fragment_;
      if (components == UriComponents.Fragment) {
        if (result[0] == '#')
          return result[1 .. $];
        else
          return result;
      }
    }

    return result;
  }

  /**
   * Gets the specified portion of a URI.
   * Params: part = Specifies the end of the URI portion to return.
   */
  string getLeftPart(UriPartial part) {
    switch (part) {
      case UriPartial.Scheme:
        return getComponents(UriComponents.KeepDelimiter | UriComponents.Scheme);
      case UriPartial.Authority:
        return getComponents(UriComponents.SchemeAndServer | UriComponents.UserInfo);
      case UriPartial.Path:
        return getComponents(UriComponents.Path | UriComponents.SchemeAndServer | UriComponents.UserInfo);
      case UriPartial.Query:
        return getComponents(UriComponents.PathAndQuery | UriComponents.SchemeAndServer | UriComponents.UserInfo);
      default:
        return null;
    }
  }

  /**
   * Indicates whether the instance is absolute.
   */
  final @property bool isAbsolute() {
    return scheme_ != null;
  }

  /**
   * Indicates whether the instance is a file URI.
   */
  final @property bool isFile() {
    return scheme_ == fileScheme.schemeName;
  }

  /**
   * Gets the absolute URI.
   */
  final @property string absoluteUri() {
    if (cache_ == null)
      cache_ = getComponents(UriComponents.AbsoluteUri);
    return cache_;
  }

  /**
   * Gets the _scheme name for this URI.
   */
  final @property string scheme() {
    return scheme_;
  }

  /**
   * Gets the Domain Name System (DNS) host name or IP address and the port number for a server.
   */
  final @property string authority() {
    //return isDefaultPort ? host_ : host_ ~ ":" ~ .toString(port_);
    return getComponents(UriComponents.Host | UriComponents.Port);
  }

  /**
   * Gets the absolute path and query information separated by a question mark (?).
   */
  final @property string pathAndQuery() {
    //return path_ ~ query_;
    return getComponents(UriComponents.PathAndQuery);
  }

  /**
   * Gets any _query information included in this URI.
   */
  final @property string query() {
    //return query_;
    return getComponents(UriComponents.Query | UriComponents.KeepDelimiter);
  }

  /**
   * Gets the URI _fragment.
   */
  final @property string fragment() {
    //return fragment_;
    return getComponents(UriComponents.Fragment | UriComponents.KeepDelimiter);
  }

  /**
   * Gets the user name, password, or other user-specific information associated with this URI.
   */
  final @property string userInfo() {
    //return userInfo_;
    return getComponents(UriComponents.UserInfo);
  }

  /**
   * Gets the _host component.
   */
  final @property string host() {
    //return host_;
    return getComponents(UriComponents.Host);
  }

  /**
   * Indicates whether the port value of the URI is the default for this scheme.
   */
  @property bool isDefaultPort() {
    return (getDefaultPort(scheme_) == port_);
  }

  /**
   * Gets the _port number of this URI.
   */
  final @property int port() {
    return port_;
  }

  /**
   * Gets the _original URI string that was passed to the constructor.
   */
  final @property string original() {
    return string_;
  }

  /**
   * Gets the local operating-system path of a file name.
   */
  final @property string localPath() {
    //return path_;
    return getComponents(UriComponents.Path | UriComponents.KeepDelimiter);
  }

  final @property string absolutePath() {
    return getComponents(UriComponents.Path | UriComponents.KeepDelimiter);
  }

  /**
   * Gets an array containing the path _segments that make up this URI.
   */
  final @property string[] segments() {
    string[] segments;

    string path = getComponents(UriComponents.Path | UriComponents.KeepDelimiter);

    if (path.length != 0) {
      int current;
      while (current < path.length) {
        int next = path.indexOf('/', current);
        if (next == -1)
          next = path.length - 1;

        segments ~= path[current .. next + 1];

        current = next + 1;
      }
    }

    return segments;
  }

  private void parseUri(string s) {
    int i = s.indexOf(':');
    if (i < 0)
      return;

    if (i == 1) {
      // Windows absolute path
      scheme_ = fileScheme.schemeName;
      port_ = fileScheme.defaultPort;
      path_ = s.replace("\\", "/");
    }
    else {
      scheme_ = s[0 .. i].toLower();
      s = s[i + 1 .. $];

      i = s.indexOf('#');
      if (i != -1) {
        fragment_ = s[i .. $];
        s = s[0 .. i];
      }

      i = s.indexOf('?');
      if (i != -1) {
        query_ = s[i .. $];
        s = s[0 .. i];
      }

      bool unixPath = (scheme_ == fileScheme.schemeName && s.startsWith("///"));

      if (s[0 .. 2] == "//") {
        if (s.startsWith("////"))
          unixPath = false;
        s = s[2 .. $];
      }

      i = s.indexOf('/');
      if (i == -1) {
        path_ = "/";
      }
      else {
        path_ = s[i .. $];
        s = s[0 .. i];
      }

      i = s.indexOf('@');
      if (i != -1) {
        userInfo_ = s[0 .. i];
        s = s.remove(0, i + 1);
      }

      port_ = -1;
      i = s.lastIndexOf(':');
      if (i != -1 && i != s.length - 1) {
        string sport = s.remove(0, i + 1);
        if (sport.length > 1 && sport[$ - 1] != ']') {
          port_ = cast(int)parse!(ushort)(sport);
          s = s[0 .. i];
        }
      }
      if (port_ == -1)
        port_ = getDefaultPort(scheme_);

      host_ = s;

      if (unixPath) {
        path_ = '/' ~ s;
        host_ = null;
      }
    }
  }

  private int getDefaultPort(string scheme) {
    scheme = scheme.toLower();

    if (scheme == httpScheme.schemeName)
      return httpScheme.defaultPort;
    else if (scheme == httpsScheme.schemeName)
      return httpsScheme.defaultPort;
    else if (scheme == ftpScheme.schemeName)
      return ftpScheme.defaultPort;
    else if (scheme == fileScheme.schemeName)
      return fileScheme.defaultPort;
    else if (scheme == newsScheme.schemeName)
      return newsScheme.defaultPort;
    else if (scheme == mailtoScheme.schemeName)
      return mailtoScheme.defaultPort;

    return -1;
  }

}

/**
 */
interface ICredentials {

  ///
  NetworkCredential getCredential(Uri uri, string authType);

}

/**
 */
interface ICredentialsByHost {

  ///
  NetworkCredential getCredential(string host, int port, string authType);

}

private class CredentialKey {

  Uri uriPrefix;
  int uriPrefixLength = -1;
  string authType;

  this(Uri uriPrefix, string authType) {
    this.uriPrefix = uriPrefix;
    this.uriPrefixLength = uriPrefix.toString().length;
    this.authType = authType;
  }

  bool match(Uri uri, string authType) {
    if (uri is null)
      return false;
    if (std.string.icmp(authType, this.authType) != 0)
      return false;
    if (uriPrefix.scheme != uri.scheme || uriPrefix.host != uri.host || uriPrefix.port != uri.port)
      return false;
    return std.string.icmp(uriPrefix.absolutePath, uri.absolutePath) == 0;
  }

  override typeof(super.opEquals(Object)) opEquals(Object obj) {
    if (auto other = cast(CredentialKey)obj)
      return (std.string.icmp(authType, other.authType) == 0 && uriPrefix.equals(other.uriPrefix));
    return false;
  }

  override uint toHash() {
    return typeid(string).getHash(&authType) + uriPrefixLength + uriPrefix.toHash();
  }

}

private class CredentialHostKey {

  string host;
  int port;
  string authType;

  this(string host, int port, string authType) {
    this.host = host;
    this.port = port;
    this.authType = authType;
  }

  bool match(string host, int port, string authType) {
    if (std.string.icmp(authType, this.authType) != 0)
      return false;
    if (std.string.icmp(host, this.host) != 0)
      return false;
    if (port != this.port)
      return false;
    return true;
  }

  override typeof(super.opEquals(Object)) opEquals(Object obj) {
    if (auto other = cast(CredentialHostKey)obj)
      return (std.string.icmp(host, other.host) == 0 && std.string.icmp(authType, other.authType) == 0 && port == other.port);
    return false;
  }

  override uint toHash() {
    return (typeid(string).getHash(&host) + typeid(string).getHash(&authType) + port);
  }

}

/**
 */
class CredentialCache : ICredentials, ICredentialsByHost {

  private NetworkCredential[CredentialKey] cache_;
  private NetworkCredential[CredentialHostKey] hostCache_;

  ///
  final NetworkCredential getCredential(Uri uriPrefix, string authType) {
    foreach (key, value; cache_) {
      if (key.match(uriPrefix, authType))
        return value;
    }
    return null;
  }

  ///
  final NetworkCredential getCredential(string host, int port, string authType) {
    foreach (key, value; hostCache_) {
      if (key.match(host, port, authType))
        return value;
    }
    return null;
  }

  ///
  final void add(Uri uriPrefix, string authType, NetworkCredential credential) {
    auto key = new CredentialKey(uriPrefix, authType);
    cache_[key] = credential;
  }

  ///
  final void add(string host, int port, string authType, NetworkCredential credential) {
    auto key = new CredentialHostKey(host, port, authType);
    hostCache_[key] = credential;
  }

  ///
  final void remove(Uri uriPrefix, string authType) {
    auto key = new CredentialKey(uriPrefix, authType);
    cache_.remove(key);
  }

  ///
  final void remove(string host, int port, string authType) {
    auto key = new CredentialHostKey(host, port, authType);
    hostCache_.remove(key);
  }

}
/**
 */
class NetworkCredential : ICredentials, ICredentialsByHost {

  //private ubyte[] userName_;
  //private ubyte[] password_;
  private string userName_;
  private string password_;

  ///
  this() {
  }

  ///
  this(string userName, string password) {
    //userName_ = encrypt(userName);
    //password_ = encrypt(password);
    userName_ = userName;
    password_ = password;
  }

  ///
  NetworkCredential getCredential(Uri uri, string authType) {
    return this;
  }

  ///
  NetworkCredential getCredential(string host, int port, string authType) {
    return this;
  }

  @property
  {
    ///
    final void userName(string value) {
      //userName_ = encrypt(value);
      userName_ = value;
    }
    /// ditto
    final string userName() {
      //return decrypt(userName_);
      return userName_;
    }

    ///
    final void password(string value) {
      //password_ = encrypt(value);
      password_ = value;
    }
    /// ditto
    final string password() {
      //return decrypt(password_);
      return password_;
    }
  } //@property
}

// Internet Protocol

extern(Windows):

enum {
  WSAEINVAL           = 10022,
  WSAEPROTONOSUPPORT  = 10043,
  WSAEOPNOTSUPP       = 10045,
  WSAEAFNOSUPPORT     = 10047
}

struct WSAPROTOCOL_INFOW {
}

int WSAStringToAddressW(in wchar* AddressString, int AddressFamily, WSAPROTOCOL_INFOW* lpProtocolInfo, sockaddr* lpAddress, ref int lpAddressLength);
alias WSAStringToAddressW WSAStringToAddress;

int WSAAddressToStringW(sockaddr* lpAddress, uint dwAddressLength, WSAPROTOCOL_INFOW* lpProtocolInfo, wchar* lpszAddressString, ref uint lpdwAddressStringLength);
alias WSAAddressToStringW WSAAddressToString;

alias DllImport!("ws2_32.dll", "getaddrinfo",
  int function(in char* nodename, in char* servname, addrinfo* hints, addrinfo** res)) getaddrinfo;

alias DllImport!("ws2_32.dll", "freeaddrinfo",
  void function(addrinfo* ai)) freeaddrinfo;

enum {
  NI_NAMEREQD = 0x04
}

alias DllImport!("ws2_32.dll", "getnameinfo",
  int function(in sockaddr* sa, socklen_t saLen, char* host, uint hostLen, char* serv, uint servLen, int flags)) getnameinfo;

alias DllImport!("icmp.dll", "IcmpCreateFile",
  Handle function()) IcmpCreateFileWin2k;

alias DllImport!("iphlpapi.dll", "IcmpCreateFile",
  Handle function()) IcmpCreateFile;

alias DllImport!("iphlpapi.dll", "Icmp6CreateFile",
  Handle function()) Icmp6CreateFile;

alias DllImport!("icmp.dll", "IcmpCloseHandle",
  BOOL function(Handle IcmpHandle)) IcmpCloseHandleWin2k;

alias DllImport!("iphlpapi.dll", "IcmpCloseHandle",
  BOOL function(Handle IcmpHandle)) IcmpCloseHandle;

struct IP_OPTION_INFORMATION {
  ubyte ttl;
  ubyte tos;
  ubyte flags;
  ubyte optionsSize;
  ubyte* optionsData;
}

struct ICMP_ECHO_REPLY {
  uint address;
  uint status;
  uint roundTripTime;
  ushort dataSize;
  ushort reserved;
  void* data;
  IP_OPTION_INFORMATION options;
}

struct IPV6_ADDRESS_EX {
  align(1):
  ushort sin6_port;
  uint sin6_flowinfo;
  //ushort[8] sin6_addr;
  ubyte[16] sin6_addr;
  uint sin6_scope_id;
}

struct ICMPV6_ECHO_REPLY {
  IPV6_ADDRESS_EX address;
  uint status;
  uint roundTripTime;
}

enum : uint {
  IP_SUCCESS                 = 0,
  IP_BUF_TOO_SMALL           = 11001 + 1,
  IP_DEST_NET_UNREACHABLE,
  IP_DEST_HOST_UNREACHABLE,
  IP_DEST_PROT_UNREACHABLE,
  IP_DEST_PORT_UNREACHABLE,
  IP_NO_RESOURCES,
  IP_BAD_OPTION,
  IP_HW_ERROR,
  IP_PACKET_TOO_BIG,
  IP_REQ_TIMED_OUT,
  IP_BAD_REQ,
  IP_BAD_ROUTE,
  IP_TTL_EXPIRED_TRANSIT,
  IP_TTL_EXPIRED_REASSEM,
  IP_PARAM_PROBLEM,
  IP_SOURCE_QUENCH,
  IP_OPTION_TOO_BIG,
  IP_BAD_DESTINATION
}

alias DllImport!("icmp.dll", "IcmpSendEcho2",
  uint function(Handle IcmpHandle, Handle Event, void* ApcRoutine, void* ApcContext, uint DestinationAddress, void* RequestData, ushort RequestSize, void* RequestOptions, void* ReplyBuffer, uint ReplySize, uint Timeout))
  IcmpSendEcho2Win2k;

alias DllImport!("iphlpapi.dll", "IcmpSendEcho2",
  uint function(Handle IcmpHandle, Handle Event, void* ApcRoutine, void* ApcContext, uint DestinationAddress, void* RequestData, ushort RequestSize, void* RequestOptions, void* ReplyBuffer, uint ReplySize, uint Timeout))
  IcmpSendEcho2;

alias DllImport!("iphlpapi.dll", "Icmp6SendEcho2",
  uint function(Handle IcmpHandle, Handle Event, void* ApcRoutine, void* ApcContext, void* SourceAddress, void* DestinationAddress, void* RequestData, ushort RequestSize, void* RequestOptions, void* ReplyBuffer, uint ReplySize, uint Timeout))
  Icmp6SendEcho2;

extern(D):

private @property bool isWin2k() {
  static Optional!(bool) isWin2k_;
  if (!isWin2k_.hasValue)
    isWin2k_ = (osVersion.major == 5 && osVersion.minor == 0);
  return isWin2k_.value;
}

private @property bool supportsIPv6() {
  static Optional!(bool) supportsIPv6_;
  if (!supportsIPv6_.hasValue) {
    uint s = socket(AF_INET6, SOCK_DGRAM, IPPROTO_IP);
    if (GetLastError() != WSAEAFNOSUPPORT)
      supportsIPv6_ = true;
    else
      supportsIPv6_ = false;

    closesocket(s);
  }
  return supportsIPv6_.value;
}

private SocketException socketException(uint errorCode = GetLastError()) {
  return new SocketException(getErrorMessage(errorCode), errorCode);
}

// Replacements for Phobos's InternetHost and InternetAddress classes.
// IPHost and IPAddress are IPv6-aware.

/**
 * Provides a container class for Internet host address information.
 */
class IPHost {

  /// A list of IP addresses associated with the host.
  IPAddress[] addressList;

  /// A list of aliases associated with the host.
  string[] aliases;

  /// The DNS name of the host.
  string hostName;

  /// Resolves an IP address to an IPHost instance.
  static IPHost get(IPAddress address) {
    return getByAddress(address, /*includeIPv6*/ true);
  }

  /// Resolves a host name or IP address to an IPHost instance.
  static IPHost get(string hostNameOrAddress) {
    IPAddress addr;
    if (IPAddress.tryParse(hostNameOrAddress, addr)
      && (addr.addressFamily == AddressFamily.INET || addr.addressFamily.INET6))
      return getByAddress(addr, true);
    return getByName(hostNameOrAddress, /*includeIPv6*/ true);
  }

  static IPHost getByAddress(IPAddress address) {
    return getByAddress(address, /*includeIPv6*/ false);
  }

  static IPHost getByAddress(string address) {
    return getByAddress(IPAddress.parse(address), /*includeIPv6*/ false);
  }

  static IPHost getByName(string hostName) {
    return getByName(hostName, /*includeIPv6*/ false);
  }

  private static IPHost getByAddress(IPAddress address, bool includeIPv6) {
    if (includeIPv6 && supportsIPv6) {
      addrinfo* info;
      addrinfo hints = addrinfo(AI_CANONNAME, AF_UNSPEC);

      ubyte[sockaddr_in6.sizeof] addr;
      addr[0 .. 2] = [cast(ubyte)address.family_, cast(ubyte)(address.family_ >> 8)];

      int offset = 8;
      foreach (n; address.numbers_)
        addr[offset++ .. offset++ + 1] = [cast(ubyte)(n >> 8), cast(ubyte)n];

      if (address.scopeId_ > 0)
        addr[24 .. $] = [cast(ubyte)address.scopeId_, cast(ubyte)(address.scopeId_ >> 8), cast(ubyte)(address.scopeId_ >> 16), cast(ubyte)(address.scopeId_ >> 24)];
      ubyte[] addrBytes = address.getAddress();
      addr[8 .. 8 + addrBytes.length] = addrBytes;

      char[1025] hostName;
      if (getnameinfo(cast(sockaddr*)addr.ptr, addr.length, hostName.ptr, hostName.length, null, 0, NI_NAMEREQD) != 0)
        throw socketException();

      if (getaddrinfo(hostName.ptr, null, &hints, &info) != 0)
        throw socketException();
      scope(exit) freeaddrinfo(info);

      return fromAddrInfo(info);
    }

    if (address.addressFamily == AddressFamily.INET6)
      throw socketException(WSAEPROTONOSUPPORT);

    uint a = address.address_;
    version(BigEndian) {
      a = htol(a);
    }
    auto he = gethostbyaddr(&a, uint.sizeof, PF_INET);
    if (he == null)
      throw socketException();

    return fromHostEntry(he);
  }

  private static IPHost getByName(string hostName, bool includeIPv6) {
    if (includeIPv6 && supportsIPv6) {
      addrinfo* info;
      addrinfo hints = addrinfo(AI_CANONNAME, AF_UNSPEC);

      if (getaddrinfo(hostName.toUtf8z(), null, &hints, &info) != 0)
        throw socketException();
      scope(exit) freeaddrinfo(info);

      return fromAddrInfo(info);
    }

    auto he = gethostbyname(hostName.toUtf8z());
    if (he == null) 
      throw socketException();

    return fromHostEntry(he);
  }

  private static IPHost fromHostEntry(hostent* entry) {
    auto host = new IPHost;

    if (entry.h_name != null)
      host.hostName = toUtf8(entry.h_name);

    for (int i = 0;; i++) {
      if (entry.h_aliases[i] == null)
        break;
      host.aliases ~= toUtf8(entry.h_aliases[i]);
    }

    for (int i = 0;; i++) {
      if (entry.h_addr_list[i] == null)
        break;
      uint address = *cast(uint*)entry.h_addr_list[i];
      version(BigEndian) {
        address = htol(address);
      }
      host.addressList ~= new IPAddress(address);
    }

    return host;
  }

  private static IPHost fromAddrInfo(addrinfo* info) {
    auto host = new IPHost;

    while (info != null) {
      if (host.hostName == null && info.ai_canonname != null)
        host.hostName = toUtf8(info.ai_canonname);

      if (info.ai_family == AF_INET || info.ai_family == AF_INET6) {
        if (info.ai_family == AF_INET6) {
          auto addr = cast(sockaddr_in6*)info.ai_addr;
          host.addressList ~= new IPAddress((cast(ubyte*)addr)[8 .. info.ai_addrlen], addr.sin6_scope_id);
        }
        else {
          auto addr = cast(sockaddr_in*)info.ai_addr;
          host.addressList ~= new IPAddress(addr.sin_addr.s_addr);
        }
      }

      info = info.ai_next;
    }

    return host;
  }

}

class SocketAddress {

  const uint ipv4AddressSize = sockaddr_in.sizeof;
  const uint ipv6AddressSize = sockaddr_in6.sizeof;

  private ubyte[] buffer_;
  private uint size_;

  this(AddressFamily family, uint size = 32) {
    size_ = size;
    buffer_.length = size;
    version(BigEndian) {
      buffer_[0 .. 2] = [cast(ubyte)(family >> 8), cast(ubyte)family];
    }
    else {
      buffer_[0 .. 2] = [cast(ubyte)family, cast(ubyte)(family >> 8)];
    }
  }

  void opIndexAssign(ubyte value, int index) {
    buffer_[index] = value;
  }
  ubyte opIndex(int index) {
    return buffer_[index];
  }

  uint size() {
    return size_;
  }

  AddressFamily addressFamily() {
    version(BigEndian) {
      return cast(AddressFamily)((buffer_[0] << 8) | buffer_[1]);
    }
    else {
      return cast(AddressFamily)(buffer_[0] | (buffer_[1] << 8));
    }
  }

}

/**
 * Provides an Internet Protocol (IP) address.
 */
class IPAddress {

  static IPAddress none;          ///
  static IPAddress any;           ///
  static IPAddress loopback;      ///
  static IPAddress broadcast;     ///
  static IPAddress ipv6None;      ///
  static IPAddress ipv6Any;       ///
  static IPAddress ipv6Loopback;  ///

  static this() {
    none = new IPAddress(0xFFFFFFFF);
    any = new IPAddress(0x00000000);
    loopback = new IPAddress(0x0100007F);
    broadcast = new IPAddress(0xFFFFFFFF);
    ipv6None = new IPAddress([0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);
    ipv6Any = new IPAddress([0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);
    ipv6Loopback = new IPAddress([0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1]);
  }

  static ~this() {
    none = null;
    any = null;
    loopback = null;
    broadcast = null;
    ipv6None = null;
    ipv6Any = null;
    ipv6Loopback = null;
  }

  private uint address_;
  private AddressFamily family_ = AddressFamily.INET;
  private ushort[8] numbers_;
  private uint scopeId_;

  private string string_;

  /// Initializes a new instance.
  this(uint address) {
    address_ = address;
  }

  /// ditto
  this(ubyte[] address) {
    if (address.length == 4) {
      family_ = AddressFamily.INET;
      address_ = ((address[3] << 24 | address[2] << 16 | address[1] << 8 | address[0]) & 0xffffffff);
    }
    else {
      family_ = AddressFamily.INET6;
      for (int i = 0; i < 8; i++) {
        numbers_[i] = cast(ushort)(address[i * 2] * 256 + address[i * 2 + 1]);
      }
    }
  }

  /// ditto
  this(ubyte[] address, uint scopeId) {
    family_ = AddressFamily.INET6;
    for (int i = 0; i < 8; i++) {
      numbers_[i] = cast(ushort)(address[i * 2] * 256 + address[i * 2 + 1]);
    }
    scopeId_ = scopeId;
  }

  private this(ushort[] address, uint scopeId) {
    family_ = AddressFamily.INET6;
    numbers_[0 .. 8] = address;
    scopeId_ = scopeId;
  }

  /// Returns the IPAddress as an array of bytes.
  final ubyte[] getAddress() {
    ubyte[] bytes;
    if (family_ == AddressFamily.INET6) {
      bytes.length = 16;
      int offset;
      for (int i = 0; i < 8; i++) {
        bytes[offset++ .. offset++ + 1] = [
          cast(ubyte)((numbers_[i] >> 8) & 0xff),
          cast(ubyte)(numbers_[i] & 0xff)
        ];
      }
    }
    else {
      bytes = [
        cast(ubyte)address_,
        cast(ubyte)(address_ >> 8),
        cast(ubyte)(address_ >> 16),
        cast(ubyte)(address_ >> 24)
      ];
    }
    return bytes.dup;
  }

  /// Converts an IPAddress to its standard notation.
  final override string toString() {
    if (string_ == null) {
      // inet_ntoa only works on IPv4 addresses.
      // Try to use WSAAddressToString on platforms that support IPv6 (WinXP+).
      if (family_ == AddressFamily.INET6) {
        if (supportsIPv6) {
          uint stringLength = 256;
          wchar[] string = new wchar[stringLength];

          ubyte[sockaddr_in6.sizeof] addr;
          addr[0 .. 2] = [cast(ubyte)family_, cast(ubyte)(family_ >> 8)];

          int offset = 8;
          foreach (n; numbers_)
            addr[offset++ .. offset++ + 1] = [cast(ubyte)(n >> 8), cast(ubyte)n];
          if (scopeId_ > 0)
            addr[24 .. $] = [cast(ubyte)scopeId_, cast(ubyte)(scopeId_ >> 8), cast(ubyte)(scopeId_ >> 16), cast(ubyte)(scopeId_ >> 24)];

          if (WSAAddressToString(cast(sockaddr*)addr.ptr, addr.length, null, string.ptr, stringLength) != 0)
            throw socketException();

          string_ = toUtf8(string.ptr);
        }
        else {
          // Should only be needed for Win2k without the IPv6 add-on.
          string s;

          s ~= std.string.format("%04x:", numbers_[0]);
          s ~= std.string.format("%04x:", numbers_[1]);
          s ~= std.string.format("%04x:", numbers_[2]);
          s ~= std.string.format("%04x:", numbers_[3]);
          s ~= std.string.format("%04x:", numbers_[4]);
          s ~= std.string.format("%04x:", numbers_[5]);
          s ~= std.string.format("%s.", (numbers_[6] >> 8) & 0xff);
          s ~= std.string.format("%s.", numbers_[6] & 0xff);
          s ~= std.string.format("%s.", (numbers_[7] >> 8) & 0xff);
          s ~= std.string.format("%s", numbers_[7] & 0xff);
          if (scopeId_ != 0)
            s ~= std.string.format("%%%s", scopeId_);

          string_ = s;
        }
      }
      else {
        string_ = toUtf8(inet_ntoa(*cast(in_addr*)&address_));
      }
    }
    return string_;
  }

  /// Converts an IP address string to an IPAddress instance.
  static IPAddress parse(string ipString) {
    return parse(ipString, false);
  }

  private static IPAddress parse(string ipString, bool tryParse) {
    if (ipString.indexOf(':') != -1) {
      if (supportsIPv6) {
        sockaddr_in6 addr;
        int addrLength = addr.sizeof;

        if (WSAStringToAddress(ipString.toUtf16z(), AF_INET6, null, cast(sockaddr*)&addr, addrLength) == 0)
          return new IPAddress((cast(ubyte*)&addr)[8 .. addrLength], addr.sin6_scope_id);

        if (tryParse)
          return null;
        throw socketException();
      }
      else {
        // Should we bother to parse the string manually? Since the OS doesn't support IPv6, it seems not worth the effort.
        if (tryParse)
          return null;
        throw socketException(WSAEINVAL);
      }
    }
    else {
      uint address = inet_addr(ipString.toUtf8z());
      if (address == ~0) {
        if (tryParse)
          return null;
        throw new FormatException;
      }
      return new IPAddress(address);
    }
  }

  /// Determines whether a string is a valid IP _address.
  static bool tryParse(string ipString, out IPAddress address) {
    return ((address = parse(ipString, true)) !is null);
  }

  bool equals(Object obj) {
    if (auto other = cast(IPAddress)obj) {
      if (other.family_ != family_)
        return false;
      if (family_ == AddressFamily.INET6) {
        for (int i = 0; i < numbers_.length; i++) {
          if (other.numbers_[i] != numbers_[i])
            return false;
        }
        if (other.scopeId_ != scopeId_)
          return false;
        return true;
      }
      return other.address_ == address_;
    }
    return false;
  }

  override typeof(super.opEquals(Object)) opEquals(Object obj) {
    return this.equals(obj);
  }

  /// Convers a number from _host byte order to network byte order.
  static short hostToNetworkOrder(short host) {
    version(BigEndian) {
      return host;
    }
    else {
      return ((cast(int)host & 0xff) << 8) | ((host >> 8) & 0xff);
    }
  }

  /// ditto
  static int hostToNetworkOrder(int host) {
    version(BigEndian) {
      return host;
    }
    else {
      return (cast(int)hostToNetworkOrder(cast(short)(host & 0xffff)) << 16)
        | (cast(int)hostToNetworkOrder(cast(short)(host >> 16)) & 0xffff);
    }
  }

  /// Converts a number from _network byte order to host byte order.
  static short networkToHostOrder(short network) {
    return hostToNetworkOrder(network);
  }

  /// ditto
  static int networkToHostOrder(int network) {
    return hostToNetworkOrder(network);
  }

  final @property uint address() {
    return address_;
  }

  /// Gets the address family.
  final @property AddressFamily addressFamily() {
    return family_;
  }

  /// Gets or sets the IPv6 scope identifier.
  final @property void scopeId(uint value) {
    if (family_ == AddressFamily.INET)
      throw socketException(WSAEOPNOTSUPP);

    if (scopeId_ != value)
      scopeId_ = value;
  }
  /// ditto
  final @property uint scopeId() {
    if (family_ == AddressFamily.INET)
      throw socketException(WSAEOPNOTSUPP);

    return scopeId_;
  }

  /// Indicates whether the specified IP _address is the loopback _address.
  final static bool isLoopback(IPAddress address) {
    if (address.family_ == AddressFamily.INET6)
      return address.equals(ipv6Loopback);
    return (address.address_ & 0x0000007F) == (loopback.address_ & 0x0000007F);
  }

  /// Indicates whether the address is an IPv6 multicase global address.
  final @property bool isIPv6Multicast() {
    return (family_ == AddressFamily.INET6 && (numbers_[0] & 0xFF00) == 0xFF00);
  }

  /// Indicates whether the address is an IPv6 link local address.
  final @property bool isIPv6LinkLocal() {
    return (family_ == AddressFamily.INET6 && (numbers_[0] & 0xFFC0) == 0xFE80);
  }

  /// Indicates whether the address is an IPv6 site local address.
  final @property bool isIPv6SiteLocal() {
    return (family_ == AddressFamily.INET6 && (numbers_[0] & 0xFFC0) == 0xFEC0);
  }

}

class IPEndPoint {

  const ushort minPort = 0x00000000;
  const ushort maxPort = 0x0000FFFF;
  const ushort anyPort = minPort;

  static IPEndPoint any;
  static IPEndPoint ipv6Any;

  static this() {
    any = new IPEndPoint(IPAddress.any, 0);
    ipv6Any = new IPEndPoint(IPAddress.ipv6Any, 0);
  }

  static ~this() {
    any = null;
    ipv6Any = null;
  }

  private IPAddress address_;
  private ushort port_;

  this(IPAddress address, ushort port) {
    if (address is null)
      throw new ArgumentNullException("address");

    address_ = address;
    port_ = port;
  }

  this(uint address, ushort port) {
    address_ = new IPAddress(address);
    port_ = port;
  }

  SocketAddress serialize() {
    if (address_.addressFamily == AddressFamily.INET6) {
      auto saddr = new SocketAddress(AddressFamily.INET6, sockaddr_in6.sizeof);

      ushort port = this.port;
      saddr.buffer_[2 .. 4] = [cast(ubyte)(port >> 8), cast(ubyte)port];

      uint scopeId = address_.scopeId;
      saddr.buffer_[24 .. $] = [cast(ubyte)scopeId, cast(ubyte)(scopeId >> 8), cast(ubyte)(scopeId >> 16), cast(ubyte)(scopeId >> 24)];

      ubyte[] addrBytes = address_.getAddress();
      saddr.buffer_[8 .. 8 + addrBytes.length] = addrBytes;

      return saddr;
    }
    else {
      auto saddr = new SocketAddress(address_.addressFamily, sockaddr.sizeof);

      ushort port = this.port;
      saddr.buffer_[2 .. 4] = [cast(ubyte)(port >> 8), cast(ubyte)port];

      uint a = address_.address_;
      saddr.buffer_[4 .. 8] = [cast(ubyte)a, cast(ubyte)(a >> 8), cast(ubyte)(a >> 16), cast(ubyte)(a >> 24)];

      return saddr;
    }
  }

  override string toString() {
    return address.toString() ~ ":" ~ .toString(port);
  }

  final @property void address(IPAddress value) {
    address_ = value;
  }
  final @property IPAddress address() {
    return address_;
  }

  final @property AddressFamily addressFamily() {
    return address_.addressFamily;
  }

  final @property void port(ushort value) {
    port_ = value;
  }
  final @property ushort port() {
    return port_;
  }

}

class PingException : Exception {

  this(string message) {
    super(message);
  }

}

/// Reports the status of sending an ICMP echo message to a computer.
enum IPStatus {
  Unknown                         = -1,                       ///
  Success                         = IP_SUCCESS,               ///
  DestinationNetworkUnreachable   = IP_DEST_NET_UNREACHABLE,  ///
  DestinationHostUnreachable      = IP_DEST_HOST_UNREACHABLE, ///
  DestinationProtocolUnreachable  = IP_DEST_PROT_UNREACHABLE, ///
  DestinationPortUnreachable      = IP_DEST_PORT_UNREACHABLE, ///
  NoResources                     = IP_NO_RESOURCES,          ///
  BadOption                       = IP_BAD_OPTION,            ///
  HardwareError                   = IP_HW_ERROR,              ///
  PacketTooBig                    = IP_PACKET_TOO_BIG,        ///
  TimedOut                        = IP_REQ_TIMED_OUT,         ///
  BadRoute                        = IP_BAD_ROUTE,             ///
  TtlExpired                      = IP_TTL_EXPIRED_TRANSIT,   ///
  TtlReassemblyTimeExceeded       = IP_TTL_EXPIRED_REASSEM,   ///
  ParameterProblem                = IP_PARAM_PROBLEM,         ///
  SourceQuench                    = IP_SOURCE_QUENCH,         ///
  BadDestination                  = IP_BAD_DESTINATION        ///
}

/// Provides information about the status and data resulting from a Ping.send operation.
class PingReply {

  private IPStatus status_;
  private ubyte[] buffer_;
  private IPAddress address_;
  private uint roundTripTime_;

  private this(IPStatus status) {
    status_ = status;
  }

  private this(ICMP_ECHO_REPLY* reply) {
    address_ = new IPAddress(reply.address);
    status_ = cast(IPStatus)reply.status;
    if (status_ == IPStatus.Success) {
      roundTripTime_ = reply.roundTripTime;
      buffer_.length = reply.dataSize;
      memcpy(buffer_.ptr, reply.data, buffer_.length);
    }
  }

  private this(ICMPV6_ECHO_REPLY* reply, void* data, uint dataSize) {
    address_ = new IPAddress(reply.address.sin6_addr, reply.address.sin6_scope_id);
    status_ = cast(IPStatus)reply.status;
    if (status_ == IPStatus.Success) {
      roundTripTime_ = reply.roundTripTime;
      buffer_.length = dataSize;
      memcpy(buffer_.ptr, data + 36, dataSize);
    }
  }

  final @property IPStatus status() {
    return status_;
  }

  final @property IPAddress address() {
    return address_;
  }

  final @property uint roundTripTime() {
    return roundTripTime_;
  }

  final @property ubyte[] buffer() {
    return buffer_;
  }

}

/**
 * Determines whether a remote computer is accessible over the network.
 * Examples:
 * ---
 * void pingServer(string server) {
 *   scope ping = new Ping;
 *   auto reply = ping.send(server);
 *   if (reply.status == IPStatus.Success) {
 *     writefln("Address: %s", reply.address);
 *     writefln("Roundtrip time: %s", reply.roundTripTime);
 *   }
 * }
 * ---
 */
class Ping : IDisposable {

  private const uint DEFAULT_TIMEOUT = 5000;
  private const uint DEFAULT_BUFFER_SIZE = 32;

  private Handle pingHandleV4_;
  private Handle pingHandleV6_;
  private bool ipv6_;
  private void* requestBuffer_;
  private void* replyBuffer_;

  private ubyte[] defaultBuffer_;

  ~this() {
    dispose();
  }

  void dispose() {
    if (pingHandleV4_ != Handle.init) {
      if (isWin2k)
        IcmpCloseHandleWin2k(pingHandleV4_);
      else
        IcmpCloseHandle(pingHandleV4_);
      pingHandleV4_ = Handle.init;
    }
    if (pingHandleV6_ != Handle.init) {
      IcmpCloseHandle(pingHandleV6_);
      pingHandleV6_ = Handle.init;
    }

    if (replyBuffer_ != null) {
      LocalFree(replyBuffer_);
      replyBuffer_ = null;
    }
  }

  /// Attempts to _send an ICMP echo message to a remote computer and receive an ICMP echo reply message.
  PingReply send(string hostNameOrAddress, uint timeout = DEFAULT_TIMEOUT) {
    IPAddress address = IPHost.get(hostNameOrAddress).addressList[0];
    return send(address, timeout);
  }

  /// ditto
  PingReply send(string hostNameOrAddress, uint timeout, ubyte[] buffer) {
    IPAddress address = IPHost.get(hostNameOrAddress).addressList[0];
    return send(address, timeout, buffer);
  }

  /// ditto
  PingReply send(IPAddress address, uint timeout = DEFAULT_TIMEOUT) {
    return send(address, timeout, defaultBuffer);
  }

  /// ditto
  PingReply send(IPAddress address, uint timeout, ubyte[] buffer) {
    if (address is null)
      throw new ArgumentNullException("address");

    ipv6_ = (address.addressFamily == AddressFamily.INET6);

    if (!ipv6_ && pingHandleV4_ == Handle.init) {
      if (isWin2k)
        pingHandleV4_ = IcmpCreateFileWin2k();
      else
        pingHandleV4_ = IcmpCreateFile();
    }
    else if (ipv6_ && pingHandleV6_ == Handle.init) {
      pingHandleV6_ = Icmp6CreateFile();
    }

    IP_OPTION_INFORMATION optionInfo;
    optionInfo.ttl = 128;

    requestBuffer_ = cast(void*)LocalAlloc(LMEM_FIXED, buffer.length);
    memcpy(requestBuffer_, buffer.ptr, buffer.length);
    scope(exit) LocalFree(requestBuffer_);

    uint replyBufferSize = ICMPV6_ECHO_REPLY.sizeof + buffer.length + 8;
    if (replyBuffer_ == null)
      replyBuffer_ = cast(void*)LocalAlloc(LMEM_FIXED, replyBufferSize);

    uint error;
    if (!ipv6_) {
      if (isWin2k)
        error = IcmpSendEcho2Win2k(pingHandleV4_, Handle.init, null, null, address.address_, requestBuffer_, cast(ushort)buffer.length, &optionInfo, replyBuffer_, replyBufferSize, timeout);
      else
        error = IcmpSendEcho2(pingHandleV4_, Handle.init, null, null, address.address_, requestBuffer_, cast(ushort)buffer.length, &optionInfo, replyBuffer_, replyBufferSize, timeout);
    }
    else {
      ubyte[sockaddr_in6.sizeof] sourceAddr;
      ubyte[sockaddr_in6.sizeof] remoteAddr;
      remoteAddr[0 .. 2] = [
        cast(ubyte)address.family_,
        cast(ubyte)(address.family_ >> 8)
      ];

      int offset = 8;
      foreach (n; address.numbers_) {
        remoteAddr[offset++ .. offset++ + 1] = [
          cast(ubyte)(n >> 8),
          cast(ubyte)n
        ];
      }
      if (address.scopeId_ > 0) {
        remoteAddr[24 .. $] = [
          cast(ubyte)address.scopeId_,
          cast(ubyte)(address.scopeId_ >> 8),
          cast(ubyte)(address.scopeId_ >> 16),
          cast(ubyte)(address.scopeId_ >> 24)
        ];
      }
      ubyte[] addrBytes = address.getAddress();
      remoteAddr[8 .. 8 + addrBytes.length] = addrBytes;
      error = Icmp6SendEcho2(pingHandleV6_, Handle.init, null, null, sourceAddr.ptr, remoteAddr.ptr, requestBuffer_, cast(ushort)buffer.length, &optionInfo, replyBuffer_, replyBufferSize, timeout);
    }

    if (error == 0) {
      error = GetLastError();
      if (error != 0)
        return new PingReply(cast(IPStatus)error);
    }

    if (ipv6_)
      return new PingReply(cast(ICMPV6_ECHO_REPLY*)replyBuffer_, replyBuffer_, buffer.length);
    return new PingReply(cast(ICMP_ECHO_REPLY*)replyBuffer_);
  }

  private @property ubyte[] defaultBuffer() {
    if (defaultBuffer_ == null) {
      defaultBuffer_.length = DEFAULT_BUFFER_SIZE;
      foreach (i, ref b; defaultBuffer_)
        b = cast(ubyte)('a' + i % 23);
    }
    return defaultBuffer_;
  }

}

/// Pings the specified server.
bool ping(string hostNameOrAddress, uint timeout = Ping.DEFAULT_TIMEOUT) {
  scope sender = new Ping;
  return (sender.send(hostNameOrAddress, timeout).status == IPStatus.Success);
}

/**
 * Copyright: (c) 2008 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.net.core;

private import juno.base.string,
  juno.locale.convert;

debug private import std.stdio : writefln;

enum UriPartial {
  Scheme,
  Authority,
  Path,
  Query
}

class Uri {

  private struct UriScheme {
    string schemeName;
    int defaultPort;
  }

  private const string URI_SCHEME_HTTP = "http";
  private const string URI_SCHEME_HTTPS = "https";
  private const string URI_SCHEME_FTP = "ftp";
  private const string URI_SCHEME_FILE = "file";
  private const string URI_SCHEME_NEWS = "news";
  private const string URI_SCHEME_MAILTO = "mailto";

  private static UriScheme httpScheme = { URI_SCHEME_HTTP, 80 };
  private static UriScheme httpsScheme = { URI_SCHEME_HTTPS, 443 };
  private static UriScheme ftpScheme = { URI_SCHEME_FTP, 21 };
  private static UriScheme fileScheme = { URI_SCHEME_FILE, -1 };
  private static UriScheme newsScheme = { URI_SCHEME_NEWS, -1 };
  private static UriScheme mailtoScheme = { URI_SCHEME_MAILTO, 25 };

  private string string_;
  private string cache_;
  private string scheme_;
  private string path_;
  private string query_;
  private string fragment_;
  private string userInfo_;
  private string host_;
  private int port_;

  this(string s) {
    string_ = s;
    port_ = -1;

    parseUri(s);
  }

  override string toString() {
    if (cache_ == null) {
      cache_ = getLeftPart(UriPartial.Path);
      if (fragment_ != null)
        cache_ ~= fragment_;
    }
    return cache_;
  }

  string getLeftPart(UriPartial part) {
    switch (part) {
      case UriPartial.Scheme:
        return scheme_ ~ "://";

      case UriPartial.Authority:
        string s = scheme_ ~ "://";
        if (userInfo_.length > 0)
          s ~= userInfo_ ~ '@';
        s ~= host_;
        if (port_ != -1 && port_ != getDefaultPort(scheme_))
          s ~= ':' ~ .toString(port_);
        return s;

      case UriPartial.Path:
        string s = scheme_ ~ "://";
        if (userInfo_.length > 0)
          s ~= userInfo_ ~ '@';
        s ~= host_;
        if (port_ != -1 && port_ != getDefaultPort(scheme_))
          s ~= ':' ~ .toString(port_);
        if (path_.length > 0)
          s ~= path_;
        return s;

      default:
    }
    return null;
  }

  final bool isAbsolute() {
    return scheme_ != null;
  }

  final string scheme() {
    return scheme_;
  }

  final string authority() {
    return isDefaultPort 
      ? host_ 
      : host_ ~ ":" ~ .toString(port_);
  }

  final string pathAndQuery() {
    return path_ ~ query_;
  }

  final string query() {
    return query_;
  }

  final string fragment() {
    return fragment_;
  }

  final string userInfo() {
    return userInfo_;
  }

  final string host() {
    return host_;
  }

  final int port() {
    return port_;
  }

  final string original() {
    return string_;
  }

  final string localPath() {
    return path_;
  }

  bool isDefaultPort() {
    return getDefaultPort(scheme_) == port_;
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
      scheme_ = s[0 .. i];
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
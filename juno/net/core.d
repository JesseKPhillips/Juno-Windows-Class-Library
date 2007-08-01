/*
 * Copyright (c) 2007 John Chapman
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

module juno.net.core;

private import juno.base.string,
  juno.base.numeric;
private static import regex = std.regexp;
private static import std.string;

/**
 * Represents a uniform resource identifier.
 */
public class Uri {

  private struct UriScheme {
    string schemeName;
    int defaultPort;
  }

  private static const string URI_SCHEME_HTTP = "http";
  private static const string URI_SCHEME_HTTPS = "https";
  private static const string URI_SCHEME_FTP = "ftp";
  private static const string URI_SCHEME_FILE = "file";
  private static const string URI_SCHEME_MAILTO = "mailto";
  private static const string URI_SCHEME_NEWS = "news";

  private static final UriScheme httpScheme = { URI_SCHEME_HTTP, 80 };
  private static final UriScheme httpsScheme = { URI_SCHEME_HTTPS, 443 };
  private static final UriScheme ftpScheme = { URI_SCHEME_FTP, 21 };
  private static final UriScheme fileScheme = { URI_SCHEME_FILE, -1 };
  private static final UriScheme mailtoScheme = { URI_SCHEME_MAILTO, 25 };
  private static final UriScheme newsScheme = { URI_SCHEME_NEWS, -1 };

  private static const string URI_REGEX = "^(([^:/?#]+):)?((//([^/?#]*))?([^?#]*)(\\?([^#]*))?)?(#(.*))?";
  private static const string AUTHORITY_REGEX = "(([^?#]*)@)?([^?#:]*)(:([0-9]*))?";

  private static final int SCHEME_GROUP_INDEX = 2;
  private static final int SCHEME_SPEC_PART_GROUP_INDEX = 3;
  private static final int AUTHORITY_GROUP_INDEX = 5;
  private static final int PATH_GROUP_INDEX = 6;
  private static final int QUERY_GROUP_INDEX = 8;
  private static final int FRAGMENT_GROUP_INDEX = 10;

  private static final int AUTHORITY_USERINFO_GROUP_INDEX = 2;
  private static final int AUTHORITY_HOST_GROUP_INDEX = 3;
  private static final int AUTHORITY_PORT_GROUP_INDEX = 5;

  private string string_;
  private string scheme_;
  private string schemeSpecPart_;
  private string authority_;
  private string path_;
  private string query_;
  private string fragment_;
  private string userInfo_;
  private string host_;
  private int port_;

  /**
   * Creates a new instance with the specified URI.
   * Params: s = A URI.
   */
  public this(string s) {
    string_ = s;
    port_ = -1;

    parseUri(s);
  }

  public override string toString() {
    return (scheme_ == null ? "" : scheme_ ~ ":")
      ~ schemeSpecPart_
      ~ (fragment_ == null ? "" : "#" ~ fragment_);
  }

  public final bool isAbsolute() {
    return scheme_ != null;
  }

  public final bool isOpaque() {
    return scheme_ != null && std.string.ifind(schemeSpecPart_, '/') == -1;
  }

  /**
   * Gets the _scheme name for this URI.
   * Returns: A string containing the _scheme for this URI.
   */
  public final string scheme() {
    return scheme_;
  }

  /**
   * Gets the DNS host name or IP address and port number for a server.
   * Returns: A string containing the _authority component of the URI.
   */
  public final string authority() {
    return authority_;
  }

  /**
   * Gets the path and query properties separated by a question mark.
   * Returns: A string containing the path and the query.
   */
  public final string pathAndQuery() {
    return (query_ == null) ? path_ : path_ ~ "?" ~ query_;
  }

  /**
   * Gets any _query information in the URI.
   * Returns: A string containing any _query information.
   */
  public final string query() {
    return query_;
  }

  /**
   * Gets any URI _fragment information.
   * Returns: A string containing the _fragment.
   */
  public final string fragment() {
    return fragment_;
  }

  /**
   * Gets the user name, password or other user-specific information associated with the URI.
   * Returns: A string containing the user information.
   */
  public final string userInfo() {
    return userInfo_;
  }

  /**
   * Gets the _host component of the URI.
   * Returns: A string containing the _host name.
   */
  public final string host() {
    return host_;
  }

  /**
   * Gets the _port number of the URI.
   * Returns: An integer containing the _port number of the URI.
   */
  public final int port() {
    return port_;
  }

  private void parseUri(string s) {
    if (auto matches = regex.search(s, URI_REGEX)) {
      scheme_ = matches.match(SCHEME_GROUP_INDEX);
      schemeSpecPart_ = matches.match(SCHEME_SPEC_PART_GROUP_INDEX);
      if (!isOpaque) {
        authority_ = matches.match(AUTHORITY_GROUP_INDEX);
        path_ = matches.match(PATH_GROUP_INDEX);
        if (path_ == null) path_ = "/";
        query_ = matches.match(QUERY_GROUP_INDEX);
      }
      fragment_ = matches.match(FRAGMENT_GROUP_INDEX);
    }

    if (authority_ != null) {
      if (auto matches = regex.search(s, AUTHORITY_REGEX)) {
        userInfo_ = matches.match(AUTHORITY_USERINFO_GROUP_INDEX);
        host_ = matches.match(AUTHORITY_HOST_GROUP_INDEX);
        if (auto portString = matches.match(AUTHORITY_PORT_GROUP_INDEX))
          port_ = .parse!(int)(portString);
        else
          port_ = getDefaultPort(scheme_);
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
    else if (scheme == mailtoScheme.schemeName)
      return mailtoScheme.defaultPort;
    else if (scheme == newsScheme.schemeName)
      return newsScheme.defaultPort;
    return -1;
  }

}
/**
 * Provides methods for sending data to and receiving data from a resource indentified by a URI.
 *
 * Copyright: (c) 2009 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.net.client;

import juno.base.core,
  juno.base.string,
  juno.base.text,
  juno.base.native,
  juno.io.path,
  juno.io.filesystem,
  juno.com.core,
  juno.net.core,
  std.stream;
static import std.c.stdlib;

import std.conv;

debug import std.stdio : writeln, writefln;

interface IBinding : IUnknown {
  mixin(uuid("79eac9c0-baf9-11ce-8c82-00aa004ba90b"));

  int Abort();
  int Suspend();
  int Resume();
  int SetPriority(int nPriority);
  int GetPriority(out int pnPriority);
  int GetBindResult(out GUID pclsidProtocol, out uint pdwResult, out wchar* pszResult, uint* pdwReserved);
}

enum : uint {
  BINDSTATUS_FINDINGRESOURCE = 1,
  BINDSTATUS_CONNECTING,
  BINDSTATUS_REDIRECTING,
  BINDSTATUS_BEGINDOWNLOADDATA,
  BINDSTATUS_DOWNLOADINGDATA,
  BINDSTATUS_ENDDOWNLOADDATA,
  BINDSTATUS_BEGINDOWNLOADCOMPONENTS,
  BINDSTATUS_INSTALLINGCOMPONENTS,
  BINDSTATUS_ENDDOWNLOADCOMPONENTS,
  BINDSTATUS_USINGCACHEDCOPY,
  BINDSTATUS_SENDINGREQUEST,
  BINDSTATUS_CLASSIDAVAILABLE,
  BINDSTATUS_MIMETYPEAVAILABLE,
  BINDSTATUS_CACHEFILENAMEAVAILABLE,
  BINDSTATUS_BEGINSYNCOPERATION,
  BINDSTATUS_ENDSYNCOPERATION,
  BINDSTATUS_BEGINUPLOADDATA,
  BINDSTATUS_UPLOADINGDATA,
  BINDSTATUS_ENDUPLOADDATA,
  BINDSTATUS_PROTOCOLCLASSID,
  BINDSTATUS_ENCODING,
  BINDSTATUS_VERIFIEDMIMETYPEAVAILABLE,
  BINDSTATUS_CLASSINSTALLLOCATION,
  BINDSTATUS_DECODING,
  BINDSTATUS_LOADINGMIMEHANDLER,
  BINDSTATUS_CONTENTDISPOSITIONATTACH,
  BINDSTATUS_FILTERREPORTMIMETYPE,
  BINDSTATUS_CLSIDCANINSTANTIATE,
  BINDSTATUS_IUNKNOWNAVAILABLE,
  BINDSTATUS_DIRECTBIND,
  BINDSTATUS_RAWMIMETYPE,
  BINDSTATUS_PROXYDETECTING,
  BINDSTATUS_ACCEPTRANGES,
  BINDSTATUS_COOKIE_SENT,
  BINDSTATUS_COOKIE_SUPPRESSED,
  BINDSTATUS_COOKIE_STATE_UNKNOWN,
  BINDSTATUS_COOKIE_STATE_ACCEPT,
}

enum : uint {
  BINDVERB_GET    = 0x0,
  BINDVERB_POST   = 0x1,
  BINDVERB_PUT    = 0x2,
  BINDVERB_CUSTOM = 0x3
}

enum : uint {
  BINDF_ASYNCHRONOUS           = 0x1,
  BINDF_ASYNCSTORAGE           = 0x2,
  BINDF_NOPROGRESSIVERENDERING = 0x4,
  BINDF_OFFLINEOPERATION       = 0x8,
  BINDF_GETNEWESTVERSION       = 0x10,
  BINDF_NEEDFILE               = 0x40,
  BINDF_NOWRITECACHE           = 0x20,
  BINDF_PULLDATA               = 0x80
}

struct BINDINFO {
  uint cbSize = BINDINFO.sizeof;
  wchar* szExtraInfo;
  STGMEDIUM stgmedData;
  uint grfBindInfoF;
  uint dwBindVerb;
  wchar* szCustomVerb;
  uint cbstgmedData;
  uint dwOptions;
  uint dwOptionsFlags;
  uint dwCodePage;
  SECURITY_ATTRIBUTES securityAttributes;
  GUID iid;
  IUnknown pUnk;
  uint dwReserved;
}

extern(Windows)
interface IBindStatusCallback : IUnknown {
  mixin(uuid("79eac9c1-baf9-11ce-8c82-00aa004ba90b"));

  int OnStartBinding(uint dwReserved, IBinding pib);
  int GetPriority(out int pnPriority);
  int OnLowResource(uint reserved);
  int OnProgress(uint ulProgress, uint ulProgressMax, uint ulStatusCode, in wchar* szStatusText);
  int OnStopBinding(int hresult, in wchar* szError);
  int GetBindInfo(out uint grfBINDF, BINDINFO* pbindinfo);
  int OnDataAvailable(uint grfBSCF, uint dwSize, FORMATETC* pformatetc, STGMEDIUM* pstgmed);
  int OnObjectAvailable(ref GUID riid, IUnknown punk);
}

interface IHttpNegotiate : IUnknown {
  mixin(uuid("79eac9d2-baf9-11ce-8c82-00aa004ba90b"));

  int BeginningTransaction(in wchar* szURL, in wchar* szHeaders, uint dwReserved, wchar** pszAdditionalHeaders);
  int OnResponse(uint dwResponseCode, in wchar* szResponseHeaders, in wchar* szRequestHeaders, wchar** pszAdditionalRequestHeaders);
}

extern(Windows)
alias DllImport!("urlmon.dll", "URLOpenStream",
  int function(IUnknown caller, in wchar* szURL, uint, IBindStatusCallback lpfnCallback)) URLOpenStream;

enum : uint {        
  URL_MK_LEGACY          = 0,
  URL_MK_UNIFORM         = 1,
  URL_MK_NO_CANONICALIZE = 2
}

extern(Windows)
alias DllImport!("urlmon.dll", "CreateURLMonikerEx",
  int function(IMoniker pMkCtx, in wchar* szURL, IMoniker* ppmk, uint dwFlags)) CreateURLMonikerEx;

extern(Windows)
alias DllImport!("urlmon.dll", "CreateAsyncBindCtx",
  int function(uint reserved, IBindStatusCallback pBSCb, IEnumFORMATETC pEFetc, IBindCtx* ppBC)) CreateAsyncBindCtx;

extern(Windows)
alias DllImport!("urlmon.dll", "RegisterBindStatusCallback",
  int function(IBindCtx pbc, IBindStatusCallback pbsc, IBindStatusCallback* ppbscPrevious, uint dwReserved)) RegisterBindStatusCallback;

enum : uint {
  INTERNET_OPEN_TYPE_PRECONFIG                   = 0,
  INTERNET_OPEN_TYPE_DIRECT                      = 1,
  INTERNET_OPEN_TYPE_PROXY                       = 3,
  INTERNET_OPEN_TYPE_PRECONFIG_WITH_NO_AUTOPROXY = 4
}

extern(Windows)
alias DllImport!("wininet.dll", "InternetOpenW",
  Handle function(in wchar* lpszAgent, uint dwAccessType, in wchar* lpszProxy, in wchar* lpszProxyBypass, uint dwFlags)) InternetOpen;

extern(Windows)
alias DllImport!("wininet.dll", "InternetCloseHandle",
  int function(Handle hInternet)) InternetCloseHandle;

// dwInternetStatus
enum : uint {
  INTERNET_STATUS_RESOLVING_NAME        = 10,
  INTERNET_STATUS_NAME_RESOLVED         = 11,
  INTERNET_STATUS_CONNECTING_TO_SERVER  = 20,
  INTERNET_STATUS_CONNECTED_TO_SERVER   = 21,
  INTERNET_STATUS_SENDING_REQUEST       = 30,
  INTERNET_STATUS_REQUEST_SENT          = 31,
  INTERNET_STATUS_RECEIVING_RESPONSE    = 40,
  INTERNET_STATUS_RESPONSE_RECEIVED     = 41,
  INTERNET_STATUS_CTL_RESPONSE_RECEIVED = 42,
  INTERNET_STATUS_PREFETCH              = 43,
  INTERNET_STATUS_CLOSING_CONNECTION    = 50,
  INTERNET_STATUS_CONNECTION_CLOSED     = 51,
  INTERNET_STATUS_HANDLE_CREATED        = 60,
  INTERNET_STATUS_HANDLE_CLOSING        = 70,
  INTERNET_STATUS_DETECTING_PROXY       = 80,
  INTERNET_STATUS_REQUEST_COMPLETE      = 100,
  INTERNET_STATUS_REDIRECT              = 110,
  INTERNET_STATUS_INTERMEDIATE_RESPONSE = 120,
  INTERNET_STATUS_USER_INPUT_REQUIRED   = 140,
  INTERNET_STATUS_STATE_CHANGE          = 200,
  INTERNET_STATUS_COOKIE_SENT           = 320,
  INTERNET_STATUS_COOKIE_RECEIVED       = 321,
  INTERNET_STATUS_PRIVACY_IMPACTED      = 324,
  INTERNET_STATUS_P3P_HEADER            = 325,
  INTERNET_STATUS_P3P_POLICYREF         = 326,
  INTERNET_STATUS_COOKIE_HISTORY        = 327
}

extern(Windows)
alias void function(Handle hInternet, uint dwContext, uint dwInternetStatus, void* lpvStatusInformation, uint dwStatusInformationLength) INTERNET_STATUS_CALLBACK;

extern(Windows)
alias DllImport!("wininet.dll", "InternetSetStatusCallbackW", 
  INTERNET_STATUS_CALLBACK function(Handle hInternet, INTERNET_STATUS_CALLBACK lpfnStatusCallback)) InternetSetStatusCallback;

struct INTERNET_ASYNC_RESULT {
  uint dwResult;
  uint dwError;
}

enum : uint {
  INTERNET_SERVICE_FTP    = 1,
  INTERNET_SERVICE_GOPHER = 2,
  INTERNET_SERVICE_HTTP   = 3
}

enum : uint {
  INTERNET_FLAG_ASYNC           = 0x10000000,
  INTERNET_FLAG_RELOAD          = 0x80000000,
  INTERNET_FLAG_PASSIVE         = 0x08000000,
  INTERNET_FLAG_NO_CACHE_WRITE  = 0x04000000,
  INTERNET_FLAG_DONT_CACHE      = INTERNET_FLAG_NO_CACHE_WRITE,
  INTERNET_FLAG_MAKE_PERSISTENT = 0x02000000,
  INTERNET_FLAG_FROM_CACHE      = 0x01000000,
  INTERNET_FLAG_OFFLINE         = INTERNET_FLAG_FROM_CACHE
}

extern(Windows)
alias DllImport!("wininet.dll", "InternetConnectW",
  Handle function(Handle hInternet, in wchar* lpszServerName, ushort nServerPort, in wchar* lpszUserName, in wchar* lpszPassword, uint dwService, uint dwFlags, uint dwContext)) InternetConnect;

extern(Windows)
alias DllImport!("wininet.dll", "InternetOpenUrlW",
  Handle function(Handle hInternet, in wchar* lpszUrl, in wchar* lpszHeaders, uint dwHeadersLength, uint dwFlags, uint dwContext)) InternetOpenUrl;

const wchar* HTTP_VERSION = "HTTP/1.0";

extern(Windows)
alias DllImport!("wininet.dll", "HttpOpenRequestW",
  Handle function(Handle hConnect, in wchar* lpszVerb, in wchar* lpszObjectName, in wchar* lpszVersion, in wchar* lpszReferrer, in wchar** lplpszAcceptTypes, uint dwFlags, uint dwContext)) HttpOpenRequest;

extern(Windows)
alias DllImport!("wininet.dll", "HttpSendRequestW",
  int function(Handle hRequest, in wchar* lpszHeaders, uint dwHeadersLength, in void* lpOptional, uint dwOptionalLength)) HttpSendRequest;

struct INTERNET_BUFFERSW {
  uint dwStructSize = INTERNET_BUFFERSW.sizeof;
  INTERNET_BUFFERSW* Next;
  const(wchar)* lpcszHeader;
  uint dwHeadersLength;
  uint dwHeadersTotal;
  void* lpvBuffer;
  uint dwBufferLength;
  uint dwBufferTotal;
  uint dwOffsetLow;
  uint dwOffsetHigh;
}
alias INTERNET_BUFFERSW INTERNET_BUFFERS;

enum : uint {
  HSR_ASYNC = 0x00000001
}

extern(Windows)
alias DllImport!("wininet.dll", "HttpSendRequestExW",
  int function(Handle hRequest, INTERNET_BUFFERSW* lpBuffersIn, INTERNET_BUFFERSW* lpBuffersOut, uint dwFlags, uint dwContext)) HttpSendRequestEx;

extern(Windows)
alias DllImport!("wininet.dll", "HttpEndRequestW",
  int function(Handle hRequest, INTERNET_BUFFERSW* lpBuffersOut, uint dwFlags, uint dwContext)) HttpEndRequest;

enum : uint {
  HTTP_QUERY_MIME_VERSION                = 0,
  HTTP_QUERY_CONTENT_TYPE                = 1,
  HTTP_QUERY_CONTENT_TRANSFER_ENCODING   = 2,
  HTTP_QUERY_CONTENT_ID                  = 3,
  HTTP_QUERY_CONTENT_DESCRIPTION         = 4,
  HTTP_QUERY_CONTENT_LENGTH              = 5,
  HTTP_QUERY_CONTENT_LANGUAGE            = 6,
  HTTP_QUERY_ALLOW                       = 7,
  HTTP_QUERY_PUBLIC                      = 8,
  HTTP_QUERY_DATE                        = 9,
  HTTP_QUERY_EXPIRES                     = 10,
  HTTP_QUERY_LAST_MODIFIED               = 11,
  HTTP_QUERY_MESSAGE_ID                  = 12,
  HTTP_QUERY_URI                         = 13,
  HTTP_QUERY_DERIVED_FROM                = 14,
  HTTP_QUERY_COST                        = 15,
  HTTP_QUERY_LINK                        = 16,
  HTTP_QUERY_PRAGMA                      = 17,
  HTTP_QUERY_VERSION                     = 18,
  HTTP_QUERY_STATUS_CODE                 = 19,
  HTTP_QUERY_STATUS_TEXT                 = 20,
  HTTP_QUERY_RAW_HEADERS                 = 21,
  HTTP_QUERY_RAW_HEADERS_CRLF            = 22,
  HTTP_QUERY_CONNECTION                  = 23,
  HTTP_QUERY_ACCEPT                      = 24,
  HTTP_QUERY_ACCEPT_CHARSET              = 25,
  HTTP_QUERY_ACCEPT_ENCODING             = 26,
  HTTP_QUERY_ACCEPT_LANGUAGE             = 27,
  HTTP_QUERY_AUTHORIZATION               = 28,
  HTTP_QUERY_CONTENT_ENCODING            = 29,
  HTTP_QUERY_FORWARDED                   = 30,
  HTTP_QUERY_FROM                        = 31,
  HTTP_QUERY_IF_MODIFIED_SINCE           = 32,
  HTTP_QUERY_LOCATION                    = 33,
  HTTP_QUERY_ORIG_URI                    = 34,
  HTTP_QUERY_REFERER                     = 35,
  HTTP_QUERY_RETRY_AFTER                 = 36,
  HTTP_QUERY_SERVER                      = 37,
  HTTP_QUERY_TITLE                       = 38,
  HTTP_QUERY_USER_AGENT                  = 39,
  HTTP_QUERY_WWW_AUTHENTICATE            = 40,
  HTTP_QUERY_PROXY_AUTHENTICATE          = 41,
  HTTP_QUERY_ACCEPT_RANGES               = 42,
  HTTP_QUERY_SET_COOKIE                  = 43,
  HTTP_QUERY_COOKIE                      = 44,
  HTTP_QUERY_REQUEST_METHOD              = 45,
  HTTP_QUERY_REFRESH                     = 46,
  HTTP_QUERY_CONTENT_DISPOSITION         = 47,
  HTTP_QUERY_AGE                         = 48,
  HTTP_QUERY_CACHE_CONTROL               = 49,
  HTTP_QUERY_CONTENT_BASE                = 50,
  HTTP_QUERY_CONTENT_LOCATION            = 51,
  HTTP_QUERY_CONTENT_MD5                 = 52,
  HTTP_QUERY_CONTENT_RANGE               = 53,
  HTTP_QUERY_ETAG                        = 54,
  HTTP_QUERY_HOST                        = 55,
  HTTP_QUERY_IF_MATCH                    = 56,
  HTTP_QUERY_IF_NONE_MATCH               = 57,
  HTTP_QUERY_IF_RANGE                    = 58,
  HTTP_QUERY_IF_UNMODIFIED_SINCE         = 59,
  HTTP_QUERY_MAX_FORWARDS                = 60,
  HTTP_QUERY_PROXY_AUTHORIZATION         = 61,
  HTTP_QUERY_RANGE                       = 62,
  HTTP_QUERY_TRANSFER_ENCODING           = 63,
  HTTP_QUERY_UPGRADE                     = 64,
  HTTP_QUERY_VARY                        = 65,
  HTTP_QUERY_VIA                         = 66,
  HTTP_QUERY_WARNING                     = 67,
  HTTP_QUERY_EXPECT                      = 68,
  HTTP_QUERY_PROXY_CONNECTION            = 69,
  HTTP_QUERY_UNLESS_MODIFIED_SINCE       = 70,
  HTTP_QUERY_ECHO_REQUEST                = 71,
  HTTP_QUERY_ECHO_REPLY                  = 72,
  HTTP_QUERY_ECHO_HEADERS                = 73,
  HTTP_QUERY_ECHO_HEADERS_CRLF           = 74,
  HTTP_QUERY_PROXY_SUPPORT               = 75,
  HTTP_QUERY_AUTHENTICATION_INFO         = 76,
  HTTP_QUERY_PASSPORT_URLS               = 77,
  HTTP_QUERY_PASSPORT_CONFIG             = 78
}

enum : uint {
  HTTP_QUERY_FLAG_COALESCE        = 0x10000000,
  HTTP_QUERY_FLAG_NUMBER          = 0x20000000,
  HTTP_QUERY_FLAG_SYSTEMTIME      = 0x40000000,
  HTTP_QUERY_FLAG_REQUEST_HEADERS = 0x80000000
}

enum : uint {
  HTTP_STATUS_CONTINUE           = 100,
  HTTP_STATUS_SWITCH_PROTOCOLS   = 101,
  HTTP_STATUS_OK                 = 200,
  HTTP_STATUS_CREATED            = 201,
  HTTP_STATUS_ACCEPTED           = 202,
  HTTP_STATUS_PARTIAL            = 203,
  HTTP_STATUS_NO_CONTENT         = 204,
  HTTP_STATUS_RESET_CONTENT      = 205,
  HTTP_STATUS_PARTIAL_CONTENT    = 206,
  HTTP_STATUS_AMBIGUOUS          = 300,
  HTTP_STATUS_MOVED              = 301,
  HTTP_STATUS_REDIRECT           = 302,
  HTTP_STATUS_REDIRECT_METHOD    = 303,
  HTTP_STATUS_NOT_MODIFIED       = 304,
  HTTP_STATUS_USE_PROXY          = 305,
  HTTP_STATUS_REDIRECT_KEEP_VERB = 307,
  HTTP_STATUS_BAD_REQUEST        = 400,
  HTTP_STATUS_DENIED             = 401,
  HTTP_STATUS_PAYMENT_REQ        = 402,
  HTTP_STATUS_FORBIDDEN          = 403,
  HTTP_STATUS_NOT_FOUND          = 404,
  HTTP_STATUS_BAD_METHOD         = 405,
  HTTP_STATUS_NONE_ACCEPTABLE    = 406,
  HTTP_STATUS_PROXY_AUTH_REQ     = 407,
  HTTP_STATUS_REQUEST_TIMEOUT    = 408,
  HTTP_STATUS_CONFLICT           = 409,
  HTTP_STATUS_GONE               = 410,
  HTTP_STATUS_LENGTH_REQUIRED    = 411,
  HTTP_STATUS_PRECOND_FAILED     = 412,
  HTTP_STATUS_REQUEST_TOO_LARGE  = 413,
  HTTP_STATUS_URI_TOO_LONG       = 414,
  HTTP_STATUS_UNSUPPORTED_MEDIA  = 415,
  HTTP_STATUS_RETRY_WITH         = 449,
  HTTP_STATUS_SERVER_ERROR       = 500,
  HTTP_STATUS_NOT_SUPPORTED      = 501,
  HTTP_STATUS_BAD_GATEWAY        = 502,
  HTTP_STATUS_SERVICE_UNAVAIL    = 503,
  HTTP_STATUS_GATEWAY_TIMEOUT    = 504,
  HTTP_STATUS_VERSION_NOT_SUP    = 505
}

extern(Windows)
alias DllImport!("wininet.dll", "HttpQueryInfoW",
  int function(Handle hRequest, uint dwInfoLevel, void* lpBuffer, uint* lpdwBufferLength, uint* lpdwIndex)) HttpQueryInfo;

enum : uint {
  FTP_TRANSFER_TYPE_UNKNOWN = 0x00000000,
  FTP_TRANSFER_TYPE_ASCII   = 0x00000001,
  FTP_TRANSFER_TYPE_BINARY  = 0x00000002
}

enum : ushort {
  INTERNET_DEFAULT_FTP_PORT = 21
}

extern(Windows)
alias DllImport!("wininet.dll", "FtpPutFileW",
  int function(Handle hConnect, in wchar* lpszLocalFile, in wchar* lpszNewRemoteFile, uint dwFlags, uint dwContext)) FtpPutFile;

extern(Windows)
alias DllImport!("wininet.dll", "FtpOpenFileW",
  Handle function(Handle hConnect, in wchar* lpszFileName, uint dwAccess, uint dwFlags, uint dwContext)) FtpOpenFile;

extern(Windows)
alias DllImport!("wininet.dll", "InternetQueryDataAvailable",
  int function(Handle hFile, uint* lpdwNumberOfBytesAvailable, uint dwFlags, uint dwContext)) InternetQueryDataAvailable;

extern(Windows)
alias DllImport!("wininet.dll", "InternetReadFile",
  int function(Handle hFile, void* lpBuffer, uint dwNumberOfBytesToRead, uint* lpdwNumberOfBytesRead)) InternetReadFile;

extern(Windows)
alias DllImport!("wininet.dll", "InternetWriteFile",
  int function(Handle hFile, in void* lpBuffer, uint dwNumberOfBytesToWrite, uint* lpdwNumberOfBytesWritten)) InternetWriteFile;

enum : uint {
  IRF_ASYNC       = 0x00000001,
  IRF_SYNC        = 0x00000004,
  IRF_USE_CONTEXT = 0x00000008,
  IRF_NO_WAIT     = 0x00000008
}

extern(Windows)
alias DllImport!("wininet.dll", "InternetReadFileExW",
  int function(Handle hFile, INTERNET_BUFFERSW* lpBuffersOut, uint dwFlags, uint dwContext)) InternetReadFileEx;

/// <code class="d_code">void delegate(int percent, long bytesReceived, long bytesToReceive, ref bool abort)</code><br>
alias void delegate(int percent, long bytesReceived, long bytesToReceive, out bool abort) DownloadProgressCallback;

/// <code class="d_code">void delegate(ubyte[] result)</code><br>
alias void delegate(ubyte[] result) DownloadDataCompletedCallback;

/// <code class="d_code">void delegate(string result)</code><br>
alias void delegate(string result) DownloadStringCompletedCallback;

/// <code class="d_code">void delegate()</code><br>
alias void delegate() DownloadCompletedCallback;

private abstract class BindStatusCallback : Implements!(IBindStatusCallback) {
  int OnStartBinding(uint dwReserved, IBinding pib) { return S_OK; }
  int GetPriority(out int pnPriority) { return E_NOTIMPL; }
  int OnLowResource(uint reserved) { return E_NOTIMPL; }
  int OnProgress(uint ulProgress, uint ulProgressMax, uint ulStatusCode, in wchar* szStatusText) { return E_NOTIMPL; }
  int OnStopBinding(int hresult, in wchar* szError) { return S_OK; }
  int GetBindInfo(out uint grfBINDF, BINDINFO* pbindinfo) { return E_NOTIMPL; }
  int OnDataAvailable(uint grfBSCF, uint dwSize, FORMATETC* pformatetc, STGMEDIUM* pstgmed) { return E_NOTIMPL; }
  int OnObjectAvailable(ref GUID riid, IUnknown punk) { return E_NOTIMPL; }
}

enum {
  S_ASYNCHRONOUS = 0x000401E8
}

private class DownloadBitsCallback : BindStatusCallback {

  extern(D):

  ubyte[] buffer;
  uint bytesReceived;
  Stream outputStream;
  bool async;
  bool cancelled;

  DownloadDataCompletedCallback downloadCompleted;
  DownloadProgressCallback downloadProgress;

  this(Stream outputStream, DownloadDataCompletedCallback downloadCompleted, DownloadProgressCallback downloadProgress, bool async) {
    this.outputStream = outputStream;
    this.downloadCompleted = downloadCompleted;
    this.downloadProgress = downloadProgress;
    this.async = async;
  }

  ~this() {
    outputStream = null;
    downloadCompleted = null;
    downloadProgress = null;
  }

  extern(Windows):

  override int OnProgress(uint ulProgress, uint ulProgressMax, uint ulStatusCode, in wchar* szStatusText) {
    if (downloadProgress !is null 
      /*&& (ulStatusCode >= BINDSTATUS_BEGINDOWNLOADDATA 
        && ulStatusCode <= BINDSTATUS_ENDDOWNLOADDATA)*/) {
      bool abort = false;
      int percent = ulProgressMax == 0 ? 0 : cast(int)((ulProgress * 100) / ulProgressMax);
      downloadProgress(percent, cast(long)ulProgress, cast(long)ulProgressMax, abort);

      cancelled = abort;
      if (abort)
        return E_ABORT;
    }
    return S_OK;
  }

  override int OnStopBinding(int hresult, in wchar* szError) {
    if (outputStream !is null)
      outputStream.close();

    // The operation is now completed, so cleanup.
    Release();

    if (FAILED(hresult))
      throw new NetException(to!string(toArray(szError)));

    if (downloadCompleted !is null)
      downloadCompleted(buffer);

    return S_OK;
  }

  override int GetBindInfo(out uint grfBINDF, BINDINFO* pbindinfo) {
    grfBINDF = BINDF_GETNEWESTVERSION | BINDF_NOWRITECACHE;
    if (async)
      grfBINDF |= (BINDF_ASYNCHRONOUS | BINDF_ASYNCSTORAGE);
    return S_OK;
  }

  override int OnDataAvailable(uint grfBSCF, uint dwSize, FORMATETC* pformatetc, STGMEDIUM* pstgmed) {
    if (cancelled)
      return E_ABORT;

    if (pformatetc !is null 
      && pformatetc.tymed == TYMED_ISTREAM 
      && pstgmed != null 
      && pstgmed.pstm !is null) {

      uint bytesToRead = dwSize - bytesReceived;
      if (bytesToRead > 0) {
        uint offset = bytesReceived;
        uint totalBytes = bytesReceived + bytesToRead;

        if (buffer.length < totalBytes)
          buffer.length = totalBytes;

        uint bytesRead;
        pstgmed.pstm.Read(buffer.ptr + offset, bytesToRead, bytesRead);

        if (outputStream !is null)
          outputStream.writeExact(buffer.ptr + offset, bytesRead);

        bytesReceived += bytesRead;
      }
    }
    return S_OK;
  }

}

private ubyte[] downloadBits(string address, 
                             Stream outputStream, 
                             DownloadDataCompletedCallback downloadCompleted, 
                             DownloadProgressCallback downloadProgress,
                             bool async) {

  auto callback = new DownloadBitsCallback(outputStream, downloadCompleted, downloadProgress, async);

  IMoniker urlMoniker;
  int hr = CreateURLMonikerEx(null, address.toUTF16z(), &urlMoniker, URL_MK_UNIFORM);
  if (FAILED(hr))
    throw new COMException(hr);
  scope(exit) tryRelease(urlMoniker);

  IBindCtx context;
  hr = async
    ? CreateAsyncBindCtx(0, callback, null, &context)
    : CreateBindCtx(0, context);
  if (FAILED(hr))
    throw new COMException(hr);
  scope(exit) tryRelease(context);

  if (!async)
    RegisterBindStatusCallback(context, callback, null, 0);

  IStream stream;
  hr = urlMoniker.BindToStorage(context, null, uuidof!(IStream), retval(stream));
  if (FAILED(hr) && (async && hr != S_ASYNCHRONOUS))
    throw new COMException(hr);
  scope(exit) tryRelease(stream);

  return async ? null : callback.buffer;
}

/**
 * Downloads the resource with the specified URI as a ubyte array.
 * Params: address = The URI from which to download data.
 * Returns: A ubyte array containing the downloaded resource.
 * Examples:
 * ---
 * import juno.net.core, std.stdio;
 *
 * void main() {
 *   auto remoteUri = new Uri("http://www.bbc.co.uk");
 *
 *   auto data = downloadData(remoteUri);
 *   writefln(data);
 * }
 * ---
 */
ubyte[] downloadData(Uri address, DownloadProgressCallback downloadProgress = null) {
  if (address is null)
    throw new ArgumentNullException("address");

  return downloadData(address.toString(), downloadProgress);
}

/**
 * ditto
 */
ubyte[] downloadData(string address, DownloadProgressCallback downloadProgress = null) {
  /*auto callback = new URLOpenStreamCallback;
  scope(exit) callback.Release();

  if (downloadProgress !is null)
    callback.downloadProgress = downloadProgress;

  URLOpenStream(null, address.toUTF16z(), 0, callback);
  return callback.buffer;*/
  return downloadBits(address, null, null, downloadProgress, false);
}

/**
 */
void downloadDataAsync(Uri address, DownloadDataCompletedCallback downloadCompleted = null, DownloadProgressCallback downloadProgress = null) {
  if (address is null)
    throw new ArgumentNullException("address");

  downloadDataAsync(address.toString(), downloadCompleted, downloadProgress);
}

/// ditto
void downloadDataAsync(string address, DownloadDataCompletedCallback downloadCompleted = null, DownloadProgressCallback downloadProgress = null) {
  downloadBits(address, null, (ubyte[] bytes) {
    if (downloadCompleted !is null)
      downloadCompleted(bytes.dup);
  }, downloadProgress, true);
}

/**
 * Downloads the resource with the specified URI as a string.
 * Params: address = The URI from which to download.
 * Returns: A string containing the downloaded resource.
 */
string downloadString(Uri address, DownloadProgressCallback downloadProgress = null) {
  if (address is null)
    throw new ArgumentNullException("address");

  return downloadString(address.toString(), downloadProgress);
}

/**
 * ditto
 */
string downloadString(string address, DownloadProgressCallback downloadProgress = null) {
  auto data = downloadData(address, downloadProgress);
  return cast(string)Encoding.DEFAULT.decode(data);
}

/**
 */
void downloadStringAsync(Uri address, DownloadStringCompletedCallback downloadCompleted = null, DownloadProgressCallback downloadProgress = null) {
  if (address is null)
    throw new ArgumentNullException("address");

  downloadStringAsync(address.toString(), downloadCompleted, downloadProgress);
}

/// ditto
void downloadStringAsync(string address, DownloadStringCompletedCallback downloadCompleted = null, DownloadProgressCallback downloadProgress = null) {
  downloadBits(address, null, (ubyte[] bytes) {
    if (downloadCompleted !is null)
      downloadCompleted(cast(string)Encoding.DEFAULT.decode(bytes));
  }, downloadProgress, true);
}

/**
 * Downloads the resource with the specified URI to a local file.
 * Params:
 *   address = The URI from which to download data.
 *   fileName = The name of a local file that is to receive the data.
 * Examples:
 * ---
 * import juno.net.core, juno.io.path, std.stdio;
 *
 * void main() {
 *   string remoteUri = "http://www.bbc.co.uk/bbchd/images/headings/";
 *   string fileName = "logo.gif";
 *
 *   downloadFile(remoteUri + fileName, fileName);
 *
 *   writefln("File is saved in " ~ currentDirectory);
 * }
 * ---
 */
void downloadFile(Uri address, string fileName, DownloadProgressCallback downloadProgress = null) {
  if (address is null)
    throw new ArgumentNullException("address");

  downloadFile(address.toString(), fileName, downloadProgress);
}

/**
 * ditto
 */
void downloadFile(string address, string fileName, DownloadProgressCallback downloadProgress = null) {
  auto data = downloadData(address, downloadProgress);
  std.file.write(fileName, data);
}

/**
 */
void downloadFileAsync(Uri address, string fileName, DownloadCompletedCallback downloadCompleted = null, DownloadProgressCallback downloadProgress = null) {
  if (address is null)
    throw new ArgumentNullException("address");

  downloadFileAsync(address.toString(), fileName, downloadCompleted, downloadProgress);
}

/// ditto
void downloadFileAsync(string address, string fileName, DownloadCompletedCallback downloadCompleted = null, DownloadProgressCallback downloadProgress = null) {
  downloadBits(address, new File(fileName, FileMode.OutNew), (ubyte[] bytes) {
    if (downloadCompleted !is null)
      downloadCompleted();
  }, downloadProgress, true);
}

private void parseUserInfo(string userInfo, out string userName, out string password) {
  if (userInfo != null) {
    string[] userNameAndPassword = userInfo.split(':');
    if (userNameAndPassword.length > 0) {
      userName = userNameAndPassword[0];
      if (userNameAndPassword.length > 1)
        password = userNameAndPassword[1];
    }
  }
}

/// <code class="d_code">void delegate(int percent, long bytesSent, long bytesToSend)</code><br>
alias void delegate(int percent, long bytesSent, long bytesToSend) UploadProgressCallback;

/// <code class="d_code">void delegate(ubyte[] result)</code><br>
alias void delegate(ubyte[] result) UploadDataCompletedCallback;

/// <code class="d_code">void delegate(string result)</code><br>
alias void delegate(string result) UploadStringCompletedCallback;

/// <code class="d_code">void delegate()</code><br>
alias void delegate() UploadCompletedCallback;

private struct ProgressData {

  long bytesSent;
  long bytesToSend;
  UploadProgressCallback uploadProgress;

}

private struct UploadBitsState {

  Uri uri;
  ubyte[] buffer;
  UploadDataCompletedCallback uploadCompleted;
  bool async;
  string method;

  Handle session;
  Handle connection;
  Handle file;

  int stage;
  ProgressData* progress;

}

private ubyte[] uploadBits(Uri address, string method, in ubyte[] data, UploadDataCompletedCallback uploadCompleted, UploadProgressCallback uploadProgress, bool async) {

  extern(Windows)
  static void statusCallback(Handle handle, uint context, uint status, void* statusInformation, uint statusInformationLength) {
    auto state = cast(UploadBitsState*)context;

    switch (status) {
      case INTERNET_STATUS_HANDLE_CREATED:
        if (state.async) {
          auto result = cast(INTERNET_ASYNC_RESULT*)statusInformation;

          if (state.stage == 0) {
            state.connection = cast(Handle)result.dwResult;
            state.stage = 1;
          }
          else if (state.stage == 1) {
            state.file = cast(Handle)result.dwResult;
          }
        }
        break;
      case INTERNET_STATUS_REQUEST_SENT:
        if (auto progress = state.progress) {
          long bytesSent = cast(long)*cast(int*)statusInformation;

          progress.bytesSent += bytesSent;
          if (progress.bytesSent > progress.bytesToSend)
            progress.bytesSent = 0;

          if (progress.uploadProgress !is null) {
            int percent = (progress.bytesToSend == 0) ? 0 : cast(int)((progress.bytesSent / progress.bytesToSend) * 100);
            progress.uploadProgress(percent, progress.bytesSent, progress.bytesToSend);
          }
        }
        break;
      case INTERNET_STATUS_REQUEST_COMPLETE:
        if (state.async) {
          if (state.stage == 1) {
            if (state.uri.scheme == Uri.uriSchemeFtp)
              FtpOpenFile(state.connection, state.uri.localPath().toUTF16z(), GENERIC_WRITE, FTP_TRANSFER_TYPE_BINARY | INTERNET_FLAG_RELOAD, cast(uint)state);
            else
              HttpOpenRequest(state.connection, state.method.toUTF16z(), state.uri.pathAndQuery().toUTF16z(), null, null, null, INTERNET_FLAG_RELOAD, cast(uint)state);
            state.stage = 2;
          }
          else if (state.stage == 2) {
            if (state.uri.scheme == Uri.uriSchemeFtp) {
              uint bytesWritten;
              InternetWriteFile(state.file, state.buffer.ptr, state.buffer.length, &bytesWritten);
            }
            else {
              HttpSendRequest(state.file, null, 0, state.buffer.ptr, state.buffer.length);
            }
            state.stage = 3;
          }
          else if (state.stage == 3) {
            InternetCloseHandle(state.file);
            InternetCloseHandle(state.connection);

            InternetSetStatusCallback(state.session, null);
            InternetCloseHandle(state.session);
            state.stage = 4;
          }
        }
        break;
      case INTERNET_STATUS_RESPONSE_RECEIVED:
        //uint bytesReceived = *cast(uint*)statusInformation;
        break;
      case INTERNET_STATUS_HANDLE_CLOSING:
        break;
      case INTERNET_STATUS_CONNECTION_CLOSED:
         if (state.uploadCompleted !is null)
          state.uploadCompleted(null);

        state = null;
        break;

      default:
    }
  }

  bool schemeIsFtp = (address.scheme == Uri.uriSchemeFtp);

  if (method == null) {
    if (schemeIsFtp)
      method = "STOR";
    else
      method = "POST";
  }

  ubyte[] response;

  auto state = new UploadBitsState;

  state.uri = address;
  state.buffer = cast(ubyte[])data;
  state.uploadCompleted = uploadCompleted;
  state.async = async;
  state.method = method;

  state.progress = new ProgressData;
  state.progress.bytesToSend = data.length;
  state.progress.uploadProgress = uploadProgress;

  Handle session = state.session = InternetOpen(null, INTERNET_OPEN_TYPE_PRECONFIG, null, null, async ? INTERNET_FLAG_ASYNC : 0);
  if (!async) scope(exit) InternetCloseHandle(session);

  if (session == Handle.init)
    throw new NetException;

  InternetSetStatusCallback(session, &statusCallback);

  string userName;
  string password;
  parseUserInfo(address.userInfo, userName, password);

  Handle connection = InternetConnect(session,
                                      address.host().toUTF16z(),
                                      cast(ushort)address.port, 
                                      userName.toUTF16z(),
                                      password.toUTF16z(),
                                      schemeIsFtp ? INTERNET_SERVICE_FTP : INTERNET_SERVICE_HTTP, 
                                      INTERNET_FLAG_PASSIVE | INTERNET_FLAG_DONT_CACHE,
                                      cast(uint)state);
  if (!async) scope(exit) InternetCloseHandle(connection);

  if ((async && connection == Handle.init && GetLastError() != ERROR_IO_PENDING) || (!async && connection == Handle.init))
    throw new NetException;

  if (!async) {
    if (schemeIsFtp) {
      Handle file = FtpOpenFile(connection, address.localPath().toUTF16z(), GENERIC_WRITE, FTP_TRANSFER_TYPE_BINARY | INTERNET_FLAG_RELOAD, cast(uint)state);
      scope(exit) InternetCloseHandle(file);

      if (file == Handle.init)
        throw new NetException;

      uint bytesWritten;
      if (!InternetWriteFile(file, data.ptr, data.length, &bytesWritten)) {
        //throw new NetException;
      }
    }
    else {
      Handle request = HttpOpenRequest(connection, method.toUTF16z(), address.pathAndQuery().toUTF16z(), null, null, null, INTERNET_FLAG_RELOAD, cast(uint)state);
      scope(exit) InternetCloseHandle(request);

      if (request == Handle.init)
        throw new NetException;

      if (!HttpSendRequest(request, null, 0, data.ptr, data.length)) {
      }

      uint statusCode;
      uint len = uint.sizeof;
      HttpQueryInfo(request, HTTP_QUERY_STATUS_CODE | HTTP_QUERY_FLAG_NUMBER, &statusCode, &len, null);

      if (statusCode > HTTP_STATUS_OK) {
        len = 0;
        HttpQueryInfo(request, HTTP_QUERY_STATUS_TEXT, null, &len, null);

        auto buffer = cast(wchar*)std.c.stdlib.malloc(len * wchar.sizeof);
        scope(exit) std.c.stdlib.free(buffer);

        HttpQueryInfo(request, HTTP_QUERY_STATUS_TEXT, buffer, &len, null);
        string statusText = to!string(buffer[0 .. len]);

        throw new NetException(std.string.format("The remote server returned an error: (%s) %s", statusCode, statusText));
      }

      ubyte[1024] buffer;
      uint totalBytesRead, bytesRead;

      while ((InternetReadFile(request, buffer.ptr, buffer.length, &bytesRead) == TRUE) && (bytesRead > 0)) {
        response.length = response.length + bytesRead;
        response[totalBytesRead .. totalBytesRead + bytesRead] = buffer[0 .. bytesRead];
        totalBytesRead += bytesRead;
      }
    }
  }

  return async ? null : response;
}

/**
 * Uploads a _data buffer to a resource identified by a URI.
 * Params:
 *   address = The URI of the resource to receive the _data.
 *   data = The _data buffer to send to the resource.
 * Returns: A ubyte array containing the body of the response from the resource.
 */
ubyte[] uploadData(Uri address, in ubyte[] data, UploadProgressCallback uploadProgress = null) {
  if (address is null)
    throw new ArgumentNullException("address");

  return uploadBits(address, null, data, null, uploadProgress, false);
}

/**
 * ditto
 */
ubyte[] uploadData(string address, in ubyte[] data, UploadProgressCallback uploadProgress = null) {
  return uploadData(new Uri(address), data, uploadProgress);
}

void uploadDataAsync(Uri address, in ubyte[] data, UploadDataCompletedCallback uploadCompleted = null, UploadProgressCallback uploadProgress = null) {
  if (address is null)
    throw new ArgumentNullException("address");

  uploadBits(address, null, data, (ubyte[] result) {
    if (uploadCompleted !is null)
      uploadCompleted(result.dup);
  }, uploadProgress, true);
}

void uploadDataAsync(string address, in ubyte[] data, UploadDataCompletedCallback uploadCompleted = null, UploadProgressCallback uploadProgress = null) {
  uploadDataAsync(new Uri(address), data, uploadCompleted, uploadProgress);
}

/**
 * Uploads the specified string to the specified resource.
 * Params:
 *   address = The URI of the resource to receive the string.
 *   data = The string to be uploaded.
 * Returns: A string containing the body of the response from the resource.
 */
string uploadString(Uri address, string data, UploadProgressCallback uploadProgress = null) {
  if (address is null)
    throw new ArgumentNullException("address");

  auto result = uploadBits(address, null, Encoding.DEFAULT.encode(cast(char[])data), null, uploadProgress, false);
  return cast(string)Encoding.DEFAULT.decode(result);
}

/**
 * ditto
 */
string uploadString(string address, string data, UploadProgressCallback uploadProgress = null) {
  return uploadString(new Uri(address), data, uploadProgress);
}

/**
 */
void uploadStringAsync(Uri address, string data, UploadStringCompletedCallback uploadCompleted = null, UploadProgressCallback uploadProgress = null) {
  if (address is null)
    throw new ArgumentNullException("address");

  uploadBits(address, null, Encoding.DEFAULT.encode(cast(char[])data), (ubyte[] result) {
    if (uploadCompleted !is null)
      uploadCompleted(cast(string)Encoding.DEFAULT.decode(result));
  }, uploadProgress, true);
}

/// ditto
void uploadStringAsync(string address, string data, UploadStringCompletedCallback uploadCompleted = null, UploadProgressCallback uploadProgress = null) {
  uploadStringAsync(new Uri(address), data, uploadCompleted, uploadProgress);
}

/**
 * Uploads the specified local file to a resource with the specified URI.
 * Params:
 *   address = The URI of the resource to receive the file. For example, ftp://localhost/samplefile.txt.
 *   fileName = The file to send to the resource. For example, "samplefile.txt".
 * Returns: A ubyte array containing the body of the response from the resource.
 * Examples:
 * ---
 * import juno.net.core, std.stdio;
 * 
 * void main() {
 *   writef("Enter the URI to upload to: ");
 *   string uriString = readln();
 *
 *   writef("\nEnter the path of the file to upload: ");
 *   string fileName = readln();
 *
 *   // Strip trailing '\n' on input.
 *   uriString = uriString[0 .. $-1];
 *   fileName = fileName[0 .. $-1];
 *
 *   writefln("\nUploading %s to %s", fileName, uriString);
 *
 *   // Upload the file to the URI.
 *   uploadFile(uriString, fileName);
 * }
 * ---
 */
ubyte[] uploadFile(Uri address, string fileName, UploadProgressCallback uploadProgress = null) {
  if (address is null)
    throw new ArgumentNullException("address");

  return uploadBits(address, null, cast(ubyte[])std.file.read(fileName), null, uploadProgress, false);
}

/**
 * ditto
 */
ubyte[] uploadFile(string address, string fileName, UploadProgressCallback uploadProgress = null) {
  return uploadFile(new Uri(address), fileName, uploadProgress);
}

/**
 */
void uploadFileAsync(Uri address, string fileName, UploadCompletedCallback uploadCompleted = null, UploadProgressCallback uploadProgress = null) {
  if (address is null)
    throw new ArgumentNullException("address");

  uploadBits(address, null, cast(ubyte[])std.file.read(fileName), (ubyte[] result) {
    if (uploadCompleted !is null)
      uploadCompleted();
  }, uploadProgress, true);
}

void uploadFileAsync(string address, string fileName, UploadCompletedCallback uploadCompleted = null, UploadProgressCallback uploadProgress = null) {
  uploadFileAsync(new Uri(address), fileName, uploadCompleted, uploadProgress);
}

module juno.io.path;

private import juno.base.core,
  juno.base.string,
  juno.base.win32;

public const char DIRECTORY_SEPARATOR = '\\';
public const char ALT_DIRECTORY_SEPARATOR = '/';
public const char VOLUME_SEPARATOR = ':';

public enum SpecialFolder {
  Desktop = 0,
  Programs = 2,
  Personal = 5,
  MyDocuments = Personal,
  Favorites = 6,
  Startup = 7,
  Recent = 8,
  SendTo = 9,
  StartMenu = 11,
  MyMusic = 13,
  DesktopDirectory = 16,
  MyComputer = 17,
  Templates = 21,
  ApplicationData = 26,
  LocalApplicationData = 28,
  InternetCache = 32,
  Cookies = 33,
  History = 34,
  CommonApplicationData = 35,
  System = 37,
  ProgramFiles = 38,
  MyPictures = 39,
  CommonProgramFiles = 43
}

public bool isPathRooted(char[] path) {
  if (path !is null) {
    int n = path.length;
    if ((n >= 1 && (path[0] == DIRECTORY_SEPARATOR || path[0] == ALT_DIRECTORY_SEPARATOR)) || (n >= 2 && path[1] == VOLUME_SEPARATOR))
      return true;
  }
  return false;
}

public char[] combinePaths(char[] path1, char[] path2) {
  if (path2.length == 0)
    return path1;
  if (path1.length == 0)
    return path2;
  if (isPathRooted(path2))
    return path2;
  char ch = path1[$ - 1];
  if (ch != DIRECTORY_SEPARATOR && ch != ALT_DIRECTORY_SEPARATOR && ch != VOLUME_SEPARATOR)
    return path1 ~ DIRECTORY_SEPARATOR ~ path2;
  return path1 ~ path2;
}

public char[] changeExtension(char[] path, char[] extension) {
  if (path !is null) {
    char[] s = path;
    for (int i = path.length; --i >= 0;) {
      char ch = path[i];
      if (ch == '.') {
        s = path[0 .. i];
        break;
      }
      if (ch == DIRECTORY_SEPARATOR || ch == ALT_DIRECTORY_SEPARATOR || ch == VOLUME_SEPARATOR)
        break;
    }
    if (path.length != 0) {
      if (extension.length == 0 || extension[0] != '.')
        s ~= '.';
      s ~= extension;
    }
    return s;
  }
  return null;
}

public bool hasExtension(char[] path) {
  if (path !is null) {
    int n = path.length;
    while (--n >= 0) {
      if (path[n] == '.') {
        if (n != path.length - 1)
          return true;
        return false;
      }
      if (path[n] == DIRECTORY_SEPARATOR || path[n] == ALT_DIRECTORY_SEPARATOR || path[n] == VOLUME_SEPARATOR)
        break;
    }
  }
  return false;
}

public char[] getExtension(char[] path) {
  if (path is null)
    return null;
  int n = path.length;
  while (--n >= 0) {
    if (path[n] == '.') {
      if (n != path.length - 1)
        return path[n .. $];
      return "";
    }
    if (path[n] == DIRECTORY_SEPARATOR || path[n] == ALT_DIRECTORY_SEPARATOR || path[n] == VOLUME_SEPARATOR)
      break;
  }
  return "";
}

public char[] getFileName(char[] path) {
  if (path !is null) {
    int len = path.length;
    int n = len;
    while (--n >= 0) {
      if (path[n] == DIRECTORY_SEPARATOR || path[n] == ALT_DIRECTORY_SEPARATOR || path[n] == VOLUME_SEPARATOR)
        return path[n + 1 .. $];
    }
  }
  return path;
}

public char[] getFileNameWithoutExtension(char[] path) {
  path = getFileName(path);
  if (path != null) {
    int i = path.indexOf('.');
    if (i == -1)
      return path;
    return path[0 .. i];
  }
  return null;
}

public char[] getDirectoryName(char[] path) {
  if (path !is null) {
    path = normalizePath(path, false);
    uint n = getRootLength(path);
    uint len = path.length;
    if (len > n) {
      while (len > n && (path[--len] != DIRECTORY_SEPARATOR && path[len] != ALT_DIRECTORY_SEPARATOR)) {}
      return path[0 .. len];
    }
  }
  return null;
}

public char[] getTempPath() {
  wchar[MAX_PATH] buffer;
  GetTempPath(buffer.length, buffer);
  return getFullPath(buffer.toUtf8());
}

public char[] getTempFileName() {
  char[] path = getTempPath();
  wchar[MAX_PATH] buffer;
  GetTempFileName(path.toLPStr(), "tmp", 0, buffer);
  return buffer.toUtf8();
}

public char[] getFolderPath(SpecialFolder folder) {
  wchar[MAX_PATH] buffer;
  SHGetFolderPath(Handle.init, cast(int)folder, Handle.init, 0, buffer);
  return buffer.toUtf8();
}

public char[] getFullPath(char[] path) {
  if (path is null)
    throw new ArgumentNullException("path");
  return normalizePath(path, true);
}

private char[] normalizePath(char[] path, bool fullCheck) {
  wchar[MAX_PATH] buffer;
  PathCanonicalizeW(buffer, path.toLPStr());
  if (fullCheck)
    GetLongPathNameW(buffer, buffer, MAX_PATH);
  return buffer.toUtf8();
}

private uint getRootLength(char[] path) {
  uint n;
  uint len = path.length;
  if (len >= 1 && (path[0] == DIRECTORY_SEPARATOR || path[0] == ALT_DIRECTORY_SEPARATOR)) {
    // UNC names
    n = 1;
    if (len >= 2 && (path[1] == DIRECTORY_SEPARATOR || path[1] == ALT_DIRECTORY_SEPARATOR)) {
      n = 2;
      uint c = 2;
      while (n < len && ((path[n] != DIRECTORY_SEPARATOR && path[n] != ALT_DIRECTORY_SEPARATOR) || --c > 0))
        n++;
    }
  }
  else if (len >= 2 && path[1] == VOLUME_SEPARATOR) {
    n = 2;
    if (len >= 3 && (path[2] == DIRECTORY_SEPARATOR || path[2] == ALT_DIRECTORY_SEPARATOR))
      n++;
  }
  return n;
}
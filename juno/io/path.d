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

module juno.io.path;

private import juno.base.core,
  juno.base.string,
  juno.base.native;

private static import std.gc;

extern (C) 
private wchar* wcsncpy(wchar*, wchar*, size_t);

public final char DirectorySeparator = '\\';
public final char AltDirectorySeparator = '/';
public final char VolumeSeparator = ':';
public final char PathSeparator = ';';
public const int MaxPath = MAX_PATH;

package int getRootLength(string path) {
  int i, len = path.length;
  if (len >= 1 && (path[0] == DirectorySeparator || path[0] == AltDirectorySeparator)) {
    i = 1;
    if (len >= 2 && (path[1] == DirectorySeparator || path[1] == AltDirectorySeparator)) {
      i = 2;
      int n = 2;
      while (i < len && ((path[i] != DirectorySeparator && path[i] != AltDirectorySeparator) || --n > 0)) {
        i++;
      }
    }
  }
  else if (len >= 2 && path[1] == VolumeSeparator) {
    i = 2;
    if (len >= 3 && (path[2] == DirectorySeparator || path[2] == AltDirectorySeparator)) {
      i++;
    }
  }
  return i;
}

public bool isPathRooted(string path) {
  if ((path.length > 1 && (path[0] == DirectorySeparator || path[0] == AltDirectorySeparator)) || (path.length >= 2 && path[1] == VolumeSeparator))
    return true;
  return false;
}

public string changeExtension(string path, string extension) {
  string s = path.dup;
  for (int i = s.length; --i >= 0;) {
    char c = path[i];
    if (c == '.') {
      s = path[0 .. i];
      break;
    }
    if (c == DirectorySeparator || c == AltDirectorySeparator || c == VolumeSeparator) break;
  }
  if (path.length > 0) {
    if (extension.length == 0 || extension[0] != '.')
      s ~= '.';
    s ~= extension;
  }
  return s;
}

public string getExtension(string path) {
  int len = path.length;
  for (int i = len; --i >= 0;) {
    char c = path[i];
    if (c == '.') {
      if (i != len - 1)
        return path[i .. $].dup;
      else
        return string.init;
    }
    if (c == DirectorySeparator || c == AltDirectorySeparator || c == VolumeSeparator) break;
  }
  return "";
}

public string getFileName(string path) {
  int len = path.length;
  for (int i = len; --i >= 0;) {
    char c = path[i];
    if (c == DirectorySeparator || c == AltDirectorySeparator || c == VolumeSeparator)
      return path[i + 1 .. $];
  }
  return path.dup;
}

public string getFileNameWithoutExtension(string path) {
  string fileName = getFileName(path);
  if (fileName != null) {
    int i;
    if ((i = fileName.lastIndexOf('.')) == -1)
      return fileName;
    else
      return fileName[0 .. i];
  }
  return "";
}

public string getDirectoryName(string path) {
  int root = getRootLength(path);
  int i = path.length;
  while (i > root && path[--i] != DirectorySeparator && path[i] != AltDirectorySeparator) {
  }
  return path[0 .. i];
}

public string combinePaths(string path1, string path2) {
  if (path2.length == 0)
    return path1.dup;
  if (path1.length == 0)
    return path2.dup;
  if (isPathRooted(path2))
    return path2.dup;
  char c = path1[$ - 1];
  if (c != DirectorySeparator && c != AltDirectorySeparator && c != VolumeSeparator)
    return path1 ~ DirectorySeparator ~ path2;
  return path1 ~ path2;
}

public string getFullPath(string path) {
  wchar[] buffer = new wchar[MaxPath + 1];
  uint bufferLength = GetFullPathName(path.toUtf16z(), MaxPath + 1, buffer.ptr, null);

  if (bufferLength > MaxPath) {
    buffer = new wchar[bufferLength];
    bufferLength = GetFullPathName(path.toUtf16z(), bufferLength, buffer.ptr, null);
  }

  if (bufferLength < MaxPath)
    buffer[bufferLength] = '\0';

  bool expandShortPath = false;
  for (int i = 0; i < bufferLength; i++) {
    if (buffer[i] == '~')
      expandShortPath = true;
  }

  if (expandShortPath) {
    wchar[] tempBuffer = new wchar[MaxPath + 1];
    uint r = GetLongPathName(buffer.ptr, tempBuffer.ptr, MaxPath);

    if (r > 0) {
      wcsncpy(buffer.ptr, tempBuffer.ptr, r * 2);
      bufferLength = r;
      buffer[bufferLength] = '\0';
    }
  }

  return toUtf8(buffer.ptr, 0, bufferLength);
}

public string getTempPath() {
  wchar[MaxPath] buffer;
  GetTempPath(MaxPath, buffer.ptr);
  return getFullPath(toUtf8(buffer.ptr));
}

public string getTempFileName(string prefix = "tmp") {
  string tempPath = getTempPath();
  wchar[MaxPath] buffer;
  GetTempFileName(tempPath.toUtf16z(), prefix.toUtf16z(), 0, buffer.ptr);
  return toUtf8(buffer.ptr);
}

public enum SpecialFolder {
  Desktop = 0x0000,
  Internet = 0x0001,
  Programs = 0x0002,
  Controls = 0x0003,
  Printers = 0x0004,
  Personal = 0x0005,
  Favorites = 0x0006,
  Startup = 0x0007,
  Recent = 0x0008,
  SendTo = 0x0009,
  RecycleBin = 0x000a,
  StartMenu = 0x000b,
  Documents = Personal,
  Music = 0x000d,
  Video = 0x000e,
  DesktopDirectory = 0x0010,
  Computer = 0x0011,
  Network = 0x0012,
  Fonts = 0x0014,
  Templates = 0x0015,
  CommonStartMenu = 0x0016,
  CommonPrograms = 0x0017,
  CommonStartup = 0x0018,
  CommonDesktopDirectory = 0x0019,
  ApplicationData = 0x001a,
  LocalApplicationData = 0x001c,
  InternetCache = 0x0020,
  Cookies = 0x0021,
  History = 0x0022,
  CommonApplicationData = 0x0023,
  Windows = 0x0024,
  System = 0x0025,
  ProgramFiles = 0x0026,
  Pictures = 0x0027,
  CommonProgramFiles = 0x002b,
  CommonTemplates = 0x002d,
  CommonDocuments = 0x002e,
  Connections = 0x0031,
  Resources = 0x0038,
  LocalizedResources = 0x0039,
  CDBurning = 0x003b
}

public string getFolderPath(SpecialFolder folder) {
  wchar[MAX_PATH] buffer;
  SHGetFolderPath(Handle.init, cast(int)folder, Handle.init, SHGFP_TYPE_CURRENT, buffer.ptr);
  return .toUtf8(buffer.ptr);
}
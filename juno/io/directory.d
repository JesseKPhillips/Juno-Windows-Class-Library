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

module juno.io.directory;

private import juno.base.core,
  juno.base.string,
  juno.base.native,
  juno.io.path;

public string getCurrentDirectory() {
  wchar[MAX_PATH + 1] buffer;
  uint len = GetCurrentDirectory(buffer.length, buffer.ptr);
  return .toUtf8(buffer.ptr, 0, len);
}

public string getSystemDirectory() {
  wchar[MAX_PATH + 1] buffer;
  uint len = GetSystemDirectory(buffer.ptr, buffer.length);
  return .toUtf8(buffer.ptr, 0, len);
}

public bool directoryExists(string path) {
  if (path == null)
    return false;

  string fullPath = getFullPath(path);

  WIN32_FILE_ATTRIBUTE_DATA data;
  if (GetFileAttributesEx(fullPath.toUtf16z(), 0, &data))
    return (data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0;
  return false;
}

public void createDirectory(string path) {
  string fullPath = getFullPath(path);

  uint len = fullPath.length;
  if (len >= 2 && (fullPath[len - 1] == DirectorySeparator || fullPath[len - 1] == AltDirectorySeparator))
    len--;

  string[] list;
  uint root = getRootLength(fullPath);
  if (len > root) {
    for (uint i = len - 1; i >= root; i--) {
      string dir = fullPath[0 .. i + 1];
      if (!directoryExists(dir))
        list ~= dir;
      while (i > root && fullPath[i] != DirectorySeparator && fullPath[i] != AltDirectorySeparator) i--;
    }
  }

  foreach_reverse (dir; list) {
    CreateDirectory(dir.toUtf16z(), null);
  }
}
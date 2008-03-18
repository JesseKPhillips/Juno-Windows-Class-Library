/**
 * Copyright: (c) 2008 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.io.path;

private import juno.base.native;

private import std.utf : toUTF16z, toUTF8;

const int MaxPath = MAX_PATH;

string getFullPath(string path) {
  wchar* p = path.toUTF16z();

  wchar[] buffer = new wchar[MaxPath + 1];
  uint bufferLength = GetFullPathName(p, MaxPath + 1, buffer.ptr, null);

  if (bufferLength > MaxPath) {
    buffer = new wchar[bufferLength];
    bufferLength = GetFullPathName(p, bufferLength, buffer.ptr, null);
  }

  bool expandShortPath;
  for (uint i = 0; i < bufferLength && !expandShortPath; i++) {
    if (buffer[i] == '~')
      expandShortPath = true;
  }
  if (expandShortPath) {
    // Expand short path names such as C:\Progra~1\Micros~2
    wchar[] tempBuffer = new wchar[MaxPath + 1];
    bufferLength = GetLongPathName(buffer.ptr, tempBuffer.ptr, MaxPath);

    if (bufferLength > 0)
      return tempBuffer[0 .. bufferLength].toUTF8();
  }

  return buffer[0 .. bufferLength].toUTF8();
}
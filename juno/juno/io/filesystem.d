module juno.io.filesystem;

import juno.base.text,
  juno.base.win32;

public abstract final class Path {

  public static char[] getFullPath(char[] path) {
    wchar[260] buffer;
    GetFullPathNameW(path.toUtf16z(), buffer.length, buffer, null);
    return toUtf8(buffer.ptr);
  }

}

public abstract final class File {

  public static bool exists(char[] path) {
    WIN32_FILE_ATTRIBUTE_DATA data;
    if (fillAttributeInfo(path, data) == 0)
      return (data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) == 0;
    return false;
  }

  private static int fillAttributeInfo(char[] path, inout WIN32_FILE_ATTRIBUTE_DATA data) {
    int result;
    if (!GetFileAttributesExW(path.toUtf16z(), 0, data))
      result = GetLastError();
    return result;
  }

}

public abstract class FileSystemInfo {

  protected char[] originalPath;
  protected char[] fullPath;

  public char[] fullName() {
    return fullPath;
  }

}

public class FileInfo : FileSystemInfo {

  public this(char[] fileName) {
    originalPath = fileName;
    fullPath = Path.getFullPath(fileName);
  }

}
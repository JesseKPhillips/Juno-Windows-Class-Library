module juno.base.environment;

private import juno.base.string,
  juno.base.win32;

public char[] expandEnvironmentVariables(char[] name) {
  char[][] parts = name.split(['%']);

  int c = 100;
  wchar[] buffer = new wchar[c];
  for (int i = 1; i < parts.length - 1; i++) {
    if (parts[i].length > 0) {
      char[] temp = "%" ~ parts[i] ~ "%";
      uint n = ExpandEnvironmentStrings(temp.toLPStr(), buffer, c);
      while (n > c) {
        c = n;
        buffer.length = c;
        n = ExpandEnvironmentStrings(temp.toLPStr(), buffer, c);
      }
    }
  }
  int n = ExpandEnvironmentStrings(name.toLPStr(), buffer, c);
  while (n > c) {
    c = n;
    buffer.length = c;
    n = ExpandEnvironmentStrings(name.toLPStr(), buffer, c);
  }
  char[] result = buffer.toUtf8();
  delete buffer;
  return result;
}

public char[] getEnvironmentVariable(char[] variable) {
  wchar[] buffer = new wchar[80];
  int n = GetEnvironmentVariable(variable.toLPStr(), buffer, buffer.length);
  if (n == 0)
    return null;
  while (n > buffer.length) {
    buffer.length = n;
    n = GetEnvironmentVariable(variable.toLPStr(), buffer, buffer.length);
  }
  char[] result = buffer.toUtf8();
  delete buffer;
  return result;
}

public void setEnvironmentVariable(char[] variable, char[] value) {
  if (!SetEnvironmentVariable(variable.toLPStr(), value.toLPStr()))
    throw new Win32Exception;
}
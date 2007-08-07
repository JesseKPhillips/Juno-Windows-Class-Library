module juno.io.file;

private import juno.base.native,
  juno.base.string,
  juno.io.path;

public bool encryptFile(string path) {
  string fullPath = getFullPath(path);
  return EncryptFile(fullPath.toUtf16z()) != 0;
}

public void decryptFile(string path) {
  string fullPath = getFullPath(path);
  DecryptFile(fullPath.toUtf16z(), 0);
}

public void moveFile(string sourceFileName, string destinationFileName) {
  string sourceFullPath = getFullPath(sourceFileName);
  string destFullPath = getFullPath(destinationFileName);

  MoveFile(sourceFullPath.toUtf16z(), destFullPath.toUtf16z());
}

public void replaceFile(string sourceFileName, string destinationFileName, string destinationBackupFileName) {
  string sourceFullPath = getFullPath(sourceFileName);
  string destFullPath = getFullPath(destinationFileName);
  string backupFullPath = getFullPath(destinationBackupFileName);

  ReplaceFile(destFullPath.toUtf16z(), sourceFullPath.toUtf16z(), backupFullPath.toUtf16z(), REPLACEFILE_WRITE_THROUGH, null, null);
}
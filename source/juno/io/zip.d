module juno.io.zip;

import juno.base.core,
  juno.base.string,
  juno.base.text,
  juno.locale.time,
  std.stream,
  etc.c.zlib;
//debug import std.stdio : writeln, writefln;

private enum : uint {
  LOCAL_FILE_HEADER_SIGNATURE             = 0x04034b50,
  CENTRAL_DIRECTORY_FILE_HEADER_SIGNATURE = 0x02014b50,
  END_OF_CENTRAL_DIRECTORY_SIGNATURE      = 0x06054b50
}

private ubyte[] END_OF_CENTRAL_DIRECTORY_SIGNATURE_BYTES = [0x50, 0x4b, 0x05, 0x06];

private DateTime dosDateTimeToDateTime(uint dosDateTime) {
  int second = (dosDateTime & 0x1f) << 1;
  int minute = (dosDateTime >> 5) & 0x3F;
  int hour = (dosDateTime >> 11) & 0x1F;
  int day = (dosDateTime >> 16) & 0x1F;
  int month = (dosDateTime >> 21) & 0xF;
  int year = 1980 + ((dosDateTime >> 25) & 0x7F);
  try {
    return DateTime(year, month, day, hour, minute, second);
  }
  catch {
    return DateTime(1980, 1, 1);
  }
}

private uint dateTimeToDosDateTime(DateTime dateTime) {
  return (dateTime.second / 2) & 0x1F |
         (dateTime.minute & 0x3F) << 5 |
         (dateTime.hour & 0x1F) << 11 |
         (dateTime.day & 0x1F) << 16 |
         (dateTime.month & 0xF) << 21 |
         ((dateTime.year - 1980) & 0x7F) << 25;
}

class ZipException : Exception {

  this(string message) {
    super(message);
  }

  this(int errorCode) {
    super(getErrorMessage(errorCode));
  }

  private static string getErrorMessage(int errorCode) {
    // Zlib's error messages aren't very descriptive.
    //return toUtf8(etc.c.zlib.zError(errorCode));
    switch (errorCode) {
      case Z_STREAM_END: return "End of stream detected.";
      case Z_NEED_DICT: return "A preset dictionary is needed.";
      case Z_ERRNO: return "File error.";
      case Z_STREAM_ERROR: return "Stream structure is inconsistent.";
      case Z_DATA_ERROR: return "Input data is corrupted.";
      case Z_MEM_ERROR: return "Not enough memory.";
      case Z_BUF_ERROR: return "No room in output buffer.";
      case Z_VERSION_ERROR: return "Incompatible library verion.";
      default: return "No error.";
    }
  }

}

/**
 * Indicates the method employed to compress an entry in a zip file.
 */
enum CompressionMethod : ushort {
  Stored   = 0x0, /// Indicates the entry is not compressed.
  Deflated = 0x8  /// Indicates the Deflate method is used to compress the entry.
}

/**
 * Indicates the compression level to be used when compressing an entry in a zip file.
 */
enum CompressionLevel {
  Default = -1, /// The default compression level.
  None    = 0,  /// Indicates the entry is not compressed.
  Fastest = 1,  /// The fastest but least efficient level of compression.
  Best    = 9   /// The most efficient but slowest level of compression.
}

private void copyStream(Stream input, Stream output) {
  ubyte[1024 * 4] buffer;

  ulong pos = input.position;
  input.position = 0;

  while (true) {
    uint n = input.readBlock(buffer.ptr, buffer.length);
    if (n == 0)
      return;
    output.writeBlock(buffer.ptr, n);
  }
}

private class SliceStreamWithSize : SliceStream {

  ulong size_;

  this(Stream source, ulong offset, ulong size) {
    super(source, offset, size);
    size_ = size;
  }

  override ulong size() {
    return size_;
  }

}

private class CopyFilterStream : FilterStream {

  this(Stream source) {
    super(source);
  }

  override void copyFrom(Stream source) {
    copyStream(source, this);
  }

}

private class InflateStream : CopyFilterStream {

  ulong size_;

  ubyte[] buffer_;
  z_stream zs_;

  this(Stream source, ulong size) {
    super(source);
    size_ = size;
    buffer_.length = 1024 * 256;

    int result = inflateInit2(&zs_, -15);
    if (result != Z_OK)
      throw new ZipException(result);
  }

  override size_t readBlock(void* buffer, size_t size) {
    if (zs_.avail_in == 0) {
      if ((zs_.avail_in = source().read(buffer_)) <= 0)
        return 0;
      zs_.next_in = buffer_.ptr;
    }

    zs_.next_out = cast(ubyte*)buffer;
    zs_.avail_out = size;

    int result = inflate(&zs_, Z_NO_FLUSH);
    if (result != Z_STREAM_END && result != Z_OK)
      throw new ZipException(result);

    return size - zs_.avail_out;
  }

  override size_t writeBlock(in void* buffer, size_t size) {
    throw new NotSupportedException;
  }

  override void flush() {
    super.flush();
    inflateEnd(&zs_);
  }

  override @property ulong size() {
    return size_;
  }

}

private class DeflateStream : CopyFilterStream {

  ubyte[] buffer_;
  z_stream zs_;
  ulong size_;

  this(Stream source, CompressionLevel level) {
    super(source);
    buffer_.length = 1024 * 256;

    int result = deflateInit2(&zs_, cast(int)level, Z_DEFLATED, -15, 8, Z_DEFAULT_STRATEGY);
    if (result != Z_OK)
      throw new ZipException(result);
  }

  override void close() {
    flush();
  }

  override size_t readBlock(void* buffer, size_t size) {
    throw new NotSupportedException;
  }

  override size_t writeBlock(in void* buffer, size_t size) {
    zs_.avail_in = size;
    zs_.next_in = cast(ubyte*)buffer;

    do {
      zs_.avail_out = buffer_.length;
      zs_.next_out = buffer_.ptr;

      int result = deflate(&zs_, Z_NO_FLUSH);
      if (result == Z_STREAM_ERROR)
        throw new ZipException(result);

      uint n = buffer_.length - zs_.avail_out;
      ubyte[] b = buffer_[0 .. n];
      do {
        size_t written = source().write(b);
        if (written <= 0)
          return 0;
        b = b[written .. $];
        size_ += written;
      } while (b.length > 0);
    } while (zs_.avail_out == 0);

    return size;
  }

  override ulong seek(long offset, SeekPos origin) {
    throw new NotSupportedException;
  }

  override void flush() {
    zs_.avail_in = 0;
    zs_.next_in = null;

    bool done;
    do {
      zs_.avail_out = buffer_.length;
      zs_.next_out = cast(ubyte*)buffer_.ptr;

      int result = deflate(&zs_, Z_FINISH);
      switch (result) {
        case Z_OK:
          break;
        case Z_STREAM_END:
          done = true;
          break;
        default:
          throw new ZipException(result);
      }

      uint n = buffer_.length - zs_.avail_out;
      ubyte[] b = buffer_[0 .. n];
      do {
        size_t written = source().write(b);
        if (written <= 0)
          return;
        b = b[written .. $];
        size_ += written;
      } while (b.length > 0);
    } while (!done);

    deflateEnd(&zs_);
  }

  override ulong size() {
    return size_;
  }

}

private class CrcStream : CopyFilterStream {

  uint value;

  this(Stream source) {
    super(source);
  }

  override size_t readBlock(void* buffer, size_t size) {
    size_t n = source().readBlock(buffer, size);
    if (n != 0)
      value = etc.c.zlib.crc32(value, cast(ubyte*)buffer, n);
    return n;
  }

  override size_t writeBlock(in void* buffer, size_t size) {
    throw new NotSupportedException;
  }

}

class ZipEntry {

  private Stream input_;
  private Stream data_;
  private Stream output_;

  private ushort extractVersion_;
  private ushort bitFlag_;
  private ushort method_ = cast(ushort)-1;
  private uint lastWriteTime_ = cast(uint)-1;
  private uint crc32_;
  private uint compressedSize_;
  private uint uncompressedSize_;
  private ushort fileNameLength_;
  private ushort extraFieldLength_;

  private string fileName_;
  private ubyte[] extraField_;
  private string comment_;

  this() {
  }

  this(string fileName) {
    fileName_ = fileName;
  }

  /*Stream readStream() {
    data_ = new SliceStreamWithSize(input_, input_.position, uncompressedSize_);
    switch (method_) {
      case CompressionMethod.Stored:
        break;
      case CompressionMethod.Deflated:
        data_ = new InflateStream(data_, uncompressedSize_);
        break;
      default:
    }
    return data_;
  }

  Stream readStream() {
    if (output_ is null)
      output_ = new CopyFilterStream(new MemoryStream);
    return output_;
  }*/

  @property void method(CompressionMethod value) {
    method_ = cast(ushort)value;
  }
  @property CompressionMethod method() {
    return cast(CompressionMethod)method_;
  }

  @property void lastWriteTime(DateTime value) {
    lastWriteTime_ = dateTimeToDosDateTime(value);
  }
  @property DateTime lastWriteTime() {
    if (lastWriteTime_ == -1)
      return DateTime.now;
    return dosDateTimeToDateTime(lastWriteTime_);
  }

  @property void fileName(string value) {
    if (value.length > 0xFFFF)
      throw new ArgumentOutOfRangeException("value");

    fileName_ = value;
  }
  @property string fileName() {
    return fileName_;
  }

  @property void comment(string value) {
    if (value.length > 0xFFFF)
      throw new ArgumentOutOfRangeException("value");

    comment_ = value;
  }
  @property string comment() {
    return comment_;
  }

  @property bool isDirectory() {
    return fileName_.endsWith("/");
  }

}

final class ZipReader {

  private Stream input_;
  private Encoding encoding_;
  private Stream readStream_;

  private ZipEntry entry_;

  private string comment_;

  this(Stream input) {
    input_ = input;
    encoding_ = Encoding.get(437);

    readEndOfCentralDirectory();
  }

  void close() {
    input_.close();
  }

  ZipEntry read() {
    if (entry_ !is null)
      closeEntry();

    uint signature;
    input_.read(signature);
    if (signature != LOCAL_FILE_HEADER_SIGNATURE)
      return null;

    entry_ = new ZipEntry;
    entry_.input_ = input_;

    input_.read(entry_.extractVersion_);
    input_.read(entry_.bitFlag_);
    input_.read(entry_.method_);
    input_.read(entry_.lastWriteTime_);
    input_.read(entry_.crc32_);
    input_.read(entry_.compressedSize_);
    input_.read(entry_.uncompressedSize_);
    input_.read(entry_.fileNameLength_);
    input_.read(entry_.extraFieldLength_);

    auto temp = new ubyte[entry_.fileNameLength_];
    input_.read(temp);
    entry_.fileName_ = cast(string)encoding_.decode(temp);
    entry_.extraField_.length = entry_.extraFieldLength_;
    input_.read(entry_.extraField_);

    if ((entry_.bitFlag_ & 1 << 0) != 0)
      throw new ZipException("Encrypted zip entries are not supported.");

    return entry_;
  }
  
  Stream readStream() {
    if (entry_ is null)
      return null;

    if (readStream_ is null) {
      readStream_ = new SliceStreamWithSize(input_, input_.position, entry_.uncompressedSize_);
      switch (entry_.method_) {
        case CompressionMethod.Stored:
          break;
        case CompressionMethod.Deflated:
          readStream_ = new InflateStream(readStream_, entry_.uncompressedSize_);
          break;
        default:
      }
    }
    return readStream_;
  }

  string comment() {
    return comment_;
  }

  private void closeEntry() {
    if (entry_ is null)
      return;

    // Skip over any unread file data.
    if (entry_.data_ !is null) {
      input_.seek(entry_.compressedSize_ - entry_.data_.position, SeekPos.Current);
    }
    else {
      input_.seek(entry_.compressedSize_, SeekPos.Current);
    }
    entry_ = null;
    readStream_ = null;
  }

  private void readEndOfCentralDirectory() {
    ubyte[4096 + 22] buffer;

    ulong pos = input_.position;
    long end = cast(long)(input_.size - buffer.length);
    if (end < 0)
      end = 0;
    input_.position = end;

    size_t n = input_.read(buffer);
    for (int i = n - 22; i >= 0; i--) {
      if (i < end)
        throw new ZipException("File contains corrupt data.");

      if (buffer[i .. i + 4] == END_OF_CENTRAL_DIRECTORY_SIGNATURE_BYTES) {
        input_.position = i + 4;
        break;
      }
    }

    ushort diskNumber;
    input_.read(diskNumber);
    ushort diskNumberStart;
    input_.read(diskNumberStart);
    ushort entries;
    input_.read(entries);
    ushort entriesTotal;
    input_.read(entriesTotal);
    uint size;
    input_.read(size);
    uint offset;
    input_.read(offset);
    ushort commentLength;
    input_.read(commentLength);
    if (commentLength > 0) {
      ubyte[] temp = new ubyte[commentLength];
      input_.read(temp);
      comment_ = cast(string)encoding_.decode(temp);
    }

    if (diskNumber != diskNumberStart || entries != entriesTotal)
      throw new ZipException("Multiple-disk zip format is not supported.");

    input_.position = pos;
  }

}

/**
 * Examples:
 * ---
 * // Create a new ZipWriter with the name "backup.zip".
 * auto writer = new ZipWriter("backup.zip");
 *
 * // Create an entry named "research.doc".
 * auto entry = new ZipEntry("research.doc");
 * writer.writeStream.copyFrom(new File("research.doc"));
 *
 * // Add the new entry to the writer.
 * writer.add(entry);
 *
 * // Finalise the writer.
 * writer.close();
 * ---
 */
class ZipWriter {

  private class Entry {

    ZipEntry entry;
    uint offset;

    this(ZipEntry entry, uint offset) {
      this.entry = entry;
      this.offset = offset;
    }

  }

  private Stream output_;
  private Encoding encoding_;
  private Stream writeStream_;

  private CompressionMethod method_ = CompressionMethod.Deflated;
  private CompressionLevel level_ = CompressionLevel.Default;

  private ZipEntry entry_;
  private Entry[] entries_;

  private string comment_;

  this(Stream output) {
    output_ = output;
    encoding_ = Encoding.get(437);
  }

  void close() {
    finish();
    output_.close();
  }

  void write(ZipEntry entry) {
    entry_ = entry;

    if (entry.method_ == cast(ushort)-1)
      entry.method_ = cast(ushort)method_;
    if (entry.lastWriteTime_ == cast(uint)-1)
      entry.lastWriteTime_ = dateTimeToDosDateTime(entry.lastWriteTime);

    //entry.uncompressedSize_ = entry_.output_.size;
    entry.uncompressedSize_ = cast(uint)writeStream.size;

    auto e = new Entry(entry, cast(uint)output_.position);
    entries_ ~= e;

    output_.write(LOCAL_FILE_HEADER_SIGNATURE);
    output_.write(cast(ushort)((entry.method_ == CompressionMethod.Deflated) ? 20 : 10));
    output_.write(entry.bitFlag_);
    output_.write(entry.method_);
    output_.write(entry.lastWriteTime_);
    output_.write(entry.crc32_);
    output_.write(entry.compressedSize_);
    output_.write(entry.uncompressedSize_);

    ubyte[] fileName = encoding_.encode(entry.fileName_);
    output_.write(cast(ushort)fileName.length);
    output_.write(cast(ushort)entry.extraField_.length);
    output_.write(fileName);
    output_.write(entry.extraField_);

    //if (entry.output_ !is null) {
      Stream source = writeStream;//entry.output_;
      Stream target = output_;
      Stream deflate = null;

      switch (entry.method_) {
        case CompressionMethod.Stored:
          break;
        case CompressionMethod.Deflated:
          target = deflate = new DeflateStream(output_, level_);
          break;
        default:
      }

      scope crc = new CrcStream(source);
      source = crc;

      //copyStream(source, target);
      target.copyFrom(source);

      if (deflate !is null)
        deflate.close();

      entry.crc32_ = crc.value;
      entry.compressedSize_ = (deflate !is null) ? cast(uint)deflate.size : entry_.uncompressedSize_;

      ulong pos = output_.position;
      output_.position = e.offset + 14;

      output_.write(entry.crc32_);
      output_.write(entry.compressedSize_);
      output_.write(entry.uncompressedSize_);

      output_.position = pos;

      writeStream_ = null;
    //}
  }

  @property Stream writeStream() {
    if (writeStream_ is null)
      writeStream_ = new CopyFilterStream(new MemoryStream);
    return writeStream_;
  }

  void finish() {
    writeCentralDirectory();
  }

  private void writeCentralDirectory() {
    uint offset = cast(uint)output_.position;

    foreach (e; entries_) {
      writeCentralDirectoryEntry(e);
    }

    writeEndOfCentralDirectory(offset, cast(uint)output_.position - offset);
  }

  private void writeCentralDirectoryEntry(Entry e) {
    auto entry = e.entry;

    output_.write(CENTRAL_DIRECTORY_FILE_HEADER_SIGNATURE);
    output_.write(entry.extractVersion_);
    output_.write(entry.extractVersion_);
    output_.write(entry.bitFlag_);
    output_.write(entry.method_);
    output_.write(entry.lastWriteTime_);
    output_.write(entry.crc32_);
    output_.write(entry.compressedSize_);
    output_.write(entry.uncompressedSize_);
    ubyte[] fileName = encoding_.encode(entry.fileName_);
    output_.write(cast(ushort)fileName.length);
    output_.write(cast(ushort)entry.extraField_.length);
    ubyte[] comment = encoding_.encode(entry.comment_);
    output_.write(cast(ushort)comment.length);
    output_.write(cast(ushort)0);
    output_.write(cast(ushort)0);
    output_.write(cast(uint)0);
    output_.write(e.offset);
    output_.write(fileName);
    output_.write(entry.extraField_);
    output_.write(comment);
  }

  private void writeEndOfCentralDirectory(uint start, uint size) {
    output_.write(END_OF_CENTRAL_DIRECTORY_SIGNATURE);
    output_.write(cast(ushort)0);
    output_.write(cast(ushort)0);
    output_.write(cast(ushort)entries_.length);
    output_.write(cast(ushort)entries_.length);
    output_.write(size);
    output_.write(start);
    output_.write(cast(ushort)comment_.length);
    output_.write(encoding_.encode(comment_));
  }

  void method(CompressionMethod value) {
    method_ = value;
  }
  CompressionMethod method() {
    return method_;
  }

  void level(CompressionLevel value) {
    level_ = value;
  }
  CompressionLevel level() {
    return level_;
  }

  void comment(string value) {
    if (value.length > 0xFFFF)
      throw new ArgumentOutOfRangeException("value");

    comment_ = value;
  }
  string comment() {
    return comment_;
  }

}

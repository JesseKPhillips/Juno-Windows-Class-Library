/**
 * Provides cryptographic services including secure encoding and decoding of data, as well as hashing and 
 * random number generation.
 *
 * Copyright: (c) 2009 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.security.crypto;

import juno.base.core,
  juno.base.string,
  juno.base.collections,
  juno.base.environment,
  juno.base.native,
  juno.locale.time,
  //juno.com.core,
  std.stream;
static import std.string;
import std.c.string : memmove;
import std.c.stdlib : malloc, free;

debug import std.stdio : writefln;

extern(Windows):

// BCrypt - Vista and higher.

const wchar* BCRYPT_RSA_ALGORITHM = "RSA";
const wchar* BCRYPT_AES_ALGORITHM = "AES";
const wchar* BCRYPT_3DES_ALGORITHM = "3DES";
const wchar* BCRYPT_MD5_ALGORITHM = "MD5";
const wchar* BCRYPT_SHA1_ALGORITHM = "SHA1";
const wchar* BCRYPT_SHA256_ALGORITHM = "SHA256";
const wchar* BCRYPT_SHA384_ALGORITHM = "SHA384";
const wchar* BCRYPT_SHA512_ALGORITHM = "SHA512";
const wchar* BCRYPT_RNG_ALGORITHM = "RNG";

const wchar* MS_PRIMITIVE_PROVIDER = "Microsoft Primitive Provider";

alias DllImport!("bcrypt.dll", "BCryptOpenAlgorithmProvider", 
  int function(Handle* phAlgorithm, in wchar* pszAlgid, in wchar* pszImplementation, uint dwFlags))
  BCryptOpenAlgorithmProvider;

alias DllImport!("bcrypt.dll", "BCryptCloseAlgorithmProvider",
  int function(Handle hAlgorithm, uint dwFlags))
  BCryptCloseAlgorithmProvider;

const wchar* BCRYPT_OBJECT_LENGTH = "ObjectLength";
const wchar* BCRYPT_HASH_LENGTH   = "HashDigestLength";

alias DllImport!("bcrypt.dll", "BCryptGetProperty",
  int function(Handle hObject, in wchar* pszProperty, ubyte* pbOutput, uint cbOutput, uint* pcbResult, uint dwFlags))
  BCryptGetProperty;

alias DllImport!("bcrypt.dll", "BCryptCreateHash",
  int function(Handle hAlgorithm, Handle* phHash, ubyte* pbHashObject, uint cbHashObject, ubyte* pbSecret, uint cbSecret, uint dwFlags))
  BCryptCreateHash;

alias DllImport!("bcrypt.dll", "BCryptHashData",
  int function(Handle hHash, ubyte* pbInput, uint cbInput, uint dwFlags))
  BCryptHashData;

alias DllImport!("bcrypt.dll", "BCryptFinishHash",
  int function(Handle hHash, ubyte* pbOutput, uint cbOutput, uint dwFlags))
  BCryptFinishHash;

alias DllImport!("bcrypt.dll", "BCryptDestroyHash",
  int function(Handle hHash))
  BCryptDestroyHash;

alias DllImport!("bcrypt.dll", "BCryptGenRandom",
  int function(Handle hAlgorithm, ubyte* pbBuffer, uint cbBuffer, uint dwFlags))
  BCryptGenRandom;

extern(D):

private bool bcryptSupported() {
  static Optional!(bool) bcryptSupported_;

  if (!bcryptSupported_.hasValue) {
    Handle h = LoadLibrary("bcrypt");
    scope(exit) FreeLibrary(h);
    bcryptSupported_ = (h != Handle.init);
  }

  return bcryptSupported_.value;
}

private void blockCopy(T, TI1 = int, TI2 = TI1, TI3 = TI1)(T[] src, TI1 srcOffset, T[] dst, TI2 dstOffset, TI3 count) {
  memmove(dst.ptr + dstOffset, src.ptr + srcOffset, count * T.sizeof);
}

/**
 * The exception thrown when an error occurs during a cryptogaphic operation.
 */
class CryptoException : Exception {

  private static const E_CRYPTO = "Error occurred during a cryptographic operation";

  this() {
    super(E_CRYPTO);
  }

  this(uint errorCode) {
    this(getErrorMessage(errorCode));
  }

  this(string message) {
    super(message);
  }

  private static string getErrorMessage(uint errorCode) {
    wchar[256] buffer;
    uint result = FormatMessageW(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS, null, errorCode, 0, buffer.ptr, buffer.length + 1, null);
    if (result != 0)
      return toUtf8(buffer[0 .. result]);
    return std.string.format("Unspecified error (0x%08X)", errorCode);
  }

}

/**
 * Defines the basic operations of cryptographic transformations.
 */
interface ICryptoTransform {

  /**
   * Transforms the specified input array and copies the resulting transform to the specified output array.
   */
  uint transformBlock(ubyte[] inputBuffer, uint inputOffset, uint inputCount, ubyte[] outputBuffer, uint outputOffset);

  /**
   * Transforms the specified array.
   */
  ubyte[] transformFinalBlock(ubyte[] inputBuffer, uint inputOffset, uint inputCount);
  //ubyte[] transformFinalBlock(ubyte[] buffer);

  /**
   * Gets the input block size.
   */
  uint inputBlockSize();

  /**
   * Gets the output block size.
   */
  uint outputBlockSize();

}

/**
 * Specifies the block cipher mode to use for encryption.
 */
enum CipherMode {
  CBC = 1, /// Cipher Block Chaining.
  ECB = 2, /// Electronic Codebook.
  OFB = 3, /// Output Feedback.
  CFB = 4, /// Cipher Feedback.
  CTS = 5  /// Cipher Text Stealing.
}

/**
 * Specifies the type of padding to apply when the message data block is shorter than the full number
 * of bytes needed for a cryptographic operation.
 */
enum PaddingMode {
  None = 1,     /// No padding is done.
  PKCS7 = 2,    /// 
  Zeros = 3,    ///
  ANSIX923 = 4, ///
  ISO10126 = 5  ///
}

/**
 * Specifies the mode of a cryptographic stream.
 */
enum CryptoStreamMode {
  Read, /// _Read access to a cryptographic stream.
  Write /// _Write access to a cryptographic stream.
}

/**
 * Defines a stream that links data streams to cryptographic transformations.
 */
class CryptoStream : Stream {

  private Stream stream_;
  private ICryptoTransform transform_;
  private CryptoStreamMode transformMode_;

  private uint inputBlockSize_;
  private ubyte[] inputBuffer_;
  private uint inputBufferIndex_;
  private uint outputBlockSize_;
  private ubyte[] outputBuffer_;
  private uint outputBufferIndex_;

  private bool finalBlockTransformed_;

  /**
   * Initializes a new instance.
   */
  this(Stream stream, ICryptoTransform transform, CryptoStreamMode mode) {
    stream_ = stream;
    transform_ = transform;
    transformMode_ = mode;

    if (transformMode_ == CryptoStreamMode.Read)
      readable = true;
    else if (transformMode_ == CryptoStreamMode.Write)
      writeable = true;

    if (transform_ !is null) {
      inputBlockSize_ = transform_.inputBlockSize;
      inputBuffer_.length = inputBlockSize_;
      outputBlockSize_ = transform_.outputBlockSize;
      outputBuffer_.length = outputBlockSize_;
    }
  }

  override void close() {
    if (!finalBlockTransformed_)
      flushFinalBlock();

    stream_.close();

    inputBuffer_ = null;
    outputBuffer_ = null;
  }

  /**
   * Updates the underlying data source with the current state of the buffer.
   */
  final void flushFinalBlock() {
    //ubyte[] block = transform_.transformFinalBlock(input_);
    ubyte[] finalBytes = transform_.transformFinalBlock(inputBuffer_, 0, inputBufferIndex_);
    finalBlockTransformed_ = true;

    if (writeable && outputBufferIndex_ > 0) {
      stream_.writeBlock(outputBuffer_.ptr, outputBufferIndex_);
      outputBufferIndex_ = 0;
    }
    if (writeable)
      stream_.writeBlock(finalBytes.ptr, finalBytes.length);

    stream_.flush();

    inputBuffer_[] = 0;
    outputBuffer_[] = 0;
  }

  override void flush() {
  }

  override ulong seek(long offset, SeekPos origin) {
    throw new NotSupportedException;
  }

  override void position(ulong) {
    throw new NotSupportedException;
  }
  override ulong position() {
    throw new NotSupportedException;
  }

  override ulong size() {
    throw new NotSupportedException;
  }

  override size_t readBlock(void* buffer, size_t size) {
    uint readBytes = size;
    uint outputIndex = 0;

    if (outputBufferIndex_ > 0) {
      if (outputBufferIndex_ <= size) {
        memmove(buffer, outputBuffer_.ptr, outputBufferIndex_);
        readBytes -= outputBufferIndex_;
        outputIndex += outputBufferIndex_;
        outputBufferIndex_ = 0;
      }
      else {
        memmove(buffer, outputBuffer_.ptr, size);
        //memmove(outputBuffer_.ptr, outputBuffer_.ptr + size, outputBufferIndex_ - size);
        blockCopy(outputBuffer_, size, outputBuffer_, 0, outputBufferIndex_ - size);
        outputBufferIndex_ -= size;
        return size;
      }
    }

    if (finalBlockTransformed_)
      return size - readBytes;

    uint outputBytes;
    uint numRead;

    while (readBytes > 0) {
      while (inputBufferIndex_ < inputBlockSize_) {
        numRead = stream_.readBlock(inputBuffer_.ptr + inputBufferIndex_, inputBlockSize_ - inputBufferIndex_);
        if (numRead == 0) {
          outputBuffer_ = transform_.transformFinalBlock(inputBuffer_, 0, inputBufferIndex_);
          outputBufferIndex_ = outputBuffer_.length;
          finalBlockTransformed_ = true;

          if (readBytes < outputBufferIndex_) {
            memmove(buffer + outputIndex, outputBuffer_.ptr, readBytes);
            outputBufferIndex_ -= readBytes;
            //memmove(outputBuffer_.ptr, outputBuffer_.ptr + readBytes, outputBufferIndex_);
            blockCopy(outputBuffer_, readBytes, outputBuffer_, 0, outputBufferIndex_);
            return size;
          }
          else {
            memmove(buffer + outputIndex, outputBuffer_.ptr, outputBufferIndex_);
            readBytes -= outputBufferIndex_;
            outputBufferIndex_ = 0;
            return size - readBytes;
          }
        }
        inputBufferIndex_ += numRead;
      }

      outputBytes = transform_.transformBlock(inputBuffer_, 0, inputBlockSize_, outputBuffer_, 0);
      inputBufferIndex_ = 0;
      if (readBytes >= outputBytes) {
        memmove(buffer + outputIndex, outputBuffer_.ptr, outputBytes);
        outputIndex += outputBytes;
        readBytes -= outputBytes;
      }
      else {
        memmove(buffer + outputIndex, outputBuffer_.ptr, readBytes);
        outputBufferIndex_ = outputBytes - readBytes;
        //memmove(outputBuffer_.ptr, outputBuffer_.ptr + readBytes, outputBufferIndex_);
        blockCopy(outputBuffer_, readBytes, outputBuffer_, 0, outputBufferIndex_);
        return size;
      }
    }
    return size;
  }

  override size_t writeBlock(in void* buffer, size_t size) {
    uint writeBytes = size;
    uint inputIndex = 0;

    if (inputBufferIndex_ > 0) {
      if (size >= inputBlockSize_ - inputBufferIndex_) {
        memmove(inputBuffer_.ptr + inputBufferIndex_, buffer, inputBlockSize_ - inputBufferIndex_);
        inputIndex += (inputBlockSize_ - inputBufferIndex_);
        writeBytes -= (inputBlockSize_ - inputBufferIndex_);
        inputBufferIndex_ = inputBlockSize_;
      }
      else {
        memmove(inputBuffer_.ptr + inputBufferIndex_, buffer, size);
        inputBufferIndex_ += size;
        return size;
      }
    }

    if (outputBufferIndex_ > 0) {
      stream_.writeBlock(outputBuffer_.ptr, outputBufferIndex_);
      outputBufferIndex_ = 0;
    }

    uint outputBytes;
    if (inputBufferIndex_ == inputBlockSize_) {
      outputBytes = transform_.transformBlock(inputBuffer_, 0, inputBlockSize_, outputBuffer_, 0);
      stream_.writeBlock(outputBuffer_.ptr, outputBytes);
      inputBufferIndex_ = 0;
    }

    while (writeBytes > 0) {
      if (writeBytes >= inputBlockSize_) {
        uint wholeBlocks = writeBytes / inputBlockSize_;
        uint wholeBlocksBytes = wholeBlocks * inputBlockSize_;

        ubyte[] tempBuffer = new ubyte[wholeBlocks * outputBlockSize_];
        outputBytes = transform_.transformBlock(cast(ubyte[])buffer[0 .. size], inputIndex, wholeBlocksBytes, tempBuffer, 0);
        stream_.writeBlock(tempBuffer.ptr, outputBytes);
        inputIndex += wholeBlocksBytes;
        writeBytes -= wholeBlocksBytes;

        /*outputBytes = transform_.transformBlock(cast(ubyte[])buffer[0 .. size], inputIndex, inputBlockSize_, outputBuffer_, 0);
        stream_.writeBlock(outputBuffer_.ptr, outputBytes);
        inputIndex += inputBlockSize_;
        writeBytes -= inputBlockSize_;*/
      }
      else {
        memmove(inputBuffer_.ptr, buffer + inputIndex, writeBytes);
        inputBufferIndex_ += writeBytes;
        return size;
      }
    }
    //memmove(inputBuffer_.ptr, buffer, size);
    return size;
  }

}

/**
 * Represents the base class from which implementations of cryptographic hash algorithms derive.
 */
abstract class HashAlgorithm : ICryptoTransform, IDisposable {

  protected ubyte[] hashValue;
  protected uint hashSizeValue;

  protected this() {
  }

  ~this() {
    clear();
  }

  /**
   * Releases all resources held by this instance.
   */
  final void clear() {
    hashValue = null;
  }

  /**
   * Computes the hash for the specified data.
   */
  final ubyte[] computeHash(ubyte[] buffer, uint offset, uint count) {
    hashCore(buffer, offset, count);
    hashValue = hashFinal();

    ubyte[] hash = hashValue.dup;
    initialize();
    return hash;
  }

  /// ditto
  final ubyte[] computeHash(ubyte[] buffer) {
    return computeHash(buffer, 0, buffer.length);
  }

  /// ditto
  final ubyte[] computeHash(Stream input) {
    ubyte[] buffer = new ubyte[4096];
    uint len;
    do {
      len = input.read(buffer);
      if (len > 0)
        hashCore(buffer, 0, len);
    } while (len > 0);
    hashValue = hashFinal();

    ubyte[] hash = hashValue.dup;
    initialize();
    return hash;
  }

  /**
   * Computes the hash value for the specified input array and copies the resulting hash value to the specified output array.
   */
  final uint transformBlock(ubyte[] inputBuffer, uint inputOffset, uint inputCount, ubyte[] outputBuffer, uint outputOffset) {
    hashCore(inputBuffer, inputOffset, inputCount);
    if (outputBuffer != null && (inputBuffer != outputBuffer || inputOffset != outputOffset))
      //memmove(outputBuffer.ptr + outputOffset, inputBuffer.ptr + inputOffset, inputCount);
      blockCopy(inputBuffer, inputOffset, outputBuffer, outputOffset, inputCount);
    return inputCount;
  }

  /**
   * Computes the hash value for the specified input array.
   */
  final ubyte[] transformFinalBlock(ubyte[] inputBuffer, uint inputOffset, uint inputCount) {
    hashCore(inputBuffer, inputOffset, inputCount);
    hashValue = hashFinal();

    ubyte[] outputBuffer = new ubyte[inputCount];
    if (inputCount != 0)
      //memmove(outputBuffer.ptr, inputBuffer.ptr + inputOffset, inputCount);
      blockCopy(inputBuffer, inputOffset, outputBuffer, 0, inputCount);
    return outputBuffer;
  }

  abstract void initialize() {
  }

  protected void hashCore(ubyte[] array, uint start, uint size);

  protected ubyte[] hashFinal();

  /**
   * Gets the value of the computed _hash code.
   */
  ubyte[] hash() {
    return hashValue.dup;
  }

  /**
   * Gets the size in bits of the computed hash code.
   */
  uint hashSize() {
    return hashSizeValue;
  }

  /**
   * Gets the input block size.
   */
  uint inputBlockSize() {
    return 1;
  }

  /**
   * Gets the output block size.
   */
  uint outputBlockSize() {
    return 1;
  }

}

/**
 * Determines the set of valid key sizes for symmetric cryptographic algorithms.
 */
final class KeySizes {

  private uint min_;
  private uint max_;
  private uint skip_;

  /**
   * Initializes a new instance.
   */
  this(uint min, uint max, uint skip) {
    min_ = min;
    max_ = max;
    skip_ = skip;
  }

  /**
   * Specifies the minimum key size in bits.
   */
  uint min() {
    return min_;
  }

  /**
   * Specifies the maximum key size in bits.
   */
  uint max() {
    return max_;
  }

  /**
   * Specifies the interval between valid key sizes in bits.
   */
  uint skip() {
    return skip_;
  }

}

/**
 * The abstract base class from which implementations of symmetric algorithms derive.
 */
abstract class SymmetricAlgorithm : IDisposable {

  protected ubyte[] keyValue;
  protected uint keySizeValue;
  protected KeySizes[] legalKeySizesValue;
  protected ubyte[] ivValue;
  protected uint blockSizeValue;
  protected CipherMode modeValue = CipherMode.CBC;
  protected PaddingMode paddingValue = PaddingMode.PKCS7;//PaddingMode.Zeros;

  protected this() {
  }

  final void clear() {
    keyValue = null;
    ivValue = null;
  }

  ~this() {
    clear();
  }

  /**
   * Creates a symmetric encryptor object.
   */
  abstract ICryptoTransform createEncryptor(ubyte[] key, ubyte[] iv);

  /// ditto
  ICryptoTransform createEncryptor() {
    return createEncryptor(key, iv);
  }

  /**
   * Creates a symmetric decryptor object.
   */
  abstract ICryptoTransform createDecryptor(ubyte[] key, ubyte[] iv);

  /// ditto
  ICryptoTransform createDecryptor() {
    return createDecryptor(key, iv);
  }

  /**
   * Generates a random key to use for the algorithm.
   */
  abstract void generateKey();

  /**
   * Generates a random initialization vector to use for the algorithm.
   */
  abstract void generateIV();

  /**
   * Determines whether the specified key size is valid for the algorithm.
   */
  final bool isValidKeySize(uint bitLength) {
    foreach (keySize; legalKeySizes) {
      if (keySize.skip == 0) {
        if (keySize.min == bitLength)
          return true;
      }
      else {
        for (uint i = keySize.min; i <= keySize.max; i += keySize.skip) {
          if (i == bitLength)
            return true;
        }
      }
    }
    return false;
  }

  /**
   * Gets or sets the secret _key for the symmetric algorithm.
   */
  void key(ubyte[] value) {
    keyValue = value.dup;
    keySizeValue = value.length * 8;
  }
  /// ditto
  ubyte[] key() {
    if (keyValue == null)
      generateKey();
    return keyValue.dup;
  }

  /**
   * Gets or sets the size in bits of the secret key used by the symmetric algorithm.
   */
  void keySize(uint value) {
    if (!isValidKeySize(value))
      throw new CryptoException;

    keySizeValue = value;
    keyValue = null;
  }
  /// ditto
  uint keySize() {
    return keySizeValue;
  }

  /**
   * Gets the key sizes in bits supported by the symmetric algorithm.
   */
  KeySizes[] legalKeySizes() {
    return legalKeySizesValue.dup;
  }

  /**
   * Gets or sets the initialization vector for the symmetric algorithm.
   */
  void iv(ubyte[] value) {
    ivValue = value;
  }
  /// ditto
  ubyte[] iv() {
    if (ivValue == null)
      generateIV();
    return ivValue.dup;
  }

  /**
   * Gets or sets the block size in bits of the symmetric algorithm.
   */
  void blockSize(uint value) {
    blockSizeValue = value;
    ivValue = null;
  }
  /// ditto
  uint blockSize() {
    return blockSizeValue;
  }

  /**
   * Gets or sets the _mode of operation of the symmetric algorithm.
   */
  void mode(CipherMode value) {
    modeValue = value;
  }
  /// ditto
  CipherMode mode() {
    return modeValue;
  }

  /**
   * Gets or sets the _padding mode used in the symmetric algorithm.
   */
  void padding(PaddingMode value) {
    paddingValue = value;
  }
  /// ditto
  PaddingMode padding() {
    return paddingValue;
  }

}

/**
 * The abstract base class from which implementations of asymmetric algorithms derive.
 */
abstract class AsymmetricAlgorithm : IDisposable {

  protected KeySizes[] legalKeySizesValue;
  protected uint keySizeValue;

  protected this() {
  }

  /**
   * Gets or sets the size in bits of the key used by the asymmetric algorithm.
   */
  void keySize(uint value) {
    foreach (keySize; legalKeySizesValue) {
      if (keySize.skip == 0) {
        if (keySize.min == value) {
          keySizeValue = value;
          return;
        }
      }
      else {
        for (int i = keySize.min; i <= keySize.max; i += keySize.skip) {
          if (i == value) {
            keySizeValue = value;
            return;
          }
        }
      }
    }
    throw new CryptoException;
  }
  /// ditto
  uint keySize() {
    return keySizeValue;
  }

  /**
   * Gets the key sizes supported by the asymmetric algorithm.
   */
  KeySizes[] legalKeySizes() {
    return legalKeySizesValue.dup;
  }

  /**
   * Gets the name of the key exchange algorithm.
   */
  abstract string keyExchangeAlgorithm();

  /**
   * Gets the name of the signature algorithm.
   */
  abstract string signatureAlgorithm();

}

/**
 * Represents the abstract base class from which implementations of cryptographic random number generators derive.
 */
abstract class RandomNumberGenerator {

  protected this() {
  }

  /**
   * Fills an array with a a cryptographically strong random sequence of values.
   */
  abstract void getBytes(ubyte[] data);

  /**
   * Fills an array with a a cryptographically strong random sequence of non-zero values.
   */
  abstract void getNonZeroBytes(ubyte[] data);

}

private final class CAPIHashAlgorithm {

  private Handle provider_;
  private Handle hash_;
  private uint algorithm_;

  this(string provider, uint providerType, uint algorithm) {
    algorithm_ = algorithm;

    if (!CryptAcquireContext(provider_, null, provider.toUtf16z(), providerType, CRYPT_VERIFYCONTEXT))
      throw new CryptoException(GetLastError());

    initialize();
  }

  ~this() {
    dispose();
  }

  void dispose() {
    if (hash_ != Handle.init) {
      CryptDestroyHash(hash_);
      hash_ = Handle.init;
    }

    if (provider_ != Handle.init) {
      CryptReleaseContext(provider_, 0);
      provider_ = Handle.init;
    }
  }

  void initialize() {
    Handle newHash;
    if (!CryptCreateHash(provider_, algorithm_, Handle.init, 0, newHash))
      throw new CryptoException(GetLastError());

    if (hash_ != Handle.init)
      CryptDestroyHash(hash_);
    hash_ = newHash;
  }

  void hashCore(ubyte[] array, uint start, uint size) {
    if (!CryptHashData(hash_, array.ptr + start, size, 0))
      throw new CryptoException(GetLastError());
  }

  ubyte[] hashFinal() {
    uint cb;
    if (!CryptGetHashParam(hash_, HP_HASHVAL, null, cb, 0))
      throw new CryptoException(GetLastError());

    ubyte[] bytes = new ubyte[cb];
    if (!CryptGetHashParam(hash_, HP_HASHVAL, bytes.ptr, cb, 0))
      throw new CryptoException(GetLastError());
    return bytes;
  }

}

private final class BCryptHashAlgorithm {

  private Handle algorithm_;
  private Handle hash_;
  private Handle hashObject_;

  this(in wchar* algorithm, in wchar* implementation) {
    if (!bcryptSupported)
      throw new NotSupportedException("The specified cryptographic operation is not supported on this platform.");

    int r = BCryptOpenAlgorithmProvider(&algorithm_, algorithm, implementation, 0);
    if (r != ERROR_SUCCESS)
      throw new CryptoException(r);

    initialize();
  }

  ~this() {
    dispose();
  }

  void dispose() {
    if (hash_ != Handle.init) {
      BCryptDestroyHash(hash_);
      hash_ = Handle.init;

      if (hashObject_ != Handle.init) {
        LocalFree(hashObject_);
        hashObject_ = Handle.init;
      }
    }

    if (algorithm_ != Handle.init) {
      BCryptCloseAlgorithmProvider(algorithm_, 0);
      algorithm_ = Handle.init;
    }
  }

  void initialize() {
    uint hashObjectSize;
    uint dataSize;
    int r = BCryptGetProperty(algorithm_, BCRYPT_OBJECT_LENGTH, cast(ubyte*)&hashObjectSize, uint.sizeof, &dataSize, 0);
    if (r != ERROR_SUCCESS)
      throw new CryptoException(r);

    Handle newHash;
    Handle newHashObject = LocalAlloc(LMEM_FIXED, hashObjectSize);
    r = BCryptCreateHash(algorithm_, &newHash, cast(ubyte*)newHashObject, hashObjectSize, null, 0, 0);
    if (r != ERROR_SUCCESS)
      throw new CryptoException(r);

    if (hash_ != Handle.init) {
      BCryptDestroyHash(hash_);
      hash_ = Handle.init;

      if (hashObject_ != Handle.init) {
        LocalFree(hashObject_);
        hashObject_ = Handle.init;
      }
    }
    hash_ = newHash;
    hashObject_ = newHashObject;
  }

  void hashCore(ubyte[] array, uint start, uint size) {
    int r = BCryptHashData(hash_, array.ptr + start, size, 0);
    if (r != ERROR_SUCCESS)
      throw new CryptoException(r);
  }

  ubyte[] hashFinal() {
    uint hashSize;
    uint dataSize;
    int r = BCryptGetProperty(algorithm_, BCRYPT_HASH_LENGTH, cast(ubyte*)&hashSize, uint.sizeof, &dataSize, 0);
    if (r != ERROR_SUCCESS)
      throw new CryptoException(r);

    ubyte[] output = new ubyte[hashSize];
    r = BCryptFinishHash(hash_, output.ptr, output.length, 0);
    if (r != ERROR_SUCCESS)
      throw new CryptoException(r);
    return output;
  }

}

/**
 * The base class from which implementations of the _MD5 hash algorithms derive.
 */
abstract class Md5 : HashAlgorithm {

  protected this() {
    hashSizeValue = 128;
  }

  override string toString() {
    return "Md5";
  }

}

/**
 * Computes the $(LINK2 http://en.wikipedia.org/wiki/MD5, MD5) hash value for the input data using the implementation provided by the cryptographic service provider.
 * Examples:
 * ---
 * import juno.base.text, juno.security.crypto, std.stdio;
 * 
 * void main() {
 *   string text = "Some text to be hashed";
 *   ubyte[] textBytes = Encoding.UTF8.encode(text);
 *
 *   scope md5 = new Md5CryptoServiceProvider;
 *   ubyte[] hashedBytes = md5.computeHash(textBytes);
 *
 *   // Writes out the hashed text as r+ITAIu+cM+Csl1GW5qYSQ==
 *   string hashedText = std.base64.encode(hashedBytes);
 *   writefln(hashedText);
 * }
 * ---
 */
final class Md5CryptoServiceProvider : Md5 {

  private CAPIHashAlgorithm hashAlgorithm_;

  this() {
    hashAlgorithm_ = new CAPIHashAlgorithm(null, PROV_RSA_FULL, CALG_MD5);
  }

  ~this() {
    dispose();
  }

  void dispose() {
    if (hashAlgorithm_ !is null) {
      hashAlgorithm_.dispose();
      hashAlgorithm_ = null;
    }
  }

  override void initialize() {
    hashAlgorithm_.initialize();
  }

  protected override void hashCore(ubyte[] array, uint start, uint size) {
    hashAlgorithm_.hashCore(array, start, size);
  }

  protected override ubyte[] hashFinal() {
    return hashAlgorithm_.hashFinal();
  }

}

/**
 * Provides a CNG (Cryptography Next Generation) implementation of the MD5 hashing algorithm.
 */
final class Md5Cng : Md5 {

  private BCryptHashAlgorithm hashAlgorithm_;

  this() {
    hashAlgorithm_ = new BCryptHashAlgorithm(BCRYPT_MD5_ALGORITHM, MS_PRIMITIVE_PROVIDER);
  }

  ~this() {
    dispose();
  }

  void dispose() {
    if (hashAlgorithm_ !is null) {
      hashAlgorithm_.dispose();
      hashAlgorithm_ = null;
    }
  }

  override void initialize() {
    hashAlgorithm_.initialize();
  }

  protected override void hashCore(ubyte[] array, uint start, uint size) {
    hashAlgorithm_.hashCore(array, start, size);
  }

  protected override ubyte[] hashFinal() {
    return hashAlgorithm_.hashFinal();
  }

}

/**
 * Computes the $(LINK2 http://en.wikipedia.org/wiki/SHA, SHA1) hash value for the input data.
 */
abstract class Sha1 : HashAlgorithm {

  protected this() {
    hashSizeValue = 160;
  }

  override string toString() {
    return "Sha1";
  }

}

/**
 * Computes the $(LINK2 http://en.wikipedia.org/wiki/SHA, SHA1) hash value for the input data using the implementation provided by the cryptographic service provider.
 */
final class Sha1CryptoServiceProvider : Sha1 {

  private CAPIHashAlgorithm hashAlgorithm_;

  this() {
    hashAlgorithm_ = new CAPIHashAlgorithm(null, PROV_RSA_FULL, CALG_SHA1);
  }

  ~this() {
    dispose();
  }

  void dispose() {
    if (hashAlgorithm_ !is null) {
      hashAlgorithm_.dispose();
      hashAlgorithm_ = null;
    }
  }

  override void initialize() {
    hashAlgorithm_.initialize();
  }

  protected override void hashCore(ubyte[] array, uint start, uint size) {
    hashAlgorithm_.hashCore(array, start, size);
  }

  protected override ubyte[] hashFinal() {
    return hashAlgorithm_.hashFinal();
  }

}

/**
 * Provides a CNG (Cryptography Next Generation) implementation of the Secure Hash Algorithm (SHA).
 */
final class Sha1Cng : Sha1 {

  private BCryptHashAlgorithm hashAlgorithm_;

  this() {
    hashAlgorithm_ = new BCryptHashAlgorithm(BCRYPT_SHA1_ALGORITHM, MS_PRIMITIVE_PROVIDER);
  }

  ~this() {
    dispose();
  }

  void dispose() {
    if (hashAlgorithm_ !is null) {
      hashAlgorithm_.dispose();
      hashAlgorithm_ = null;
    }
  }

  override void initialize() {
    hashAlgorithm_.initialize();
  }

  protected override void hashCore(ubyte[] array, uint start, uint size) {
    hashAlgorithm_.hashCore(array, start, size);
  }

  protected override ubyte[] hashFinal() {
    return hashAlgorithm_.hashFinal();
  }

}

/**
 * Computes the $(LINK2 http://en.wikipedia.org/wiki/SHA, SHA256) hash value for the input data.
 */
abstract class Sha256 : HashAlgorithm {

  protected this() {
    hashSizeValue = 256;
  }

  override string toString() {
    return "Sha256";
  }

}

/**
 * Computes the $(LINK2 http://en.wikipedia.org/wiki/SHA, SHA256) hash value for the input data using the implementation provided by the cryptographic service provider.
 */
final class Sha256CryptoServiceProvider : Sha256 {

  private CAPIHashAlgorithm hashAlgorithm_;

  this() {
    hashAlgorithm_ = new CAPIHashAlgorithm(null, PROV_RSA_AES, CALG_SHA_256);
  }

  ~this() {
    dispose();
  }

  void dispose() {
    if (hashAlgorithm_ !is null) {
      hashAlgorithm_.dispose();
      hashAlgorithm_ = null;
    }
  }

  override void initialize() {
    hashAlgorithm_.initialize();
  }

  protected override void hashCore(ubyte[] array, uint start, uint size) {
    hashAlgorithm_.hashCore(array, start, size);
  }

  protected override ubyte[] hashFinal() {
    return hashAlgorithm_.hashFinal();
  }

}

/**
 * Provides a CNG (Cryptography Next Generation) implementation of the Secure Hash Algorithm (SHA) for 256-bit hash values.
 */
final class Sha256Cng : Sha256 {

  private BCryptHashAlgorithm hashAlgorithm_;

  this() {
    hashAlgorithm_ = new BCryptHashAlgorithm(BCRYPT_SHA256_ALGORITHM, MS_PRIMITIVE_PROVIDER);
  }

  ~this() {
    dispose();
  }

  void dispose() {
    if (hashAlgorithm_ !is null) {
      hashAlgorithm_.dispose();
      hashAlgorithm_ = null;
    }
  }

  override void initialize() {
    hashAlgorithm_.initialize();
  }

  protected override void hashCore(ubyte[] array, uint start, uint size) {
    hashAlgorithm_.hashCore(array, start, size);
  }

  protected override ubyte[] hashFinal() {
    return hashAlgorithm_.hashFinal();
  }

}

/**
 * Computes the $(LINK2 http://en.wikipedia.org/wiki/SHA, SHA384) hash value for the input data.
 */
abstract class Sha384 : HashAlgorithm {

  protected this() {
    hashSizeValue = 384;
  }

  override string toString() {
    return "Sha384";
  }

}

/**
 * Computes the $(LINK2 http://en.wikipedia.org/wiki/SHA, SHA384) hash value for the input data using the implementation provided by the cryptographic service provider.
 */
final class Sha384CryptoServiceProvider : Sha384 {

  private CAPIHashAlgorithm hashAlgorithm_;

  this() {
    hashAlgorithm_ = new CAPIHashAlgorithm(null, PROV_RSA_AES, CALG_SHA_384);
  }

  ~this() {
    dispose();
  }

  void dispose() {
    if (hashAlgorithm_ !is null) {
      hashAlgorithm_.dispose();
      hashAlgorithm_ = null;
    }
  }

  override void initialize() {
    hashAlgorithm_.initialize();
  }

  protected override void hashCore(ubyte[] array, uint start, uint size) {
    hashAlgorithm_.hashCore(array, start, size);
  }

  protected override ubyte[] hashFinal() {
    return hashAlgorithm_.hashFinal();
  }

}

/**
 * Provides a CNG (Cryptography Next Generation) implementation of the Secure Hash Algorithm (SHA) for 384-bit hash values.
 */
final class Sha384Cng : Sha384 {

  private BCryptHashAlgorithm hashAlgorithm_;

  this() {
    hashAlgorithm_ = new BCryptHashAlgorithm(BCRYPT_SHA384_ALGORITHM, MS_PRIMITIVE_PROVIDER);
  }

  ~this() {
    dispose();
  }

  void dispose() {
    if (hashAlgorithm_ !is null) {
      hashAlgorithm_.dispose();
      hashAlgorithm_ = null;
    }
  }

  override void initialize() {
    hashAlgorithm_.initialize();
  }

  protected override void hashCore(ubyte[] array, uint start, uint size) {
    hashAlgorithm_.hashCore(array, start, size);
  }

  protected override ubyte[] hashFinal() {
    return hashAlgorithm_.hashFinal();
  }

}

/**
 * Computes the $(LINK2 http://en.wikipedia.org/wiki/SHA, SHA512) hash value for the input data.
 */
abstract class Sha512 : HashAlgorithm {

  protected this() {
    hashSizeValue = 512;
  }

  override string toString() {
    return "Sha512";
  }

}

/**
 * Computes the $(LINK2 http://en.wikipedia.org/wiki/SHA, SHA512) hash value for the input data using the implementation provided by the cryptographic service provider.
 */
final class Sha512CryptoServiceProvider : Sha512 {

  private CAPIHashAlgorithm hashAlgorithm_;

  this() {
    hashAlgorithm_ = new CAPIHashAlgorithm(null, PROV_RSA_AES, CALG_SHA_512);
  }

  ~this() {
    dispose();
  }

  void dispose() {
    if (hashAlgorithm_ !is null) {
      hashAlgorithm_.dispose();
      hashAlgorithm_ = null;
    }
  }

  override void initialize() {
    hashAlgorithm_.initialize();
  }

  protected override void hashCore(ubyte[] array, uint start, uint size) {
    hashAlgorithm_.hashCore(array, start, size);
  }

  protected override ubyte[] hashFinal() {
    return hashAlgorithm_.hashFinal();
  }

}

/**
 * Provides a CNG (Cryptography Next Generation) implementation of the Secure Hash Algorithm (SHA) for 512-bit hash values.
 */
final class Sha512Cng : Sha512 {

  private BCryptHashAlgorithm hashAlgorithm_;

  this() {
    hashAlgorithm_ = new BCryptHashAlgorithm(BCRYPT_SHA512_ALGORITHM, MS_PRIMITIVE_PROVIDER);
  }

  ~this() {
    dispose();
  }

  void dispose() {
    if (hashAlgorithm_ !is null) {
      hashAlgorithm_.dispose();
      hashAlgorithm_ = null;
    }
  }

  override void initialize() {
    hashAlgorithm_.initialize();
  }

  protected override void hashCore(ubyte[] array, uint start, uint size) {
    hashAlgorithm_.hashCore(array, start, size);
  }

  protected override ubyte[] hashFinal() {
    return hashAlgorithm_.hashFinal();
  }

}

private enum EncryptionMode {
  Encrypt,
  Decrypt
}

/**
 * The base class from which implementations of the Triple DES algorithms derive.
 */
abstract class TripleDes : SymmetricAlgorithm {

  protected this() {
    legalKeySizesValue = [ new KeySizes(/*min*/ 128, /*max*/ 192, /*step*/ 64) ];
    keySizeValue = 192;
    blockSizeValue = 64;
  }

}

/**
 * Provides access to the cryptographic service provider implementation of the $(LINK2 http://en.wikipedia.org/wiki/Triple_DES, Triple DES) algorithm.
 */
final class TripleDesCryptoServiceProvider : TripleDes {

  private Handle provider_;
  private Handle key_;

  this() {
    if (!CryptAcquireContext(provider_, null, null, PROV_RSA_FULL, CRYPT_VERIFYCONTEXT))
      throw new CryptoException(GetLastError());
    //writefln("CryptAcquireContext");
  }

  ~this() {
    dispose();
  }

  void dispose() {
    if (key_ != Handle.init) {
      CryptDestroyKey(key_);
      key_ = Handle.init;
    }

    if (provider_ != Handle.init) {
      CryptReleaseContext(provider_, 0);
      provider_ = Handle.init;
    }
  }

  override ICryptoTransform createEncryptor() {
    if (key_ == Handle.init)
      generateKey();
    if (mode != CipherMode.ECB && ivValue == null)
      generateIV();
    return new CAPITransform(blockSizeValue, provider_, key_, ivValue, mode, paddingValue, EncryptionMode.Encrypt);
  }

  override ICryptoTransform createEncryptor(ubyte[] key, ubyte[] iv) {
    if (!isValidKeySize(key.length * 8))
      throw new ArgumentException;

    ubyte[] ivValue = (iv == null) ? null : iv.dup;
    Handle importedKey = importSymmetricKey(provider_, CALG_3DES, key.dup);
    return new CAPITransform(blockSizeValue, provider_, importedKey, ivValue, mode, paddingValue, EncryptionMode.Encrypt);
  }

  override ICryptoTransform createDecryptor() {
    if (key_ == Handle.init)
      generateKey();
    return new CAPITransform(blockSizeValue, provider_, key_, ivValue, mode, paddingValue, EncryptionMode.Decrypt);
  }

  override ICryptoTransform createDecryptor(ubyte[] key, ubyte[] iv) {
    if (!isValidKeySize(key.length * 8))
      throw new ArgumentException;

    ubyte[] ivValue = (iv == null) ? null : iv.dup;
    Handle importedKey = importSymmetricKey(provider_, CALG_3DES, key.dup);
    return new CAPITransform(blockSizeValue, provider_, importedKey, ivValue, mode, paddingValue, EncryptionMode.Decrypt);
  }

  override void generateKey() {
    Handle newKey;
    if (!CryptGenKey(provider_, CALG_3DES, CRYPT_EXPORTABLE, newKey))
      throw new CryptoException(GetLastError());

    if (key_ != Handle.init)
      CryptDestroyKey(key_);
    key_ = newKey;
    //writefln("CryptGenKey");
  }

  override void generateIV() {
    ubyte[] iv = new ubyte[8];
    if (!CryptGenRandom(provider_, iv.length, iv.ptr))
      throw new CryptoException(GetLastError());
    ivValue = iv;
  }

  override void key(ubyte[] value) {
    Handle newKey = importSymmetricKey(provider_, CALG_3DES, value.dup);
    if (key_ != Handle.init)
      CryptDestroyKey(key_);
    key_ = newKey;
    keySizeValue = value.length * 8;
  }
  override ubyte[] key() {
    if (key_ == Handle.init)
      generateKey();
    return exportSymmetricKey(key_);
  }

  override void keySize(uint value) {
    super.keySize = value;
    if (key_ != Handle.init)
      CryptDestroyKey(key_);
  }
  override uint keySize() {
    return super.keySize;
  }

}

/**
 * The base class from which implementations of the $(LINK2 http://en.wikipedia.org/wiki/Advanced_Encryption_Standard, Advanced Encryption Standard) (AES) derive.
 */
abstract class Aes : SymmetricAlgorithm {

  protected this() {
    blockSizeValue = 128;
    keySizeValue = 256;
    legalKeySizesValue = [ new KeySizes(/*min*/ 128, /*max*/ 256, /*step*/ 64) ];
  }

}

/**
 * Provides access to the cryptographic service provider implementation of the $(LINK2 http://en.wikipedia.org/wiki/Advanced_Encryption_Standard, AES) algorithm.
 * Examples:
 * ---
 * import juno.security.crypto, juno.base.text, std.stdio;
 *
 * ubyte[] encryptText(string text, ubyte[] key, ubyte[] iv) {
 *   scope aes = new AesCryptoServiceProvider;
 *
 *   scope ms = new MemoryStream;
 *   scope cs = new CryptoStream(ms, aes.createEncryptor(key, iv), CryptoStreamMode.Write);
 *
 *   ubyte[] data = Encoding.UTF8.encode(text);
 *
 *   cs.write(data);
 *   cs.flushFinalBlock();
 *
 *   ubyte[] ret = ms.data;
 *
 *   cs.close();
 *   ms.close();
 *
 *   return ret;
 * }
 *
 * ubyte[] decryptText(ubyte[] data, ubyte[] key, ubyte[] iv) {
 *   scope aes = new AesCryptoServiceProvider;
 *
 *   scope ms = new MemoryStream(data);
 *   scope cs = new CryptoStream(ms, aes.createEncryptor(key, iv), CryptoStreamMode.Read);
 *
 *   ubyte[] bytes = new ubyte[data.length];
 *
 *   cs.read(bytes);
 *
 *   return Encoding.UTF8.decode(bytes);
 * }
 *
 * void main() {
 *   string text = "Some text to encrypt.";
 *
 *   scope aes = new AesCryptoServiceProvider;
 *   ubyte[] data = encryptText(text, aes.key, aes.iv);
 *
 *   text = decryptText(data, aes.key, aes.iv);
 *   writefln(text);
 * }
 * ---
 */
final class AesCryptoServiceProvider : Aes {

  private Handle provider_;
  private Handle key_;

  this() {
    /*auto providerName = MS_ENH_RSA_AES_PROV;
    if (osVersion.major == 5 && osVersion.minor == 1)
      providerName = MS_ENH_RSA_AES_PROV_XP;*/
    if (!CryptAcquireContext(provider_, null, null, PROV_RSA_AES, CRYPT_VERIFYCONTEXT))
      throw new CryptoException(GetLastError());
    //writefln("CryptAcquireContext");

    PROV_ENUMALGS enumAlgs;
    uint enumAlgsSize = PROV_ENUMALGS.sizeof;
    for (int i = 0; ; i++) {
      if (!CryptGetProvParam(provider_, PP_ENUMALGS, cast(ubyte*)&enumAlgs, enumAlgsSize, (i == 0) ? CRYPT_FIRST : 0)) {
        uint error = GetLastError();
        if (error == ERROR_NO_MORE_ITEMS)
          break;
        else if (error != ERROR_MORE_DATA)
          throw new CryptoException(error);
      }

      if (enumAlgs.aiAlgid == 0)
        break;

      switch (enumAlgs.aiAlgid) {
        case CALG_AES_128:
          legalKeySizesValue ~= new KeySizes(128, 128, 0);
          if (keySizeValue < 128)
            keySizeValue = 128;
          break;
        case CALG_AES_192:
          legalKeySizesValue ~= new KeySizes(192, 192, 0);
          if (keySizeValue < 192)
            keySizeValue = 192;
          break;
        case CALG_AES_256:
          legalKeySizesValue ~= new KeySizes(256, 256, 0);
          if (keySizeValue < 256)
            keySizeValue = 256;
          break;
        default:
      }
    }
  }

  ~this() {
    dispose();
  }

  void dispose() {
    if (key_ != Handle.init) {
      CryptDestroyKey(key_);
      key_ = Handle.init;
    }

    if (provider_ != Handle.init) {
      CryptReleaseContext(provider_, 0);
      provider_ = Handle.init;
    }
  }

  override ICryptoTransform createEncryptor() {
    if (key_ == Handle.init)
      generateKey();
    if (mode != CipherMode.ECB && ivValue == null)
      generateIV();
    return new CAPITransform(blockSizeValue, provider_, key_, ivValue, mode, paddingValue, EncryptionMode.Encrypt);
  }

  override ICryptoTransform createEncryptor(ubyte[] key, ubyte[] iv) {
    if (!isValidKeySize(key.length * 8))
      throw new ArgumentException;

    ubyte[] ivValue = (iv == null) ? null : iv.dup;
    Handle importedKey = importSymmetricKey(provider_, algorithmId(key.length * 8), key.dup);
    return new CAPITransform(blockSizeValue, provider_, importedKey, ivValue, mode, paddingValue, EncryptionMode.Encrypt);
  }

  override ICryptoTransform createDecryptor() {
    if (key_ == Handle.init)
      generateKey();
    return new CAPITransform(blockSizeValue, provider_, key_, ivValue, mode, paddingValue, EncryptionMode.Decrypt);
  }

  override ICryptoTransform createDecryptor(ubyte[] key, ubyte[] iv) {
    if (!isValidKeySize(key.length * 8))
      throw new ArgumentException;

    ubyte[] ivValue = (iv == null) ? null : iv.dup;
    Handle importedKey = importSymmetricKey(provider_, algorithmId(key.length * 8), key.dup);
    return new CAPITransform(blockSizeValue, provider_, importedKey, ivValue, mode, paddingValue, EncryptionMode.Decrypt);
  }

  override void generateKey() {
    Handle newKey;
    if (!CryptGenKey(provider_, algorithmId(keySizeValue), CRYPT_EXPORTABLE, newKey))
      throw new CryptoException(GetLastError());

    if (key_ != Handle.init)
      CryptDestroyKey(key_);
    key_ = newKey;
    //writefln("CryptGenKey");
  }

  override void generateIV() {
    ubyte[] iv = new ubyte[blockSizeValue / 8];
    if (!CryptGenRandom(provider_, iv.length, iv.ptr))
      throw new CryptoException(GetLastError());
    ivValue = iv;
  }

  override void key(ubyte[] value) {
    Handle newKey = importSymmetricKey(provider_, algorithmId(value.length * 8), value.dup);
    if (key_ != Handle.init)
      CryptDestroyKey(key_);
    key_ = newKey;
    keySizeValue = value.length * 8;
  }
  override ubyte[] key() {
    if (key_ == Handle.init)
      generateKey();
    return exportSymmetricKey(key_);
  }

  override void keySize(uint value) {
    super.keySize = value;
    if (key_ != Handle.init)
      CryptDestroyKey(key_);
  }
  override uint keySize() {
    return super.keySize;
  }

  private static uint algorithmId(uint keySize) {
    switch (keySize) {
      case 128: return CALG_AES_128;
      case 192: return CALG_AES_192;
      case 256: return CALG_AES_256;
      default: return 0;
    }
  }

}

// PLAINTEXTKEYBLOB layout:
//   BLOBHEADER hdr
//   uint cbKey
//   ubyte[cbKey]

private ubyte[] exportSymmetricKey(Handle key) {
  uint cbData;
  if (!CryptExportKey(key, Handle.init, PLAINTEXTKEYBLOB, 0, null, cbData))
    throw new CryptoException(GetLastError());

  auto pbData = cast(ubyte*)malloc(cbData);
  if (!CryptExportKey(key, Handle.init, PLAINTEXTKEYBLOB, 0, pbData, cbData))
    throw new CryptoException(GetLastError());

  //writefln("CryptExportKey");

  ubyte[] keyBuffer = new ubyte[*cast(uint*)(pbData + BLOBHEADER.sizeof)];
  memmove(keyBuffer.ptr, pbData + BLOBHEADER.sizeof + uint.sizeof, keyBuffer.length);
  free(pbData);
  return keyBuffer;
}

private Handle importSymmetricKey(Handle provider, uint algorithm, ubyte[] key) {
  uint cbData = BLOBHEADER.sizeof + uint.sizeof + key.length;
  auto pbData = cast(ubyte*)malloc(cbData);

  auto pBlob = cast(BLOBHEADER*)pbData;
  pBlob.bType = PLAINTEXTKEYBLOB;
  pBlob.bVersion = CUR_BLOB_VERSION;
  pBlob.reserved = 0;
  pBlob.aiKeyAlg = algorithm;

  *(cast(uint*)pbData + BLOBHEADER.sizeof) = key.length;
  memmove(pbData + BLOBHEADER.sizeof + uint.sizeof, key.ptr, key.length);

  Handle importedKey;
  if (!CryptImportKey(provider, pbData, cbData, Handle.init, CRYPT_EXPORTABLE, importedKey))
    throw new CryptoException(GetLastError());

  //writefln("CryptImportKey");

  free(pbData);
  return importedKey;
}

/**
 */
abstract class Rsa : AsymmetricAlgorithm {

  protected this() {
  }

}

private static string[string] nameToHash;

static this() {
  nameToHash = [
    "MD5"[]: "juno.security.crypto.Md5CryptoServiceProvider"[],
    "SHA1": "juno.security.crypto.Sha1CryptoServiceProvider",
    "SHA256": "juno.security.crypto.Sha256CryptoServiceProvider",
    "SHA384": "juno.security.crypto.Sha384CryptoServiceProvider",
    "SHA512": "juno.security.crypto.Sha512CryptoServiceProvider"
  ];
}

private HashAlgorithm nameToHashAlgorithm(string algorithm) {
  if (auto value = algorithm.toUpper() in nameToHash) {
    return cast(HashAlgorithm)Object.factory(*value);
  }
  return null;
}

private uint oidToAlgId(string oid) {
  CRYPT_OID_INFO oidInfo;
  if (auto pOidInfo = CryptFindOIDInfo(CRYPT_OID_INFO_OID_KEY, oid.toUtf8z(), 0))
    oidInfo = *pOidInfo;
  uint algId = oidInfo.Algid;
  // Default to SHA1
  if (algId == 0)
    algId = CALG_SHA1;
  // The following not reported by CAPI
  else if (oid == "2.16.840.1.101.3.4.2.1")
    algId = CALG_SHA_256;
  else if (oid == "2.16.840.1.101.3.4.2.2")
    algId = CALG_SHA_384;
  else if (oid == "2.16.840.1.101.3.4.2.3")
    algId = CALG_SHA_512;
  return algId;
}

struct RsaParameters {

  ubyte[] exponent;
  ubyte[] modulus;
  ubyte[] p;
  ubyte[] q;
  ubyte[] dp;
  ubyte[] dq;
  ubyte[] inverseq;
  ubyte[] d;

}

/**
 */
final class RsaCryptoServiceProvider : Rsa {

  private Handle provider_;
  private Handle key_;
  private uint keySize_;

  ~this() {
    dispose();
  }

  void dispose() {
    if (key_ != Handle.init) {
      CryptDestroyKey(key_);
      key_ = Handle.init;
    }

    if (provider_ != Handle.init) {
      CryptReleaseContext(provider_, 0);
      provider_ = Handle.init;
    }
  }

  ///
  void importKeyBlob(ubyte[] keyBlob) {
    if (provider_ != Handle.init) {
      CryptReleaseContext(provider_, 0);
      provider_ = Handle.init;
    }

    if (provider_ == Handle.init) {
      if (!CryptAcquireContext(provider_, null, MS_ENHANCED_PROV, PROV_RSA_FULL, CRYPT_VERIFYCONTEXT))
        throw new CryptoException(GetLastError());
    }

    Handle exchangeKey;
    /*if (!CryptGetUserKey(provider_, AT_KEYEXCHANGE, exchangeKey)) {
      if (!CryptGenKey(provider_, AT_KEYEXCHANGE, CRYPT_EXPORTABLE, exchangeKey))
        throw new CryptoException(GetLastError());
    }
    scope(exit) {
      if (exchangeKey != Handle.init)
        CryptDestroyKey(exchangeKey);
    }*/

    // Layout of keyBlob:
    //   BLOBHEADER
    //   RSAPUBKEY
    bool isPublic = true;
    if (keyBlob[0] != PUBLICKEYBLOB)
      isPublic = false;
    if (keyBlob[8] != 'R' || keyBlob[9] != 'S' || keyBlob[10] != 'A' || keyBlob[11] != '1')
      isPublic = false;

    if (isPublic) {
      if (!CryptImportKey(provider_, keyBlob.ptr, keyBlob.length, exchangeKey, CRYPT_EXPORTABLE, key_))
        throw new CryptoException(GetLastError());
    }
    else {
    }
  }

  ///
  ubyte[] exportKeyBlob(bool includePrivateParameters) {
    ensureKeyPair();

    Handle exchangeKey;
    /*if (includePrivateParameters) {
      if (!CryptGetUserKey(provider_, AT_KEYEXCHANGE, exchangeKey)) {
        if (!CryptGenKey(provider_, AT_KEYEXCHANGE, CRYPT_EXPORTABLE, exchangeKey))
          throw new CryptoException(GetLastError());
      }
    }
    scope(exit) {
      if (exchangeKey != Handle.init)
        CryptDestroyKey(exchangeKey);
    }*/

    uint cbData;
    if (!CryptExportKey(key_, exchangeKey, includePrivateParameters ? PRIVATEKEYBLOB : PUBLICKEYBLOB, 0, null, cbData))
      throw new CryptoException(GetLastError());

    auto pbData = cast(ubyte*)malloc(cbData);
    if (!CryptExportKey(key_, exchangeKey, includePrivateParameters ? PRIVATEKEYBLOB : PUBLICKEYBLOB, 0, pbData, cbData))
      throw new CryptoException(GetLastError());
    scope(exit) free(pbData);

    return pbData[0 .. cbData].dup;
  }

  /+RsaParameters exportParameters(bool includePrivateParameters) {
    ensureKeyPair();

    Handle exchangeKey;
    /*if (includePrivateParameters) {
      if (!CryptGetUserKey(provider_, AT_KEYEXCHANGE, exchangeKey)) {
        if (!CryptGenKey(provider_, AT_KEYEXCHANGE, CRYPT_EXPORTABLE, exchangeKey))
          throw new CryptoException(GetLastError());
      }
    }
    scope(exit) {
      if (exchangeKey != Handle.init)
        CryptDestroyKey(exchangeKey);
    }*/

    // Currently failing if includePrivateParameters is true and the key was imported from importKeyBlob.

    uint cbData;
    if (!CryptExportKey(key_, exchangeKey, includePrivateParameters ? PRIVATEKEYBLOB : PUBLICKEYBLOB, 0, null, cbData))
      throw new CryptoException(GetLastError());

    auto pbData = cast(ubyte*)malloc(cbData);
    if (!CryptExportKey(key_, exchangeKey, includePrivateParameters ? PRIVATEKEYBLOB : PUBLICKEYBLOB, 0, pbData, cbData))
      throw new CryptoException(GetLastError());
    scope(exit) free(pbData);

    /*
      PUBLICKEYBLOB:

      BLOBHEADER hdr
      RSAPUBKEY rsapubkey
      BYTE modulus[rsapubkey.bitlen / 8]
    */

    auto pbKey = pbData + BLOBHEADER.sizeof;
    uint bitLen = *cast(uint*)(pbKey + uint.sizeof);

    RsaParameters rsap;
    rsap.exponent.length = 3;
    memmove(rsap.exponent.ptr, pbKey + (uint.sizeof * 2), rsap.exponent.length);
    rsap.exponent.reverse;
    rsap.modulus.length = bitLen / 8;
    memmove(rsap.modulus.ptr, pbKey + RSAPUBKEY.sizeof, rsap.modulus.length);
    rsap.modulus.reverse;

    /*
      PRIVATEKEYBLOB:

      BLOBHEADER hdr
      RSAPUBKEY rsapubkey
      BYTE modulus[rsapubkey.bitlen / 8]
      BYTE prime1[rsapubkey.bitlen / 16]
      BYTE prime2[rsapubkey.bitlen / 16]
      BYTE exponent1[rsapubkey.bitlen / 16]
      BYTE exponent2[rsapubkey.bitlen / 16]
      BYTE coefficient[rsapubkey.bitlen / 16]
      BYTE privateExponent[rsapubkey.bitlen / 8]
    */
    if (includePrivateParameters) {
      pbKey += RSAPUBKEY.sizeof + rsap.modulus.length;
      rsap.p.length = bitLen / 16;
      memmove(rsap.p.ptr, pbKey, rsap.p.length);
      rsap.p.reverse;

      pbKey += rsap.p.length;
      rsap.q.length = bitLen / 16;
      memmove(rsap.q.ptr, pbKey, rsap.q.length);
      rsap.q.reverse;

      pbKey += rsap.q.length;
      rsap.dp.length = bitLen / 16;
      memmove(rsap.dp.ptr, pbKey, rsap.dp.length);
      rsap.dp.reverse;

      pbKey += rsap.dp.length;
      rsap.dq.length = bitLen / 16;
      memmove(rsap.dq.ptr, pbKey, rsap.dq.length);
      rsap.dq.reverse;

      pbKey += rsap.dq.length;
      rsap.inverseq.length = bitLen / 16;
      memmove(rsap.inverseq.ptr, pbKey, rsap.inverseq.length);
      rsap.inverseq.reverse;

      pbKey += rsap.inverseq.length;
      rsap.d.length = bitLen / 8;
      memmove(rsap.d.ptr, pbKey, rsap.d.length);
      rsap.d.reverse;
    }

    return rsap;
  }+/

  ///
  ubyte[] encrypt(ubyte[] rgb, bool useOAEP) {
    ensureKeyPair();

    uint cb = rgb.length;
    if (!CryptEncrypt(key_, Handle.init, TRUE, useOAEP ? CRYPT_OAEP : 0, null, cb, rgb.length))
      throw new CryptoException(GetLastError());

    auto encryptedData = new ubyte[cb];
    encryptedData[0 .. rgb.length] = rgb;

    cb = rgb.length;
    if (!CryptEncrypt(key_, Handle.init, TRUE, useOAEP ? CRYPT_OAEP : 0, encryptedData.ptr, cb, encryptedData.length))
      throw new CryptoException(GetLastError());

    return encryptedData;
  }

  ///
  ubyte[] decrypt(ubyte[] rgb, bool useOAEP) {
    ensureKeyPair();

    uint cb = rgb.length;
    if (!CryptDecrypt(key_, Handle.init, TRUE, useOAEP ? CRYPT_OAEP : 0, null, cb))
      throw new CryptoException(GetLastError());

    auto decryptedData = new ubyte[cb];
    decryptedData[0 .. rgb.length] = rgb;

    cb = rgb.length;
    if (!CryptDecrypt(key_, Handle.init, TRUE, useOAEP ? CRYPT_OAEP : 0, decryptedData.ptr, cb))
      throw new CryptoException(GetLastError());
    return decryptedData;
  }

  ///
  ubyte[] signData(ubyte[] buffer, uint offset, uint count, string algorithm) {
    CRYPT_OID_INFO oidInfo;
    if (auto pOidInfo = CryptFindOIDInfo(CRYPT_OID_INFO_NAME_KEY, algorithm.toUtf16z(), 0))
      oidInfo = *pOidInfo;
    string oid = toUtf8(oidInfo.pszOID);

    scope hashAlgorithm = nameToHashAlgorithm(algorithm);
    ubyte[] hash = hashAlgorithm.computeHash(buffer, offset, count);
    return signHash(hash, oid);
  }

  /// ditto
  ubyte[] signData(ubyte[] buffer, string algorithm) {
    return signData(buffer, 0, buffer.length, algorithm);
  }

  /// ditto
  ubyte[] signData(Stream input, string algorithm) {
    CRYPT_OID_INFO oidInfo;
    if (auto pOidInfo = CryptFindOIDInfo(CRYPT_OID_INFO_NAME_KEY, algorithm.toUtf16z(), 0))
      oidInfo = *pOidInfo;
    string oid = toUtf8(oidInfo.pszOID);

    scope hashAlgorithm = nameToHashAlgorithm(algorithm);
    ubyte[] hash = hashAlgorithm.computeHash(input);
    return signHash(hash, oid);
  }

  ///
  ubyte[] signHash(ubyte[] hash, string oid) {
    ensureKeyPair();

    Handle tempHash;
    if (!CryptCreateHash(provider_, oidToAlgId(oid), Handle.init, 0, tempHash))
      throw new CryptoException(GetLastError());
    scope(exit) CryptDestroyHash(tempHash);

    uint cbSignature;
    if (!CryptSignHash(tempHash, AT_KEYEXCHANGE, null, 0, null, cbSignature)) {
      uint lastError = GetLastError();
      if (lastError != ERROR_MORE_DATA)
        throw new CryptoException(lastError);
    }

    auto signature = new ubyte[cbSignature];
    if (!CryptSignHash(tempHash, AT_KEYEXCHANGE, null, 0, signature.ptr, cbSignature))
      throw new CryptoException(GetLastError());

    return signature;
  }

  ///
  bool verifyData(ubyte[] data, string algorithm, ubyte[] signature) {
    return verifyData(data, 0, data.length, algorithm, signature);
  }

  ///
  bool verifyData(ubyte[] data, uint offset, uint count, string algorithm, ubyte[] signature) {
    CRYPT_OID_INFO oidInfo;
    if (auto pOidInfo = CryptFindOIDInfo(CRYPT_OID_INFO_NAME_KEY, algorithm.toUtf16z(), 0))
      oidInfo = *pOidInfo;
    string oid = toUtf8(oidInfo.pszOID);

    scope hashAlgorithm = nameToHashAlgorithm(algorithm);
    ubyte[] hash = hashAlgorithm.computeHash(data, offset, count);
    return verifyHash(hash, oid, signature);
  }

  ///
  bool verifyData(Stream data, string algorithm, ubyte[] signature) {
    CRYPT_OID_INFO oidInfo;
    if (auto pOidInfo = CryptFindOIDInfo(CRYPT_OID_INFO_NAME_KEY, algorithm.toUtf16z(), 0))
      oidInfo = *pOidInfo;
    string oid = toUtf8(oidInfo.pszOID);

    scope hashAlgorithm = nameToHashAlgorithm(algorithm);
    ubyte[] hash = hashAlgorithm.computeHash(data);
    return verifyHash(hash, oid, signature);
  }

  ///
  bool verifyHash(ubyte[] hash, string oid, ubyte[] signature) {
    ensureKeyPair();

    CRYPT_OID_INFO oidInfo;
    if (auto pOidInfo = CryptFindOIDInfo(CRYPT_OID_INFO_OID_KEY, oid.toUtf8z(), 0))
      oidInfo = *pOidInfo;

    Handle tempHash;
    if (!CryptCreateHash(provider_, oidInfo.Algid, Handle.init, 0, tempHash))
      throw new CryptoException(GetLastError());
    scope(exit) CryptDestroyHash(tempHash);

    if (!CryptVerifySignature(tempHash, hash.ptr, hash.length, key_, null, 0)) {
      uint lastError = GetLastError();
      if (lastError != NTE_BAD_SIGNATURE)
        throw new CryptoException(lastError);
      return false;
    }
    return true;
  }

  override uint keySize() {
    ensureKeyPair();

    uint cbKeySize = uint.sizeof;
    if (!CryptGetKeyParam(key_, KP_KEYLEN, cast(ubyte*)&keySize_, cbKeySize, 0))
        throw new CryptoException(GetLastError());
    return keySize_;
  }

  override string keyExchangeAlgorithm() {
    return "RSA-PKCS1-KeyEx";
  }

  override string signatureAlgorithm() {
    return "http://www.w3.org/2000/09/xmldsig#rsa-sha1";
  }

  private void ensureKeyPair() {
    if (key_ != Handle.init)
      return;

    if (provider_ == Handle.init) {
      if (!CryptAcquireContext(provider_, null, MS_ENHANCED_PROV, PROV_RSA_FULL, CRYPT_VERIFYCONTEXT))
        throw new CryptoException(GetLastError());
    }

    if (!CryptGetUserKey(provider_, AT_KEYEXCHANGE, key_)) {
      if (!CryptGenKey(provider_, AT_KEYEXCHANGE, CRYPT_EXPORTABLE, key_))
        throw new CryptoException(GetLastError());
    }
  }

}

/**
 */
abstract class Dsa : AsymmetricAlgorithm {

  ///
  abstract ubyte[] createSignature(ubyte[] hash);

  ///
  abstract bool verifySignature(ubyte[] hash, ubyte[] signature);

}

/**
 */
final class DsaCryptoServiceProvider : Dsa {

  private Handle provider_;
  private Handle key_;
  private uint keySize_;
  private Sha1CryptoServiceProvider hashAlgorithm_;

  this() {
    hashAlgorithm_ = new Sha1CryptoServiceProvider;
  }

  ~this() {
    dispose();
  }

  void dispose() {
    if (hashAlgorithm_ !is null) {
      hashAlgorithm_.dispose();
      hashAlgorithm_ = null;
    }

    if (key_ != Handle.init) {
      CryptDestroyKey(key_);
      key_ = Handle.init;
    }

    if (provider_ != Handle.init) {
      CryptReleaseContext(provider_, 0);
      provider_ = Handle.init;
    }
  }

  override ubyte[] createSignature(ubyte[] hash) {
    return signHash(hash, null);
  }

  override bool verifySignature(ubyte[] hash, ubyte[] signature) {
    return verifyHash(hash, null, signature);
  }

  ///
  void importKeyBlob(ubyte[] keyBlob) {
    if (provider_ != Handle.init) {
      CryptReleaseContext(provider_, 0);
      provider_ = Handle.init;
    }

    if (provider_ == Handle.init) {
      if (!CryptAcquireContext(provider_, null, MS_DEF_DSS_DH_PROV, PROV_DSS_DH, CRYPT_VERIFYCONTEXT))
        throw new CryptoException(GetLastError());
    }

    // Layout of keyBlob:
    //   BLOBHEADER
    //   DSSPUBKEY
    bool isPublic = true;
    if (keyBlob[0] != PUBLICKEYBLOB)
      isPublic = false;
    if (keyBlob[8] != 'D' || keyBlob[9] != 'S' || keyBlob[10] != 'S' || (keyBlob[11] != '1' && keyBlob[11] != '3'))
      isPublic = false;

    if (isPublic) {
      if (!CryptImportKey(provider_, keyBlob.ptr, keyBlob.length, Handle.init, /*CRYPT_EXPORTABLE*/ 0, key_))
        throw new CryptoException(GetLastError());
    }
    else {
    }
  }

  ///
  ubyte[] exportKeyBlob(bool includePrivateParameters) {
    ensureKeyPair();

    uint cbData;
    if (!CryptExportKey(key_, Handle.init, includePrivateParameters ? PRIVATEKEYBLOB : PUBLICKEYBLOB, 0, null, cbData))
      throw new CryptoException(GetLastError());

    auto pbData = cast(ubyte*)malloc(cbData);
    if (!CryptExportKey(key_, Handle.init, includePrivateParameters ? PRIVATEKEYBLOB : PUBLICKEYBLOB, 0, pbData, cbData))
      throw new CryptoException(GetLastError());
    scope(exit) free(pbData);

    return pbData[0 .. cbData].dup;
  }

  ///
  ubyte[] signData(ubyte[] buffer, uint offset, uint count) {
    ubyte[] hash = hashAlgorithm_.computeHash(buffer, offset, count);
    return signHash(hash, null);
  }

  /// ditto
  ubyte[] signData(ubyte[] buffer) {
    return signData(buffer, 0, buffer.length);
  }

  /// ditto
  ubyte[] signData(Stream input) {
    ubyte[] hash = hashAlgorithm_.computeHash(input);
    return signHash(hash, null);
  }

  ///
  ubyte[] signHash(ubyte[] hash, string oid) {
    ensureKeyPair();

    Handle tempHash;
    if (!CryptCreateHash(provider_, oidToAlgId(oid), Handle.init, 0, tempHash))
      throw new CryptoException(GetLastError());
    scope(exit) CryptDestroyHash(tempHash);

    uint cbSignature;
    if (!CryptSignHash(tempHash, AT_SIGNATURE, null, 0, null, cbSignature)) {
      uint lastError = GetLastError();
      if (lastError != ERROR_MORE_DATA)
        throw new CryptoException(lastError);
    }

    auto signature = new ubyte[cbSignature];
    if (!CryptSignHash(tempHash, AT_SIGNATURE, null, 0, signature.ptr, cbSignature))
      throw new CryptoException(GetLastError());

    return signature;
  }

  ///
  bool verifyData(ubyte[] data, ubyte[] signature) {
    return verifyData(data, 0, data.length, signature);
  }

  /// ditto
  bool verifyData(ubyte[] data, uint offset, uint count, ubyte[] signature) {
    ubyte[] hash = hashAlgorithm_.computeHash(data, offset, count);
    return verifyHash(hash, null, signature);
  }

  /// ditto
  bool verifyData(Stream data, ubyte[] signature) {
    ubyte[] hash = hashAlgorithm_.computeHash(data);
    return verifyHash(hash, null, signature);
  }

  ///
  bool verifyHash(ubyte[] hash, string oid, ubyte[] signature) {
    ensureKeyPair();

    CRYPT_OID_INFO oidInfo;
    if (auto pOidInfo = CryptFindOIDInfo(CRYPT_OID_INFO_OID_KEY, oid.toUtf8z(), 0))
      oidInfo = *pOidInfo;

    Handle tempHash;
    if (!CryptCreateHash(provider_, oidInfo.Algid, Handle.init, 0, tempHash))
      throw new CryptoException(GetLastError());
    scope(exit) CryptDestroyHash(tempHash);

    if (!CryptVerifySignature(tempHash, hash.ptr, hash.length, key_, null, 0)) {
      uint lastError = GetLastError();
      if (lastError != NTE_BAD_SIGNATURE)
        throw new CryptoException(lastError);
      return false;
    }
    return true;
  }

  override uint keySize() {
    ensureKeyPair();

    uint cbKeySize = uint.sizeof;
    if (!CryptGetKeyParam(key_, KP_KEYLEN, cast(ubyte*)&keySize_, cbKeySize, 0))
        throw new CryptoException(GetLastError());
    return keySize_;
  }

  override string keyExchangeAlgorithm() {
    return null;
  }

  override string signatureAlgorithm() {
    return "http://www.w3.org/2000/09/xmldsig#dsa-sha1";
  }

  private void ensureKeyPair() {
    if (key_ != Handle.init)
      return;

    if (provider_ == Handle.init) {
      if (!CryptAcquireContext(provider_, null, MS_DEF_DSS_DH_PROV, PROV_DSS_DH, CRYPT_VERIFYCONTEXT))
        throw new CryptoException(GetLastError());
    }

    if (!CryptGetUserKey(provider_, AT_SIGNATURE, key_)) {
      if (!CryptGenKey(provider_, AT_SIGNATURE, CRYPT_EXPORTABLE, key_))
        throw new CryptoException(GetLastError());
    }
  }

}

private final class CAPITransform : ICryptoTransform {

  private uint blockSize_;
  private Handle provider_;
  private Handle key_;
  private PaddingMode paddingMode_;
  private EncryptionMode encryptionMode_;
  private ubyte[] depadBuffer_;

  this(uint blockSize, Handle provider, Handle key, ubyte[] iv, CipherMode cipherMode, PaddingMode paddingMode, EncryptionMode encryptionMode) {
    blockSize_ = blockSize;
    provider_ = provider;
    key_ = key;
    paddingMode_ = paddingMode;
    encryptionMode_ = encryptionMode;

    if (iv == null) {
      if (cipherMode != CipherMode.ECB)
        throw new CryptoException("The cipher mode specified requires that an initialization vector be used.");
    }

    if (!CryptSetKeyParam(key, KP_MODE, cast(ubyte*)&cipherMode, 0))
      throw new CryptoException(GetLastError());

    if (cipherMode != CipherMode.ECB) {
      if (!CryptSetKeyParam(key, KP_IV, iv.ptr, 0))
        throw new CryptoException(GetLastError());
    }
  }

  ~this() {
    if (key_ != Handle.init) {
      CryptDestroyKey(key_);
      key_ = Handle.init;
    }
  }

  private uint encryptBlocks(ubyte[] buffer, uint offset, uint count) {
    uint length = count;
    if (!CryptEncrypt(key_, Handle.init, FALSE, 0, buffer.ptr + offset, length, buffer.length))
      throw new CryptoException(GetLastError());
    //writefln("CryptEncrypt");
    return length;
  }

  private uint decryptBlocks(ubyte[] buffer, uint offset, uint count) {
    uint length = count;
    if (!CryptDecrypt(key_, Handle.init, FALSE, 0, buffer.ptr + offset, length))
      throw new CryptoException(GetLastError());
    return length;
  }

  uint transformBlock(ubyte[] inputBuffer, uint inputOffset, uint inputCount, ubyte[] outputBuffer, uint outputOffset) {
    //writefln("transformBlock");
    if (encryptionMode_ == EncryptionMode.Encrypt) {
      //memmove(outputBuffer.ptr + outputOffset, inputBuffer.ptr + inputOffset, inputCount);
      blockCopy(inputBuffer, inputOffset, outputBuffer, outputOffset, inputCount);
      return encryptBlocks(outputBuffer, outputOffset, inputCount);
    }
    else {
      uint n;
      if (paddingMode_ != PaddingMode.None && paddingMode_ != PaddingMode.Zeros) {
        if (depadBuffer_ == null) {
          depadBuffer_.length = inputBlockSize;
        }
        else {
          uint c = decryptBlocks(depadBuffer_, 0, depadBuffer_.length);
          //memmove(outputBuffer.ptr + outputOffset, depadBuffer_.ptr, c);
          blockCopy(depadBuffer_, 0, outputBuffer, outputOffset, c);
          depadBuffer_[] = 0;
          outputOffset += c;
          n += c;
        }
        //memmove(depadBuffer_.ptr, inputBuffer.ptr + (inputOffset - inputCount) + depadBuffer_.length, depadBuffer_.length);
        blockCopy(inputBuffer, (inputOffset - inputCount) + depadBuffer_.length, depadBuffer_, 0, depadBuffer_.length);
        inputCount -= depadBuffer_.length;
      }

      if (inputCount > 0) {
        //memmove(outputBuffer.ptr + outputOffset, inputBuffer.ptr + inputOffset, inputCount);
        blockCopy(inputBuffer, inputOffset, outputBuffer, outputOffset, inputCount);
        n += decryptBlocks(outputBuffer, outputOffset, inputCount);
      }
      return n;
    }
  }

  ubyte[] transformFinalBlock(ubyte[] inputBuffer, uint inputOffset, uint inputCount) {

    ubyte[] padBlock(ubyte[] block, uint offset, uint count) {
      assert(block != null && count <= block.length - offset);

      ubyte[] bytes;
      uint padding = inputBlockSize - (count % inputBlockSize);
      switch (paddingMode_) {
        case PaddingMode.None:
          bytes.length = count;
          bytes[0 .. count] = block[offset .. count];
          break;

        case PaddingMode.PKCS7:
          bytes.length = count + padding;
          bytes[0 .. count] = block[offset .. count];
          bytes[count .. $] = cast(ubyte)padding;
          break;

        case PaddingMode.Zeros:
          if (padding == inputBlockSize)
            padding = 0;
          bytes.length = count + padding;
          bytes[0 .. count] = block[offset .. count];
          break;

        case PaddingMode.ANSIX923:
          bytes.length = count + padding;
          bytes[0 .. count] = block[0 .. count];
          bytes[$ - 1] = cast(ubyte)padding;
          break;

        case PaddingMode.ISO10126:
          bytes.length = count + padding;
          CryptGenRandom(provider_, bytes.length - 1, bytes.ptr);
          bytes[0 .. count] = block[0 .. count];
          bytes[$ - 1] = cast(ubyte)padding;
          break;

        default:
          throw new CryptoException("Unknown padding mode.");
      }
      return bytes;
    }

    ubyte[] depadBlock(ubyte[] block, uint offset, uint count) {
      assert(block != null && count >= block.length - offset);

      uint padding;
      switch (paddingMode_) {
        case PaddingMode.None, PaddingMode.Zeros:
          padding = 0;
          break;

        case PaddingMode.PKCS7:
          padding = cast(uint)block[offset + count - 1];
          if (0 > padding || padding > inputBlockSize)
            throw new CryptoException("Padding is invalid.");

          for (uint i = offset + count - padding; i < offset + count; i++) {
            if (block[i] != cast(ubyte)padding)
              throw new CryptoException("Padding is invalid");
          }
          break;

        case PaddingMode.ANSIX923:
          padding = cast(uint)block[offset + count - 1];
          if (0 > padding || padding > inputBlockSize)
            throw new CryptoException("Padding is invalid.");

          for (uint i = offset + count - padding; i < offset + count - 1; i++) {
            if (block[i] != 0)
              throw new CryptoException("Padding is invalid.");
          }
          break;

        case PaddingMode.ISO10126:
          padding = cast(uint)block[offset + count - 1];
          if (0 > padding || padding > inputBlockSize)
            throw new CryptoException("Padding is invalid.");
          break;

        default:
          throw new CryptoException("Unknown padding mode.");
      }

      //juno.io.core.Console.writeln(cast(int)(count - padding));
      return block[offset .. count - padding];
    }

    //writefln("transformFinalBlock");
    ubyte[] finalBytes;

    if (encryptionMode_ == EncryptionMode.Encrypt) {
      /*uint padding = inputBlockSize - (inputCount % inputBlockSize);
      bytes.length = inputCount + padding;
      memmove(bytes.ptr, inputBuffer.ptr + inputOffset, inputCount);*/
      finalBytes = padBlock(inputBuffer, inputOffset, inputCount);
      if (finalBytes.length > 0)
        encryptBlocks(finalBytes, 0, finalBytes.length);
    }
    else {
      ubyte[] temp;
      if (depadBuffer_ == null) {
        temp.length = inputCount;
        //memmove(temp.ptr, inputBuffer.ptr + inputOffset, inputCount);
        blockCopy(inputBuffer, inputOffset, temp, 0, inputCount);
      }
      else {
        temp.length = depadBuffer_.length + inputCount;
        //memmove(temp.ptr, depadBuffer_.ptr, depadBuffer_.length);
        blockCopy(depadBuffer_, 0, temp, 0, depadBuffer_.length);
        //memmove(temp.ptr + depadBuffer_.length, inputBuffer.ptr + inputOffset, inputCount);
        blockCopy(inputBuffer, inputOffset, temp, depadBuffer_.length, inputCount);
      }
      if (temp.length > 0) {
        uint c = decryptBlocks(temp, 0, temp.length);
        finalBytes = depadBlock(temp, 0, c);
      }
    }

    ubyte[] temp = new ubyte[outputBlockSize];
    uint count = 0;
    if (encryptionMode_ == EncryptionMode.Encrypt)
      CryptEncrypt(key_, Handle.init, TRUE, 0, temp.ptr, count, temp.length);
    else
      CryptDecrypt(key_, Handle.init, TRUE, 0, temp.ptr, count);
    delete temp;

    depadBuffer_ = null;

    return finalBytes;
  }

  /*ubyte[] transformFinalBlock(ubyte[] buffer) {
    ubyte[] output;

    if (encryptionMode_ == EncryptionMode.Encrypt) {
      output = new ubyte[inputBlockSize];
      memmove(output.ptr, buffer.ptr, buffer.length);

      uint count = output.length;
      if (!CryptEncrypt(key_, Handle.init, FALSE, 0, output.ptr, count, output.length))
        throw new CryptoException(GetLastError());

      writefln("CryptEncrypt");
    }
    else {
      output = new ubyte[outputBlockSize];
      memmove(output.ptr, buffer.ptr, buffer.length);

      uint count = output.length;
      if (!CryptDecrypt(key_, Handle.init, FALSE, 0, output.ptr, count))
        throw new CryptoException(GetLastError());

      writefln("CryptDecrypt");
    }

    ubyte[] temp = new ubyte[outputBlockSize];
    uint count = 0;
    if (encryptionMode_ == EncryptionMode.Encrypt)
      CryptEncrypt(key_, Handle.init, TRUE, 0, temp.ptr, count, temp.length);
    else
      CryptDecrypt(key_, Handle.init, TRUE, 0, temp.ptr, count);
    delete temp;

    return output;
  }*/

  uint inputBlockSize() {
    return blockSize_ / 8;
  }

  uint outputBlockSize() {
    return blockSize_ / 8;
  }

}

/**
 * Implements a cryptographic random number generator using the implementation provided by the cryptographic service provider.
 */
final class RngCryptoServiceProvider : RandomNumberGenerator {

  private Handle provider_;

  this() {
    if (!CryptAcquireContext(provider_, null, null, PROV_RSA_FULL, 0)) {
      if (!CryptAcquireContext(provider_, null, null, PROV_RSA_FULL, CRYPT_NEWKEYSET))
        throw new CryptoException(GetLastError());
    }
  }

  ~this() {
    if (provider_ != Handle.init) {
      CryptReleaseContext(provider_, 0);
      provider_ = Handle.init;
    }
  }

  override void getBytes(ubyte[] data) {
    if (!CryptGenRandom(provider_, data.length, data.ptr))
      throw new CryptoException(GetLastError());
  }

  override void getNonZeroBytes(ubyte[] data) {
    ubyte[] temp = new ubyte[data.length * 2];
    uint i;
    while (i < data.length) {
      getBytes(temp);
      foreach (j, b; temp) {
        if (i == data.length)
          break;
        if (b != 0)
          data[i++] = b;
      }
    }
  }

}

/**
 * Provides a CNG (Cryptography Next Generation) implementation of a cryptographic random number generator.
 */
final class RngCng : RandomNumberGenerator {

  private Handle algorithm_;

  this() {
    if (!bcryptSupported)
      throw new NotSupportedException("The specified cryptographic operation is not supported on this platform.");

    int r = BCryptOpenAlgorithmProvider(&algorithm_, BCRYPT_RNG_ALGORITHM, MS_PRIMITIVE_PROVIDER, 0);
    if (r != ERROR_SUCCESS)
      throw new CryptoException(r);
  }

  ~this() {
    if (algorithm_ != Handle.init) {
      BCryptCloseAlgorithmProvider(algorithm_, 0);
      algorithm_ = Handle.init;
    }
  }

  override void getBytes(ubyte[] data) {
    int r = BCryptGenRandom(algorithm_, data.ptr, data.length, 0);
    if (r != ERROR_SUCCESS)
      throw new CryptoException(r);
  }

  override void getNonZeroBytes(ubyte[] data) {
    ubyte[] temp = new ubyte[data.length * 2];
    uint i;
    while (i < data.length) {
      getBytes(temp);
      foreach (j, b; temp) {
        if (i == data.length)
          break;
        if (b != 0)
          data[i++] = b;
      }
    }
  }

}

/**
 */
enum DataProtectionScope {
  CurrentUser,
  LocalMachine
}

/**
 * Protects userData and returns an array representing the encrypted data.
 */
ubyte[] protectData(ubyte[] userData, ubyte[] optionalEntropy, DataProtectionScope protectionScope) {
  DATA_BLOB dataBlob, entropyBlob, resultBlob;

  dataBlob = DATA_BLOB(userData.length, userData.ptr);
  if (optionalEntropy != null)
    entropyBlob = DATA_BLOB(optionalEntropy.length, optionalEntropy.ptr);

  uint flags = CRYPTPROTECT_UI_FORBIDDEN;
  if (protectionScope == DataProtectionScope.LocalMachine)
    flags |= CRYPTPROTECT_LOCAL_MACHINE;

  if (!CryptProtectData(&dataBlob, null, &entropyBlob, null, null, flags, &resultBlob))
    throw new CryptoException(GetLastError());

  scope(exit) {
    if (resultBlob.pbData != null)
      LocalFree(resultBlob.pbData);
  }

  return resultBlob.pbData[0 .. resultBlob.cbData].dup;
}

/**
 * Unprotects protectedData and returns an array representing the unprotected data.
 */
ubyte[] unprotectData(ubyte[] protectedData, ubyte[] optionalEntropy, DataProtectionScope protectionScope) {
  DATA_BLOB dataBlob, entropyBlob, resultBlob;

  dataBlob = DATA_BLOB(protectedData.length, protectedData.ptr);
  if (optionalEntropy != null)
    entropyBlob = DATA_BLOB(optionalEntropy.length, optionalEntropy.ptr);

  uint flags = CRYPTPROTECT_UI_FORBIDDEN;
  if (protectionScope == DataProtectionScope.LocalMachine)
    flags |= CRYPTPROTECT_LOCAL_MACHINE;

  if (!CryptUnprotectData(&dataBlob, null, &entropyBlob, null, null, flags, &resultBlob))
    throw new CryptoException(GetLastError());

  scope(exit) {
    if (resultBlob.pbData != null)
      LocalFree(resultBlob.pbData);
  }

  return resultBlob.pbData[0 .. resultBlob.cbData].dup;
}

enum : uint {
  RTL_ENCRYPT_OPTION_SAME_PROCESS  = 0x0,
  RTL_ENCRYPT_OPTION_CROSS_PROCESS = 0x1,
  RTL_ENCRYPT_OPTION_SAME_LOGON    = 0x2
}

enum : uint {
  RTL_ENCRYPT_MEMORY_SIZE = 8
}

// No import library for these two functions, so we need to import them by ordinal.
extern(Windows)
alias DllImport!("advapi32.dll", "#749",
  int function(in void* pData, uint cbData, uint dwFlags)) RtlEncryptMemory;

extern(Windows)
alias DllImport!("advapi32.dll", "#750",
  int function(in void* pData, uint cbData, uint dwFlags)) RtlDecryptMemory;

/**
 */
enum MemoryProtectionScope : uint {
  SameProcess  = RTL_ENCRYPT_OPTION_SAME_PROCESS,
  CrossProcess = RTL_ENCRYPT_OPTION_CROSS_PROCESS,
  SameLogon    = RTL_ENCRYPT_OPTION_SAME_LOGON
}

/**
 * Protects userData.
 */
void protectMemory(ubyte[] userData, MemoryProtectionScope protectionScope) {
  if (userData.length == 0 || (userData.length % 16) != 0)
    throw new CryptoException("The length of the data must be a multiple of 16 bytes.");

  int status = RtlEncryptMemory(userData.ptr, userData.length, cast(uint)protectionScope);
  if (status < 0)
    throw new CryptoException(LsaNtStatusToWinError(status));
}

/**
 * Unprotects encryptedData, which was protected using protectMemory.
 */
void unprotectMemory(ubyte[] encryptedData, MemoryProtectionScope protectionScope) {
  if (encryptedData.length == 0 || (encryptedData.length % 16) != 0)
    throw new CryptoException("The length of the data must be a multiple of 16 bytes.");

  int status = RtlDecryptMemory(encryptedData.ptr, encryptedData.length, cast(uint)protectionScope);
  if (status < 0)
    throw new CryptoException(LsaNtStatusToWinError(status));
}
/**
 * Provides access to advanced GDI+ graphics functionality.
 *
 * For detailed information, refer to MSDN's documentation for the $(LINK2 http://msdn2.microsoft.com/en-us/library/system.drawing.imaging.aspx, System.Drawing.Imaging) namespace.
 *
 * Copyright: (c) 2009 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.media.imaging;

import juno.base.core,
  juno.base.string,
  juno.base.native,
  juno.com.core,
  juno.media.constants,
  juno.media.core,
  juno.media.native;

/**
 * Specifies the attributes of a bitmap image.
 */
final class BitmapData {

  int width;               /// Gets or sets the pixel _width of the Bitmap object.
  int height;              /// Gets of sets the pixel _height of the Bitmap object.
  int stride;              /// Gets or sets the _stride width of the Bitmap object.
  PixelFormat pixelFormat; /// Gets or sets the format of the pixel information in the Bitmap object.
  void* scan0;             /// Gets or sets the address of the first pixel data in the Bitmap object.
  int reserved;            /// Reserved. Do not use.

}

/**
 */
final class PropertyItem {

  int id;         ///
  uint len;       ///
  ushort type;    ///
  ubyte[] value;  //

}

/**
 */
final class ImageFormat {

  private static ImageFormat memoryBmp_;
  private static ImageFormat bmp_;
  private static ImageFormat emf_;
  private static ImageFormat wmf_;
  private static ImageFormat jpeg_;
  private static ImageFormat png_;
  private static ImageFormat gif_;
  private static ImageFormat tiff_;
  private static ImageFormat exif_;
  private static ImageFormat icon_;

  private Guid guid_;

  /**
   */
  this(Guid guid) {
    guid_ = guid;
  }

  /**
   */
  Guid guid() {
    return guid_;
  }

  /**
   */
  static ImageFormat memoryBmp() {
    if (memoryBmp_ is null)
      memoryBmp_ = new ImageFormat(Guid(0xb96b3caa, 0x0728, 0x11d3, 0x9d, 0x7b, 0x00, 0x00, 0xf8, 0x1e, 0xf3, 0x2e));
    return memoryBmp_;
  }

  /**
   */
  static ImageFormat bmp() { 
    if (bmp_ is null)
      bmp_ = new ImageFormat(Guid(0xb96b3cab, 0x0728, 0x11d3, 0x9d, 0x7b, 0x00, 0x00, 0xf8, 0x1e, 0xf3, 0x2e));
   return bmp_; 
  }

  /**
   */
  static ImageFormat emf() {
    if (emf_ is null)
      emf_ = new ImageFormat(Guid(0xb96b3cac, 0x0728, 0x11d3, 0x9d, 0x7b, 0x00, 0x00, 0xf8, 0x1e, 0xf3, 0x2e));
    return emf_;
  }

  /**
   */
  static ImageFormat wmf() { 
    if (wmf_ is null)
      wmf_ = new ImageFormat(Guid(0xb96b3cad, 0x0728, 0x11d3, 0x9d, 0x7b, 0x00, 0x00, 0xf8, 0x1e, 0xf3, 0x2e));
    return wmf_; 
  }

  /**
   */
  static ImageFormat jpeg() {
    if (jpeg_ is null)
      jpeg_ = new ImageFormat(Guid(0xb96b3cae, 0x0728, 0x11d3, 0x9d, 0x7b, 0x00, 0x00, 0xf8, 0x1e, 0xf3, 0x2e));
    return jpeg_; 
  }

  /**
   */
  static ImageFormat png() {
    if (png_ is null)
      png_ = new ImageFormat(Guid(0xb96b3caf, 0x0728, 0x11d3, 0x9d, 0x7b, 0x00, 0x00, 0xf8, 0x1e, 0xf3, 0x2e));
    return png_; 
  }

  /**
   */
  static ImageFormat gif() { 
    if (gif_ is null)
      gif_ = new ImageFormat(Guid(0xb96b3cb0, 0x0728, 0x11d3, 0x9d, 0x7b, 0x00, 0x00, 0xf8, 0x1e, 0xf3, 0x2e));
    return gif_; 
  }

  /**
   */
  static ImageFormat tiff() { 
    if (tiff_ is null)
      tiff_ = new ImageFormat(Guid(0xb96b3cb1, 0x0728, 0x11d3, 0x9d, 0x7b, 0x00, 0x00, 0xf8, 0x1e, 0xf3, 0x2e));
    return tiff_; 
  }

  /**
   */
  static ImageFormat exif() { 
    if (exif_ is null)
      exif_ = new ImageFormat(Guid(0xb96b3cb2, 0x0728, 0x11d3, 0x9d, 0x7b, 0x00, 0x00, 0xf8, 0x1e, 0xf3, 0x2e));
    return exif_; 
  }

  /**
   */
  static ImageFormat icon() { 
    if (icon_ !is null)
      icon_ = new ImageFormat(Guid(0xb96b3cb5, 0x0728, 0x11d3, 0x9d, 0x7b, 0x00, 0x00, 0xf8, 0x1e, 0xf3, 0x2e));
    return icon_; 
  }

}

/** 
 */
final class ImageCodecInfo {

  Guid clsid;                     ///
  Guid formatId;                  ///
  string codecName;               ///
  string dllName;                 ///
  string formatDescription;       ///
  string filenameExtension;       ///
  string mimeType;                ///
  ImageCodecFlags flags;          ///
  ubyte[][] signaturePatterns;    ///
  ubyte[][] signatureMasks;       ///

  /**
   */
  static ImageCodecInfo[] getImageEncoders() {
    int numEncoders, size;

    Status status = GdipGetImageEncodersSize(numEncoders, size);
    if (status != Status.OK)
      throw statusException(status);

    auto pCodecs = cast(GpImageCodecInfo*)LocalAlloc(LMEM_FIXED, size);

    status = GdipGetImageEncoders(numEncoders, size, pCodecs);
    if (status != Status.OK)
      throw statusException(status);

    auto codecs = new ImageCodecInfo[numEncoders];
    for (int i = 0; i < numEncoders; i++) {
      with (codecs[i] = new ImageCodecInfo) {
        with (pCodecs[i]) {
          clsid = Clsid;
          formatId = FormatID;
          if (CodecName) codecName = .toUtf8(CodecName);
          if (DllName) dllName = .toUtf8(DllName);
          if (FormatDescription) formatDescription = .toUtf8(FormatDescription);
          if (FilenameExtension) filenameExtension = .toUtf8(FilenameExtension);
          if (MimeType) mimeType = .toUtf8(MimeType);
          flags = cast(ImageCodecFlags)Flags;

          signaturePatterns.length = SigCount;
          signatureMasks.length = SigCount;
          for (int j = 0; j < SigCount; j++) {
            signaturePatterns[j].length = SigSize;
            signatureMasks[j].length = SigSize;
            std.c.string.memcpy(signaturePatterns[j].ptr, SigPattern + (j * SigSize), SigSize);
            std.c.string.memcpy(signatureMasks[j].ptr, SigMask + (j * SigSize), SigSize);
          }
        }
      }
    }

    LocalFree(cast(Handle)pCodecs);

    return codecs;
  }

  /**
   */
  static ImageCodecInfo[] getImageDecoders() {
    int numDecoders, size;

    Status status = GdipGetImageDecodersSize(numDecoders, size);
    if (status != Status.OK)
      throw statusException(status);

    auto pCodecs = cast(GpImageCodecInfo*)LocalAlloc(LMEM_FIXED, size);

    status = GdipGetImageDecoders(numDecoders, size, pCodecs);
    if (status != Status.OK)
      throw statusException(status);

    auto codecs = new ImageCodecInfo[numDecoders];
    for (int i = 0; i < numDecoders; i++) {
      with (codecs[i] = new ImageCodecInfo) {
        with (pCodecs[i]) {
          clsid = Clsid;
          formatId = FormatID;
          codecName = .toUtf8(CodecName);
          if (DllName) dllName = .toUtf8(DllName);
          if (FormatDescription) formatDescription = .toUtf8(FormatDescription);
          if (FilenameExtension) filenameExtension = .toUtf8(FilenameExtension);
          if (MimeType) mimeType = .toUtf8(MimeType);
          flags = cast(ImageCodecFlags)Flags;

          signaturePatterns.length = SigCount;
          signatureMasks.length = SigCount;
          for (int j = 0; j < SigCount; j++) {
            signaturePatterns[j].length = SigSize;
            signatureMasks[j].length = SigSize;
            std.c.string.memcpy(signaturePatterns[j].ptr, SigPattern + (j * SigSize), SigSize);
            std.c.string.memcpy(signatureMasks[j].ptr, SigMask + (j * SigSize), SigSize);
          }
        }
      }
    }

    LocalFree(cast(Handle)pCodecs);

    return codecs;
  }

}

/**
 */
final class Encoder {

  private static Encoder compression_;
  private static Encoder colorDepth_;
  private static Encoder scanMethod_;
  private static Encoder version_;
  private static Encoder renderMethod_;
  private static Encoder quality_;
  private static Encoder transformation_;
  private static Encoder luminanceTable_;
  private static Encoder chrominanceTable_;
  private static Encoder saveFlag_;

  private Guid guid_;

  /**
   */
  this(Guid guid) {
    guid_ = guid;
  }

  /**
   */
  Guid guid() {
    return guid_;
  }

  /**
   */
  static Encoder compression() {
    if (compression_ is null)
      compression_ = new Encoder(Guid(0xe09d739d, 0xccd4, 0x44ee, 0x8e, 0xba, 0x3f, 0xbf, 0x8b, 0xe4, 0xfc, 0x58));
    return compression_;
  }

  /**
   */
  static Encoder colorDepth() {
    if (colorDepth_ is null)
      colorDepth_ = new Encoder(Guid(0x66087055, 0xad66, 0x4c7c, 0x9a, 0x18, 0x38, 0xa2, 0x31, 0x0b, 0x83, 0x37));
    return colorDepth_;
  }

  /**
   */
  static Encoder scanMethod() {
    if (scanMethod_ is null)
      scanMethod_ = new Encoder(Guid(0x3a4e2661, 0x3109, 0x4e56, 0x85, 0x36, 0x42, 0xc1, 0x56, 0xe7, 0xdc, 0xfa));
    return scanMethod_;
  }

  /**
   */
  static Encoder _version() {
    if (version_ is null)
      version_ = new Encoder(Guid(0x24d18c76, 0x814a, 0x41a4, 0xbf, 0x53, 0x1c, 0x21, 0x9c, 0xcc, 0xf7, 0x97));
    return version_;
  }

  /**
   */
  static Encoder renderMethod() {
    if (renderMethod_ is null)
      renderMethod_ = new Encoder(Guid(0x6d42c53a, 0x229a, 0x4825, 0x8b, 0xb7, 0x5c, 0x99, 0xe2, 0xb9, 0xa8, 0xb8));
    return renderMethod_;
  }

  /**
   */
  static Encoder quality() {
    if (quality_ is null)
      quality_ = new Encoder(Guid(0x1d5be4b5, 0xfa4a, 0x452d, 0x9c, 0xdd, 0x5d, 0xb3, 0x51, 0x05, 0xe7, 0xeb));
    return quality_;
  }

  /**
   */
  static Encoder transformation() {
    if (transformation_ is null)
      transformation_ = new Encoder(Guid(0x8d0eb2d1, 0xa58e, 0x4ea8, 0xaa, 0x14, 0x10, 0x80, 0x74, 0xb7, 0xb6, 0xf9));
    return transformation_;
  }

  /**
   */
  static Encoder luminanceTable() {
    if (luminanceTable_ is null)
      luminanceTable_ = new Encoder(Guid(0xedb33bce, 0x0266, 0x4a77, 0xb9, 0x04, 0x27, 0x21, 0x60, 0x99, 0xe7, 0x17));
    return luminanceTable_;
  }

  /**
   */
  static Encoder chrominanceTable() {
    if (chrominanceTable_ is null)
      chrominanceTable_ = new Encoder(Guid(0xf2e455dc, 0x09b3, 0x4316, 0x82, 0x60, 0x67, 0x6a, 0xda, 0x32, 0x48, 0x1c));
    return chrominanceTable_;
  }

  /**
   */
  static Encoder saveFlag() {
    if (saveFlag_ is null)
      saveFlag_ = new Encoder(Guid(0x292266fc, 0xac40, 0x47bf, 0x8c,  0xfc,  0xa8,  0x5b,  0x89,  0xa6,  0x55,  0xde));
    return saveFlag_;
  }

}

/**
 */
final class EncoderParameter {

  private GUID guid_;
  private int numberOfValues_;
  private int type_;
  private void* value_;

  /**
   */
  this(Encoder encoder, int numberOfValues, int type, void* value) {
    guid_ = encoder.guid;
    numberOfValues_ = numberOfValues;
    type_ = type;
    value_ = value;
  }

  ~this() {
    dispose();
  }

  /**
   */
  void dispose() {
    if (value_ != null)
      value_ = null;
  }

  /**
   */
  void encoder(Encoder value) {
    guid_ = value.guid;
  }

  /**
   * ditto
   */
  Encoder encoder() {
    return new Encoder(guid_);
  }

  /**
   */
  int numberOfValues() {
    return numberOfValues_;
  }

  /**
   */
  EncoderParameterValueType type() {
    return cast(EncoderParameterValueType)type_;
  }

}

/**
 */
final class EncoderParameters {

  /**
   */
  EncoderParameter[] param;

  /**
   */
  this(int count = 1) {
    param.length = count;
  }

  package this(GpEncoderParameters* p) {
    param.length = p.Count;
    for (int i = 0; i < p.Count; i++) {
      param[i] = new EncoderParameter(new Encoder(p.Parameter[i].Guid), p.Parameter[i].NumberOfValues, p.Parameter[i].Type, p.Parameter[i].Value);
    }
  }

  package GpEncoderParameters* forGDIplus() {
    GpEncoderParameters* p = cast(GpEncoderParameters*)LocalAlloc(LMEM_FIXED, GpEncoderParameters.sizeof);
    p.Count = param.length;
    for (int i = 0; i < param.length; i++) {
      p.Parameter[i].Guid = param[i].guid_;
      p.Parameter[i].NumberOfValues = param[i].numberOfValues_;
      p.Parameter[i].Type = param[i].type_;
      p.Parameter[i].Value = param[i].value_;
    }
    return p;
  }

}

final class FrameDimension {

  private static FrameDimension time_;
  private static FrameDimension resolution_;
  private static FrameDimension page_;

  private Guid guid_;

  /**
   */
  this(Guid guid) {
    guid_ = guid;
  }

  /**
   */
  Guid guid() {
    return guid_;
  }

  /**
   */
  static FrameDimension time() {
    if (time_ is null)
      time_ = new FrameDimension(Guid(0x6aedbd6d, 0x3fb5, 0x418a, 0x83, 0xa6, 0x7f, 0x45, 0x22, 0x9d, 0xc8, 0x72));
    return time_;
  }

  /**
   */
  static FrameDimension resolution() {
    if (resolution_ is null)
      resolution_ = new FrameDimension(Guid(0x84236f7b, 0x3bd3, 0x428f, 0x8d, 0xab, 0x4e, 0xa1, 0x43, 0x9c, 0xa3, 0x15));
    return resolution_;
  }

  /**
   */
  static FrameDimension page() {
    if (page_ is null)
      page_ = new FrameDimension(Guid(0x7462dc86, 0x6180, 0x4c7e, 0x8e, 0x3f, 0xee, 0x73, 0x33, 0xa7, 0xa4, 0x83));
    return page_;
  }

}

/**
 */
final class ColorMatrix {

  package float[][] matrix_;

  /**
   */
  this() {
    matrix_ = [
      [ 1f, 0f, 0f, 0f, 0f ],
      [ 0f, 1f, 0f, 0f, 0f ],
      [ 0f, 0f, 1f, 0f, 0f ],
      [ 0f, 0f, 0f, 1f, 0f ],
      [ 0f, 0f, 0f, 0f, 0f ]
    ];
  }

  /**
   */
  this(float[][] newColorMatrix) {
    matrix_ = newColorMatrix;
  }

  /**
   */
  void opIndexAssign(float value, int row, int column) {
    matrix_[row][column] = value;
  }

  /**
   * ditto
   */
  float opIndex(int row, int column) {
    return matrix_[row][column];
  }

}
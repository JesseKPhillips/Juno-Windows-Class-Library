module juno.media.imaging;

private import juno.base.core,
  juno.base.string,
  juno.base.native,
  juno.media.native,
  juno.media.constants;

private import juno.media.core : Color;
private import juno.com.core : GUID;

public final class BitmapData {

  public int width;
  public int height;
  public int stride;
  public PixelFormat pixelFormat;
  public void* scan0;
  public int reserved;

}

public final class ImageFormat {

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

  private GUID guid_;

  public this(GUID guid) {
    guid_ = guid;
  }

  public GUID guid() {
    return guid_;
  }

  public static ImageFormat memoryBmp() {
    if (memoryBmp_ is null)
      memoryBmp_ = new ImageFormat(GUID(0xb96b3caa,0x0728,0x11d3,0x9d,0x7b,0x00,0x00,0xf8,0x1e,0xf3,0x2e));
    return memoryBmp_;
  }

  public static ImageFormat bmp() { 
    if (bmp_ is null)
      bmp_ = new ImageFormat(GUID(0xb96b3cab,0x0728,0x11d3,0x9d,0x7b,0x00,0x00,0xf8,0x1e,0xf3,0x2e));
   return bmp_; 
  }

  public static ImageFormat emf() {
    if (emf_ is null)
      emf_ = new ImageFormat(GUID(0xb96b3cac,0x0728,0x11d3,0x9d,0x7b,0x00,0x00,0xf8,0x1e,0xf3,0x2e));
    return emf_;
  }

  public static ImageFormat wmf() { 
    if (wmf_ is null)
      wmf_ = new ImageFormat(GUID(0xb96b3cad,0x0728,0x11d3,0x9d,0x7b,0x00,0x00,0xf8,0x1e,0xf3,0x2e));
    return wmf_; 
  }

  public static ImageFormat jpeg() {
    if (jpeg_ is null)
      jpeg_ = new ImageFormat(GUID(0xb96b3cae,0x0728,0x11d3,0x9d,0x7b,0x00,0x00,0xf8,0x1e,0xf3,0x2e));
    return jpeg_; 
  }

  public static ImageFormat png() {
    if (png_ is null)
      png_ = new ImageFormat(GUID(0xb96b3caf,0x0728,0x11d3,0x9d,0x7b,0x00,0x00,0xf8,0x1e,0xf3,0x2e));
    return png_; 
  }

  public static ImageFormat gif() { 
    if (gif_ is null)
      gif_ = new ImageFormat(GUID(0xb96b3cb0,0x0728,0x11d3,0x9d,0x7b,0x00,0x00,0xf8,0x1e,0xf3,0x2e));
    return gif_; 
  }

  public static ImageFormat tiff() { 
    if (tiff_ is null)
      tiff_ = new ImageFormat(GUID(0xb96b3cb1,0x0728,0x11d3,0x9d,0x7b,0x00,0x00,0xf8,0x1e,0xf3,0x2e));
    return tiff_; 
  }

  public static ImageFormat exif() { 
    if (exif_ is null)
      exif_ = new ImageFormat(GUID(0xb96b3cb2,0x0728,0x11d3,0x9d,0x7b,0x00,0x00,0xf8,0x1e,0xf3,0x2e));
    return exif_; 
  }

  public static ImageFormat icon() { 
    if (icon_ !is null)
      icon_ = new ImageFormat(GUID(0xb96b3cb5,0x0728,0x11d3,0x9d,0x7b,0x00,0x00,0xf8,0x1e,0xf3,0x2e));
    return icon_; 
  }

}

public final class ImageCodecInfo {

  public GUID clsid;
  public GUID formatID;
  public string codecName;
  public string dllName;
  public string formatDescription;
  public string filenameExtension;
  public string mimeType;
  public ImageCodecFlags flags;
  public ubyte[][] signaturePatterns;
  public ubyte[][] signatureMasks;

  public static ImageCodecInfo[] getImageEncoders() {
    int numEncoders = 0, size = 0;

    Status status = GdipGetImageEncodersSize(numEncoders, size);
    if (status != Status.OK)
      throw statusException(status);

    GpImageCodecInfo* pEncoders = cast(GpImageCodecInfo*)HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, size);

    status = GdipGetImageEncoders(numEncoders, size, pEncoders);
    if (status != Status.OK)
      throw statusException(status);

    ImageCodecInfo[] encoders = new ImageCodecInfo[numEncoders];
    for (int i = 0; i < numEncoders; i++) {
      encoders[i] = new ImageCodecInfo;
      encoders[i].clsid = pEncoders[i].Clsid;
      encoders[i].formatID = pEncoders[i].FormatID;
      encoders[i].codecName = .toUtf8(pEncoders[i].CodecName);
      encoders[i].dllName = .toUtf8(pEncoders[i].DllName);
      encoders[i].formatDescription = .toUtf8(pEncoders[i].FormatDescription);
      encoders[i].filenameExtension = .toUtf8(pEncoders[i].FilenameExtension);
      encoders[i].mimeType = .toUtf8(pEncoders[i].MimeType);
      encoders[i].flags = cast(ImageCodecFlags)pEncoders[i].Flags;

      encoders[i].signaturePatterns.length = pEncoders[i].SigCount;
      encoders[i].signatureMasks.length = pEncoders[i].SigCount;
      for (int j = 0; j < pEncoders[i].SigCount; j++) {
        encoders[i].signaturePatterns[j].length = pEncoders[i].SigSize;
        encoders[i].signatureMasks[j].length = pEncoders[i].SigSize;
        memcpy(encoders[i].signaturePatterns[j].ptr, pEncoders[i].SigPattern + (j * pEncoders[i].SigSize), pEncoders[i].SigSize);
        memcpy(encoders[i].signatureMasks[j].ptr, pEncoders[i].SigMask + (j * pEncoders[i].SigSize), pEncoders[i].SigSize);
      }
    }

    HeapFree(GetProcessHeap(), 0, pEncoders);

    return encoders;
  }

  private this() {
  }

}

public final class Encoder {

  private GUID guid_;

  public this(GUID guid) {
    guid_ = guid;
  }

  public GUID guid() {
    return guid_;
  }

}

public final class EncoderParameter {

  private GUID guid_;
  private int numberOfValues_;
  private int type_;
  private void* value_;

  public this(Encoder encoder, int numberOfValues, int type, void* value) {
    guid_ = encoder.guid;
    numberOfValues_ = numberOfValues;
    type_ = type;
    value_ = value;
  }

  ~this() {
    dispose();
  }

  public void dispose() {
    if (value_ != null) {
      value_ = null;
    }
  }

  public void encoder(Encoder value) {
    guid_ = value.guid;
  }

  public Encoder encoder() {
    return new Encoder(guid_);
  }

  public int numberOfValues() {
    return numberOfValues_;
  }

  public EncoderParameterValueType type() {
    return cast(EncoderParameterValueType)type_;
  }

}

public final class EncoderParameters {

  public EncoderParameter[] param;

  public this(int count = 1) {
    param.length = count;
  }

  package this(GpEncoderParameters* p) {
    param.length = p.Count;
    for (int i = 0; i < p.Count; i++) {
      param[i] = new EncoderParameter(new Encoder(p.Parameter[i].Guid), p.Parameter[i].NumberOfValues, p.Parameter[i].Type, p.Parameter[i].Value);
    }
  }

  package GpEncoderParameters* forGDIplus() {
    GpEncoderParameters* p = cast(GpEncoderParameters*)HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, GpEncoderParameters.sizeof);
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

public final class ColorPalette {

  private int flags_;
  private Color[] entries_;

  package this(int count) {
    entries_ = new Color[count];
  }

  package this(GpColorPalette* p) {
    flags_ = p.Flags;
    entries_ = new Color[p.Count];
    for (int i = 0; i < p.Count; i++) {
      entries_[i] = Color.fromArgb(p.Entries[i]);
    }
  }

  package GpColorPalette* forGDIplus() {
    GpColorPalette* p = cast(GpColorPalette*)HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, 4 * (entries_.length + 2));
    p.Flags = flags_;
    p.Count = entries_.length;
    for (int i = 0; i < entries_.length; i++) {
      p.Entries[i] = entries_[i].toArgb();
    }
    return p;
  }

  public int flags() {
    return flags_;
  }

  public Color[] entries() {
    return entries_;
  }

}

public final class PropertyItem {

  public int id;
  public int length;
  public short type;
  public ubyte[] value;

}

public final class FrameDimension {

  private static FrameDimension time_;
  private static FrameDimension resolution_;
  private static FrameDimension page_;

  private GUID guid_;

  /*static ~this() {
    time_ = null;
    resolution_ = null;
    page_ = null;
  }*/

  public this(GUID guid) {
    guid_ = guid;
  }

  public GUID guid() {
    return guid_;
  }

  public static FrameDimension time() {
    if (time_ is null)
      time_ = new FrameDimension(GUID(0x6aedbd6d, 0x3fb5, 0x418a, 0x83, 0xa6, 0x7f, 0x45, 0x22, 0x9d, 0xc8, 0x72));
    return time_;
  }

  public static FrameDimension resolution() {
    if (resolution_ is null)
      resolution_ = new FrameDimension(GUID(0x84236f7b, 0x3bd3, 0x428f, 0x8d, 0xab, 0x4e, 0xa1, 0x43, 0x9c, 0xa3, 0x15));
    return resolution_;
  }

  public static FrameDimension page() {
    if (page_ is null)
      page_ = new FrameDimension(GUID(0x7462dc86, 0x6180, 0x4c7e, 0x8e, 0x3f, 0xee, 0x73, 0x33, 0xa7, 0xa4, 0x83));
    return page_;
  }

}

public final class ColorMatrix {

  package float[][] matrix_;

  public this() {
    matrix_ = new float[][](5, 5);
    matrix_[0][0] = 1f;
    matrix_[1][1] = 1f;
    matrix_[2][2] = 1f;
    matrix_[3][3] = 1f;
    matrix_[4][4] = 1f;
  }

  public this(float[][] newColorMatrix) {
    matrix_ = newColorMatrix;
  }

  public void opIndexAssign(float value, int row, int column) {
    matrix_[row][column] = value;
  }

  public float opIndex(int row, int column) {
    return matrix_[row][column];
  }

}

public final class ColorMap {

  public Color oldColor;
  public Color newColor;

}

public final class ImageAttributes {

  private Handle nativeImageAttributes_;

  public this() {
    Status status = GdipCreateImageAttributes(nativeImageAttributes_);
    if (status != Status.OK)
      throw statusException(status);
  }

  ~this() {
    dispose();
  }

  package Handle nativeImageAttributes() {
    return nativeImageAttributes_;
  }

  public void dispose() {
    if (nativeImageAttributes_ != Handle.init) {
      GdipDisposeImageAttributesSafe(nativeImageAttributes_);
      nativeImageAttributes_ = Handle.init;
    }
  }

  public void setColorMatrix(ColorMatrix newColorMatrix, ColorMatrixFlag mode = ColorMatrixFlag.Default, ColorAdjustType type = ColorAdjustType.Default) {
    GpColorMatrix m;
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 5; j++)
        m.m[i][j] = newColorMatrix[i, j];
    }

    Status status = GdipSetImageAttributesColorMatrix(nativeImageAttributes_, type, 1, &m, null, mode);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void clearColorMatrix(ColorAdjustType type = ColorAdjustType.Default) {
    Status status = GdipSetImageAttributesColorMatrix(nativeImageAttributes_, type, 0, null, null, ColorMatrixFlag.Default);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void setColorMatrices(ColorMatrix newColorMatrix, ColorMatrix grayMatrix, ColorMatrixFlag mode = ColorMatrixFlag.Default, ColorAdjustType type = ColorAdjustType.Default) {
    GpColorMatrix nm, gm;
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 5; j++) {
        nm.m[i][j] = newColorMatrix[i, j];
        gm.m[i][j] = grayMatrix[i, j];
      }
    }

    Status status = GdipSetImageAttributesColorMatrix(nativeImageAttributes_, type, 1, &nm, &gm, mode);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void setThreshold(float threshold, ColorAdjustType type = ColorAdjustType.Default) {
    Status status = GdipSetImageAttributesThreshold(nativeImageAttributes_, type, 1, threshold);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void clearThreshold(ColorAdjustType type = ColorAdjustType.Default) {
    Status status = GdipSetImageAttributesThreshold(nativeImageAttributes_, type, 0, 0);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void setGamma(float gamma, ColorAdjustType type = ColorAdjustType.Default) {
    Status status = GdipSetImageAttributesGamma(nativeImageAttributes_, type, 1, gamma);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void clearGamma(ColorAdjustType type = ColorAdjustType.Default) {
    Status status = GdipSetImageAttributesGamma(nativeImageAttributes_, type, 0, 0);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void setNoOp(ColorAdjustType type = ColorAdjustType.Default) {
    Status status = GdipSetImageAttributesNoOp(nativeImageAttributes_, type, 1);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void clearNoOp(ColorAdjustType type = ColorAdjustType.Default) {
    Status status = GdipSetImageAttributesNoOp(nativeImageAttributes_, type, 0);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void setColorKey(Color colorLow, Color colorHigh, ColorAdjustType type = ColorAdjustType.Default) {
    Status status = GdipSetImageAttributesColorKeys(nativeImageAttributes_, type, 1, colorLow.toArgb(), colorHigh.toArgb());
    if (status != Status.OK)
      throw statusException(status);
  }

  public void clearColorKey(ColorAdjustType type = ColorAdjustType.Default) {
    Status status = GdipSetImageAttributesColorKeys(nativeImageAttributes_, type, 0, 0, 0);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void setOutputChannel(ColorChannelFlag flags, ColorAdjustType type = ColorAdjustType.Default) {
    Status status = GdipSetImageAttributesOutputChannel(nativeImageAttributes_, type, 1, flags);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void clearOutputChannel(ColorAdjustType type = ColorAdjustType.Default) {
    Status status = GdipSetImageAttributesOutputChannel(nativeImageAttributes_, type, 0, ColorChannelFlag.ColorChannelLast);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void setOutputChannelColorProfile(string colorProfileFileName, ColorAdjustType type = ColorAdjustType.Default) {
    Status status = GdipSetImageAttributesOutputChannelColorProfile(nativeImageAttributes_, type, 1, colorProfileFileName.toUtf16z());
    if (status != Status.OK)
      throw statusException(status);
  }

  public void clearOutputChannelColorProfile(ColorAdjustType type = ColorAdjustType.Default) {
    Status status = GdipSetImageAttributesOutputChannelColorProfile(nativeImageAttributes_, type, 0, null);
    if (status != Status.OK)
      throw statusException(status);
  }

  public void setWrapMode(WrapMode mode, Color color = Color.init, bool clamp = false) {
    Status status = GdipSetImageAttributesWrapMode(nativeImageAttributes_, mode, color.toArgb(), (clamp ? 1 : 0));
    if (status != Status.OK)
      throw statusException(status);
  }

}
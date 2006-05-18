module juno.com.reflect;

private import juno.base.core,
  juno.base.text,
  juno.com.core,
  juno.com.client,
  juno.utils.registry;

package bool checkHResult(int hr, bool throwException = true) {
  if (hr != S_OK && throwException)
    throw new COMException(hr);
  return (hr == S_OK);
}

// Check if the name if reserved word such as a keyword.
package bool isReservedWord(char[] name) {

  const char[][] RESERVEDWORDS = [
    "abstract", "alias", "align", "asm", "assert", "auto", 
    "bit", "body",  "bool", "break", "byte",
    "case", "cast", "catch", "cdouble", "cent", "cfloat",	"char",	"class", "const", "continue",	"creal",
    "dchar", "debug",	"default", "delegate", "delete", "deprecated", "do", "double",
	  "else",	"enum",	"export",	"extern",	
    "false", "final", "finally", "float",	"for", "foreach",	"function",
	  "goto",
	  "idouble", "if", "ifloat", "import", "in", "inout", "int", "interface", "invariant", "ireal", "is",
	  "long",
	  "mixin", "module",
	  "new", "null",
	  "out", "override", 
    "package", "pragma", "private", "protected", "public",
	  "real", "return", 
    "scope", "short", "static", "struct", "super", "switch", "synchronized",
	  "template", "this", "throw", "true", "try", "typedef", "typeid", "typeof", 
    "ubyte", "ucent", "uint", "ulong", "union", "unittest", "ushort",
    "version", "void", "volatile", 
    "wchar", "while", "with"
  ];

  foreach (word; RESERVEDWORDS) {
    if (word == name)
      return true;
  }
  return false;
}

alias bool delegate(Type type) TypeFilter;
alias bool delegate(MemberInfo member) MemberFilter;

public class TypeLibrary {

  private ITypeLib typeLib_;
  private char[] name_;
  private char[] helpString_;
  private GUID guid_;
  private Version version_;
  private Type[] types_;
  private Module[] modules_;

  public Type[] findTypes(TypeFilter filter) {
    Type[] filteredTypes;
    foreach (Type type; getTypes()) {
      if (filter(type))
        filteredTypes ~= type;
    }
    return filteredTypes;
  }

  public Type[] getTypes() {
    if (types_ is null) {
      ITypeInfo typeInfo;
      TYPEKIND typeKind;
      TYPEATTR* typeAttr;

      for (uint i = 0; i < typeLib_.GetTypeInfoCount(); i++) {
        int hr = typeLib_.GetTypeInfo(i, typeInfo);
        hr = typeLib_.GetTypeInfoType(i, typeKind);
        hr = typeInfo.GetTypeAttr(typeAttr);

        switch (typeKind) {
          case TYPEKIND.TKIND_COCLASS:
            types_ ~= new TypeImpl(typeInfo, TypeAttributes.CoClass, this);
            break;
          case TYPEKIND.TKIND_INTERFACE:
            TypeAttributes attr = TypeAttributes.Interface;
            if ((typeAttr.wTypeFlags & TYPEFLAGS.TYPEFLAG_FDUAL) != 0)
              attr |= TypeAttributes.Dual;
            types_ ~= new TypeImpl(typeInfo, attr, this);
            break;
          case TYPEKIND.TKIND_DISPATCH:
            TypeAttributes attr = TypeAttributes.Interface | TypeAttributes.Dispatch;
            if ((typeAttr.wTypeFlags & TYPEFLAGS.TYPEFLAG_FDUAL) != 0)
              attr |= TypeAttributes.Dual;
            uint refType;
            typeInfo.GetRefTypeOfImplType(-1, refType);
            if (refType != 0) {
              ITypeInfo refTypeInfo;
              typeInfo.GetRefTypeInfo(refType, refTypeInfo);
              types_ ~= new TypeImpl(typeInfo, refTypeInfo, attr, this);
              refTypeInfo.Release();
              break;
            }
            types_ ~= new TypeImpl(typeInfo, attr, this);
            break;
          case TYPEKIND.TKIND_RECORD:
            types_ ~= new TypeImpl(typeInfo, TypeAttributes.Struct, this);
            break;
          case TYPEKIND.TKIND_UNION:
            types_ ~= new TypeImpl(typeInfo, TypeAttributes.Union, this);
            break;
          case TYPEKIND.TKIND_ALIAS:
            types_ ~= new TypeImpl(typeInfo, TypeAttributes.Alias, this);
            break;
          case TYPEKIND.TKIND_ENUM:
            types_ ~= new TypeImpl(typeInfo, TypeAttributes.Enum, this);
            break;
          default:
            break;
        }

        typeInfo.ReleaseTypeAttr(typeAttr);
        typeInfo.Release();
      }
    }
    if (types_ is null)
      types_ = new Type[0];
    return types_;
  }

  public Module[] getModules() {
    if (modules_ is null) {
      int hr;
      for (uint i = 0; i < typeLib_.GetTypeInfoCount(); i++) {
        TYPEKIND typeKind;
        hr = typeLib_.GetTypeInfoType(i, typeKind);
        checkHResult(hr);
        if (typeKind == TYPEKIND.TKIND_MODULE) {
          ITypeInfo typeInfo;
          hr = typeLib_.GetTypeInfo(i, typeInfo);
          checkHResult(hr);
          modules_ ~= new Module(typeInfo, this);
          typeInfo.Release();
        }
      }
    }
    else
      modules_ = new Module[0];
    return modules_;
  }

  public static TypeLibrary load(char[] fileNameOrGuid) {
    ITypeLib typeLib;
    // Try to load from a file.
    if (LoadTypeLib(fileNameOrGuid.toUtf16z(), typeLib) != S_OK) {
      // If that failed, try to load from the registry.
      // We're not using LoadRegTypeLib because we'll enumerate the versions ourself.

      // Fix the GUID so it's in the expected format.
      if (fileNameOrGuid[0] != '{')
        fileNameOrGuid = '{' ~ fileNameOrGuid;
      if (fileNameOrGuid[$ - 1] != '}')
        fileNameOrGuid ~= '}';
      auto RegistryKey typeLibKey = Registry.classesRoot.openSubKey("TypeLib\\" ~ fileNameOrGuid);
      if (typeLibKey !is null && typeLibKey.subKeyCount > 0) {
        // The sub keys are the version numbers of the type library.
        char[][] subKeyNames = typeLibKey.getSubKeyNames();
        // It's the last one we want.
        auto RegistryKey subKey = typeLibKey.openSubKey(subKeyNames[$ - 1]);
        if (subKey !is null && subKey.subKeyCount > 0) {
          subKeyNames = subKey.getSubKeyNames();
          // The next list of sub keys represents the locale ID. Let's just take the first and hope for the best.
          auto RegistryKey win32Key = subKey.openSubKey(subKeyNames[0] ~ "\\win32");
          // The value is the path to the DLL.
          if (win32Key !is null)
            return load(win32Key.getStringValue(null));
        }
      }
      // If we get here, we couldn't find it either way.
      throw new Exception("Could not load the specified type library.");
    }

    TypeLibrary typeLibrary = new TypeLibrary(typeLib);
    if (typeLib !is null)
      typeLib.Release();
    return typeLibrary;
  }

  public char[] name() {
    return name_;
  }

  public char[] helpString() {
    return helpString_;
  }

  public GUID guid() {
    return guid_;
  }

  public Version getVersion() {
    return version_;
  }

  private this(ITypeLib typeLib) {
    typeLib_ = cast(ITypeLib)releasingRef(typeLib);
    typeLib_.AddRef();

    // Get the library name and help string.
    wchar* bstrName, bstrHelpString;
    int hr = typeLib_.GetDocumentation(-1, &bstrName, &bstrHelpString, null, null);
    checkHResult(hr);

    name_ = bstrToUtf8(bstrName);
    helpString_ = bstrToUtf8(bstrHelpString);

    // Get the GUID and version.
    TLIBATTR* libAttr;
    hr = typeLib_.GetLibAttr(libAttr);
    checkHResult(hr);
    guid_ = libAttr.guid;
    version_ = Version(libAttr.wMajorVerNum, libAttr.wMinorVerNum);
    typeLib_.ReleaseTLibAttr(libAttr);
  }

}

public class Module {

  private TypeLibrary library_;
  private MemberInfo[] members_;
  private FieldInfo[] fields_;

  private ITypeInfo typeInfo_;

  public MemberInfo[] getMembers() {
    if (members_ is null) {
      TYPEATTR* typeAttr;
      int hr = typeInfo_.GetTypeAttr(typeAttr);
      checkHResult(hr);

      VARDESC* varDesc;
      for (uint i = 0; i < typeAttr.cVars; i++) {
        hr = typeInfo_.GetVarDesc(i, varDesc);
        checkHResult(hr);

        if (varDesc.varkind == VARKIND.VAR_CONST) {
          wchar* bstrName;
          uint n;
          hr = typeInfo_.GetNames(varDesc.memid, &bstrName, 1, &n);
          checkHResult(hr);

          members_ ~= new FieldInfoImpl(new TypeImpl(TypeImpl.getTypeName(&varDesc.elemdescVar.tdesc, typeInfo_), library_), bstrToUtf8(bstrName), *varDesc.lpvarValue, cast(FieldAttributes)varDesc.varkind);
        }
      }
    }
    else
      members_ = new MemberInfo[0];
    return members_;
  }

  public FieldInfo[] getFields() {
    if (fields_ is null) {
      foreach (MemberInfo member; getMembers()) {
        if ((member.memberType & MemberTypes.Field) != 0)
          fields_ ~= cast(FieldInfo)member;
      }
    }
    else
      fields_ ~= new FieldInfo[0];
    return fields_;
  }

  package this(ITypeInfo typeInfo, TypeLibrary library) {
    typeInfo_ = cast(ITypeInfo)releasingRef(typeInfo);
    typeInfo_.AddRef();
  }

}

public enum MemberTypes {
  Field = 0x1,
  Method = 0x2,
  TypeInfo = 0x3
}

public abstract class MemberInfo {

  public abstract char[] name();

  public abstract char[] helpString();

  public abstract MemberTypes memberType();

}

public enum TypeAttributes {
  CoClass = 0x0001,
  Interface = 0x0002,
  Struct = 0x0004,
  Enum = 0x0008,
  Alias = 0x0010,
  Union = 0x0020,
  Dispatch = 0x0100,
  Default = 0x0200,
  Source = 0x0400,
  Dual = 0x0800
}

public abstract class Type : MemberInfo {

  public MemberInfo[] findMembers(MemberFilter filter) {
    MemberInfo[] filteredMembers;
    foreach (MemberInfo member; getMembers()) {
      if (filter(member))
        filteredMembers ~= member;
    }
    return filteredMembers;
  }

  public override char[] toString() {
    return "Type: " ~ name;
  }

  public abstract Type[] getInterfaces();

  public abstract Type getInterface(char[] name);

  public abstract MemberInfo[] getMembers();

  public abstract MemberInfo getMember(char[] name);

  public abstract FieldInfo[] getFields();

  public abstract FieldInfo getField(char[] name);

  public abstract MethodInfo[] getMethods();

  public abstract MethodInfo getMethod(char[] name);

  public abstract TypeAttributes attributes();

  public abstract Type baseType();

  public abstract Type underlyingType();

  public abstract GUID guid();

  public abstract TypeLibrary typeLibrary();

  public override MemberTypes memberType() {
    return MemberTypes.TypeInfo;
  }

  public final bool isCoClass() {
    return (attributes & TypeAttributes.CoClass) != 0;
  }

  public final bool isInterface() {
    return (attributes & TypeAttributes.Interface) != 0;
  }

  public final bool isStruct() {
    return (attributes & TypeAttributes.Struct) != 0;
  }

  public final bool isEnum() {
    return (attributes & TypeAttributes.Enum) != 0;
  }

  public final bool isAlias() {
    return (attributes & TypeAttributes.Alias) != 0;
  }

  public final bool isUnion() {
    return (attributes & TypeAttributes.Union) != 0;
  }

}

package class TypeImpl : Type {

  private char[] name_;
  private char[] helpString_;
  private GUID guid_;
  private Type baseType_;
  private Type underlyingType_;
  private TypeAttributes attr_;
  private TypeLibrary library_;
  private Type[] interfaces_;
  private MemberInfo[] members_;
  private FieldInfo[] fields_;
  private MethodInfo[] methods_;

  private ITypeInfo typeInfo_;
  private ITypeInfo dispTypeInfo_;

  public override char[] name() {
    return name_;
  }

  public override char[] helpString() {
    return helpString_;
  }

  public override Type[] getInterfaces() {
    if (interfaces_ is null && isCoClass) {
      TYPEATTR* typeAttr;
      int hr = typeInfo_.GetTypeAttr(typeAttr);
      checkHResult(hr);
      uint count = typeAttr.cImplTypes;
      typeInfo_.ReleaseTypeAttr(typeAttr);

      for (uint i = 0; i < count; i++) {
        uint refType;
        hr = typeInfo_.GetRefTypeOfImplType(i, refType);
        checkHResult(hr);

        ITypeInfo implTypeInfo;
        hr = typeInfo_.GetRefTypeInfo(refType, implTypeInfo);
        checkHResult(hr);

        int typeFlags;
        hr = typeInfo_.GetImplTypeFlags(i, typeFlags);
        checkHResult(hr);

        TypeAttributes attr = TypeAttributes.Interface;
        if ((typeFlags & IMPLTYPEFLAG_FDEFAULT) != 0)
          attr |= TypeAttributes.Default;
        if ((typeFlags & IMPLTYPEFLAG_FSOURCE) != 0)
          attr |= TypeAttributes.Source;
        interfaces_ ~= new TypeImpl(implTypeInfo, attr, library_);

        implTypeInfo.Release();
      }
    }
    if (interfaces_ is null)
      interfaces_ = new Type[0];
    return interfaces_;
  }

  public override Type getInterface(char[] name) {
    return null;
  }

  public override MemberInfo[] getMembers() {
    if (members_ is null) {
      TYPEATTR* typeAttr;
      int hr = typeInfo_.GetTypeAttr(typeAttr);
      checkHResult(hr);

      FUNCDESC* funcDesc;
      for (uint i = 0; i < typeAttr.cFuncs; i++) {
        hr = typeInfo_.GetFuncDesc(i, funcDesc);
        checkHResult(hr);
        int memId = funcDesc.memid;
        if (((attributes & TypeAttributes.Dispatch) != 0 && (memId < 0x60000000 || memId > 0x60010003)) || (attributes & TypeAttributes.Dispatch) == 0) {
          MethodAttributes attr;
          if ((funcDesc.invkind & INVOKEKIND.INVOKE_PROPERTYGET) != 0)
            attr = MethodAttributes.GetProperty;
          if ((funcDesc.invkind & INVOKEKIND.INVOKE_PROPERTYPUT) != 0)
            attr = MethodAttributes.PutProperty;
          if ((funcDesc.invkind & INVOKEKIND.INVOKE_PROPERTYPUTREF) != 0)
            attr = MethodAttributes.PutRefProperty;

          wchar* bstrName, bstrHelpString;
          hr = typeInfo_.GetDocumentation(memId, &bstrName, &bstrHelpString, null, null);

          Type returnType = new TypeImpl(TypeImpl.getTypeName(&funcDesc.elemdescFunc.tdesc, typeInfo_), library_);
          members_ ~= new MethodInfoImpl(typeInfo_, bstrToUtf8(bstrName), bstrToUtf8(bstrHelpString), memId, attr, returnType, library_);
        }

        typeInfo_.ReleaseFuncDesc(funcDesc);
      }

      VARDESC* varDesc;
      for (uint i = 0; i < typeAttr.cVars; i++) {
        hr = typeInfo_.GetVarDesc(i, varDesc);
        checkHResult(hr);

        wchar* bstrName;
        uint n;
        hr = typeInfo_.GetNames(varDesc.memid, &bstrName, 1, &n);
        checkHResult(hr);

        if (varDesc.varkind == VARKIND.VAR_CONST)
          members_ ~= new FieldInfoImpl(new TypeImpl(TypeImpl.getTypeName(&varDesc.elemdescVar.tdesc, typeInfo_), library_), bstrToUtf8(bstrName), *varDesc.lpvarValue, cast(FieldAttributes)varDesc.varkind);
        else
          members_ ~= new FieldInfoImpl(new TypeImpl(TypeImpl.getTypeName(&varDesc.elemdescVar.tdesc, typeInfo_), library_), bstrToUtf8(bstrName), cast(FieldAttributes)varDesc.varkind);
        typeInfo_.ReleaseVarDesc(varDesc);
      }

      typeInfo_.ReleaseTypeAttr(typeAttr);
    }
    else
      members_ = new MemberInfo[0];
    return members_;
  }

  public override MemberInfo getMember(char[] name) {
    return null;
  }

  public override FieldInfo[] getFields() {
    if (fields_ is null) {
      foreach (MemberInfo member; getMembers()) {
        if ((member.memberType & MemberTypes.Field) != 0)
          fields_ ~= cast(FieldInfo)member;
      }
    }
    else
      fields_ = new FieldInfo[0];
    return fields_;
  }

  public override FieldInfo getField(char[] name) {
    return null;
  }

  public override MethodInfo[] getMethods() {
    if (methods_ is null) {
      foreach (MemberInfo member; getMembers()) {
        if ((member.memberType & MemberTypes.Method) != 0)
          methods_ ~= cast(MethodInfo)member;
      }
    }
    else
      methods_ = new MethodInfo[0];
    return methods_;
  }

  public override MethodInfo getMethod(char[] name) {
    return null;
  }

  public override TypeAttributes attributes() {
    return attr_;
  }

  public override Type baseType() {
    if (baseType_ is null) {
      ITypeInfo typeInfo = (dispTypeInfo_ !is null) ? dispTypeInfo_ : typeInfo_;
      TYPEATTR* typeAttr;
      int hr = typeInfo.GetTypeAttr(typeAttr);
      checkHResult(hr);
      bool hasBase = (typeAttr.cImplTypes > 0);
      typeInfo.ReleaseTypeAttr(typeAttr);

      if (hasBase) {
        uint refType;
        hr = typeInfo.GetRefTypeOfImplType(-1, refType);
        if (hr != S_OK && hr != TYPE_E_ELEMENTNOTFOUND)
          checkHResult(hr);

        ITypeInfo baseTypeInfo;
        hr = typeInfo.GetRefTypeInfo(refType, baseTypeInfo);
        checkHResult(hr);

        hr = baseTypeInfo.GetTypeAttr(typeAttr);
        checkHResult(hr);
        hasBase = (typeAttr.cImplTypes > 0);

        if (hasBase && (attributes & TypeAttributes.Dispatch) != 0) {
          switch (typeAttr.typekind) {
            case TYPEKIND.TKIND_INTERFACE:
            case TYPEKIND.TKIND_DISPATCH:
              hr = baseTypeInfo.GetRefTypeOfImplType(0, refType);
              checkHResult(hr);
              ITypeInfo actualTypeInfo;
              hr = baseTypeInfo.GetRefTypeInfo(refType, actualTypeInfo);
              checkHResult(hr);
              TypeAttributes attr = TypeAttributes.Interface;
              if (typeAttr.typekind == TYPEKIND.TKIND_DISPATCH)
                attr |= TypeAttributes.Dispatch;
              baseType_ = new TypeImpl(actualTypeInfo, attr, library_);
              actualTypeInfo.Release();
              break;
            default:
              break;
          }
        }
        else {
          hr = typeInfo.GetRefTypeOfImplType(0, refType);
          checkHResult(hr);
          ITypeInfo actualTypeInfo;
          hr = typeInfo.GetRefTypeInfo(refType, actualTypeInfo);
          checkHResult(hr);
          baseType_ = new TypeImpl(actualTypeInfo, TypeAttributes.Interface, library_);
          actualTypeInfo.Release();
        }

        baseTypeInfo.ReleaseTypeAttr(typeAttr);
        baseTypeInfo.Release();
      }

    }
    return baseType_;
  }

  public override Type underlyingType() {
    if (underlyingType_ is null) {
      TYPEATTR* typeAttr;
      int hr = typeInfo_.GetTypeAttr(typeAttr);
      checkHResult(hr);
      underlyingType_ = new TypeImpl(getTypeName(&typeAttr.tdescAlias, typeInfo_), library_);
      typeInfo_.ReleaseTypeAttr(typeAttr);
    }
    return underlyingType_;
  }

  public override GUID guid() {
    return guid_;
  }

  public override TypeLibrary typeLibrary() {
    return library_;
  }

  private void initFromTypeInfo(ITypeInfo typeInfo, TypeLibrary library) {
    typeInfo.AddRef();
    typeInfo_ = cast(ITypeInfo)releasingRef(typeInfo);
    library_ = library;

    ITypeLib typeLib;
    uint typeIndex;
    int hr = typeInfo.GetContainingTypeLib(typeLib, typeIndex);
    checkHResult(hr);

    wchar* bstrName, bstrHelpString;
    hr = typeLib.GetDocumentation(typeIndex, &bstrName, &bstrHelpString, null, null);
    checkHResult(hr);
    name_ = bstrToUtf8(bstrName);
    helpString_ = bstrToUtf8(bstrHelpString);

    TYPEATTR* typeAttr;
    hr = typeInfo.GetTypeAttr(typeAttr);
    checkHResult(hr);
    guid_ = typeAttr.guid;
    typeInfo.ReleaseTypeAttr(typeAttr);

    typeLib.Release();
  }

  package this(ITypeInfo typeInfo, TypeAttributes attributes, TypeLibrary library) {
    initFromTypeInfo(typeInfo, library);
    attr_ = attributes;
  }

  package this(ITypeInfo dispTypeInfo, ITypeInfo typeInfo, TypeAttributes attributes, TypeLibrary library) {
    //this(dispTypeInfo, attributes, library);
    //dispTypeInfo_ = typeInfo_;
    //typeInfo_ = dispTypeInfo_;
    this(dispTypeInfo, attributes, library);
    typeInfo_ = typeInfo;
    dispTypeInfo_ = dispTypeInfo;
  }

  package this(char[] name, TypeLibrary library) {
    name_ = name;
    library_ = library;
  }

  package static char[] getTypeName(TYPEDESC* desc, ITypeInfo typeInfo, int flags = 0) {
    if (desc.vt == VT_PTR) {
      // Don't add '*' to interfaces.
      bool isInterface;
      ITypeInfo ti;
      if (typeInfo.GetRefTypeInfo(desc.lptdesc.hreftype, ti) == S_OK) {
        TYPEATTR* typeAttr;
        if (ti.GetTypeAttr(typeAttr) == S_OK) {
          isInterface = (typeAttr.typekind == TYPEKIND.TKIND_INTERFACE || typeAttr.typekind == TYPEKIND.TKIND_DISPATCH);
          ti.ReleaseTypeAttr(typeAttr);
        }
        ti.Release();
      }
      char[] name = getTypeName(desc.lptdesc, typeInfo, flags);
      // Format out parameters.
      if (((flags & PARAMFLAG_FOUT) == 0 && !isInterface) || ((flags & PARAMFLAG_FOUT) != 0 && name == "void"))
        name ~= "*";
      return name;
    }

    if (desc.vt == VT_CARRAY) {
      if (desc.lpadesc.cDims == 1 && desc.lpadesc.rgbounds[desc.lpadesc.cDims - 1].cElements > 0)
        return std.string.format("%s[%s]", getTypeName(&desc.lpadesc.tdescElem, typeInfo, flags), desc.lpadesc.rgbounds[desc.lpadesc.cDims - 1].cElements);
      else
        return getTypeName(&desc.lpadesc.tdescElem, typeInfo, flags) ~ "*";
    }

    switch (desc.vt) {
      case VT_BYREF:
        return "void*";
      case VT_BOOL:
        return "short";
      case VT_DATE:
        return "double";
      case VT_ERROR:
        return "int";
      case VT_I1:
        return "byte";
      case VT_UI1:
        return "ubyte";
      case VT_I2:
        return "short";
      case VT_UI2:
        return "ushort";
      case VT_I4:
      case VT_INT:
      case VT_HRESULT:
        return "int";
      case VT_UI4:
      case VT_UINT:
        return "uint";
      case VT_I8:
        return "long";
      case VT_UI8:
        return "ulong";
      case VT_R4:
        return "float";
      case VT_R8:
        return "double";
      case VT_CY:
        return "long";
      case VT_BSTR:
      case VT_LPWSTR:
        return "wchar*";
      case VT_LPSTR:
        return "char*";
      case VT_UNKNOWN:
        return "IUnknown";
      case VT_DISPATCH:
        return "IDispatch";
      case VT_VOID:
        return "void";
      case VT_VARIANT:
        return "VARIANT";
      case VT_DECIMAL:
        return "DECIMAL";
      case VT_ARRAY:
        return "SAFEARRAY";
      default:
        break;
    }

    ITypeInfo customTypeInfo;
    int hr = typeInfo.GetRefTypeInfo(desc.hreftype, customTypeInfo);
    checkHResult(hr);
    wchar* bstrName;
    hr = customTypeInfo.GetDocumentation(-1, &bstrName, null, null, null);
    char[] name = bstrToUtf8(bstrName);
    customTypeInfo.Release();
    return name;
  }

}

public enum FieldAttributes {
  Static = 1,
  Constant
}

public abstract class FieldInfo : MemberInfo {

  public abstract VARIANT getValue();

  public abstract FieldAttributes attributes();

  public abstract Type fieldType();

  public override MemberTypes memberType() {
    return MemberTypes.Field;
  }

}

package class FieldInfoImpl : FieldInfo {

  private char[] name_;
  private Type fieldType_;
  private FieldAttributes attr_;
  private VARIANT value_;

  ~this() {
    value_.clear();
  }

  public override VARIANT getValue() {
    return value_;
  }

  public override FieldAttributes attributes() {
    return attr_;
  }

  public override char[] name() {
    return name_;
  }

  public override char[] helpString() {
    return null;
  }

  public override Type fieldType() {
    return fieldType_;
  }

  package this(Type fieldType, char[] name, FieldAttributes attributes) {
    fieldType_ = fieldType;
    name_ = name;
    attr_ = attributes;
  }

  package this(Type fieldType, char[] name, VARIANT value, FieldAttributes attributes) {
    VariantCopy(&value_, &value);
    fieldType_ = fieldType;
    name_ = name;
    attr_ = attributes;
  }

}

public enum MethodAttributes {
  Default = 0x1,
  GetProperty = 0x2,
  PutProperty = 0x4,
  PutRefProperty = 0x8
}

public abstract class MethodInfo : MemberInfo {

  public abstract ParameterInfo[] getParameters();

  public abstract MethodAttributes attributes();

  public abstract Type returnType();

  public abstract ParameterInfo returnParameter();

  public override MemberTypes memberType() {
    return MemberTypes.Method;
  }

  public abstract int id();

}

package class MethodInfoImpl : MethodInfo {

  private char[] name_;
  private char[] helpString_;
  private Type returnType_;
  private ParameterInfo returnParameter_;
  private ParameterInfo[] parameters_;
  private int id_;
  private MethodAttributes attr_;
  private TypeLibrary library_;

  private ITypeInfo typeInfo_;

  public override ParameterInfo[] getParameters() {
    if (parameters_ is null)
      parameters_ = ParameterInfo.getParameters(this);
    return parameters_;
  }

  public override MethodAttributes attributes() {
    return attr_;
  }

  public override int id() {
    return id_;
  }

  public override char[] name() {
    return name_;
  }

  public override char[] helpString() {
    return helpString_;
  }

  public override Type returnType() {
    return returnType_;
  }

  public override ParameterInfo returnParameter() {
    if (returnParameter_ is null)
      returnParameter_ = ParameterInfo.getReturnParameter(this);
    return returnParameter_;
  }

  package this(ITypeInfo typeInfo, char[] name, char[] helpString, int id, MethodAttributes attributes, Type returnType, TypeLibrary library) {
    typeInfo_ = cast(ITypeInfo)releasingRef(typeInfo);
    name_ = name;
    helpString_ = helpString;
    id_ = id;
    attr_ = attributes;
    returnType_ = returnType;
    library_ = library;
  }

}

public enum ParameterAttributes {
  None = 0x0,
  In = 0x1,
  Out = 0x2,
  Lcid = 0x4,
  Retval = 0x8,
  Optional = 0x10,
  HasDefault = 0x20
}

public class ParameterInfo {

  private MemberInfo member_;
  private char[] name_;
  private Type parameterType_;
  private int position_;
  private ParameterAttributes attr_;

  public MemberInfo member() {
    return member_;
  }

  public char[] name() {
    return name_;
  }

  public Type parameterType() {
    return parameterType_;
  }

  public int position() {
    return position_;
  }

  public ParameterAttributes attributes() {
    return attr_;
  }

  public bool isIn() {
    return (attributes & ParameterAttributes.In) != 0;
  }

  public bool isOut() {
    return (attributes & ParameterAttributes.Out) != 0;
  }

  public bool isRetval() {
    return (attributes & ParameterAttributes.Retval) != 0;
  }

  public bool isOptional() {
    return (attributes & ParameterAttributes.Optional) != 0;
  }

  package this(MethodInfo owner, char[] name, Type parameterType, int position, ParameterAttributes attributes) {
    member_ = owner;
    name_ = name;
    parameterType_ = parameterType;
    position_ = position;
    attr_ = attributes;

    if (isReservedWord(name_))
      name_ ~= "Arg";
  }

  package static ParameterInfo[] getParameters(MethodInfoImpl method) {
    ParameterInfo dummy;
    return getParameters(method, dummy, false);
  }

  package static ParameterInfo getReturnParameter(MethodInfoImpl method) {
    ParameterInfo returnParam;
    getParameters(method, returnParam, true);
    return returnParam;
  }

  private static ParameterInfo[] getParameters(MethodInfoImpl method, out ParameterInfo returnParameter, bool getReturnParameter) {
    ParameterInfo[] params;
    TYPEATTR* typeAttr;
    FUNCDESC* funcDesc;
    int hr = method.typeInfo_.GetTypeAttr(typeAttr);
    checkHResult(hr);
    for (uint index = 0; index < typeAttr.cFuncs; index++) {
      hr = method.typeInfo_.GetFuncDesc(index, funcDesc);
      checkHResult(hr);
      if (funcDesc.memid == method.id_ && (funcDesc.invkind & method.attr_) != 0) {
        wchar** bstrNames = new wchar*[funcDesc.cParams + 1];
        uint n;
        hr = method.typeInfo_.GetNames(funcDesc.memid, bstrNames, funcDesc.cParams + 1, &n);
        checkHResult(hr);
        // The element at 0 is the name of the function. We already have this so free it.
        SysFreeString(bstrNames[0]);

        if ((funcDesc.invkind & INVOKEKIND.INVOKE_PROPERTYPUT) != 0)
          bstrNames[1] = utf8ToBstr("value");

        for (uint position = 0; position < funcDesc.cParams; position++) {
          ushort flags = funcDesc.lprgelemdescParam[position].paramdesc.wParamFlags;
          Type paramType = new TypeImpl(TypeImpl.getTypeName(&funcDesc.lprgelemdescParam[position].tdesc, method.typeInfo_, flags), method.library_);
          if (((flags & PARAMFLAG_FRETVAL) != 0) && getReturnParameter && (returnParameter is null))
            returnParameter = new ParameterInfo(method, bstrToUtf8(bstrNames[position + 1]), paramType, -1, cast(ParameterAttributes)flags);
          else if (!getReturnParameter)
            params ~= new ParameterInfo(method, bstrToUtf8(bstrNames[position + 1]), paramType, position, cast(ParameterAttributes)flags);
        }
        delete bstrNames;
      }
      method.typeInfo_.ReleaseFuncDesc(funcDesc);
    }
    method.typeInfo_.ReleaseTypeAttr(typeAttr);
    return params;
  }

}
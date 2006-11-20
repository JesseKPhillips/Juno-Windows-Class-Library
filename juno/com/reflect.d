module juno.com.reflect;

private import juno.base.core,
  juno.base.string,
  juno.utils.registry,
  juno.com.core;
private static import std.c.stdlib;

// Check if the name if reserved word such as a keyword or other global symbol.
public bool isReservedWord(char[] name) {

  const char[][] RESERVEDWORDS = [
    "abstract", "alias", "align", "asm", "assert", "auto",
    "body", "bool", "break", "byte",
    "case", "cast", "catch", "cdouble", "cent", "cfloat", "char", "class", "const", "continue", "creal",
    "dchar", "debug", "default", "delegate", "delete", "deprecated", "do", "double",
    "else", "enum", "export", "extern",
    "false", "final", "finally", "float", "for", "foreach", "foreach_reverse", "function",
    "goto",
    "idouble", "if", "ifloat", "import", "in", "inout", "int", "interface", "invariant", "ireal", "is",
    "lazy", "long",
    "mixin", "module",
    "new", "null",
    "out", "override", "Object",
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

private void checkHResult(int hr) {
  if (hr != S_OK)
    throw new COMException(hr);
}

public class Reference {

  private char[] name_;
  private char[] doc_;
  private char[] path_;
  private Version version_;
  private GUID guid_;

  public char[] name() {
    return name_;
  }

  public char[] documentation() {
    return doc_;
  }

  public GUID guid() {
    return guid_;
  }

  public char[] path() {
    return path_;
  }

  public Version getVersion() {
    return version_;
  }

}

/**
 * Performs reflection on a COM type library.
 */
public class TypeLibrary {

  private char[] name_;
  private char[] doc_;
  private GUID guid_;
  private Version version_;
  private Type[] types_;
  private Reference[] references_;
  private Module[] modules_;

  private ITypeLib typeLib_;

  public static TypeLibrary load(char[] fileName) {
    if (fileName == null)
      throw new ArgumentException("File name cannot be null.");

    ITypeLib typeLib;
    // Try to load the type library from fileName.
    int hr = LoadTypeLib(fileName.toLPStr(), typeLib);
    if (hr != S_OK) {
      // If that failed, treat fileName as a GUID and try to load from the Windows registry.

      char[] guid = fileName;
      // Fix the GUID so it's in the expected format.
      if (guid[0] != '{')
        guid = '{' ~ guid;
      if (guid[$ - 1] != '}')
        guid ~= '}';

      scope auto typeLibKey = RegistryKey.classesRoot.openSubKey("TypeLib\\" ~ guid);
      if (typeLibKey !is null && typeLibKey.subKeyCount > 0) {
        // The subkeys are the type library's version numbers.
        // Sort and then iterate in reverse order so that the most recent version is attempted first.
        char[][] versions = typeLibKey.subKeyNames.sort;
        foreach_reverse (v; versions) {
          scope auto versionKey = typeLibKey.openSubKey(v);
          if (versionKey !is null && versionKey.subKeyCount > 0) {
            char[][] subKeyNames = versionKey.subKeyNames;
            // The keys under the version key are <LCID>\win32.
            scope auto pathKey = versionKey.openSubKey(subKeyNames[0] ~ "\\win32");
            if (pathKey !is null)
              // The key's default value is the path.
              return load(pathKey.getStringValue(null));
          }
        }
      }

      // If we get here, we can't locate the type library.
      throw new COMException(hr);
    }

    return new TypeLibrary(typeLib);
  }

  /**
   * Returns a list of references to type libraries that this type library depends on.
   */
  public final Reference[] getReferences() {
    if (references_ == null) {
      GUID libGuid;
      TLIBATTR* libAttr;
      ITypeInfo typeInfo;
      Reference[GUID] map;
      int hr;

      void addTLibGuidToMapTI(ITypeInfo typeInfo) {
        ITypeLib typeLib;
        uint index;

        hr = typeInfo.GetContainingTypeLib(typeLib, index);

        try {
          hr = typeLib.GetLibAttr(libAttr);

          try {
            if (!(libAttr.guid in map)) {
              Reference ref = new Reference;
              map[ref.guid_ = libAttr.guid] = ref;
              ref.version_ = Version(libAttr.wMajorVerNum, libAttr.wMinorVerNum);

              wchar* bstrName, bstrHelp;
              hr = typeLib.GetDocumentation(-1, &bstrName, &bstrHelp, null, null);
              ref.name_ = bstrToUtf8(bstrName);
              ref.doc_ = bstrToUtf8(bstrHelp);

              scope auto typeLibKey = RegistryKey.classesRoot.openSubKey("TypeLib\\" ~ ref.guid_.toString());
              if (typeLibKey !is null && typeLibKey.subKeyCount > 0) {
                char[] ver = format("{0}.{1}", ref.version_.major, ref.version_.minor);
                scope auto subKey = typeLibKey.openSubKey(ver);
                if (subKey !is null && subKey.subKeyCount > 0) {
                  char[][] subKeyNames = subKey.subKeyNames;
                  scope auto win32Key = subKey.openSubKey(subKeyNames[0] ~ "\\win32");
                  if (win32Key !is null)
                    ref.path_ = win32Key.getStringValue(null);
                }
              }
            }
          }
          finally {
            typeLib.ReleaseTLibAttr(libAttr);
          }
        }
        finally {
          typeLib.Release();
        }
      }

      void addTLibGuidToMapRT(ITypeInfo typeInfo, uint refType) {
        ITypeInfo refTypeInfo;
        hr = typeInfo.GetRefTypeInfo(refType, refTypeInfo);
        try {
          addTLibGuidToMapTI(refTypeInfo);
        }
        finally {
          refTypeInfo.Release();
        }
      }

      void addBaseToMap(ITypeInfo typeInfo) {
        uint refType;
        ITypeInfo refTypeInfo;
        hr = typeInfo.GetRefTypeOfImplType(-1, refType);
        hr = typeInfo.GetRefTypeInfo(refType, refTypeInfo);
        try {
          hr = refTypeInfo.GetRefTypeOfImplType(0, refType);
          addTLibGuidToMapRT(refTypeInfo, refType);
        }
        finally {
          refTypeInfo.Release();
        }
      }

      void addTLibGuidToMapTD(TYPEDESC* typeDesc) {
        if (typeDesc != null) {
          for (int i = 0; typeDesc.vt == VT_PTR || typeDesc.vt == VT_SAFEARRAY || typeDesc.vt == VT_CARRAY; i++) {
            typeDesc = typeDesc.lptdesc;
            if (i == 200)
              break;
          }
          if (typeDesc.vt == VT_USERDEFINED)
            addTLibGuidToMapRT(typeInfo, typeDesc.hreftype);
        }
      }

      void addTLibGuidToMapVD(VARDESC* varDesc) {
        addTLibGuidToMapTD(&varDesc.elemdescVar.tdesc);
      }

      void addTLibGuidToMapFD(FUNCDESC* funcDesc) {
        if (funcDesc != null) {
          addTLibGuidToMapTD(&funcDesc.elemdescFunc.tdesc);
          for (uint i = 0; i < funcDesc.cParams; i++)
            addTLibGuidToMapTD(&funcDesc.lprgelemdescParam[i].tdesc);
        }
      }

      hr = typeLib_.GetLibAttr(libAttr);
      try {
        map[libGuid = libAttr.guid] = new Reference;
      }
      finally {
        typeLib_.ReleaseTLibAttr(libAttr);
      }

      TYPEATTR* typeAttr;
      for (uint i = 0; i < typeLib_.GetTypeInfoCount(); i++) {
        hr = typeLib_.GetTypeInfo(i, typeInfo);

        try {
          hr = typeInfo.GetTypeAttr(typeAttr);
          try {
            if (typeAttr.typekind == TYPEKIND.TKIND_DISPATCH && (typeAttr.wTypeFlags & TYPEFLAGS.TYPEFLAG_FDUAL) != 0)
              addBaseToMap(typeInfo);

            for (uint j = 0; j < typeAttr.cImplTypes; j++) {
              uint refType;
              hr = typeInfo.GetRefTypeOfImplType(j, refType);
              addTLibGuidToMapRT(typeInfo, refType);
            }

            for (uint j = 0; j < typeAttr.cVars; j++) {
              VARDESC* varDesc;
              typeInfo.GetVarDesc(j, varDesc);
              addTLibGuidToMapVD(varDesc);
              typeInfo.ReleaseVarDesc(varDesc);
            }

            for (uint j = 0; j < typeAttr.cFuncs; j++) {
              FUNCDESC* funcDesc;
              typeInfo.GetFuncDesc(j, funcDesc);
              addTLibGuidToMapFD(funcDesc);
              typeInfo.ReleaseFuncDesc(funcDesc);
            }
          }
          finally {
            typeInfo.ReleaseTypeAttr(typeAttr);
          }
        }
        finally {
          typeInfo.Release();
        }
      }
      map.remove(libGuid);
      references_.length = map.keys.length;
      foreach (i, key; map.keys)
        references_[i] = map[key];
    }
    if (references_ == null)
      return new Reference[0];
    return references_;
  }

  public final Module[] getModules() {
    if (modules_ == null) {
      ITypeInfo typeInfo;
      TYPEKIND typeKind;
      for (uint i = 0; i < typeLib_.GetTypeInfoCount(); i++) {
        checkHResult(typeLib_.GetTypeInfoType(i, typeKind));
        if (typeKind == TYPEKIND.TKIND_MODULE) {
          checkHResult(typeLib_.GetTypeInfo(i, typeInfo));
          modules_ ~= new Module(typeInfo, this);
        }
      }
    }
    if (modules_ == null)
      return new Module[0];
    return modules_;
  }

  public final Type[] getTypes() {
    if (types_ == null) {
      ITypeInfo typeInfo;
      TYPEKIND typeKind;
      TYPEATTR* typeAttr;

      for (uint i = 0; i < typeLib_.GetTypeInfoCount(); i++) {
        checkHResult(typeLib_.GetTypeInfo(i, typeInfo));
        checkHResult(typeLib_.GetTypeInfoType(i, typeKind));
        checkHResult(typeInfo.GetTypeAttr(typeAttr));

        switch (typeKind) {
          case TYPEKIND.TKIND_COCLASS:
            types_ ~= new TypeImpl(typeInfo, TypeAttributes.CoClass, this);
            break;
          case TYPEKIND.TKIND_INTERFACE:
            TypeAttributes attrs = TypeAttributes.Interface;
            if ((typeAttr.wTypeFlags & TYPEFLAGS.TYPEFLAG_FDUAL) != 0)
              attrs |= TypeAttributes.InterfaceIsDual;
            types_ ~= new TypeImpl(typeInfo, attrs, this);
            break;
          case TYPEKIND.TKIND_DISPATCH:
            // IDispatch interfaces aren't as straightforward. We need to get the implemented interface.
            TypeAttributes attrs = TypeAttributes.Interface | TypeAttributes.InterfaceIsDispatch;
            if ((typeAttr.wTypeFlags & TYPEFLAGS.TYPEFLAG_FDUAL) != 0)
              attrs |= TypeAttributes.InterfaceIsDual;

            uint refType = 0;
            int hr = typeInfo.GetRefTypeOfImplType(-1, refType);
            if (hr != TYPE_E_ELEMENTNOTFOUND && refType != 0) {
              ITypeInfo refTypeInfo;
              checkHResult(typeInfo.GetRefTypeInfo(refType, refTypeInfo));
              try {
                types_ ~= new TypeImpl(typeInfo, refTypeInfo, attrs, this);
              }
              finally {
                refTypeInfo.Release();
              }
            }
            else
              types_ ~= new TypeImpl(typeInfo, attrs, this);
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
        }

        typeInfo.ReleaseTypeAttr(typeAttr);
        typeInfo.Release();
      }
    }
    if (types_ == null)
      return new Type[0];
    return types_;
  }

  public final Type[] findTypes(bool delegate(Type) filter) {
    Type[] filteredTypes;
    foreach (type; getTypes()) {
      if (filter(type))
        filteredTypes ~= type;
    }
    return filteredTypes;
  }

  public final Version getVersion() {
    return version_;
  }

  public final char[] name() {
    return name_;
  }

  public final char[] documentation() {
    return doc_;
  }

  public final GUID guid() {
    return guid_;
  }

  private this(ITypeLib typeLib) {
    typeLib_ = typeLib;

    // Get the library's name and help string.
    wchar* bstrName, bstrHelp;
    int hr = typeLib_.GetDocumentation(-1, &bstrName, &bstrHelp, null, null);
    if (hr == S_OK) {
      name_ = bstrToUtf8(bstrName);
      doc_ = bstrToUtf8(bstrHelp);
    }

    TLIBATTR* attr;
    hr = typeLib_.GetLibAttr(attr);
    if (hr == S_OK) {
      guid_ = attr.guid;
      version_ = Version(attr.wMajorVerNum, attr.wMinorVerNum);
      typeLib_.ReleaseTLibAttr(attr);
    }
  }

  ~this() {
    types_ = null;
    references_ = null;
    modules_ = null;
    tryRelease(typeLib_);
    typeLib_ = null;
  }

}

/**
 * Performs reflection on a COM module.
 */
public class Module {

  private Member[] members_;
  private Field[] fields_;
  private Method[] methods_;
  private TypeLibrary typeLib_;

  private ITypeInfo typeInfo_;

  ~this() {
    members_ = null;
    fields_ = null;
    methods_ = null;
    typeLib_ = null;
    tryRelease(typeInfo_);
    typeInfo_ = null;
  }

  public final Member[] getMembers() {
    if (members_ == null) {
      TYPEATTR* attr;
      checkHResult(typeInfo_.GetTypeAttr(attr));

      FUNCDESC* funcDesc;
      for (uint i = 0; i < attr.cFuncs; i++) {
        checkHResult(typeInfo_.GetFuncDesc(i, funcDesc));

        int dispId = funcDesc.memid;

        wchar* bstrName, bstrDoc;
        checkHResult(typeInfo_.GetDocumentation(dispId, &bstrName, &bstrDoc, null, null));

        Type returnType = new TypeImpl(TypeImpl.getTypeName(&funcDesc.elemdescFunc.tdesc, typeInfo_), typeLib_);
        members_ ~= new MethodImpl(typeInfo_, bstrToUtf8(bstrName), bstrToUtf8(bstrDoc), dispId, MethodAttributes.Default, returnType, typeLib_);

        typeInfo_.ReleaseFuncDesc(funcDesc);
      }

      VARDESC* varDesc;
      for (uint i = 0; i < attr.cVars; i++) {
        checkHResult(typeInfo_.GetVarDesc(i, varDesc));

        try {
          wchar* bstrName;
          uint count;
          checkHResult(typeInfo_.GetNames(varDesc.memid, &bstrName, 1, count));

          Type fieldType = new TypeImpl(TypeImpl.getTypeName(&varDesc.elemdescVar.tdesc, typeInfo_), typeLib_);
          members_ ~= new FieldImpl(fieldType, bstrToUtf8(bstrName), *varDesc.lpvarValue, cast(FieldAttributes)varDesc.varkind);
        }
        finally {
          typeInfo_.ReleaseVarDesc(varDesc);
        }
      }

      typeInfo_.ReleaseTypeAttr(attr);
    }
    if (members_ == null)
      return new Member[0];
    return members_;
  }

  public final Field[] getFields() {
    if (fields_ == null) {
      foreach (member; getMembers()) {
        if ((member.memberType & MemberTypes.Field) != 0)
          fields_ ~= cast(Field)member;
      }
    }
    if (fields_ == null)
      return new Field[0];
    return fields_;
  }

  public final Method[] getMethods() {
    if (methods_ == null) {
      foreach (member; getMembers()) {
        if ((member.memberType & MemberTypes.Method) != 0)
          methods_ ~= cast(Method)member;
      }
    }
    if (methods_ == null)
      return new Method[0];
    return methods_;
  }

  package this(ITypeInfo typeInfo, TypeLibrary typeLib) {
    typeInfo_ = typeInfo;
    typeLib_ = typeLib;
  }

}

public enum MemberTypes {
  Field = 0x1,
  Method = 0x2,
  TypeInfo = 0x4
}

public abstract class Member {

  public abstract char[] name();

  public abstract char[] documentation();

  public abstract MemberTypes memberType();

}

public enum TypeAttributes {
  CoClass = 0x0001,
  Interface = 0x0002,
  Struct = 0x0004,
  Enum = 0x0008,
  Alias = 0x0010,
  Union = 0x0020,
  InterfaceIsDual = 0x0040,
  InterfaceIsDispatch = 0x0080,
  InterfaceIsDefault = 0x0100,
  InterfaceIsSource = 0x0200
}

public abstract class Type : Member {

  public abstract TypeLibrary typeLibrary();

  public abstract TypeAttributes attributes();

  public abstract GUID guid();

  public abstract Type baseType();

  public abstract Type underlyingType();

  public abstract Type[] getInterfaces();

  public abstract Member[] getMembers();

  public abstract Method[] getMethods();

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

package final class TypeImpl : Type {

  private char[] name_;
  private char[] doc_;
  private GUID guid_;
  private TypeAttributes attr_;
  private TypeLibrary typeLib_;
  private Type baseType_;
  private Type underlyingType_;
  private Type[] interfaces_;
  private Member[] members_;
  private Field[] fields_;
  private Method[] methods_;

  private ITypeInfo typeInfo_;
  private ITypeInfo dispTypeInfo_;

  public override char[] name() {
    return name_;
  }

  public override char[] documentation() {
    return doc_;
  }

  public override TypeLibrary typeLibrary() {
    return typeLib_;
  }

  public override TypeAttributes attributes() {
    return attr_;
  }

  public override GUID guid() {
    return guid_;
  }

  public override Type baseType() {
    if (baseType_ is null) {
      ITypeInfo typeInfo = (dispTypeInfo_ !is null)
        ? dispTypeInfo_
        : typeInfo_;

      TYPEATTR* typeAttr;
      checkHResult(typeInfo.GetTypeAttr(typeAttr));
      bool hasBase = (typeAttr.cImplTypes > 0);
      typeInfo.ReleaseTypeAttr(typeAttr);

      if (hasBase) {
        uint refType = 0;
        int hr = typeInfo.GetRefTypeOfImplType((dispTypeInfo_ !is null) ? -1 : 0, refType);
        if (hr != S_OK && hr != TYPE_E_ELEMENTNOTFOUND)
          throw new COMException(hr);

        if (hr != TYPE_E_ELEMENTNOTFOUND && refType != 0) {
          ITypeInfo baseTypeInfo;
          checkHResult(typeInfo.GetRefTypeInfo(refType, baseTypeInfo));

          // Take separate paths for dispinterfaces and pure interfaces.
          if (dispTypeInfo_ !is null) {
            checkHResult(baseTypeInfo.GetTypeAttr(typeAttr));
            hasBase = (typeAttr.cImplTypes > 0);

            if (hasBase && (attributes & TypeAttributes.InterfaceIsDispatch) != 0) {
              // Slightly more roundabout way for IDispatch.
              switch (typeAttr.typekind) {
                case TYPEKIND.TKIND_INTERFACE:
                case TYPEKIND.TKIND_DISPATCH:
                  checkHResult(baseTypeInfo.GetRefTypeOfImplType(0, refType));

                  ITypeInfo realTypeInfo;
                  checkHResult(baseTypeInfo.GetRefTypeInfo(refType, realTypeInfo));

                  TypeAttributes attrs = TypeAttributes.Interface;
                  if (typeAttr.typekind == TYPEKIND.TKIND_DISPATCH)
                    attrs |= TypeAttributes.InterfaceIsDispatch;
                  baseType_ = new TypeImpl(realTypeInfo, attrs, typeLib_);

                  realTypeInfo.Release();
                  break;
                default:
              }
            }
            else {
              checkHResult(typeInfo.GetRefTypeOfImplType(0, refType));
              ITypeInfo realTypeInfo;
              checkHResult(baseTypeInfo.GetRefTypeInfo(refType, realTypeInfo));
              baseType_ = new TypeImpl(realTypeInfo, TypeAttributes.Interface, typeLib_);
              realTypeInfo.Release();
            }
          }
          else
            baseType_ = new TypeImpl(baseTypeInfo, TypeAttributes.Interface, typeLib_);

          baseTypeInfo.ReleaseTypeAttr(typeAttr);
          baseTypeInfo.Release();
        }
      }
    }
    return baseType_;
  }

  public override Type underlyingType() {
    // For aliases.
    if (underlyingType_ is null) {
      TYPEATTR* attr;
      int hr = typeInfo_.GetTypeAttr(attr);
      checkHResult(hr);

      try {
        underlyingType_ = new TypeImpl(getTypeName(&attr.tdescAlias, typeInfo_), typeLib_);
      }
      finally {
        typeInfo_.ReleaseTypeAttr(attr);
      }
    }
    return underlyingType_;
  }

  public override Type[] getInterfaces() {
    if (interfaces_ == null && isCoClass()) {
      uint count;
      TYPEATTR* typeAttr;

      checkHResult(typeInfo_.GetTypeAttr(typeAttr));
      try {
        count = typeAttr.cImplTypes;
      }
      finally {
        typeInfo_.ReleaseTypeAttr(typeAttr);
      }

      for (uint i = 0; i < count; i++) {
        uint refType;
        checkHResult(typeInfo_.GetRefTypeOfImplType(i, refType));

        ITypeInfo implTypeInfo;
        checkHResult(typeInfo_.GetRefTypeInfo(refType, implTypeInfo));
        try {
          int flags;
          checkHResult(typeInfo_.GetImplTypeFlags(i, flags));
          TypeAttributes attrs = TypeAttributes.Interface;
          if ((flags & IMPLTYPEFLAG_FDEFAULT) != 0)
            attrs |= TypeAttributes.InterfaceIsDefault;
          if ((flags & IMPLTYPEFLAG_FSOURCE) != 0)
            attrs |= TypeAttributes.InterfaceIsSource;

          interfaces_ ~= new TypeImpl(implTypeInfo, attrs, typeLib_);
        }
        finally {
          implTypeInfo.Release();
        }
      }
    }
    if (interfaces_ == null)
      return new Type[0];
    return interfaces_;
  }

  public override Member[] getMembers() {
    if (members_ == null) {
      TYPEATTR* attr;
      checkHResult(typeInfo_.GetTypeAttr(attr));

      FUNCDESC* funcDesc;
      for (uint i = 0; i < attr.cFuncs; i++) {
        checkHResult(typeInfo_.GetFuncDesc(i, funcDesc));

        int dispId = funcDesc.memid;

        if (((attributes & TypeAttributes.InterfaceIsDispatch) != 0 
          && (dispId < 0x60000000 || dispId > 0x60010003) 
          || (attributes & TypeAttributes.InterfaceIsDispatch) == 0)) {
          // Only if we're not one of the IDispatch functions, otherwise this doesn't work correctly.
          MethodAttributes attrs;
          if ((funcDesc.invkind & INVOKEKIND.INVOKE_PROPERTYGET) != 0)
            attrs = MethodAttributes.GetProperty;
          if ((funcDesc.invkind & INVOKEKIND.INVOKE_PROPERTYPUT) != 0)
            attrs = MethodAttributes.PutProperty;
          if ((funcDesc.invkind & INVOKEKIND.INVOKE_PROPERTYPUTREF) != 0)
            attrs = MethodAttributes.PutRefProperty;

          wchar* bstrName, bstrDoc;
          checkHResult(typeInfo_.GetDocumentation(dispId, &bstrName, &bstrDoc, null, null));

          Type returnType = new TypeImpl(TypeImpl.getTypeName(&funcDesc.elemdescFunc.tdesc, typeInfo_), typeLib_);
          members_ ~= new MethodImpl(typeInfo_, bstrToUtf8(bstrName), bstrToUtf8(bstrDoc), dispId, attrs, returnType, typeLib_);
        }

        typeInfo_.ReleaseFuncDesc(funcDesc);
      }

      VARDESC* varDesc;
      for (uint i = 0; i < attr.cVars; i++) {
        checkHResult(typeInfo_.GetVarDesc(i, varDesc));

        try {
          wchar* bstrName;
          uint count;
          checkHResult(typeInfo_.GetNames(varDesc.memid, &bstrName, 1, count));

          Type fieldType = new TypeImpl(getTypeName(&varDesc.elemdescVar.tdesc, typeInfo_), typeLib_);
          char[] fieldName = bstrToUtf8(bstrName);
          if (varDesc.varkind == VARKIND.VAR_CONST)
            members_ ~= new FieldImpl(fieldType, fieldName, *varDesc.lpvarValue, cast(FieldAttributes)varDesc.varkind);
          else
            members_ ~= new FieldImpl(fieldType, fieldName, cast(FieldAttributes)varDesc.varkind);
        }
        finally {
          typeInfo_.ReleaseVarDesc(varDesc);
        }
      }

      typeInfo_.ReleaseTypeAttr(attr);
    }
    if (members_ == null)
      return new Member[0];
    return members_;
  }

  public override Field[] getFields() {
    if (fields_ == null) {
      foreach (member; getMembers()) {
        if (member !is null && (member.memberType & MemberTypes.Field) != 0)
          fields_ ~= cast(Field)member;
      }
    }
    if (fields_ == null)
      return new Field[0];
    return fields_;
  }

  public override Method[] getMethods() {
    if (methods_ == null) {
      foreach (member; getMembers()) {
        if (member !is null && (member.memberType & MemberTypes.Method) != 0)
          methods_ ~= cast(Method)member;
      }
    }
    if (methods_ == null)
      return new Method[0];
    return methods_;
  }

  package this(ITypeInfo typeInfo, TypeAttributes attributes, TypeLibrary typeLib) {
    init(typeInfo);
    attr_ = attributes;
    typeLib_ = typeLib;
  }

  package this(ITypeInfo dispTypeInfo, ITypeInfo typeInfo, TypeAttributes attributes, TypeLibrary typeLib) {
    this(dispTypeInfo, attributes, typeLib);

    typeInfo_ = typeInfo;
    typeInfo_.AddRef();
    dispTypeInfo_ = dispTypeInfo;
  }

  package this(char[] name, TypeLibrary typeLib) {
    name_ = name;
    typeLib_ = typeLib;
  }

  ~this() {
    tryRelease(typeInfo_);
    typeInfo_ = null;
    if (dispTypeInfo_ !is null) {
      tryRelease(dispTypeInfo_);
      dispTypeInfo_ = null;
    }
    typeLib_ = null;
    baseType_ = null;
    underlyingType_ = null;
    interfaces_ = null;
    members_ = null;
    methods_ = null;
    fields_ = null;
  }

  private void init(ITypeInfo typeInfo) {
    typeInfo_ = typeInfo;
    typeInfo_.AddRef();

    wchar* bstrName, bstrHelp;
    if (typeInfo_.GetDocumentation(-1, &bstrName, &bstrHelp, null, null) == S_OK) {
      name_ = bstrToUtf8(bstrName);
      doc_ = bstrToUtf8(bstrHelp);
    }

    TYPEATTR* attr;
    if (typeInfo_.GetTypeAttr(attr) == S_OK) {
      guid_ = attr.guid;
      typeInfo_.ReleaseTypeAttr(attr);
    }
  }

  package static char[] getTypeName(TYPEDESC* desc, ITypeInfo typeInfo, int flags = 0, bool isInterface = false) {

    char[] getBasicTypeName() {
      switch (desc.vt) {
        case VT_BYREF:
          return "void*";
        case VT_BOOL:
          return "short"; // VARIANT_BOOL
        case VT_DATE:
          return "double"; // DATE
        case VT_ERROR:
          return "int";
        case VT_UI1:
          return "ubyte";
        case VT_I1:
          return "byte";
        case VT_UI2:
          return "ushort";
        case VT_I2:
          return "short";
        case VT_UI4: case VT_UINT:
          return "uint";
        case VT_I4: case VT_INT:
          return "int";
        case VT_HRESULT:
          return "int"; // HRESULT
        case VT_UI8:
          return "ulong";
        case VT_I8:
          return "long";
        case VT_R4:
          return "float";
        case VT_R8:
          return "double";
        case VT_CY:
          return "long";
        case VT_LPSTR:
          return "char*";
        case VT_BSTR:
          return "wchar*"; // BSTR
        case VT_LPWSTR:
          return "wchar*";
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
        case VT_SAFEARRAY:
        case VT_ARRAY:
          return "SAFEARRAY";
        default:
      }
      return null;
    }

    char[] getCustomTypeName() {
      char[] typeName = null;
      ITypeInfo customTypeInfo;
      int hr = typeInfo.GetRefTypeInfo(desc.hreftype, customTypeInfo);
      if (hr == S_OK) {
        try {
          wchar* bstrName;
          hr = customTypeInfo.GetDocumentation(-1, &bstrName, null, null, null);
          typeName = bstrToUtf8(bstrName);
        }
        finally {
          tryRelease(customTypeInfo);
        }
      }
      return typeName;
    }

    char[] getPtrTypeName() {
      // Try to resolve the name of a pointer type.
      //
      // Special cases to consider:
      //   - Don't add '*' to interfaces.
      //   - Strings are sometimes defined as ushort* instead of wchar* (in C, typedef unsigned short wchar_t), 
      //     however we can't be certain ushort* always equals wchar*.

      char[] typeName = null;

      if (desc.lptdesc.vt == VT_USERDEFINED) {
        ITypeInfo ti = null;
        if (typeInfo.GetRefTypeInfo(desc.lptdesc.hreftype, ti) == S_OK && ti !is null) {
          try {
            TYPEATTR* typeAttr;
            if (ti.GetTypeAttr(typeAttr) == S_OK) {
              if (typeAttr.typekind == TYPEKIND.TKIND_INTERFACE || typeAttr.typekind == TYPEKIND.TKIND_DISPATCH) {
                typeName = getTypeName(desc.lptdesc, typeInfo, flags, true);
              }
              ti.ReleaseTypeAttr(typeAttr);
            }
          }
          finally {
            tryRelease(ti);
          }
          if (typeName != null)
            return typeName;
        }
      }

      if (typeName == null)
        typeName = getTypeName(desc.lptdesc, typeInfo, flags, isInterface);
      if (!isInterface && (flags & PARAMFLAG_FOUT) == 0)
        typeName ~= "*";

      return typeName;
    }

    char[] getArrayTypeName() {
      if (desc.lpadesc.cDims == 1 && desc.lpadesc.rgbounds[desc.lpadesc.cDims - 1].cElements > 0)
        return format("{0}[{1}]", getTypeName(&desc.lpadesc.tdescElem, typeInfo, flags, isInterface), desc.lpadesc.rgbounds[desc.lpadesc.cDims - 1].cElements);
      return getTypeName(&desc.lpadesc.tdescElem, typeInfo, flags, isInterface) ~ '*';
    }

    if (desc.vt == VT_PTR)
      return getPtrTypeName();
    if (desc.vt == VT_CARRAY)
      return getArrayTypeName();

    // Try to get the type from the VARTYPE.
    char[] typeName = getBasicTypeName();
    if (typeName == null)
      typeName = getCustomTypeName();
    return typeName;
  }

}

public enum FieldAttributes {
  Static = 1,
  Constant
}

public abstract class Field : Member {

  public override MemberTypes memberType() {
    return MemberTypes.Field;
  }

  public abstract VARIANT getValue();

  public abstract FieldAttributes attributes();

  public abstract Type fieldType();

}

package class FieldImpl : Field {

  private char[] name_;
  private Type fieldType_;
  private FieldAttributes attr_;
  private VARIANT value_;

  ~this() {
    value_.clear();
  }

  public override char[] name() {
    return name_;
  }

  public override char[] documentation() {
    return null;
  }

  public override VARIANT getValue() {
    return value_;
  }

  public override FieldAttributes attributes() {
    return attr_;
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
    value.copyTo(value_);
    this(fieldType, name, attributes);
  }

}

public enum MethodAttributes {
  Default = 0x1,
  GetProperty = 0x2,
  PutProperty = 0x4,
  PutRefProperty = 0x8
}

public abstract class Method : Member {

  public abstract Parameter[] getParameters();

  public override MemberTypes memberType() {
    return MemberTypes.Method;
  }

  public abstract MethodAttributes attributes();

  public abstract Type returnType();

  public abstract Parameter returnParameter();

  public abstract int dispId();

}

private final class MethodImpl : Method {

  private char[] name_;
  private char[] doc_;
  private int dispId_;
  private MethodAttributes attrs_;
  private TypeLibrary typeLib_;
  private Type returnType_;
  private Parameter returnParameter_;
  private Parameter[] parameters_;

  private ITypeInfo typeInfo_;

  public override Parameter[] getParameters() {
    if (parameters_ == null)
      parameters_ = Parameter.getParameters(this);
    return parameters_;
  }

  public override char[] name() {
    return name_;
  }

  public override char[] documentation() {
    return doc_;
  }

  public override MethodAttributes attributes() {
    return attrs_;
  }

  public override Type returnType() {
    return returnType_;
  }

  public override Parameter returnParameter() {
    if (returnParameter_ is null)
      Parameter.getParameters(this, returnParameter_, true);
    return returnParameter_;
  }

  public override int dispId() {
    return dispId_;
  }

  package this(ITypeInfo typeInfo, char[] name, char[] documentation, int dispId, MethodAttributes attributes, Type returnType, TypeLibrary typeLib) {
    typeInfo_ = typeInfo;
    typeInfo_.AddRef();
    name_ = name;
    doc_ = documentation;
    dispId_ = dispId;
    attrs_ = attributes;
    returnType_ = returnType;
    typeLib_ = typeLib;
  }

  ~this() {
    tryRelease(typeInfo_);
    typeInfo_ = null;
    returnType_ = null;
    parameters_ = null;
    typeLib_ = null;
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

public class Parameter {

  private Member member_;
  private char[] name_;
  private Type parameterType_;
  private int position_;
  private ParameterAttributes attrs_;

  ~this() {
    member_ = null;
    parameterType_ = null;
  }

  public char[] name() {
    return name_;
  }

  public int position() {
    return position_;
  }

  public ParameterAttributes attributes() {
    return attrs_;
  }

  public Member member() {
    return member_;
  }

  public Type parameterType() {
    return parameterType_;
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

  package this(Member owner, char[] name, Type parameterType, int position, ParameterAttributes attributes) {
    member_ = owner;
    name_ = name;
    parameterType_ = parameterType;
    position_ = position;
    attrs_ = attributes;

    if (isReservedWord(name_))
      name_ ~= "Param";
  }

  package static Parameter[] getParameters(MethodImpl method) {
    Parameter dummy;
    return getParameters(method, dummy, false);
  }

  package static Parameter[] getParameters(MethodImpl method, out Parameter returnParameter, bool getReturnParameter) {
    Parameter[] params = null;

    TYPEATTR* typeAttr;
    FUNCDESC* funcDesc;

    checkHResult(method.typeInfo_.GetTypeAttr(typeAttr));

    //try {
      for (uint i = 0; i < typeAttr.cFuncs; i++) {
        checkHResult(method.typeInfo_.GetFuncDesc(i, funcDesc));

        //try {
          if (funcDesc.memid == method.dispId && (funcDesc.invkind & method.attributes) != 0) {
            wchar** bstrNames = cast(wchar**)std.c.stdlib.calloc(funcDesc.cParams + 1, (wchar*).sizeof);

            uint count;
            checkHResult(method.typeInfo_.GetNames(funcDesc.memid, bstrNames, funcDesc.cParams + 1, count));

            // The element at 0 is the name of the function. We've already got this, so free it.
            freeBstr(bstrNames[0]);

            if ((funcDesc.invkind & INVOKEKIND.INVOKE_PROPERTYPUT) != 0 || (funcDesc.invkind & INVOKEKIND.INVOKE_PROPERTYPUTREF) != 0)
              bstrNames[0] = utf8ToBstr("value");

            for (ushort pos = 0; pos < funcDesc.cParams; pos++) {
              ushort flags = funcDesc.lprgelemdescParam[pos].paramdesc.wParamFlags;
              TypeImpl paramType = new TypeImpl(TypeImpl.getTypeName(&funcDesc.lprgelemdescParam[pos].tdesc, method.typeInfo_, flags), method.typeLib_);

              if (((flags & PARAMFLAG_FRETVAL) != 0) && getReturnParameter && (returnParameter is null))
                returnParameter = new Parameter(method, bstrToUtf8(bstrNames[pos + 1]), paramType, -1, cast(ParameterAttributes)flags);
              else if (!getReturnParameter) {
                ParameterAttributes attrs = cast(ParameterAttributes)flags;
                if (paramType.name_ == "GUID*") {
                  // Remove pointer description from GUIDs, and make them inout params instead.
                  paramType.name_ = "GUID";
                  attrs |= (ParameterAttributes.In | ParameterAttributes.Out);
                }
                params ~= new Parameter(method, bstrToUtf8(bstrNames[pos + 1]), paramType, pos, attrs);
              }
            }

            std.c.stdlib.free(bstrNames);
          }
        //}
        //finally {
          method.typeInfo_.ReleaseFuncDesc(funcDesc);
        //}
      }
    //}
    //finally {
      method.typeInfo_.ReleaseTypeAttr(typeAttr);
    //}

    return params;
  }

}
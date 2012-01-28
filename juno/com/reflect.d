/**
 * Contains types that retrieve information about type libraries.
 *
 * Copyright: (c) 2009 John Chapman
 *
 * License: See $(LINK2 ..\..\licence.txt, licence.txt) for use and distribution terms.
 */
module juno.com.reflect;

import juno.base.core,
  juno.base.environment,
  juno.base.string,
  juno.com.core,
  juno.utils.registry;

import std.c.string : memset;
//debug import std.stdio : writefln;

// Check if the name if reserved word such as a keyword or other global symbol.
bool isReservedWord(string name) {

  immutable string[] RESERVEDWORDS = [
    "abstract", "alias", "align", "asm", "assert", "auto",
    "body", "bool", "break", "byte",
    "case", "cast", "catch", "cdouble", "cent", "cfloat", "char", "class", "const", "continue", "creal",
    "dchar", "debug", "default", "delegate", "delete", "deprecated", "do", "double",
    "else", "enum", "Exception", "export", "extern",
    "false", "final", "finally", "float", "for", "foreach", "foreach_reverse", "function",
    "goto",
    "idouble", "if", "ifloat", "import", "in", "inout", "int", "interface", "invariant", "immutable", "ireal", "is",
    "lazy", "long",
    "macro", "mixin", "module",
    "new", "nothrow", "null",
    "out", "override", "Object",
    "package", "pragma", "private", "protected", "public", "pure",
    "real", "ref", "return",
    "scope", "shared", "short", "static", "struct", "super", "switch", "synchronized",
    "template", "this", "throw", "Throwable", "true", "try", "typedef", "typeid", "typeof",
    "ubyte", "ucent", "uint", "ulong", "union", "unittest", "ushort",
    "version", "void", "volatile",
    "wchar", "while", "with",
    "__FILE__", "__LINE__", "__thread", "__traits", "__gshared"
  ];

  foreach (word; RESERVEDWORDS) {
    if (word == name)
      return true;
  }
  return false;
}

// Check if the name is a reserved name (DMD doesn't allow user types with these names).
bool isReservedClassName(string name) {

  immutable string[] RESERVEDTYPES = [
    "Exception", "Object", "Throwable"];

  foreach (word; RESERVEDTYPES) {
    if (word == name)
      return true;
  }
  return false;
}

private void checkHResult(int hr) {
  if (hr != S_OK)
    throw new COMException(hr);
}

class Reference {

    private string name_;
    private string help_;
    private Guid guid_;
    private string location_;
    private Version version_;

    @property {
        string name() {
            return name_;
        }

        string help() {
            return help_;
        }

        Guid guid() {
            return guid_;
        }

        string location() {
            return location_;
        }
    }

    Version getVersion() {
        return version_;
    }


    private this() {
    }

    private this(string name, string help, Guid guid, string location, Version ver) {
        name_ = name;
        help_ = help;
        guid_ = guid;
        location_ = location;
        version_ = ver;
    }

}

/**
 */
class TypeLibrary {

  private string name_;
  private string help_;
  private Guid guid_;
  private Version version_;
  private string location_;
  private Type[] types_;
  private Module[] modules_;
  private Reference[] references_;

  private ITypeLib typeLib_;

  private this(ITypeLib typeLib, string fileName) {
    typeLib_ = typeLib;
    location_ = fileName;

    wchar* bstrName, bstrHelp;
    if (SUCCEEDED(typeLib_.GetDocumentation(-1, &bstrName, &bstrHelp, null, null))) {
      name_ = fromBstr(bstrName);
      help_ = fromBstr(bstrHelp);
    }

    TLIBATTR* attr;
    if (SUCCEEDED(typeLib_.GetLibAttr(attr))) {
      scope(exit) typeLib_.ReleaseTLibAttr(attr);

      guid_ = attr.guid;
      version_ = new Version(attr.wMajorVerNum, attr.wMinorVerNum);
    }
  }

  ~this() {
    if (typeLib_ !is null) {
      tryRelease(typeLib_);
      typeLib_ = null;
    }

    types_ = null;
    modules_ = null;
    references_ = null;
  }

  @property {
      /**
       */
      string name() {
        return name_;
      }

      /**
       */
      string help() {
        return help_;
      }

      /**
       */
      Guid guid() {
        return guid_;
      }

      /**
       */
      string location() {
        return location_;
      }

      /**
       */
      Version getVersion() {
        return version_;
      }
  }

  /**
   */
  static TypeLibrary load(string fileName) {
    if (fileName == null)
      throw new ArgumentException("File name cannot be null", "fileName");

    ITypeLib typeLib = null;
    // Try to load the library from fileName.
    int hr = LoadTypeLib(fileName.toUtf16z(), typeLib);
    if (hr != S_OK) {
      // If that failed, treat filename as a GUID and try to load from the registry.

      string guid = fileName;
      if (guid[0] != '{')
        guid = '{' ~ guid;
      if (guid[$ - 1] != '}')
        guid ~= '}';

      scope typeLibKey = RegistryKey.classesRoot.openSubKey("TypeLib\\" ~ guid);
      if (typeLibKey !is null && typeLibKey.subKeyCount > 0) {
        // The subkeys are the type library's version numbers.
        // Sort then iterate in reverse order so that the most recent version is attempted first.
        string[] versions = typeLibKey.subKeyNames.sort;
        foreach_reverse (v; versions) {
          scope versionKey = typeLibKey.openSubKey(v);
          if (versionKey !is null && versionKey.subKeyCount > 0) {
            string[] subKeyNames = versionKey.subKeyNames;
            // The keys under the version are <LCID>\win32. The LCID is usually 0 - but, even if not, we just
            // take the first entry and look inside that for the path.
            scope pathKey = versionKey.openSubKey(subKeyNames[0] ~ "\\win32");
            if (pathKey !is null) {
              // The key's default value is the path.
              return load(pathKey.getValue!(string)(null));
            }
          }
        }
      }

      // If we get here, we couldn't open the type library.
      throw new COMException(hr);
    }

    return new TypeLibrary(typeLib, fileName);
  }

  public final Reference[] getReferences() {
    if (references_ == null) {
      GUID libGuid;
      TLIBATTR* libAttr;
      ITypeInfo typeInfo;
      int hr;

      Reference[GUID] map;

      void addTLibGuidToMapTI(ITypeInfo typeInfo) {
        ITypeLib typeLib;
        uint index;
        if (typeInfo.GetContainingTypeLib(typeLib, index) == S_OK) {
          scope(exit) typeLib.Release();

          if (typeLib.GetLibAttr(libAttr) == S_OK) {
            scope(exit) typeLib.ReleaseTLibAttr(libAttr);

            if (!(libAttr.guid in map)) {
              string name, help, location;

              wchar* bstrName, bstrHelp;
              if (typeLib.GetDocumentation(-1, &bstrName, &bstrHelp, null, null) == S_OK) {
                name = fromBstr(bstrName);
                help = fromBstr(bstrHelp);
              }
              Version ver = new Version(libAttr.wMajorVerNum, libAttr.wMinorVerNum);

              scope typeLibKey = RegistryKey.classesRoot.openSubKey("TypeLib\\" ~ libAttr.guid.toString("P"));
              if (typeLibKey !is null && typeLibKey.subKeyCount > 0) {
                scope subKey = typeLibKey.openSubKey(ver.toString());
                if (subKey !is null && subKey.subKeyCount > 0) {
                  string[] subKeyNames = subKey.subKeyNames;
                  scope win32Key = subKey.openSubKey(subKeyNames[0] ~ "\\win32");
                  if (win32Key !is null)
                    location = win32Key.getValue!(string)(null);
                }
              }

              map[libAttr.guid] = new Reference(name, help, libAttr.guid, location, ver);
            }
          }
        }
      }

      void addTLibGuidToMapRT(ITypeInfo typeInfo, uint refType) {
        ITypeInfo refTypeInfo;
        if (typeInfo.GetRefTypeInfo(refType, refTypeInfo) == S_OK) {
          scope(exit) refTypeInfo.Release();
          addTLibGuidToMapTI(refTypeInfo);
        }
      }

      void addTLibGuidToMapTD(TYPEDESC* typeDesc) {
        if (typeDesc != null) {
          for (int i = 0; typeDesc.vt == VT_PTR || typeDesc.vt == VT_SAFEARRAY || typeDesc.vt == VT_CARRAY; i++) {
            typeDesc = typeDesc.lptdesc;
            if (i == 200) break;
          }
          if (typeDesc.vt == VT_USERDEFINED)
            addTLibGuidToMapRT(typeInfo, typeDesc.hreftype);
        }
      }

      void addBaseToMap(ITypeInfo typeInfo) {
        uint refType;
        ITypeInfo refTypeInfo;
        if (typeInfo.GetRefTypeOfImplType(-1, refType) == S_OK) {
          if (typeInfo.GetRefTypeInfo(refType, refTypeInfo) == S_OK) {
            scope(exit) refTypeInfo.Release();
            if (refTypeInfo.GetRefTypeOfImplType(0, refType) == S_OK)
              addTLibGuidToMapRT(refTypeInfo, refType);
          }
        }
      }

      if (typeLib_.GetLibAttr(libAttr) == S_OK) {
        scope(exit) typeLib_.ReleaseTLibAttr(libAttr);
        map[libGuid = libAttr.guid] = new Reference;
      }

      TYPEATTR* typeAttr;
      for (uint i = 0; i < typeLib_.GetTypeInfoCount(); i++) {
        if (typeLib_.GetTypeInfo(i, typeInfo) == S_OK) {
          scope(exit) typeInfo.Release();

          if (typeInfo.GetTypeAttr(typeAttr) == S_OK) {
            scope(exit) typeInfo.ReleaseTypeAttr(typeAttr);

            if (typeAttr.typekind == TYPEKIND.TKIND_DISPATCH && (typeAttr.wTypeFlags & TYPEFLAGS.TYPEFLAG_FDUAL) != 0)
              addBaseToMap(typeInfo);

            for (uint j = 0; j < typeAttr.cImplTypes; j++) {
              uint refType;
              if (typeInfo.GetRefTypeOfImplType(j, refType) == S_OK)
                addTLibGuidToMapRT(typeInfo, refType);
            }

            for (uint j = 0; j < typeAttr.cVars; j++) {
              VARDESC* varDesc;
              if (typeInfo.GetVarDesc(j, varDesc) == S_OK) {
                scope(exit) typeInfo.ReleaseVarDesc(varDesc);
                addTLibGuidToMapTD(&varDesc.elemdescVar.tdesc);
              }
            }

            for (uint j = 0; j < typeAttr.cFuncs; j++) {
              FUNCDESC* funcDesc;
              if (typeInfo.GetFuncDesc(j, funcDesc) == S_OK) {
                scope(exit) typeInfo.ReleaseFuncDesc(funcDesc);
                addTLibGuidToMapTD(&funcDesc.elemdescFunc.tdesc);
                for (uint k = 0; k < funcDesc.cParams; k++)
                  addTLibGuidToMapTD(&funcDesc.lprgelemdescParam[k].tdesc);
              }
            }
          }
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

  /**
   */
  final Module[] getModules() {
    if (modules_ == null) {
      ITypeInfo typeInfo;
      TYPEKIND typeKind;
      for (auto i = 0; i < typeLib_.GetTypeInfoCount(); i++) {
        checkHResult(typeLib_.GetTypeInfoType(i, typeKind));
        if (typeKind == TYPEKIND.TKIND_MODULE) {
          checkHResult(typeLib_.GetTypeInfo(i, typeInfo));
          modules_ ~= new Module(typeInfo, this);
        }
      }
    }
    return modules_;
  }

  /**
   */
  final Type[] getTypes() {
    if (types_ == null) {
      ITypeInfo typeInfo;
      TYPEKIND typeKind;
      TYPEATTR* typeAttr;

      for (auto i = 0; i < typeLib_.GetTypeInfoCount(); i++) {
        checkHResult(typeLib_.GetTypeInfo(i, typeInfo));
        checkHResult(typeLib_.GetTypeInfoType(i, typeKind));
        checkHResult(typeInfo.GetTypeAttr(typeAttr));

        scope(exit) {
          typeInfo.ReleaseTypeAttr(typeAttr);
          tryRelease(typeInfo);
        }

        switch (typeKind) {
          case TYPEKIND.TKIND_COCLASS:
            if (typeAttr.wTypeFlags & TYPEFLAGS.TYPEFLAG_FCANCREATE)
              types_ ~= new TypeImpl(typeInfo, TypeAttributes.CoClass, this);
            break;

          case TYPEKIND.TKIND_INTERFACE:
            auto attrs = TypeAttributes.Interface;
            if (typeAttr.wTypeFlags & TYPEFLAGS.TYPEFLAG_FDUAL)
              attrs |= TypeAttributes.InterfaceIsDual;
            types_ ~= new TypeImpl(typeInfo, attrs, this);
            break;

          case TYPEKIND.TKIND_DISPATCH:
            auto attrs = TypeAttributes.Interface | TypeAttributes.InterfaceIsDispatch;
            if (typeAttr.wTypeFlags & TYPEFLAGS.TYPEFLAG_FDUAL)
              attrs |= TypeAttributes.InterfaceIsDual;

            uint refType;
            int hr = typeInfo.GetRefTypeOfImplType(-1, refType);
            if (hr != TYPE_E_ELEMENTNOTFOUND && refType != 0) {
              ITypeInfo refTypeInfo;
              checkHResult(typeInfo.GetRefTypeInfo(refType, refTypeInfo));
              scope(exit) tryRelease(refTypeInfo);

              types_ ~= new TypeImpl(typeInfo, refTypeInfo, attrs, this);
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
      }
    }
    return types_;
  }

  /**
   */
  final Type[] findTypes(bool delegate(Type) filter) {
    Type[] filteredTypes;
    foreach (type; getTypes()) {
      if (filter(type))
        filteredTypes ~= type;
    }
    return filteredTypes;
  }

}

/**
 */
class Module {

  private Member[] members_;
  private Field[] fields_;
  private Method[] methods_;
  private TypeLibrary typeLib_;

  private ITypeInfo typeInfo_;

  /**
   */
  final Member[] getMembers() {
    if (members_ == null) {
      TYPEATTR* typeAttr;
      checkHResult(typeInfo_.GetTypeAttr(typeAttr));
      scope(exit) typeInfo_.ReleaseTypeAttr(typeAttr);

      VARDESC* varDesc;
      for (auto i = 0; i < typeAttr.cVars; i++) {
        checkHResult(typeInfo_.GetVarDesc(i, varDesc));
        scope(exit) typeInfo_.ReleaseVarDesc(varDesc);

        wchar* bstrName;
        uint nameCount;
        checkHResult(typeInfo_.GetNames(varDesc.memid, &bstrName, 1, nameCount));

        Type fieldType = new TypeImpl(TypeImpl.getTypeName(&varDesc.elemdescVar.tdesc, typeInfo_), typeLib_);
        members_ ~= new FieldImpl(fieldType, fromBstr(bstrName), *varDesc.lpvarValue, cast(FieldAttributes)varDesc.varkind);
      }

      FUNCDESC* funcDesc;
      for (auto i = 0; i < typeAttr.cFuncs; i++) {
        checkHResult(typeInfo_.GetFuncDesc(i, funcDesc));
        scope(exit) typeInfo_.ReleaseFuncDesc(funcDesc);

        int id = funcDesc.memid;

        wchar* bstrName, bstrHelp;
        checkHResult(typeInfo_.GetDocumentation(id, &bstrName, &bstrHelp, null, null));

        Type returnType = new TypeImpl(TypeImpl.getTypeName(&funcDesc.elemdescFunc.tdesc, typeInfo_), typeLib_);
        members_ ~= new MethodImpl(typeInfo_, fromBstr(bstrName), fromBstr(bstrHelp), id, MethodAttributes.Default, returnType, typeLib_);
      }
    }
    return members_;
  }

  /**
   */
  final Field[] getFields() {
    if (fields_ == null) {
      foreach (member; getMembers()) {
        if (member !is null && (member.memberType & MemberTypes.Field))
          fields_ ~= cast(Field)member;
      }
    }
    return fields_;
  }

  /**
   */
  final Method[] getMethods() {
    if (methods_ == null) {
      foreach (member; getMembers()) {
        if (member !is null && (member.memberType & MemberTypes.Method))
          methods_ ~= cast(Method)member;
      }
    }
    return methods_;
  }

  /**
   */
  final Member[] getMember(string name) {
    Member[] result = null;
    foreach (member; getMembers()) {
      if (member !is null && member.name == name)
        result ~= member;
    }
    return result;
  }

  /**
   */
  final Field getField(string name) {
    foreach (field; getFields()) {
      if (field !is null && field.name == name)
        return field;
    }
    return null;
  }

  /**
   */
  final Method getMethod(string name) {
    foreach (method; getMethods()) {
      if (method !is null && method.name == name)
        return method;
    }
    return null;
  }

  package this(ITypeInfo typeInfo, TypeLibrary typeLib) {
    typeInfo_ = typeInfo;
    typeLib_ = typeLib;
  }

  ~this() {
    if (typeInfo_ !is null) {
      tryRelease(typeInfo_);
      typeInfo_ = null;
    }
  }

}

///
enum MemberTypes {
  Field  = 0x1, ///
  Method = 0x2, ///
  Type   = 0x4  ///
}

/**
 */
abstract class Member {

  /**
   */
  abstract @property string name();

  /**
   */
  abstract @property string help();

  /**
   */
  abstract @property MemberTypes memberType();

}

///
enum TypeAttributes {
  CoClass             = 0x1,
  Interface           = 0x2,
  Struct              = 0x4,
  Enum                = 0x8,
  Alias               = 0x10,
  Union               = 0x20,
  InterfaceIsDual     = 0x100,
  InterfaceIsDispatch = 0x200,
  InterfaceIsDefault  = 0x400,
  InterfaceIsSource   = 0x800
}

/**
 */
abstract class Type : Member {

    /**
     */
    override MemberTypes memberType() {
        return MemberTypes.Type;
    }

    /**
     */
    abstract @property TypeAttributes attributes();

    @property {
        /**
         */
        abstract Guid guid();

        /**
         */
        abstract Type baseType();

        /**
         */
        abstract Type underlyingType();
    }

    /**
     */
    abstract Type[] getInterfaces();

    /**
     */
    abstract Member[] getMembers();

    /**
     */
    abstract Field[] getFields();

    /**
     */
    abstract Method[] getMethods();

    /**
     */
    Member[] getMember(string name) {
        Member[] result = null;
        foreach (member; getMembers()) {
            if (member !is null && member.name == name)
                result ~= member;
        }
        return result;
    }

    /**
     */
    Field getField(string name) {
        foreach (field; getFields()) {
            if (field !is null && field.name == name)
                return field;
        }
        return null;
    }

    /**
     */
    Method getMethod(string name) {
        foreach (method; getMethods()) {
            if (method !is null && method.name == name)
                return method;
        }
        return null;
    }

    /**
     */
    override string toString() {
        return "Type: " ~ name;
    }

    @property {
        /**
         */
        final bool isCoClass() {
            return (attributes & TypeAttributes.CoClass) != 0;
        }

        /**
         */
        final bool isInterface() {
            return (attributes & TypeAttributes.Interface) != 0;
        }

        /**
         */
        final bool isStruct() {
            return (attributes & TypeAttributes.Struct) != 0;
        }

        /**
         */
        final bool isEnum() {
            return (attributes & TypeAttributes.Enum) != 0;
        }

        /**
         */
        final bool isAlias() {
            return (attributes & TypeAttributes.Alias) != 0;
        }

        /**
         */
        final bool isUnion() {
            return (attributes & TypeAttributes.Union) != 0;
        }
    }
}

package final class TypeImpl : Type {

  private string name_;
  private string help_;
  private Guid guid_;
  private TypeAttributes attr_;
  private Type baseType_;
  private Type underlyingType_;
  private Type[] interfaces_;
  private Member[] members_;
  private Field[] fields_;
  private Method[] methods_;

  private ITypeInfo typeInfo_;
  private ITypeInfo dispTypeInfo_;
  private TypeLibrary typeLib_;

  override string name() {
    return name_;
  }

  override string help() {
    return help_;
  }

  override @property TypeAttributes attributes() {
    return attr_;
  }

  override Guid guid() {
    return guid_;
  }

  override Type baseType() {
    if (baseType_ is null) {
      auto typeInfo = (dispTypeInfo_ !is null) 
        ? dispTypeInfo_
        : typeInfo_;

      TYPEATTR* typeAttr;
      checkHResult(typeInfo.GetTypeAttr(typeAttr));
      bool hasBase = (typeAttr.cImplTypes > 0);
      typeInfo.ReleaseTypeAttr(typeAttr);

      if (hasBase) {
        uint refType;
        int hr = typeInfo.GetRefTypeOfImplType((dispTypeInfo_ !is null) ? -1 : 0, refType);
        if (hr != S_OK && hr != TYPE_E_ELEMENTNOTFOUND)
          throw new COMException(hr);

        if (hr != TYPE_E_ELEMENTNOTFOUND) {
          ITypeInfo baseTypeInfo;
          checkHResult(typeInfo.GetRefTypeInfo(refType, baseTypeInfo));
          scope(exit) baseTypeInfo.Release();

          // Take separate paths for dispinterfaces and pure interfaces.
          if (dispTypeInfo_ !is null) {
            checkHResult(baseTypeInfo.GetTypeAttr(typeAttr));
            scope(exit) baseTypeInfo.ReleaseTypeAttr(typeAttr);
            hasBase = (typeAttr.cImplTypes > 0);

            if (hasBase && (attributes & TypeAttributes.InterfaceIsDispatch)) {
              if (typeAttr.typekind == TYPEKIND.TKIND_INTERFACE || typeAttr.typekind == TYPEKIND.TKIND_DISPATCH) {
                checkHResult(baseTypeInfo.GetRefTypeOfImplType(0, refType));

                ITypeInfo realTypeInfo;
                checkHResult(baseTypeInfo.GetRefTypeInfo(refType, realTypeInfo));
                scope(exit) realTypeInfo.Release();

                TypeAttributes attrs = TypeAttributes.Interface;
                if (typeAttr.typekind == TYPEKIND.TKIND_DISPATCH)
                  attrs |= TypeAttributes.InterfaceIsDispatch;
                baseType_ = new TypeImpl(realTypeInfo, attrs, typeLib_);
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
        }
      }
    }
    return baseType_;
  }

  override Type underlyingType() {
    if (underlyingType_ is null) {
      TYPEATTR* typeAttr;
      checkHResult(typeInfo_.GetTypeAttr(typeAttr));
      scope(exit) typeInfo_.ReleaseTypeAttr(typeAttr);

      underlyingType_ = new TypeImpl(getTypeName(&typeAttr.tdescAlias, typeInfo_), typeLib_);
    }
    return underlyingType_;
  }

  override Type[] getInterfaces() {
    if (interfaces_ == null && isCoClass()) {
      uint count;
      TYPEATTR* typeAttr;
      checkHResult(typeInfo_.GetTypeAttr(typeAttr));
      scope(exit) typeInfo_.ReleaseTypeAttr(typeAttr);

      count = typeAttr.cImplTypes;

      for (uint i = 0; i < count; i++) {
        uint refType;
        checkHResult(typeInfo_.GetRefTypeOfImplType(i, refType));

        ITypeInfo implTypeInfo;
        checkHResult(typeInfo_.GetRefTypeInfo(refType, implTypeInfo));
        scope(exit) implTypeInfo.Release();

        int flags;
        checkHResult(typeInfo_.GetImplTypeFlags(i, flags));
        TypeAttributes attrs = TypeAttributes.Interface;
        if (flags & IMPLTYPEFLAG_FDEFAULT)
          attrs |= TypeAttributes.InterfaceIsDefault;
        if (flags & IMPLTYPEFLAG_FSOURCE)
          attrs |= TypeAttributes.InterfaceIsSource;

        interfaces_ ~= new TypeImpl(implTypeInfo, attrs, typeLib_);
      }
    }
    return interfaces_;
  }

  override Member[] getMembers() {
    if (members_ == null) {
      TYPEATTR* typeAttr;
      checkHResult(typeInfo_.GetTypeAttr(typeAttr));
      scope(exit) typeInfo_.ReleaseTypeAttr(typeAttr);

      VARDESC* varDesc;
      for (auto i = 0; i < typeAttr.cVars; i++) {

        checkHResult(typeInfo_.GetVarDesc(i, varDesc));
        scope(exit) typeInfo_.ReleaseVarDesc(varDesc);

        wchar* bstrName;
        uint nameCount;
        checkHResult(typeInfo_.GetNames(varDesc.memid, &bstrName, 1, nameCount));

        Type fieldType = new TypeImpl(TypeImpl.getTypeName(&varDesc.elemdescVar.tdesc, typeInfo_), typeLib_);
        string fieldName = fromBstr(bstrName);
        if (varDesc.varkind == VARKIND.VAR_CONST)
          members_ ~= new FieldImpl(fieldType, fieldName, *varDesc.lpvarValue, cast(FieldAttributes)varDesc.varkind);
        else
          members_ ~= new FieldImpl(fieldType, fieldName, cast(FieldAttributes)varDesc.varkind);
      }

      FUNCDESC* funcDesc;
      for (auto i = 0; i < typeAttr.cFuncs; i++) {
        checkHResult(typeInfo_.GetFuncDesc(i, funcDesc));
        scope(exit) typeInfo_.ReleaseFuncDesc(funcDesc);

        int id = funcDesc.memid;

        if ((attributes & TypeAttributes.InterfaceIsDispatch)
          && (id < 0x60000000 || id > 0x60010003)
          || !(attributes & TypeAttributes.InterfaceIsDispatch)) {
          // Only if we're not one of the IDispatch functions.
          MethodAttributes attrs = MethodAttributes.Default;
          if (funcDesc.invkind & INVOKEKIND.INVOKE_PROPERTYGET)
            attrs = MethodAttributes.GetProperty;
          if (funcDesc.invkind & INVOKEKIND.INVOKE_PROPERTYPUT)
            attrs = MethodAttributes.PutProperty;
          if (funcDesc.invkind & INVOKEKIND.INVOKE_PROPERTYPUTREF)
            attrs = MethodAttributes.PutRefProperty;

          wchar* bstrName, bstrHelp;
          checkHResult(typeInfo_.GetDocumentation(id, &bstrName, &bstrHelp, null, null));

          Type returnType = new TypeImpl(TypeImpl.getTypeName(&funcDesc.elemdescFunc.tdesc, typeInfo_), typeLib_);
          members_ ~= new MethodImpl(typeInfo_, fromBstr(bstrName), fromBstr(bstrHelp), id, attrs, returnType, typeLib_);
        }
      }
    }
    return members_;
  }

  override Field[] getFields() {
    if (fields_ == null) {
      foreach (member; getMembers()) {
        if (member !is null && (member.memberType & MemberTypes.Field) != 0)
          fields_ ~= cast(Field)member;
      }
    }
    return fields_;
  }

  override Method[] getMethods() {
    if (methods_ == null) {
      foreach (member; getMembers()) {
        if (member !is null && (member.memberType & MemberTypes.Method) != 0)
          methods_ ~= cast(Method)member;
      }
    }
    return methods_;
  }

  private void init(ITypeInfo typeInfo) {
    typeInfo_ = typeInfo;
    typeInfo_.AddRef();

    wchar* bstrName, bstrHelp;
    if (SUCCEEDED(typeInfo_.GetDocumentation(-1, &bstrName, &bstrHelp, null, null))) {
      name_ = fromBstr(bstrName);
      help_ = fromBstr(bstrHelp);
    }

    TYPEATTR* attr;
    if (SUCCEEDED(typeInfo_.GetTypeAttr(attr))) {
      guid_ = attr.guid;
      typeInfo_.ReleaseTypeAttr(attr);
    }
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

  package this(string name, TypeLibrary typeLib) {
    name_ = name;
    typeLib_ = typeLib;
  }

  ~this() {
    if (typeInfo_ !is null) {
      tryRelease(typeInfo_);
      typeInfo_ = null;
    }

    if (dispTypeInfo_ !is null) {
      tryRelease(dispTypeInfo_);
      dispTypeInfo_ = null;
    }
  }

  package static string getTypeName(TYPEDESC* desc, ITypeInfo typeInfo, int flags = 0, bool isInterface = false) {

    string getBasicTypeName() {
      switch (desc.vt) {
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
        case VT_UI4, VT_UINT:
          return "uint";
        case VT_I4, VT_INT:
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
          return "wchar*";
        case VT_BSTR:
          return "wchar*"; // BSTR
        case VT_LPWSTR:
          return "wchar*";
        case VT_UNKNOWN:
          return "IUnknown";
        case VT_DISPATCH:
          return "IDispatch";
        case VT_VARIANT:
          return "VARIANT";
        case VT_DECIMAL:
          return "DECIMAL";
        case VT_ARRAY, VT_SAFEARRAY:
          return "SAFEARRAY*";
        case VT_VOID:
          return "void";
        case VT_BYREF:
          return "void*";
        default:
      }
      return null;
    }

    string getCustomTypeName() {
      string typeName;
      ITypeInfo customTypeInfo;
      if (SUCCEEDED(typeInfo.GetRefTypeInfo(desc.hreftype, customTypeInfo))) {
        scope(exit) customTypeInfo.Release();

        wchar* bstrName;
        customTypeInfo.GetDocumentation(-1, &bstrName, null, null, null);
        typeName = fromBstr(bstrName);
      }
      return typeName;
    }

    string getPtrTypeName() {
      // Try to resolve the name of a pointer type.
      // Special cases to consider:
      //   - Don't add '*' to interfaces.
      //   - Strings are sometimes defined as ushort* instead of wchar*, but ushort* doesn't always equal wchar*.

      string typeName;

      if (desc.lptdesc.vt == VT_USERDEFINED) {
        ITypeInfo ti;
        if (typeInfo.GetRefTypeInfo(desc.lptdesc.hreftype, ti) == S_OK && ti !is null) {
          scope(exit) ti.Release();

          TYPEATTR* typeAttr;
          if (ti.GetTypeAttr(typeAttr) == S_OK) {
            scope(exit) ti.ReleaseTypeAttr(typeAttr);
            if (typeAttr.typekind == TYPEKIND.TKIND_INTERFACE || typeAttr.typekind == TYPEKIND.TKIND_DISPATCH)
              typeName = getTypeName(desc.lptdesc, typeInfo, flags, true);
          }
          if (typeName != null)
            return typeName;
        }
      }

      if (typeName == null)
        typeName = getTypeName(desc.lptdesc, typeInfo, flags, isInterface);
      if (!isInterface && (!(flags & PARAMFLAG_FOUT) || typeName == "void"))
        typeName ~= "*";

      return typeName;
    }

    string getArrayTypeName() {
      if (desc.lpadesc.cDims == 1 && desc.lpadesc.rgbounds[desc.lpadesc.cDims - 1].cElements > 0)
        return format("{0}[{1}]", getTypeName(&desc.lpadesc.tdescElem, typeInfo, flags, isInterface), desc.lpadesc.rgbounds[desc.lpadesc.cDims - 1].cElements);
      return getTypeName(&desc.lpadesc.tdescElem, typeInfo, flags, isInterface) ~ "*";
    }

    if (desc.vt == VT_PTR)
      return getPtrTypeName();
    if (desc.vt == VT_CARRAY)
      return getArrayTypeName();

    // Try to get the name from the VARTYPE.
    string typeName = getBasicTypeName();
    if (typeName == null)
      typeName = getCustomTypeName();
    return typeName;
  }

}

///
enum FieldAttributes {
  None,
  Static,
  Constant
}

/**
 */
abstract class Field : Member {

  /**
   */
  @property override MemberTypes memberType() {
    return MemberTypes.Field;
  }

  /**
   */
  abstract VARIANT getValue();

  /**
   */
  @property abstract FieldAttributes attributes();

  /**
   */
  @property abstract Type fieldType();

}

package final class FieldImpl : Field {

  private string name_;
  private Type fieldType_;
  private FieldAttributes attr_;
  private VARIANT value_;

  override string name() {
    return name_;
  }

  override string help() {
    return null;
  }

  override VARIANT getValue() {
    return value_;
  }

  override FieldAttributes attributes() {
    return attr_;
  }

  override Type fieldType() {
    return fieldType_;
  }

  package this(Type fieldType, string name, FieldAttributes attributes) {
    fieldType_ = fieldType;
    name_ = name;
    attr_ = attributes;
  }

  package this(Type fieldType, string name, ref VARIANT value, FieldAttributes attributes) {
    value.copyTo(value_);
    //value_ = value;
    this(fieldType, name, attributes);
  }

}

///
enum MethodAttributes {
  None           = 0x0,
  Default        = 0x1,
  GetProperty    = 0x2,
  PutProperty    = 0x4,
  PutRefProperty = 0x8
}

/**
 */
abstract class Method : Member {

  /**
   */
  @property override MemberTypes memberType() {
    return MemberTypes.Method;
  }

  /**
   */
  abstract Parameter[] getParameters();

  /**
   */
  @property abstract MethodAttributes attributes();

  /**
   */
  @property abstract Type returnType();

  /**
   */
  @property abstract Parameter returnParameter();

  /**
   */
  @property abstract int id();

}

package final class MethodImpl : Method {

  private string name_;
  private string help_;
  private int id_;
  private MethodAttributes attrs_;
  private TypeLibrary typeLib_;
  private Type returnType_;
  private Parameter returnParameter_;
  private Parameter[] parameters_;

  private ITypeInfo typeInfo_;

  override @property string name() {
    return name_;
  }

  override @property string help() {
    return help_;
  }

  override Parameter[] getParameters() {
    if (parameters_ == null)
      parameters_ = Parameter.getParameters(this);
    return parameters_;
  }

  override @property MethodAttributes attributes() {
    return attrs_;
  }

  override @property Type returnType() {
    return returnType_;
  }

  override @property Parameter returnParameter() {
    if (returnParameter_ is null)
      Parameter.getParameters(this, returnParameter_, true);
    return returnParameter_;
  }

  override @property int id() {
    return id_;
  }

  package this(ITypeInfo typeInfo, string name, string help, int id, MethodAttributes attributes, Type returnType, TypeLibrary typeLib) {
    typeInfo_ = typeInfo;
    typeInfo.AddRef();
    name_ = name;
    help_ = help;
    id_ = id;
    attrs_ = attributes;
    returnType_ = returnType;
    typeLib_ = typeLib;
  }

  ~this() {
    if (typeInfo_ !is null) {
      tryRelease(typeInfo_);
      typeInfo_ = null;
    }
  }

}

///
enum ParameterAttributes {
  None       = 0x0,
  In         = 0x1,
  Out        = 0x2,
  Lcid       = 0x4,
  Retval     = 0x8,
  Optional   = 0x10,
  HasDefault = 0x20
}

/**
 */
class Parameter {

  private Member member_;
  private string name_;
  private Type parameterType_;
  private int position_;
  private ParameterAttributes attrs_;

  /**
   */
  @property string name() {
    return name_;
  }

  /**
   */
  @property int position() {
    return position_;
  }

  /**
   */
  @property ParameterAttributes attributes() {
    return attrs_;
  }

  /**
   */
  @property Member member() {
    return member_;
  }

  /**
   */
  @property Type parameterType() {
    return parameterType_;
  }

  /**
   */
  @property void parameterType(Type newType) {
    parameterType_ = newType;
  }

  /**
   */
  @property bool isIn() {
    return (attributes & ParameterAttributes.In) != 0;
  }

  /**
   */
  @property bool isOut() {
    return (attributes & ParameterAttributes.Out) != 0;
  }

  /**
   */
  @property bool isRetval() {
    return (attributes & ParameterAttributes.Retval) != 0;
  }

  /**
   */
  @property bool isOptional() {
    return (attributes & ParameterAttributes.Optional) != 0;
  }

  package this(Member owner, string name, Type parameterType, int position, ParameterAttributes attributes) {
    member_ = owner;
    name_ = name;
    parameterType_ = parameterType;
    position_ = position;
    attrs_ = attributes;

    if (isReservedWord(name_))
      name_ ~= "Param";
      
    //If name is the same as type, then rename name
    if (name_ == parameterType.name())
        name_ ~= "Param";
  }

  package static Parameter[] getParameters(MethodImpl method) {
    Parameter dummy;
    return getParameters(method, dummy, false);
  }

  package static Parameter[] getParameters(MethodImpl method, out Parameter returnParameter, bool getReturnParameter) {
    
    Parameter[] params;

    TYPEATTR* typeAttr;
    FUNCDESC* funcDesc;

    checkHResult(method.typeInfo_.GetTypeAttr(typeAttr));
    scope(exit) method.typeInfo_.ReleaseTypeAttr(typeAttr);

    for (uint i = 0; i < typeAttr.cFuncs; i++) {
      checkHResult(method.typeInfo_.GetFuncDesc(i, funcDesc));
      scope(exit) method.typeInfo_.ReleaseFuncDesc(funcDesc);

      if (funcDesc.memid == method.id && (funcDesc.invkind & method.attributes)) {
        auto bufferSize = (funcDesc.cParams + 1) * (wchar*).sizeof;
        wchar** bstrNames = cast(wchar**)CoTaskMemAlloc(bufferSize);
        memset(bstrNames, 0, bufferSize);

        uint count;
        checkHResult(method.typeInfo_.GetNames(funcDesc.memid, bstrNames, funcDesc.cParams + 1, count));

        // The element at 0 is the name of the function. We've already got this, so free it.
        freeBstr(bstrNames[0]);

        //if ((funcDesc.invkind & INVOKEKIND.INVOKE_PROPERTYPUT) || (funcDesc.invkind & INVOKEKIND.INVOKE_PROPERTYPUTREF))
        //  bstrNames[1] = toBstr("value");

        for (ushort pos = 0; pos < funcDesc.cParams; pos++) {
          ushort flags = funcDesc.lprgelemdescParam[pos].paramdesc.wParamFlags;
          TypeImpl paramType = new TypeImpl(TypeImpl.getTypeName(&funcDesc.lprgelemdescParam[pos].tdesc, method.typeInfo_, flags), method.typeLib_);

          if ((flags & PARAMFLAG_FRETVAL) && getReturnParameter && returnParameter is null)
            returnParameter = new Parameter(method, fromBstr(bstrNames[pos + 1]), paramType, -1, cast(ParameterAttributes)flags);
          else if (!getReturnParameter) {
            ParameterAttributes attrs = cast(ParameterAttributes)flags;
            if (paramType.name_ == "GUID*") {
              // Remove pointer description from GUIDs, making them ref params instead.
              paramType.name_ = "GUID";
              attrs |= (ParameterAttributes.In | ParameterAttributes.Out);
            }
            
            params ~= new Parameter(method, fromBstr(bstrNames[pos + 1]), paramType, pos, attrs);
          }
        }

        CoTaskMemFree(bstrNames);
      }
    }

    return params;
  }

}

module tlbimpd.codegen;

private import std.format,
  std.utf,
  std.stream,
  std.c.stdio,
  std.stdio,
  juno.com.core,
  juno.com.reflect,
  tlbimpd.options;

private char[] formatGuid(GUID guid) {

  void hexToChars(inout char[] chars, uint a, uint b = -1) {

    char hexToChar(uint a) {
      a = a & 0xf;
      return cast(char)((a > 9) ? a - 10 + 0x61 : a + 0x30);
    }

    chars ~= hexToChar(a >> 4);
    chars ~= hexToChar(a);
    if (b != -1) {
    chars ~= hexToChar(b >> 4);
    chars ~= hexToChar(b);
    }
  }

  char[] chars = "{ 0x";
  hexToChars(chars, guid.a >> 24, guid.a >> 16);
  hexToChars(chars, guid.a >> 8, guid.a);
  chars ~= ", 0x";
  hexToChars(chars, guid.b >> 8, guid.b);
  chars ~= ", 0x";
  hexToChars(chars, guid.c >> 8, guid.c);
  chars ~= ", 0x";
  hexToChars(chars, guid.d);
  chars ~= ", 0x";
  hexToChars(chars, guid.e);
  chars ~= ", 0x";
  hexToChars(chars, guid.f);
  chars ~= ", 0x";
  hexToChars(chars, guid.g);
  chars ~= ", 0x";
  hexToChars(chars, guid.h);
  chars ~= ", 0x";
  hexToChars(chars, guid.i);
  chars ~= ", 0x";
  hexToChars(chars, guid.j);
  chars ~= ", 0x";
  hexToChars(chars, guid.k);
  chars ~= " }";
  return chars;
}

public class StringWriter : MemoryStream {

  public this(char[] buffer = null) {
    super(buffer);
  }

  public void write(...) {
    writeFormat(_arguments, _argptr);
  }

  public void writeLine(...) {
    writeFormat(_arguments, _argptr);
    super.writeString("\r\n");
  }

  protected void writeFormat(TypeInfo[] arguments, void* argptr) {
    std.format.doFormat(delegate(dchar c) {
      char[4] buffer;
      super.writeString(std.utf.toUTF8(buffer, c));
    }, arguments, argptr);
  }

}

public class IndentingStringWriter : StringWriter {

  private StringWriter writer_;
  private int indent_;
  private bool tabsPending_;

  public this(StringWriter writer) {
    super(null);
    writer_ = writer;
  }

  public override void write(...) {
    writeFormat(_arguments, _argptr);
  }

  public override void writeLine(...) {
    writeFormat(_arguments, _argptr);
    writer_.writeLine();
    tabsPending_ = true;
  }

  protected override void writeFormat(TypeInfo[] arguments, void* argptr) {
    outputIndent();
    writer_.writeFormat(arguments, argptr);
  }

  private void outputIndent() {

    const char[100] TABS = '\t';
    const char[100] SPACES = ' ';

    if (tabsPending_) {
      int n = indent_ * lineIndent;
      if (n > 0) {
        if (indentWithTabs)
          writer_.write(TABS[0 .. n]);
        else
          writer_.write(SPACES[0 .. n]);
      }
      tabsPending_ = false;
    }
  }

}

public class CodeGenerator {

  private IndentingStringWriter output;
  private Type currentType;
  private MemberInfo currentMember;
  
  public void generateCodeFromTypeLibrary(TypeLibrary lib, StringWriter w) {
    output = new IndentingStringWriter(w);
    generateModule(lib);
  }

  private void generateModule(TypeLibrary lib) {
    generateModuleStart(lib);
    generateTypes(lib);
    generateGlobals(lib);
  }

  private void generateModuleStart(TypeLibrary lib) {
    if (emitComments) {
      char[] fileName = std.path.getBaseName(outputFileName);
      if (fileName != null)
        generateComment(fileName);
      if (lib.helpString != null)
        generateComment(lib.helpString);

      generateComment(std.string.format("Version %s.%s", lib.getVersion().major, lib.getVersion().minor));
      output.writeLine();
      output.writeLine("/*[uuid(\"" ~ lib.guid.toString()[1..$-2] ~ "\")]*/");
    }

    output.write("module ");
    output.write(moduleName);
    output.writeLine(";");
    output.writeLine();

    output.writeLine("private import juno.com.core;");
    if (!blanksBetweenMembers)
      output.writeLine();
  }

  private void generateTypes(TypeLibrary lib) {
    if (verbatimOrder) {
      foreach (Type type; lib.getTypes()) {
        if (blanksBetweenMembers)
          output.writeLine();
        generateType(type);
      }
    }
    else {
      if (emitComments) {
        output.writeLine();
        generateComment("Enums");
      }
      generateTypes(lib.findTypes(delegate bool(Type type) {
        return type.isEnum;
      }));

      if (emitComments) {
        output.writeLine();
        generateComment("Unions");
      }
      generateTypes(lib.findTypes(delegate bool(Type type) {
        return type.isUnion;
      }));

      if (emitComments) {
        output.writeLine();
        generateComment("Structs");
      }
      generateTypes(lib.findTypes(delegate bool(Type type) {
        return type.isStruct;
      }));

      if (emitComments) {
        output.writeLine();
        generateComment("Aliases");
      }
      generateTypes(lib.findTypes(delegate bool(Type type) {
        return type.isAlias;
      }));

      if (emitComments) {
        output.writeLine();
        generateComment("Interfaces");
      }
      generateTypes(lib.findTypes(delegate bool(Type type) {
        return type.isInterface;
      }));

      if (emitComments) {
        output.writeLine();
        generateComment("CoClasses");
      }
      generateTypes(lib.findTypes(delegate bool(Type type) {
        return type.isCoClass;
      }));
    }
  }

  private void generateGlobals(TypeLibrary lib) {
    FieldInfo[] fields;
    Module[] modules = lib.getModules();

    foreach (Module m; modules)
      fields ~= m.getFields();

    if (fields != null) {
      if (emitComments) {
        output.writeLine();
        generateComment("Global Variables");
      }
      foreach (FieldInfo field; fields)
        generateField(field);
    }
  }

  private void generateComment(char[] comment) {
    output.write("// ");
    output.writeLine(comment);
  }

  private void generateTypes(Type[] types) {
    foreach (Type type; types) {
      if (blanksBetweenMembers)
        output.writeLine();
      generateType(type);
    }
  }

  private void generateType(Type type) {
    currentType = type;
    generateTypeStart(type);

    if (!type.isEnum || !type.isAlias) {
      if (type.guid != GUID.init)
        outputGuid(type.guid, type);
    }

    if (type.isCoClass) {
      output.write("mixin CoClassInterfaces!(");
      bool first = true;
      foreach (Type t; type.getInterfaces()) {
        if (!(t.attributes & TypeAttributes.Source)) {
          if (emitComments && (t.attributes & TypeAttributes.Default))
            output.write("/*[default]*/ ");
          if (first)
            first = false;
          else
            output.write(", ");
          outputType(t);
        }
      }
      output.writeLine(");");
    }
    else {
      foreach (MemberInfo member; type.getMembers())
        generateTypeMember(member, type);
    }

    currentType = type;
    generateTypeEnd(type);
  }

  private void generateTypeStart(Type type) {
    if (emitComments && type.helpString != null)
      generateComment(type.helpString);

    if (type.isAlias) {
      output.write("alias ");
      outputType(type.underlyingType);
      output.write(" ");
      outputIdentifier(type.name);
      output.writeLine(";");
    }
    else {
        if (type.isInterface)
          output.write("interface ");
        else if (type.isCoClass)
          output.write("abstract class ");
        else if (type.isStruct)
          output.write("struct ");
        else if (type.isEnum) {
          output.write("enum");
          if (!noEnumNames)
            output.write(" ");
        }
        else if (type.isUnion)
          output.write("union ");
        if (!(type.isEnum && noEnumNames))
          output.write(type.name);

        Type[] baseTypes;
        baseTypes ~= type.baseType;
        baseTypes ~= type.getInterfaces();
        if (!type.isCoClass) {
          bool first = true;
          foreach (Type baseType; baseTypes) {
            if (baseType !is null) {
              if (first) {
                output.write(" : ");
                first = false;
              }
              else
                output.write(", ");
              outputType(baseType);
            }
          }
        }

        outputStartingBrace();
        indent = indent + 1;
      }
  }

  private void generateTypeEnd(Type type) {
    if (!currentType.isAlias) {
      indent = indent - 1;
      output.writeLine("}");
    }
  }

  private void generateTypeMember(MemberInfo member, Type declaringType) {
    if (member.memberType & MemberTypes.Field)
      generateField(cast(FieldInfo)member);
    else if (member.memberType & MemberTypes.Method)
      generateMethod(cast(MethodInfo)member, declaringType);
  }

  private void generateField(FieldInfo field) {
    if (currentType.isEnum) {
      outputIdentifier(field.name);
      if (field.attributes == FieldAttributes.Constant) {
        output.write(" = ");
        generateVariable(field.getValue());
      }
      output.writeLine(",");
    }
    else {
      outputAttributes(field.attributes);
      outputTypeNamePair(field.fieldType, field.name);
      if (field.attributes == FieldAttributes.Constant) {
        output.write(" = ");
        generateVariable(field.getValue());
      }
      output.writeLine(";");
    }
  }

  private void outputGuid(GUID guid, Type declaringType) {
    if (emitComments)
      output.writeLine("/*[uuid(\"" ~ guid.toString()[1..$-2] ~ "\")]*/");
    output.write("static GUID IID = ");
    output.write(formatGuid(guid));
    output.writeLine(";");
  }

  private void generateMethod(MethodInfo method, Type declaringType) {
    if (currentType.isInterface || currentType.isCoClass || currentType.isStruct) {

      if (emitComments) {
        if ((currentType.attributes & TypeAttributes.Dispatch) != 0 && (currentType.attributes & TypeAttributes.Dual) == 0)
          output.write("/+");
        if (method.helpString != null)
          generateComment(method.helpString);
        char[100] buffer;
        size_t n = sprintf(buffer, "/*[id(0x%08x)]*/", method.id);
        output.write(buffer[0 .. n]);
        output.write(" ");
      }

      outputType(method.returnType);
      output.write(" ");

      if (method.attributes == MethodAttributes.GetProperty)
        output.write("%s_", propGetPrefix);
      else if (method.attributes == MethodAttributes.PutProperty)
        output.write("%s_", propPutPrefix);
      else if (method.attributes == MethodAttributes.PutRefProperty)
        output.write("%sref_", propPutPrefix);

      output.write(method.name);
      output.write("(");
      outputParameters(method.getParameters());
      output.write(")");

      if (currentType.isInterface) {
        output.write(";");
        if ((currentType.attributes & TypeAttributes.Dispatch) != 0 && emitComments && (currentType.attributes & TypeAttributes.Dual) == 0)
          output.write("+/");
        output.writeLine();
      }
      else {
        outputStartingBrace();
        indent = indent + 1;
        indent = indent - 1;
        output.writeLine("}");
      }
    }
  }

  private void generateVariable(VARIANT var) {
    if (var.vt == VT_BSTR || var.vt == VT_LPSTR)
      output.write("\"");
    char[] value;
    if (var.vt == VT_I4) {
      char[100] buffer;
      size_t n = sprintf(buffer, "0x%x", com_cast!(int)(var));
      value = buffer[0 .. n];
    }
    else
      value = com_cast!(char[])(var);
    output.write(value);
    if (var.vt == VT_BSTR || var.vt == VT_LPSTR)
      output.write("\"");
  }

  private void outputStartingBrace() {
    if (braceOnNewLine) {
      output.writeLine();
      output.writeLine("{");
    }
    else
      output.writeLine(" {");
  }

  private void outputType(Type type) {
    output.write(type.name);
  }

  private char[] createIdentifier(char[] name) {
    if (!isReservedWord(name))
      return name;
    return "_" ~ name;
  }

  private void outputIdentifier(char[] name) {
    output.write(createIdentifier(name));
  }

  private void outputParameters(ParameterInfo[] parameters) {
    bool first = true;
    foreach (ParameterInfo p; parameters) {
      if (first)
        first = false;
      else
        output.write(", ");
      generateParameter(p);
    }
  }

  private void generateParameter(ParameterInfo parameter) {
    outputAttributes(parameter.attributes);
    outputType(parameter.parameterType);

    if (parameter.attributes & ParameterAttributes.Out && !(parameter.attributes & ParameterAttributes.In) &&
      (parameter.attributes & ParameterAttributes.Optional))
      output.write("*");
    output.write(" ");
    outputIdentifier(parameter.name);
  }

  private void outputAttributes(FieldAttributes attr) {
    if (attr & FieldAttributes.Constant)
      output.write("const ");
  }

  private void outputAttributes(ParameterAttributes attr) {
    if (attr & ParameterAttributes.Out && !(attr & ParameterAttributes.Optional)) {
      if (attr & ParameterAttributes.In)
        output.write("inout ");
      else if (attr & ParameterAttributes.Retval)
        output.write("out ");
      else
        output.write("out ");
    }
  }

  private void outputTypeNamePair(Type type, char[] name) {
    outputType(type);
    output.write(" ");
    outputIdentifier(name);
  }

  private int indent() {
    return output.indent_;
  }
  private void indent(int value) {
    output.indent_ = value;
  }

}
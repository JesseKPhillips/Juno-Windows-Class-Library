module tlbimpd.codegen;

private import juno.base.all,
  juno.io.all,
  juno.com.core,
  juno.com.reflect,
  tlbimpd.options;

public class IndentingTextWriter : TextWriter {

  private TextWriter writer_;
  private int indent_;
  private bool tabsPending_;

  public this(TextWriter writer) {
    writer_ = writer;
  }

  ~this() {
    writer_ = null;
  }

  public override void close() {
    if (writer_ !is null)
      writer_.close();
  }

  public override void write(...) {
    outputIndent();
    writer_.write(_arguments, _argptr);
  }

  public override void writeln(...) {
    outputIndent();
    writer_.writeln(_arguments, _argptr);
    tabsPending_ = true;
  }

  public override Encoding encoding() {
    return writer_.encoding;
  }

  public override char[] newLine() {
    return writer_.newLine;
  }
  public override void newLine(char[] value) {
    writer_.newLine = value;
  }

  private void outputIndent() {

    const char[100] TABS = '\t';
    const char[100] SPACES = ' ';

    if (tabsPending_) {
      int n = indent_ * 2;
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

  private IndentingTextWriter output;
  private Type currentType;
  private Member currentMember;

  public void generateCodeFromTypeLibrary(TypeLibrary typeLib, TextWriter w) {
    output = new IndentingTextWriter(w);
    generateModule(typeLib);
  }

  private void generateModule(TypeLibrary typeLib) {
    generateModuleStart(typeLib);
    generateTypes(typeLib);
    generateGlobals(typeLib);
  }

  private void generateModuleStart(TypeLibrary typeLib) {
    if (emitComments) {
      if (typeLib.documentation != null)
        generateComment(typeLib.documentation);

      generateComment(format("Version {0}.{1}", typeLib.getVersion().major, typeLib.getVersion().minor));
      output.writeln();
      output.writeln("/*[uuid(\"" ~ typeLib.guid.toString()[1 .. $ - 1] ~ "\")]*/");
    }

    output.write("module ");
    char[][] packages = moduleName.split(['.']);
    outputIdentifier(packages[0]);
    for (int i = 1; i < packages.length; i++) {
      output.write(".");
      outputIdentifier(packages[i]);
    }
    output.writeln(";");
    output.writeln();

    if (emitComments) {
      try { // There's a bug in getReferences
        foreach (reference; typeLib.getReferences()) {
          if (reference !is null) {
            char[] fileName = getFileName(reference.path);
            if (fileName != null)
              output.writeln("/*[importlib(\"" ~ fileName ~ "\")];*/");
          }
          output.writeln();
        }
      }
      catch {
      }
    }

    output.writeln("private import juno.com.core;");

    if (!blanksBetweenMembers)
      output.writeln();
  }

  private void generateTypes(TypeLibrary typeLib) {
    if (verbatimOrder) {
      foreach (type; typeLib.getTypes()) {
        if (type !is null) {
          if (blanksBetweenMembers)
            output.writeln();
          generateType(type);
        }
      }
    }
    else {
      Type[] types = typeLib.findTypes((Type type) {
        return (type !is null && type.isEnum());
      });
      if (types.length > 0) {
        if (emitComments) {
          output.writeln();
          generateComment("Enums");
        }
        generateTypes(types);
      }
      
      types = typeLib.findTypes((Type type) {
        return (type !is null && type.isUnion());
      });
      if (types.length > 0) {
        if (emitComments) {
          output.writeln();
          generateComment("Unions");
        }
        generateTypes(types);
      }
      
      types = typeLib.findTypes((Type type) {
        return (type !is null && type.isStruct());
      });
      if (types.length > 0) {
        if (emitComments) {
          output.writeln();
          generateComment("Structs");
        }
        generateTypes(types);
      }
      
      types = typeLib.findTypes((Type type) {
        return (type !is null && type.isAlias());
      });
      if (types.length > 0) {
        if (emitComments) {
          output.writeln();
          generateComment("Aliases");
        }
        generateTypes(types);
      }

      types = typeLib.findTypes((Type type) {
        return (type !is null && type.isInterface());
      });
      if (types.length > 0) {
        if (emitComments) {
          output.writeln();
          generateComment("Interfaces");
        }
        generateTypes(types);
      }

      types = typeLib.findTypes((Type type) {
        return (type !is null && type.isCoClass());
      });
      if (types.length > 0) {
        if (emitComments) {
          output.writeln();
          generateComment("CoClasses");
        }
        generateTypes(types);
      }
    }
  }

  private void generateGlobals(TypeLibrary typeLib) {
    currentType = null;
    Field[] fields;
    Method[] methods;

    foreach (m; typeLib.getModules()) {
      fields ~= m.getFields();
      methods ~= m.getMethods();
    }

    if (fields.length > 0) {
      if (emitComments) {
        output.writeln();
        generateComment("Global variables");
      }
      foreach (field; fields)
        generateField(field);
    }

    if (methods.length > 0) {
      if (emitComments) {
        output.writeln();
        generateComment("Global functions");
      }
      output.writeln();
      output.writeln("extern (Windows):");
      output.writeln();
      foreach (method; methods)
        generateMethod(method, null);
    }
  }

  private void generateComment(char[] comment) {
    output.write("// ");
    output.writeln(comment);
  }

  private void generateTypes(Type[] types) {
    foreach (type; types) {
      if (type !is null) {
        if (blanksBetweenMembers)
          output.writeln();
        generateType(type);
      }
    }
  }

  private void generateType(Type type) {
    currentType = type;
    generateTypeStart(type);

    if (!type.isEnum() && !type.isAlias()) {
      if (type.guid != GUID.init)
        outputGuid(type.guid, type);
    }

    if (type.isCoClass()) {
      output.write("mixin CoInterfaces!(");
      bool first = true;
      foreach (t; type.getInterfaces()) {
        if ((t.attributes & TypeAttributes.InterfaceIsSource) == 0) {
          if (emitComments && (t.attributes & TypeAttributes.InterfaceIsDefault) != 0)
            output.write("/*[default]*/ ");
          if (first)
            first = false;
          else
            output.write(", ");
          outputType(t);
        }
      }
      output.writeln(");");
    }
    else {
      foreach (member; type.getMembers()) {
        if (member !is null)
          generateTypeMember(member, type);
      }
    }

    currentType = type;
    generateTypeEnd(type);
  }

  private void generateTypeStart(Type type) {
    if (emitComments && type.documentation != null)
      generateComment(type.documentation);

    if (type.isAlias()) {
      output.write("alias ");
      outputType(type.underlyingType);
      output.write(" ");
      outputIdentifier(type.name);
      output.writeln(";");
    }
    else {
      if (type.isInterface())
        output.write("interface ");
      else if (type.isCoClass())
        output.write("abstract class ");
      else if (type.isStruct())
        output.write("struct ");
      else if (type.isEnum()) {
        output.write("enum");
        if (!noEnumNames)
          output.write(" ");
      }
      else if (type.isUnion())
        output.write("union ");

      if (!(type.isEnum() && noEnumNames))
        output.write(type.name);

      Type[] baseTypes;
      baseTypes ~= type.baseType;
      baseTypes ~= type.getInterfaces();

      if (!type.isCoClass()) {
        bool first = true;
        foreach (baseType; baseTypes) {
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
    if (!currentType.isAlias()) {
      indent = indent - 1;
      output.writeln("}");
    }
  }

  private void generateTypeMember(Member member, Type declaringType) {
    if ((member.memberType & MemberTypes.Field) != 0)
      generateField(cast(Field)member);
    else if ((member.memberType & MemberTypes.Method) != 0)
      generateMethod(cast(Method)member, declaringType);
  }

  private void generateField(Field field) {
    if (currentType !is null && currentType.isEnum()) {
      outputIdentifier(field.name);
      if (field.attributes == FieldAttributes.Constant) {
        output.write(" = ");
        generateVariable(field.getValue());
      }
      output.writeln(",");
    }
    else {
      if (currentType !is null &&
        (currentType.attributes & TypeAttributes.InterfaceIsDispatch) != 0 &&
        (currentType.attributes & TypeAttributes.InterfaceIsDual) == 0)
        output.write("/+");
      outputAttributes(field.attributes);
      outputTypeNamePair(field.fieldType, field.name);
      if (field.attributes == FieldAttributes.Constant) {
        output.write(" = ");
        generateVariable(field.getValue());
      }
      output.write(";");
      if (currentType !is null &&
        (currentType.attributes & TypeAttributes.InterfaceIsDispatch) != 0 &&
        (currentType.attributes & TypeAttributes.InterfaceIsDual) == 0)
        output.write("+/");
      output.writeln();
    }
  }

  private void generateMethod(Method method, Type declaringType) {
    if (currentType is null || (currentType.isInterface() || currentType.isCoClass() || currentType.isStruct())) {
      if (currentType !is null &&
        (currentType.attributes & TypeAttributes.InterfaceIsDispatch) != 0 &&
        (currentType.attributes & TypeAttributes.InterfaceIsDual) == 0)
        output.write("/+");
      if (emitComments) {
        if (method.documentation != null)
          generateComment(method.documentation);
        output.write("/*[id(0x{0:X8})]*/", method.dispId);
        output.write(" ");
      }

      outputType(method.returnType);
      output.write(" ");

      if (method.attributes == MethodAttributes.GetProperty)
        output.write(propGetPrefix ~ "_");
      else if (method.attributes == MethodAttributes.PutProperty)
        output.write(propPutPrefix ~ "_");
      else if (method.attributes == MethodAttributes.PutRefProperty)
        output.write(propPutPrefix ~ "ref_");

      output.write(method.name);
      output.write("(");
      outputParameters(method.getParameters());
      output.write(")");

      if (currentType is null || currentType.isInterface()) {
        output.write(";");
        if (currentType !is null &&
          (currentType.attributes & TypeAttributes.InterfaceIsDispatch) != 0 &&
          (currentType.attributes & TypeAttributes.InterfaceIsDual) == 0)
          output.write("+/");
        output.writeln();
      }
      else {
        outputStartingBrace();
        output.writeln("}");
      }
    }
  }

  private void generateParameter(Parameter parameter) {
    outputAttributes(parameter.attributes);
    outputType(parameter.parameterType);

    if ((parameter.attributes & ParameterAttributes.Out) != 0 && 
      (parameter.attributes & ParameterAttributes.In) == 0 &&
      (parameter.attributes & ParameterAttributes.Optional) != 0)
      output.write("*");

    output.write(" ");
    outputIdentifier(parameter.name);
  }

  private void outputAttributes(ParameterAttributes attr) {
    if ((attr & ParameterAttributes.Out) != 0 && (attr & ParameterAttributes.Optional) == 0) {
      if ((attr & ParameterAttributes.In) != 0)
        output.write("inout ");
      else
      //else if ((attr & ParameterAttributes.Retval) != 0)
        output.write("out ");
    }
    else if ((attr & ParameterAttributes.In) != 0 && (attr & ParameterAttributes.Optional) == 0)
      output.write("in ");
  }

  private void generateVariable(VARIANT var) {

    char[] quoteSnippet(char[] value) {
      char[] result = "\"";
      for (int i = 0; i < value.length; i++) {
        char c = value[i];
        if (c == '\\')
          result ~= r"\\";
        else if (c == '\'')
          result ~= r"\'";
        else if (c == '\t')
          result ~= r"\t";
        else if (c == '\r')
          result ~= r"\r";
        else if (c == '\n')
          result ~= r"\n";
        else if (c == '\v')
          result ~= r"\v";
        else if (c == '\b')
          result ~= r"\b";
        else if (c == '\f')
          result ~= r"\f";
        else if (c == '"')
          result ~= "\\\"";
        else if (c == '\0')
          result ~= r"\0";
        else
          result ~= c;
      }
      result ~= "\"";
      return result;
    }

    char[] value;
    if (var.vt == VT_I4)
      value = format("0x{0:X8}", var.lVal);
    else if (var.vt == VT_BOOL)
      value = (var.boolVal == VARIANT_TRUE) ? "true" : "false";
    else if (var.vt == VT_NULL)
      value = "null";
    else
      value = var.toString();
    if (var.vt == VT_BSTR || var.vt == VT_LPSTR || var.vt == VT_LPWSTR)
      value = quoteSnippet(value);
    try {
      output.write(value);
    }
    catch {
    }
  }

  private void outputType(Type type) {
    output.write(type.name);
  }

  private void outputGuid(GUID guid, Type declaringType) {
    if (emitComments)
      output.writeln("/*[uuid(\"" ~ guid.toString()[1 .. $ - 1] ~ "\")]*/");
    output.write("static GUID ");
    if (declaringType.isCoClass())
      output.write("CLSID");
    else
      output.write("IID");
    output.write(" = ");
    output.write(formatGuid(guid));
    output.writeln(";");
  }

  private void outputStartingBrace() {
    if (braceOnNewLine) {
      output.writeln();
      output.writeln("{");
    }
    else
      output.writeln(" {");
  }

  private void outputParameters(Parameter[] parameters) {
    bool first = true;
    foreach (param; parameters) {
      if (param !is null) {
        if (first)
          first = false;
        else
          output.write(", ");
        generateParameter(param);
      }
    }
  }

  private char[] createIdentifier(char[] name) {
    if (name == null)
      return defaultParamName;
    if (!isReservedWord(name))
      return name;
    return "_" ~ name;
  }

  private void outputIdentifier(char[] name) {
    output.write(createIdentifier(name));
  }

  private void outputAttributes(FieldAttributes attr) {
    if ((attr & FieldAttributes.Constant) != 0)
      output.write("const ");
  }

  private void outputTypeNamePair(Type type, char[] name) {
    outputType(type);
    output.write(" ");
    outputIdentifier(name);
  }

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

  private int indent() {
    return output.indent_;
  }
  public void indent(int value) {
    output.indent_ = value;
  }

}
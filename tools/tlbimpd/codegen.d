module tlbimpd.codegen;

//private import juno.base.all, juno.com.all;
private import juno.io.core, juno.base.text, juno.com.core, juno.com.reflect;
private import juno.base.string : split;
private import tlbimpd.options;

private import std.string : format;
private import std.path : getBaseName;

debug private import std.stdio;

class IndentingWriter : Writer {

  private Writer writer_;
  private int indent_;
  private bool tabsPending_;

  this(Writer writer) {
    writer_ = writer;
  }

  ~this() {
    writer_ = null;
  }

  override void close() {
    if (writer_ !is null)
      writer_.close();
  }

  override void write(...) {
    outputIndent();
    writer_.write(_arguments, _argptr);
  }

  override void writeln(...) {
    outputIndent();
    writer_.writeln(_arguments, _argptr);
    tabsPending_ = true;
  }

  override void newLine(string value) {
    writer_.newLine = value;
  }

  override string newLine() {
    return writer_.newLine;
  }

  @property override Encoding encoding() {
    return writer_.encoding;
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

class CodeGenerator {

  private IndentingWriter output;
  private Type currentType;
  private Member currentMember;

  void generateCodeFromTypeLibrary(TypeLibrary typeLib, Writer w) {
    output = new IndentingWriter(w);
    generateModuleStart(typeLib);
    generateTypes(typeLib);
    generateGlobals(typeLib);
  }

  private void generateModuleStart(TypeLibrary typeLib) {
    if (emitComments) {
      if (typeLib.help != null)
        generateComment(typeLib.help);

      generateComment("Version " ~ typeLib.getVersion().toString());
      output.writeln();
      output.writeln("/*[uuid(\"" ~ typeLib.guid.toString() ~ "\")]*/");
    }

    output.write("module ");
    string[] packages = moduleName.split(['.']);
    outputIdentifier(packages[0]);
    for (int i = 1; i < packages.length; i++) {
      output.write(".");
      outputIdentifier(packages[i]);
    }
    output.writeln(";");
    output.writeln();

    if (emitComments) {
      foreach (reference; typeLib.getReferences()) {
        if (reference !is null) {
          string fileName = getBaseName(reference.location);
          if (fileName != null)
            output.writeln("/*[importlib(\"" ~ fileName ~ "\")]*/");
        }
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
        return type !is null && type.isEnum;
      });
      if (types.length > 0) {
        if (emitComments) {
          output.writeln();
          generateComment("Enums");
        }

        generateTypes(types);
      }

      types = typeLib.findTypes((Type type) {
        return type !is null && type.isUnion;
      });
      if (types.length > 0) {
        if (emitComments) {
          output.writeln();
          generateComment("Union");
        }
        generateTypes(types);
      }

      types = typeLib.findTypes((Type type) {
        return type !is null && type.isStruct;
      });
      if (types.length > 0) {
        if (emitComments) {
          output.writeln();
          generateComment("Structs");
        }
        generateTypes(types);
      }

      types = typeLib.findTypes((Type type) {
        return type !is null && type.isAlias;
      });
      if (types.length > 0) {
        if (emitComments) {
          output.writeln();
          generateComment("Aliases");
        }
        generateTypes(types);
      }

      types = typeLib.findTypes((Type type) {
        return type !is null && type.isInterface;
      });
      if (types.length > 0) {
        if (emitComments) {
          output.writeln();
          generateComment("Interfaces");
        }
        generateTypes(types);
      }

      types = typeLib.findTypes((Type type) {
        return type !is null && type.isCoClass;
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
      output.writeln("extern(Windows):");
      output.writeln();
      foreach (method; methods)
        generateMethod(method, null);
    }
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

    if (!type.isEnum && !type.isAlias) {
      if (type.guid != GUID.empty)
        outputGuid(type.guid, type);
    }

    if (type.isCoClass) {
      output.write("mixin Interfaces!(");
      bool first = true;
      foreach (t; type.getInterfaces()) {
        if ((t.attributes & TypeAttributes.InterfaceIsSource) == 0) {
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
    if (emitComments && type.help != null)
      generateComment(type.help);

    if (type.isAlias) {
      output.write("alias ");
      outputType(type.underlyingType);
      output.write(" ");
      outputIdentifier(type.name);
      output.writeln(";");
    }
    else {
      if (type.isInterface)
        output.write("interface ");
      else if (type.isCoClass)
        output.write("abstract final class ");
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
        outputType(type);

      if (type.baseType !is null && !type.isCoClass) {
        output.write(" : ");
        outputType(type.baseType);
      }

      outputStartingBrace();
      indent = indent + 1;
    }
  }

  private void generateTypeEnd(Type type) {
    if (!currentType.isAlias) {
      indent = indent - 1;
      output.writeln("}");
    }
  }

  private void generateTypeMember(Member member, Type declaringType) {
    if (member.memberType & MemberTypes.Field)
      generateField(cast(Field)member);
    else if (member.memberType & MemberTypes.Method)
      generateMethod(cast(Method)member, declaringType);
  }

  private void generateField(Field field) {
    if (currentType !is null && currentType.isEnum) {
      outputIdentifier(field.name);
      if (field.attributes == FieldAttributes.Constant) {
        output.write(" = ");
        generateVariable(field.getValue());
      }
      output.writeln(",");
    }
    else {
      if (currentType !is null 
        && (currentType.attributes & TypeAttributes.InterfaceIsDispatch)
        && !(currentType.attributes & TypeAttributes.InterfaceIsDual))
        output.write("/+");
      outputAttributes(field.attributes);
      outputTypeNamePair(field.fieldType, field.name);
      if (field.attributes == FieldAttributes.Constant) {
        output.write(" = ");
        generateVariable(field.getValue());
      }
      output.write(";");
      if (currentType !is null 
        && (currentType.attributes & TypeAttributes.InterfaceIsDispatch)
        && !(currentType.attributes & TypeAttributes.InterfaceIsDual))
        output.write("+/");
      output.writeln();
    }
  }

  private void generateMethod(Method method, Type declaringType) {
    if (currentType is null || (currentType.isInterface || currentType.isCoClass || currentType.isStruct)) {
      if (currentType !is null
        && (currentType.attributes & TypeAttributes.InterfaceIsDispatch)
        && !(currentType.attributes & TypeAttributes.InterfaceIsDual))
        output.write("/+"); // Comment out late-bound methods.
      if (emitComments) {
        if (method.help != null)
          generateComment(method.help);
        output.write(format("/*[id(0x%08X)]*/", method.id));
        output.write(" ");
      }

      outputType(method.returnType);
      output.write(" ");

      if (method.attributes & MethodAttributes.GetProperty)
        output.write(propGetPrefix ~ "_");
      else if (method.attributes & MethodAttributes.PutProperty)
        output.write(propPutPrefix ~ "_");
      else if (method.attributes & MethodAttributes.PutRefProperty)
        output.write(propPutPrefix ~ "ref_");

      output.write(method.name);
      output.write("(");
      outputParameters(method.getParameters());
      output.write(")");

      if (currentType is null || currentType.isInterface) {
        output.write(";");
        if (currentType !is null
          && (currentType.attributes & TypeAttributes.InterfaceIsDispatch)
          && !(currentType.attributes & TypeAttributes.InterfaceIsDual))
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
    // Treat void* as a special case
    if (!((parameter.attributes & ParameterAttributes.Out) && parameter.parameterType.name == "void*"))
      outputAttributes(parameter.attributes);
    outputType(parameter.parameterType);

    if ((parameter.attributes & ParameterAttributes.Out)
      && !(parameter.attributes & ParameterAttributes.In)
      && ((parameter.attributes & ParameterAttributes.Optional) 
        || ((parameter.attributes & ParameterAttributes.Retval) 
        && parameter.parameterType.name == "void*")))
      output.write("*");

    output.write(" ");
    outputIdentifier(parameter.name);
  }

  private void outputAttributes(ParameterAttributes attr) {
    if ((attr & ParameterAttributes.Out) && !(attr & ParameterAttributes.Optional)) {
      if (attr & ParameterAttributes.In)
        output.write("ref ");
      else// if (attr & ParameterAttributes.Retval)
        output.write("out ");
    }
  }

  private void outputAttributes(FieldAttributes attr) {
    if (attr & FieldAttributes.Constant)
      output.write("const ");
  }

  private void outputTypeNamePair(Type type, string name) {
    outputType(type);
    output.write(" ");
    outputIdentifier(name);
  }

  private void generateVariable(VARIANT var) {

    string quoteSnippet(string value) {
      string result = "\"";
      foreach (c; value) {
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

    string value;
    if (var.vt == VT_I4)
      value = format("0x%08X", var.lVal);
    else if (var.vt == VT_BOOL)
      value = (var.boolVal == VARIANT_TRUE) ? "true" : "false";
    else if (var.vt == VT_NULL)
      value = "null";
    else
      value = var.toString();
    if (var.vt == VT_BSTR || var.vt == VT_LPSTR || var.vt == VT_LPWSTR)
      value = quoteSnippet(value);
    output.write(value);
  }

  private void generateComment(string comment, bool docComment = false) {
    output.write(docComment ? "///" : "//");
    output.write(" ");
    output.writeln(comment);
  }

  private void outputType(Type type) {
    if (isReservedClassName(type.name))
      output.write("Com" ~ type.name);
    else
      output.write(type.name);
  }

  private void outputGuid(GUID guid, Type declaringType) {
    output.write("mixin(uuid(\"" ~ guid.toString() ~ "\"))");
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

  private string createIdentifier(string name) {
    if (name == null)
      name = defaultParamName;
    if (!isReservedWord(name))
      return name;
    return "_" ~ name;
  }

  private void outputIdentifier(string name) {
    output.write(createIdentifier(name));
  }

  @property private void indent(int value) {
    output.indent_ = value;
  }

  @property private int indent() {
    return output.indent_;
  }

}

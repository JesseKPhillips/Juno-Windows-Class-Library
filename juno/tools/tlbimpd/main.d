module tlbimpd.main;

import std.stdio,
  std.conv,
  std.string,
  std.file,
  std.path,
  std.stream,
  juno.com.core,
  juno.com.reflect,
  tlbimpd.options,
  tlbimpd.util,
  tlbimpd.codegen;

char[] generateSource(char[] path) {
  auto TypeLibrary typeLib = TypeLibrary.load(path);
  char[] fileName = std.path.getBaseName(path);

  if (moduleName == null)
    moduleName = typeLib.name().tolower();
  if (!silentMode)
    std.stdio.writefln("Reading type library " ~ typeLib.name().tolower());

  StringWriter w = new StringWriter;
  auto codeGenerator = new CodeGenerator;
  codeGenerator.generateCodeFromTypeLibrary(typeLib, w);
  w.close();
  return w.toString();
}

void main(char[][] args) {
  if (args.length > 1) {
    char[] typeLibraryPath;

    ArgParser parser = new ArgParser(delegate uint(char[] value, uint index) {
      typeLibraryPath = value;
      return value.length;
    });
    parser.bind("/", "comments", delegate { emitComments = true; });
    parser.bind("/", "noblanks", delegate { blanksBetweenMembers = false; });
    parser.bind("/", "noenums", delegate { noEnumNames = true; });
    parser.bind("/", "nologo", delegate { suppressBanner = true; });
    parser.bind("/", "silent", delegate { silentMode = true; });
    parser.bind("/", "tabs", delegate { indentWithTabs = true; });
    parser.bind("/", "indent:", delegate uint(char[] value) {
      lineIndent = toInt(value);
      if (lineIndent > 10)
        lineIndent = 10;
      return value.length;
    });
    parser.bind("/", "braces:", delegate uint(char[] value) {
      braceOnNewLine = (value == "newline");
      return value.length;
    });
    parser.bind("/", "module:", delegate uint(char[] value) {
      moduleName = value;
      return value.length;
    });
    parser.bind("/", "out:", delegate uint(char[] value) {
      outputFileName = value;
      return value.length;
    });
    parser.bind("/", "propget:", delegate uint(char[] value) {
      propGetPrefix = value;
      return value.length;
    });
    parser.bind("/", "propput:", delegate uint(char[] value) {
      propPutPrefix = value;
      return value.length;
    });
    parser.bind("/", "unnamed:", delegate uint(char[] value) {
      defaultParamName = value;
      return value.length;
    });
    parser.bind("/", "order:", delegate uint(char[] value) {
      verbatimOrder = (value == "verbatim");
      return value.length;
    });

    parser.parse(args[1 .. $]);

    bool succeeded;
    try {
      if (!suppressBanner && !silentMode) {
        std.stdio.writefln("D Type Library Importer");
        std.stdio.writefln();
      }

      if (typeLibraryPath != null) {
        char[] source = generateSource(typeLibraryPath);

        if (outputFileName == null)
          outputFileName = std.path.addExt(moduleName, "d");

        auto Stream fs = new File(outputFileName, FileMode.OutNew);
        fs.writeString(source);
        succeeded = true;
      }
    }
    catch (COMException ex) {
      if (!silentMode)
        std.stdio.writefln("Import failed with the following error: " ~ ex.msg ~ "\n");
    }
    catch (StreamException ex) {
      if (!silentMode)
        std.stdio.writefln("Import failed with the following error: " ~ ex.msg ~ "\n");
    }
    catch (FileException ex) {
      if (!silentMode)
        std.stdio.writefln("Import failed with the following error: " ~ ex.msg ~ "\n");
    }
    catch (Exception ex) {
      if (!silentMode)
        std.stdio.writefln("Import failed with the following error: " ~ ex.msg ~ "\n");
    }
    finally {
      if (!silentMode && succeeded)
        std.stdio.writefln("Module " ~ moduleName ~ " was generated successfully\n");
    }
  }
}
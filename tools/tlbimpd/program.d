module tlbimpd.program;

import juno.base.all,
  juno.io.all,
  juno.com.all,
  tlbimpd.codegen,
  tlbimpd.options,
  tlbimpd.utils;

import std.stream : FileStream = File, FileMode;

void printLogo() {
  Console.writeln("Type Library to D Module Converter 1.0");
  Console.writeln();
}

void printUsage() {
  Console.writeln("Syntax: tlbimpd TypeLibName [Options]");
  Console.writeln("Options:");
  Console.writeln("    /comments             Adds documentation as comments");
  Console.writeln("    /noblanks             Omits blank lines between members");
  Console.writeln("    /noenums              Prevents generating named enums");
  Console.writeln("    /nologo               Omits display of logo");
  Console.writeln("    /silent               Suppresses all output except errors");
  Console.writeln("    /tabs                 Indents new lines with tabs instead of spaces");
  Console.writeln("    /indent:indentCount   Indents new lines with the specified number of spaces");
  Console.writeln("    /braces:newLine       Places braces on a new line");
  Console.writeln("    /module:moduleName    Name of module to be produced");
  Console.writeln("    /out:fileName         File name of module to be produced");
  Console.writeln("    /propget:prefix       Prefix to use for property getters");
  Console.writeln("    /propput:prefix       Prefix to use for property setters");
  Console.writeln("    /unnamed:value        Value for unnamed parameters");
  Console.writeln("    /order:verbatim       Generate types in original order");
  Console.writeln("    /? or /help           Displays this usage message");
  Console.writeln();
}

void run(string path) {
  scope typeLib = TypeLibrary.load(path);
  if (moduleName == null)
    moduleName = typeLib.name().toLower();
  if (outputFileName == null)
    outputFileName = moduleName ~ ".d";

  scope writer = new StringWriter;
  auto codeGen = new CodeGenerator;
  codeGen.generateCodeFromTypeLibrary(typeLib, writer);

  scope s = new FileStream(outputFileName, FileMode.OutNew);
  string str = writer.toString();
  ubyte[] bytes = writer.encoding.encode(str.dup);
  s.write(bytes);
}

void main(string[] args) {
  if (args.length > 1) {
    string typeLibPath;
    bool showHelp;

    ArgParser parser = new ArgParser((string value, int index) {
      typeLibPath = value;
      return value.length;
    });

    parser.bind("/", "comments", { emitComments = true; });
    parser.bind("/", "noblanks", { blanksBetweenMembers = false; });
    parser.bind("/", "noenums", { noEnumNames = true; });
    parser.bind("/", "nologo", { suppressBanner = true; });
    parser.bind("/", "silent", { silentMode = true; });
    parser.bind("/", "tabs", { indentWithTabs = true; });
    parser.bind("/", "help", { showHelp = true; });
    parser.bind("/", "?", { showHelp = true; });
    parser.bind("/", "indent:", (string value) {
      lineIndent = parse!(int)(value);
      if (lineIndent > 10)
        lineIndent = 10;
      return value.length;
    });
    parser.bind("/", "braces:", (string value) {
      braceOnNewLine = (value == "newLine");
      return value.length;
    });
    parser.bind("/", "module:", (string value) {
      moduleName = value;
      return value.length;
    });
    parser.bind("/", "out:", (string value) {
      outputFileName = value;
      return value.length;
    });
    parser.bind("/", "propget:", (string value) {
      propGetPrefix = value;
      return value.length;
    });
    parser.bind("/", "propput:", (string value) {
      propPutPrefix = value;
      return value.length;
    });
    parser.bind("/", "unnamed:", (string value) {
      defaultParamName = value;
      return value.length;
    });
    parser.bind("/", "order:", (string value) {
      verbatimOrder = (value == "verbatim");
      return value.length;
    });

    parser.parse(args[1 .. $]);

    bool succeeded = false;

    if (!suppressBanner && !silentMode)
      printLogo();

    if (showHelp)
      printUsage();
    else {
      try {
        if (typeLibPath == null)
          throw new Exception("No input file was specified.");
        else {
          run(typeLibPath);
          succeeded = true;
        }
      }
      catch (Exception ex) {
        Console.writeln(ex.msg);
        Console.writeln();
      }
      finally {
        if (!silentMode && succeeded) {
          Console.writeln("Type library '" ~ getFileName(typeLibPath) ~ "' exported to '" ~ outputFileName ~ "'.");
          Console.writeln();
        }
      }
    }
  }
  else {
    printLogo();
    printUsage();
  }
}
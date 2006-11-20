module tlbimpd.program;

private import juno.base.all,
  juno.io.all,
  juno.com.all,
  tlbimpd.codegen,
  tlbimpd.utils,
  tlbimpd.options;
private import std.stdio : writefln, writeln = writefln;
private import std.stream : File, FileStream = File;
private import std.stream : FileMode;
private import convert = std.conv;

void printUsage() {
  writeln("Syntax: tlbimpd TypeLibName [Options]");
  writeln("Options:");
  writeln("    /comments             Adds documentation as comments");
  writeln("    /noblanks             Omits blank lines between members");
  writeln("    /noenums              Prevents generating named enums");
  writeln("    /nologo               Omits display of logo");
  writeln("    /silent               Suppresses all output except errors");
  writeln("    /tabs                 Indents new lines with tabs instead of spaces");
  writeln("    /indent:indentCount   Indents new lines with the specified number of spaces");
  writeln("    /braces:newLine       Places braces on a new line");
  writeln("    /module:moduleName    Name of module to be produced");
  writeln("    /out:fileName         File name of module to be produced");
  writeln("    /propget:prefix       Prefix to use for property getters");
  writeln("    /propput:prefix       Prefix to use for property setters");
  writeln("    /unnamed:value        Value for unnamed parameters");
  writeln("    /order:verbatim       Generate types in original order");
  writeln("    /? or /help           Displays this usage message");
  writeln();
}

void printLogo() {
  writeln("Type Library to D Module Converter 1.0");
  writeln();
}

void run(char[] path) {
  char[] fullPath = getFullPath(path);
  scope TypeLibrary typeLib = TypeLibrary.load(fullPath);
  if (moduleName == null)
    moduleName = typeLib.name().toLower();
  if (outputFileName == null)
    outputFileName = moduleName ~ ".d";//changeExtension(moduleName, "d");

  StringWriter writer = new StringWriter;
  CodeGenerator codeGen = new CodeGenerator;
  try {
    codeGen.generateCodeFromTypeLibrary(typeLib, writer);
  }
  finally {
    writer.close();
  }

  FileStream s = new FileStream(outputFileName, FileMode.OutNew);
  try {
    char[] chars = writer.toString();
    ubyte[] bytes = writer.encoding.encode(chars);
    s.write(bytes);
  }
  finally {
    s.close();
  }
}

void main(char[][] args) {
  if (args.length > 1) {
    char[] typeLibPath;
    bool showHelp = false;

    ArgParser parser = new ArgParser(delegate uint(char[] value, uint index) {
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
    parser.bind("/", "indent:", (char[] value) {
      lineIndent = convert.toInt(value);
      if (lineIndent > 10)
        lineIndent = 10;
      return value.length;
    });
    parser.bind("/", "braces:", (char[] value) {
      braceOnNewLine = (value == "newLine");
      return value.length;
    });
    parser.bind("/", "module:", (char[] value) {
      moduleName = value;
      return value.length;
    });
    parser.bind("/", "out:", (char[] value) {
      outputFileName = value;
      return value.length;
    });
    parser.bind("/", "propget:", (char[] value) {
      propGetPrefix = value;
      return value.length;
    });
    parser.bind("/", "propput:", (char[] value) {
      propPutPrefix = value;
      return value.length;
    });
    parser.bind("/", "uunamed:", (char[] value) {
      defaultParamName = value;
      return value.length;
    });
    parser.bind("/", "order:", (char[] value) {
      verbatimOrder = (value == "verbatim");
      return value.length;
    });

    parser.parse(args[1 .. $]);

    if (getExtension(typeLibPath) == ".d") {
      scope FileStream fs = new FileStream(typeLibPath, FileMode.In);
      typeLibPath = null;

      while (!fs.eof) {
        char[] line = fs.readLine();
        if (line.indexOf("+/") != -1 && line.indexOf("@import") != -1 && line.indexOf("+/") != -1) {
          int start = line.indexOf("@import") + "@import".length + 1;
          int end = line[start .. $].indexOf(';');

          if (end < line.length) {
            char[][] arguments;
            char[] command = line[start .. start + end];
            int quoteStart = command.indexOf('\"');
            int quoteEnd = -1;
            if (quoteStart != -1) {
              quoteEnd = command[quoteStart + 1 .. $].indexOf('\"');
              if (quoteEnd != -1)
                typeLibPath = command[quoteStart + 1 .. quoteStart + 1 + quoteEnd];
            }

            if (quoteEnd != -1)
              arguments = command[quoteStart + 1 + quoteEnd + 1 .. $].split([' ']);
            else
              arguments = command.split([' ']);

            if (typeLibPath != null || arguments.length > 0) {
              parser = new ArgParser(delegate uint(char[] value, uint index) {
                typeLibPath = value;
                return value.length;
              });

              parser.bind(null, "comments", { emitComments = true; });
              parser.bind(null, "noblanks", { blanksBetweenMembers = false; });
              parser.bind(null, "noenums", { noEnumNames = true; });
              parser.bind(null, "nologo", { suppressBanner = true; });
              parser.bind(null, "silent", { silentMode = true; });
              parser.bind(null, "tabs", { indentWithTabs = true; });
              parser.bind(null, "help", { showHelp = true; });
              parser.bind(null, "?", { showHelp = true; });
              parser.bind(null, "indent:", (char[] value) {
                lineIndent = convert.toInt(value);
                if (lineIndent > 10)
                  lineIndent = 10;
                return value.length;
              });
              parser.bind(null, "braces:", (char[] value) {
                braceOnNewLine = (value == "newLine");
                return value.length;
              });
              parser.bind(null, "module:", (char[] value) {
                moduleName = value;
                return value.length;
              });
              parser.bind(null, "out:", (char[] value) {
                outputFileName = value;
                return value.length;
              });
              parser.bind(null, "propget:", (char[] value) {
                propGetPrefix = value;
                return value.length;
              });
              parser.bind(null, "propput:", (char[] value) {
                propPutPrefix = value;
                return value.length;
              });
              parser.bind(null, "uunamed:", (char[] value) {
                defaultParamName = value;
                return value.length;
              });
              parser.bind(null, "order:", (char[] value) {
                verbatimOrder = (value == "verbatim");
                return value.length;
              });

              parser.parse(arguments);

              break;
            }
          }
        }
      }
    }

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
        writeln(ex.msg);
        writeln();
      }
      finally {
        if (!silentMode && succeeded)
          writeln("Type library '" ~ getFileName(typeLibPath) ~ "' exported to '" ~ outputFileName ~ "'.", \n);
      }
    }
  }
  else {
    printLogo();
    printUsage();
  }
}
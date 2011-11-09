module tlbimpd.program;

import tlbimpd.utils,
       tlbimpd.options,
       tlbimpd.codegen;

import juno.base.core,
       juno.base.string,
       juno.com.reflect,
       juno.io.core,
       juno.locale.convert;

import std.stdio : writefln, writeln;
import std.path : getBaseName, getExt;
import std.stream : File, FileMode;

void printLogo() {
  writefln("Type Library to D Module Converter 1.0");
  writeln();
}

void printUsage() {
  writefln("Syntax: tlbimpd TypeLibName [Options]");
  writefln("Options:");
  writefln("    /comments             Adds documentation as comments");
  writefln("    /noblanks             Omits blank lines between members");
  writefln("    /noenums              Prevents generating named enums");
  writefln("    /nologo               Omits display of logo");
  writefln("    /silent               Suppresses all output except errors");
  writefln("    /tabs                 Indents new lines with tabs instead of spaces");
  writefln("    /indent:indentCount   Indents new lines with the specified number of spaces");
  writefln("    /braces:newLine       Places braces on a new line");
  writefln("    /module:moduleName    Name of module to be produced");
  writefln("    /out:fileName         File name of module to be produced");
  writefln("    /propget:prefix       Prefix to use for property getters");
  writefln("    /propput:prefix       Prefix to use for property setters");
  writefln("    /unnamed:value        Value for unnamed parameters");
  writefln("    /order:verbatim       Generate types in original order");
  writefln("    /? or /help           Displays this usage message");
  writeln();
}

private string actualTypeLibPath;

void run(string path) {
  scope typeLib = TypeLibrary.load(path);
  // 'path' might be a GUID
  actualTypeLibPath = typeLib.location;

  if (moduleName == null)
    moduleName = typeLib.name().toLower();
  if (outputFileName == null)
    outputFileName = moduleName ~ ".d";

  scope writer = new StringWriter;
  auto codeGen = new CodeGenerator;
  codeGen.generateCodeFromTypeLibrary(typeLib, writer);

  scope s = new File(outputFileName, FileMode.OutNew);
  string str = writer.toString();
  ubyte[] bytes = writer.encoding.encode(str);
  s.write(bytes);
}

void main(string[] args) {
  if (args.length > 1) {
    string typeLibPath;
    bool showHelp;

    auto parser = new ArgParser((string value, int index) { typeLibPath = value; });
    parser.bind("/", "comments", { emitComments = true; });
    parser.bind("/", "noenums", { noEnumNames = true; });
    parser.bind("/", "nologo", { suppressBanner = true; });
    parser.bind("/", "silent", { slientMode = true; });
    parser.bind("/", "tabs", { indentWithTabs = true; });
    parser.bind("/", "?", { showHelp = true; });
    parser.bind("/", "help", { showHelp = true; });
    parser.bind("/", "indent:", (string value) {
      lineIndent = parse!(int)(value);
      if (lineIndent > 10)
        lineIndent = 10;
    });
    parser.bind("/", "braces:", (string value) { braceOnNewLine = (value == "newLine"); });
    parser.bind("/", "module:", (string value) { moduleName = value; });
    parser.bind("/", "out:", (string value) { outputFileName = value; });
    parser.bind("/", "propget:", (string value) { propGetPrefix = value; });
    parser.bind("/", "propput:", (string value) { propPutPrefix = value; });
    parser.bind("/", "unnamed:", (string value) { defaultParamName = value; });
    parser.bind("/", "order:", (string value) { verbatimOrder = (value == "verbatim"); });

    parser.parse(args[1 .. $]);

    if (getExt(typeLibPath) == "d") {
      scope s = new File(typeLibPath, FileMode.In);
      typeLibPath = null;

      while (!s.eof) {
        string line = s.readLine().idup;
        if (line.indexOf("/+") != -1 && line.indexOf("@import") != -1 && line.indexOf("+/") != -1) {
          int start = line.indexOf("@import") + "@import".length + 1;
          int end = line[start .. $].indexOf(';');

          if (end < line.length) {
            string[] arguments;
            string command = line[start .. start + end];
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
              parser = new ArgParser((string value, int index) { typeLibPath = value; });
              parser.bind(null, "comments", { emitComments = true; });
              parser.bind(null, "noenums", { noEnumNames = true; });
              parser.bind(null, "nologo", { suppressBanner = true; });
              parser.bind(null, "silent", { slientMode = true; });
              parser.bind(null, "tabs", { indentWithTabs = true; });
              parser.bind(null, "?", { showHelp = true; });
              parser.bind(null, "help", { showHelp = true; });
              parser.bind(null, "indent:", (string value) {
                lineIndent = parse!(int)(value);
                if (lineIndent > 10)
                  lineIndent = 10;
              });
              parser.bind(null, "braces:", (string value) { braceOnNewLine = (value == "newLine"); });
              parser.bind(null, "module:", (string value) { moduleName = value; });
              parser.bind(null, "out:", (string value) { outputFileName = value; });
              parser.bind(null, "propget:", (string value) { propGetPrefix = value; });
              parser.bind(null, "propput:", (string value) { propPutPrefix = value; });
              parser.bind(null, "unnamed:", (string value) { defaultParamName = value; });
              parser.bind(null, "order:", (string value) { verbatimOrder = (value == "verbatim"); });

              parser.parse(arguments);

              break;
            }
          }
        }
      }
    }

    bool succeeded;

    if (!suppressBanner && !slientMode)
      printLogo();

    if (showHelp)
      printUsage();
    else {
      try {
        if (typeLibPath == null)
          throw new ArgumentException("No input file was specified.");
        else {
          run(typeLibPath);
          succeeded = true;
        }
      }
      catch (Exception ex) {
        writefln(ex.msg);
        writeln();
      }
      finally {
        if (!slientMode && succeeded) {
          writefln("Type library '" ~ getBaseName(actualTypeLibPath) ~ "' exported to '" ~ outputFileName ~ "'.");
          writeln();
        }
      }
    }
  }
  else {
    printLogo();
    printUsage();
  }
}

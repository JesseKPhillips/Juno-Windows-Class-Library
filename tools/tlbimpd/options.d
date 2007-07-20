module tlbimpd.options;

public bool emitComments = false;
public bool blanksBetweenMembers = true;
public bool noEnumNames = false;
public bool suppressBanner = false;
public bool silentMode = false;
public bool indentWithTabs = false;
public int lineIndent = 2;
public bool braceOnNewLine = false;
public string moduleName;
public string outputFileName;
public string propGetPrefix = "get";
public string propPutPrefix = "set";
public string defaultParamName = "value";
public bool verbatimOrder = false;
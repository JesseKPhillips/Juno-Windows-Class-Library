module tlbimpd.options;

public int lineIndent = 2;
public bool blanksBetweenMembers = true;
public bool braceOnNewLine = false;
public bool emitComments = false;
public bool noEnumNames = false;
public bool suppressBanner = false;
public bool silentMode = false;
public bool indentWithTabs = false;
public bool verbatimOrder = false;
public char[] moduleName;
public char[] outputFileName;
public char[] propGetPrefix = "get";
public char[] propPutPrefix = "set";
public char[] defaultParamName = "value";
module tlbimpd.options;

int lineIndent = 2;
bool blanksBetweenMembers = true;
bool braceOnNewLine = false;
bool emitComments = true;
bool noEnumNames = false;
bool suppressBanner = false;
bool silentMode = false;
bool indentWithTabs = false;
bool verbatimOrder = false;
char[] moduleName;
char[] outputFileName;
char[] propGetPrefix = "get";
char[] propPutPrefix = "set";
char[] defaultParamName = "value";
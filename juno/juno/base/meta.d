module juno.base.meta;

// Based on DDL's meta.demangle.

template demangle(char[] s) {
  static if (s[0] == 'D' || s[0] == 'P') {
    static if (s[1] == 'F' || s[1] == 'W') {
      static if (getParamListTail!(s[1 .. $]).length == 0)
        const char[] demangle = demangleFunction!(s[1 .. $])[s.length - 2 .. $];
      else
        const char[] demangle = (getParamListTail!(s[1 .. $]) ~ demangleFunction!((s[1 .. $])))[s.length - 2 .. $];
    }
    else
      const char[] demangle = demangleType!(getDotNameTail!(s[1 .. $])) ~ toDotName!(s[1 .. $]);
  }
  else static if (isDigit!((s[0])))
    const char[] demangle = toDotName!(s);
  else
    const char[] demangle = s;
}

template demangleFunction(char[] s) {
  const char[] demangleFunction = demangleReturnType!(s[1 .. $]) ~ "|" ~ demangleParamList!(s[1 .. $]);
}

template getParamListTail(char[] s) {
  static if (s[0] == 'Z')
    const char[] getParamListTail = getTypeTail!(s[1 .. $]);
  else
    const char[] getParamListTail = getTypeTail!(s);
}

template getTypeTail(char[] s) {
  static if (s[0] == 'C' || s[0] == 'S' || s[0] == 'T' || s[0] == 'E')
    const char[] getTypeTail = getDotNameTail!(s[1 .. $]);
  else static if (s[0] == 'P' || s[0] == 'A' || s[0] == 'J'/*out*/ || s[0] == 'K'/*inout*/)
    const char[] getTypeTail = getTypeTail!(s[1 .. $]);
  else
    const char[] getTypeTail = s[1 .. $];
}

template demangleSimple(char[] s) {
  static if (s[0] == 'g')
    const char[] demangleSimple = "byte";
  else static if (s[0] == 'h')
    const char[] demangleSimple = "ubyte";
  else static if (s[0] == 's')
    const char[] demangleSimple = "short";
  else static if (s[0] == 't')
    const char[] demangleSimple = "ushort";
  else static if (s[0] == 'i')
    const char[] demangleSimple = "int";
  else static if (s[0] == 'k')
    const char[] demangleSimple = "uint";
  else static if (s[0] == 'l')
    const char[] demangleSimple = "long";
  else static if (s[0] == 'm')
    const char[] demangleSimple = "ulong";
  else static if (s[0] == 'f')
    const char[] demangleSimple = "float";
  else static if (s[0] == 'd')
    const char[] demangleSimple = "double";
  else static if (s[0] == 'e')
    const char[] demangleSimple = "real";
  else static if (s[0] == 'a')
    const char[] demangleSimple = "char";
  else static if (s[0] == 'u')
    const char[] demangleSimple = "wchar";
  else static if (s[0] == 'w')
    const char[] demangleSimple = "dchar";
  else static if (s[0] == 'v')
    const char[] demangleSimple = "void";
  else static if (s[0] == 'b')
    const char[] demangleSimple = "bit";
  else static if (s[0] == 'x')
    const char[] demangleSimple = "bool";
  else
    const char[] demangleSimple = "?";
}

template demangleType(char[] s) {
  static if (s[0] == 'C')
    const char[] demangleType = demangle!(s[1 .. $]);
  else static if (s[0] == 'S' || s[0] == 'T' || s[0] == 'E')
    const char[] demangleType = demangle!(s[1 .. $]);
  else static if (s[0] == 'P' ||  s[0] == 'J' || s[0] == 'K')
    const char[] demangleType = demangleType!(s[1 .. $]) ~ "*";
  else static if (s[0] == 'A')
    const char[] demangleType = demangleType!(s[1 .. $]) ~ "[]";
  else
    const char[] demangleType = demangleSimple!(s);
}

template demangleReturnType(char[] s) {
  static if (s[0] == 'Z')
    const char[] demangleReturnType = demangleType!(s[1 .. $]);
  else
    const char[] demangleReturnType = demangleReturnType!(getTypeTail!(s));
}

template demangleParamList(char[] s, char[] sep = "") {
  static if (s[0] == 'Z')
    const char[] demangleParamList = "";
  else
    const char[] demangleParamList = sep ~ demangleType!(s) ~ demangleParamList!(getTypeTail!(s), "|");
}

template isDigit(char c) {
  static if (c >= '0' && c <= '9')
    const bool isDigit = true;
  else
    const bool isDigit = false;
}

template getDotNameTail(char[] s) {
  static if (s.length == 0)
    const char[] getDotNameTail = "";
  else static if (isDigit!((s[0])))
    const char[] getDotNameTail = getDotNameTail!(demangleGetTail!(s));
  else
    const char[] getDotNameTail = s;
}

template demangleGetHead(char[] s) {
  static if (s.length <= 10 || !isDigit!((s[1])))
    const char[] demangleGetHead = s[1 .. (s[0]-'0'+1)];
  else static if (s.length<=100 || !isDigit!( (s[2]) ))
    const char[] demangleGetHead = s[2 .. ((s[0]-'0')*10 + s[1]-'0'+2)];
  else
    const char[] demangleGetHead = s[3..((s[0]-'0')*100 + (s[1]-'0')*10 + s[0]-'0' + 3)];
}

template demangleGetTail(char[] s) {
  static if (s.length <= 10 || !isDigit!((s[1])))
    const char[] demangleGetTail = s[(s[0]-'0'+1) .. $];
  else static if (s.length<=100 || !isDigit!( (s[2]) ))
    const char[] demangleGetTail = s[((s[0]-'0')*10 + s[1]-'0'+2)..$];
  else
    const char[] demangleGetTail = s[((s[0]-'0')*100 + (s[1]-'0')*10 + s[0]-'0' + 3)..$];
}

template toDotName(char[] s, bool last = false, char[] dot = "") {
  static if (s.length == 0)
    const char[] toDotName = "";
  else static if (isDigit!((s[0]))) {
    static if (last && demangleGetTail!(s).length > 0) {
      static if (isDigit!((demangleGetTail!(s)[0])))
        const char[] toDotName = toDotName!(demangleGetTail!(s), last, "");
      else
        const char[] toDotName = demangleTextCount!(demangleGetHead!(s));
    }
    else
      const char[] toDotName = dot ~ demangleTextCount!(demangleGetHead!(s)) ~ toDotName!(demangleGetTail!(s), last, ".");
  }
  else static if (s[0] == 'F')
    const char[] toDotName = toDotName!(getParamListTail!(s), last, "().");
  else
    const char[] toDotName = "";
}

template demangleTextCount(char[] s) {
  const char[] demangleTextCount = s;
}
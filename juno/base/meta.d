module juno.base.meta;

template isPointer(T) {
  const bool isPointer = false;
}

template isPointer(T : T*) {
  const bool isPointer = true;
}

template isArray(T) {
  const bool isArray = false;
}

template isArray(T : T[]) {
  const bool isArray = true;
}

template isArray(T : T[][]) {
  const bool isArray = true;
}

template isMultiDimArray(T) {
  const bool isMultiDimArray = false;
}

template isMultiDimArray(T : T[][]) {
  const bool isMultiDimArray = true;
}

template isMultiDimArray(T : char[][]) {
  const bool isMultiDimArray = false;
}

// The following templates are borrowed from ddl.meta to give us readable type names in static asserts.

template isDigit(dchar c) {
  static if (c >= '0' && c <= '9')
    const bool isDigit = true;
  else
    const bool isDigit = false;
}

template demangleType(char[] s, bool fullyQualified = false) {
  static if (s[0] == 'C')
    const char[] demangleType = prettyLname!(s[1 .. $], fullyQualified);
  else
    const char[] demangleType = demangleBasicType!(s);
}

template demangleBasicType(char[] s) {
  static if (s == "v") const char[] demangleBasicType = "void";
  else static if (s == "x") const char[] demangleBasicType = "bool";
  else static if (s == "g") const char[] demangleBasicType = "byte";
  else static if (s == "h") const char[] demangleBasicType = "ubyte";
  else static if (s == "s") const char[] demangleBasicType = "short";
  else static if (s == "t") const char[] demangleBasicType = "ushort";
  else static if (s == "i") const char[] demangleBasicType = "int";
  else static if (s == "k") const char[] demangleBasicType = "uint";
  else static if (s == "l") const char[] demangleBasicType = "long";
  else static if (s == "m") const char[] demangleBasicType = "ulong";
  else static if (s == "d") const char[] demangleBasicType = "double";
  else static if (s == "f") const char[] demangleBasicType = "float";
  else static if (s == "e") const char[] demangleBasicType = "real";
  else static if (s == "o") const char[] demangleBasicType = "ifloat";
  else static if (s == "p") const char[] demangleBasicType = "idouble";
  else static if (s == "j") const char[] demangleBasicType = "ireal";
  else static if (s == "a") const char[] demangleBasicType = "char";
  else static if (s == "u") const char[] demangleBasicType = "wchar";
  else static if (s == "w") const char[] demangleBasicType = "dchar";
}

template prettyLname(char[] s, bool fullyQualified = false) {
  static if (isDigit!((s[0])))
    const char[] prettyLname = getQualifiedName!(s[0 .. getQualifiedNameConsumed!(s)], fullyQualified);
  else
    const char[] prettyLname = s;
}

template getLnameConsumed(char [] str) {
  static if (str.length==0)
    const int getLnameConsumed=0;
  else static if (str.length <= (9+1) || !isDigit!( (str[1]) ) )
    const int getLnameConsumed = 1 + str[0]-'0';
  else static if (str.length <= (99+2) || !isDigit!( (str[2]) ))
    const int getLnameConsumed = (str[0]-'0')*10 + str[1]-'0' + 2;
  else static if (str.length <= (999+3) || !isDigit!( (str[3]) ))
    const int getLnameConsumed = (str[0]-'0')*100 + (str[1]-'0')*10 + str[2]-'0' + 3;
  else
    const int getLnameConsumed = (str[0]-'0')*1000 + (str[1]-'0')*100 + (str[2]-'0')*10 + (str[3]-'0') + 4;
}

template getLname(char [] str) {
  static if (str.length <= 9+1 || !isDigit!( (str[1]) ) )
    const char [] getLname = str[1..(str[0]-'0' + 1)];
  else static if (str.length <= 99+2 || !isDigit!( (str[2]) ))
    const char [] getLname = str[2..((str[0]-'0')*10 + str[1]-'0'+ 2)];
  else static if (str.length <= 999+3 || !isDigit!( (str[3]) ))
    const char [] getLname =
    str[3..((str[0]-'0')*100 + (str[1]-'0')*10 + str[2]-'0' + 3)];
  else
    const char [] getLname =
    str[4..((str[0]-'0')*1000 + (str[1]-'0')*100 + (str[2]-'0')*10 + (str[3]-'0') + 4)];
}

template getQualifiedNameConsumed(char[] s) {
  static if (s.length > 1 &&  isDigit!((s[0])) ) {
    static if (getLnameConsumed!(s) < s.length && isDigit!((s[getLnameConsumed!(s)])))
      const int getQualifiedNameConsumed = getLnameConsumed!(s)
        + getQualifiedNameConsumed!(s[getLnameConsumed!(s) .. $]);
    else
      const int getQualifiedNameConsumed = getLnameConsumed!(s);
  }
}

template getQualifiedName(char[] str, bool fullyQualified, char [] dotstr = "") {
  static if (str.length == 0)
    const char [] getQualifiedName = "";
  else {
    static assert (isDigit!(( str[0] )));
    static if ( getLnameConsumed!(str) < str.length && isDigit!(( str[getLnameConsumed!(str)] ))) {
      static if (!fullyQualified)
        // For symbol names, only display the last symbol
        const char [] getQualifiedName =
          getQualifiedName!(str[getLnameConsumed!(str) .. $], fullyQualified, "");
      else
        // Qualified and pretty names display everything
        const char [] getQualifiedName = dotstr
          ~ prettyLname!(getLname!(str), fullyQualified)
          ~ getQualifiedName!(str[getLnameConsumed!(str) .. $], fullyQualified, ".");
    }
    else
      const char [] getQualifiedName = dotstr ~ prettyLname!(getLname!(str), fullyQualified);
  }
}

template fullnameof(alias T) {
  const char[] fullnameof = demangleType!(T.mangleof, true);
}

template nameof(alias T) {
  const char[] nameof = demangleType!(T.mangleof, false);
}

template nameof(T) {
  const char[] nameof = demangleType!(T.mangleof, false);
}
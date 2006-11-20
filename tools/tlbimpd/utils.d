module tlbimpd.utils;

// Based on ArgParser.d by Eric Anderton and Lars Ivar Igesund

alias uint delegate(char[] value, uint index) DefaultArgumentHandler;
alias uint delegate(char[] value) ArgumentHandler;
alias void delegate() SimpleArgumentHandler;

public class ArgParser {

  protected struct PrefixHandler {
    char[] name;
    ArgumentHandler handler;
  }

  protected class SimpleArgumentAdapter {

    SimpleArgumentHandler handler;

    this(SimpleArgumentHandler handler) {
      this.handler = handler;
    }

    public uint adapterHandler(char[] value) {
      handler();
      return 0;
    }

  }

  protected PrefixHandler[][char[]] bindings;
  protected char[][] prefixSearchOrder;
  protected DefaultArgumentHandler defaultBinding;

  public this(DefaultArgumentHandler handler = null) {
    defaultBinding = handler;
  }

  public void bind(char[] prefix, char[] name, ArgumentHandler handler) {
    PrefixHandler prefixHandler;
    prefixHandler.name = name;
    prefixHandler.handler = handler;
    addBinding(prefixHandler, prefix);
  }

  public void bind(char[] prefix, char[] name, SimpleArgumentHandler handler) {
    SimpleArgumentAdapter adapter = new SimpleArgumentAdapter(handler);
    PrefixHandler prefixHandler;
    prefixHandler.name = name;
    prefixHandler.handler = &adapter.adapterHandler;
    addBinding(prefixHandler, prefix);
  }

  public void parse(char[][] args) {
    if (bindings.length == 0)
      return;
    uint index;
    foreach (char[] arg; args) {
      char[] a = arg;
      while (a.length > 0) {
        bool found;
        char[] orig = a;
        foreach (char[] prefix; prefixSearchOrder) {
          if (a.length < prefix.length)
            continue;
          if (a[0 .. prefix.length] != prefix)
            continue;
          else
            a = a[prefix.length .. $];
          foreach (PrefixHandler handler; bindings[prefix]) {
            if (a.length < handler.name.length)
              continue;
            uint len = handler.name.length;
            if (handler.name == a[0 .. len]) {
              found = true;
              a = a[len .. $];
              uint eaten = handler.handler(a);
              a = a[eaten .. $];
              break;
            }
          }
          if (found)
            break;
          a = orig;
        }
        if (!found) {
          if (defaultBinding !is null) {
            uint eaten = defaultBinding(a, index);
            a = a[eaten .. $];
            index++;
          }
          else
            throw new Exception("Illegal argument '" ~ a ~ "'.");
        }
      }
    }
  }

  protected void addBinding(PrefixHandler handler, char[] prefix) {
    if (!(prefix in bindings))
      prefixSearchOrder ~= prefix;
    bindings[prefix] ~= handler;
  }

}
module tlbimpd.utils;

alias uint delegate(string value, int index) DefaultArgumentHandler;
alias uint delegate(string value) ArgumentHandler;
alias void delegate() SimpleArgumentHandler;

public class ArgParser {

  protected struct PrefixHandler {
    string name;
    ArgumentHandler handler;
  }

  protected class SimpleArgumentAdapter {

    SimpleArgumentHandler handler;

    this(SimpleArgumentHandler handler) {
      this.handler = handler;
    }

    public uint adapterHandler(string value) {
      handler();
      return 0;
    }

  }

  protected PrefixHandler[][string] bindings;
  protected string[] prefixSearchOrder;
  protected DefaultArgumentHandler defaultBinding;

  public this(DefaultArgumentHandler handler = null) {
    defaultBinding = handler;
  }

  public void bind(string prefix, string name, ArgumentHandler handler) {
    auto prefixHandler = PrefixHandler(name, handler);
    addBinding(prefixHandler, prefix);
  }

  public void bind(string prefix, string name, SimpleArgumentHandler handler) {
    auto adapter = new SimpleArgumentAdapter(handler);
    auto prefixHandler = PrefixHandler(name, &adapter.adapterHandler);
    addBinding(prefixHandler, prefix);
  }

  public void parse(string[] args) {
    if (bindings.length == 0)
      return;

    uint index;
    foreach (arg; args) {
      string a = arg;
      while (a.length > 0) {
        bool found = false;
        string orig = a;

        foreach (prefix; prefixSearchOrder) {
          if (a.length < prefix.length)
            continue;

          if (a[0 .. prefix.length] != prefix)
            continue;
          else
            a = a[prefix.length .. $];

          foreach (handler; bindings[prefix]) {
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
          if (defaultBinding != null) {
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

  protected void addBinding(PrefixHandler handler, string prefix) {
    if (!(prefix in bindings))
      prefixSearchOrder ~= prefix;
    bindings[prefix] ~= handler;
  }

}
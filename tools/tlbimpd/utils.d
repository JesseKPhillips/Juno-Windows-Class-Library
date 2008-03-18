module tlbimpd.utils;

alias void delegate(string value, int index) DefaultArgumentHandler;
alias void delegate(string value) ArgumentHandler;
alias void delegate() SimpleArgumentHandler;

class ArgParser {

  protected struct PrefixHandler {
    string name;
    ArgumentHandler handler;
  }

  protected class SimpleArgumentAdapter {

    SimpleArgumentHandler handler;

    this(SimpleArgumentHandler handler) {
      this.handler = handler;
    }

    void adapterHandler(string value) {
      handler();
    }

  }

  protected PrefixHandler[][string] bindings;
  protected DefaultArgumentHandler[string] defaultBindings;
  protected string[] prefixSearchOrder;
  protected DefaultArgumentHandler defaultBinding;
  protected int defaultIndex;

  protected void addBinding(PrefixHandler handler, string prefix) {
    if (!(prefix in bindings))
      prefixSearchOrder ~= prefix;
    bindings[prefix] ~= handler;
  }

  this(DefaultArgumentHandler handler = null) {
    defaultBinding = handler;
  }

  void bind(string prefix, string name, ArgumentHandler handler) {
    auto prefixHandler = PrefixHandler(name, handler);
    addBinding(prefixHandler, prefix);
  }

  void bind(string prefix, string name, SimpleArgumentHandler handler) {
    auto adapter = new SimpleArgumentAdapter(handler);
    auto prefixHandler = PrefixHandler(name, &adapter.adapterHandler);
    addBinding(prefixHandler, prefix);
  }

  void parse(string[] args) {
    if (bindings.length == 0)
      return;

    foreach (arg; args) {
      string a = arg;
      string orig = a;

      bool found;

      foreach (prefix; prefixSearchOrder) {
        if (a.length < prefix.length)
          continue;

        if (a[0 .. prefix.length] != prefix)
          continue;
        else
          a = a[prefix.length .. $];

        if (prefix in bindings) {
          PrefixHandler[] handlers;
          foreach (handler; bindings[prefix]) {
            if (a.length < handler.name.length)
              continue;
            if (handler.name == a[0 .. handler.name.length]) {
              found = true;
              handlers ~= handler;
            }
          }

          if (found) {
            int i;
            if (handlers.length > 1) {
              foreach (j, handler; handlers) {
                if (handler.name.length > handlers[i].name.length)
                  i = j;
              }
            }

            with (handlers[i]) {
              handler(a[name.length .. $]);
            }
          }
        }

        if (found)
          break;
        /*else if (prefix in defaultBindings) {
          defaultBindings[prefix](a, prefixOrdinals[prefix]);
          prefixOrdinals[prefix]++;
          found = true;
          break;
        }*/

        a = orig;
      }

      if (!found) {
        if (defaultBinding !is null) {
          defaultBinding(a, defaultIndex);
          defaultIndex++;
        }
      }
    }
  }

}
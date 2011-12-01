import juno.base.native;

extern (Windows)
alias DllImport!("user32.dll", "MessageBeep", int function(uint type)) MessageBeep;

void main() {
  MessageBeep(-1);
}

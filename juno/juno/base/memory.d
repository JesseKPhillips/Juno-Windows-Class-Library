module juno.base.memory;

private import std.gc;

extern (C)
public void* malloc(size_t);

extern (C)
public void free(void*);

extern (C)
public void* memcpy(void*, void*, size_t);

public abstract final class GC {

  public static void collect() {
    std.gc.fullCollect();
  }

  public static void addRange(void* bottom, void* top) {
    std.gc.addRange(bottom, top);
  }

  public static void removeRange(void* bottom) {
    std.gc.removeRange(bottom);
  }

}
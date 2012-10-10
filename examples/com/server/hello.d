module hello;

// This is the interface.

private import juno.com.all;

interface ISaysHello : IUnknown {
  mixin(uuid("ae0dd4b7-e817-44ff-9e11-d1cffae11f16"));

  int sayHello();
}

// coclass
abstract class SaysHello {
  mixin(uuid("35115e92-33f5-4e14-9d0a-bd43c80a75af"));

  mixin Interfaces!(ISaysHello);
}

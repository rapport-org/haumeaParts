# plain attrsets are wrapped the same way as other plain values
{ plain-attrset-leaf, perSystem }:
builtins.isFunction plain-attrset-leaf
&& plain-attrset-leaf perSystem == { foo = "bar"; baz = 42; }

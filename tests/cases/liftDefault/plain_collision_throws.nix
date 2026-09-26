# plain default + sibling with the same key: accessing that key throws
{ lifted, throws }:
let r = lifted { default = { foo = "d"; }; foo = "s"; };
in throws r.foo

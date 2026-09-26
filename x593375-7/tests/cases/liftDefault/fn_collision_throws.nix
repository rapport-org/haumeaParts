# function default + sibling with the same key: accessing that key throws
{ lifted, throws, perSystem, plain-leaf }:
let r = lifted { default = _: { curl = "from-default"; }; curl = plain-leaf; } perSystem;
in throws r.curl

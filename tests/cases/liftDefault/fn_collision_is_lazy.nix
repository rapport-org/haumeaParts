# the error is lazy: colliding key is still listed, other keys still resolve
{ lifted, perSystem, plain-leaf }:
let r = lifted { default = _: { curl = "from-default"; extra = 1; }; curl = plain-leaf; } perSystem;
in builtins.attrNames r == [ "curl" "extra" ] && r.extra == 1

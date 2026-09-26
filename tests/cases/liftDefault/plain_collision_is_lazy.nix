# the error is lazy: colliding key is still listed, other keys still resolve
{ lifted }:
let r = lifted { default = { foo = "d"; }; foo = "s"; bar = "b"; };
in builtins.attrNames r == [ "bar" "foo" ] && r.bar == "b"

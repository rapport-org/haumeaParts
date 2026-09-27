# leaves are only called when accessed: a failing sibling doesn't break the others
{ resolve, throws, fn-leaf }:
let r = resolve { packages = { hello = fn-leaf; broken = _: throw "boom"; }; };
in builtins.attrNames r.packages == [ "broken" "hello" ]
&& r.packages.hello == "pkgs-hello"
&& throws r.packages.broken

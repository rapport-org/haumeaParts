# once called: default's keys resolved, siblings still deferred, no `default` key left
{ lifted, perSystem, fn-attrset-default, plain-leaf }:
let r = lifted { default = fn-attrset-default; curl = plain-leaf; } perSystem;
in r.myPkg == "pkgs-hello"
&& builtins.isFunction r.curl
&& !(r ? default)

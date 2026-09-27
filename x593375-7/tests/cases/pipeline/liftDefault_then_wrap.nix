# a lifted default.nix + siblings resolves correctly through wrap's lazyWrap
{ lifted, resolve, fn-attrset-default, plain-leaf }:
let r = resolve { packages = lifted { default = fn-attrset-default; curl = plain-leaf; }; };
in r.packages.myPkg == "pkgs-hello"
&& r.packages.curl == "plain-value"
&& builtins.attrNames r.packages == [ "curl" "myPkg" ]

# a default.nix/sibling collision still throws after wrapping; other keys still resolve
{ lifted, resolve, throws, plain-leaf }:
let r = resolve { packages = lifted { default = _: { curl = "d"; extra = 1; }; curl = plain-leaf; }; };
in throws r.packages.curl && r.packages.extra == 1

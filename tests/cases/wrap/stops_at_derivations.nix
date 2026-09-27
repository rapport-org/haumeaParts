# a derivation is returned as-is: its attributes are not walked or called
{ resolve }:
let r = resolve { packages.drv = _: { type = "derivation"; name = "d"; inner = _: "not-called"; }; };
in builtins.isFunction r.packages.drv.inner

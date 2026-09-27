# each node gets exactly the right transformer, applied in list order as haumea does
{ defaultTransformers, haumeaStub, perSystem, fn-attrset-default, plain-leaf }:
let
  ts = defaultTransformers { haumea = haumeaStub; };
  apply = cursor: mod: builtins.foldl' (m: t: t cursor m) mod ts;
  inPerSystem = apply [ "perSystem" "packages" ] { default = fn-attrset-default; curl = plain-leaf; };
  atPerSystem = apply [ "perSystem" ] { packages.curl = plain-leaf; };
in
builtins.length ts == 3
# perSystem subtree: haumeaParts' liftDefault (deferred merge), not wrapped
&& (inPerSystem perSystem).myPkg == "pkgs-hello"
# outside: haumea's liftDefault, not wrapped
&& apply [ "flake" "lib" ] { default = { }; } == "haumea-lifted"
&& apply [ ] { flake = { }; } == "haumea-lifted"
# the perSystem node itself: wrapped into a module that resolves the subtree
&& ((builtins.head atPerSystem.imports) perSystem).packages.curl == "plain-value"

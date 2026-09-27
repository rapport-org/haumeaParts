# the resolver is a module function whose named args flake-parts can introspect
{ wrap }:
let r = wrap [ "perSystem" ] { };
in builtins.attrNames r == [ "imports" ]
&& builtins.functionArgs (builtins.head r.imports)
   == { pkgs = false; lib = false; system = false; inputs' = false; self' = false; config = false; }

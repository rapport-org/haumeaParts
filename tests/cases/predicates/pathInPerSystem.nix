# only files under <src>/perSystem/ match — not a nested perSystem/, a look-alike name, or another src
{ predicates }:
let
  p = path: predicates.pathInPerSystem /x/src { inherit path; };
in
p /x/src/perSystem/packages/hello.nix
&& p /x/src/perSystem/default.nix
&& !(p /x/src/flake/perSystem/a.nix)
&& !(p /x/src/perSystemExtra/a.nix)
&& !(p /x/srcOther/perSystem/a.nix)
&& !(p /x/src/systems.nix)

# only the perSystem node itself, where wrap applies
{ predicates }:
let p = cursor: predicates.cursorIsPerSystem { inherit cursor; };
in p [ "perSystem" ] && !(p [ "perSystem" "packages" ]) && !(p [ ]) && !(p [ "flake" "perSystem" ])

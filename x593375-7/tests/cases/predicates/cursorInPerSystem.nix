# perSystem itself and everything below it — but not a nested perSystem elsewhere, nor the root
{ predicates }:
let p = cursor: predicates.cursorInPerSystem { inherit cursor; };
in p [ "perSystem" ]
&& p [ "perSystem" "packages" "hello" ]
&& !(p [ ])
&& !(p [ "flake" "perSystem" ])

# exact complement of cursorInPerSystem, including the root
{ predicates }:
let
  cursors = [ [ ] [ "perSystem" ] [ "perSystem" "packages" ] [ "flake" ] [ "flake" "perSystem" ] ];
  agrees = cursor: predicates.cursorOutsidePerSystem { inherit cursor; } == !(predicates.cursorInPerSystem { inherit cursor; });
in builtins.all agrees cursors
&& predicates.cursorOutsidePerSystem { cursor = [ ]; }

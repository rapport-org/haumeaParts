# transformers/default.nix
#
# The standard transformer list:
#   - haumeaParts' liftDefault inside the top-level perSystem/ (defers the merge)
#   - haumea's liftDefault everywhere else
#   - wrap at the perSystem node, turning the subtree into a flake-parts module
#
#   transformer = haumeaParts.lib.transformers.default { inherit (inputs) haumea; };
#
# `haumea` is the haumea flake, taken as an argument to keep this library
# dependency-free. It's a plain list: append to it with `++`, or build your own
# from transformers.match and the predicates.
{ ... }:
{ haumea }:
let
  match = import ./match.nix { };
  predicates = import ../predicates.nix { };
in
[
  (match { runIf = predicates.cursorInPerSystem; } (import ./liftDefault.nix { }))
  (match { runIf = predicates.cursorOutsidePerSystem; } haumea.lib.transformers.liftDefault)
  (match { runIf = predicates.cursorIsPerSystem; } (import ./wrap.nix { }))
]

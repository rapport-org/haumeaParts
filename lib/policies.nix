# policies.nix
#
# Ready-made loaders.dispatch policies. Each is a plain attrset, so fields can
# be added or overridden with `//`, e.g. `(policies.perSystem src) // { logIf = true; }`.
{ ... }:
let
  predicates = import ./predicates.nix { };
  scoped = import ./loaders/scoped.nix { };
in
{
  # Files under <src>/perSystem/ are loaded deferred (functionArgs intact) for
  # `wrap` to resolve later. `src` must be the same path given to haumea.lib.load.
  perSystem = src: {
    runIf = predicates.pathInPerSystem src;
    runFn = scoped;
  };
}

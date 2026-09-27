# loaders/default.nix
#
# The standard loader: files under <src>/perSystem/ are deferred
# (policies.perSystem); everything else goes to haumea's own scoped loader.
#
#   loader = haumeaParts.lib.loaders.default { inherit src; inherit (inputs) haumea; };
#
# `src` must be the same path given to haumea.lib.load. `haumea` is the haumea
# flake, taken as an argument to keep this library dependency-free.
# For anything more custom, build the policy list yourself with loaders.dispatch.
{ ... }:
{ src, haumea }:
import ./dispatch.nix { } [
  ((import ../policies.nix { }).perSystem src)
  { runFn = haumea.lib.loaders.scoped; }
]

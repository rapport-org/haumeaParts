{
  description = "Libs to extend Haumea with Flake-Parts support ";
  outputs = _: {
    lib.loaders.dispatch = import ./lib/loaders/dispatch.nix { };
    lib.loaders.scoped = import ./lib/loaders/scoped.nix { };
    lib.transformers.liftDefault = import ./lib/transformers/liftDefault.nix { };
    lib.transformers.match = import ./lib/transformers/match.nix { };
    lib.transformers.trace = import ./lib/transformers/trace.nix { };
    lib.transformers.wrap = import ./lib/transformers/wrap.nix { };
  };
}

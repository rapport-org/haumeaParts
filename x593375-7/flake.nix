{
  description = "Libs to extend Haumea with Flake-Parts support";

  outputs = { ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      # Evaluate tests once — pure Nix, no system dependency.
      # Any false value or evaluation error here surfaces as a flake-eval failure.
      testResults = import ./tests;
      failures    = builtins.filter (n: !testResults.${n}) (builtins.attrNames testResults);

    in {
      lib.loaders.dispatch        = import ./lib/loaders/dispatch.nix        {};
      lib.loaders.scoped          = import ./lib/loaders/scoped.nix          {};
      lib.transformers.liftDefault = import ./lib/transformers/liftDefault.nix {};
      lib.transformers.match      = import ./lib/transformers/match.nix       {};
      lib.transformers.trace      = import ./lib/transformers/trace.nix       {};
      lib.transformers.wrap       = import ./lib/transformers/wrap.nix        {};

      checks = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
          # Test failures throw at eval time (before any build is attempted),
          # so `nix flake check` reports them as evaluation errors with test names.
          loaders = if failures != []
            then builtins.throw "haumeaParts: tests failed — ${builtins.concatStringsSep ", " failures}"
            else pkgs.runCommand "haumeaParts-tests" {} "touch $out";
        }
      );
    };
}

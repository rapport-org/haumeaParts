{
  description = "Libs to extend Haumea with Flake-Parts support";

  outputs = { ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: builtins.listToAttrs (map (s: { name = s; value = f s; }) systems);

      testRunResults = import ./tests;
      testRunFailures    = builtins.filter (n: !testRunResults.${n}) (builtins.attrNames testRunResults);

    in {
      lib.loaders.dispatch         = import ./lib/loaders/dispatch.nix        {};
      lib.loaders.scoped           = import ./lib/loaders/scoped.nix          {};
      lib.transformers.liftDefault = import ./lib/transformers/liftDefault.nix {};
      lib.transformers.match       = import ./lib/transformers/match.nix       {};
      lib.transformers.trace       = import ./lib/transformers/trace.nix       {};
      lib.transformers.wrap        = import ./lib/transformers/wrap.nix        {};

      checks = forAllSystems (system: {
        # Failures throw at eval time; success builds a trivial sentinel derivation.
        loaders = if testRunFailures != []
          then builtins.throw "haumeaParts: tests failed — ${builtins.concatStringsSep ", " testRunFailures}"
          else builtins.derivation {
            name    = "haumeaParts-tests";
            system  = system;
            builder = "/bin/sh";
            args    = [ "-c" ": > $out" ];
          };
      });
    };
}

# haumeaParts — test runner
#
# Run standalone:  nix eval --file tests/runner.nix
# Run via flake:   nix flake check
#
# Both directories are discovered by traversal:
#
#   cases/<unit>/<case>.nix   one test per file, named "<unit>/<case>"
#   fixtures/<name>.nix       leaf files, offered to tests as
#                               <name>       — loaded through the scoped loader
#                               <name>-path  — the raw path, for tests that load it themselves
#
# A test file is a function whose named arguments declare exactly what it
# needs — fixtures and/or the helpers below — and it returns true (pass) or
# false (fail). Declaring an unknown name, or returning a non-bool, throws.
#
# Expected failures are asserted with `throws`, which relies on builtins.tryEval
# and so only catches `throw`/`assert`. Any other evaluation error (e.g. a
# missing attribute) aborts the whole run — which is itself a failure.
#
let
  helpers = rec {
    scoped      = import ../lib/loaders/scoped.nix {};
    dispatch    = import ../lib/loaders/dispatch.nix {};
    liftDefault = import ../lib/transformers/liftDefault.nix {};

    throws = expr: !(builtins.tryEval expr).success;

    # haumea inputs attrset — what the user passes as `inputs` to haumea.lib.load
    haumeaInputs = { injectedValue = "from-scope"; };

    # perSystem args — what lazyWrap (in wrap.nix) calls deferred leaf functions with
    perSystem = {
      pkgs    = { hello = "pkgs-hello"; };
      lib     = { optionalString = cond: s: if cond then s else ""; };
      system  = "x86_64-linux";
      inputs' = {};
      self'   = {};
      config  = {};
    };

    # liftDefault at a representative cursor inside the perSystem subtree
    lifted = liftDefault [ "perSystem" "packages" ];
  };

  # Recursively collect `*.nix` under `dir` as { "<rel/path/sans/ext>" = path; },
  # joining directory levels with `sep`.
  nixFilesIn = sep: dir:
    let
      go = prefix: dir:
        let entries = builtins.readDir dir;
        in builtins.foldl' (acc: name:
          let
            type = entries.${name};
            path = dir + "/${name}";
            stem = builtins.match "(.*)\\.nix" name;
          in
          if type == "directory" then acc // go "${prefix}${name}${sep}" path
          else if type == "regular" && stem != null then acc // { "${prefix}${builtins.head stem}" = path; }
          else acc
        ) {} (builtins.attrNames entries);
    in go "" dir;

  fixturePaths = nixFilesIn "-" ./fixtures;

  fixtures = builtins.foldl' (acc: name: acc // {
    ${name}         = helpers.scoped helpers.haumeaInputs fixturePaths.${name};
    "${name}-path"  = fixturePaths.${name};
  }) {} (builtins.attrNames fixturePaths);

  clashes = builtins.attrNames (builtins.intersectAttrs helpers fixtures);
  available =
    if clashes == [ ] then helpers // fixtures
    else builtins.throw "tests/runner.nix: fixture name(s) shadow a helper: ${builtins.concatStringsSep ", " clashes}";

  run = name: file:
    let
      test = import file;
      declared = builtins.functionArgs test;
      unknown = builtins.filter (arg: !declared.${arg} && !(available ? ${arg})) (builtins.attrNames declared);
      result =
        if !builtins.isFunction test then
          builtins.throw "test '${name}' must be a function of its fixtures/helpers"
        else if unknown != [ ] then
          builtins.throw "test '${name}' declares unknown argument(s): ${builtins.concatStringsSep ", " unknown}"
        else
          test (builtins.intersectAttrs declared available);
    in
    if builtins.isBool result then result
    else builtins.throw "test '${name}' returned a ${builtins.typeOf result}, expected a bool";

in
builtins.mapAttrs run (nixFilesIn "/" ./cases)

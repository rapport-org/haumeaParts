# <src>/perSystem/** is deferred through haumeaParts' scoped loader
{ defaultLoader, haumeaStub, fixturesDir, haumeaInputs, perSystem, perSystem-hello-path }:
let r = defaultLoader { src = fixturesDir; haumea = haumeaStub; } haumeaInputs perSystem-hello-path;
in builtins.functionArgs r == { pkgs = false; } && r perSystem == "pkgs-hello"

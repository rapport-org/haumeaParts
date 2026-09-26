# the selected runFn's result passes through untouched
{ dispatch, scoped, haumeaInputs, perSystem, fn-leaf-path }:
let r = dispatch [ { runFn = scoped; } ] haumeaInputs fn-leaf-path;
in builtins.isFunction r
&& builtins.functionArgs r == { pkgs = false; }
&& r perSystem == "pkgs-hello"

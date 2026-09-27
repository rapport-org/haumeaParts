# the preset routes <src>/perSystem/** to the scoped loader and lets everything else fall through
{ dispatch, policies, haumeaInputs, perSystem, fn-leaf-path }:
let
  src = /x/src;
  p = policies.perSystem src;
  loaded = p.runFn haumeaInputs fn-leaf-path;
in
p.runIf { path = /x/src/perSystem/packages/hello.nix; }
&& !(p.runIf { path = /x/src/flake/perSystem/a.nix; })
# runFn is the scoped loader: function returned unevaluated, functionArgs intact
&& builtins.functionArgs loaded == { pkgs = false; }
&& loaded perSystem == "pkgs-hello"
# fixtures aren't under <src>/perSystem/, so dispatch falls through to the next policy
&& dispatch [ p { runFn = _: _: "general"; } ] haumeaInputs fn-leaf-path == "general"

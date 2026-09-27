# the preset is a plain attrset: extra dispatch fields merge in with //
{ dispatch, policies, haumeaInputs, fn-leaf-path, perSystem }:
let
  policy = (policies.perSystem /x/src) // { runIf = true; logSfx = "note"; };
in
policy.logSfx == "note"
&& (dispatch [ policy ] haumeaInputs fn-leaf-path) perSystem == "pkgs-hello"

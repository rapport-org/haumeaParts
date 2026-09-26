# first matching policy wins; non-matching ones are skipped without running
{ dispatch, scoped, haumeaInputs, perSystem, fn-leaf-path }:
dispatch [
  { runIf = _: false; runFn = _: _: "wrong"; }
  { runIf = true;     runFn = scoped; }
] haumeaInputs fn-leaf-path perSystem == "pkgs-hello"

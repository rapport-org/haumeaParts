# no matching policy is a deliberate throw
{ dispatch, scoped, throws, haumeaInputs, fn-leaf-path }:
throws (dispatch [ { runIf = _: false; runFn = scoped; } ] haumeaInputs fn-leaf-path)

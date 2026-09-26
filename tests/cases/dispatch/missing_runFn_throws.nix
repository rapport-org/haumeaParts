# a matched policy with no runFn is a deliberate throw (not a missing-attr abort)
{ dispatch, throws, haumeaInputs, fn-leaf-path }:
throws (dispatch [ { runIf = true; } ] haumeaInputs fn-leaf-path)

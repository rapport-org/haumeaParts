# scopedImport puts haumeaInputs names in the file's top-level scope
{ fn-uses-inputs, perSystem }:
fn-uses-inputs perSystem == "string-pkgs-hello"

# A file that uses a name injected via scopedImport (flake inputs in scope).
# Tests that the `inputs` attrset is available in the file's top-level scope.
{ pkgs, ... }: "${builtins.typeOf injectedValue}-${pkgs.hello}"

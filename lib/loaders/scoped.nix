# loaders/scoped.nix
#
# perSystem loader: imports with `inputs` in scope and returns the file's
# function unevaluated; plain values are wrapped as `_: content`.
{ ... }:
inputs: path:
let
  content = builtins.scopedImport inputs path;
in
if builtins.isFunction content
then content
else _: content

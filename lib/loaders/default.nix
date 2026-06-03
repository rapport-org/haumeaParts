{ ... }@fnArgs:
let
  dispatch = import ./dispatch.nix fnArgs;
in
# loader operates as a first match wins system

dispatch [
  # handle the perSystem case w/ a special loader before the general case
  {
    runIf = ctx: builtins.match ".*/perSystem/(.*\.nix)?$" (builtins.toString ctx.path) != null;
    runFn = inputs.haumeaParts.lib.loaders.scoped;
  }
  # handle the general case w/ a normal loader
  { runFn = inputs.haumea.lib.loaders.scoped; }
]

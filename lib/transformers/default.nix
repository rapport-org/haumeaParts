#WIP#
let
  trace = import ./trace.nix {};
  match = import ./match.nix {};
  trace = import ./trace.nix {};
  trace = import ./trace.nix {};
in
  # transformers operate as an assembly line of sequential (potential) match-action modifications
  [
  #(inputs.haumea.lib.transformers.trace {})
  (inputs.haumeaParts.lib.transformers.match
    { runIf = ctx: builtins.elem "perSystem" ctx.cursor; }
    inputs.haumeaParts.lib.transformers.liftDefault)
  (inputs.haumeaParts.lib.transformers.match
    { runIf = ctx: !(builtins.elem "perSystem" ctx.cursor); }
    inputs.haumea.lib.transformers.liftDefault)
  (inputs.haumeaParts.lib.transformers.match
    { runIf = ctx: ctx.cursor == ["perSystem"]; }
    inputs.haumeaParts.lib.transformers.wrap)
  ];

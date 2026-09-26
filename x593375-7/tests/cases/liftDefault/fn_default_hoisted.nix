# default only: hoisted directly, still the same unevaluated function
{ lifted, fn-leaf }:
let r = lifted { default = fn-leaf; };
in builtins.isFunction r && builtins.functionArgs r == { pkgs = false; }

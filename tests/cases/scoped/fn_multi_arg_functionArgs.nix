# every declared parameter survives the load
{ fn-multi-arg-leaf }:
builtins.functionArgs fn-multi-arg-leaf == { pkgs = false; lib = false; system = false; }

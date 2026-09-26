# function-valued file is returned as-is: not called, functionArgs intact
{ fn-leaf }:
builtins.isFunction fn-leaf
&& builtins.functionArgs fn-leaf == { pkgs = false; }

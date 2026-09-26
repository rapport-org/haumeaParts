# function default + siblings: the merge is deferred until called with perSystem args
{ lifted, fn-attrset-default, plain-leaf }:
builtins.isFunction (lifted { default = fn-attrset-default; curl = plain-leaf; })

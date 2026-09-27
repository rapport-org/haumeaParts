# outside cursor ["perSystem"], wrap returns mod unchanged
{ wrap, fn-leaf }:
let mod = { a = fn-leaf; };
in wrap [ "flake" ] mod == mod && wrap [ "perSystem" "packages" ] mod == mod

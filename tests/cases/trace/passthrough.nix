# trace never changes the value, whether or not it logs
{ trace }:
let mod = { a = 1; };
in trace { logIf = false; } [ "x" ] mod == mod

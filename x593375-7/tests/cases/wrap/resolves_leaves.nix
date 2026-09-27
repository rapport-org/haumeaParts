# function leaves are called with the perSystem args; plain-value leaves are unwrapped
{ resolve, fn-leaf, plain-leaf, plain-attrset-leaf }:
let r = resolve { packages = { hello = fn-leaf; plain = plain-leaf; }; nested.attrs = plain-attrset-leaf; };
in r.packages.hello == "pkgs-hello"
&& r.packages.plain == "plain-value"
&& r.nested.attrs == { foo = "bar"; baz = 42; }

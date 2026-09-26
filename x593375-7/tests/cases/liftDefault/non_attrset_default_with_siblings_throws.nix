# only an attrset can absorb siblings
{ lifted, throws, perSystem, plain-leaf }:
throws (lifted { default = _: "a-string"; curl = plain-leaf; } perSystem)

# a derivation would silently gain the siblings as attrs, so it is rejected
{ lifted, throws, perSystem, plain-leaf }:
throws (lifted { default = _: { type = "derivation"; name = "d"; }; curl = plain-leaf; } perSystem)

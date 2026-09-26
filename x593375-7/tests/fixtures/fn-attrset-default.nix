# A default.nix that returns an attrset — the realistic shape when default.nix
# sits alongside sibling files.  liftDefault merges siblings with (this args) as a disjoint union.
{ pkgs, ... }: { myPkg = pkgs.hello; }

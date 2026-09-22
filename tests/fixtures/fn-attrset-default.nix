# A default.nix that returns an attrset — the realistic shape when default.nix
# sits alongside sibling files.  liftDefault merges siblings // (this args).
{ pkgs, ... }: { myPkg = pkgs.hello; }

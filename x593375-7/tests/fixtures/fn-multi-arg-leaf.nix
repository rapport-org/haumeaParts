# A file that declares multiple named perSystem args.
# Tests that all functionArgs are preserved across the { pkgs, lib, system, ... } pattern.
{ pkgs, lib, system, ... }: "${system}-${lib.optionalString true pkgs.hello}"

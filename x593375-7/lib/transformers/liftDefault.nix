# transformers/liftDefault.nix
#
# perSystem-safe variant of haumea's liftDefault. Like upstream (which uses
# lib.attrsets.unionOfDisjoint), a key defined by both default.nix and a
# sibling is an error — raised lazily, when the colliding key is accessed.
{ ... }:
cursor: mod:
let
  where = if cursor == [ ] then "<root>" else builtins.concatStringsSep "." cursor;

  # Inlined lib.attrsets.unionOfDisjoint (keeps this library dependency-free),
  # with the cursor added to the message.
  unionOfDisjoint =
    x: y:
    let
      collisions = builtins.intersectAttrs x y;
      names = builtins.concatStringsSep ", " (builtins.attrNames collisions);
      mask = builtins.mapAttrs (
        name: _:
        builtins.throw "haumeaParts.liftDefault: collision at '${where}' on key '${name}' (defined by both default.nix and a sibling; all collisions: ${names})"
      ) collisions;
    in
    x // y // mask;

  merge =
    siblings: hoisted:
    if builtins.isAttrs hoisted && (hoisted.type or null) != "derivation" then
      unionOfDisjoint siblings hoisted
    else
      builtins.throw "haumeaParts.liftDefault: default.nix at '${where}' has siblings (${builtins.concatStringsSep ", " (builtins.attrNames siblings)}) but returned ${
        if builtins.isAttrs hoisted then "a derivation" else "a ${builtins.typeOf hoisted}"
      }; only an attrset can be merged with siblings";
in
if builtins.isAttrs mod && mod ? default then
  let
    siblings = builtins.removeAttrs mod [ "default" ];
    hoisted = mod.default;
  in
  if siblings == { } then
    hoisted
  else
  # If the hoisted default is a deferred function (from the scoped loader),
  # we must defer the merge until flake-parts provides the args.
  if builtins.isFunction hoisted then
    args: merge siblings (hoisted args)
  else
    merge siblings hoisted
else
  mod

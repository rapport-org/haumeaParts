# predicates.nix
#
# Ready-made `runIf` predicates for the standard haumeaParts wiring. Only the
# top-level `perSystem/` is special: a `perSystem/` directory nested elsewhere
# is not matched (it would be deferred by the loader but never wrapped).
#
#   loaders.dispatch:     runIf = predicates.pathInPerSystem src;
#   transformers.match:   runIf = predicates.cursorInPerSystem;
#                         runIf = predicates.cursorOutsidePerSystem;
#                         runIf = predicates.cursorIsPerSystem;
{ ... }:
let
  hasPrefix = prefix: s: builtins.substring 0 (builtins.stringLength prefix) s == prefix;
  inPerSystem = cursor: cursor != [ ] && builtins.head cursor == "perSystem";
in
{
  # For dispatch: the file being loaded is under <src>/perSystem/.
  # `src` must be the same path given to haumea.lib.load — loader paths are
  # absolute, so there is no other way to know where the tree starts.
  pathInPerSystem = src: ctx: hasPrefix "${toString src}/perSystem/" (toString ctx.path);

  # For match: the node is `perSystem` itself or anything below it.
  cursorInPerSystem = ctx: inPerSystem ctx.cursor;

  # For match: the complement of cursorInPerSystem (includes the root, cursor == []).
  cursorOutsidePerSystem = ctx: !(inPerSystem ctx.cursor);

  # For match: the `perSystem` node itself — where `wrap` applies.
  cursorIsPerSystem = ctx: ctx.cursor == [ "perSystem" ];
}

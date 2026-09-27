# logIf gets the same full context as runIf (cursor, mod, …), not just the user's ctx.
# A regression here aborts the run with a missing-attribute error rather than returning false.
{ match }:
match { logIf = ctx: ctx.cursor == [ "never" ] && ctx.mod == null; } (_: _: "inner") [ "x" ] "mod" == "inner"

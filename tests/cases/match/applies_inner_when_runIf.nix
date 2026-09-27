# runIf holds: the inner transformer's result is returned
{ match }:
match { runIf = ctx: ctx.cursor == [ "x" ]; } (_: _: "inner") [ "x" ] "mod" == "inner"

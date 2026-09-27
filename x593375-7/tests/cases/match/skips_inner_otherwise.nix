# runIf fails: mod is returned unchanged and the inner transformer never runs
{ match }:
match { runIf = ctx: ctx.cursor == [ "x" ]; } (_: _: throw "should not run") [ "y" ] "mod" == "mod"

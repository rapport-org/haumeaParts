# the predicates plug straight into match's runIf (which passes the full ctx)
{ match, predicates }:
let inner = _: _: "applied";
in match { runIf = predicates.cursorIsPerSystem; } inner [ "perSystem" ] "mod" == "applied"
&& match { runIf = predicates.cursorIsPerSystem; } inner [ "perSystem" "packages" ] "mod" == "mod"
&& match { runIf = predicates.cursorOutsidePerSystem; } inner [ ] "mod" == "applied"

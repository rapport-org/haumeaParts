# no runIf: the inner transformer always applies
{ match }:
match { } (_: m: "${m}-inner") [ ] "mod" == "mod-inner"

# logIf may be a function of the full context (cursor, keys, typeOf, …)
{ trace }:
trace { logIf = ctx: ctx.cursor == [ "never" ] && ctx.keys == "[]" && ctx.typeOf == "set"; } [ "x" ] { } == { }

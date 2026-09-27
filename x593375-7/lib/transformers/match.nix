# transformers/match.nix
# Note:
# - the predicate (abbrv. "logIf") allows shipping a function or boolean value into the execution context.
# - If 'logIf' evals true, the trace log will emit. If not it will proceed normally, but without emitting a trace event.
# - The default value of 'logIf' is boolean false.
# - Using 'logIf' and 'logSfx' should allow for emitting simple trace messages only when certain watched conditions are encountered in the execution context.
# - If used (carefully), a custom 'logFmt' can also get supplemental diagnostic info from the execution context.
# - To perform only tracing, use the trace transformer instead of this.
{ ... }@fnArgs:
ctx: innerFunc: cursor: mod:
let
  fullCtx =
    fnArgs
    // ctx
    // {
      inherit
        innerFunc
        cursor
        mod
        typeOf
        runIf
        logIf
        logPfx
        ;
    };
  default = {
    runIf = true;
    logIf = false;
    logPfx = "[T] :match:\t";
  };
  simplify = part: ctx: if builtins.isFunction part then (part ctx) else part;
  evalPred = pred: ctx: (simplify pred ctx) == true;
  ##
  typeOf = builtins.typeOf mod;
  runIf = evalPred (if ctx ? runIf then ctx.runIf else default.runIf) fullCtx; # render runIf to bool
  logIf = evalPred (ctx.logIf or default.logIf) fullCtx; # render logIf to bool, default: false
  logPfx = ctx.logPfx or default.logPfx;
  logFn = data: (import ./trace.nix { }) fullCtx cursor data;
  out = if runIf then innerFunc cursor mod else mod;
in
if logIf then logFn out else out

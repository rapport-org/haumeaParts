# haumeaParts — loader and transformer correctness tests
#
# Run standalone:  nix eval --file tests/eval.nix
# Run via flake:   nix flake check
#
# Each attribute in the returned set is a named test.
# true  = pass,  false = fail.
# Any evaluation error is also a failure.
#
let
  scoped      = import ../lib/loaders/scoped.nix      {};
  dispatch    = import ../lib/loaders/dispatch.nix     {};
  liftDefault = import ../lib/transformers/liftDefault.nix {};

  # haumea inputs attrset — what the user passes as `inputs` to haumea.lib.load
  haumeaInputs = { injectedValue = "from-scope"; };

  # perSystem args — what lazyWrap (in wrap.nix) calls deferred leaf functions with
  perSystem = {
    pkgs    = { hello = "pkgs-hello"; };
    lib     = { optionalString = cond: s: if cond then s else ""; };
    system  = "x86_64-linux";
    inputs' = {};
    self'   = {};
    config  = {};
  };

  # -- helpers -----------------------------------------------------------------
  fn-leaf             = scoped haumeaInputs ./fixtures/fn-leaf.nix;
  fn-multi-arg-leaf   = scoped haumeaInputs ./fixtures/fn-multi-arg-leaf.nix;
  fn-attrset-default  = scoped haumeaInputs ./fixtures/fn-attrset-default.nix;
  plain-leaf          = scoped haumeaInputs ./fixtures/plain-leaf.nix;
  plain-attrset-leaf  = scoped haumeaInputs ./fixtures/plain-attrset-leaf.nix;
  fn-uses-inputs      = scoped haumeaInputs ./fixtures/fn-uses-inputs.nix;

in {

  # ---------------------------------------------------------------------------
  # scoped loader
  # ---------------------------------------------------------------------------

  # T01  function-valued file is returned as a function (not evaluated)
  T01_scoped_fn_is_function =
    builtins.isFunction fn-leaf;

  # T02  functionArgs on the returned function matches the file's declared params
  T02_scoped_fn_functionArgs_preserved =
    builtins.functionArgs fn-leaf == { pkgs = false; };

  # T03  calling the returned function with perSystem args evaluates correctly
  T03_scoped_fn_result =
    fn-leaf perSystem == "pkgs-hello";

  # T04  multi-arg file: all declared params appear in functionArgs
  T04_scoped_multi_arg_functionArgs =
    builtins.functionArgs fn-multi-arg-leaf == { pkgs = false; lib = false; system = false; };

  # T05  plain-value file is wrapped as a function (not returned bare)
  T05_scoped_plain_value_is_function =
    builtins.isFunction plain-leaf;

  # T06  calling the plain-value wrapper with any args returns the original value
  T06_scoped_plain_value_result =
    plain-leaf perSystem == "plain-value";

  # T07  plain attrset file is also wrapped as a function
  T07_scoped_plain_attrset_is_function =
    builtins.isFunction plain-attrset-leaf;

  # T08  calling the plain attrset wrapper returns the original attrset
  T08_scoped_plain_attrset_result =
    plain-attrset-leaf perSystem == { foo = "bar"; baz = 42; };

  # T09  scopedImport injects haumeaInputs names into the file's top-level scope
  T09_scoped_inputs_injected_fn =
    builtins.isFunction fn-uses-inputs;

  # T10  injected name is accessible inside the file's function body
  T10_scoped_inputs_injected_result =
    fn-uses-inputs perSystem == "string-pkgs-hello";

  # ---------------------------------------------------------------------------
  # dispatch loader
  # ---------------------------------------------------------------------------

  # T11  dispatch with runFn=scoped returns the leaf file's function
  T11_dispatch_result_is_function =
    let result = (dispatch [{ runFn = scoped; }]) haumeaInputs ./fixtures/fn-leaf.nix;
    in builtins.isFunction result;

  # T12  dispatch preserves functionArgs through to the returned function
  T12_dispatch_functionArgs_preserved =
    let result = (dispatch [{ runFn = scoped; }]) haumeaInputs ./fixtures/fn-leaf.nix;
    in builtins.functionArgs result == { pkgs = false; };

  # T13  dispatch result, when called with perSystem args, evaluates correctly
  T13_dispatch_fn_result =
    let result = (dispatch [{ runFn = scoped; }]) haumeaInputs ./fixtures/fn-leaf.nix;
    in result perSystem == "pkgs-hello";

  # T14  dispatch with a policy missing runFn throws (not a cryptic missing-attr error)
  T14_dispatch_missing_runFn_throws =
    let r = builtins.tryEval
              ((dispatch [{ runIf = true; }]) haumeaInputs ./fixtures/fn-leaf.nix);
    in !r.success;

  # T15  dispatch runIf predicate: second policy selected when first does not match
  T15_dispatch_runIf_second_policy =
    let d = dispatch [
              { runIf = _: false; runFn = _: _: "wrong"; }
              { runIf = true;     runFn = scoped; }
            ];
        result = d haumeaInputs ./fixtures/fn-leaf.nix;
    in builtins.isFunction result && builtins.functionArgs result == { pkgs = false; };

  # T16  dispatch with no matching policy throws
  T16_dispatch_no_match_throws =
    let r = builtins.tryEval
              ((dispatch [{ runIf = _: false; runFn = scoped; }])
                haumeaInputs ./fixtures/fn-leaf.nix);
    in !r.success;

  # ---------------------------------------------------------------------------
  # liftDefault transformer interaction
  # (liftDefault receives the output of scoped and must hoist without evaluating)
  # ---------------------------------------------------------------------------

  # T17  single-function default: hoisted directly, functionArgs intact
  T17_liftDefault_fn_default_is_function =
    builtins.isFunction (liftDefault [] { default = fn-leaf; });

  # T18  functionArgs preserved through the hoist
  T18_liftDefault_fn_default_functionArgs =
    builtins.functionArgs (liftDefault [] { default = fn-leaf; }) == { pkgs = false; };

  # T19  function default + siblings: liftDefault returns a deferred merge function
  T19_liftDefault_siblings_is_function =
    let mod = { default = fn-attrset-default; curl = plain-leaf; };
    in builtins.isFunction (liftDefault [] mod);

  # T20  calling the merged result resolves the default's attrset; siblings remain deferred
  T20_liftDefault_siblings_resolved =
    let mod    = { default = fn-attrset-default; curl = plain-leaf; };
        called = (liftDefault [] mod) perSystem;
    in called.myPkg == "pkgs-hello"
    && builtins.isFunction called.curl
    && !(called ? default);

  # T21  plain-value default: returned directly (not wrapped as a function)
  T21_liftDefault_plain_default =
    (liftDefault [] { default = "just-a-string"; }) == "just-a-string";

  # T22  no default key: mod returned unchanged
  T22_liftDefault_no_default_passthrough =
    (liftDefault [] { foo = "a"; bar = "b"; }) == { foo = "a"; bar = "b"; };

}

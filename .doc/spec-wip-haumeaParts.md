# haumeaParts — Specification

> **proj:** haumeaParts · **kind:** spec · **status:** wip · **updated:** 2026-09-22

---

## Purpose

`haumeaParts` is a small pure-Nix library that bridges **haumea** (filesystem-to-attrset loader) and **flake-parts** (flake module system). It provides loaders and transformers so a user can express an entire Nix flake as a directory tree — including the `perSystem` subtree, which requires deferred evaluation — without manual wiring in `flake.nix`.

The library ships four transformers and two loaders. This spec covers their contracts.

---

## Constraints (non-negotiable invariants)

These are hard requirements that any correct implementation must satisfy.

**C1 — No eager evaluation of perSystem files.**  
Files under `perSystem/` must remain unevaluated (as Nix functions) through haumea's entire load pass. They are called only when flake-parts invokes the `perSystem` module for a given system. Any path through the library that forces a perSystem value — even accidentally — is a defect.

**C2 — `builtins.functionArgs` must be preserved on perSystem leaf functions.**  
flake-parts uses `builtins.functionArgs` to determine which arguments to supply when calling a `perSystem` module function. A Nix lambda (a constructed function, not a parsed one) has no `functionArgs`. The function returned by the loader for a perSystem file must therefore be the **parsed function from the file itself** — not a wrapper lambda. Wrapping in `newCtx:` or any other anonymous lambda destroys `functionArgs` and breaks flake-parts compatibility.

**C3 — `liftDefault` applies uniformly inside `perSystem/`.**  
`default.nix` always means "I am the value of my parent directory." This convention applies inside `perSystem/` exactly as it does everywhere else. The perSystem transformer must implement its own `liftDefault` logic for the `perSystem` subtree — it cannot delegate to the general `liftDefault` transformer, because that transformer may evaluate perSystem functions in the wrong context.

**C4 — The general case is not broken.**  
All non-`perSystem` paths — `flake/`, `imports.nix`, `systems.nix`, etc. — must continue to work exactly as before. Changes are surgical and isolated to perSystem handling.

**C5 — flake-parts' module structure is authoritative.**  
The library does not work around flake-parts' module system, type checking, or option validation. If flake-parts rejects something, the library is wrong — not flake-parts. Valid `perSystem` option names are defined by flake-parts and any loaded flake-parts modules; the library does not attempt to enumerate or validate them.

**C6 — Plain-value files are handled uniformly.**  
A file may return a plain value (not a function). Both plain values and functions must be handled in all cases. Inside `perSystem/`, a plain value becomes a constant across all systems and must be wrapped as `_: value` so that `lazyWrap` can call it uniformly. This is consistent with how the general case handles plain-value files.

---

## Loaders

### `loaders/scoped`

**Purpose.** The loader for files matched as inside `perSystem/`. Imports the file with `builtins.scopedImport` (injecting `inputs` into the file's top-level scope), then returns the result without further evaluation.

**Signature.** After instantiation (the `{ ... }:` receives the module's own attrs, ignored):

```
inputs: path → value
```

Where `value` is:
- If the file evaluates to a function: **the function itself**, returned directly so `builtins.functionArgs` is intact.
- If the file evaluates to a plain value: **a constant function** `_: value`, so `lazyWrap` in the `wrap` transformer can call it uniformly.

**Implementation (correct):**

```nix
{ ... }:
inputs: path:
let
  content = builtins.scopedImport inputs path;
in
if builtins.isFunction content
then content
else _: content
```

**What it must not do.** It must not call `content` with any arguments — not with haumea's internal context, not with `newCtx`, not with anything. The function is returned intact for flake-parts to call later, via `wrap`'s `lazyWrap`.

---

### `loaders/dispatch`

**Purpose.** A policy-based dispatch loader. Accepts a list of policies (each pairing a match predicate with a loader function), evaluates them in order, and invokes the first matching loader.

**Signature.** After instantiation and policy partial-application:

```
inputs: path → value
```

**Policy schema:**

| field | type | default | meaning |
|-------|------|---------|---------|
| `runIf` | `bool \| (ctx → bool)` | `true` | match predicate; `ctx` is `{ path, inputs }` |
| `runFn` | `inputs: path → value` | *(none — required)* | the loader to invoke on match |
| `logIf` | `bool \| (ctx → bool)` | `false` | enable trace logging |
| `logPfx` | `string` | `"[L] :dispatch:\t"` | trace prefix |
| `logSfx` | `string` | `""` | trace suffix note |

**`runFn` is required on every policy.** There is no default `runFn`. If no policy matches, or if a matched policy has no `runFn`, dispatch throws with a clear error. This is intentional — dispatch was designed to be wired with explicit loaders per policy, not to have a default that depends on closed-over state.

**Correct behavior when no `runFn` and no fallback:**  
The line `policy.runFn or default.runFn or (throw "...")` must throw because `default.runFn` is absent. The error message names the problem clearly.

---

## Transformers

### `transformers/liftDefault` (haumeaParts variant)

**Purpose.** The `liftDefault` transformer for the `perSystem` subtree. Applies `default.nix`-hoisting semantics without evaluating perSystem functions.

**Signature:** `cursor: mod → mod`

**Behavior:**
- If `mod` has a `default` key and **no siblings**: return `mod.default` directly (the function or value).
- If `mod` has a `default` key and **siblings present**, and `mod.default` is a function: return `args: merge siblings (mod.default args)`, deferring both sides to evaluation time.
- If `mod` has a `default` key and **siblings present**, and `mod.default` is not a function: return `merge siblings mod.default`.
- If `mod` has no `default` key: return `mod` unchanged.

`merge` is a disjoint union, matching upstream haumea's `liftDefault` (`lib.attrsets.unionOfDisjoint`), inlined to keep the library dependency-free:

- **Key collisions are an error.** If `default.nix` produces a top-level key with the same name as a sibling file or directory, accessing that key throws, naming the cursor and every colliding key. The error is lazy: the key still appears in `attrNames`, and non-colliding keys resolve normally. For the function case the default's keys are only known once it is called, so the check happens then.
- **Only an attrset can be merged with siblings.** If `default.nix` returns a non-attrset (string, list, …) or a derivation while siblings exist, `merge` throws. A derivation is rejected because the siblings would otherwise silently become attributes of the derivation.

---

### `transformers/wrap`

**Purpose.** Wraps the assembled `perSystem` subtree in a flake-parts-compatible module function. Applied at `cursor == ["perSystem"]`.

**Signature:** `cursor: mod → module`

**Behavior:** Returns `{ imports = [ haumeaPartsPerSystemResolverTree ]; }` where `haumeaPartsPerSystemResolverTree` is:

```nix
{ pkgs, lib, system, inputs', self', config, ... }@perSystemArgs:
lazyWrap mod perSystemArgs
```

The explicit named parameter signature is required so that `builtins.functionArgs` returns the expected set for flake-parts' module inspection.

`lazyWrap` recurses into the tree: any function node is called with `perSystemArgs`; any attrset is recursed into (unless it is a derivation); any plain value is returned as-is.

---

### `transformers/match`

**Purpose.** Conditionally applies an inner transformer based on a predicate over the current cursor and mod. Optionally traces the decision.

### `transformers/trace`

**Purpose.** Emits a trace line describing the current transformer context. Used for debugging the transformer pipeline.

---

## Recommended usage (flake.nix)

```nix
outputs = { self, ... }@inputs:
  inputs.parts.lib.mkFlake { inherit inputs; } (
    inputs.haumea.lib.load {
      src = ./_attrs;
      inputs = { inherit inputs; };
      loader = inputs.haumeaParts.lib.loaders.dispatch [
        # perSystem files: deferred evaluation, functionArgs preserved
        { runIf = ctx: builtins.match ".*/perSystem/.*\\.nix$" (toString ctx.path) != null;
          runFn = inputs.haumeaParts.lib.loaders.scoped; }
        # general case
        { runFn = inputs.haumea.lib.loaders.scoped; }
      ];
      transformer = [
        (inputs.haumeaParts.lib.transformers.match
          { runIf = ctx: builtins.elem "perSystem" ctx.cursor; }
          inputs.haumeaParts.lib.transformers.liftDefault)
        (inputs.haumeaParts.lib.transformers.match
          { runIf = ctx: !(builtins.elem "perSystem" ctx.cursor); }
          inputs.haumea.lib.transformers.liftDefault)
        (inputs.haumeaParts.lib.transformers.match
          { runIf = ctx: ctx.cursor == ["perSystem"]; }
          inputs.haumeaParts.lib.transformers.wrap)
      ];
    }
  );
```

---

## Execution flow

```
haumea.lib.load
  └─ for each file: dispatch inputs path
       ├─ perSystem/**/*.nix  →  loaders/scoped inputs path
       │    returns: the file's parsed function (functionArgs intact)
       │             or _: content for plain-value files
       └─ all other files     →  haumea.lib.loaders.scoped inputs path
            returns: the file's evaluated value

transformers (bottom-up):
  ├─ haumeaParts.liftDefault  (when cursor ∋ "perSystem")
  │    hoists default.nix keys without evaluating functions
  ├─ haumea.liftDefault       (when cursor ∌ "perSystem")
  │    standard hoist for non-perSystem subtree
  └─ haumeaParts.wrap         (when cursor == ["perSystem"])
       wraps the whole subtree in { imports = [ { pkgs, lib, system, ... }: lazyWrap mod ... } ] }

flake-parts:
  └─ calls haumeaPartsPerSystemResolverTree { pkgs, lib, system, ... } once per system
       └─ lazyWrap recursively calls each deferred function with perSystemArgs
```

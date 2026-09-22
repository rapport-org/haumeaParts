# Insitu — haumeaParts
> **proj:** haumeaParts · **kind:** insitu · **status:** wip · **updated:** 2026-09-22

---

## ethic

### P3-ET — Loader purity: never evaluate what you load
The perSystem loader must return file content as-is. If a file is a function, the loader returns that function. It does not call it, wrap it in a lambda, or interact with its arguments. Evaluation is the responsibility of the consumer (flake-parts, via the `wrap` transformer).

*Why:* Calling a function during load time forces evaluation before the correct argument set (`{ pkgs, lib, system, … }`) exists. Any wrapping in an anonymous lambda destroys `builtins.functionArgs`, breaking flake-parts' introspection of perSystem module signatures.

### P4-ET — Explicit over implicit wiring
Components of the library should not silently depend on each other through closed-over state. A loader instantiated in isolation (`import ./loaders/dispatch.nix {}`) must be fully self-sufficient or fail loudly if it is not — not silently produce a broken value that explodes later when an attribute access fails.

*Why:* Silent failures propagate far from their origin and are hard to diagnose. A clear `throw` at the point of misconfiguration is far preferable to `attribute 'loaders' missing` surfacing in an unrelated error path.

---

## logjam

### 1. [P1-LJ] `scoped.nix` deviates from its own spec — calls leaf functions prematurely
- **Type:** inconsistency (implementation vs. DESIGN.md spec)
- **Blocks:** correct perSystem evaluation (P6-DP)
- **How:** `scoped.nix` is a 3-arg loader (`inputs: path: newCtx:`). It calls `imported newCtx` when the loaded content is a function, wrapping it in an opaque lambda. This violates C2 (destroys `functionArgs`) and C1 (risks eager evaluation if the loader is ever called with 3 args rather than partially applied through dispatch). The DESIGN.md spec explicitly prescribes a 2-arg loader that returns the function directly.
- **Stakes:** perSystem leaf functions lose `functionArgs`; the current design only works because `dispatch` happens to partially apply `scoped` — a fragile, undocumented dependency on call-site behavior.
- **supported-by:** E1, E2
- **O / C:** <4 / 1>

### 2. [P2-LJ] `dispatch.nix` has a latent broken default `runFn`
- **Type:** bug (unreachable but explosive default)
- **Blocks:** safe use of dispatch without explicit `runFn` on every policy (P6-DP)
- **How:** `default.runFn = fnArgs.loaders.scoped` where `fnArgs = {}` (dispatch is exported as `import ./lib/loaders/dispatch.nix {}`). Accessing `fnArgs.loaders` throws `attribute 'loaders' missing`. This path is only avoided because every published usage explicitly provides `runFn` on each policy.
- **Stakes:** any user who omits `runFn` from a policy gets a cryptic, misdirected error rather than a helpful one. The library's own fallback behavior is broken.
- **supported-by:** E3
- **O / C:** <2 / 1>

---

## Appendix

### Design Proposals

#### [P6-DP] Corrective changes to `scoped.nix` and `dispatch.nix`
- **Status:** under-review
- **Relates-to:** P1-LJ, P2-LJ
- **supported-by:** E1, E2, E3

##### Intent / Premise

Two independent bugs exist in the published library. Both are small, surgical fixes. Neither touches the transformer pipeline or the `wrap`/`liftDefault` logic, which is correct.

The fixes are independently applicable — P7-IM (scoped.nix) and P8-IM (dispatch.nix) do not depend on each other.

##### The design

**Fix 1 — `lib/loaders/scoped.nix` (addresses P1-LJ)**

Replace the current 3-arg loader with the 2-arg implementation prescribed by DESIGN.md:

*Current (defective):*
```nix
{ ... }:
inputs: path: newCtx:
let
  imported = builtins.scopedImport (inputs // newCtx) path;
in
if builtins.isFunction imported then imported newCtx else imported
```

*Corrected:*
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

What changes:
- `newCtx` parameter removed — the loader is now a clean 2-arg function, consistent with haumea's standard loader interface.
- `inputs // newCtx` → `inputs` in `scopedImport` — the file's top-level scope receives the user-provided `inputs` (flake inputs, etc.) but not haumea's internal context, which perSystem files do not need.
- `imported newCtx` removed — the function is returned directly. `builtins.functionArgs` is preserved.
- Plain values are wrapped as `_: content` — so `lazyWrap` in `wrap.nix` can call all leaf values uniformly without a separate function/non-function branch.

What does not change: `lazyWrap` in `wrap.nix` still works identically — it calls `node perSystemArgs` when `node` is a function, whether that function is a direct file function or the old partial. The transformer pipeline is untouched.

**Fix 2 — `lib/loaders/dispatch.nix` (addresses P2-LJ)**

Remove `runFn = fnArgs.loaders.scoped;` from the `default` attrset.

*Current (defective):*
```nix
default = {
  runIf = true;
  runFn = fnArgs.loaders.scoped;  ← throws when fnArgs = {}
  logIf = false;
  ...
};
```

*Corrected:*
```nix
default = {
  runIf = true;
  logIf = false;
  ...
};
```

The existing fallback line already handles the missing-`runFn` case correctly:
```nix
runFn = policy.runFn or default.runFn or (throw "${logPfx} no loader (or default loader) provided");
```
With `runFn` absent from `default`, `default.runFn` evaluates via the `or`-chain to the throw. The error message is already present and clear.

##### Convergence stance

Both fixes bring the implementation into alignment with the existing DESIGN.md constraints (C1, C2, C4 in spec-wip-haumeaParts.md). No new behavior is added.

##### Absent / missing capabilities

These fixes do not add tests, CI, or a test harness. Tests are created alongside the fixes in a new `tests/` directory, but no automated test runner is wired into the flake.

##### Staging

- [x] P7-IM — Fix `lib/loaders/scoped.nix` (2-arg loader, return function directly) — landable independently
- [x] P8-IM — Fix `lib/loaders/dispatch.nix` (remove broken default `runFn`) — landable independently
- [ ] P9-IM — Add `tests/` with `nix eval`-based tests for both fixes — landable independently; included in this pass

##### Locked decisions
- 2026-09-22: Use `builtins.scopedImport inputs path` (just `inputs`, not `inputs // newCtx`) — consistent with DESIGN.md; perSystem files receive flake inputs in scope but not haumea's context, which they do not need.
- 2026-09-22: Wrap plain values as `_: content` rather than returning them directly — ensures `lazyWrap` has a uniform `isFunction` path for all leaf values inside `perSystem/`, matching the DESIGN.md spec.

---

### Telemetry // Proposition-Evidence Reference

> next_id: 10

| id | type | state | kinds | version | one-line | links |
|----|------|-------|-------|---------|----------|-------|
| P9-IM | P | open | DP | wip | Add `tests/` with `nix eval`-based test coverage | bears-on: P6-DP |
| P8-IM | P | open | DP | wip | Fix `dispatch.nix`: remove broken default `runFn` | bears-on: P2-LJ, P6-DP |
| P7-IM | P | open | DP | wip | Fix `scoped.nix`: 2-arg loader, return function directly | bears-on: P1-LJ, P6-DP |
| P6-DP | P | under-review | DP | wip | Design Proposal: corrective changes to scoped.nix and dispatch.nix | supported-by: E1, E2, E3 |
| E3 | E | active | LJ | wip | dispatch.nix line 21: `runFn = fnArgs.loaders.scoped` with `fnArgs = {}` | bears-on: P2-LJ |
| E2 | E | active | LJ | wip | scoped.nix line 7: `imported newCtx` called during load — function wrapped in opaque lambda | bears-on: P1-LJ |
| E1 | E | active | LJ | wip | DESIGN.md lines 36-39: spec prescribes 2-arg loader returning content directly | bears-on: P1-LJ |
| P5-ET | P | open | ET | wip | (reserved) | — |
| P4-ET | P | open | ET | wip | Explicit over implicit wiring | — |
| P3-ET | P | open | ET | wip | Loader purity: never evaluate what you load | — |
| P2-LJ | P | open | LJ | wip | dispatch.nix has a latent broken default runFn | supported-by: E3 |
| P1-LJ | P | open | LJ | wip | scoped.nix deviates from its own spec | supported-by: E1, E2 |

### Telemetry // Version-Added Index

| version | ids added |
|---------|-----------|
| wip | P1-LJ, P2-LJ, P3-ET, P4-ET, E1, E2, E3, P6-DP, P7-IM, P8-IM, P9-IM |

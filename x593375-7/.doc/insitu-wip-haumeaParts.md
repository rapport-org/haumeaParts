# Insitu — haumeaParts
> **proj:** haumeaParts · **kind:** insitu · **status:** wip · **updated:** 2026-09-27

---

## intents

### Vision

Express an entire Nix flake — including flake-parts' `perSystem` — as a haumea directory tree, with a small, dependency-free library and near-zero wiring in `flake.nix`.

With v00dot03 (git tag `v0.3.0`), haumea-parts is **complete**. It remains stable and maintained and keeps its existing character: a small library with an informal charter. New and more advanced ergonomics, integrations and adaptations belong to the follow-on project **nix-tessera** (<https://gitlab.com/rapport-org/nix-tessera>), which builds directly on haumea-parts. See P12-ED and P19-ET.

### Pending

None. The charter is fulfilled; further ambitions are routed to nix-tessera (P12-ED).

### Completed since v00

*Composite temperature: n/a. This is the first propalux-scored seal, so there is no prior baseline for a volatility comparison.*

#### v00dot03 (tag `v0.3.0`)

- **P11-IN: Onboarding in two lines.** The common case needs only `loaders.default { src, haumea }` and `transformers.default { haumea }`. The pieces they are built from (`policies.perSystem`, `predicates.*`, `dispatch`, `match`) stay public for customization. O:4 C:2.

#### v00dot02 (tag `v0.2.0`)

- **P10-IN, hardened.** Collision safety restored in the `perSystem` `liftDefault`, zero dependencies, and a modular test suite. O:3 C:2.

#### v00dot01

- **P10-IN: Founding charter delivered.** `perSystem` files are loaded deferred with their `functionArgs` intact, resolved by `wrap` inside flake-parts, and covered by tests run by `nix flake check`. O:4 C:1.

---

## news

### v00dot03 — complete, stable, and easy to start with (tag `v0.3.0`)

haumea-parts lets you describe a whole Nix flake as a folder of `.nix` files: haumea turns the folder into configuration, and flake-parts turns the configuration into flake outputs. That now includes the per-system part of a flake (packages, dev shells, checks), which used to need hand-written wiring. With 0.3.0 the library is complete.

**What's new since 0.2**

- **Two-line setup.** `loaders.default` and `transformers.default` replace roughly thirty lines of wiring. Every building block remains public for anyone who needs something different.
- **More precise.** Only the top-level `perSystem/` folder is treated specially. Previously a `perSystem/` folder nested anywhere could be half-processed. The README's example pattern also had an escaping bug that matched more paths than intended.
- **Clearer rules for per-system files.** The docs now state exactly which arguments each file receives, that files must accept `...`, and how to reach other module arguments (`config._module.args.<name>`).
- **Fixes.** Conditional tracing no longer crashes when its predicate reads the cursor. Trace output from `match` is labelled correctly.
- **Tests** now cover every component end to end: 44 cases, run by `nix flake check`.

**Across the 0.x series**

- **0.1** made deferred per-system loading correct and added a test suite.
- **0.2** made a name clash between a folder's `default.nix` and a sibling file a clear error instead of a silent overwrite. It also removed the last dependency, so the library has no inputs of its own.

**What's next: nix-tessera**

haumea-parts will stay stable and maintained, but it is feature-complete. Further ergonomics, such as a single-call `load` or `mkFlake`, deeper integrations and new adaptations, will happen in **nix-tessera** (<https://gitlab.com/rapport-org/nix-tessera>), which builds directly on haumea-parts. nix-tessera diverges from haumea-parts at 0.3.0, so users on 0.3.0 or earlier can switch by re-pointing their flake input to the same tag in the new repository.

*Volatility temperature: n/a. This is the first propalux-scored seal, so there is no baseline to compare against.*

---

## ethic

### P3-ET — Loader purity: never evaluate what you load

The perSystem loader must return file content as-is. If a file is a function, the loader returns that function. It does not call it, wrap it in a lambda, or interact with its arguments. The one exception is a plain (non-function) value, which is wrapped as `_: content` so `lazyWrap` can call every leaf uniformly; there is no signature to lose. Evaluation is the responsibility of the consumer (flake-parts, via the `wrap` transformer).

*Why:* Calling a function at load time forces evaluation before the correct argument set (`{ pkgs, lib, system, … }`) exists. Wrapping it in an anonymous lambda destroys `builtins.functionArgs` and hides the file's signature (see spec C2).

### P4-ET — Explicit over implicit wiring

Components of the library should not silently depend on each other through closed-over state. A loader instantiated in isolation (`import ./loaders/dispatch.nix {}`) must be fully self-sufficient, or fail loudly if it is not. It must not silently produce a broken value that explodes later when an attribute access fails.

*Why:* Silent failures propagate far from their origin and are hard to diagnose. A clear `throw` at the point of misconfiguration is far preferable to `attribute 'loaders' missing` surfacing in an unrelated error path.

### P16-ET — Zero dependencies; upstream pieces are supplied, never copied

The flake has no inputs. Where the library needs an upstream component, such as haumea's own `loaders.scoped` and `transformers.liftDefault` for the general (non-`perSystem`) case, the caller passes it in: `loaders.default { src, haumea }`, `transformers.default { haumea }`.

*Why:* A dependency-free library never pins a version on its users or forces `follows` overrides. Supplying upstream pieces rather than inlining copies keeps the general case exactly as upstream ships it. A copy would drift silently; for example, upstream `liftDefault` rejects a non-attrset `default.nix`, while the haumeaParts variant accepts one (E21). *supported-by:* E21.

### P19-ET — Completeness: stable, maintained, same character

From v00dot03 (`v0.3.0`), haumea-parts is complete. Changes are maintenance only: fixes, documentation, compatibility with haumea and flake-parts, and small additions that stay within the original charter. The public API does not break. Ergonomics, integrations and adaptations beyond the charter go to nix-tessera (P12-ED).

*Why:* Users need a dependable foundation, and nix-tessera needs a stable base to build on and diverge from. Keeping this project small and settled serves both.

---

## edge

### P12-ED — Beyond-charter ergonomics, integrations and adaptations → nix-tessera

Anything that goes past the informal charter (a small bridge library with composable loaders, transformers, predicates and defaults) is out of scope here. Its home is **nix-tessera** (<https://gitlab.com/rapport-org/nix-tessera>), which builds directly on haumea-parts. nix-tessera diverges from haumea-parts at **`v0.3.0` (v00dot03)** and shares this repository's history up to that release, so any release up to and including `v0.3.0` can be consumed from either repository by the same tag. As of 2026-09-26 nix-tessera mirrored `main` at `3402829` and tag `v0.2.0` (E26); publishing `v0.3.0` there is P30-LJ. *supported-by:* E26.

### P13-ED — One-call entry points (`lib.load`, `lib.mkFlake`): deferred to nix-tessera

Two further onboarding steps were assessed and are handed to nix-tessera as candidates:

- **`lib.load { src, inputs, haumea ? inputs.haumea, … }`** wraps `haumea.lib.load` with both defaults and `inputs = { inherit inputs; }`. The consumer writes `mkFlake { inherit inputs; } (inputs.haumeaParts.lib.load { src = ./_attrs; inherit inputs; })`.
- **`lib.mkFlake { inputs, src, … }`** is a thin layer over `load` that also finds flake-parts among the inputs by name (`parts` / `flake-parts`) and passes `mkFlake`'s other arguments and extra modules through. The consumer writes `outputs = inputs: inputs.haumeaParts.lib.mkFlake { inherit inputs; src = ./_attrs; };`.

Both are workable. They are set aside here because they introduce conventions (input names, argument pass-through) that go beyond this project's charter (P19-ET).

### P14-ED — A flake-parts module with a `haumeaParts.src` option: rejected, not workable

`imports = [ inputs.haumeaParts.flakeModules.default ]; haumeaParts.src = ./_attrs;` cannot work. A module's `imports` cannot depend on option values without infinite recursion, so the module would have to become a function of `src`, which is just P13-ED's `lib.load` again.

### P15-ED — Making haumea a real flake input of haumea-parts: rejected

This would remove the `haumea` argument from the defaults, but it ends the zero-dependency design (P16-ET) and makes haumea-parts choose the haumea version for every consumer unless each overrides it with `follows`. P13-ED's `haumea ? inputs.haumea` default gets nearly the same brevity without the dependency.

### P17-ED — Passing all `_module.args` to leaf files automatically: rejected

Calling leaves with `config._module.args // perSystemArgs` would let a leaf name any module argument. It recurses infinitely whenever `perSystem/default.nix` is a function, because the module system must call the resolver to learn which options it defines, and that forces `config._module.args` (E18). Leaves read other arguments lazily as `config._module.args.<name>` instead. *supported-by:* E18.

---

## grit

### P20-GR — When forking an upstream component, diff its safety properties

The haumeaParts `liftDefault` was written to delay the merge for `perSystem`. In the process it replaced upstream's `unionOfDisjoint` with `//`, silently turning a collision error into a silent overwrite. This went unnoticed until v00dot02, and the docs briefly called the overwrite "intrinsic". Lesson: when re-implementing an upstream function, read the upstream source and list every guarantee it gives (errors, laziness, type checks) before calling any behavior intrinsic. *supported-by:* E21.

### P22-GR — Nix string escapes eat regex backslashes; prefer prefix comparison for paths

In a Nix double-quoted string, `"\."` is just `.`, so `".*/perSystem/(.*\.nix)?$"` matches far more than intended. A regex needs `"\\."`. For path tests, prefer a prefix comparison against `"${toString src}/perSystem/"`: it has no escaping hazards, and special characters in store paths can't affect it. *supported-by:* E23.

### P24-GR — Verify module-system claims against real flake-parts

Several confident claims about how flake-parts calls functions were wrong or incomplete until they were run in a scratch flake:

- which arguments leaves receive
- whether a bare `args:` works
- why auto-merging `_module.args` fails; the first explanation, `_module/args` in the tree, was wrong because haumea ignores `_`-prefixed paths

Pure unit tests cannot catch these, because they stub the module system. Lesson: check module-system behavior in a real flake before documenting it. *supported-by:* E18, E25.

---

## logjam

Ranked by value blocked (propalux, low intensity, offset safety, Cmax 3):

### 1. [P30-LJ] `v0.3.0` is not yet published to nix-tessera

- **Type:** blocker (operator-held)
- **Blocks:** the migration promise in news, README and the spec, that users on `v0.3.0` or earlier can re-point to the same tag in nix-tessera. Today nix-tessera has only `v0.2.0` (E26).
- **How:** the operator has asked that nothing be pushed to nix-tessera for now, so the divergence tag exists only here.
- **Stakes:** re-pointing a `v0.3.0` pin at nix-tessera fails until the tag is published there.
- **Propalux:** O:3 C:1, I=9.00, Quick Win (balanced), **do now once the operator releases the hold**.
- *supported-by:* E26

### 2. [P29-LJ] GitLab Release objects are missing for `v0.2.0` and `v0.3.0`

- **Type:** blocker (tooling)
- **Blocks:** Release pages for the published tags (the tags themselves are published)
- **How:** `glab release create` is refused because the access token lacks the "Release: Create" permission.
- **Stakes:** cosmetic and discoverability only.
- **Propalux:** O:1 C:1, I=3.00, Freebie (safety-leaning), **opportunistic**.

**Resolved at v00dot03:** P27-LJ (git tags are semver `v<major>.<minor>.0`; the project notes use `v<MM>dot<NN>`, so `v0.3.0` is v00dot03; recorded in the spec's Maintainer's Guide). P28-LJ (nix-tessera diverges at `v0.3.0`; recorded in the spec's User Guide, the README and P12-ED).

---

## Appendix

### Landing register

| when | landed | bears-on | note |
|------|--------|----------|------|
| 2026-09-27 · v00dot03 | Release `v0.3.0` cut; the notes' version token and the git tag scheme reconciled (P27-LJ); nix-tessera divergence fixed at `v0.3.0` (P28-LJ) | P30-LJ, P29-LJ | tag not published to nix-tessera (operator hold) |
| 2026-09-26 · v00dot03 | Default wiring: `loaders.default { src, haumea }`, `transformers.default { haumea }`, `policies.perSystem src`, `predicates.*` | P11-IN, P16-ET, P13-ED | two-line onboarding; building blocks remain public |
| 2026-09-26 · v00dot03 | `perSystem` detection anchored to the top-level `perSystem/` (path-prefix and cursor-head checks) | P22-GR, E23; spec Errata | a nested `perSystem/` was deferred but never wrapped |
| 2026-09-26 · v00dot03 | `match`: `logIf` gets the full context; its own `logPfx` reaches `trace`. Dead `logIf` fallbacks removed in dispatch/match/trace. `dispatch` no longer re-evaluates `runIf`, and uses `toString` for paths in logs and errors | spec transformers/match, loaders/dispatch | a `logIf` reading `ctx.cursor` used to abort evaluation |
| 2026-09-26 · v00dot03 | Leaf-call contract documented (argument set, `...` required, `config._module.args.<name>`, functor walking) | E25, P17-ED, P24-GR | verified against real flake-parts |
| 2026-09-26 · v00dot03 | Tests for wrap, match, trace, pipeline, predicates, policies and defaults (44 cases); runner helpers | spec Maintainer's Guide | |
| 2026-09-26 · v00dot02 (`v0.2.0`, 3402829) | Tests restructured: one file per case under `tests/cases/<unit>/`; runner discovers cases and fixtures | spec Maintainer's Guide | |
| 2026-09-26 · v00dot02 (054f198) | `perSystem` `liftDefault` made a disjoint union again (lazy collision error naming the cursor); a non-attrset or derivation `default.nix` with siblings is rejected | P20-GR, E21 | restores parity with upstream |
| 2026-09-26 · v00dot02 (700b91e) | nixpkgs input removed; zero dependencies | P16-ET | |
| 2026-09-22 · v00dot01 (9b6af81) | P6-DP landed: 2-argument `scoped` loader, broken default `runFn` removed from `dispatch`, tests wired into `nix flake check` (P7-IM..P9-IM) | P1-LJ, P2-LJ | resolved both original logjam entries |

### Telemetry // Proposition-Evidence Reference

> next_id: 31

| id | type | state | kinds | version | one-line | links |
|----|------|-------|-------|---------|----------|-------|
| P30-LJ | P | open | LJ | v00dot03 | `v0.3.0` not yet published to nix-tessera (operator hold) | supported-by: E26 |
| P29-LJ | P | open | LJ | v00dot03 | GitLab Release objects missing for `v0.2.0`, `v0.3.0` (token scope) | — |
| P28-LJ | P | resolved | LJ, SP, ED | v00dot03 | nix-tessera diverges at `v0.3.0` | supported-by: E26 |
| P27-LJ | P | resolved | LJ, SP | v00dot03 | Git tags semver `v<major>.<minor>.0`; notes use `v<MM>dot<NN>` | blocks: P28-LJ |
| E26 | E | active | ED | v00dot03 | nix-tessera remote mirrors `main` at 3402829 and tag `v0.2.0` (2026-09-26) | bears-on: P12-ED, P28-LJ |
| E25 | E | active | GR | v00dot03 | Leaf argument set verified in a real flake; `{ pkgs }:` fails "unexpected argument 'system'"; named custom `_module.args` fail | bears-on: P24-GR, P17-ED |
| P24-GR | P | active | GR | v00dot03 | Verify module-system claims against real flake-parts | supported-by: E18, E25 |
| E23 | E | active | GR | v00dot03 | `nix eval --expr '"\."'` returns `"."` | bears-on: P22-GR |
| P22-GR | P | active | GR | v00dot03 | Nix string escapes eat regex backslashes; prefer prefix compare | supported-by: E23 |
| E21 | E | active | ET, GR | v00dot03 | Upstream haumea `liftDefault` = `unionOfDisjoint`; collision throws `unionOfDisjoint: collision on baz`; rejects non-attrset `default` | bears-on: P20-GR, P16-ET |
| P20-GR | P | active | GR | v00dot03 | When forking upstream, diff its safety properties | supported-by: E21 |
| P19-ET | P | active | ET | v00dot03 | Completeness: stable, maintained, same character | relates-to: P12-ED |
| E18 | E | active | ED, GR | v00dot03 | `config._module.args // perSystemArgs` → `infinite recursion encountered` when `perSystem/default.nix` is a function | bears-on: P17-ED, P24-GR |
| P17-ED | P | rejected | ED | v00dot03 | Auto-pass all `_module.args` to leaves | supported-by: E18 |
| P16-ET | P | active | ET | v00dot03 | Zero dependencies; upstream pieces supplied, never copied | supported-by: E21 |
| P15-ED | P | rejected | ED | v00dot03 | haumea as a real flake input | relates-to: P16-ET |
| P14-ED | P | rejected | ED | v00dot03 | flake-parts module with a `haumeaParts.src` option | relates-to: P13-ED |
| P13-ED | P | deferred | ED | v00dot03 | One-call `lib.load` / `lib.mkFlake` → nix-tessera | relates-to: P12-ED, P11-IN |
| P12-ED | P | active | ED | v00dot03 | Beyond-charter work → nix-tessera | supported-by: E26 |
| P11-IN | P | completed | IN | v00dot03 | Two-line onboarding defaults | relates-to: P16-ET |
| P10-IN | P | completed | IN | v00dot03 | Founding charter: whole flake incl. `perSystem` as a haumea tree | relates-to: P6-DP |
| P9-IM | P | landed | DP, IM, SP | v00dot01 | Add `tests/` with `nix eval`-based coverage | bears-on: P6-DP |
| P8-IM | P | landed | DP, IM, SP | v00dot01 | Fix `dispatch.nix`: remove broken default `runFn` | bears-on: P2-LJ, P6-DP |
| P7-IM | P | landed | DP, IM, SP | v00dot01 | Fix `scoped.nix`: 2-argument loader, return function directly | bears-on: P1-LJ, P6-DP |
| P6-DP | P | accepted | DP, SP | v00dot01 | Corrective changes to `scoped.nix` and `dispatch.nix` (graduated to spec) | supported-by: E1, E2, E3 |
| E3 | E | active | LJ | v00dot01 | `dispatch.nix` line 21: `runFn = fnArgs.loaders.scoped` with `fnArgs = {}` | bears-on: P2-LJ |
| E2 | E | active | LJ | v00dot01 | `scoped.nix` line 7: `imported newCtx` called during load | bears-on: P1-LJ |
| E1 | E | active | LJ | v00dot01 | spec (then DESIGN.md) prescribed a 2-argument loader returning content directly | bears-on: P1-LJ |
| P5-ET | P | retired | ET | v00dot01 | (reserved placeholder; never used) | — |
| P4-ET | P | active | ET | v00dot01 | Explicit over implicit wiring | — |
| P3-ET | P | active | ET | v00dot01 | Loader purity: never evaluate what you load | — |
| P2-LJ | P | resolved | LJ, SP | v00dot01 | `dispatch.nix` had a latent broken default `runFn` | supported-by: E3 |
| P1-LJ | P | resolved | LJ, SP | v00dot01 | `scoped.nix` deviated from its own spec | supported-by: E1, E2 |

### Telemetry // Version-Added Index

| version | ids added |
|---------|-----------|
| v00dot03 | P10-IN, P11-IN, P12-ED, P13-ED, P14-ED, P15-ED, P16-ET, P17-ED, E18, P19-ET, P20-GR, E21, P22-GR, E23, P24-GR, E25, E26, P27-LJ, P28-LJ, P29-LJ, P30-LJ |
| v00dot02 | — |
| v00dot01 | P1-LJ, P2-LJ, P3-ET, P4-ET, P5-ET, P6-DP, P7-IM, P8-IM, P9-IM, E1, E2, E3 |

### Telemetry — volatility by seal

| seal | intents temperature | logjam centroid | note |
|------|--------------------|-----------------|------|
| v00dot03 (2026-09-27) | n/a (no prior baseline) | prep: I=8.00, Quick Win, balanced; at seal: P30-LJ I=9.00 Quick Win, P29-LJ I=3.00 Freebie | first propalux-scored seal |

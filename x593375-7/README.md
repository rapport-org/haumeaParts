# haumeaParts

*.. using Flake-Parts with Haumea - so elegant ..*

> **Status: complete.** haumea-parts is stable and maintained: its public API (`lib.loaders`, `lib.transformers`, `lib.predicates`, `lib.policies`) won't break, and changes are limited to fixes, documentation and compatibility. New and more advanced ergonomics, integrations and adaptations are being built in the follow-on project **[nix-tessera](https://gitlab.com/rapport-org/nix-tessera)**, which builds directly on haumea-parts. nix-tessera diverges from haumea-parts at `v0.3.0`, so a flake pinned to haumea-parts `v0.3.0` or earlier can switch by re-pointing its input to the same tag in nix-tessera.


## Why 

- .. express a Nix flake entirely as a directory tree, with the filesystem structure mirroring the flake's output structure. 
- .. all `outputs` are managed as a semantically hierarchical (Dendritic-adjacent) tree of `.nix` files and directories.
- .. a flake-forward approach with a minimal and rarely changing `flake.nix`.

We can _literally_ drag-and-drop a compatible configuration into place, because configurations are added to a flake by creating a file/directory at the right path - no boilerplate or wiring required.


## What This Is

This project provides a small pure-Nix library for Haumea — to bridge these two popular and *wonderful* libraries: **haumea** (filesystem-to-attrset loader) and **flake-parts** (flake module system).



### haumea

[haumea](https://github.com/nix-community/haumea) loads a directory tree of `.nix` files into a Nix attrset. The filesystem path becomes the attrset path:

```
_attrs/
  foo.nix        →  { foo = <value>; }
  bar/
    baz.nix      →  { bar.baz = <value>; }
    default.nix  →  <value>   # liftDefault: default.nix hoists to parent, which means that this 'value' is used for the value for 'bar'
```

`default.nix` always means "I am the value of my parent directory." If you want a `default` key in the output, you return `{ default = ...; }` from inside `default.nix`. This convention is enforced uniformly — no exceptions.

When `default.nix` sits beside sibling files, its output and the siblings must not share key names. If `bar/default.nix` returns `{ baz = ...; }` next to `bar/baz.nix`, accessing `bar.baz` is an evaluation error. haumea's `liftDefault` does this via `unionOfDisjoint`, and the haumeaParts `perSystem` variant does the same, adding the cursor to the message. In that case `default.nix` must also return an attrset (not a string or derivation), since there is nothing else to merge the siblings into.

haumea supports **loaders** (how individual files are imported) and **transformers** (how the assembled attrset is post-processed at each node). It also supports `scopedImport`, which injects names into a file's top-level scope. For the general (non-`perSystem`) case, `inputs` is injected this way. Files under `perSystem/` receive `pkgs`, `lib`, `system`, and other system-specific names as function arguments — they are **not** available via ambient scope injection.

### flake-parts

[flake-parts](https://flake.parts) structures a Nix flake as a module system. A flake's `outputs` is built by `mkFlake`, which accepts a list of modules. Each module is either an attrset or a function returning an attrset, with keys like `perSystem`, `flake`, `imports`, etc.

The critical constraint is `perSystem`. In flake-parts, `perSystem` is a function that receives system-specific arguments and returns per-system outputs:

```nix
{
  perSystem = { pkgs, lib, system, inputs', self', config, ... }: {
    packages.hello = pkgs.hello;
  };
}
```

flake-parts calls this function once per system in `config.systems`, passing a fully-constructed argument set. The argument set is constructed using `builtins.functionArgs` to inspect what the function declares — **only explicitly named parameters are provided**. A bare `args:` binding does not work; named parameters are required. (This applies to module functions. haumeaParts' own leaf files are called differently — see [Leaf files under `perSystem/`](#leaf-files-under-persystem).)

Even without the **haumeaParts**'s extensions, the non-`perSystem` portions of a **Haumea** config already worked with **flake-parts**. haumeaParts closes the remaining gap: it gathers the `perSystem` subtree and wraps it into a flake-parts module, so both halves of the flake work from the same directory tree.

---

## What Already Worked

The general case was already **fully functional**. The directory tree:

```
_attrs/
  imports.nix
  systems.nix
  flake/
    nixosConfigurations/
      myhost/
        default.nix
    darwinConfigurations/
      mylaptop/
        default.nix
    homeConfigurations/
      user@host/
        default.nix
    overlays/
      default.nix
    lib/
      mylib.nix
```

...loads correctly via haumea and is accepted by flake-parts as a valid module. The haumea output is passed directly as the module argument to `mkFlake`. `liftDefault` works correctly throughout, and `scopedImport` injects `inputs` into file scope.

---

## The Gap Closed: `perSystem`

The `perSystem` subtree requires special handling because files inside it need `pkgs`, `lib`, `system`, `inputs'`, `self'`, and `config` — arguments that **do not exist at haumea load time**. **haumeaParts** wraps these components in a **flake-parts** module function which is passed through **haumea** unevaluated then evaluated in the **flake-parts**'s module evaluation context.

This means files under `perSystem/` cannot be evaluated during haumea's load pass. They must be **deferred**: stored as functions and called later, once per system, inside the flake-parts module that `wrap` builds.

The filesystem structure to support:

```
_attrs/
  perSystem/
    packages/
      default.nix     →  perSystem.packages.default
      curl.nix        →  perSystem.packages.curl
    devShells/
      default.nix     →  perSystem.devShells.default
    checks/
      default.nix     →  perSystem.checks.default
    apps/
      default.nix     →  perSystem.apps.default
```

A file like `perSystem/packages/curl.nix` looks like any other haumea file:

```nix
{ pkgs, ... }:
pkgs.curl
```

It is not called by haumea. flake-parts calls the `perSystem` module that `wrap` builds, and that module calls each leaf.

### Leaf files under `perSystem/`

Leaf files are called directly by `wrap`'s `lazyWrap`, not introspected by the module system, so the rules differ from flake-parts module functions:

- **Accept `...`.** Every leaf receives the same argument set: `pkgs`, `lib`, `system`, `inputs'`, `self'`, `config`, plus the module system's `options`, `specialArgs`, `_class` and `_prefix`. A leaf written as `{ pkgs }: …` fails with "called with unexpected argument". A bare `args:` does work.
- **Other `_module.args` are not passed by name.** A leaf asking for `{ myArg, ... }` set via `perSystem._module.args.myArg` fails with "called without required argument". Read it as `config._module.args.myArg` instead.
- **Every function value in the tree is called.** `lazyWrap` calls any function it meets with the argument set, and walks into any attrset that isn't a derivation — including attrsets with `__functor`, whose `__functor` gets called. A `perSystem` option whose *value* should be a function can't be expressed as a bare function in the tree.

## Repository Structure

```
lib/
  loaders/
    default.nix      ← the standard loader: loaders.default { src, haumea }
    dispatch.nix     ← first-match-wins policy loader
    scoped.nix       ← the perSystem loader (defers evaluation)
  transformers/
    default.nix      ← the standard transformer list: transformers.default { haumea }
    liftDefault.nix  ← the perSystem liftDefault (defers the merge)
    wrap.nix         ← turns the perSystem subtree into a flake-parts module
    match.nix        ← applies a transformer only where a predicate holds
    trace.nix        ← debug tracing for the transformer pipeline
  predicates.nix     ← runIf predicates for the standard wiring
  policies.nix       ← ready-made dispatch policies (policies.perSystem src)
tests/
  default.nix        ← runner: discovers tests/cases/** and fixtures/, run by nix flake check
  cases/<unit>/*.nix ← one test per file
  fixtures/*.nix
```

## Flake.nix Example

```nix
# flake.nix (consuming project)
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.parts.url = "github:hercules-ci/flake-parts";
  inputs.haumea.url = "github:nix-community/haumea";
  inputs.haumea.inputs.nixpkgs.follows = "nixpkgs";
  inputs.haumeaParts.url = "gitlab:rapport-org/haumea-parts";

  outputs = inputs:
    let src = ./_attrs; in
    inputs.parts.lib.mkFlake { inherit inputs; } (
      inputs.haumea.lib.load {
        inherit src;
        inputs = { inherit inputs; };
        loader = inputs.haumeaParts.lib.loaders.default { inherit src; inherit (inputs) haumea; };
        transformer = inputs.haumeaParts.lib.transformers.default { inherit (inputs) haumea; };
      }
    );
}
```

- **`loaders.default { src, haumea }`** defers files under `<src>/perSystem/` and sends everything else to haumea's own `scoped` loader. `src` must be the same path you give `haumea.lib.load`.
- **`transformers.default { haumea }`** is a list: haumeaParts' `liftDefault` inside `perSystem/`, haumea's `liftDefault` everywhere else, then `wrap` at the `perSystem` node. Add your own with `++`.

Both take the haumea flake as `haumea` because haumeaParts has no dependencies of its own; the general case uses haumea's loader and `liftDefault` exactly as haumea ships them.

### Customizing the wiring

The defaults are built from public pieces, so you can drop down a level for any part. This is exactly what the defaults expand to:

```nix
        # loader: first matching policy wins
        loader = hp.loaders.dispatch [
          # perSystem files: deferred, called later by flake-parts
          (hp.policies.perSystem src)
          # everything else: haumea's normal loader
          { runFn = inputs.haumea.lib.loaders.scoped; }
        ];
        # transformers: applied in order at every node, bottom-up
        transformer = [
          (hp.transformers.match
            { runIf = hp.predicates.cursorInPerSystem; }
            hp.transformers.liftDefault)
          (hp.transformers.match
            { runIf = hp.predicates.cursorOutsidePerSystem; }
            inputs.haumea.lib.transformers.liftDefault)
          (hp.transformers.match
            { runIf = hp.predicates.cursorIsPerSystem; }
            hp.transformers.wrap)
        ];
```

(with `hp = inputs.haumeaParts.lib;`)

`hp.policies.perSystem src` is the whole dispatch policy: `{ runIf = hp.predicates.pathInPerSystem src; runFn = hp.loaders.scoped; }`. It's a plain attrset, so you can add or override fields with `//`, e.g. `(hp.policies.perSystem src) // { logIf = true; }`.

`lib.predicates` holds the `runIf` checks for the standard wiring:

| predicate | for | true when |
|---|---|---|
| `pathInPerSystem src` | `loaders.dispatch` | the file is under `<src>/perSystem/`. Pass the same `src` given to `haumea.lib.load`: loader paths are absolute, so the predicate can't otherwise know where the tree starts. |
| `cursorInPerSystem` | `transformers.match` | the node is `perSystem` or below it |
| `cursorOutsidePerSystem` | `transformers.match` | the complement, including the root |
| `cursorIsPerSystem` | `transformers.match` | the node is `perSystem` itself, which is where `wrap` applies |

Only the top-level `perSystem/` is special. A `perSystem/` directory nested elsewhere, such as `flake/foo/perSystem/`, is loaded and transformed like any other directory. Plain `ctx: …` functions still work anywhere these are used.

The two `liftDefault` entries match disjoint parts of the tree, so their relative order doesn't matter. What matters is that both come before `wrap`: at the `perSystem` node itself, `perSystem/default.nix` must be lifted before the subtree is wrapped.

---

No manual `perSystem = ...` anywhere in `flake.nix`. The filesystem is the configuration.




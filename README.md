# haumeaParts

*.. using Flake-Parts with Haumea - so elegant ..*


## Why 

- .. express a Nix flake entirely as a directory tree, with the filesystem structure mirroring the flake's output structure. 
- .. all `outputs` are managed using a semantically hierarchial (Dendritic-adjacent), of `.nix` files and directory of configurations.
- .. a flake -forward approach with a minimal and infrequently changing flake.nix file.

We can _literally_ drap-and-drop a compatible configuration into place, because configurations are added to a flake by creating a file/directory at the right path - no boilerplate or wiring required.


## What This Is

This project provides a few small pure nix library for Haumea — to bridge these two popular and *wonderful* libraries: **haumea** (filesystem-to-attrset loader) and **flake-parts** (flake module system).



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

haumea supports **loaders** (how individual files are imported) and **transformers** (how the assembled attrset is post-processed at each node). It also supports `scopedImport`, which injects names into a file's top-level scope without the file needing to explicitly receive them as function arguments.

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

flake-parts calls this function once per system in `config.systems`, passing a fully-constructed argument set. The argument set is constructed using `builtins.functionArgs` to inspect what the function declares — **only explicitly named parameters are provided**. A bare `args:` binding does not work; named parameters are required.

Even without the **haumeaParts**'s extensions, the non-`perSystem` portions of a **Haumea** config already worked with **flake-parts**. The libraries in this extension provide an accumulator/wrapper which close the final `perSystem` for full interoperability across both halves across the same terms.

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

...loads correctly via haumea and is accepted by flake-parts as a valid module. The haumea output is passed directly as the module argument to `mkFlake`. `liftDefault` works correctly throughout, `scopedImport` injects `inputs` into file scope, and `__func.nix` handles function-valued outputs where needed.

---

## The Gap Closed: `perSystem`

The `perSystem` subtree requires special handling because files inside it need `pkgs`, `lib`, `system`, `inputs'`, `self'`, and `config` — arguments that **do not exist at haumea load time**. **haumeaParts** wraps these components in a **flake-parts** module function which is passed through **haumea** unevaluated then evaluated in the **flake-parts**'s module evaluation context.

This means files under `perSystem/` cannot be evaluated during haumea's load pass. They must be **deferred**: stored as functions, expanded for `system` and called later by flake-parts with the correct arguments.

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

It receives `pkgs` etc. as named function arguments. It is called by flake-parts, not by haumea.


## Repository Structure

```
lib/
  loaders/
    scoped.nix   ← the perSystem loader
  transformers/
    liftDefault.nix  ← the perSystem transformer
  # ... existing haumea files, do not modify
```

## Flake.nix Example

```nix
# flake.nix (consuming project)
##<inputs>##

##</inputs>##
  inputs.haumeaParts.url = "github:rapport-org/haumeaParts";
  inputs.haumea.url = "github:nix-community/haumea";
##<outputs>##
outputs = {self, ...} @ inputs:
  inputs.parts.lib.mkFlake {inherit inputs;} (
    # Note the blending of haumea with haumeaParts 
    inputs.haumea.lib.load {
      src = ./_attrs;
      inputs = {inherit inputs;};
      # loader operates as a first match wins system
      loader = inputs.haumeaParts.lib.loaders.dispatch
          [
            # handle the perSystem case w/ a special loader before the general case
            { runIf = ctx: builtins.match ".*/perSystem/(.*\.nix)?$" (builtins.toString ctx.path) != null;
              runFn = inputs.haumeaParts.lib.loaders.scoped; }
            # handle the general case w/ a normal loader
            { runFn = inputs.haumea.lib.loaders.scoped; }
          ];
      # transformers operate as an assembly line of sequential (potential) match-action modifications
      transformer = 
      [
        #(inputs.haumea.lib.transformers.trace {})
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
##</outputs>##
```

Order matters: `haumeaParts:liftDefault` runs first and matches on entries under the `perSystem` subtree, while `haumea:liftDefault` matches on the inverse.

---

No manual `perSystem = ...` anywhere in `flake.nix`. The filesystem is the configuration.




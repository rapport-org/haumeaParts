## Technical Constraints

These are non-negotiable and must be respected throughout:

**1. Do not trigger evaluation of perSystem files during haumea's load pass.**
Files under `perSystem/` return functions. Those functions must remain unevaluated until flake-parts calls them. Any transformer logic that forces a perSystem value — even accidentally, e.g. via `//` on a function, or `?` on a value that turns out to be a function — is incorrect.

**2. Preserve `builtins.functionArgs` on the final `perSystem` function.**
flake-parts uses `builtins.functionArgs` to determine which arguments to pass to a `perSystem` module. A function constructed in Nix (a lambda) has no `functionArgs`. Therefore, the function delivered to flake-parts as the value of `perSystem` must have an **explicit named parameter signature**, not be an opaque constructed lambda. This means the transformer must wrap the assembled perSystem subtree in a function with an explicit `{ pkgs, lib, system, inputs', self', config, ... }:` signature.

**3. `liftDefault` applies uniformly, including inside `perSystem/`.**
`default.nix` always means "I am the value of my parent directory." This applies inside `perSystem/` exactly as it does everywhere else. The perSystem transformer must implement its own `liftDefault` logic for the perSystem subtree — it cannot delegate to the general `liftDefault` transformer, because that transformer would attempt to evaluate perSystem functions in the wrong context.

**4. The general case must not be broken.**
The existing working behavior for `flake/`, `imports.nix`, `systems.nix`, and all other non-perSystem paths must continue to work exactly as before. Changes must be surgical and isolated to perSystem handling.

**5. flake-parts' module structure is authoritative.**
We do not try to work around flake-parts' module system, type checking, or option validation. If flake-parts rejects something, the library is wrong, not flake-parts. Valid `perSystem` option names are defined by flake-parts and any loaded flake-parts modules; we do not attempt to enumerate or validate them ourselves.

**6. Files work "naked" or with function arguments.**
A file may return a plain value (no function wrapping) or a function. Both must be handled. For perSystem files, a plain value becomes a constant across all systems; a function is called with perSystemArgs. This is consistent with how the general case handles files.

---



## The Implementation: Two Files

All the work lives in two files within the haumea library source:

### `lib/loaders/scoped.nix`

This is the **loader** for files matched as being inside `perSystem/`. Its job: import the file with `scopedImport` (injecting `inputs` into scope), and return the result **as-is** — if it's a function, return the function directly so that `builtins.functionArgs` is preserved. Do not wrap it in another lambda.

```nix
inputs: path:
  let content = builtins.scopedImport inputs path;
  in if builtins.isFunction content
     then content          # return directly — functionArgs intact
     else _: content       # wrap plain values as constant functions
```

### `lib/transformers/liftDefault.nix`

This is the **transformer** that post-processes the assembled haumea attrset. It runs at every node in the tree. Its responsibilities:

- **Inside `perSystem/`** (cursor contains `"perSystem"` but is not `["perSystem"]`): apply `liftDefault` semantics safely, without evaluating any functions. When a node has a `default` key alongside siblings, merge them lazily.

- **At `cursor == ["perSystem"]`**: the entire perSystem subtree has been assembled into a tree of deferred functions. Wrap it in a single function with an explicit named signature that flake-parts can inspect, which recursively calls the deferred functions when invoked.

- **Everywhere else**: pass through untouched — the general `liftDefault` transformer handles it.

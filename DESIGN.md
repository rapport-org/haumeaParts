Here is a complete, rewritten `DESIGN.md` for the `haumeaParts` repository. This version synthesizes the core mechanics of `haumea` and `flake-parts`, incorporates the corrected Nix module system constraints we discussed, and serves as a comprehensive architectural blueprint for the project.

---

# Architecture & Design of haumeaParts

This document outlines the internal architecture, technical constraints, and design decisions behind `haumeaParts`. It is intended for maintainers and contributors who want to understand how the library bridges the gap between `haumea` and `flake-parts`.

## 1. The Core Problem: Eager vs. Deferred Evaluation

`haumeaParts` exists to bridge two libraries with fundamentally different evaluation models:

* **haumea (Eager):** Designed to crawl a directory tree and immediately load `.nix` files into a static attribute set. It processes files at load time.
* **flake-parts (Deferred):** Structured as a Nix module system. While top-level flake outputs can be static, the `perSystem` outputs are strictly deferred. They are defined as functions that require per-system arguments (like `pkgs`, `system`, and `config`), which are only injected later by `mkFlake` during module evaluation.

**The Conflict:** If `haumea` eagerly evaluates a file under `perSystem/` that expects `pkgs`, it crashes because `pkgs` does not exist in the initial load context. Therefore, `haumeaParts` must intercept the `perSystem/` directory, suppress haumea's eager evaluation, and safely construct a tree of functions that `flake-parts` can evaluate later.

## 2. Technical Constraints

To successfully interface with the Nix module system, `haumeaParts` must strictly adhere to the following constraints:

### I. Suppress Evaluation in `perSystem/`

Files under the `perSystem/` directory must remain unevaluated during haumea's load pass. Any transformer logic that forces the evaluation of a `perSystem` node—even accidentally (e.g., via checking a type or attempting to merge a function with `//`)—will result in an evaluation error.

### II. Preserve `builtins.functionArgs` for `flake-parts`

The Nix module system uses `builtins.functionArgs` to detect which arguments a module requires.

* If a function is wrapped in a generic bare lambda (e.g., `args: ...`), `builtins.functionArgs` returns `{}`, and `flake-parts` will fail to inject necessary arguments.
* The final constructed `perSystem` function must explicitly declare its required arguments. Ideally, this should be done dynamically using `lib.setFunctionArgs` to merge the argument requirements of all leaf nodes, ensuring compatibility with custom arguments injected by third-party `flake-parts` modules. *(Note: If a static signature is used as a fallback, it must explicitly list all standard flake-parts arguments).*

### III. Function Composition over Merging (The `liftDefault` rule)

In a standard haumea tree, `default.nix` means "I am the value of my parent directory," and is merged with its siblings.
Inside `perSystem/`, the nodes are *functions*, not attribute sets. Functions cannot be merged using standard attribute set updates (`//`). Therefore, to apply `liftDefault` semantics inside `perSystem/`, the transformer must construct a **new composite function**. When evaluated, this composite function passes the arguments to the `default.nix` function, passes the arguments to all sibling functions, and *then* merges the resulting attribute sets.

### IV. Non-Interference

The existing working behavior for `flake/`, `imports.nix`, `systems.nix`, and all other non-perSystem paths must continue to work exactly as standard `haumea` dictates. Custom logic must be surgically isolated to the `perSystem` subtree.

### V. Module System Authority

We do not attempt to work around `flake-parts`' type checking or option validation. Valid `perSystem` option names are defined by `flake-parts` modules. `haumeaParts` acts purely as a delivery mechanism; if `flake-parts` rejects the resulting structure, our delivery mechanism is wrong.

## 3. The Implementation Pipeline

The execution of `haumeaParts` relies on intercepting the `haumea` assembly line using custom loaders and transformers.

### Phase 1: The Loader (`lib/loaders/scoped.nix`)

The loader targets files matched inside the `perSystem/` tree. Its primary job is normalization without evaluation.
Files can be written "naked" (returning a plain value) or as a function. The loader ensures everything becomes a function:

1. **Functions:** Returned exactly as-is to preserve their `functionArgs`.
2. **Plain Values:** Wrapped in a constant function (`_: content`), making them consistent with the rest of the tree.

### Phase 2: The Inner Transformer (`lib/transformers/liftDefault.nix`)

This transformer operates *inside* the `perSystem/` tree (where the cursor contains `"perSystem"` but is not exactly `["perSystem"]`).
It implements the **Function Composition** constraint described above. It safely restructures the tree by collapsing `default.nix` files into their parent directories by wrapping the sibling functions into unified composite functions, ensuring no leaf nodes are actually evaluated during the traversal.

### Phase 3: The Master Wrapper

At the root of the perSystem tree (`cursor == ["perSystem"]`), the entire subtree has been assembled into a single composite function by the previous phases.
This final transformer acts as the gatekeeper to `flake-parts`. It wraps the composite function, ensuring the outer layer possesses the correct `builtins.functionArgs` metadata. When `flake-parts` eventually calls this master function with per-system arguments, the master function traverses the tree, evaluates every leaf with those arguments, and returns the final evaluated attribute set to the module system.
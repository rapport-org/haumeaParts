# everything outside <src>/perSystem/ goes to haumea's own scoped loader
{ defaultLoader, haumeaStub, fixturesDir, haumeaInputs, fn-leaf-path }:
defaultLoader { src = fixturesDir; haumea = haumeaStub; } haumeaInputs fn-leaf-path == "haumea-loaded"

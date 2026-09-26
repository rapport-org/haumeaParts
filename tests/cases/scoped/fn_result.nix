# calling the loaded function with perSystem args evaluates the file body
{ fn-leaf, perSystem }:
fn-leaf perSystem == "pkgs-hello"

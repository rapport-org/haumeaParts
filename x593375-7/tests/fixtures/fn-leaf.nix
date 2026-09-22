# A file that returns a function, simulating a typical perSystem package file.
# Its functionArgs ({ pkgs = false }) must be preserved by the scoped loader.
{ pkgs, ... }: pkgs.hello

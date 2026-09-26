# no default key: mod returned unchanged
{ lifted }:
lifted { foo = "a"; bar = "b"; } == { foo = "a"; bar = "b"; }

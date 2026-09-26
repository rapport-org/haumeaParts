# plain-value default with no siblings: returned directly, not wrapped
{ lifted }:
lifted { default = "just-a-string"; } == "just-a-string"

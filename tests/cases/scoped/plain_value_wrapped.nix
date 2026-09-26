# plain values are wrapped as `_: content` so lazyWrap can call every leaf uniformly
{ plain-leaf, perSystem }:
builtins.isFunction plain-leaf
&& plain-leaf perSystem == "plain-value"

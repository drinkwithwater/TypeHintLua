# Lua 5.4 public headers

LPeg needs only `lua.h`, `lauxlib.h`, and `luaconf.h` to compile against the
Lua 5.4 C ABI. The interpreter itself is provided by mlua's `vendored` feature;
there is no separate Lua source checkout or submodule to initialize.

These unmodified headers are from Lua 5.4.4, commit
`5d708c3f9cae12820e415d4f89c9eacbe2ab964b` of
<https://github.com/lua/lua>, previously checked out in `3rd/lua`.
The full Lua license and copyright notice are preserved at the end of `lua.h`.
Keep the numeric types and other ABI settings consistent with mlua's Lua 5.4
build when updating these headers or changing interpreter features.

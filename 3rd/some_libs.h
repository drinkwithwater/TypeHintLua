
#ifndef lua_with_libs_h
#define lua_with_libs_h

#include "lauxlib.h"
#include "lualib.h"
int luaopen_lpeg (lua_State *L);
int luaopen_rapidjson(lua_State* L);
int luaopen_path(lua_State* L);
int luaopen_path_fs(lua_State* L);
int luaopen_chrono(lua_State* L);

#endif

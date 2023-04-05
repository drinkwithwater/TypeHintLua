
#ifndef lua_with_libs_h
#define lua_with_libs_h

#include "lauxlib.h"
#include "lualib.h"
int luaopen_lpeg (lua_State *L);
int luaopen_rapidjson(lua_State* L);

#endif


#include <chrono>
#include <cstring>
#include <iostream>

#include "lua.hpp"

const char CHRONO[] = "chrono";

static int chrono_now(lua_State* L)
{
	auto cur = std::chrono::high_resolution_clock::now();
	void * ptr = lua_newuserdatauv(L, sizeof(cur), 0);
	std::memcpy(ptr, &cur, sizeof(cur));
	luaL_setmetatable(L, CHRONO);
	return 1;
}

static int chrono_sub(lua_State* L)
{
	using T = std::chrono::time_point<std::chrono::high_resolution_clock>;
	auto t1 = (T*)luaL_checkudata(L, 1, CHRONO);
	auto t2 = (T*)luaL_checkudata(L, 2, CHRONO);
	long long microseconds = std::chrono::duration_cast<std::chrono::microseconds>(*t1-*t2).count();
	lua_pushinteger(L, microseconds);
	return 1;
}

static const luaL_Reg methods[] = {
	// string <--> json
	{ "now", chrono_now },
	{ "sub", chrono_sub },

	{ NULL, NULL }
};

extern "C" {

	LUALIB_API int luaopen_chrono(lua_State* L)
	{

		luaL_newmetatable(L, CHRONO);
		lua_pushcfunction(L, chrono_sub);
		lua_setfield(L, -2, "__sub");
		lua_pop(L, 1);

		lua_newtable(L); // [rapidjson]

		luaL_setfuncs(L, methods, 0);

		return 1;
	}

}

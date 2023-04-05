
#include "lua.hpp"
extern "C" {
#include "some_libs.h"
}

#include <iostream>
#include <string>
#include <emscripten/bind.h>

using namespace emscripten;


class CallInstance {
	lua_State *pState;
	int dispatchIndex;
public:
	CallInstance(std::string vInitScript) {
		dispatchIndex = 0;
		pState = luaL_newstate();  /* create state */
		luaL_openlibs(pState);  /* open standard libraries */
		lua_gc(pState, LUA_GCGEN, 0, 0);  /* GC in generational mode */
		// add preload lpeg & rapidjson
	  lua_getfield(pState, LUA_REGISTRYINDEX, LUA_PRELOAD_TABLE);
	  lua_pushcfunction(pState, &luaopen_lpeg);
	  lua_setfield(pState, -2, "lpeg");
	  lua_pushcfunction(pState, &luaopen_rapidjson);
	  lua_setfield(pState, -2, "rapidjson");
	  lua_pop(pState, 1);
	  // init
	  this->init(vInitScript);
	}

	void init(std::string vInitScript) {
		auto compile_result = luaL_loadbuffer(pState, vInitScript.c_str(), vInitScript.size(), "@init.lua");
		if(compile_result != LUA_OK) {
			printf("compile fail%s\n", lua_tostring(pState, -1));
			return ;
		}
		auto init_result = lua_pcall(pState, 0, 1, lua_gettop(pState));
		if(init_result != LUA_OK) {
			printf("init fail%s\n", lua_tostring(pState, -1));
			return ;
		}
		if(lua_type(pState, lua_gettop(pState)) != LUA_TFUNCTION) {
			printf("init script return function\n");
			return ;
		}
		dispatchIndex = lua_gettop(pState);
	}

	std::string call(std::string methodName, std::string params) {
		if(dispatchIndex==0) {
			throw std::runtime_error(std::string("instance init fail, can't use call"));
		}
		lua_pushvalue(pState, dispatchIndex);
		lua_pushlstring(pState, methodName.c_str(), methodName.size());
		lua_pushlstring(pState, params.c_str(), params.size());
		lua_pcall(pState, 2, 1, lua_gettop(pState));
		if(lua_type(pState, lua_gettop(pState)) != LUA_TSTRING) {
			lua_pop(pState, 1);
			return "";
		} else {
			size_t retLen = 0;
			const char *retPtr = luaL_tolstring(pState, -1, &retLen);
			std::string ret(retPtr, retLen);
			lua_pop(pState, 1);
			return ret;
		}
	}

	~CallInstance(){
		lua_close(pState);
	}

};

// Binding code
EMSCRIPTEN_BINDINGS(my_class_example) {
  class_<CallInstance>("CallInstance")
    .constructor<std::string>()
    .function("call", &CallInstance::call)
    ;
}

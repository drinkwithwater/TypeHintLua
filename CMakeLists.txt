cmake_minimum_required(VERSION 2.8)

if ( WIN32 AND NOT CYGWIN AND NOT ( CMAKE_SYSTEM_NAME STREQUAL "WindowsStore" ) AND NOT ANDROID)
	set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} /MT" CACHE STRING "")
	set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} /MTd" CACHE STRING "")
	set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /MT" CACHE STRING "")
	set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} /MTd" CACHE STRING "")
endif ()

if ( WASM )
	set(CMAKE_C_COMPILER "emcc")
	set(CMAKE_CXX_COMPILER "emcc")
endif()

project(TypeHintLua)

set(LUA_SRC_PATH 3rd/lua)

#begin lua-rapidjson
set (RAPIDJSON_SRC
	3rd/lua-rapidjson/source/rapidjson.cpp
	3rd/xlua/i64lib.c
)
list(APPEND THIRDPART_INC 3rd/lua-rapidjson/include 3rd/xlua)
set (THIRDPART_SRC ${THIRDPART_SRC} ${RAPIDJSON_SRC})
#end lua-rapidjson

#begin lpeg
set ( LPEG_SRC
    3rd/lpeg/lpcap.c
    3rd/lpeg/lpcode.c
    3rd/lpeg/lpprint.c
    3rd/lpeg/lptree.c
    3rd/lpeg/lpvm.c
)
set (THIRDPART_SRC ${THIRDPART_SRC} ${LPEG_SRC})
#end lpeg

#begin lpath
set ( LPATH_SRC
    3rd/lpath/lpath.c
)
set (THIRDPART_SRC ${THIRDPART_SRC} ${LPATH_SRC})
#end lpath

#begin chrono
set (THIRDPART_SRC ${THIRDPART_SRC} 3rd/lua-chrono.cpp)
#end chrono

if (NOT WASM)
#begin luv
  #begin libuv
  include_directories(3rd/luv/deps/libuv/include)
  add_subdirectory(3rd/luv/deps/libuv EXCLUDE_FROM_ALL)
  add_definitions( -DBUILDING_UV_SHARED )
  set(LIBUV_LIBRARIES uv_a)
  set_target_properties(uv_a PROPERTIES COMPILE_FLAGS "-fPIC")
  #end libuv
include_directories(3rd/luv/src)
set (THIRDPART_SRC ${THIRDPART_SRC} 3rd/luv/src/luv.c)
#end luv
endif()



set (LUA_HPP 3rd)
include_directories(
	${LUA_HPP}
	${CMAKE_SOURCE_DIR}
	${LUA_SRC_PATH}
	${CMAKE_CURRENT_BINARY_DIR}
	${THIRDPART_INC}
)

aux_source_directory(${LUA_SRC_PATH} LUA_CORE)
list(REMOVE_ITEM LUA_CORE ${LUA_SRC_PATH}/luac.c ${LUA_SRC_PATH}/onelua.c ${LUA_SRC_PATH}/lua.c)

if (NOT WASM)
	add_executable(lua
		3rd/lua_with_libs.c
		${LUA_CORE}
		${THIRDPART_SRC}
	)

	if ( WIN32 AND NOT CYGWIN )
		target_link_libraries(lua
			ws2_32
			${LIBUV_LIBRARIES}
		)
	else ( )
		target_link_libraries(lua
			m
			${LIBUV_LIBRARIES}
		)
	endif ( )
endif()

if ( WASM )
	add_executable(lua.js
		3rd/lua_wasm.cpp
		${LUA_CORE}
		${THIRDPART_SRC}
	)
	target_link_libraries(lua.js
		embind
		${THIRDPART_LIB}
	)
endif()

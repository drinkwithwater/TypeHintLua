use std::env;

fn main() {
    let target = env::var("TARGET").unwrap();

    let artifacts = lua_src::Build::new().build(lua_src::Lua54);

    let include_path = artifacts.include_dir();

    // --- 添加c实现的库 ---

    let mut build3rdc = cc::Build::new();
    build3rdc.cpp(false);
    build3rdc.include(include_path);
    build3rdc.include("3rd");

    // LPeg
    build3rdc.files([
        "3rd/lpeg/lpcap.c",
        "3rd/lpeg/lpcode.c",
        "3rd/lpeg/lpprint.c",
        "3rd/lpeg/lptree.c",
        "3rd/lpeg/lpvm.c",
    ]);

    // lpath
    build3rdc.file("3rd/lpath/lpath.c");

    // luv
    if !target.contains("wasm32") {
        build3rdc.include("3rd/luv/deps/libuv/include");
        build3rdc.include("3rd/luv/src");
        build3rdc.file("3rd/luv/src/luv.c");

        let dst = cmake::Config::new("3rd/luv/deps/libuv")
            .profile("Release")
            .build();
        //println!("cargo:warning=这是dst.display : {}/lib", dst.display());
        // Tell cargo to link the library
        println!("cargo:rustc-link-search=native={}/lib", dst.display());
        if target.contains("windows") {
            println!("cargo:rustc-link-lib=static=libuv");
        } else if !target.contains("wasm32") {
            println!("cargo:rustc-link-lib=static=uv");
        }
    }

    build3rdc.compile("lua3rdc");

    // --- 添加cpp实现的库 ---

    let mut build3rdpp = cc::Build::new();
    build3rdpp.cpp(true);
    build3rdpp.include(include_path);
    build3rdpp.include("3rd");
    build3rdpp.include("3rd/lua-rapidjson/include");


    // RapidJSON & i64lib
    build3rdpp.file("3rd/lua-rapidjson/source/rapidjson.cpp");

    // Chrono
    build3rdpp.file("3rd/lua-chrono.cpp");

    build3rdpp.compile("lua3rdcpp");

    // --- WASM TODO ---
    if target.contains("wasm32") {
        println!("cargo:warning=wasmTODO");
    }

    // 重新编译触发条件
    println!("cargo:rerun-if-changed=3rd/");
    println!("cargo:rerun-if-changed=build.rs");

    /* 链接系统库 (对应 CMake 的 target_link_libraries)
    if target.contains("windows") {
        //println!("cargo:rustc-link-lib=ws2_32");
    } else if !target.contains("wasm32") {
        //println!("cargo:rustc-link-lib=m");
        //println!("cargo:rustc-link-lib=dl");
    }*/
}

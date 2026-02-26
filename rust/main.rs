use mlua::prelude::*;
use std::os::raw::c_int;
use mlua::{Lua, Result, MultiValue};
use rustyline::DefaultEditor;
use std::collections::HashMap;
use std::collections::HashSet;
use std::env;
use std::fs;
use std::path::Path;

#[link(name = "lua3rdcpp")]
extern "C-unwind" {
    fn luaopen_chrono(L: *mut mlua::lua_State) -> c_int;
    fn luaopen_rapidjson(L: *mut mlua::lua_State) -> c_int;
}

#[link(name = "lua3rdc")]
extern "C-unwind" {
    fn luaopen_luv(L: *mut mlua::lua_State) -> c_int;
    fn luaopen_lpeg(L: *mut mlua::lua_State) -> c_int;
    fn luaopen_path(L: *mut mlua::lua_State) -> c_int;
    fn luaopen_path_fs(L: *mut mlua::lua_State) -> c_int;
}

/// 执行指定的 Lua 脚本文件
fn run_file(lua: &Lua, path: &str, args: &[String]) -> Result<()> {
    let script = fs::read_to_string(path).expect("无法读取文件");

    // 设置全局变量 arg，模拟 lua.exe 的行为
    let arg_table = lua.create_table()?;
    for (i, arg) in args.iter().enumerate() {
        arg_table.set(i + 1, arg.as_str())?;
    }
    lua.globals().set("arg", arg_table)?;

    // 加载并运行脚本
    let path = Path::new(path);
    lua.load(&script)
        .set_name(path.to_str().unwrap())
        .exec()?;

    Ok(())
}

/// 交互式 REPL 实现
fn run_repl(lua: &Lua) -> Result<()> {
    println!("Lua 5.4.x (Rust mlua REPL)");
    println!("输入 'quit()' 或按 Ctrl-C 退出");

    let mut rl = DefaultEditor::new().expect("无法初始化 Readline");

    loop {
        // 读取输入
        let readline = rl.readline(">> ");
        match readline {
            Ok(line) => {
                if line.trim() == "quit()" { break; }
                if line.trim().is_empty() { continue; }

                // 将输入添加到历史记录
                let _ = rl.add_history_entry(line.as_str());

                // 尝试执行。先尝试作为表达式运行（方便直接打印结果），失败后再作为代码块运行
                // 例如输入 1+1，会尝试 return 1+1
                let eval_line = format!("return {}", line);
                let result = lua.load(&eval_line).eval::<MultiValue>();

                match result {
                    Ok(values) => {
                        // 如果 eval 成功，打印返回值
                        if !values.is_empty() {
                            println!("{}", values.iter()
                                .map(|v| format!("{:?}", v))
                                .collect::<Vec<_>>()
                                .join("\t"));
                        }
                    }
                    Err(_) => {
                        // 如果作为表达式失败，尝试作为普通语句执行
                        if let Err(e) = lua.load(&line).exec() {
                            eprintln!("错误: {}", e);
                        }
                    }
                }
            }
            Err(_) => break, // 捕获 Ctrl-C 或 Ctrl-D
        }
    }
    Ok(())
}

fn main() -> Result<()> {
    // 1. 初始化 Lua 虚拟机
    let lua = Lua::new();

    // 手动注册到 package.preload
    // 在 Lua 中这相当于：package.preload[name] = loader
    let package: LuaTable = lua.globals().get("package")?;
    let preload: LuaTable = package.get("preload")?;
    let mut register = |name: &str, func| -> mlua::Result<()> {
        let loader = unsafe { lua.create_c_function(func)? };
        preload.set(name, loader)
    };

    register("chrono", luaopen_chrono)?;
    register("rapidjson", luaopen_rapidjson)?;
    register("lpeg", luaopen_lpeg)?;
    register("path", luaopen_path)?;
    register("path.fs", luaopen_path_fs)?;
    register("luv", luaopen_luv)?;

    // 获取命令行参数
    let args: Vec<String> = env::args().collect();

    if args.len() > 1 {
        // 2. 如果有参数，执行脚本文件
        run_file(&lua, &args[1], &args[2..])
    } else {
        // 3. 如果没有参数，进入交互模式 (REPL)
        run_repl(&lua)
    }
}

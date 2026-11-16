use crate::host::{self, Scheduler};
use mlua::{Error, Function, Lua, LuaSerdeExt, Result, StdLib, Table, Value};
use std::fs;

include!(concat!(env!("OUT_DIR"), "/sources.rs"));

unsafe extern "C-unwind" {
    fn luaopen_lpeg(state: *mut mlua::lua_State) -> std::os::raw::c_int;
}

pub struct Runtime {
    pub lua: Lua,
    pub scheduler: Scheduler,
}

impl Runtime {
    pub fn new() -> Result<Self> {
        // The checker uses debug.getinfo/sethook and standard Lua module loading.
        // Embedded compiler scripts are trusted and require the full library set.
        let lua = unsafe { Lua::unsafe_new_with(StdLib::ALL, Default::default()) };
        let package: Table = lua.globals().get("package")?;
        let preload: Table = package.get("preload")?;
        preload.set("lpeg", unsafe { lua.create_c_function(luaopen_lpeg)? })?;
        let scheduler = host::install(&lua)?;
        // Load the bootstrap compiler first. It is plain Lua and needs only LPeg.
        let parser: Table = lua
            .load(include_str!("../thlua/code/ParseEnv.lua"))
            .set_name("@embedded/thlua/code/ParseEnv.lua")
            .eval()?;
        package
            .get::<Table>("loaded")?
            .set("thlua.code.ParseEnv", parser.clone())?;
        let compile: Function = parser.get("compile")?;
        for &(name, path, source) in SOURCES {
            if matches!(
                name,
                "thlua.code.ParseEnv" | "thlua.server.json" | "thlua.server.stdio"
            ) {
                continue;
            }
            let compile = compile.clone();
            preload.set(
                name,
                lua.create_function(move |lua, module: String| {
                    let code = if path.ends_with(".thlua") {
                        let (code, error): (Option<String>, Option<String>) =
                            compile.call((source, path))?;
                        code.ok_or_else(|| {
                            Error::runtime(
                                error.unwrap_or_else(|| format!("cannot compile {path}")),
                            )
                        })?
                    } else {
                        source.to_owned()
                    };
                    lua.load(&code)
                        .set_name(format!("@embedded/{path}"))
                        .call::<Value>(module)
                })?,
            )?;
        }
        // Enable user modules without a system Lua installation or LUA_PATH.
        let old_path: String = package.get("path")?;
        package.set("path", format!("./?.lua;./?/init.lua;{old_path}"))?;
        parser.get::<Function>("patch")?.call::<()>(())?;
        Ok(Self { lua, scheduler })
    }

    pub fn compile(&self, source: &str, name: &str) -> Result<String> {
        let parser: Table = self.require("thlua.code.ParseEnv")?;
        let (code, err): (Option<String>, Option<String>) =
            parser.get::<Function>("compile")?.call((source, name))?;
        code.ok_or_else(|| Error::runtime(err.unwrap_or_else(|| "compilation failed".into())))
    }

    pub fn require(&self, name: &str) -> Result<Table> {
        self.lua.globals().get::<Function>("require")?.call(name)
    }

    pub fn check(&self, file: &str, json: bool) -> Result<u8> {
        // Keep diagnostic construction in Lua where node and severity data live.
        let diagnostics: Table = self.lua.load(include_str!("check.lua")).call(file)?;
        self.scheduler.drain()?;
        if !diagnostics.get::<bool>("done")? {
            return Err(Error::runtime("type checker did not finish"));
        }
        if let Some(error) = diagnostics.get::<Option<String>>("error")? {
            return Err(Error::runtime(error));
        }
        let items: Table = diagnostics.get("items")?;
        let items: Vec<serde_json::Value> = self.lua.from_value(Value::Table(items))?;
        let failed = items.iter().any(|item| item["severity"] == 1);
        if json {
            println!(
                "{}",
                serde_json::to_string_pretty(&items).map_err(Error::external)?
            );
        } else {
            for item in &items {
                let severity = match item["severity"].as_i64() {
                    Some(1) => "error",
                    Some(2) => "warning",
                    Some(3) => "info",
                    _ => "hint",
                };
                println!(
                    "{}:{}:{}: {}: {}",
                    item["file"].as_str().unwrap_or(file),
                    item["line"],
                    item["column"],
                    severity,
                    item["message"].as_str().unwrap_or("")
                );
            }
        }
        Ok(u8::from(failed))
    }

    pub fn run(&self, file: &str, args: &[String]) -> Result<()> {
        let arg = self.lua.create_table()?;
        arg.set(0, file)?;
        for (i, value) in args.iter().enumerate() {
            arg.set(i + 1, value.as_str())?;
        }
        self.lua.globals().set("arg", arg)?;
        let source = fs::read_to_string(file).map_err(Error::external)?;
        let code = self.compile(&source, file)?;
        self.lua.load(&code).set_name(format!("@{file}")).exec()?;
        self.scheduler.drain()
    }
}

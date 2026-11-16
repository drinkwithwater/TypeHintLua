use mlua::{Error, Function, Lua, LuaSerdeExt, Result, Table, Value, Variadic};
use std::{
    cell::RefCell,
    collections::VecDeque,
    io::{self, Write},
    path::{Component, Path, PathBuf},
    rc::Rc,
    time::Instant,
};

#[derive(Clone, Default)]
pub struct Scheduler(Rc<RefCell<VecDeque<Function>>>);

impl Scheduler {
    pub fn tick(&self) -> Result<bool> {
        // Release the borrow before calling Lua: callbacks can enqueue more work.
        let callback = self.0.borrow_mut().pop_front();
        if let Some(callback) = callback {
            callback.call::<()>(())?;
            return Ok(true);
        }
        Ok(false)
    }
    pub fn drain(&self) -> Result<()> {
        while self.tick()? {}
        Ok(())
    }
    pub fn pending(&self) -> bool {
        !self.0.borrow().is_empty()
    }
}

pub fn preload(lua: &Lua, name: &str, module: Table) -> Result<()> {
    let package: Table = lua.globals().get("package")?;
    package.get::<Table>("preload")?.set(
        name,
        lua.create_function(move |_, _: Value| Ok(module.clone()))?,
    )
}

fn absolute(parts: Variadic<String>) -> Result<PathBuf> {
    let mut path = std::env::current_dir().map_err(Error::external)?;
    for part in parts {
        path.push(part);
    }
    let mut normalized = PathBuf::new();
    for component in path.components() {
        match component {
            Component::CurDir => (),
            Component::ParentDir => {
                normalized.pop();
            }
            component => normalized.push(component),
        }
    }
    Ok(normalized)
}

pub fn install(lua: &Lua) -> Result<Scheduler> {
    let scheduler = Scheduler::default();
    let queue = scheduler.clone();
    let enqueue = lua.create_function(move |_, callback: Function| {
        queue.0.borrow_mut().push_back(callback);
        Ok(())
    })?;
    // The compatibility surface is deliberately limited to the async handles
    // used by the checker. Transport is owned by Rust, not emulated libuv pipes.
    let uv: Table = lua
        .load(
            r#"
        local enqueue = ...
        local uv = {}
        function uv.new_async(callback)
            local closing, pending = false, false
            local handle = {}
            function handle:is_closing() return closing end
            function handle:send()
                if closing or pending then return end
                pending = true
                enqueue(function()
                    pending = false
                    if not closing then callback() end
                end)
            end
            function handle:close(callback)
                if closing then return end
                closing = true
                if callback then enqueue(callback) end
            end
            return handle
        end
        uv.async_send = function(handle) handle:send() end
        uv.close = function(handle, callback) handle:close(callback) end
        uv.is_closing = function(handle) return handle:is_closing() end
        return uv
    "#,
        )
        .call(enqueue)?;
    let queue = scheduler.clone();
    uv.set("run", lua.create_function(move |_, ()| queue.drain())?)?;
    preload(lua, "luv", uv)?;

    let path = lua.create_table()?;
    path.set(
        "cwd",
        lua.create_function(|_, ()| {
            Ok(std::env::current_dir()
                .map_err(Error::external)?
                .to_string_lossy()
                .into_owned())
        })?,
    )?;
    path.set(
        "abs",
        lua.create_function(|_, parts: Variadic<String>| {
            Ok(absolute(parts)?.to_string_lossy().into_owned())
        })?,
    )?;
    path.set(
        "isfile",
        lua.create_function(|lua, parts: Variadic<String>| {
            let path = absolute(parts)?;
            if path.is_file() {
                Ok(Value::String(
                    lua.create_string(path.to_string_lossy().as_bytes())?,
                ))
            } else {
                Ok(Value::Boolean(false))
            }
        })?,
    )?;
    path.set(
        "name",
        lua.create_function(|_, path: String| {
            Ok(Path::new(&path)
                .file_name()
                .unwrap_or_default()
                .to_string_lossy()
                .into_owned())
        })?,
    )?;
    preload(lua, "path", path)?;

    let chrono = lua.create_table()?;
    let start = Instant::now();
    chrono.set(
        "now",
        lua.create_function(move |_, ()| {
            Ok(start.elapsed().as_micros().min(i64::MAX as u128) as i64)
        })?,
    )?;
    chrono.set(
        "sub",
        lua.create_function(|_, (a, b): (i64, i64)| Ok(a - b))?,
    )?;
    preload(lua, "chrono", chrono)?;

    let json = lua.create_table()?;
    json.set("null", lua.null())?;
    json.set(
        "decode",
        lua.create_function(|lua, source: String| {
            match serde_json::from_str::<serde_json::Value>(&source) {
                Ok(value) => Ok((lua.to_value(&value)?, None::<String>)),
                Err(err) => Ok((Value::Nil, Some(err.to_string()))),
            }
        })?,
    )?;
    json.set(
        "encode",
        lua.create_function(|lua, value: Value| {
            let value: serde_json::Value = lua.from_value(value)?;
            serde_json::to_string(&value).map_err(Error::external)
        })?,
    )?;
    json.set(
        "array",
        lua.create_function(|lua, table: Option<Table>| {
            let table = match table {
                Some(table) => table,
                None => lua.create_table()?,
            };
            table.set_metatable(Some(lua.array_metatable()))?;
            Ok(table)
        })?,
    )?;
    preload(lua, "rapidjson", json.clone())?;
    preload(lua, "thlua.server.json", json)?;

    let stdio = lua.create_table()?;
    stdio.set(
        "writeout",
        lua.create_function(|_, data: mlua::String| {
            let mut out = io::stdout().lock();
            out.write_all(&data.as_bytes())
                .and_then(|_| out.flush())
                .map_err(Error::external)
        })?,
    )?;
    let writeerr = lua.create_function(|_, data: mlua::String| {
        let mut out = io::stderr().lock();
        out.write_all(&data.as_bytes())
            .and_then(|_| out.flush())
            .map_err(Error::external)
    })?;
    stdio.set("writeerr", writeerr)?;
    preload(lua, "thlua.server.stdio", stdio)?;
    Ok(scheduler)
}

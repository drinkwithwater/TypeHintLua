use crate::runtime::Runtime;
use mlua::{Error, Function, LuaSerdeExt, Result, SerializeOptions, Table};
use serde_json::{json, Value};
use std::{
    io::{self, BufRead, Read, Write},
    sync::mpsc,
};

const MAX_HEADER: usize = 16 * 1024;
const MAX_BODY: usize = 16 * 1024 * 1024;

fn read_frame(reader: &mut impl BufRead) -> io::Result<Option<serde_json::Result<Value>>> {
    let invalid = |message| io::Error::new(io::ErrorKind::InvalidData, message);
    let mut content_length = None;
    let mut header_bytes = 0;
    loop {
        let mut line = Vec::new();
        let n = reader
            .take((MAX_HEADER + 1 - header_bytes) as u64)
            .read_until(b'\n', &mut line)?;
        if n == 0 {
            if header_bytes == 0 {
                return Ok(None);
            }
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "incomplete LSP header",
            ));
        }
        header_bytes += n;
        if header_bytes > MAX_HEADER {
            return Err(invalid("LSP header too large"));
        }
        let line = std::str::from_utf8(&line)
            .map_err(|_| invalid("invalid LSP header"))?
            .trim();
        if line.is_empty() {
            break;
        }
        let (name, value) = line
            .split_once(':')
            .ok_or_else(|| invalid("invalid LSP header"))?;
        if name.eq_ignore_ascii_case("Content-Length") {
            if content_length.is_some() {
                return Err(invalid("duplicate Content-Length"));
            }
            let length: usize = value
                .trim()
                .parse()
                .map_err(|_| invalid("invalid Content-Length"))?;
            if length > MAX_BODY {
                return Err(invalid("LSP message too large"));
            }
            content_length = Some(length);
        }
    }
    let length = content_length.ok_or_else(|| invalid("missing Content-Length"))?;
    let mut body = vec![0; length];
    reader.read_exact(&mut body)?;
    // A malformed JSON body is a JSON-RPC parse error; framing remains usable.
    Ok(Some(serde_json::from_slice(&body)))
}

fn write_packet(packet: Value) -> Result<()> {
    let data = serde_json::to_vec(&packet).map_err(Error::external)?;
    let mut stdout = io::stdout().lock();
    write!(stdout, "Content-Length: {}\r\n\r\n", data.len()).map_err(Error::external)?;
    stdout
        .write_all(&data)
        .and_then(|_| stdout.flush())
        .map_err(Error::external)
}

fn rpc_error(id: Value, code: i32, message: &str) -> Result<()> {
    write_packet(json!({"jsonrpc":"2.0", "id":id, "error":{"code":code, "message":message}}))
}

pub fn serve(runtime: Runtime, global: Option<&str>) -> Result<u8> {
    let lua = &runtime.lua;
    // User hint code may print before initialize. stdout is always protocol-only.
    lua.load("print = function(...) local t = {}; for i=1,select('#',...) do t[i]=tostring(select(i,...)) end; io.stderr:write(table.concat(t,'\\t'),'\\n') end").exec()?;
    let server: Table = lua.load(include_str!("lsp.lua")).call(global)?;
    let handlers: Table = server.get("_methodHandler")?;
    let (sender, receiver) = mpsc::sync_channel(16);
    // Read independently of Lua scheduling, so edits can cancel in-flight checks.
    // Never pass Lua values across threads. The bounded channel limits buffering.
    // No join on this thread: exit must work while the client still holds stdin.
    std::thread::Builder::new()
        .name("thlua-stdin".into())
        .spawn(move || {
            let stdin = io::stdin();
            let mut reader = stdin.lock();
            loop {
                let frame = read_frame(&mut reader);
                let finished = !matches!(&frame, Ok(Some(_)));
                if sender.send(frame).is_err() || finished {
                    break;
                }
            }
        })
        .map_err(Error::external)?;
    let mut shutdown = false;
    loop {
        let incoming = if !shutdown && runtime.scheduler.pending() {
            match receiver.try_recv() {
                Ok(frame) => Some(frame),
                Err(mpsc::TryRecvError::Empty) => None,
                Err(mpsc::TryRecvError::Disconnected) => return Ok(0),
            }
        } else {
            Some(receiver.recv().map_err(Error::external)?)
        };
        if let Some(frame) = incoming {
            let Some(packet) = frame.map_err(Error::external)? else {
                return Ok(0);
            };
            let packet = match packet {
                Ok(packet) => packet,
                Err(_) => {
                    rpc_error(Value::Null, -32700, "Parse error")?;
                    continue;
                }
            };
            let method = packet.get("method").and_then(Value::as_str);
            let id = packet.get("id").cloned();
            if packet.get("jsonrpc").and_then(Value::as_str) != Some("2.0")
                || !packet.is_object()
                || id
                    .as_ref()
                    .is_some_and(|id| !id.is_null() && !id.is_string() && !id.is_i64())
                || packet
                    .get("method")
                    .is_some_and(|method| !method.is_string())
                || (method.is_none()
                    && packet.get("result").is_none()
                    && packet.get("error").is_none())
            {
                rpc_error(Value::Null, -32600, "Invalid Request")?;
                continue;
            }
            match method {
                Some("exit") => return Ok(if shutdown { 0 } else { 1 }),
                Some(_) if !server.get::<bool>("initialize")? && method != Some("initialize") => {
                    if let Some(id) = id {
                        rpc_error(id, -32002, "Server not initialized")?;
                    }
                }
                Some("shutdown") => {
                    if let Some(id) = id {
                        shutdown = true;
                        server.set("shutdown", true)?;
                        write_packet(json!({"jsonrpc":"2.0", "id":id, "result":null}))?;
                    }
                }
                Some(_) if shutdown => {
                    if let Some(id) = id {
                        rpc_error(id, -32600, "Server has shut down")?;
                    }
                }
                Some("initialize") if server.get::<bool>("initialize")? => {
                    if let Some(id) = id {
                        rpc_error(id, -32600, "Server already initialized")?;
                    }
                }
                Some("initialized" | "$/cancelRequest" | "$/setTrace") => (),
                Some(method) => {
                    let Some(handler) = handlers.get::<Option<Table>>(method)? else {
                        if let Some(id) = id {
                            rpc_error(id, -32601, "Method not found")?;
                        }
                        continue;
                    };
                    let params = packet.get("params").unwrap_or(&Value::Null);
                    if !params.is_null() && !params.is_object() {
                        if let Some(id) = id {
                            rpc_error(id, -32602, "Invalid params")?;
                        }
                        continue;
                    }
                    let options = SerializeOptions::new()
                        .serialize_unit_to_null(false)
                        .serialize_none_to_null(false);
                    let params = lua.to_value_with(params, options)?;
                    let result = handler
                        .get::<Function>("call")?
                        .call::<mlua::Value>(params)
                        .and_then(|result| {
                            if matches!(
                                method,
                                "textDocument/completion"
                                    | "textDocument/definition"
                                    | "textDocument/typeDefinition"
                                    | "textDocument/references"
                            ) {
                                if let mlua::Value::Table(table) = &result {
                                    table.set_metatable(Some(lua.array_metatable()))?;
                                }
                            }
                            lua.from_value::<Value>(result)
                        });
                    match result {
                        Ok(result) => {
                            if let Some(id) = id {
                                write_packet(json!({"jsonrpc":"2.0", "id":id, "result":result}))?;
                            }
                        }
                        Err(error) => {
                            if method == "initialize" {
                                server.set("initialize", false)?;
                            }
                            if let Some(id) = id {
                                rpc_error(id, -32603, &error.to_string())?;
                            } else {
                                eprintln!("thlua: {method}: {error}");
                            }
                        }
                    }
                }
                None => (), // Responses to server-initiated requests.
            }
        }
        if !shutdown {
            runtime.scheduler.tick()?;
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Cursor;

    #[test]
    fn framing_supports_utf8_extra_headers_and_multiple_messages() {
        let body = r#"{"jsonrpc":"2.0","method":"中文"}"#;
        let frame = format!("content-length: {}\r\nContent-Type: application/vscode-jsonrpc; charset=utf-8\r\n\r\n{}", body.len(), body);
        let mut input = Cursor::new(format!("{frame}{frame}"));
        assert_eq!(
            read_frame(&mut input).unwrap().unwrap().unwrap()["method"],
            "中文"
        );
        assert!(read_frame(&mut input).unwrap().is_some());
        assert!(read_frame(&mut input).unwrap().is_none());
    }

    #[test]
    fn rejects_invalid_truncated_and_oversized_frames() {
        for input in [
            "Content-Length: 3\r\nContent-Length: 3\r\n\r\n{} ".into(),
            "Content-Length: -1\r\n\r\n".into(),
            "Content-Type: x\r\n\r\n".into(),
            "Content-Length: 5\r\n\r\n{}".into(),
            format!("Content-Length: {}\r\n\r\n", MAX_BODY + 1),
            "x".repeat(MAX_HEADER + 1),
        ] {
            assert!(read_frame(&mut Cursor::new(input)).is_err());
        }
    }
}

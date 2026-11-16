mod host;
mod lsp;
mod runtime;

use mlua::{Error, Result};
use std::{
    env, fs,
    io::{self, Write},
    path::PathBuf,
    process::ExitCode,
};

const HELP: &str = "TypeHintLua\n\nUsage:\n  thlua compile <file.thlua> [-o <file.lua>]\n  thlua check [file.thlua | --project <directory>] [--json]\n  thlua lsp [--stdio] [--global <directory>]\n  thlua run <file.thlua> [args...]\n\nAliases: thc = compile, the = check, thls = lsp\nCheck defaults to ./throot.thlua. Compilation writes to stdout unless -o is set.\nExit codes: 0 success, 1 diagnostics/runtime error, 2 invalid command or I/O failure.\n";

fn argument_error(message: &str) -> Result<u8> {
    eprintln!("thlua: {message}\nRun 'thlua --help' for usage.");
    Ok(2)
}

fn execute(args: Vec<String>) -> Result<u8> {
    let Some(command) = args.first().map(String::as_str) else {
        print!("{HELP}");
        return Ok(0);
    };
    if matches!(command, "--help" | "-h" | "help") {
        print!("{HELP}");
        return Ok(0);
    }
    if matches!(command, "--version" | "-V") {
        println!("thlua {}", env!("CARGO_PKG_VERSION"));
        return Ok(0);
    }
    let rest = &args[1..];
    match command {
        "compile" | "thc" => {
            let (input, output) = match rest {
                [input] if !input.starts_with('-') => (input, None),
                [input, option, output]
                    if !input.starts_with('-') && matches!(option.as_str(), "-o" | "--out") =>
                {
                    (input, Some(output))
                }
                _ => return argument_error("expected compile <file> [-o <output>]"),
            };
            if let Some(output) = output {
                let input_path = std::path::absolute(input).map_err(Error::external)?;
                let output_path = std::path::absolute(output).map_err(Error::external)?;
                if input_path == output_path
                    || (fs::canonicalize(input)
                        .ok()
                        .is_some_and(|p| Some(p) == fs::canonicalize(output).ok()))
                {
                    return argument_error("output must differ from input");
                }
            }
            let runtime = runtime::Runtime::new()?;
            let source = fs::read_to_string(input).map_err(Error::external)?;
            let code = runtime.compile(&source, input)?;
            if let Some(output) = output {
                fs::write(output, code).map_err(Error::external)?;
            } else {
                io::stdout()
                    .lock()
                    .write_all(code.as_bytes())
                    .map_err(Error::external)?;
            }
            Ok(0)
        }
        "check" | "the" => {
            let mut file = None;
            let mut json = false;
            let mut project = None;
            let mut iter = rest.iter();
            while let Some(arg) = iter.next() {
                match arg.as_str() {
                    "--json" => json = true,
                    "--project" | "-p" if project.is_none() => {
                        let Some(value) = iter.next() else {
                            return argument_error("--project needs a directory");
                        };
                        project = Some(PathBuf::from(value));
                    }
                    value if !value.starts_with('-') && file.is_none() => {
                        file = Some(PathBuf::from(value))
                    }
                    _ => return argument_error("unexpected check argument"),
                }
            }
            if file.is_some() && project.is_some() {
                return argument_error("choose a file or --project");
            }
            if let Some(project) = project {
                env::set_current_dir(project).map_err(Error::external)?;
            }
            let file = file.unwrap_or_else(|| PathBuf::from("throot.thlua"));
            // Fail on missing/unreadable input before starting the checker.
            fs::read_to_string(&file).map_err(Error::external)?;
            runtime::Runtime::new()?.check(&file.to_string_lossy(), json)
        }
        "lsp" | "thls" => {
            let mut global = None;
            let mut iter = rest.iter();
            while let Some(arg) = iter.next() {
                match arg.as_str() {
                    "--stdio" => (),
                    "--global" if global.is_none() => {
                        let Some(value) = iter.next() else {
                            return argument_error("--global needs a directory");
                        };
                        global = Some(value.as_str());
                    }
                    _ => return argument_error("unexpected lsp argument"),
                }
            }
            lsp::serve(runtime::Runtime::new()?, global)
        }
        "run" => {
            let Some(input) = rest.first() else {
                return argument_error("run needs a file");
            };
            runtime::Runtime::new()?.run(input, &rest[1..])?;
            Ok(0)
        }
        _ => argument_error("unknown command"),
    }
}

fn main() -> ExitCode {
    // The self-hosted checker needs more than Windows' default 1 MiB stack.
    let result = std::thread::Builder::new()
        .name("thlua".into())
        .stack_size(16 * 1024 * 1024)
        .spawn(|| match execute(env::args().skip(1).collect()) {
            Ok(code) => code,
            Err(err) => {
                eprintln!("thlua: {err}");
                if matches!(err, Error::ExternalError(_)) {
                    2
                } else {
                    1
                }
            }
        })
        .expect("start thlua runtime")
        .join()
        .unwrap_or(1);
    ExitCode::from(result)
}

use std::{env, fs, path::Path};

// Embed the current self-hosted sources, rather than the prepacked thlua.lua.
fn collect(dir: &Path, modules: &mut Vec<(String, String)>) {
    println!("cargo:rerun-if-changed={}", dir.display());
    for entry in fs::read_dir(dir).expect("read source directory") {
        let path = entry.expect("source entry").path();
        if path.is_dir() {
            collect(&path, modules);
        } else if matches!(
            path.extension().and_then(|s| s.to_str()),
            Some("lua" | "thlua")
        ) {
            let name = path
                .with_extension("")
                .to_string_lossy()
                .replace(['/', '\\'], ".");
            if !name.ends_with(".d") {
                modules.push((name, path.to_string_lossy().replace('\\', "/")));
            }
        }
    }
}

fn main() {
    // LPeg uses the stable Lua 5.4 C ABI. Only the public headers are vendored;
    // mlua's vendored Lua provides the single linked interpreter.
    cc::Build::new()
        .include("3rd/lua54-headers")
        .files([
            "3rd/lpeg/lpcap.c",
            "3rd/lpeg/lpcode.c",
            "3rd/lpeg/lpprint.c",
            "3rd/lpeg/lptree.c",
            "3rd/lpeg/lpvm.c",
        ])
        .compile("lpeg");
    println!("cargo:rerun-if-changed=3rd/lpeg");
    println!("cargo:rerun-if-changed=3rd/lua54-headers");
    println!("cargo:rerun-if-changed=rust/build.rs");
    let mut modules = Vec::new();
    collect(Path::new("thlua"), &mut modules);
    modules.sort();
    // Prefer .lua over .thlua if both exist.
    modules.dedup_by(|a, b| a.0 == b.0);
    let root = env::current_dir().expect("source root");
    let mut manifest = String::from("const SOURCES: &[(&str, &str, &str)] = &[\n");
    for (name, path) in modules {
        let absolute = root.join(&path).to_string_lossy().into_owned();
        manifest.push_str(&format!(
            "({name:?}, {path:?}, include_str!({absolute:?})),\n"
        ));
    }
    manifest.push_str("];\n");
    fs::write(
        Path::new(&env::var_os("OUT_DIR").unwrap()).join("sources.rs"),
        manifest,
    )
    .expect("write source manifest");
}

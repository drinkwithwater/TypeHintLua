# Rust 主程序

项目的原生入口是 `thlua`。发布时只需要分发 `thlua.exe`（Windows）或
`thlua`（Linux/macOS），无需安装 Lua、LuaRocks、动态 Lua 模块，或复制
`thlua/`、`global/`、`bin/` 目录。

## 构建

需要 Rust stable 和平台 C 编译器；Windows 使用 Visual Studio Build Tools 的
“使用 C++ 的桌面开发”工具链。C 编译器只用于 mlua 内置的 Lua 和 LPeg。
Windows MSVC 的 C 运行库采用静态链接。
release 使用 `panic = "unwind"`，以便 Lua 的 `pcall` 能正常捕获 Rust 宿主
回调错误；本项目的 release 回归测试覆盖了这种情况，参见
[mlua 对应问题](https://github.com/mlua-rs/mlua/issues/628)。

```sh
cargo build --release --locked
# POSIX shell 下也可运行 ./build.sh，额外参数会传递给 Cargo
```

产物：`target/release/thlua.exe` 或 `target/release/thlua`。
首次构建需要下载 Cargo 依赖，之后可以使用 `--offline`。
`3rd/lua54-headers` 仅保留 LPeg 需要的三份 Lua 5.4 公共头文件，解释器源码由
mlua 的 `vendored` 功能提供。无需初始化 Git 子模块。

旧 Lua、luv/libuv、lpath、RapidJSON 源码及 C++ 宿主、CMake 构建已删除，
`build.sh` 也已改用 Cargo。`3rd/web/` 的历史 Web 产物仍保留，但旧 Emscripten
构建链已移除；当前 Cargo 入口提供原生 CLI/LSP，不提供 Web/WASM 构建。

## 命令

```sh
# 对应 thc：默认输出 Lua 源码到 stdout；只擦除类型，不执行类型检查
thlua compile main.thlua
thlua compile main.thlua -o main.lua

# 对应 the：默认检查当前目录的 throot.thlua
thlua check
thlua check main.thlua
thlua check --project path/to/project
thlua check main.thlua --json

# 对应 thls：通过标准输入输出提供 LSP，不需要外部 global 目录
thlua lsp --stdio

# 可选：使用调用方自己的标准库声明目录
thlua lsp --global path/to/global

# 对应原来的 bin/thlua，编译并执行；arg[0] 为脚本名，后面为用户参数
thlua run main.thlua arg1 arg2
```

也可使用 `thlua thc`、`thlua the`、`thlua thls`。
编译不会覆盖输入文件；编译失败不会写入输出文件。
`check --project` 会切换到指定工程目录，然后检查 `throot.thlua`；
直接检查文件时，require 路径仍按当前工作目录解释，与旧入口一致。
`throot.thlua` 和 `setPath` 的现有配置方式继续有效，没有引入新的配置格式。

退出码：`0` 成功（包括只有 warning 的检查）；`1` 类型错误、语法错误或运行错误；
`2` 命令行参数、文件或传输 I/O 错误。
`check --json` 的 stdout 是诊断数组，包含 `file`、`line`、`column`、
`severity`、`message`；位置从 1 开始，severity 为现有的 1–4 级。
调试输出进入 stderr。

LSP 客户端配置为启动 `thlua`，参数 `['lsp', '--stdio']`。
仓库中的 VS Code 扩展使用 Rust 入口：可将 `TypeHintLua.executablePath` 设置为
可执行文件的绝对路径；未配置时优先使用扩展 `server/` 中的 `thlua.exe` 或
`thlua`，否则从 PATH 查找 `thlua`。扩展的运行命令使用 `thlua run`。
修改可执行文件设置后需要重新加载扩展。LSP 的 stdout 仅包含 Content-Length 帧，支持
`shutdown` 返回 `null` 后等待 `exit`。未经 shutdown 的 exit 返回 1。
内置标准库的定义位置使用 `thlua://global/` 虚拟 URI；需要在编辑器中打开这些
定义时，客户端应提供相应的虚拟文档，或改用 `--global` 的磁盘声明文件。
仓库扩展默认传入其 `server/global/` 声明目录，以便定义跳转可以打开磁盘文件。
打包扩展时将目标平台的 Rust 产物复制为 `server/thlua.exe`（Windows）或
`server/thlua`（Linux/macOS），这些生成文件已加入扩展的 `.gitignore`。

## 结构与依赖替换

| 旧实现 | Rust 入口的实现 |
| --- | --- |
| 单独安装/编译 Lua | mlua + vendored Lua 5.4，静态链接 |
| luv / libuv | Rust 输入线程、有界通道和协作式回调队列 |
| lpath | `std::path`、`std::fs`、`std::env` |
| lua-chrono.cpp | `std::time::Instant`，整数微秒及时间差 |
| lua-rapidjson | serde_json + mlua Serde，保留空数组、对象和 JSON null |
| LPeg | 保留原有 C 实现，静态链接 |

`build.rs` 生成源码清单，将当前 `thlua/` 中的运行模块嵌入二进制。
普通 Lua 引导编译器先加载，其余 `.thlua` 模块首次 require 时编译并缓存。
标准库声明来自 `thlua/global/`，不会使用可能过时的预打包 `thlua.lua`。
源码变更、增删文件会触发 Cargo 重新构建。

`host.rs` 的 `luv`、`path`、`chrono` 和 `rapidjson` 名称用于兼容现有实现。
只实现项目实际使用的接口，不是这些库的通用替代品；LSP 管道传输由
`lsp.rs` 直接处理。Lua 回调始终在同一线程执行，每次处理一个调度任务后
检查新消息，使编辑通知仍能触发现有的取消检查逻辑。独立输入线程及有界通道
避免阻塞 Lua 调度，并允许在 stdin 仍打开时响应 exit。

语言、类型推导和编辑器业务继续由 thlua 自举实现。这次替换的是原生宿主与
分发方式，没有重写类型检查算法，也没有以此宣称类型检查性能提升。

## 验证

```sh
cargo fmt --check
cargo clippy --locked --all-targets -- -D warnings
python test.py
python test.py --release
# 已构建的独立程序：
python test.py --binary target/release/thlua.exe
# Linux/macOS 使用 python3 和 target/release/thlua
```

完整套件包括语法、提示擦除、生成 Lua、类型诊断和多文件工程测试，
使用 Python 3.10+ 标准库；覆盖范围、基准维护和已知失败见 [测试指南](../test/README.md)。
CLI 测试会把单个可执行文件复制到包含中文路径的临时目录，清空 Lua 模块
搜索环境，并验证编译、运行、工程检查、JSON/回调桥接，以及真实 stdio LSP
初始化、文档修改、诊断、hover、错误响应、shutdown 和 exit。
LSP 帧的单元测试覆盖 UTF-8、连续消息、额外头字段、截断及大小限制。

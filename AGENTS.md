# 仓库贡献指南

首次阅读项目或缺少历史上下文时，先阅读 [架构与源码阅读导引](docs/architecture.md)，了解自举流程、类型语法和实际调用链。修改相关架构时同步更新导引，并区分已确认的行为与待验证的推断。

## 项目结构与模块组织

- `rust/`：可执行程序入口、Lua 宿主桥接、LSP 传输及源码嵌入构建脚本。
- `thlua/`：语言的自举实现。`code/` 负责解析，`runtime/` 和 `type/` 负责类型检查，`schedule/` 负责调度，`server/` 提供编辑器功能，`global/` 存放标准库声明。
- `lib/`：`.d.thlua` 声明文件；`examples/`：语言特性示例；`test/`：语言测试用例和命令行集成测试。
- `3rd/`：LPeg、必要的 Lua 头文件、编辑器集成和历史 Web 资源。构建产物存放在 `target/`。
- 打包及命令行用法见 `rust/README.md`；`bin/` 保留旧版 Lua 入口脚本。

## 构建、测试与开发命令

使用 Rust 稳定版和对应平台的 C 编译器；Windows 需要 Visual Studio Build Tools。无需单独安装 Lua 或初始化 Git 子模块。

```sh
cargo build --release --locked       # 构建独立可执行文件
cargo fmt --check                    # 检查 Rust 代码格式
cargo clippy --locked --all-targets -- -D warnings
cargo test --locked                  # 运行 Rust 单元测试
python test/rust_cli.py target/release/thlua.exe
cargo run -- compile examples/0_helloworld.thlua
cargo run -- lsp --stdio
```

Linux/macOS 下使用 `python3` 和 `target/release/thlua`。`./build.sh` 封装了 release 构建命令。使用 `thlua check --project <目录>` 检查工程中的 `throot.thlua`。

## 代码风格与命名约定

Rust 使用 rustfmt 默认格式，模块及函数使用 `snake_case`，类型使用 `PascalCase`。thlua 和 TypeScript 沿用现有的制表符缩进及 camelCase 方法命名；Python 使用四空格缩进。thlua 类模块采用 `ScheduleTask.thlua` 这样的命名。语言实现的修改应落在 `thlua/`，不要直接修改 `thlua.lua` 等生成的打包文件。

## 测试要求

Rust 测试使用 `#[test]`；可执行程序测试使用 Python `unittest`，测试方法以 `test_` 开头。为行为变更添加有针对性的回归测试。保留 `test/case*/` 语言用例中表示预期诊断的 `--E` 标记。目前没有固定的覆盖率门槛。集成测试应按变更范围验证独立运行、退出码、JSON 数据保真、UTF-8 路径及 LSP 生命周期。

## 提交与合并请求规范

历史提交使用简短的祈使句标题，例如 `add rust` 和 `update .gitignore`，不强制使用 Conventional Commits 前缀。每次提交应聚焦单一主题。PR 应说明解决的问题、修改后的行为、验证命令和兼容性变化，并关联相关 issue；涉及编辑器界面变化时附上截图。

## 架构约束

保留 LPeg 及其必要的 Lua 头文件；Lua 解释器由 mlua 的 vendored 构建提供。release 配置应保留 `panic = "unwind"`，使宿主错误可以被正常捕获。LSP 的标准输出仅用于协议消息。提交 `Cargo.lock` 和共享的 `.cargo/config.toml`，不要提交生成的二进制文件或性能分析产物。

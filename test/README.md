# 测试指南

## 运行

需要 Rust 工具链、平台 C 编译器和 Python 3.10+；Python 部分仅使用标准库。无需 pyskynet、Lua 安装或 pip 依赖。在仓库根目录运行：

```sh
python test.py                         # cargo test、cargo build，再运行全部 Python 测试
python test.py --release               # 对发布版本执行同样的完整验证
python test.py --no-build --filter types_optional
python test.py --binary target/release/thlua.exe
python test.py --list                  # 列出用例，不构建
```

Linux/macOS 使用 `python3`，可执行文件没有 `.exe` 后缀。`--filter` 按完整测试名的子串筛选；没有匹配项会失败。`--binary` / `--no-build` 会跳过 Cargo 单元测试与构建，因此修改 `thlua/` 后应先重新构建，避免验证旧的嵌入源码。失败返回非零退出码。

## 目录与覆盖范围

当前 manifest 有 149 个语言用例，展开为 288 项编译、运行和检查测试，另有 9 项测试器测试、10 项 CLI/LSP 测试、19 项类型 API 测试及 2 项 Rust 单元测试。语法覆盖是功能矩阵，不是行覆盖率，也不代表完整 Lua 5.4 兼容性。

| 位置 / 分类 | 数量 | 覆盖内容 |
| --- | ---: | --- |
| `cases/syntax/` | 35 | 数字、字符串与转义、注释、运算符、表、作用域、函数、可变参数、多返回值、分支、循环、goto/label、continue、换行和文件头 |
| `cases/hints/` | 14 | const、参数/返回提示、HintSpace、$、四类 cast、非空断言、泛型、模板、open/nocheck、表模式和提示擦除 |
| `cases/types/` | 42 | 基础类型、字面量/联合、可空收窄、Struct/Interface/交叉接口、递归、函数参数/返回、泛型、集合、class、guard、cast 和错误诊断 |
| `cases/invalid/` | 31 | 缺失/多余 token、非法赋值、保留字、未闭合字符串/表/调用/提示/泛型，以及非法提示位置 |
| `cases/projects/` 和 `caseRequire/` | 7 | require/import、嵌套模块、声明解析、依赖诊断、缺失模块、循环依赖和类模块 |
| `caseClass/`、`caseFlow/`、`caseFunc/`、`caseReturn/`、`caseTable/`、`caseType/`、`codeUnreachable.thlua` | 20 | 保留并迁移已有单文件回归 |

`cases/manifest.json` 保存预期；`baselines/` 保存人工审阅的 Lua 输出。`test_language.py` 负责语言测试，`support.py` 负责隔离与严格诊断匹配，`test_harness.py` 验证测试器本身，`rust_cli.py` 验证独立二进制及真实 stdio LSP。Rust 帧解析单元测试在 `rust/lsp.rs`。`test_type_algebra.py` 将 `goal/cases.json` 中的正确性保护逐项复制到隔离目录，在独立进程中验证嵌入类型实现；背景与接口契约见 [类型运算设计](../docs/type-algebra.md)。

## 断言与新增用例

1. 在相应分类添加一个最小 `.thlua` 文件，在 manifest 注册唯一的 `分类/snake_case` 名称；工程用例使用 `project`，单文件使用 `source`，路径相对 `test/`。新文件遗漏注册会导致测试失败。
2. 编译阶段检查退出码和输出，再用 Lua `loadfile` 验证输出确实可加载。非法语法指定 `syntaxError` 消息片段，必须编译失败且不创建输出。
3. 需要行为验证时填写精确 `stdout`；测试会分别执行原始 thlua 和生成的 Lua。生成代码通过 Lua 加载，避免把 `goto continue` 等生成内容重新当作 thlua 解析。
4. 类型用例填写 `diagnostics`；`[]` 表示不能出现任何诊断。每条指定 `file`、1 基 `line`、`severity` 和 `message` 或 `contains`，可加 `column`。数量必须完全一致，重复诊断逐条计算；非预期诊断、漏报、级别或位置变化均失败。部分旧检查路径会重复报告同一错误，当前基准记录了该行为，修正去重逻辑时应单独审阅变化。
5. 需要稳定代码生成基准时添加 `lua` 路径。诊断失败的实际结果写入 `target/test-results/<name>.actual.json`，不会自动覆盖预期；确认语义后手动修改基准。

例如：

```json
{
  "name": "types/wrong_primitive",
  "source": "cases/types/wrong_primitive.thlua",
  "compile": true,
  "diagnostics": [
    {"file": "main.thlua", "line": 1, "severity": 1, "contains": "type not match"}
  ]
}
```

每项测试在独立中文临时目录运行，清空 `LUA_PATH` / `LUA_CPATH`。单文件统一复制为 `main.thlua`；工程整体复制，保留相对路径。超时视为失败。CLI 测试额外只复制可执行文件，确保没有依赖工作区源码。

## 旧测试审计与修正

旧 `test.py` 依赖 pyskynet，只收集六类单文件，遗漏 `caseRequire/`；旧 `TestCase` 的异步接口仍是 TODO，失败也只打印文字。现已改为统一入口，并修复兼容 `TestCase.go` 的调度和退出行为。

- 类模块的过时 `:impl(...)` 改为 `function:class(...)`；移除非可变参数函数里的 `...`。工程入口改为可断言的 require 场景，并为 `pkg.lua` 补充声明。
- `caseTypeAfterCast` 原来在 HintSpace 直接读取运行变量，实际上访问了不存在的提示名字；改为真正验证 cast 后的联合类型。
- `caseMixOpen` 的未使用 open 参数不会产生参数约束，原 `--E` 是错误预期；移除该标记。补齐 open/auto 调用的外层诊断标记，并按真实节点修正递归元表诊断位置。
- `caseFillMember` 的 HintSpace print 属于 info，改用 `--I`。兼容标记支持 `--E/--W/--I/--H` 和 `--E: 说明`；manifest 是精确数量、位置和消息的正式基准，测试器检查两者位置及级别一致。
- `codeUnreachable` 纳入现有行为回归，记录三个 HintSpace 输出；这不能证明分支穷尽性检查正确。
- LSP 测试等待 rerun 完成，避免把 didChange 的临时空语法诊断当成检查完成，并验证实际变量使用处的 hover。

`test/testDraft/`、根目录及 `test/` 下其他临时探索脚本（例如 `temp*`、`runtype`、`testskynet`、`count/`）保留为实验材料，部分使用旧语法或外部环境，未自动纳入正式套件。第三方目录中的测试属于上游，不由本入口运行。

## 已知失败

以下四项保留正确预期，用 `knownFailure.phase/reason` 明确标记为 `unittest.expectedFailure`，没有改成接受错误结果：

| 用例 | 当前问题 |
| --- | --- |
| `syntax/hexadecimal_float`（compile） | Number 规则只支持十六进制整数，不支持合法 Lua 十六进制浮点数 |
| `syntax/shebang`（run） | 编译和 Lua loadfile 通过，但 Rust run 的字符串加载未处理 shebang |
| `syntax/utf8_bom`（run） | 编译和 Lua loadfile 通过，但 Rust run 的字符串加载未处理 BOM |
| `invalid/continue_outside_loop`（compile） | 循环外 continue 未被拒绝，生成缺少目标标签的 goto |

其他阶段照常验证；新增非预期失败仍使套件失败。已知失败意外通过也会使套件失败，修复实现后应删除对应标记。这里不引入 Lua 5.4 的所有新特性，例如 `<close>`，也没有为增量类型检查提供覆盖或性能保证。

组织方式参考 [TypeScript 的 compiler tests 与基准分离做法](https://github.com/microsoft/TypeScript/blob/main/CONTRIBUTING.md#compiler-tests)：将输入、正式预期和本次实际输出分开保存，独立验证编译产物、诊断和编辑器行为。没有引入 TypeScript 的构建依赖。

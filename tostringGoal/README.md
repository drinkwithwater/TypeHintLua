# 类型字符串显示：问题、复现与后续设计边界

本目录分析检查器内部类型对象的 `tostring` / `detailString`，以及这些字符串如何进入诊断和 hover。它不讨论用户 Lua 对象的 `__tostring` 元事件，也没有修改当前打印实现或类型算法。

2026-11-17，使用重新构建的 Windows Debug、Release 可执行文件验证 17 个探针：12 项显示缺陷按指定正确性断言复现，3 项风险观察与 2 项行为保护通过。默认 runner 的成功表示“当前行为符合档案”，不表示缺陷已修复。

## 运行与目录

在仓库根目录运行，Python 3.10+，无需额外 Python 包：

```sh
cargo build --locked
python tostringGoal/run.py
python tostringGoal/run.py --filter T04
python tostringGoal/run.py --list
python tostringGoal/run.py --strict
cargo build --release --locked
python tostringGoal/run.py --binary target/release/thlua.exe
```

Linux/macOS 使用 `python3` 和不带 `.exe` 的程序。修改 `thlua/` 后应重建，因为程序使用嵌入源码。也可以直接执行 `target/debug/thlua.exe run tostringGoal/04_member_parameter_disappears.lua`。这些内部 API 脚本使用 **run**，不是 check；`fixtures/` 下的 `.thlua` 才是源语言样例。

- [cases.json](cases.json)：分类、预期观察输出和指定缺陷断言。
- [run.py](run.py)：独立进程、固定工作目录、清空 `LUA_PATH` / `LUA_CPATH`，每项 25 秒超时；校验重复 ID、脚本遗漏与分类。
- [support.lua](support.lua)：用真实 TestCase / CodeRuntime / TypeManager / HintTask 初始化；复现使用实际类型，不伪造类型对象。另支持分析指定源码。
- `fixtures/`：真实诊断与 hover 样例，可在编辑器中打开或用 CLI 检查。

状态与 `goal/` 相同：`REPRODUCED` 必须同时满足退出码 1、指定 `Txx:` 正确性断言和观察输出；其他异常、超时、缺少输出都算 `ERROR`。已知缺陷意外通过为 `UNEXPECTED_PASS`，须审阅契约后更新清单。普通保护/观察须退出 0。默认在 12 个问题正确复现、其余 5 项通过时返回 0；`--strict` 在仍有缺陷时返回 1；空筛选/无效程序路径返回 2。**T17 的底层异常不是直接的匹配条件**：脚本分别捕获打印错误和后续调度错误，再通过自己的正确性断言失败，避免把任意崩溃视为复现。

`H.show` 用 JSON 转义记录字符串，便于观察换行和 NUL；日志中的 `\n`、`\u0000` 是记录层的转义，并不表示被测 printer 做了转义。探针是分析档案，尚未加入 `test.py` 的正式成功回归。

## 问题索引

| 编号 | 脚本 | 分类 | 当前观察 |
| --- | --- | --- | --- |
| T01 | [01_structural_information_loss.lua](01_structural_information_loss.lua) | 信息缺失 | 同一构造节点的 `{x=Integer}` / `{x=String}` 结构，verbose 字符串仍完全相同 |
| T02 | [02_string_literal_escaping.lua](02_string_literal_escaping.lua) | 格式缺陷 | 字面量直接拼接引号、反斜杠、换行及 NUL，没有转义 |
| T03 | [03_float_precision_collision.lua](03_float_precision_collision.lua) | 信息丢失 | 1.0 与下一个可表示 double 都显示 `Literal(1.0)` |
| T04 | [04_member_parameter_disappears.lua](04_member_parameter_disappears.lua) | 签名错误 | `Mfn(Integer):Ret(String)` 显示空参数元组 |
| T05 | [05_function_error_type_missing.lua](05_function_error_type_missing.lua) | 契约缺失 | 不同 Err 类型的函数在 verbose 模式也显示相同 |
| T06 | [06_resolved_async_placeholder.lua](06_resolved_async_placeholder.lua) | 路径不一致 | 已解析 Integer 引用直接打印为 wrapper，嵌入元组则成为 TODO |
| T07 | [07_printing_finalizes_builder.lua](07_printing_finalizes_builder.lua) | 观察副作用 | `detailString` 完成函数返回构建，之后追加 Ret 被拒绝 |
| T08 | [08_printing_can_wait.lua](08_printing_can_wait.lua) | 调度风险观察 | `detailString` 可实际等待，未注册 coroutine 中失败 |
| T09 | [09_pending_and_recursive_guard.lua](09_pending_and_recursive_guard.lua) | 行为保护 | pending 引用打印不等待；当前递归对象打印能终止，但不展示结构 |
| T10 | [10_union_creation_order.lua](10_union_creation_order.lua) | 稳定性缺陷 | 相同字面量成员跨 runtime 的显示顺序由创建 ID 决定 |
| T11 | [11_shared_graph_expansion.lua](11_shared_graph_expansion.lua) | 规模风险观察 | 9 个不同函数节点的共享图展开成 511 个签名，16,355 字节 |
| T12 | [12_auto_table_state_label.lua](12_auto_table_state_label.lua) | 状态标签错误 | `isCastable()==false` 时却显示 `@castable@` |
| T13 | [13_private_field_helper.lua](13_private_field_helper.lua) | 私有助手观察 | 字段值后多出 `]=`，且公开显示完全不调用此助手 |
| T14 | [14_assignment_diagnostic_context.lua](14_assignment_diagnostic_context.lua) | 消费端缺失 | Integer 接收字符串的错误只有 `type not match ` |
| T15 | [15_structural_hover_context.lua](15_structural_hover_context.lua) | 消费端缺失 | 真实 hover 业务返回 `Struct@[test]:1,1`，没有 Customer 或字段 |
| T16 | [16_primitive_and_union_guard.lua](16_primitive_and_union_guard.lua) | 行为保护 | 基础类型名、Boolean verbose 与同一 Union 重复打印目前稳定 |
| T17 | [17_tostring_pending_function_fails.lua](17_tostring_pending_function_fails.lua) | 运行错误 | 未完成函数的 tostring 触发跨 C 调用 yield，之后恢复死协程 |

这里的“缺陷”同时包括可复现的运行/签名错误，以及面向人类可读性所提出的显示契约缺口，不把它们一概视为类型计算错误。T01/T10/T11 不要求任意语义等价类型都具有相同字符串；字符串也不应成为类型身份键或包含关系的依据。

## 1. 当前入口与实际消费链

```text
tostring(type)
  → BaseReadyType.__tostring
  → concreteType:detailString(false)

TypedFunction:detailString(verbose)
  → buildParRet()
  → parameterTuple:detailString(verbose)
  → returnTuples:detailString(verbose)

StackManager:hoverNode
  → 收集表达式的原子类型，按 TypeId 排序
  → eachType:detailString(true)
  → 用逗号拼接
  → ApiProvider:onHover 返回 plaintext

CodeRuntime:_save
  → 对诊断参数调用 tostring
  → 合并成诊断消息
```

相关源码：[BaseReadyType](../thlua/type/basic/BaseReadyType.thlua)、[TypedFunction](../thlua/type/func/TypedFunction.thlua)、[BaseTypeTuple](../thlua/tuple/BaseTypeTuple.thlua)、[RetTuples](../thlua/tuple/RetTuples.thlua)、[StackManager](../thlua/stack/StackManager.thlua)、[ApiProvider](../thlua/server/ApiProvider.thlua)、[CodeRuntime](../thlua/runtime/CodeRuntime.thlua)。

`detailString(Boolean)` 没有统一的格式上下文。基础 Boolean 会按 verbose 区分 `True` 与 `Literal(true)`，不少其他类型完全忽略它。AutoFunction / ClassFactory 还有独立 `__tostring`，AsyncTypeCom 的 `__tostring` 与继承的 `detailString` 也不一致。因此只改 BaseReadyType 的一个方法，无法覆盖全部路径。

## 2. 结构内容、名字和位置：T01、T15

Struct 和 Interface 的 `detailString` 只返回类型类别与 `tostring(node)`，后者是路径、行、列。T01 使用实际的同节点构造，确认字段类型和语义均不等价，但输出分别都是：

```text
Struct@[test]:1,1
Struct@[test]:1,1
Interface@[test]:1,1
Interface@[test]:1,1
```

这说明它们主要表达“在哪里构造”，无法说明“这个类型是什么”。同节点探针不声称所有普通源码声明都位于同一节点；Template/组合构建等内部调用允许复用构造位置，不能把位置当结构标识。

T15 分析 [named_struct_hover.thlua](fixtures/named_struct_hover.thlua)，查找 `print(customer)` 中的真实标识符，执行生产代码 `StackManager:hoverNode`。输出依然只有 `Struct@[test]:1,1`。可在编辑器中悬停 customer 复现；探针没有启动 JSON-RPC 传输，因此这里验证的是实际 hover 业务结果，不声称覆盖客户端渲染或协议层。

位置应作为可选来源信息，结构字段或可用的别名应进入主展示内容。**别名需要调用方的名字/作用域上下文**：不能假定每个结构对象只有一个源名字，也不能仅靠 `detailString` 反向恢复用户写下的 Customer。

## 3. 字面量格式：T02、T03

[StringLiteral](../thlua/type/basic/StringLiteral.thlua) 直接拼接 `"Literal('" .. literal .. "')"`。输入含单引号后引号不配对，含真实换行/NUL 后输出包含相同控制字节。T02 额外在仅提供 Literal 函数的隔离环境中尝试加载显示结果，验证现有写法不能保留字面量。这只是当前 `Literal(...)` 记法的转义检查，不要求未来所有类型显示都必须可作为 Lua 源码执行。

[FloatLiteral](../thlua/type/basic/FloatLiteral.thlua) 用数字到字符串的默认拼接，精度不足：

```text
实际值（%.17g）：1 / 1.0000000000000002
显示：Literal(1.0) / Literal(1.0)
```

两个值由真实 TypeManager 生成不同 FloatLiteral，未伪造或修改对象。建议提供足以区分字面量的浮点格式，并单独确定整数/浮点、负零、无穷值等格式；本轮**没有**验证负零、NaN 或无穷值的全部行为，不将其列为已确认缺陷。

## 4. 函数签名缺失：T04、T05

[TypedMemberFunction](../thlua/type/func/TypedMemberFunction.thlua) 对 headless 参数元组调用 `detailStringIfFirst(verbose, false)`，无条件跳过第一项。但 `buildMfn` 的 `_headlessFn` 保存的是显式参数，`toTypeFn(owner)` 才会在前面补 self。T04 检查两者的真实元组，得到：

```text
headless 参数：Tuple(Integer)
显示：member:fn-Tuple()->(Tuple(String))
绑定 owner 后：两个参数，第二项仍为 Integer
```

这属于直接丢参数，而不只是记号风格问题。

[RetTuples](../thlua/tuple/RetTuples.thlua) 的比较会考虑 `_errType`，但格式化只遍历正常返回元组。T05 构造相同输入/正常返回、不同 Err 的函数，实际错误类型为 `Union(Integer,String)` 与 `Union(False,String)`，两边显示却同为：

```text
fn-Tuple(Integer)->(Tuple(String))
```

建议在完整/verbose 签名中明确 Err；短模式是否省略可以另行规定。参数名、泛型参数和 Open/Auto/PolyFunction 的可用签名信息也值得纳入统一格式设计，但本轮未为每种函数模式建立独立缺陷证明。

## 5. 引用与未完成状态：T06、T09

已解析为 Integer 的 AsyncTypeCom：

```text
tostring(ref)      = AsyncTypeCom(Integer)
detailString(true)= BaseTypeCom detail string TODO
Tuple(ref)        = Tuple(BaseTypeCom detail string TODO)
```

原因是 [AsyncTypeCom](../thlua/space/AsyncTypeCom.thlua) 仅自定义了 `__tostring`，[BaseTypeCom](../thlua/space/BaseTypeCom.thlua) 的 `detailString` 仍返回占位文本，而元组使用后者。

需要区分 pending、成员集合已就绪、最终类型已就绪，以及诊断期的失败状态。已解析引用可以展示其结果；未解析引用应提供明确、有限的占位信息。T09 保护当前 `AsyncTypeCom(?)` 的非等待行为和递归对象打印终止性。**当前没有证明递归结构会造成无限打印**：它们现在只显示位置；未来展开结构时才必须加入递归引用与深度控制。

## 6. 打印副作用与等待：T07、T08、T17

T07 通过直接调用 `detailString(false)` 排除元方法 yield 边界的干扰。未打印函数可以继续 `Ret(String)`；同样的函数在格式化后被赋予默认空返回类型，随后 Ret 抛出“构建已完成”。路径是 `detailString → buildParRet → RetBuilder:build`。建议观测未完成类型时显示 pending/builder 状态，或明确拒绝这种格式化，不能让日志查询悄悄改变后续构建。

T08 验证直接 `detailString` 可等待返回元组事件，顺序为 `before,scheduled,after`；同样调用在未注册 coroutine 中报“requires a registered checker task”。这是隐藏的执行前提，不表示所有类型的打印都等待。

T17 是另一条更严重的路径：在**已注册 HintTask** 中对未完成 TypedFunction 调用 Lua `tostring`：

```text
打印：attempt to yield across a C-call boundary
后续调度：cannot resume dead coroutine
```

`__tostring` 经 Lua 的字符串转换调用进入格式化，当前环境不允许在该 C 调用边界中 yield。`ScheduleEvent:wait` 在 yield 前已经登记等待者；异常被 pcall 捕获、任务结束后，依赖事件仍把它唤醒，因此出现第二个错误。脚本使用真实任务和合法函数 Builder，没有手动向队列塞死协程。两个异常被分别校验，最终以 T17 正确性断言失败。

建议把非等待、无构建副作用的展示核心与显式等待的“准备完整描述”分开；若提供后者，调用方需先完成准备，再调用普通 tostring。仅给所有 printer 套一个等待禁令会把已有诊断变成异常，也不能补全缺失信息；根本上要让 printer 读取可用状态而非隐式推进计算。调度器对失败等待登记的清理也值得单独修复，但本轮未修改它。

## 7. 顺序、共享图和输出预算：T10、T11

[BaseUnionType](../thlua/type/union/BaseUnionType.thlua) 先按 TypeId 排序，保证单个对象反复打印稳定，但跨检查生命周期会受创建顺序影响。T10 在两个真实管理器中分别先创建 alpha/omega、omega/alpha，成员 payload 相同，显示顺序相反。探针没有跨管理器调用类型包含或集合运算。

RetTuples 的多个返回分支、AsyncTypeCom 的成员遍历及若干调试容器还使用未排序遍历。从源码可确认没有显式稳定排序，但本轮**没有把每次运行必然产生不同顺序当作已复现事实**。要改善稳定性，应该为显示制定排序规则，而不是改 TypeId 分配、身份驻留或语言语义。

T11 创建 9 个不同 TypedFunction，每层两个参数都引用同一个下层函数。当前完整递归展开得到 511 个签名和 16,355 字节。探针记录的是共享子图重复展开的规模，不是运行时间基准，也不证明当前发生超时。即使不存在环，长联合、共享 DAG 和多返回分支也需要输出预算。可以引入可解释的引用、截断标记、最大深度/节点/字符限制，并允许用户主动展开。

## 8. 其他相关问题：T12、T13、T14

- **T12**：[AutoTable](../thlua/type/object/AutoTable.thlua) 在 `not self:isCastable()` 时返回 `AutoTable@castable@...`，状态标签与查询结果相反。脚本使用真实表、真实 AssignContext 子类进行两次赋值登记，不伪造 context。
- **T13**：[TypedObject](../thlua/type/object/TypedObject.thlua) 的私有 `_kvDetailString` 产生 `{\t[Literal('x')]=Integer]=\n}\n`，字段值后多出 `]=`。源码中只有其定义，公开 Struct/Interface 显示不调用它。这是未接入助手的局部观察，不能据此声称用户当前 hover 会展示这个畸形字段串。
- **T14**：[assignment_mismatch.thlua](fixtures/assignment_mismatch.thlua) 的诊断只有 `type not match `。[AssignContext:includeAndCast](../thlua/stack/context/AssignContext.thlua) 没有把期望/实际类型传给消息生成。修复 printer 本身不会自动改善这条诊断；消费端需要显式调用格式化，并保留源位置与字段/参数路径。探针断言恰好一个错误、级别和行号正确，避免拿其他初始化错误充当缺失类型信息。

## 9. 建议的后续设计

以下为后续方案，**尚未实现**。建议统一显示上下文，而非逐类继续堆叠字符串拼接：

| 层次 | 建议职责 |
| --- | --- |
| 只读类型快照访问 | 读取已解析结果、构建状态及可用结构；不等待、不规范化、不修改缓存/Builder |
| 结构化显示文档 | 表示原子、字面量、联合、字段、元组、签名、引用与来源注释；共享递归/预算上下文 |
| 格式策略 | short / hover / full / debug；稳定排序、转义、数字精度、优先级及括号规则 |
| 消费端适配 | hover、诊断、日志分别选择策略；诊断加入 expected/actual 和失败路径 |

可能的配置包括 `maxDepth`、`maxNodes`、`maxChars`、`showAliases`、`showSource`、`showErrors`；这些是设计维度，不是当前已经存在的 API。别名优先级和多个别名的选择应由作用域决定。debug 模式可以显示 ID/来源，常规模式应以类型内容为主。不要把显示稳定性要求变成用字符串判断类型相等。

建议优先级：

1. 先处理 T17 运行错误及 T07/T08 的观测副作用/等待边界；确保打印安全可用。
2. 修复 T02/T03/T04/T06/T12 的明确格式、签名与路径一致性问题。
3. 引入结构/签名完整显示，覆盖 T01/T05/T14/T15，并设计别名上下文。
4. 加入稳定排序、共享图和截断预算，保留 T09/T16 保护，再逐步扩展其他类型类别。

## 验证范围与限制

当前用例针对内部类型显示及两个真实消费端。没有修改实现，也没有把默认 runner 退出 0 宣称为“所有显示功能正确”。没有声称所有字符串必须唯一或可回解析，没有证明所有递归、Unicode/宽字符、浮点特殊值、复杂元表、泛型名称和跨平台格式均已覆盖。hover 探针不启动 LSP 传输，T13 使用私有方法，T07/T08/T17 涉及未完成构建状态，均在对应章节明确说明。

后续修复时应更新相关正确性断言和清单，再将稳定用例纳入正式套件；不可通过接受任意异常、扩大错误匹配或取消关键断言消除失败。

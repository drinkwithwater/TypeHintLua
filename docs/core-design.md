# 核心设计：用 Lua 计算类型

TypeHintLua 在 Lua 上添加静态类型系统，并复用 Lua 的计算能力来编写类型层程序。同一份源码在编译运行和静态检查时生成不同的 Lua：前者擦除提示；后者保留提示中的 Lua 计算，把普通程序翻译为分析操作，再执行组合后的 Lua typing code 来推进检查。

这是阅读项目时应先建立的认识。仅把项目理解为“Lua 加类型注解”，容易忽略提示代码的执行语义，也难以理解 `HintGener`、类型对象、名字引用和调度器为什么这样协作。源码入口和宿主结构见 [架构导引](architecture.md)，具体类型关系契约见 [类型运算](type-algebra.md)。

## 1. 两种空间复用计算语言，各自承担不同的工作

| 问题 | 普通程序的值空间 | Hint Space（提示／类型空间） |
| --- | --- | --- |
| 操作什么 | 程序的数字、字符串、表、函数等值 | 类型对象、名字引用、模板，以及辅助计算的普通 Lua 值 |
| 怎样写计算 | Lua 表达式、函数、控制流，加少量扩展 | 复用 Lua 表达式、函数、表和控制流，通过提示语法嵌入 |
| `compile` / `run` 时 | 转为 Lua，`run` 执行用户程序 | 提示被擦除 |
| `check` 时 | 被翻译为类型、term、符号及分支状态的分析操作 | 普通 Lua 片段在检查器提供的环境中执行；`$` 等跨空间部分另行转换 |

`Struct {x=Integer}` 首先是一次 Lua 函数调用，其参数是 Lua 表；`Union(Integer, String)` 也遵循 Lua 调用语法。`Struct`、`Union` 等名字由检查器注入，调用后构造或组合类型。用户可以先用普通 Lua 程序计算字段表，再交给 `Struct`，也可以把类型构造封装为函数，经 `Template` 注册为类型模板。

因此设计上复用的是**类型计算的表达与执行机制**。类型的表示、包含关系、变型、规范化、收窄、递归引用和函数调用分析仍需实现；Lua VM 不会自动提供这些语义。

语法边界仍然存在：`:T`、转换、`@<...>`、`(@...)`、`$` 等负责标记两种空间及其交互。单个提示位置有各自的语法约束；复杂的提示程序可以放进 `(@do ... end)`，不能据“复用 Lua”认定每个提示位置都接受任意语句。

## 2. 一个能同时看见两种空间的例子

以下完整示例已用当前实现验证：

```lua
(@do
	let.Pair = Template(function(T)
		local fields = {}
		for _, name in lua.ipairs({"left", "right"}) do
			fields[name] = T
		end
		return Struct(fields)
	end)
end)

const pair:Pair(Integer) = {left=1, right=2}
(@let.SameAsPair = $pair)
const copy:SameAsPair = pair
print(copy.left + copy.right)
```

这里的循环、局部变量、表赋值和模板回调都按 Lua 语义执行，用于计算类型。`Pair(Integer)` 实例化出左右字段均为 `Integer` 的结构类型；`$pair` 把值空间中 `pair` 的分析所得类型带入提示空间，再用于 `copy` 的提示。它不会取得运行时那张 `{left=1, right=2}` 表。

### 编译运行路径

`compile` 擦除上述模板定义、类型提示和 `$` 所在的提示语句，并把 `const` 改成 `local`。忽略为保持位置而留下的空白和分号，得到：

```lua
local pair = {left=1, right=2}
local copy = pair
print(copy.left + copy.right)
```

`run` 执行它并输出 `3`，不先检查模板定义或字段类型是否正确。

### 静态检查路径

`HintGener` 生成另一份合法 Lua，其关键部分如下。表中是操作对应关系，省略了节点参数、元组处理和函数包装，不能作为完整生成代码使用。

| 源码部分 | typing code 的处理 |
| --- | --- |
| `Template(function(T) ... end)` 内的 Lua 计算 | 保留提示脚本，包含 `lua.ipairs` 循环和 `Struct(fields)` 调用 |
| `Pair(Integer)` | 保留为提示环境中的类型模板调用，所得类型交给变量分析操作 |
| `{left=1, right=2}` | 生成 `TABLE_NEW`、`LITERAL_TERM` 等分析操作，建立表的类型信息 |
| `const pair:...` | 生成 `SYMBOL_NEW`，记录符号并检查初始化与提示的兼容性 |
| `$pair` | 生成 `EVAL_EXPR(SYMBOL_GET(...))`，从 term 中取得类型 |
| `copy.left + copy.right` | 字段查询及 `META_BOP_SOME`，按类型规则分析加法 |
| 值空间的 `print(...)` | 生成 `META_CALL`，分析函数调用 |

所以在检查阶段，提示中的循环会实际迭代；值空间的函数调用和分支则交给分析器处理。比如运行时 `if` 被改写为 `IF_ONE` / `IF_TWO` 和分支闭包，由分析器根据类型条件分析可达分支并合并状态。不能按“把用户程序执行一次，看看有没有错误”来理解 `check`。

将示例保存为 `demo.thlua` 后，可以分别观察：

```sh
thlua check demo.thlua --json     # []
thlua compile demo.thlua -o demo.lua
thlua run demo.thlua             # 3
thlua run demo.lua               # 3
```

## 3. 从源码核实这个机制

| 阅读顺序 | 已确认的实现 |
| --- | --- |
| [ParseEnv:buildIHintSpace](../thlua/code/ParseEnv.lua) | 把普通提示脚本按源码切片保存为 `HintScript`，把 `$` 嵌入部分单独保存为 `HintEval`。同一解析器还记录擦除提示、生成执行 Lua 的变换。 |
| [CodeEnv:_prepare / _buildTypingFn / callTypingFn](../thlua/code/CodeEnv.thlua) | 准备 AST 与符号关系，调用 `HintGener`，使用 Lua `load` 加载 typing code，再传入节点、分析栈和全局项执行。 |
| [HintGener:fixIHintSpace / TagToVisiting / visitFunc](../thlua/code/HintGener.thlua) | 保留普通 `HintScript`，将 `$` 生成 `EVAL_EXPR` / `EVAL_DO`；普通程序节点则生成 `SYMBOL_*`、`META_*`、分支分析等调用，并设置提示的 `let` 和 `_ENV`。 |
| [InstStack](../thlua/stack/InstStack.thlua) | `RUN_STAT` 调用提示闭包；`EVAL_EXPR` 返回 term 的类型；`META_CALL`、`IF_TWO` 等消费分析结果和类型规则。 |
| [CodeRuntime:buildSimpleGlobal](../thlua/runtime/CodeRuntime.thlua) | 向提示空间注册基础类型与 `Union`、`Struct`、`Template` 等内建构造器。 |
| [TypeManager:convertFunctionToTemplateLambda](../thlua/type/TypeManager.thlua)、[TemplateCom:cacheCall](../thlua/space/TemplateCom.thlua) | 调用真实 Lua 模板回调，将返回值转为类型，并按类型参数缓存实例化结果。 |

检查器自身也在利用这个设计：[HintGener.thlua](../thlua/code/HintGener.thlua) 开头的 `let.RealTraverser` 用 Lua 闭包、局部表和 `foreachPair` 遍历 `node.TagToNodeType`，为各节点计算访问器函数类型，再调用 `Struct` 构造访问器表的结构类型。这是自举源码中直接可见的类型计算程序。

需要查看完整生成结果时，使用 `CodeEnv:getTypingCode()`。例如把以下普通 Lua 保存为 `inspect.lua`，在仓库中执行 `thlua run inspect.lua demo.thlua`：

```lua
local CodeEnv = require "thlua.code.CodeEnv"
local input = assert(io.open(arg[1], "r"))
local source = input:read("*a")
input:close()
local env = CodeEnv.new(source, arg[1])
print(env:getTypingCode())
```

生成文本可以被 Lua `load`；真正推进分析还需要 `CodeRuntime` 提供栈、类型管理器、名字空间和调度。单独生成或加载成功不代表类型检查通过。

## 4. 环境、类型对象与跨空间边界

普通提示片段作为 Lua 检查脚本执行，其局部变量和控制流不会再走值空间的同一套静态分析。因此调试时也要区分提示程序自身的 Lua 执行错误与被分析程序的类型不匹配。

- **提示环境有专门的名字解析。** `InstStack:SPACE()` 经 `LetSpace:export` 提供 `let` 和 `_ENV`。`let.Name = ...` 定义提示名字；未限定名字沿提示作用域解析。它不是直接使用宿主全局表。
- **`lua` 与 `_G` 含义不同。** [SpaceValue.envCreate](../thlua/space/SpaceValue.thlua) 将 `lua` 设为访问宿主 Lua 全局的入口，将 `_G` 设为类型根名字空间代理。需要宿主迭代器时写 `lua.ipairs` / `lua.pairs`，需要表库时写 `lua.table`；不能用 `_G.ipairs` 或裸 `ipairs` 代替。仓库 [throot.thlua](../throot.thlua) 也是这样构造搜索路径的。
- **`$expr` 连接的是分析结果。** 表达式仍经过分析，再从 `RefineTerm` 取得类型。这里通用术语“Lua term／项”表示 Lua 的计算表达式；仓库 `term/RefineTerm` 则是带类型和分支事实的分析对象，二者不要混为一谈。
- **普通 Lua 值可以辅助计算，类型结果仍有协议。** [SpaceManager:spaceToMustType](../thlua/space/SpaceManager.thlua) 接受类型对象、可解析引用、类型组件，以及可转成字面量类型的 number/string/boolean 等；任意普通表、函数或 Lua `nil` 不能直接充当类型。示例的 `fields` 是给 `Struct` 的构造参数，不是结构类型本身。
- **模板保留实例化与调度语义。** 回调能写普通 Lua 程序，但模板调用受参数、缓存和异步类型解析规则约束，不应依赖每次写出调用都会重新执行副作用。名字引用和递归类型的就绪也不能简单视为顺序执行中的普通变量赋值。
- **模块与泛型仍需按本项目规则阅读。** `import` 取得被分析模块关联的类型空间，与宿主 `require` 的模块值不同；函数／方法泛型调用仍必须用 `@<...>` 显式传入类型参数。`Pair(Integer)` 这种提示中的模板调用并不表示支持函数泛型参数自动推导。

## 5. 与其他语言比较时，区别应落在哪里

TypeScript 通过条件类型、映射类型等类型专用机制表达类型变换，见其官方 [Creating Types from Types](https://www.typescriptlang.org/docs/handbook/2/types-from-types.html)。TypeHintLua 的设计选择是让这类构造计算可以直接写成 Lua 函数、循环和表操作，再通过类型 API 取得类型结果。

C++ 的模板具有参数、实例化和特化等规则，见 [C++ 工作草案 Templates](https://eel.is/c++draft/temp)。不过 C++ 也提供 `constexpr` / `consteval` 函数来进行编译期计算，见 [相关声明规则](https://eel.is/c++draft/dcl.constexpr)。因此不能笼统地说其他语言都必须另外学习一套完全不同的计算语言。

对本项目而言，显著的区别是这组具体选择的组合：**提示计算采用 Lua；类型是检查器管理的 Lua 对象及引用；值程序被生成成分析操作；两部分组成 Lua typing code，由同一个 Lua 执行机制驱动检查。** 这对理解实现很重要，但本文不据此主张编译期执行或复用宿主语言是独有发明。

“利用 Lua 的图灵完备性”可理解为设计动机：复用已有通用语言的计算能力，避免再实现一套通用的类型计算求值器。它不构成类型系统健全性、检查终止性、类型可表示性或所有类型关系均可判定的证明，也不意味着任意运行时数据都能在检查时取得。本文没有给出这些形式化证明。

## 6. 自举与两种空间的关系

自举与上述设计相互配合，但要分别说明两件事：

1. **实现如何启动并运行。** Rust 先加载普通 Lua 写的 `ParseEnv.lua`，再在首次 `require` 时把其余 `.thlua` 实现擦除提示并执行。解析、类型检查主体和编辑器业务由此在 Lua VM 中运行；Lua、LPeg 和 Rust 宿主仍是启动依赖。
2. **实现源码如何被检查。** 对这些 `.thlua` 文件执行检查时，才会生成 typing code，执行它们的提示程序并分析普通程序部分。这与“擦除提示后能运行检查器自身”是不同的验证。

因此，主要实现用 TypeHintLua 编写，并能由普通 Lua 编写的 `ParseEnv.lua` 引导编译并执行，可以从启动链确认；不能从这个事实推出实现源码已全部通过自身类型检查。当前整工程自检查仍有已有诊断，参见 [架构导引中的已复现边界](architecture.md#4-类型检查模块如何协作)。

## 7. 后续对话与修改时保留的认识

先确定正在讨论哪种 Lua 输出、哪种空间，再沿 `ParseEnv → CodeEnv → HintGener → Stack → TypeManager / Space / Schedule` 追踪。修改擦除路径时验证生成 Lua 与运行行为；修改类型计算、泛型或分析语义时还需验证检查诊断。`compile` 或 `run` 成功无法验证已被擦除的类型计算。

已有最小回归可帮助重新建立上下文：[template_pair](../test/cases/hints/template_pair.thlua)、[dollar_type](../test/cases/hints/dollar_type.thlua)、[template_reject](../test/cases/types/template_reject.thlua) 分别展示模板、跨空间取类型以及“编译成功但检查报错”。正式测试及预期维护方式见 [测试指南](../test/README.md)。

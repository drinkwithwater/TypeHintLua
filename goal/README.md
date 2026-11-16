# 类型系统重构：问题、复现与保护用例

本文对应 Union、TypeSet、类型关系接口的重构讨论，记录可执行代码、当前结果及迁移约束。所有文件都位于 `goal/`，本次仅建立问题档案，没有修改类型系统实现。

## 运行方式

在仓库根目录运行，需要 Python 3.10+ 标准库及已构建的 thlua：

```sh
cargo build --locked
python goal/run.py
python goal/run.py --binary target/release/thlua.exe
python goal/run.py --filter G09
python goal/run.py --list
python goal/run.py --strict
```

Linux/macOS 使用 `python3` 和不带 `.exe` 的可执行文件。验证 release 前先运行 `cargo build --release --locked`。修改 `thlua/` 后必须重建，因为程序使用嵌入源码。

也可单独执行：

```sh
target/debug/thlua.exe run goal/01_stale_atom_result.lua
target/debug/thlua.exe run goal/09_union_intersection_drops_overlap.lua
```

这些 `.lua` 文件调用检查器内部 API，应使用 **run**，不是 check。它们不是普通应用的类型错误样例；单独运行 G01/G02/G03/G09 时，当前会按正确性断言返回退出码 1。

[run.py](run.py) 按 [cases.json](cases.json) 在独立进程中执行每个文件，清空 Lua 模块搜索环境，固定工作目录，并设置 25 秒超时：

- `REPRODUCED`：已知缺陷命中指定的 `Gxx:` 断言，同时出现预期观察输出。任意其他异常不能算复现成功。
- `PASS`：正常行为保护或风险观察符合文档；不表示观察到的接口设计已经理想。
- `ERROR`：非预期错误、超时或输出变化。
- `UNEXPECTED_PASS`：已知缺陷脚本意外通过，需要检查实现变化并更新档案。

默认模式在“已知问题按记录复现，其他代码通过”时返回 0；`--strict` 在任何已知缺陷仍然复现时返回 1。非预期结果始终返回 1，空筛选返回 2。修复后应更新相应代码和清单，不能靠扩大异常匹配掩盖问题；若新接口直接禁止某种操作，也应调整契约后再验证。

[支持代码](support.lua) 用 `TestCase.new("")` 初始化真实 CodeRuntime、TypeManager 和标准声明，再在注册的 HintTask 中运行探针，允许正常调度等待。除 G14 明确模拟未来代理外，均使用工程实际类型，不用伪造类型对象代替实现。初始化失败、未完成的依赖均会导致失败。

## 问题与代码索引

| 编号 | 对应代码 | 分类 | 当前观察 |
| --- | --- | --- | --- |
| G01 | [01_stale_atom_result.lua](01_stale_atom_result.lua) | 已确认接口缺陷 | 添加 String 后集合有 2 个成员，结果仍为 Integer |
| G02 | [02_stale_union_result.lua](02_stale_union_result.lua) | 已确认接口缺陷 | 向 Integer/String 集合添加 Nil，结果仍不可空 |
| G03 | [03_frozen_members_escape.lua](03_frozen_members_escape.lua) | 已确认封装漏洞 | 外部修改冻结集合，实际 1 个成员，缓存仍为 2 |
| G04 | [04_set_identity_vs_union.lua](04_set_identity_vs_union.lua) | 正常行为保护 | 不同成员集合可规范化为同一类型 |
| G05 | [05_hash_collision_guard.lua](05_hash_collision_guard.lua) | 正常行为保护 | 不同集合发生哈希碰撞，仍正确区分并驻留 |
| G06 | [06_intern_hit_allocation.lua](06_intern_hit_allocation.lua) | 性能结构观察 | 5 次缓存命中仍创建 5 次 FrozenTypeSet |
| G07 | [07_containment_witness.lua](07_containment_witness.lua) | 接口契约保护 | includeAtom 返回匹配类型，不能按布尔值接口处理 |
| G08 | [08_intersection_protocol.lua](08_intersection_protocol.lua) | 接口契约保护 | false 与 Never 在 safeIntersect 中含义不同 |
| G09 | [09_union_intersection_drops_overlap.lua](09_union_intersection_drops_overlap.lua) | 已确认计算缺陷 | 联合分支有交集，safeIntersect 却返回 Never |
| G10 | [10_union_can_wait.lua](10_union_can_wait.lua) | 调度前提观察 | checkedUnion 会等待，未注册任务的协程调用会异常 |
| G11 | [11_recursive_relation_guard.lua](11_recursive_relation_guard.lua) | 正常行为保护 | 递归等价、不兼容和重复查询当前保持一致 |
| G12 | [12_union_laws_guard.lua](12_union_laws_guard.lua) | 正常行为保护 | 基础 Union 规律及 nil/false 投影通过 |
| G13 | [13_cross_manager_identity.lua](13_cross_manager_identity.lua) | 所有权边界风险 | 故意混用两个管理器的同 ID 类型，只保留一个成员 |
| G14 | [14_proxy_identity_guard.lua](14_proxy_identity_guard.lua) | 代理迁移风险 | 模拟代理的值相等，但 table key 与类身份仍不同 |
| G15 | [15_mutated_relation_cache.lua](15_mutated_relation_cache.lua) | 可变性与失效风险 | 故意修改已发布结构后，缓存与重新比较结论不同 |

G01/G02/G03 的异常输入来自当前内部 API 允许的操作，不证明正常源码检查已经走到这些路径。G13/G15 刻意违反单管理器、完成构建后不再修改的隐含前提，应作为契约强化和未来增量检查的风险，不能冒充当前正常检查流程的缺陷。

## 1. 成员收集与最终结果缓存混合：G01、G02

实现位置：[HashableTypeSet](../thlua/type/HashableTypeSet.thlua) 的 `initFromAtom`、`initFromUnion`、`putAtom`，以及 [FrozenTypeSet](../thlua/type/FrozenTypeSet.thlua) 的构造和 `_buildType`。

`initFromAtom` / `initFromUnion` 保存 `_typeResult`，后续 `putAtom` 只更新成员、数量和哈希，没有清除结果。冻结时旧结果被复制，`_buildType` 直接返回旧类型。

G01 从 Integer 开始添加 String，正确结果应包含两者，当前遗漏 String。G02 从 Integer/String 开始添加 Nil，正确结果应可空，当前遗漏 Nil。

**建议约束：** 可变 Builder 不保存最终结果，或每次有效修改都使派生缓存失效；也可以显式终结 Builder，终结后拒绝修改。不要保留“成员已经变化但结果仍被当作有效”的中间状态。

## 2. 冻结集合暴露可写成员：G03

实现位置：[FrozenTypeSet](../thlua/type/FrozenTypeSet.thlua) 的 `getDict`、`getNum`、`getHash`；[HashableTypeSet](../thlua/type/HashableTypeSet.thlua) 的 `getDict` 也暴露内部存储。

G03 通过公开返回的 table 删除 String，再重新读取冻结集合，得到实际成员 1、缓存数量 2；`findAtom(String)` 也不再能找到它。哈希和可能已有的结果缓存同样没有失效途径。

代码允许未来实现拒绝修改，或返回不影响原集合的副本；断言检查的是再次读取的内部状态，而非要求外部副本必须不变。

**建议约束：** 对外提供只读迭代、成员查询、数量查询。成员不可变与允许延迟填充结果缓存是两回事；不能因存在缓存就放弃成员不可变的保证。

## 3. 成员身份、规范化与驻留职责：G04、G05、G06、G12

实现位置：[TypeManager](../thlua/type/TypeManager.thlua) 的 `unifyTypeSet`、`unifyAndBuild`、`unionUnifyToType`，[TypeCollection](../thlua/type/TypeCollection.thlua)，以及 [ObjectUnion](../thlua/type/union/ObjectUnion.thlua)、[FuncUnion](../thlua/type/union/FuncUnion.thlua)。

### G04：集合不同不代表类型语义不同

`{Integer, Literal(1)}` 与 `{Integer}` 是不同的成员集合，最终都可规范化成 Integer。同样，“findAtom 找不到 Literal(1)”不表示 Integer 不包含 Literal(1)。重构中若以集合身份直接决定类型兼容性，就会产生错误。

### G05：哈希相同不代表成员相同

探针用真实字面量类型构造两个不同集合，找到当前 sum/xor 哈希的碰撞，然后验证完整成员比较和重复驻留仍正确。**当前冲突处理在这个例子中是正确的。** 将实现迁入 Rust 或替换哈希算法时，不能把完整相等比较删掉。若新哈希不再产生此例碰撞，应更新构造方式，而非把“未找到碰撞”视为语义失败。

### G06：缓存命中前仍分配并复制集合

对同一个 Builder 驻留 5 次，复用结果的同时仍调用 `frozen()` 5 次。脚本仅临时包装该方法计数，随后恢复原方法。这是避免分配的优化机会，**不是耗时基准，也没有证明实际性能瓶颈或加速倍数。** 优化后应更新该观察。

### G12：集中规范化必须保留的规律

检查空联合为 Never、单成员与重复成员消除、Integer 吸收整数 Literal、基础类型的交换与结合，以及可空、真假分支投影。等价关系用双向包含检查，不一概要求对象身份相同。这些用例没有证明所有对象、函数或 Open/Auto 类型都可按相同方式化简。

**建议边界：** 集合只处理成员身份；Normalizer 处理语义化简；Interner 负责共享表示和冲突桶。保留必要的 Union 专门表示，把创建与驻留入口收拢，不必立即删除所有 Union 子类。`unify` 在这里主要表示驻留复用，可考虑使用 `intern` 命名。

## 4. 类型关系返回值和递归上下文：G07、G08、G09、G11

实现位置：[BaseReadyType](../thlua/type/basic/BaseReadyType.thlua)、[Interface](../thlua/type/object/Interface.thlua)、[TypeRelation](../thlua/type/TypeRelation.thlua)、[RefineTerm](../thlua/term/RefineTerm.thlua) 的 `includeAtomCase` / `filter`。

### G07：包含判断与匹配见证不能混用

`Integer:includeAll(Literal(1))` 返回 true；`Integer:includeAtom(Literal(1))` 返回 Integer 对象。错误地写成 `includeAtom(...) == true` 会漏掉匹配，统一返回 bool 又会丢掉 RefineTerm 查询分支事实所需的类型键。

### G08：三种相交结果不是统一的布尔值

对 A=`Interface{x=Integer}`、B=`Interface{y=String}`：A 与 B 可以同时成立，`intersectAtom` 返回 true，表示非空但没有具体可返回的类型；`safeIntersect` 返回 false。Integer 与 String 不相交时，`intersectAtom` 返回 false，但 `safeIntersect` 返回 Never。Integer 与 Literal(1) 的具体交集则返回 Literal(1)。

同一探针也记录 `checkedIntersect(A,B)` 当前抛出 `unexpected intersect`。因此不能把 `not safeIntersect(...)` 解读为“不相交”，也不能把所有操作都包装成“始终返回类型”。

### G09：联合分支丢失不可表示交集

沿用 G08 的 A、B，计算 A 与 `Union(B,Nil)`：

```text
A:intersectAtom(B)                 = true
A:intersectSome(Union(B,Nil))      = true
A:safeIntersect(Union(B,Nil))     = Never  （当前错误结果）
```

`safeIntersect` 遍历联合时，遇到 true 只返回当前回调，没有保留“存在不可表示交集”的状态。Nil 分支又没有具体交集，最终按空集合构建出 Never。正确结果至少不能是 Never；可以保留无法表示状态，或由未来算法构造准确交集。探针没有强制要求未来必须继续返回 false。

### G11：递归假设不能成为最终证明

分别建立两个同形递归 Interface 和一个字段类型不兼容的递归 Interface。验证同形者双向包含，不兼容者在两方向均被拒绝，重复失败查询也不污染后续正确结果。当前通过，是必须保留的保护，不是已发现递归算法错误。

**建议边界：** 用明确结果区分空集、具体交集、不可表示交集；匹配见证与布尔判断分别提供接口；将递归的临时假设封装在 QueryContext 中，与最终缓存分离。依赖未完成的 Pending 状态另外表达。

## 5. 类型运算隐藏调度前提：G10

实现位置：[TypeManager](../thlua/type/TypeManager.thlua) 的 `checkedUnion` / `buildUnion`，[BaseTypeCom](../thlua/space/BaseTypeCom.thlua) 的 `checkAtomUnion`，[ScheduleEvent](../thlua/schedule/ScheduleEvent.thlua) 的 `wait`。

探针构造一个尚未完成的 AsyncTypeCom。在普通但未注册的协程中调用 checkedUnion，当前遇到 `nCurTask` 为 nil 的异常；在合法 HintTask 中，同样操作会等待，观察顺序为 `before,resolved,after`。

这是内部 API 的前提风险，不是“支持任意协程调用却实现失败”的主张。迁入普通 Rust 回调时若沿用隐式等待，很容易打破这个前提。

**建议边界：** 明确区分只接受就绪类型的核心运算与可等待的 Resolver。递归引用的占位、成员集合就绪、最终结果就绪仍须分别处理，不能简单地等待所有递归子类型全部完成。

## 6. 所有权、代理身份和未来缓存失效：G13、G14、G15

### G13：TypeId 只在一个 TypeManager 内有效

实现位置：[TypeManager](../thlua/type/TypeManager.thlua) 的 `genTypeId`，[HashableTypeSet](../thlua/type/HashableTypeSet.thlua) 的 `putAtom`。

两个独立管理器可以产生相同 ID 的不同字面量，故意将它们放入同一个集合时会按 ID 去重，只剩一个成员。当前正常检查应避免混用管理器；未来持久化或跨检查复用句柄时，应带 EngineId/代次并检查所有权，不能仅凭整数 ID 判断身份。

### G14：代理值相等不等于 table key 或类身份相同

关联实现：[class.thlua](../thlua/class.thlua) 的 metatable 类判断，[RefineTerm](../thlua/term/RefineTerm.thlua) 和多个 Type 字典的对象键。

脚本用两个 Lua table **模拟**未来相同原生 ID 的不同代理，故意让 `__eq` 返回 true；两者仍不是同一个 table key，也不具有旧类的 metatable。这里没有声称当前 Rust 已实现这些代理。

未来应缓存并复用同一代理，或统一改用带所有权的键，同时适配 Class.is 和 `type(...) == "table"` 等判断。

### G15：结构改变后旧关系缓存不再有效

实现位置：[TypedObject](../thlua/type/object/TypedObject.thlua) 的 `getValueDict`，[TypeManager](../thlua/type/TypeManager.thlua) 的 `_pairToRelation` / `attachPairRelation`。

先比较两个 `{value=Integer}` Interface 得到相等，再**故意修改**右侧已发布结构为 `{value=String}`。缓存查询仍返回 true，绕过该对象对缓存重新比较则返回 false。

这不是受支持的文档编辑入口，不证明当前 LSP 会直接修改已发布类型；它说明未来增量检查不能一边修改同 ID 描述，一边继续使用旧关系缓存。应采用新的不可变描述，或设计版本和传递依赖失效，推导状态与稳定类型分开存放。

## 验证记录与后续使用

2026-11-17，本目录探针在 Windows 的现有 Debug 与 Release 可执行文件上验证。当前清单共 15 项：4 项指定缺陷复现，11 项契约保护或风险观察符合记录；没有非预期结果。严格模式按设计返回非零。

这些例子覆盖的是本次接口重构讨论，未证明整个类型系统正确，也不替代 `python test.py` 的正式语言、CLI 和 LSP 套件。后续修复应将稳定的正确性回归逐项纳入正式套件，保留这里的原因、原始触发条件和对应代码路径。

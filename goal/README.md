# 类型系统问题与回归清单

本目录保留类型接口、Union、TypeSet 和递归关系的问题触发条件与保护用例。2026-11-17 已完成针对这些问题的核心重构；当前 19 个探针均为正确性保护，严格模式无已知缺陷复现。设计取舍、运算契约、源码审查范围及未覆盖边界见 [类型与类型集合运算](../docs/type-algebra.md)。

## 运行

```sh
cargo build --locked
python goal/run.py --strict
python goal/run.py --filter G09
python goal/run.py --list
python test.py
python test.py --release
```

使用现有发布程序时先 `cargo build --release --locked`，再执行 `python goal/run.py --binary target/release/thlua.exe --strict`。Linux/macOS 使用 `python3` 和不带 `.exe` 的程序。修改 `thlua/` 后必须重建嵌入源码。

这些脚本调用真实检查器内部 API，使用 **run** 而非 check。`support.lua` 初始化 CodeRuntime、TypeManager 和标准声明，在注册 HintTask 中执行，允许正常等待并拒绝未完成依赖。G14 是未来代理的模拟，其余类型均来自真实管理器。

[run.py](run.py) 按 [cases.json](cases.json) 逐进程运行，清空 Lua 搜索环境并设置 25 秒超时。所有探针已纳入正式入口的 `test/test_type_algebra.py`；正式测试将脚本和 support 复制到隔离目录，验证实际嵌入实现。任意异常、超时和观察输出缺失均失败。旧 runner 保留已知缺陷分类能力，当前清单没有该类条目；不得通过放宽匹配隐藏后续失败。

## 原始问题及当前契约

| 编号 | 脚本 | 原始问题/保护 | 当前结果 |
| --- | --- | --- | --- |
| G01 | [01_stale_atom_result.lua](01_stale_atom_result.lua) | 从 Integer 开始添加 String 后仍返回旧结果 | Builder 不再缓存结果，保留两个类型 |
| G02 | [02_stale_union_result.lua](02_stale_union_result.lua) | 向 Integer/String 添加 Nil 后仍不可空 | 正确生成可空联合 |
| G03 | [03_frozen_members_escape.lua](03_frozen_members_escape.lua) | 删除公开字典成员破坏数量及哈希一致性 | `getDict` 返回快照，冻结成员不受影响 |
| G04 | [04_set_identity_vs_union.lua](04_set_identity_vs_union.lua) | 不同成员集合可规范化为同一 Integer | 保留身份驻留与语义化简的区别 |
| G05 | [05_hash_collision_guard.lua](05_hash_collision_guard.lua) | 相同哈希不代表同一集合 | 冲突桶完整比较成员，重复驻留正确 |
| G06 | [06_intern_hit_allocation.lua](06_intern_hit_allocation.lua) | 5 次缓存命中仍冻结、复制 5 次 | 命中先比较 Builder，新增冻结次数为 0 |
| G07 | [07_containment_witness.lua](07_containment_witness.lua) | includeAtom 返回类型见证而非 Boolean | 增加 containsAtom 与 findCoveringAtom，兼容旧见证接口 |
| G08 | [08_intersection_protocol.lua](08_intersection_protocol.lua) | false 与 Never 在交集中意义不同 | 新结果明确 empty/exact/overlap；旧协议保留适配 |
| G09 | [09_union_intersection_drops_overlap.lua](09_union_intersection_drops_overlap.lua) | 联合分支丢弃不可表示交集，错误得到 Never | 保留 overlap，safeIntersect 返回 false |
| G10 | [10_union_can_wait.lua](10_union_can_wait.lua) | 未注册协程等待时发生 nil task 异常 | ready 操作禁止等待；Resolver 合法等待，非法调用明确报错 |
| G11 | [11_recursive_relation_guard.lua](11_recursive_relation_guard.lua) | 递归等价、不兼容和重复查询保护 | 独立 QueryContext 保留这些行为 |
| G12 | [12_union_laws_guard.lua](12_union_laws_guard.lua) | Union 基础规律、nil/false 投影 | 保护继续通过 |
| G13 | [13_cross_manager_identity.lua](13_cross_manager_identity.lua) | 故意混用同 ID 的不同管理器类型会静默丢失成员 | 插入、驻留、运算和缓存键明确拒绝混用 |
| G14 | [14_proxy_identity_guard.lua](14_proxy_identity_guard.lua) | 模拟代理虽 __eq 相等，table key 和类身份仍不同 | 保留真实 Lua 对象及类身份；未引入代理 |
| G15 | [15_mutated_relation_cache.lua](15_mutated_relation_cache.lua) | 故意修改已发布字段后缓存与新比较不一致 | 字段返回快照、发布输入复制、重复发布拒绝；修改使用新描述 |

G01/G02/G03 原始触发来自旧内部 API 允许的操作，不证明原本已有普通源码走到这些路径。G13/G15 原来刻意违反单管理器和发布后稳定的隐含前提；现在把前提落实为可执行契约。G06 检查分配次数，不是时间基准或加速倍数。

## 扩展保护

| 编号 | 脚本 | 覆盖 |
| --- | --- | --- |
| G16 | [16_identity_set_algebra.lua](16_identity_set_algebra.lua) | 身份集合并、交、差、包含、空集、快照及只读迭代；区别于语义子类型 |
| G17 | [17_intersection_algebra.lua](17_intersection_algebra.lua) | 基础交集对称、吸收和分配律；未知交集与具体 Nil 分支并存时不得丢失 |
| G18 | [18_query_context_isolation.lua](18_query_context_isolation.lua) | 包含/相交假设隔离，路径退出与异常清理，递归不兼容保护 |
| G19 | [19_function_union_relations.lua](19_function_union_relations.lua) | 函数联合空交集、参数逆变/返回协变、AnyFunction 吸收、单成员规范化及已发布联合不可修改 |

源码级用例 `test/cases/types/interface_union_overlap.thlua` 验证互不包含但有交集的 Interface 可以组成联合、接受两种实参、生成可加载 Lua 并保持正常执行。

## 契约说明

`{Integer, Literal(1)}` 和 `{Integer}` 的集合身份不同，但最终类型可以相同。身份集合的 intersectSet/subtractSet 不等于类型交集/语义差集。包含判断返回 Boolean，覆盖分支查询返回类型见证，供 RefineTerm 保存条件事实。

对于 A=`Interface{x=Integer}`、B=`Interface{y=String}`，当前算法仍不能返回一个准确的通用交集类型，使用 overlap 明示该限制。`safeIntersect(A,B)` 的兼容结果为 false；Integer 与 String 的结果为 Never；Integer 与 Literal(1) 的结果为 Literal(1)。`checkedIntersect` 只接受可表示结果，不在 overlap 时伪造类型。

递归名字占位、成员集合就绪和最终规范化结果就绪仍分阶段处理。ready 操作不仅拒绝 AsyncTypeCom，还会拒绝隐藏的未完成结构依赖；Resolver 则在注册任务内正常等待。没有将递归引用全部提前展开，也没有迁入 Rust 或引入代理。

类型描述及已发布联合通过公开 API 保持稳定，Open/Auto 的推导状态继续独立推进。未实现跨检查缓存复用、增量依赖失效或任意交叉类型；不要把本目录通过解读成所有语言类型行为都已得到证明。

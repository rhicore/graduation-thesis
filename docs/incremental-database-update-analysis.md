# 数据库变动下的增量更新能力分析

本文讨论五种 Text-to-SQL 方法在数据库结构和数据内容发生变动时的增量更新潜力。这里的“增量更新”不指新增自然语言 query，而是指底层数据库本身发生演化后，系统是否能够局部刷新已有预处理资产，而不是重新执行完整预处理或完全依赖运行时重新探索。

## 1. 问题定义

真实业务数据库通常不是静态 benchmark。数据库变动可以分为几类：

| 变动类型 | 示例 | 对 Text-to-SQL 的影响 |
|---|---|---|
| Schema drift | 新增/删除表、列改名、类型变化、外键变化 | 影响 schema linking、JOIN path、列选择和 SQL 可执行性。 |
| Value drift | 新增枚举值、实体名、代码值、地址、状态值 | 影响 value retrieval、文本匹配、过滤条件落点。 |
| Distribution drift | 行数、top-k、distinct count、NULL 比例变化 | 影响 sample/topk、去重判断、聚合粒度、异常值判断。 |
| Semantic drift | 同一列业务含义改变，代码值口径改变 | 影响列/表 description、README、hint、disambig 等语义资产。 |
| Relationship drift | 关系覆盖率、join cardinality、桥表含义变化 | 影响 JOIN 选择、聚合前粒度和结果重复。 |

对增量更新能力的评价重点不是“是否能在新数据库上跑”，而是：

1. 能否定位哪些预处理资产受影响；
2. 能否只刷新受影响的表、列、值索引、语义节点或 embedding；
3. 能否保留未受影响的稳定知识；
4. 能否避免 stale metadata 继续误导 SQL agent；
5. 能否把数据库长期演化转化为可维护的语义资产，而不是每次从零开始。

## 2. 五种方法的增量更新潜力

### BashAgent

BashAgent 几乎没有持久化预处理资产。数据库结构或内容变动后，它不需要刷新索引、图谱、README 或 embedding，直接在新数据库上运行即可。

这种设计的增量维护成本最低，但它的低成本来自“不维护知识”。数据库变化不会造成 stale index 问题，但也无法复用稳定的列语义、表粒度、join consequence、枚举解释和历史探索结论。换言之，BashAgent 把数据库演化成本转移到了每次查询时的运行时探索中。

### CHESS

CHESS 的数据库侧预处理主要体现为 schema/value 相关检索资源，尤其是 embedding/vector index。未来如果要支持数据库增量更新，较自然的方向是以数据库或列为粒度刷新索引。

当 schema 发生变化时，受影响的表、列、外键和对应向量表示需要重建。当数据内容变化时，如果只是少量事实行变化，旧索引可能仍然可用；但如果文本值集合、枚举值、样例值或列统计明显变化，value retrieval 会受到影响，需要刷新对应列或数据库的索引。

CHESS 的优势是预处理资产相对单纯，增量更新边界比较清楚；局限是它缺少更丰富的语义图谱和知识节点，能局部刷新的主要是 retrieval index，而不是高层语义解释。

### DeepEye-SQL

DeepEye-SQL 对 value-level vector database 的依赖更重。它的 schema linking 和 value retrieval 依赖数据库内容索引，因此数据库内容变化会比 CHESS 更直接地影响检索结果。

如果 schema 变化，必须刷新相关 schema/value index。如果数据内容变化涉及实体名、地址、类别、代码、状态值等文本值，则即使 schema 不变，也需要更新对应向量库。DeepEye-SQL 的增量更新潜力主要在于把 vector DB 从 database-level rebuild 改造成 table-level 或 column-level rebuild：当某个表或列发生变化时，只删除并重建该局部索引。

它的局限是 value index 很重，且语义解释多分散在 prompt 和 pipeline 中。数据库长期演化时，它能较好刷新“可检索值”，但不天然维护“为什么这个字段应该这样用”的可解释知识资产。

### Alpha-SQL

Alpha-SQL 同时依赖 schema/value 索引、LSH/value retrieval 和搜索式 SQL 生成流程。数据库结构变化时，需要刷新 schema/value 相关索引；数据库内容变化时，如果影响文本值、枚举值或相似值匹配，也需要更新 LSH 和 embedding 资源。

Alpha-SQL 的增量更新潜力在于把预处理拆成 schema index、value index、LSH index 和 question-independent retrieval assets。对数据库变动而言，最理想的设计是只更新受影响表/列对应的 value candidates，而不是重跑全库预处理。

但 Alpha-SQL 的主要优势在 test-time search，而不是数据库知识资产维护。它可以局部刷新索引，但难以像图谱系统一样显式表达“某个表的一行粒度是什么”“某条 join 会扩行还是补属性”“某两个近义列如何区分”等可维护知识。

### Pontis

Pontis 的预处理成本最高，但它的设计目标也最接近数据库长期演化下的增量更新。Pontis 并不是只生成一次性 prompt，而是把数据库结构、统计、语义解释、关系、hint、disambig、README 和 embedding 都写入统一的图谱工作空间。

从现有系统结构看，Pontis 已经预留了多层增量更新 hook：

| 设计点 | 增量更新意义 |
|---|---|
| Source module trigger | `Workspace.cypher(...)` 在查询前通过 trigger router 选择需要刷新的 source module。 |
| Source fingerprint | source module 可以用文件 mtime/size 等 fingerprint 判断源事实是否已新鲜，避免无意义刷新。 |
| `refresh_sources(...)` | 支持显式强制刷新指定 source module。 |
| Cypher `MERGE` 写入 | schema module 以 `_ref`、`path`、外键端点等稳定 key 做幂等写入，天然支持重复刷新。 |
| Extractor registry | 预处理阶段按模块注册和执行，可以拆分为 stats、summary、hints、README、embedding 等局部 pass。 |
| `update_meta` / `create_entity` / `add_edge` | agent 和 explorer 可以局部修改图谱节点、边和元数据。 |
| `semantic_embedding` hash | embedding 以 `detail_embedding_hash`、model、dimension 判断是否需要重算，适合只重嵌入变化节点。 |
| scoped ref | 表、列、fk 使用数据库作用域内稳定 ref，便于定位受影响实体。 |

这些设计意味着 Pontis 的未来增量更新不必以“重跑整个数据库 extract”为唯一方式。更理想的流程是：

1. 检测数据库变动，生成 table/column/value/change set；
2. 刷新 source-derived schema nodes；
3. 将受影响节点标记为 dirty；
4. 只重算受影响列的统计、sample、topk、overlap、fk validation；
5. 只重写受影响表/列的 brief/detail/hints；
6. 只更新相关 rel/disambig/hint/README 片段；
7. 只对 detail hash 变化的节点重算 embedding；
8. 保留未受影响的人工或 agent 生成知识。

因此，Pontis 的优势不是当前全量 extract 成本低，而是它把预处理结果组织成可定位、可覆盖、可连接、可重嵌入的数据库语义资产。只要后续补齐 dirty tracking、provenance 和依赖传播，Pontis 可以把 database drift 处理成图谱节点级或子图级更新问题。

## 3. Pontis 的未来增量更新模型

Pontis 可以把数据库变动拆成四层处理。

### 3.1 结构层更新

结构层包括数据库文件、表、列、视图、外键和基础边。它们通常来自 source module，而不是 LLM。

未来可以维护：

- database fingerprint：文件级 mtime、size、schema hash；
- table fingerprint：列名、类型、主键、外键、row count sketch；
- column fingerprint：类型、NULL 比例、distinct sketch、sample/topk hash；
- relationship fingerprint：外键定义、join match rate、overlap score。

当 schema drift 出现时，只刷新结构变化涉及的节点和边。删除列或表时，不应立即物理删除所有关联知识，而应先标记 stale，等待依赖分析确认哪些 hint、rel、disambig 和 README 片段仍然有效。

### 3.2 统计和值层更新

统计和值层包括 sample、topk、cardinality、null_percentage、overlap、value index。它们对数据内容变化敏感，但通常不需要 LLM。

未来可以支持：

- 对 changed columns 重新计算 sample/topk/cardinality；
- 对 changed text columns 重新生成或更新 value embedding；
- 对 join key columns 重新计算 overlap 和 match rate；
- 对稳定列跳过统计刷新；
- 对高频变动事实行只更新 sketch，而不重扫全表。

这一层的目标是降低 value drift 对 retrieval 的影响，同时避免全库扫描。

### 3.3 语义层更新

语义层包括 table/column brief/detail、hints、rel、disambig、README。它们最容易因为 stale metadata 误导 SQL agent，也是 Pontis 区别于普通 vector index 的核心资产。

未来可以把语义节点加上 provenance：

- 来源节点：该 summary/hint/disambig 依赖哪些 table、column、sample、topk、query evidence；
- 生成时间和模型；
- source fingerprint；
- confidence；
- 是否人工确认；
- 是否允许自动覆盖。

当某个列的 value/topk/schema 变化时，只把依赖该列的语义节点标为 dirty。然后根据风险分级决定处理方式：

| 风险 | 处理策略 |
|---|---|
| 低风险，如 row count 小幅变化 | 保留语义，更新统计字段即可。 |
| 中风险，如 topk/枚举值变化 | 重审相关 column detail/hints。 |
| 高风险，如列改名、类型变化、业务代码重定义 | 标记相关 hint/disambig/README 片段 stale，要求 agent 重写。 |
| 极高风险，如表粒度或 join cardinality 变化 | 重跑该表邻域的 schema_prepare/entity_hints。 |

### 3.4 Embedding 层更新

Pontis 当前 semantic embedding 已经使用 detail hash、model 和 dimension 判断是否需要重算。未来只要所有语义写入都维护稳定 detail hash，embedding 增量更新可以自然成立：

```text
if detail_hash unchanged:
    keep old vector
else:
    re-embed this node only
```

这使 Pontis 的 embedding 更新粒度可以达到 node-level，而不是 database-level。相比 DeepEye-SQL 这类 value vector DB，Pontis 的语义 embedding 更适合长期维护，因为它绑定的是图谱节点和可解释 metadata，而不是单纯的原始值集合。

## 4. 与其他方法的核心差异

| 方法 | 增量更新对象 | 最小合理刷新粒度 | 长期维护潜力 |
|---|---|---|---|
| BashAgent | 无持久化资产 | 无需刷新 | 低。灵活但不积累数据库语义。 |
| CHESS | schema/value retrieval index | database 或 column | 中。适合刷新索引，不擅长维护解释性知识。 |
| DeepEye-SQL | value-level vector DB | database/table/column | 中。value drift 处理能力强，但索引重。 |
| Alpha-SQL | schema/value/LSH assets | table/column/value index | 中。可局部刷新检索资产，但语义资产较弱。 |
| Pontis | 图谱节点、统计、关系、hint、README、embedding | node/subgraph | 高。全量成本高，但最适合演化为可维护语义资产系统。 |

从数据库变动角度看，Pontis 和其他方法的差异不只是“预处理重不重”，而是预处理结果是否有结构化生命周期。CHESS、DeepEye-SQL 和 Alpha-SQL 的预处理更像 index：数据库变了，就判断哪些索引需要重建。Pontis 的预处理更像 knowledge base：数据库变了，需要判断哪些知识仍然有效、哪些知识过期、哪些知识可以局部重写。

## 5. 论文可用论述

可以在论文中这样表述：

> 从数据库结构和内容变动的角度看，BashAgent 几乎没有增量维护问题，但这是因为它没有持久化数据库语义资产。CHESS、DeepEye-SQL 和 Alpha-SQL 主要面对索引刷新问题，即 schema/value/embedding/LSH 等检索资源如何随数据库变化局部重建。Pontis 面对的问题更复杂，但也更有长期潜力：它将数据库结构、统计、语义解释、关系、消歧提示、README 和 embedding 统一组织为图谱化工作空间。只要为图谱节点补充 provenance、dirty flag 和依赖传播机制，数据库变动就可以被转化为局部子图更新，而不是全量重跑。

更进一步，可以强调：

> Pontis 的全量 extract 成本不应只被视为一次性开销，而应被理解为构建数据库语义资产的成本。对于长期稳定但持续演化的业务数据库，理想的系统不应在每次结构或内容变化后丢弃已有知识，而应识别变动影响范围，保留未受影响的语义节点，只重算受影响的统计、hint、README 片段和 embedding。相比传统 pipeline baseline，Pontis 的图谱化架构为这种细粒度增量更新提供了更自然的表达空间。

## 6. 后续实现方向

为了把这种潜力落地，Pontis 后续可以补齐以下机制：

1. **Change detector**：为数据库文件、表、列和值集合计算 fingerprint，输出结构化 change set。
2. **Dirty flag**：在节点上维护 `dirty_reason`、`dirty_at`、`source_fingerprint`、`stale` 等字段。
3. **Provenance graph**：为 summary、hint、disambig、README 片段记录依赖的 source nodes。
4. **Dependency propagation**：表/列变化后，将依赖它们的知识节点标记为待审计。
5. **Partial extractor**：允许按 table、column、subgraph 执行 stats、summary、hints、embedding。
6. **Stale-safe query mode**：SQL agent 读取到 stale metadata 时，要么降权使用，要么触发后台 refresh。
7. **Human-confirmed knowledge lock**：人工确认的知识默认不自动覆盖，只在依赖源强冲突时提示复审。
8. **README section-level update**：把 README 拆成可定位片段，避免单列变化导致整篇 README 重写。
9. **Embedding node-level refresh**：继续利用 detail hash，只重嵌入变化节点。
10. **Evaluation protocol**：构造数据库 drift benchmark，比较全量重跑、局部刷新和不刷新三种策略的准确率与成本。

这套方向能把 Pontis 从“高成本预处理 + 高质量查询”进一步推进到“长期维护数据库语义资产 + 低成本增量刷新”的系统。

# 研究问题与有效性威胁

本文的目标不是单纯提出一个新的 Text-to-SQL prompt，而是研究图谱化项目工作空间能否改善大语言模型智能体在真实数据库理解任务中的稳定性、可解释性和长期维护能力。因此，实验设计应围绕系统问题展开，而不只是报告最终执行准确率。

## 1. 研究问题

### RQ1：图谱化工作空间是否提升 Text-to-SQL 准确率？

该问题比较 Pontis 与只提供 shell、sqlite 和文件访问能力的 BashAgent。二者都依赖通用大语言模型和工具调用，但 Pontis 额外维护数据库图谱、列统计、元数据摘要、README、hint、disambig 和 SQL 护栏。

如果 Pontis 相比 BashAgent 有稳定提升，说明图谱化数据工作空间确实提供了超出通用工具访问的价值。该对比也比直接与 CHESS、DeepEye-SQL、Alpha-SQL 比较更能体现 Pontis 自身设计的边际贡献，因为 BashAgent 可以视为“无图谱工作空间”的工具智能体下限。

本文当前实验中，Pontis 在 BIRD dev 上达到 65.38% 执行准确率，而 BashAgent 为 60.04%，提升 5.34 个百分点。

### RQ2：Pontis 的提升主要来自哪些错误类型？

总体准确率只能说明系统是否更接近 benchmark 标注，但不能解释系统为什么有效。为此，本文将 BashAgent 的错题分为三类：

- `GOLDEN_SQL_STYLE`：输出列、排序、比例、格式、DISTINCT 等 BIRD 风格或 golden SQL 口径不一致；
- `DATASET_PRIOR_REQUIRED`：需要数据集或 benchmark 口径先验，仅靠当前 query 和数据库难以稳定推出；
- `DB_EXPLORATION_FIXABLE`：理论上可通过更充分的 schema/value grounding、数据库探索或 join path 验证修复。

实验结果显示，Pontis 在 `GOLDEN_SQL_STYLE` 和 `DB_EXPLORATION_FIXABLE` 上的补对率都约为 31%，但在 `DATASET_PRIOR_REQUIRED` 上补对率只有 8.6%。这说明 Pontis 的主要价值在于增强数据库探索、输出契约约束和局部语义 grounding，而不是凭空恢复 benchmark 隐藏先验。

### RQ3：图谱化上下文的 token 成本是否能被 prompt cache 摊薄？

Pontis 是多轮工具智能体，每轮都会携带系统提示词、工具定义、图谱 ontology、项目 README、BIRD README 和工具历史。因此，Pontis 的 total input tokens 明显高于传统 pipeline baseline。

但 total tokens 不能直接等价于商业 API 成本。对于支持 prompt cache 的 provider，稳定前缀会被计入 cached input，成本远低于 uncached input 和 output。本文因此单独统计：

- LLM rounds；
- cached input tokens；
- uncached input tokens；
- output tokens；
- total tokens；
- 预处理成本；
- 按 `cached:uncached:output = 0.02:1:2` 计算的加权成本。

结果显示，Pontis 的 cached input 很高，但 uncached input 和 output 并没有同比例升高。即使将 full extract 预处理成本按 1534 道题摊销，Pontis 的每题加权成本约为 18.7k，仍低于 DeepEye-SQL、CHESS 和 Alpha-SQL。

### RQ4：Pontis 是否比 pipeline baseline 更适合数据库长期演化？

真实数据库会持续发生 schema drift、value drift、distribution drift 和 semantic drift。CHESS、DeepEye-SQL 和 Alpha-SQL 的预处理结果主要是 schema/value index 或搜索 pipeline 的中间资产；数据库变化后，通常需要判断哪些索引需要重建。

Pontis 的预处理结果则是图谱化语义资产，包括表列节点、统计、关系、hint、disambig、README 和 embedding。理论上，这些资产可以通过 dirty flag、provenance 和依赖传播进行局部刷新。因此，Pontis 的全量 extract 成本不应只被视为一次性负担，也可以被理解为构建长期可维护数据库语义层的成本。

## 2. 实验假设

本文实验可以对应以下假设：

| 假设 | 内容 | 验证方式 |
|---|---|---|
| H1 | 图谱化工作空间能提高通用工具智能体的 Text-to-SQL 准确率。 | Pontis vs BashAgent 总体准确率。 |
| H2 | Pontis 的提升主要来自可通过探索和 SQL 护栏修复的错误。 | BashAgent 错题三分类迁移分析。 |
| H3 | Pontis 的高 total input tokens 主要是可缓存上下文，而不是等价的高实际成本。 | cached / uncached / output token 拆分和加权成本。 |
| H4 | Pontis 的架构更适合未来数据库增量更新。 | 与 pipeline baseline 的预处理资产形态比较。 |

## 3. 有效性威胁

### 3.1 内部有效性

第一，本文没有完整消融实验。Pontis 包含图谱工作空间、列统计、README、hint、工具调用和护栏等多个组件，当前实验不能严格证明每个组件的独立因果贡献。当前结论更适合表述为系统级整体效果，而不是单个模块的精确定量贡献。

第二，不同 baseline 的实现路径不同。CHESS、DeepEye-SQL、Alpha-SQL 是专门 Text-to-SQL pipeline，而 Pontis 和 BashAgent 是工具智能体。它们的 LLM 调用轮次、prompt 组织方式、输出格式和执行选择机制不同，因此 token 成本和准确率差异并不完全来自单一变量。

第三，所有方法使用的本地复现配置未必等同于原论文最优配置。例如模型、并行度、embedding、本地 patch、运行参数都会影响最终结果。因此，本文更强调在统一本地实验环境下的系统对比，而不是声称复现了各 baseline 的公开最佳成绩。

### 3.2 外部有效性

第一，实验主要基于 BIRD dev。BIRD 包含真实数据库和 evidence 字段，但仍是固定 benchmark，不能完全代表企业数据库、权限系统、数据仓库 SQL 方言或多轮业务分析流程。

第二，BIRD 的 dev 数据库数量有限。当前实验覆盖 11 个数据库、1534 道题，能够反映跨库场景下的总体趋势，但仍不足以证明 Pontis 在所有数据库结构、规模和行业场景中都有效。

第三，本文实验主要使用 zero-shot / BIRD-adapted zero-shot 协议。真实企业系统常常可以利用历史 SQL、业务文档、数据目录和人工反馈，因而长期表现可能与静态 benchmark 不同。

### 3.3 构造有效性

第一，执行准确率不完全等价于业务正确性。同一自然语言 query 可能对应多种合理 SQL；执行结果比对仍然会受到输出列、排序、格式、聚合粒度、DISTINCT 和标注噪声影响。

第二，token 成本中的加权公式是近似口径。本文使用 `cached:uncached:output = 0.02:1:2` 只是为了模拟 prompt cache 下的相对成本，并不代表某一具体 API 的绝对价格。

第三，预处理成本的摊销依赖使用场景。如果同一数据库只回答少量问题，Pontis 的 full extract 成本会显得较高；如果同一数据库长期被反复查询，预处理成本会被更多问题摊薄。

### 3.4 结论有效性

第一，Pontis 与 DeepEye-SQL 的准确率差距很小。Pontis 为 65.38%，DeepEye-SQL 为 65.25%，只差 2 题。因此，不能过度强调 Pontis 在准确率上显著超过 DeepEye-SQL，更合理的结论是：Pontis 在准确率上达到与专门 baseline 相当的水平，同时提供了不同的资源结构和长期维护潜力。

第二，Pontis 的优势具有场景依赖性。对于一次性、低频、临时数据库查询，BashAgent 这类无预处理系统成本更低；对于长期稳定但持续演化的数据项目，Pontis 的图谱化语义资产才更有价值。

## 4. 可写入论文的总结段

本文实验回答的核心问题不是“Pontis 是否在 BIRD 上绝对最强”，而是“图谱化项目工作空间是否为 Text-to-SQL 智能体提供了可量化的系统价值”。实验结果表明，Pontis 相比 BashAgent 明显提升准确率，并在 BashAgent 的 SQL 风格错误和数据库探索错误上具有较强补救能力；相比 CHESS、DeepEye-SQL 和 Alpha-SQL，Pontis 达到相近甚至略高的执行准确率，同时通过 prompt cache 将长上下文成本大部分转化为低成本 cached input。与此同时，本文也承认当前实验缺少完整消融，且 BIRD 执行准确率受到 benchmark 口径和标注噪声影响。因此，Pontis 的贡献应被理解为一种面向项目级数据理解的系统架构，而不是单纯追求静态 Text-to-SQL 排行榜分数的方法。

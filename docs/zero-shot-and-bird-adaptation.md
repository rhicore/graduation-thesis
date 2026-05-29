# Zero-Shot 协议与 BIRD 数据集适配

本文实验采用 protocol-level zero-shot 设置：推理阶段不显式输入或检索 BIRD train 集中的 golden SQL，也不将 train 集样例作为 few-shot examples 提供给模型。但需要强调的是，这并不意味着所有方法都是完全 benchmark-agnostic 的 zero-shot。CHESS、DeepEye-SQL、Alpha-SQL 和 Pontis 都包含不同程度的 BIRD-specific engineering。

## 1. 为什么需要区分两种 zero-shot

Text-to-SQL 论文中常说的 zero-shot 通常指：测试时不给当前数据库或当前问题的标注 SQL 示例，模型需要直接根据 question、schema 和可用上下文生成 SQL。这个定义关注的是是否显式使用训练样例或 golden SQL。

但在现代 LLM-based Text-to-SQL 系统中，即使不使用 train golden SQL，系统仍可能在以下层面适配 benchmark：

- prompt 中包含 BIRD 风格的 Question / Evidence / Hint 字段；
- prompt 中写入 BIRD 常见 SQL 输出约束；
- 使用 SQLite-only 函数规则；
- 对 BIRD 的 evidence 字段做专门解析；
- 使用 BIRD dev 数据库结构生成 value index 或 embedding；
- 使用 BIRD evaluation 格式组织 predictions；
- 针对 BIRD 的输出格式、执行环境和错误类型做工程 patch。

因此，本文将实验设置称为 **protocol-level zero-shot** 或 **BIRD-adapted zero-shot**，而不是严格意义上的 benchmark-agnostic zero-shot。

## 2. 各方法是否使用 BIRD train golden SQL

当前实验中，没有发现 CHESS、DeepEye-SQL、Alpha-SQL 或 Pontis 在推理阶段显式检索 BIRD train 集 golden SQL。

| 方法 | 是否显式使用 train golden SQL | 说明 |
|---|---|---|
| Pontis | 否 | 使用 BIRD dev 数据库 extract、BIRD README 规则和当前问题 evidence，不使用 BIRD train golden SQL。 |
| CHESS | 否 | 当前 run manifest 标记 zero-shot；使用 BIRD dev `dev_zeroshot.json` 和本地 embedding。 |
| DeepEye-SQL | 否 | 当前配置为 `config-bird-zero-shot.toml`，`icl_sampling_budget = 0`，few-shot path 为空。 |
| Alpha-SQL | 否 | run manifest 标记 zero-shot；当前 dev run 未显示使用 train golden SQL。 |
| BashAgent | 否 | 通用工具智能体，不使用 train golden SQL。 |

## 3. 各方法如何适配 BIRD

### Pontis

Pontis 的 BIRD 适配主要包括：

- BIRD dev 数据库 full extract；
- 将数据库表、列、外键、统计、README、hint、disambig 等写入图谱；
- 使用 BIRD README 系统提示词约束 SQL 输出；
- 使用 final README recheck，在最终 SQL 前强制主 agent 重新检查 BIRD SQL 写作规则；
- 使用 BIRD evaluation 格式输出 predictions 和 evaluation。

Pontis 的适配不是 few-shot，而是将 BIRD 中常见的 SQL 输出风格、evidence 优先级和 SQLite 规则整理为数据集级决策表。

### CHESS

CHESS 的适配主要体现在 prompt template 和 pipeline 中。其 SQL generation / revision prompt 使用 BIRD 风格输入，包括 Question、Evidence 或 Hint，并包含一组强规则：

- 只选择问题中提到的列；
- 避免不必要输出列；
- 严格跟随 hints；
- 使用 SQLite functions only；
- 使用 `STRFTIME()` 处理日期；
- 不拼接字符串；
- 优先使用 INNER JOIN；
- 根据 unique / distinct 需求使用 DISTINCT。

CHESS 还使用信息检索、schema 选择、候选生成和 revision 等多阶段流程，并对 BIRD dev 数据库构建本地 embedding / vector 资源。

### DeepEye-SQL

DeepEye-SQL 的 BIRD 适配主要包括：

- dataset config 中明确 `type = "bird"`、`split = "dev"`；
- schema linking、value retrieval、SQL generation、SQL revision、SQL selection 等阶段均使用 Question / Hint 结构；
- prompt 中强调 Value Examples、foreign key constraints、SQLite functions、SELECT 最小化和 XML 输出格式；
- 当前 run 禁用了 ICL few-shot，但仍使用 BIRD dev 数据库构建 value-level vector database。

DeepEye-SQL 的适配不只是 prompt，也包括数据集 loader、vector database、stage pipeline 和 evaluation 输出。

### Alpha-SQL

Alpha-SQL 的 BIRD 适配主要包括：

- BIRD dev zero-shot 数据文件；
- question / hint / evidence 字段处理；
- keyword extraction、question rephrase、schema selection、column value/function identification；
- LSH / value retrieval；
- MCTS 或多候选搜索式 SQL generation；
- SQLite-only 和 BIRD 风格输出约束。

Alpha-SQL 的预处理包含 per-question keyword/value 相关 LLM 调用，因此它不仅依赖数据库级索引，也包含问题级预处理。

### BashAgent

BashAgent 基本没有 BIRD 专门 pipeline。它主要依赖 shell、sqlite 和文件工具访问数据库，属于更接近通用工具智能体的 baseline。它也使用当前问题和 evidence，但没有 CHESS、DeepEye-SQL、Alpha-SQL 那种复杂 BIRD pipeline。

## 4. 是否可以称为“伪 zero-shot”

可以在口头讨论中说“伪 zero-shot”，但论文中建议避免直接使用这个词，因为它容易被误解为数据泄漏或使用了 train golden SQL。

更准确的表述是：

> 本文实验采用 protocol-level zero-shot：推理阶段不显式检索或输入 BIRD train 集的 golden SQL 或 few-shot examples；但各 baseline 均包含不同程度的 BIRD-specific engineering，包括对 BIRD evidence/hint 字段、SQLite 执行环境、schema/value 预处理、输出格式和评测协议的适配。因此，这些方法不是 benchmark-agnostic zero-shot，而是 BIRD-adapted zero-shot。

## 5. 对实验结论的影响

这个区分很重要，因为它说明：

1. 本文的对比是公平的本地 zero-shot protocol 对比，而不是 train-set supervised 对比；
2. baseline 的高准确率不能完全归因于模型通用 SQL 能力，也包含 benchmark prompt 和 pipeline engineering；
3. Pontis 的 BIRD README 不是额外泄漏，而是与其他方法中的 BIRD prompt 规则类似，属于 benchmark adaptation；
4. 真正需要避免的是从 dev/test golden SQL 或 train golden SQL 中检索当前问题答案，而当前实验没有这样做。

## 6. 可写入论文的段落

本文所有方法均在 zero-shot 协议下进行评测，即推理阶段不显式使用 BIRD train 集中的 golden SQL 或 few-shot examples。然而，这里的 zero-shot 并不意味着完全不含数据集先验。CHESS、DeepEye-SQL 和 Alpha-SQL 均包含对 BIRD 数据格式、evidence/hint 字段、SQLite 执行环境、schema/value 预处理和输出协议的适配；Pontis 也通过 BIRD README 规则约束最终 SQL。因此，本文将该设置称为 protocol-level zero-shot 或 BIRD-adapted zero-shot。该定义既避免了 train-set leakage，也承认现代 Text-to-SQL baseline 往往包含 benchmark-specific engineering。

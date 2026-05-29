# Pontis 与 Pipeline Baseline 的结构差异

本文比较的五种方法并不属于同一种系统范式。CHESS、DeepEye-SQL 和 Alpha-SQL 更接近多阶段 Text-to-SQL pipeline；Pontis 和 BashAgent 更接近工具调用智能体。Pontis 与 BashAgent 的差异在于，Pontis 在工具智能体之前构建了持久化图谱工作空间。

理解这一结构差异很重要，因为它影响准确率、token 成本、预处理成本、可解释性和增量更新潜力。

## 1. Pipeline baseline 的典型结构

CHESS、DeepEye-SQL 和 Alpha-SQL 通常将 Text-to-SQL 拆成多个阶段：

```text
question + schema
-> keyword extraction / value retrieval
-> schema linking
-> SQL generation
-> SQL revision / execution check
-> SQL selection
-> prediction
```

这种设计的优势是阶段明确，容易针对某个子任务优化。例如：

- schema linking 阶段提高表列召回；
- value retrieval 阶段定位文本值；
- SQL generation 阶段约束输出格式；
- revision 或 checker 阶段利用执行反馈修复错误；
- selection 阶段在多个候选 SQL 中选择结果。

但 pipeline 的中间结果通常主要服务当前推理流程。即使系统构建了 embedding 或 vector database，这些资产也更像检索索引，而不是完整的数据库语义工作空间。

## 2. Pontis 的 workspace 范式

Pontis 的核心不是把 Text-to-SQL 拆成更多 prompt 阶段，而是在原始数据和智能体之间构建一个持久化图谱工作空间：

```text
raw project data
-> source modules
-> graph workspace
-> extractors / explorer agents
-> metadata, hints, README, embeddings
-> tool-calling SQL agent
```

在这个范式下，表、列、外键、统计、样例值、top-k、overlap、rel、hint、disambig、README 和 embedding 都成为图谱中的可查询资产。SQL agent 不需要每次从零理解整个数据库，而是可以通过 `find`、`meta`、`query` 等工具按需读取局部上下文。

因此，Pontis 的目标不是替代所有专门 Text-to-SQL pipeline，而是研究一种不同的系统组织方式：让数据库理解结果可保存、可查询、可更新、可复用。

## 3. BashAgent 作为下限对比

BashAgent 和 Pontis 都是工具智能体，但 BashAgent 没有图谱工作空间。它主要依赖 shell、sqlite 和文件工具在运行时直接探索数据库。

可以把 BashAgent 理解为：

```text
raw database + tools + LLM
```

Pontis 则是：

```text
raw database + graph workspace + extracted knowledge + tools + LLM
```

二者对比可以回答一个关键问题：图谱化工作空间是否真的带来收益，而不仅仅是工具调用本身带来收益。

当前实验中，BashAgent 的准确率为 60.04%，Pontis 为 65.38%。这说明在相同 benchmark 下，图谱化 schema/value/metadata/hint 组织方式确实能提高工具智能体的稳定性。

## 4. 中间资产的性质差异

| 方法 | 中间资产 | 主要用途 | 是否适合长期维护 |
|---|---|---|---|
| BashAgent | 无持久化资产 | 每题运行时探索 | 弱 |
| CHESS | embedding、schema/value retrieval context、prompt 中间结果 | 支持当前 SQL 生成流程 | 中 |
| DeepEye-SQL | value-level vector DB、schema linking 结果、候选 SQL | 支持 value retrieval 和 pipeline 选择 | 中 |
| Alpha-SQL | LSH/value index、问题改写、搜索树、候选 SQL | 支持 test-time search | 中 |
| Pontis | 图谱节点、统计、README、hint、disambig、embedding、工具历史知识 | 支持跨问题复用、解释和增量更新 | 强 |

pipeline baseline 的中间资产更偏“计算过程”；Pontis 的中间资产更偏“项目知识”。

## 5. 成本结构差异

Pipeline baseline 每个阶段往往构造独立 prompt，因此单次调用上下文较短，cached input 较少。Pontis 作为多轮工具智能体会携带长系统提示词、工具定义、ontology、项目 README 和工具历史，因此 cached input 很高。

这种差异导致：

- Pontis total tokens 高；
- Pontis cached input 高；
- Pontis uncached input 和 output 不一定高；
- pipeline baseline output 可能因为多候选推理或 revision 较高；
- 不能只用 total tokens 判断成本。

按 `cached:uncached:output = 0.02:1:2` 计算，Pontis 加上预处理摊销后仍低于 DeepEye-SQL、CHESS 和 Alpha-SQL。这说明 workspace 范式虽然带来长上下文，但在 prompt cache 支持下并不一定更贵。

## 6. 错误修复能力差异

从 BashAgent 错题三分类看，Pontis 的提升主要来自两类：

- `GOLDEN_SQL_STYLE`：通过 BIRD README 和 final recheck 更好地对齐输出契约；
- `DB_EXPLORATION_FIXABLE`：通过图谱化 meta、统计、hints 和工具探索更好地定位表列和值。

但 Pontis 对 `DATASET_PRIOR_REQUIRED` 类错误提升有限。这说明图谱工作空间擅长解决当前数据库内可验证的问题，但不能凭空知道 benchmark 隐含口径。

Pipeline baseline 也能补对部分 BashAgent 错题，尤其 DeepEye-SQL 在 value retrieval 和多阶段生成上较强。但它们也会丢掉更多 BashAgent 原本做对的题，说明更复杂 pipeline 并不一定单调提升所有类型问题。

## 7. 增量更新差异

数据库结构和内容变化时，pipeline baseline 主要面对索引刷新问题：

```text
schema/value changed -> rebuild affected index
```

Pontis 面对的是语义资产维护问题：

```text
schema/value changed
-> detect affected graph nodes
-> mark dependent hints/README/disambig stale
-> refresh affected statistics and summaries
-> re-embed changed nodes
-> keep unaffected knowledge
```

这使 Pontis 的问题更复杂，但也更有长期潜力。对于真实企业数据库，重要的不只是一次性生成 SQL，而是随着数据库演化持续维护业务语义、字段解释和查询经验。

## 8. 论文可用总结

本文比较的 baseline 代表了两种不同系统范式。CHESS、DeepEye-SQL 和 Alpha-SQL 通过多阶段 pipeline 将 Text-to-SQL 拆解为检索、schema linking、生成、修正和选择等子任务；Pontis 则把重点放在推理前的数据项目理解，将结构、统计、语义摘要、消歧提示和经验规则组织为持久化图谱工作空间。实验结果表明，Pontis 在 BIRD dev 上达到与专门 pipeline baseline 相当的准确率，并在 prompt cache 场景下保持较低的加权成本。更重要的是，Pontis 的中间结果不是一次性推理过程，而是可查询、可更新、可复用的数据库语义资产，因此更适合长期演化的数据项目。

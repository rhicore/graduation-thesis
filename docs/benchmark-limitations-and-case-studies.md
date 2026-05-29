# Text-to-SQL Benchmark 局限与案例分析

本文实验使用 BIRD dev 作为主要评测基准。BIRD 相比早期 Text-to-SQL 数据集更接近真实数据库场景，包含较大的数据库、真实值理解和 evidence 字段。但 BIRD 仍然是静态 benchmark，其执行准确率不能完全等价于真实业务正确性。本文需要在实验讨论中明确这一点，避免把分数提升简单解释为“系统更理解用户”。

## 1. Text-to-SQL 不是严格单值映射

传统 Text-to-SQL 任务常被抽象为：

```text
f(query, database) -> sql
```

这个建模隐含了一个强假设：给定一个自然语言 query 和一个数据库，存在唯一正确 SQL。但实际情况并非如此。更准确地说，Text-to-SQL 更接近：

```text
f(query, database, context) -> {sql_1, sql_2, ...}
```

也就是说，同一个业务目标可能存在多种 SQL 实现；同一个自然语言 query 也可能存在多个合理解释。benchmark 只能选择其中一个 golden SQL 作为参考答案，这会带来两类问题：

1. SQL 多重可达性；
2. query 语义欠定性。

## 2. SQL 多重可达性

同一业务目标可以通过多种 SQL 写法实现。即使执行结果语义上接近，仍可能因为输出列、排序、格式、数值类型或聚合粒度不同而被 benchmark 判错。

### case 1：`card_games/q390`

问题询问 ID 1-20 的卡牌颜色和格式。BashAgent 返回：

```text
id, colors, format
```

golden SQL 只返回：

```text
colors, format
```

从真实用户角度看，额外返回 `id` 有助于识别每张卡牌，甚至可能更有用；但在执行结果比对中，额外输出列会导致错误。

这个例子说明，benchmark accuracy 有时测量的是“是否严格匹配 golden SQL 的输出契约”，而不是“是否回答了用户问题”。

### case 2：`superhero/q763`

问题要求 Abomination 的 attribute value。BashAgent 返回：

```text
attribute_name, attribute_value
```

golden SQL 只接受：

```text
attribute_value
```

对人类读者而言，带上 attribute name 可以帮助解释 value 的含义；但 benchmark 只接受单列输出。这说明输出列最小化是 BIRD 风格中的重要隐含口径，而不一定是业务上唯一合理的输出。

### case 3：`toxicology/q226`

问题要求五位小数百分比。BashAgent 使用：

```sql
printf('%.5f', ...)
```

golden SQL 使用：

```sql
ROUND(..., 5)
```

两种写法都符合“保留五位小数”的直觉，但一个输出字符串，一个输出数值，执行结果类型不同可能导致判错。这个例子说明，执行结果比对仍然会受到格式和类型影响。

## 3. Query 语义欠定性

自然语言 query 往往是用户基于某种数据库先验写出的简短表达。用户不会把所有表选择、字段含义、过滤值、聚合粒度都完整写出来。当数据库中存在多个合理候选时，agent 只能根据 query、evidence、schema 和样例值做最大似然解释。

### case 4：`codebase_community/q689`

问题要求找出 “last to edit the post with ID 183” 的用户。

这个表达可以有多种解释：

- 使用 postHistory 中最后一条编辑记录；
- 使用 posts.LastEditorUserId；
- 使用 posts.OwnerUserId。

不同方法会选择不同路径，而 golden SQL 实际连接的是 `OwnerUserId`。从自然语言表述看，“last to edit” 与 owner 并不完全等价，因此该题存在明显解释空间。

这个例子说明，很多错误不是 SQL 语法能力不足，而是 query 表达、数据库结构和 golden SQL 选择之间存在欠定性。

### case 5：`student_club/q1376`

问题询问 closed events 中 spend-to-budget ratio 最高的 event。

一种自然解释是按 event 聚合预算行：

```text
SUM(spent) / SUM(amount)
```

golden SQL 则按单条 budget row 的：

```text
spent / amount
```

排序，没有进行 event-level aggregation。

二者代表不同业务粒度：前者是一场 event 的整体预算使用率，后者是一条预算记录的比例。自然语言中的 “event ratio” 更容易让人倾向 event-level aggregation，但 benchmark 选择了 row-level 口径。

### case 6：`thrombosis_prediction/q1187`

题面说 examined between 两个日期，同时条件来自 GPT 和 ALB。模型可能把 examined date 映射到 Examination 表的 `Examination Date`，再连接 Laboratory；golden SQL 则直接使用 Laboratory.Date。

该例体现了日期字段来源歧义：自然语言中的 examined date 并不唯一指向某个表列，需要结合标注者口径才能确定。

## 4. 执行结果比对的局限

现有 Text-to-SQL benchmark 通常使用两类评测方式：

- SQL 字符串或结构比对；
- 执行结果比对。

执行结果比对相比字符串比对更合理，因为它允许语法不同但结果相同的 SQL 被判为正确。然而，执行结果比对仍然无法解决：

1. 输出列差异；
2. 排序差异；
3. 数值格式差异；
4. 聚合粒度差异；
5. DISTINCT 口径差异；
6. query 语义歧义；
7. golden SQL 本身的标注错误或风格偏好。

因此，执行准确率应被理解为“与 benchmark golden SQL 的一致程度”，而不是“真实业务正确性的完整度量”。

## 5. 对 Pontis 实验的影响

Pontis 的 BIRD README 和 final recheck 很大程度上是在约束模型贴近 BIRD 的输出契约。例如：

- 只输出 question/evidence 要求的列；
- 不自动添加额外展示列；
- 不自动 DISTINCT；
- 不自动加隐藏状态过滤；
- 严格遵循 evidence 中的公式和字段映射；
- 保持 SQLite 函数和格式约束。

这些规则能提升 benchmark accuracy，但它们本质上是在对齐 BIRD 的评测口径，而不一定总是等价于真实用户最想要的业务输出。

因此，Pontis 的实验结论需要分两层表述：

1. 在 BIRD dev 上，Pontis 的图谱化工作空间和 SQL 护栏能提高与 golden SQL 的一致性；
2. 在真实业务中，Pontis 更重要的价值是提供可查询、可验证、可更新的数据库语义工作空间，使 agent 能在必要时与用户澄清业务目标，而不是盲目追求某个唯一 SQL。

## 6. 从单轮 SQL 到交互式业务目标

真实数据分析往往不是一次性输入输出。用户可能会问：

- “这里的 active 是哪个字段？”
- “按 event 统计还是按 budget row 统计？”
- “ratio 要不要乘以 100？”
- “输出学校代码还是学校名？”
- “latest 是按创建时间还是更新时间？”

在这些情况下，理想系统应该能够追问或提出假设，而不是直接生成唯一 SQL。也就是说，复杂 Text-to-SQL 更合理的任务形式是：

```text
ambiguous query
-> clarification / database exploration
-> explicit business goal
-> executable SQL
```

当前 benchmark 通常跳过 clarification，直接要求模型复现 golden SQL。因此，benchmark 更适合比较静态问题回答能力，而不足以完整评估真实数据智能体。

## 7. 可写入论文的段落

本文认为，当前 Text-to-SQL 评测的主要局限不只在于模型方法，也在于任务建模本身。传统评测默认给定 query 和 database 后存在唯一正确 SQL，但在真实数据分析中，同一业务目标可能存在多种 SQL 实现路径，自然语言 query 也常常不足以唯一决定表选择、字段来源、输出粒度和格式口径。BIRD 采用执行结果比对，已经避免了部分 SQL 表面形式差异带来的误判，但仍然无法解决输出列、排序、格式、聚合粒度和 query 歧义问题。因此，本文在报告执行准确率的同时，也结合错误类型和案例分析讨论 benchmark 口径对结果的影响。Pontis 的价值不应仅被理解为提高静态 benchmark 分数，而应被理解为构建一个能够持续维护数据库语义、支持工具验证和未来用户澄清的数据智能体工作空间。

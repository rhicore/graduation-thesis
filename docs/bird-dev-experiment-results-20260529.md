# BIRD Dev 实验结果整理

本文档整理截至 2026-05-29 的 BIRD dev 全量实验结果，用于后续撰写本科毕业论文的实验章节。实验重点不是只比较执行准确率，而是同时比较 LLM 调用轮次、缓存输入、非缓存输入、输出 token 和总体 token 消耗，以支撑“Text-to-SQL 系统工程化评估”的论述。

## 1. 实验设置

### 数据集

- 数据集：BIRD dev
- 题目数：1534
- 数据库数：11
- 评测指标：执行结果一致性，即 predicted SQL 与 golden SQL 在同一数据库上执行后结果集合是否一致。

### 对比方法

本轮整理包含五种方法：

| 方法 | 说明 |
|---|---|
| Pontis direct README | 本文方法。使用 Pontis 图谱化项目工作空间、工具调用智能体、BIRD README 系统提示词和 final SQL 前 direct README recheck。不开启 BIRD train 全局经验库，不开启 reflection。 |
| DeepEye-SQL | 软件工程式多阶段 Text-to-SQL baseline。使用本地 BGE embedding，zero-shot dev 评测。 |
| Alpha-SQL | MCTS / 多候选搜索式 baseline。使用本地 BGE embedding，zero-shot dev 评测。 |
| BashAgent | 只提供 shell / sqlite / 文件操作能力的通用工具智能体 baseline。 |
| CHESS | Contextual Harnessing for Efficient SQL Synthesis baseline。使用本地 BGE embedding，zero-shot dev 评测。 |

### Pontis 当前运行配置

Pontis 当前采用的完整 run id：

```text
20260529_211836_bird_dev_full_readme_direct_noglobal_noreflection
```

关键参数：

```text
db_workers = 6
workers/db = 20
bird_global = off
bird_readme = on
prompt_profile = full
reflection = off
exec_repair = on
final README recheck = on, direct 回灌
```

其中 `final README recheck` 指在 agent 首次准备输出 final SQL 时，guardrail 强制 block 一次，并将完整 BIRD SQL 写作 README 作为 checklist 重新输入给主 agent。该机制不读取 few-shot examples。

## 2. 主实验结果

### 总体准确率与资源消耗

下表按执行准确率排序。所有 token 指标均为每题平均值。

| 方法 | 正确数 / 总数 | 执行准确率 | LLM 轮次 / 题 | cached input / 题 | uncached input / 题 | output / 题 | total tokens / 题 |
|---|---:|---:|---:|---:|---:|---:|---:|
| Pontis direct README | 1003 / 1534 | 65.38% | 11.446 | 156569.7 | 6651.9 | 3174.7 | 166396.4 |
| DeepEye-SQL | 1001 / 1534 | 65.25% | 5.339 | 4253.7 | 12637.4 | 5430.2 | 22321.3 |
| Alpha-SQL | 972 / 1534 | 63.36% | 12.040 | 33972.8 | 18444.5 | 14181.0 | 66598.3 |
| BashAgent | 921 / 1534 | 60.04% | 6.746 | 6079.7 | 1544.8 | 1897.9 | 9522.4 |
| CHESS | 900 / 1534 | 58.67% | 10.795 | 11191.5 | 15880.8 | 5142.9 | 32215.2 |

上述表格只统计即席查询阶段的每题平均消耗，不包含一次性预处理、embedding 建库或 Pontis extract 阶段的成本。各方法预处理资源消耗按 11 个 BIRD dev 数据库平均后如下：

| 方法 | 预处理 LLM 轮次 / DB | cached input / DB | uncached input / DB | output / DB | embedding tokens / DB | preprocess total / DB |
|---|---:|---:|---:|---:|---:|---:|
| Pontis direct README | 219.0 | 1891828.4 | 120304.7 | 100566.7 | 15467.7 | 2128167.5 |
| DeepEye-SQL | 0.0 | 0.0 | 0.0 | 0.0 | 1240116.0 | 1240116.0 |
| Alpha-SQL | 139.5 | 87691.6 | 4994.6 | 50230.5 | 3732.6 | 146649.4 |
| BashAgent | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 |
| CHESS | 0.0 | 0.0 | 0.0 | 0.0 | 1059.5 | 1059.5 |

其中 Pontis 的预处理来自同日 full extract run，包含 schema 准备、列/实体语义抽取、README 写入和 embedding；DeepEye-SQL 和 CHESS 的预处理主要是本地 BGE embedding 建库；Alpha-SQL 的预处理包含每题 keyword/value 相关 LLM 调用和 embedding；BashAgent 没有独立预处理阶段。

若采用此前讨论的加权成本口径：

```text
weighted_cost = 0.02 * cached_input_tokens
              + 1.00 * uncached_input_tokens
              + 2.00 * output_tokens
```

则每题平均加权成本如下：

| 方法 | 加权成本 / 题 | 相对 Pontis |
|---|---:|---:|
| BashAgent | 5462.1 | 0.34x |
| Pontis direct README | 16132.8 | 1.00x |
| DeepEye-SQL | 23582.9 | 1.46x |
| CHESS | 26390.4 | 1.64x |
| Alpha-SQL | 47485.9 | 2.94x |

### 结果解读

Pontis direct README 在本轮五方法比较中取得最高执行准确率，为 65.38%，比 DeepEye-SQL 高 2 题，即 0.13 个百分点。两者在准确率上基本持平，但资源结构明显不同：Pontis 的 total input 很高，主要来自长系统提示词、工具定义、项目 README、BIRD README 和多轮工具历史；然而其中绝大部分能够被 provider 归入 cached input。DeepEye-SQL 的 total tokens 明显更低，但 uncached input 和 output 都高于 Pontis，因此在上述加权成本口径下成本高于 Pontis。

BashAgent 的准确率为 60.04%，明显低于 Pontis 和 DeepEye-SQL，但其每题加权成本最低。这说明只提供通用 shell/sqlite 工具可以获得很低的 token 成本，但缺少图谱化上下文组织、元数据读取和专门 SQL 护栏后，复杂跨库 Text-to-SQL 的准确率存在明显上限。

Alpha-SQL 的准确率为 63.36%，低于 Pontis 和 DeepEye-SQL，并且 output token 极高。该结果反映出多候选搜索、MCTS 或 test-time scaling 方法虽然可能提高生成覆盖率，但若输出和候选推理链过长，会显著提高运行成本。

CHESS 在本轮实验中准确率最低，为 58.67%。其 uncached input 和 output 均不低，说明在当前本地复现实验配置和模型设置下，CHESS 的效率和准确率均未体现出优势。

## 3. Pontis 与其他方法的资源结构差异

Pontis 的 cached input 明显高于其他方法。按每轮 LLM 调用折算：

| 方法 | cached input / round | uncached input / round | input / 题 |
|---|---:|---:|---:|
| Pontis direct README | 13679.7 | 581.1 | 163221.6 |
| DeepEye-SQL | 796.7 | 2367.0 | 16891.1 |
| Alpha-SQL | 2821.7 | 1531.9 | 52417.3 |
| BashAgent | 901.1 | 229.0 | 7624.6 |
| CHESS | 1036.7 | 1471.1 | 27072.3 |

这说明 Pontis 并不是每轮都产生大量新的非缓存输入，而是每轮都携带较长、可重复命中的上下文前缀。典型 Pontis query 首轮上下文长度约为：

| 上下文组成 | token 数 |
|---|---:|
| base prompt | 383 |
| tool prompt | 642 |
| ontology prompt | 2541 |
| SQL prompt | 370 |
| effort prompt | 43 |
| guardrail prompt | 127 |
| BIRD README system prompt | 3516 |
| project context | 50 |
| project README | 1693 |
| tool definitions | 1235 |
| query user prompt | 191 |
| first request total | 约 10900 |

因此 Pontis 的上下文增长更接近累积式 chat agent：

```text
call 1: system + tools + user query
call 2: system + tools + user query + tool call/result history
call 3: system + tools + user query + longer tool call/result history
...
final recheck: previous context + final SQL + README checklist
```

相比之下，DeepEye-SQL、CHESS 和 Alpha-SQL 更接近多阶段 pipeline，每个阶段构造一个相对独立的 prompt，而不是持续携带完整工具交互历史。因此它们的 total input 和 cached input 不会像 Pontis 一样随着多轮对话显著累积。

该差异对论文写作很重要：Pontis 的总 token 并不能直接解释为“实际成本更高”。在 provider 支持 prompt cache 的情况下，Pontis 的长稳定上下文主要落入 cached input；真正影响成本的是 uncached input 和 output。Pontis 的 output 也显著低于 Alpha-SQL、DeepEye-SQL 和 CHESS。

## 4. Pontis 分库结果

Pontis direct README 在 11 个 BIRD dev 数据库上的结果如下：

| 数据库 | 正确数 / 总数 | 执行准确率 | LLM 轮次 / 题 | total tokens / 题 |
|---|---:|---:|---:|---:|
| california_schools | 51 / 89 | 57.3% | 14.02 | 214485.8 |
| card_games | 117 / 191 | 61.3% | 10.79 | 166724.8 |
| codebase_community | 131 / 186 | 70.4% | 11.51 | 167774.9 |
| debit_card_specializing | 46 / 64 | 71.9% | 12.17 | 155968.6 |
| european_football_2 | 83 / 129 | 64.3% | 11.54 | 154303.5 |
| financial | 72 / 106 | 67.9% | 12.52 | 182253.5 |
| formula_1 | 93 / 174 | 53.4% | 12.69 | 220293.9 |
| student_club | 128 / 158 | 81.0% | 9.57 | 127882.5 |
| superhero | 110 / 129 | 85.3% | 7.98 | 98548.3 |
| thrombosis_prediction | 85 / 163 | 52.1% | 13.68 | 206757.7 |
| toxicology | 87 / 145 | 60.0% | 10.59 | 130726.8 |

从分库结果看，Pontis 在 `superhero`、`student_club`、`debit_card_specializing` 上表现较好，在 `thrombosis_prediction`、`formula_1` 和 `california_schools` 上表现较弱。这些弱项通常对应更复杂的领域口径、隐藏风格偏好、多个同构角色列或较长探索路径。后续错误分析可重点围绕这些数据库展开。

## 5. 可写入论文的实验结论

可以在论文实验章节中将结论组织为以下几点。

第一，在 BIRD dev 全量评测中，Pontis direct README 取得 65.38% 的执行准确率，略高于 DeepEye-SQL 的 65.25%，高于 Alpha-SQL、BashAgent 和 CHESS。该结果说明，图谱化项目工作空间与工具调用护栏结合后，在 zero-shot BIRD dev 场景下具备与现有专门 Text-to-SQL baseline 相当甚至略优的准确率。

第二，Pontis 的 token 消耗结构不同于传统 pipeline baseline。Pontis 的 total input 和 cached input 很高，这是因为它作为多轮工具智能体持续携带系统提示词、工具定义、项目上下文、README 和工具历史。然而，其 uncached input 和 output 并未同比例升高。在支持 prompt cache 的 provider 上，Pontis 的稳定上下文能够被大量缓存，因此不能仅用 total tokens 判断系统成本。

第三，BashAgent 的成本最低但准确率明显较低，说明单纯提供 shell/sqlite/file 工具不足以稳定解决复杂 Text-to-SQL。Pontis 相比 BashAgent 的准确率提升为：

```text
65.38% - 60.04% = 5.34 个百分点
```

该对比可以用于论证图谱化工作空间、结构化元数据和 SQL 专用护栏对准确率的贡献。

第四，Pontis 仍存在明显局限。部分数据库准确率较低，说明图谱化上下文和工具验证并不能完全解决自然语言歧义、benchmark 风格偏好和复杂 SQL 口径问题。BIRD 中的 gold SQL 也存在输出列、排序、DISTINCT、比例口径等风格性要求，部分错误并非纯粹 schema linking 或 SQL 语法错误。因此论文中应避免只用单一准确率评价系统，而应结合错误分析和资源成本讨论系统边界。

## 6. 论文表格草稿

### 主结果表

可在论文中改写为：

```latex
\begin{table}[htbp]
\centering
\caption{BIRD dev 全量评测结果}
\begin{tabular}{lrrrrrrr}
\toprule
方法 & 正确数 & 准确率 & 轮次/题 & Cached/题 & Uncached/题 & Output/题 & Total/题 \\
\midrule
Pontis & 1003 & 65.38\% & 11.446 & 156569.7 & 6651.9 & 3174.7 & 166396.4 \\
DeepEye-SQL & 1001 & 65.25\% & 5.339 & 4253.7 & 12637.4 & 5430.2 & 22321.3 \\
Alpha-SQL & 972 & 63.36\% & 12.040 & 33972.8 & 18444.5 & 14181.0 & 66598.3 \\
BashAgent & 921 & 60.04\% & 6.746 & 6079.7 & 1544.8 & 1897.9 & 9522.4 \\
CHESS & 900 & 58.67\% & 10.795 & 11191.5 & 15880.8 & 5142.9 & 32215.2 \\
\bottomrule
\end{tabular}
\end{table}
```

### 加权成本表

可在论文中说明：为了近似反映 prompt cache 场景下的商业 API 成本，采用 `cached:uncached:output = 0.02:1:2` 的相对权重计算每题加权成本。

```latex
\begin{table}[htbp]
\centering
\caption{不同方法的每题加权 token 成本}
\begin{tabular}{lrr}
\toprule
方法 & 加权成本/题 & 相对 Pontis \\
\midrule
BashAgent & 5462.1 & 0.34 \\
Pontis & 16132.8 & 1.00 \\
DeepEye-SQL & 23582.9 & 1.46 \\
CHESS & 26390.4 & 1.64 \\
Alpha-SQL & 47485.9 & 2.94 \\
\bottomrule
\end{tabular}
\end{table}
```

## 7. BashAgent 错题三分类对比

BashAgent 运行结果中，错误样本带有 `reflection_primary_error_category` 字段。按该字段统计，BashAgent 在 1534 道题中正确 921 道、错误 613 道；其中 608 道被归入以下三类，另有 5 道没有 reflection 分类。

| BashAgent 错误类别 | 题数 | 含义 |
|---|---:|---|
| `GOLDEN_SQL_STYLE` | 241 | BIRD SQL 风格、输出列、排序、比例、格式等与 golden 口径不一致。 |
| `DATASET_PRIOR_REQUIRED` | 222 | 需要 benchmark 或数据集口径先验，仅靠当前问题和数据库较难稳定推出。 |
| `DB_EXPLORATION_FIXABLE` | 145 | 理论上可通过更充分的数据库探索、schema/value grounding 或 join path 验证修复。 |

下表统计另外四种方法在 BashAgent 各类错题上补对了多少。括号中为该类别内补对率。

| BashAgent 错误类别 | 题数 | Pontis direct README | DeepEye-SQL | Alpha-SQL | CHESS |
|---|---:|---:|---:|---:|---:|
| BIRD SQL 风格 / 输出契约 | 241 | 75 (31.1%) | 77 (32.0%) | 72 (29.9%) | 68 (28.2%) |
| 需要数据集口径先验 | 222 | 19 (8.6%) | 26 (11.7%) | 26 (11.7%) | 16 (7.2%) |
| 可通过数据库探索修复 | 145 | 46 (31.7%) | 42 (29.0%) | 41 (28.3%) | 34 (23.4%) |

对应地，仍然没有被修复的 BashAgent 错题数如下。

| BashAgent 错误类别 | 题数 | Pontis 仍错 | DeepEye 仍错 | Alpha 仍错 | CHESS 仍错 |
|---|---:|---:|---:|---:|---:|
| BIRD SQL 风格 / 输出契约 | 241 | 166 | 164 | 169 | 173 |
| 需要数据集口径先验 | 222 | 203 | 196 | 196 | 206 |
| 可通过数据库探索修复 | 145 | 99 | 103 | 104 | 111 |

如果不只看 BashAgent 错题，也看 BashAgent 原本做对的 921 道题，另外四种方法均存在一定“回退”，即 BashAgent 正确但该方法错误的题。综合“补对 BashAgent 错题”和“丢掉 BashAgent 对题”后，净收益如下。

| 方法 | BashAgent 错题中补对 | BashAgent 对题中又做错 | 净收益 | 总正确数 |
|---|---:|---:|---:|---:|
| Pontis direct README | 141 | 59 | +82 | 1003 |
| DeepEye-SQL | 146 | 66 | +80 | 1001 |
| Alpha-SQL | 139 | 88 | +51 | 972 |
| CHESS | 118 | 139 | -21 | 900 |

这个结果说明，Pontis 相对 BashAgent 的提升并不是来自单一错误类型。Pontis 对 `GOLDEN_SQL_STYLE` 和 `DB_EXPLORATION_FIXABLE` 两类错题的补对率都约为 31%，说明 BIRD README 约束和图谱化探索都在发挥作用；但在 `DATASET_PRIOR_REQUIRED` 上只补对 8.6%，说明很多题需要的是 benchmark 口径或隐藏先验，而不是更强的局部数据库探索。DeepEye-SQL 在 BashAgent 错题上的补对数略高于 Pontis，但也丢掉了更多 BashAgent 原本做对的题，因此净收益低于 Pontis。

从论文论证角度看，这组实验比单纯报告总体准确率更有解释力：BashAgent 代表“通用工具 + 原始数据库探索”的下限，Pontis 的净提升主要来自能够补救一部分输出契约错误和数据库探索错误，同时相对少地破坏 BashAgent 已经能解决的简单题。另一方面，所有方法在 `DATASET_PRIOR_REQUIRED` 类别上补对率都很低，这说明 BIRD dev 中仍有一批题目更接近 benchmark convention matching，而不是纯粹的 schema linking 或 SQL 生成能力问题。

## 8. 原始结果路径

### Pontis direct README

```text
workspace/baselines/pontis/results/20260529_211836_bird_dev_full_readme_direct_noglobal_noreflection/evaluation/evaluation.json
workspace/baselines/pontis/results/20260529_211836_bird_dev_full_readme_direct_noglobal_noreflection/results/results.jsonl
workspace/baselines/pontis/results/20260529_211836_bird_dev_full_readme_direct_noglobal_noreflection/results/predictions.json
workspace/baselines/pontis/runtime_logs/20260529_211836_bird_dev_full_readme_direct_noglobal_noreflection/progress.log
workspace/baselines/pontis/preprocess_logs/20260529_163106_bird_dev_full_extract_20260529/extract_summary.json
```

### DeepEye-SQL

```text
workspace/baselines/deepeye_sql/evaluation/20260529_0545_deepeye_alpha_bird_dev_full_local_bge_speedmax_deepeye_sql/evaluation.json
workspace/baselines/deepeye_sql/results/20260529_0545_deepeye_alpha_bird_dev_full_local_bge_speedmax_deepeye_sql/preprocess_efficiency.json
```

### Alpha-SQL

```text
workspace/baselines/alpha_sql/evaluation/20260529_0545_deepeye_alpha_bird_dev_full_local_bge_speedmax_alpha_sql/evaluation.json
workspace/baselines/alpha_sql/preprocess/20260529_0545_deepeye_alpha_bird_dev_full_local_bge_speedmax_alpha_sql/dev/preprocess_efficiency.json
workspace/baselines/alpha_sql/results/20260529_0545_deepeye_alpha_bird_dev_full_local_bge_speedmax_alpha_sql/preprocess_efficiency.json
```

### BashAgent

```text
workspace/baselines/bash_agent/results/bird_dev_20260524_031500_bash_agent_bird_dev_full_reflection_w50_fixed/evaluation/evaluation.json
```

### CHESS

```text
workspace/baselines/chess/evaluation/20260529_0525_chess_bird_dev_full_local_bge_small_forceprep_chess/evaluation.json
workspace/baselines/chess/results/20260529_0525_chess_bird_dev_full_local_bge_small_forceprep_chess/preprocess_efficiency.json
```

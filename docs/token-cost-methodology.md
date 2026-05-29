# Token 成本统计方法

本文实验不仅报告执行准确率，也统计 LLM 调用轮次、cached input tokens、uncached input tokens、output tokens、total tokens 和预处理成本。这样做的原因是：在 LLM agent 系统中，资源消耗本身就是系统设计的一部分；尤其是在支持 prompt cache 的 API 中，total tokens 不能直接等价于实际成本。

## 1. 为什么不能只看 total tokens

传统 Text-to-SQL pipeline 通常每个阶段构造一个相对独立的 prompt，调用结束后不保留完整工具交互历史。Pontis 则是多轮工具智能体，每轮调用都携带较长的系统提示词、工具定义、图谱 ontology、项目 README、BIRD README 和历史工具结果。

因此，Pontis 的 total input tokens 会显著高于 pipeline baseline。但这并不意味着 Pontis 的实际成本按相同比例升高，因为大量稳定前缀可以被 provider 计入 prompt cache。

如果只看 total tokens，会把以下两类 token 混在一起：

- 每轮都稳定重复、可缓存的上下文；
- 每题新产生、无法缓存的上下文和模型输出。

前者主要影响上下文长度和缓存命中，后者才更直接影响边际成本。

## 2. 指标定义

本文主要统计以下指标：

| 指标 | 含义 |
|---|---|
| `llm_rounds` | 每题平均 LLM 调用轮次。 |
| `cached_input_tokens` | provider 认为命中 prompt cache 的输入 token。 |
| `uncached_input_tokens` | 未命中 cache、需要按正常输入计费的 token。 |
| `output_tokens` | 模型生成 token。 |
| `total_tokens` | cached input + uncached input + output。 |
| `preprocess tokens` | 即席查询前的一次性 extract、index 或 embedding 成本。 |

为了统一不同方法的成本比较，本文使用以下加权成本：

```text
weighted_cost = 0.02 * cached_input_tokens
              + 1.00 * uncached_input_tokens
              + 2.00 * output_tokens
```

该公式不是某个具体 API 的绝对价格，而是近似反映 prompt cache 场景下的相对成本：cached input 成本较低，uncached input 按 1 倍计算，output token 通常更贵，因此按 2 倍计算。

## 3. 预处理成本与即席查询成本

不同方法的预处理形态不同：

- Pontis 有 full extract，包括 schema 准备、列统计、语义摘要、entity hints、README 和 embedding；
- DeepEye-SQL 主要构建 value-level vector database；
- CHESS 主要构建数据库级 embedding / retrieval 资源；
- Alpha-SQL 包含 per-question keyword/value 相关 LLM 预处理和 embedding；
- BashAgent 没有独立预处理阶段。

因此，本文将成本拆成两部分：

1. **benchmark runtime cost**：每道题即席查询阶段的平均成本；
2. **preprocess amortized cost**：将一次性预处理成本按题目数摊销后的平均成本。

这种拆分比直接合并更清楚，因为预处理成本的意义取决于使用场景。如果一个数据库只查询一次，预处理成本会很高；如果同一个数据库长期被反复查询，预处理成本会被持续摊薄。

## 4. Pontis 的成本结构

Pontis 的 runtime 每题平均指标为：

| 指标 | 数值 |
|---|---:|
| LLM rounds / query | 11.446 |
| cached input / query | 156569.7 |
| uncached input / query | 6651.9 |
| output / query | 3174.7 |
| total tokens / query | 166396.4 |
| weighted runtime cost / query | 16132.8 |

Pontis 的 full extract 预处理总量为：

| 指标 | 数值 |
|---|---:|
| cached input | 20810112 |
| uncached input | 1323352 |
| output | 1106234 |
| embedding tokens | 170145 |

不计 embedding 时，预处理加权成本为：

```text
0.02 * 20,810,112 + 1,323,352 + 2 * 1,106,234
= 3,952,022.24
```

摊到 BIRD dev 1534 道题：

```text
3,952,022.24 / 1534 = 2576.3 / query
```

因此，Pontis 加上预处理摊销后的每题成本为：

```text
16132.8 + 2576.3 = 18709.1
```

如果 embedding tokens 也按 1.0 倍 token-equivalent 计入，则 Pontis 每题成本约为：

```text
18820.0
```

## 5. 五种方法的成本对比

不把 embedding token 计入加权成本时：

| 方法 | runtime / query | preprocess / query | total / query |
|---|---:|---:|---:|
| BashAgent | 5462.1 | 0.0 | 5462.1 |
| Pontis | 16132.8 | 2576.3 | 18709.1 |
| DeepEye-SQL | 23582.9 | 0.0 | 23582.9 |
| CHESS | 26390.4 | 0.0 | 26390.4 |
| Alpha-SQL | 47485.9 | 768.8 | 48254.7 |

如果 embedding token 也按 1.0 倍计入：

| 方法 | runtime / query | preprocess / query | total / query |
|---|---:|---:|---:|
| BashAgent | 5462.1 | 0.0 | 5462.1 |
| Pontis | 16132.8 | 2687.2 | 18820.0 |
| CHESS | 26390.4 | 7.6 | 26398.0 |
| DeepEye-SQL | 23582.9 | 8892.6 | 32475.5 |
| Alpha-SQL | 47485.9 | 795.5 | 48281.4 |

## 6. 结果解释

第一，BashAgent 的成本最低，但准确率也明显低于 Pontis 和 DeepEye-SQL。这说明完全依赖运行时探索可以降低预处理和上下文成本，但缺少可复用数据库语义。

第二，Pontis 的 total tokens 很高，但大量输入属于 cached input。按加权成本计算后，Pontis 的成本低于 DeepEye-SQL、CHESS 和 Alpha-SQL。

第三，DeepEye-SQL 的 runtime token 成本不算最高，但如果将 embedding 建库按 token-equivalent 计入，其总成本会明显上升。这说明 value-level vector DB 对数据库内容理解有帮助，但预处理成本不可忽略。

第四，Alpha-SQL 的 output tokens 极高，说明多候选搜索和 test-time scaling 会显著增加生成成本。对于追求准确率的任务这可能是合理权衡，但在系统评估中必须显式报告。

## 7. 可写入论文的段落

本文将 token 成本拆分为 cached input、uncached input 和 output 三类，而不是只报告 total tokens。原因在于，Pontis 作为多轮工具智能体会携带较长的系统提示词、工具定义和项目上下文，其中大量稳定前缀可以被 prompt cache 命中。若只看 total tokens，会高估这类系统的边际成本。为近似反映 prompt cache 场景下的商业 API 成本，本文采用 `cached:uncached:output = 0.02:1:2` 的相对权重计算加权成本，并将预处理成本单独统计后按题目数摊销。实验结果显示，即使计入 full extract 预处理成本，Pontis 的每题加权成本仍低于 DeepEye-SQL、CHESS 和 Alpha-SQL，仅高于轻量但准确率较低的 BashAgent。

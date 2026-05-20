# LaTeX 论文模板用法速查

## 1. 图片

### 基本插图

```latex
\begin{figure}[htbp]
   \centering
   \includegraphics[width=0.5\textwidth]{figure/图片文件名.png}
   \downcaption{图片标题}
   \label{fig:标签名}
\end{figure}
```

- `\downcaption` 用于图题（图下方），编号格式为"图X-Y"
- `width=0.5\textwidth` 表示宽度为页面的一半，按需调整
- 引用：`如图\ref{fig:标签名}所示`

### 子图

```latex
\begin{figure}[ht!]
    \centering
    \begin{subfigure}{.45\textwidth}
        \centering
        \includegraphics[width=\textwidth]{figure/a.png}
        \caption{子图A标题}
    \end{subfigure}
    \begin{subfigure}{.45\textwidth}
        \centering
        \includegraphics[width=\textwidth]{figure/b.png}
        \caption{子图B标题}
    \end{subfigure}
    \caption{总标题}
    \label{fig:子图标签}
\end{figure}
```

## 2. 表格

### 三线表

```latex
\begin{table}[htbp]\small
  \centering
  \topcaption{表格标题}
  \begin{tabular}{cccc}
    \toprule[1.5pt]
    \textbf{列1} & \textbf{列2} & \textbf{列3} & \textbf{列4} \\
    \midrule[1pt]
    数据1 & 数据2 & 数据3 & 数据4 \\
    数据5 & 数据6 & 数据7 & 数据8 \\
    \bottomrule[1.5pt]
  \end{tabular}
\end{table}
```

- `\topcaption` 用于表题（表上方），编号格式为"表X-Y"
- 引用：`如表\ref{tab:标签名}所示`（需在 `\topcaption` 后加 `\label{tab:标签名}`）

## 3. 公式

### 单行公式

```latex
\begin{equation}
E = mc^2
\label{eq:质能方程}
\end{equation}
```

编号格式为 (X-Y)，引用：`式(\ref{eq:质能方程})`

### 多行公式（居中对齐）

```latex
\begin{gather}
a = b + c \label{eq:a} \\
d = e + f \label{eq:d}
\end{gather}
```

### 多行公式（按等号对齐）

```latex
\begin{align}
a &= b + c \label{eq:align1} \\
  &= d + e \label{eq:align2}
\end{align}
```

### 不编号公式

在环境名后加星号：`equation*`、`align*`、`gather*`

### 公式说明（式中）

```latex
\begin{equation}
v = \frac{s}{t}
\end{equation}
式中：
\begin{align*}
v &\text{—— 速度，m/s} \\
s &\text{—— 位移，m} \\
t &\text{—— 时间，s}
\end{align*}
```

## 4. 参考文献

### 引用方式

```latex
上标引用\upcite{key1}                          % 输出：^[1]
正文引用\cite{key2}                             % 输出：[2]
连续引用\cite{key1,key2,key3}                   % 输出：[1-3]
带页码\cite[124--128]{key4}                     % 输出：[4, pp.124-128]
```

### 添加中文文献（在 sample.bib 中）

```bibtex
@article{张三2024某研究,
  title  = {某研究标题},
  author = {张三 and 李四},
  journal = {某期刊},
  volume  = {10},
  number  = {2},
  pages   = {100--110},
  year    = {2024},
  language = {zh}
}
```

中文文献**必须**加 `language = {zh}`，否则排版会出问题。

## 5. 算法

```latex
\begin{algorithm}
    \caption{算法标题}
    \label{alg:标签名}
    \begin{algorithmic}[1]
        \Require 输入描述
        \Ensure 输出描述
        \State $x \gets 0$
        \For{$i = 1$ \to $n$}
            \State $x \gets x + i$
        \EndFor
        \State \Return $x$
    \end{algorithmic}
\end{algorithm}
```

## 6. 定理/定义等环境

```latex
\begin{definition}
定义内容。
\end{definition}

\begin{theorem}
定理内容。
\end{theorem}
```

可用环境：`definition`、`theorem`、`lemma`（引理）、`corollary`（推论）、`proposition`（命题）、`example`（例）、`remark`（评注）、`proof`（证明）

## 7. 附录

```latex
\appendixs{附录标题名称}
% 附录正文内容写在这里
```

## 8. 常用备忘

| 用途 | 命令 |
|------|------|
| 首行缩进 | 默认2字符，无需手动 |
| 强制换页 | `\newpage` |
| 空行 | 留一个空行即可分段 |
| 加粗 | `\textbf{文字}` |
| 斜体 | `\textit{文字}` |
| 行内公式 | `$E=mc^2$` |
| 上标 | `$x^2$` |
| 下标 | `$v_i$` |
| 度数符号 | `$30\degree$`（需 `\usepackage{gensymb}`）|
| 省略号 | `$\cdots$`（居中）、`$\ldots$`（靠下）|

% !TEX program = xelatex
% !Mode:: "TeX:UTF-8"
%%
%% 西安交通大学本科毕业设计（论文）LaTeX 模板
%%
%% 原始版本：XJTU-BSThesis_latex_2022 by Chenjie Gan (干晨劼)
%% 基于：XJTU-BSThesis_latex_2016 Version 1.1 by Lingxiao Zhao (赵令霄)
%% 适配 2025 届格式要求
%%
%% 免责声明：本模板仅供参考，作者不对使用本模板产生的格式错误负责。
%% 使用前请务必核对学校最新的格式要求。
%%
%% 参考来源：
%%   1. NJU LaTeX Template by Chuheng Zhang
%%   2. XJTU CTex Model by wanghongxin, hugo, hy_haoyun
%%   3. XJTU-BSThesis_latex_2016 by Lingxiao Zhao
%%      https://github.com/LingxiaoShawn/XJTU_LaTeX
%%
%% 用法：\documentclass[Linux]{xjtuBSThesis}
%%       可选参数：Linux / Mac / Win
%%

\NeedsTeXFormat{LaTeX2e}[1995/12/01]
\ProvidesClass{xjtuBSThesis}[2025/01/01 xjtuBSThesis for XJTU]

%% ============================================================================
%%  1. 文档类选项
%% ============================================================================
\newif\ifXJTU@Mac \XJTU@Macfalse
\newif\ifXJTU@Linux \XJTU@Linuxfalse
\newif\ifXJTU@Win \XJTU@Winfalse

\DeclareOption{Mac}{\XJTU@Mactrue}
\DeclareOption{Linux}{\XJTU@Linuxtrue}
\DeclareOption{Win}{\XJTU@Wintrue}
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}
\ProcessOptions\relax

% 12pt 字号，A4 纸，单面打印（本科论文一般单面）
\LoadClass[12pt,a4paper,oneside]{article}

%% ============================================================================
%%  2. 宏包加载
%% ============================================================================

% ---------- 页面布局 ----------
% 页边距：上 3.0cm，下 2.5cm，左 2.6cm，右 2.6cm
\RequirePackage{geometry}
\geometry{hmargin=2.6truecm, top=3.0truecm, bottom=2.5truecm}

% ---------- 图片 ----------
\RequirePackage{graphicx}
\DeclareGraphicsExtensions{.pdf,.eps,.jpg,.png}
\graphicspath{{./}{./figure/}{./img/}{./fig/}{./image/}{./images/}}

% ---------- 中文支持 ----------
\RequirePackage[CJKchecksingle,CJKnumber]{xeCJK}
\RequirePackage{fontspec,xltxtra,xunicode}
\RequireXeTeX

% ---------- 数学 ----------
\let\Zbar\relax                          % 解决 amssymb 与 fontspec 冲突
\RequirePackage{amssymb}
\RequirePackage{amsmath}                 % 公式居中对齐
\RequirePackage{amsthm}                  % 定理环境

% ---------- 标题与目录 ----------
\RequirePackage[sf]{titlesec}            % 标题格式，sf 指定黑体
\RequirePackage{titletoc}                % 目录样式

% ---------- 表格 ----------
\RequirePackage{booktabs}                % 三线表
\RequirePackage{multirow}                % 合并行
\RequirePackage{tabularx}                % 可设宽度的表格
\RequirePackage{array}

% ---------- 图表标题 ----------
\RequirePackage{caption}
\RequirePackage{subcaption}              % 子图

% ---------- 引用与参考文献 ----------
\RequirePackage[sort&compress,numbers]{natbib}

% ---------- 算法 ----------
\RequirePackage{algorithm}
\RequirePackage{algpseudocode}
\floatname{algorithm}{算法}
\numberwithin{algorithm}{section}

% ---------- 行距与间距 ----------
\RequirePackage{setspace}
\onehalfspacing

% ---------- 定理 ----------
\RequirePackage{thmtools}

% ---------- 其他 ----------
\RequirePackage{ifxetex,ifpdf}
\RequirePackage{perpage}
\RequirePackage{pifont}
\RequirePackage{hyperref}
\RequirePackage{pdfpages}                % 插入 PDF 页面（任务书等）
\RequirePackage{calc}
\RequirePackage{etoolbox}

% ---------- 超链接设置 ----------
\hypersetup{
    unicode=false,
    hyperfootnotes=true,
    hyperindex=true,
    pageanchor=true,
    CJKbookmarks=true,
    bookmarksnumbered=true,
    bookmarksopen=true,
    bookmarksopenlevel=0,
    breaklinks=true,
    colorlinks=false,
    plainpages=false,
    pdfpagelabels,
    pdfborder=0 0 0
}

% ---------- 公式间距调整 ----------
\apptocmd\normalsize{%
    \abovedisplayskip=6pt
    \abovedisplayshortskip=4pt
    \belowdisplayskip=6pt
    \belowdisplayshortskip=4pt
}{}{}

% 从这里开始 @ 作为字母，直到文件末尾
\makeatletter

%% ============================================================================
%%  3. 用户命令（在 .tex 文件 preamble 中设置）
%% ============================================================================

% --- 基本信息 ---
\renewcommand\title[2]{\gdef\XJTU@title@cn{#1}\gdef\XJTU@title@en{#2}}
\def\XJTU@title@cn{\@latex@warning@no@line{No \noexpand\title for cn given}}
\def\XJTU@title@en{\@latex@warning@no@line{No \noexpand\title for en given}}

\renewcommand\author[2]{\gdef\XJTU@author@cn{#1}\gdef\XJTU@author@en{#2}}
\def\XJTU@author@cn{\@latex@warning@no@line{No \noexpand\author for cn given}}
\def\XJTU@author@en{\@latex@warning@no@line{No \noexpand\author for en given}}

\def\advisor#1#2{\gdef\XJTU@advisor@cn{#1}\gdef\XJTU@advisor@en{#2}}
\def\XJTU@advisor@cn{\@latex@warning@no@line{No \noexpand\advisor for cn given}}
\def\XJTU@advisor@en{\@latex@warning@no@line{No \noexpand\advisor for en given}}

\def\college#1{\gdef\XJTU@college{#1}}
\def\XJTU@college{\@latex@warning@no@line{No \noexpand\college given}}

\def\department#1{\gdef\XJTU@department{#1}}
\def\XJTU@department{\@latex@warning@no@line{No \noexpand\department given}}

\def\class#1{\gdef\XJTU@class{#1}}
\def\XJTU@class{\@latex@warning@no@line{No \noexpand\class given}}

\def\studentid#1{\gdef\XJTU@studentid{#1}}
\def\XJTU@studentid{\@latex@warning@no@line{No \noexpand\studentid given}}

\def\place#1{\gdef\XJTU@place{#1}}
\def\XJTU@place{\@latex@warning@no@line{No \noexpand\place given}}

% --- 日期（格式：YYYY/MM/DD）---
\def\XJTU@begindate#1/#2/#3.{\gdef\XJTU@byear{#1}\gdef\XJTU@bmonth{#2}\gdef\XJTU@bday{#3}}
\def\bdate#1{{\edef\XJTU@tempbdate{#1}\expandafter\XJTU@begindate\XJTU@tempbdate.}}
\def\XJTU@enddate#1/#2/#3.{\gdef\XJTU@eyear{#1}\gdef\XJTU@emonth{#2}\gdef\XJTU@eday{#3}}
\def\edate#1{{\edef\XJTU@tempedate{#1}\expandafter\XJTU@enddate\XJTU@tempedate.}}
\def\XJTU@byear{\@latex@warning@no@line{No \noexpand\bdate given}}
\def\XJTU@bmonth{\@latex@warning@no@line{No \noexpand\bdate given}}
\def\XJTU@bday{\@latex@warning@no@line{No \noexpand\bdate given}}
\def\XJTU@eyear{\@latex@warning@no@line{No \noexpand\edate given}}
\def\XJTU@emonth{\@latex@warning@no@line{No \noexpand\edate given}}
\def\XJTU@eday{\@latex@warning@no@line{No \noexpand\edate given}}

%% ============================================================================
%%  4. 基础排版设置
%% ============================================================================
\renewcommand{\baselinestretch}{1.2}     % 1.2 倍行距
\setlength{\parindent}{2em}              % 首行缩进 2 字符

%% ============================================================================
%%  5. 字体配置
%% ============================================================================

% --- Windows ---
\newcommand*{\xjtu@ChineseFont@songti@win}{SimSun}
\newcommand*{\xjtu@ChineseFont@heiti@win}{SimHei}
\newcommand*{\xjtu@ChineseFont@kaishu@win}{KaiTi}
\newcommand*{\xjtu@ChineseFont@fangsong@win}{FangSong}
\newcommand*{\xjtu@EnglishFont@main@win}{Times New Roman}
\newcommand*{\xjtu@EnglishFont@sans@win}{Arial}
\newcommand*{\xjtu@EnglishFont@mono@win}{Courier New}

% --- Linux（Noto CJK / Liberation）---
\newcommand*{\xjtu@ChineseFont@songti@linux}{Noto Serif CJK SC}
\newcommand*{\xjtu@ChineseFont@heiti@linux}{Noto Sans CJK SC}
\newcommand*{\xjtu@ChineseFont@kaishu@linux}{Noto Serif CJK SC}
\newcommand*{\xjtu@ChineseFont@fangsong@linux}{Noto Sans CJK SC}
\newcommand*{\xjtu@EnglishFont@main@linux}{Liberation Serif}
\newcommand*{\xjtu@EnglishFont@sans@linux}{Liberation Sans}
\newcommand*{\xjtu@EnglishFont@mono@linux}{Liberation Mono}

% --- macOS ---
\newcommand*{\xjtu@ChineseFont@songti@mac}{STSong}
\newcommand*{\xjtu@ChineseFont@heiti@mac}{STHeiti}
\newcommand*{\xjtu@ChineseFont@kaishu@mac}{STKaiti}
\newcommand*{\xjtu@ChineseFont@fangsong@mac}{STFangsong}
\newcommand*{\xjtu@EnglishFont@main@mac}{Times}
\newcommand*{\xjtu@EnglishFont@sans@mac}{Helvetica}
\newcommand*{\xjtu@EnglishFont@mono@mac}{Courier}

% --- 按平台选择字体 ---
\newcommand{\win}{%
    \def\xjtu@ChineseFont@songti{\xjtu@ChineseFont@songti@win}
    \def\xjtu@ChineseFont@heiti{\xjtu@ChineseFont@heiti@win}
    \def\xjtu@ChineseFont@kaishu{\xjtu@ChineseFont@kaishu@win}
    \def\xjtu@ChineseFont@fangsong{\xjtu@ChineseFont@fangsong@win}
    \def\xjtu@EnglishFont@main{\xjtu@EnglishFont@main@win}
    \def\xjtu@EnglishFont@sans{\xjtu@EnglishFont@sans@win}
    \def\xjtu@EnglishFont@mono{\xjtu@EnglishFont@mono@win}
}
\newcommand{\linux}{%
    \def\xjtu@ChineseFont@songti{\xjtu@ChineseFont@songti@linux}
    \def\xjtu@ChineseFont@heiti{\xjtu@ChineseFont@heiti@linux}
    \def\xjtu@ChineseFont@kaishu{\xjtu@ChineseFont@kaishu@linux}
    \def\xjtu@ChineseFont@fangsong{\xjtu@ChineseFont@fangsong@linux}
    \def\xjtu@EnglishFont@main{\xjtu@EnglishFont@main@linux}
    \def\xjtu@EnglishFont@sans{\xjtu@EnglishFont@sans@linux}
    \def\xjtu@EnglishFont@mono{\xjtu@EnglishFont@mono@linux}
}
\newcommand{\mac}{%
    \def\xjtu@ChineseFont@songti{\xjtu@ChineseFont@songti@mac}
    \def\xjtu@ChineseFont@heiti{\xjtu@ChineseFont@heiti@mac}
    \def\xjtu@ChineseFont@kaishu{\xjtu@ChineseFont@kaishu@mac}
    \def\xjtu@ChineseFont@fangsong{\xjtu@ChineseFont@fangsong@mac}
    \def\xjtu@EnglishFont@main{\xjtu@EnglishFont@main@mac}
    \def\xjtu@EnglishFont@sans{\xjtu@EnglishFont@sans@mac}
    \def\xjtu@EnglishFont@mono{\xjtu@EnglishFont@mono@mac}
}

\ifXJTU@Mac   \mac   \fi
\ifXJTU@Linux \linux \fi
\ifXJTU@Win   \win   \fi

% --- 设置主字体 ---
% 英文衬线（正文）：Times New Roman / Liberation Serif
% 中文正文：宋体，粗体→黑体，斜体→楷书
% 无衬线：黑体（用于标题）
\defaultfontfeatures{Mapping=tex-text}
\setromanfont[Mapping=tex-text]{\xjtu@EnglishFont@main}
\setsansfont[Scale=MatchLowercase,Mapping=tex-text]{\xjtu@EnglishFont@sans}
\setmonofont[Scale=MatchLowercase]{\xjtu@EnglishFont@mono}
\setCJKmainfont[BoldFont={\xjtu@ChineseFont@heiti},%
                ItalicFont={\xjtu@ChineseFont@kaishu}]%
               {\xjtu@ChineseFont@songti}
\setCJKsansfont{\xjtu@ChineseFont@heiti}
\setCJKmonofont{\xjtu@ChineseFont@fangsong}
\punctstyle{hangmobanjiao}               % 标点悬挂于行末半角

%% ============================================================================
%%  6. 字号定义
%% ============================================================================
% 两组字号命令均可使用：
%   \erhao, \xiaoerhao, \sihao ...（中文名，不设行距）
%   \two, \stwo, \four ...       （英文名，含行距）

% --- 中文名字号 ---
\newcommand{\chuhao}{\fontsize{42pt}{\baselineskip}\selectfont}
\newcommand{\xiaochuhao}{\fontsize{36pt}{\baselineskip}\selectfont}
\newcommand{\yihao}{\fontsize{28pt}{\baselineskip}\selectfont}
\newcommand{\erhao}{\fontsize{21pt}{\baselineskip}\selectfont}
\newcommand{\xiaoerhao}{\fontsize{18pt}{\baselineskip}\selectfont}
\newcommand{\sanhao}{\fontsize{15.75pt}{\baselineskip}\selectfont}
\newcommand{\xiaosanhao}{\fontsize{15pt}{\baselineskip}\selectfont}
\newcommand{\sihao}{\fontsize{14pt}{\baselineskip}\selectfont}
\newcommand{\xiaosihao}{\fontsize{12pt}{\baselineskip}\selectfont}
\newcommand{\wuhao}{\fontsize{10.5pt}{}\selectfont}
\newcommand{\xiaowuhao}{\fontsize{9pt}{\baselineskip}\selectfont}
\newcommand{\liuhao}{\fontsize{7.875pt}{\baselineskip}\selectfont}
\newcommand{\qihao}{\fontsize{5.25pt}{\baselineskip}\selectfont}

% --- 英文名字号（含行距，用于数学公式缩放参考）---
\newcommand*{\xjtu@FontSize@eight}{5.02}    \newcommand*{\xjtu@FontSize@eightskip}{6.02}
\newcommand*{\xjtu@FontSize@seven}{5.52}    \newcommand*{\xjtu@FontSize@sevenskip}{6.62}
\newcommand*{\xjtu@FontSize@ssix}{6.52}     \newcommand*{\xjtu@FontSize@ssixskip}{7.83}
\newcommand*{\xjtu@FontSize@six}{7.53}      \newcommand*{\xjtu@FontSize@sixskip}{9.03}
\newcommand*{\xjtu@FontSize@sfive}{9.03}    \newcommand*{\xjtu@FontSize@sfiveskip}{10.84}
\newcommand*{\xjtu@FontSize@five}{10.54}    \newcommand*{\xjtu@FontSize@fiveskip}{12.65}
\newcommand*{\xjtu@FontSize@sfour}{12.05}   \newcommand*{\xjtu@FontSize@sfourskip}{14.45}
\newcommand*{\xjtu@FontSize@four}{14.05}    \newcommand*{\xjtu@FontSize@fourskip}{16.86}
\newcommand*{\xjtu@FontSize@sthree}{15.06}  \newcommand*{\xjtu@FontSize@sthreeskip}{18.07}
\newcommand*{\xjtu@FontSize@three}{16.06}   \newcommand*{\xjtu@FontSize@threeskip}{19.27}
\newcommand*{\xjtu@FontSize@stwo}{18.07}    \newcommand*{\xjtu@FontSize@stwoskip}{21.68}
\newcommand*{\xjtu@FontSize@two}{22.08}     \newcommand*{\xjtu@FontSize@twoskip}{26.50}
\newcommand*{\xjtu@FontSize@sone}{24.09}    \newcommand*{\xjtu@FontSize@soneskip}{28.91}
\newcommand*{\xjtu@FontSize@one}{26.10}     \newcommand*{\xjtu@FontSize@oneskip}{31.32}
\newcommand*{\xjtu@FontSize@szero}{36.14}   \newcommand*{\xjtu@FontSize@szeroskip}{43.36}
\newcommand*{\xjtu@FontSize@zero}{42.16}    \newcommand*{\xjtu@FontSize@zeroskip}{50.59}

\newcommand{\zero}{\fontsize{\xjtu@FontSize@zero}{\xjtu@FontSize@zeroskip}\selectfont}
\newcommand{\szero}{\fontsize{\xjtu@FontSize@szero}{\xjtu@FontSize@szeroskip}\selectfont}
\newcommand{\one}{\fontsize{\xjtu@FontSize@one}{\xjtu@FontSize@oneskip}\selectfont}
\newcommand{\sone}{\fontsize{\xjtu@FontSize@sone}{\xjtu@FontSize@soneskip}\selectfont}
\newcommand{\two}{\fontsize{\xjtu@FontSize@two}{\xjtu@FontSize@twoskip}\selectfont}
\newcommand{\stwo}{\fontsize{\xjtu@FontSize@stwo}{\xjtu@FontSize@stwoskip}\selectfont}
\newcommand{\three}{\fontsize{\xjtu@FontSize@three}{\xjtu@FontSize@threeskip}\selectfont}
\newcommand{\sthree}{\fontsize{\xjtu@FontSize@sthree}{\xjtu@FontSize@sthreeskip}\selectfont}
\newcommand{\four}{\fontsize{\xjtu@FontSize@four}{\xjtu@FontSize@fourskip}\selectfont}
\newcommand{\sfour}{\fontsize{\xjtu@FontSize@sfour}{\xjtu@FontSize@sfourskip}\selectfont}
\newcommand{\five}{\fontsize{\xjtu@FontSize@five}{\xjtu@FontSize@fiveskip}\selectfont}
\newcommand{\sfive}{\fontsize{\xjtu@FontSize@sfive}{\xjtu@FontSize@sfiveskip}\selectfont}
\newcommand{\six}{\fontsize{\xjtu@FontSize@six}{\xjtu@FontSize@sixskip}\selectfont}
\newcommand{\ssix}{\fontsize{\xjtu@FontSize@ssix}{\xjtu@FontSize@ssixskip}\selectfont}
\newcommand{\seven}{\fontsize{\xjtu@FontSize@seven}{\xjtu@FontSize@sevenskip}\selectfont}
\newcommand{\eight}{\fontsize{\xjtu@FontSize@eight}{\xjtu@FontSize@eightskip}\selectfont}

%% ============================================================================
%%  7. 各级标题格式
%% ============================================================================
% 一级标题：三号黑体居中，段前 2 行段后 1 行
% 二级标题：小三号黑体，段前 1 行段后 0.5 行
% 三级标题：四号黑体缩进，段前 0.5 行段后 0 行

\newcommand{\sectionbreak}{\cleardoublepage \null}

\titleformat{\section}
    [hang]
    {\centering\three}
    {\thesection}
    {1em}{}[]
\titleformat{\subsection}
    [hang]
    {\sthree}
    {\thesubsection}
    {1em}{}[]
\titleformat{\subsubsection}
    [hang]
    {\four}
    {\hspace{4ex}\thesubsubsection}
    {1em}{}[]

\titlespacing{\section}
    {0pt}
    {2\baselineskip plus 1ex minus .2ex}
    {1\baselineskip plus .2ex}
\titlespacing{\subsection}
    {0pt}
    {1\baselineskip plus 1ex minus .2ex}
    {.5\baselineskip plus .2ex}
\titlespacing{\subsubsection}
    {0pt}
    {.5\baselineskip plus 1ex minus .2ex}
    {0pt plus .2ex}

%% ============================================================================
%%  8. 页眉页脚
%% ============================================================================

% --- 前置/后置部分页眉（只显示校名）---
\newpagestyle{main}{
    \setlength{\headheight}{0.7cm}
    \sethead[][\five 西安交通大学本科毕业设计（论文）][]
            {}{\five \sectiontitle}{}
    \setfoot[\five\thepage][][]
            {}{}{\five\thepage}
    \renewcommand{\makeheadrule}{%
        \makebox[0pt][l]{\rule[-0.28\baselineskip]{\linewidth}{0.5pt}}%
        \rule[-0.34\baselineskip]{\linewidth}{0.5pt}}
}

% --- 正文页眉（显示校名 + 章节标题）---
\newpagestyle{document}{
    \setlength{\headheight}{0.7cm}
    \sethead[][\five 西安交通大学本科毕业设计（论文）][]
            {}{\five \thesection \quad \sectiontitle}{}
    \setfoot[\five\thepage][][]
            {}{}{\five\thepage}
    \renewcommand{\makeheadrule}{%
        \makebox[0pt][l]{\rule[-0.28\baselineskip]{\linewidth}{0.5pt}}%
        \rule[-0.34\baselineskip]{\linewidth}{0.5pt}}
}

% --- 页脚位置 ---
\setlength{\footskip}{\paperheight
    -(1in+\voffset+\topmargin+\headheight+\headsep+\textheight)
    -0.75in}

%% ============================================================================
%%  9. frontmatter / mainmatter / backmatter
%% ============================================================================

\newcommand\frontmatter{%
    \cleardoublepage
    \pagestyle{main}
    \pagenumbering{Roman}}

\newcommand\mainmatter{%
    \cleardoublepage
    \pagestyle{document}
    \pagenumbering{arabic}}

\newcommand\backmatter{%
    \cleardoublepage
    \pagestyle{main}}

%% ============================================================================
%%  10. 封面页
%% ============================================================================
% 在 .tex 中通过以下命令设置封面信息：
%   \title{中文题目}{English Title}
%   \author{中文名}{English Name}
%   \advisor{导师中文}{Advisor English}
%   \college{学院}  \department{专业}  \class{班级}
%   \studentid{学号}  \edate{YYYY/MM/DD}
% 然后调用 \makecover 生成封面。

\newcommand{\makecover}{
    \cleardoublepage
    \thispagestyle{empty}
    \begin{center}
        \vspace*{0.5cm}
        % 校徽 + 校名
        \includegraphics[width=0.65\textwidth]{figure/xjtu_emblem.png}

        \vspace{0.3cm}
        % 红色横线
        {\color{red}\rule{0.5\textwidth}{0.4pt}}

        \vspace{1cm}
        % 论文类型（宋体二号）
        {\erhao 本科毕业设计（论文）}

        \vspace{1.5cm}
        % 论文题目（宋体小二号）
        {\xiaoerhao \XJTU@title@cn}

        \vspace{2.5cm}
        % 信息栏（宋体四号）
        {\sihao
        \begin{tabular}{r@{\quad}l}
            学院（部、中心）： & \XJTU@college \\
            专\qquad 业：     & \XJTU@department \\
            班\qquad 级：     & \XJTU@class \\
            学生姓名：         & \XJTU@author@cn \\
            学\qquad 号：     & \XJTU@studentid \\
            指导教师：         & \XJTU@advisor@cn \\
        \end{tabular}
        }

        \vspace{2cm}
        % 日期
        {\sihao \XJTU@eyear{}年\XJTU@emonth{}月}

        \vfill
        % 红色注释
        {\xiaowuhao\textcolor{red}{（注：X均为阿拉伯数字，如2025年06月）}}
    \end{center}
    \clearpage
}

%% ============================================================================
%%  11. 摘要页
%% ============================================================================

% --- 中文摘要 ---
% 标题："摘  要"，三号宋体居中，段前 2 行段后 1 行
% 正文：小四号宋体，行距 1.2 倍
% 关键词：小四号宋体加粗
\newcommand\XJTU@abstract@cn{\three 摘\hspace{2ex}要}
\newenvironment{abstractcn}{%
    \cleardoublepage
    \sectionmark{ 摘要}
    \setcounter{page}{5}
    \begin{center}
        {\vspace*{2\baselineskip plus 1ex minus .2ex}%
         \XJTU@abstract@cn
         \vspace*{1\baselineskip plus 1ex minus .2ex}}
    \end{center}
}{\par}

\newcommand{\keywordscn}[1]{%
    \vspace{\baselineskip}\par\noindent
    {\sfour {\bfseries 关\hspace{1ex}键\hspace{1ex}词\hspace{0.5ex}：}#1}}

% --- 英文摘要 ---
% 标题："ABSTRACT"，三号居中
% 正文段首不缩进，段间距 1em
\newcommand\XJTU@abstract@en{\three ABSTRACT}
\newenvironment{abstracten}{%
    \cleardoublepage
    \sectionmark{ ABSTRACT}
    \begin{center}
        {\vspace*{2\baselineskip plus 1ex minus .2ex}%
         \XJTU@abstract@en
         \vspace*{1\baselineskip plus 1ex minus .2ex}}
    \end{center}\par
    \setlength\parskip{1em}
    \setlength\parindent{0em}
}{%
    \setlength\parskip{0.1em}
    \setlength\parindent{2ex}
    \par}

\newcommand{\keywordsen}[1]{%
    \vspace{\baselineskip}\par\noindent
    {\sfour {\bfseries KEY WORDS:} #1}}

%% ============================================================================
%%  12. 目录
%% ============================================================================

\let\oldtableofcontents\tableofcontents
\renewcommand{\tableofcontents}{%
    \cleardoublepage
    \sectionmark{目录}
    \oldtableofcontents
}

\renewcommand{\contentsname}{目\hspace{2ex}录}

% --- 目录样式 ---
\titlecontents{section}[0mm]
    {\vspace{0pt}}
    {\normalsize{\thecontentslabel}~\hspace{.5em}}
    {}
    {\dotfill\contentspage[{\makebox[0pt][r]{\thecontentspage}}]}
    [\vspace{0pt}]
\titlecontents{subsection}[2ex]
    {\vspace{0pt}}
    {\normalsize{\thecontentslabel}~\hspace{.5em}}
    {}
    {\dotfill\contentspage[{\makebox[0pt][r]{\thecontentspage}}]}
    [\vspace{0pt}]
\titlecontents{subsubsection}[4ex]
    {\vspace{0pt}}
    {\normalsize{\thecontentslabel}~\hspace{.5em}}
    {}
    {\dotfill\contentspage[{\makebox[0pt][r]{\thecontentspage}}]}
    [\vspace{0pt}]

%% ============================================================================
%%  13. 图表公式编号
%% ============================================================================
% 编号格式：X-Y（章号-序号）

\captionsetup{labelformat=simple,labelsep=quad,font=small}
\captionsetup[table]{position=top}
\captionsetup[figure]{position=bottom}

\numberwithin{figure}{section}
\numberwithin{table}{section}
\numberwithin{equation}{section}

\renewcommand{\thefigure}{\arabic{section}-\arabic{figure}}
\renewcommand{\thetable}{\arabic{section}-\arabic{table}}
\renewcommand*{\theequation}{\arabic{section}-\arabic{equation}}

\renewcommand*{\figurename}{图}
\renewcommand*{\tablename}{表}

% \topcaption — 表题在表上方
\newcommand{\topcaption}[1]{%
    \setlength{\abovecaptionskip}{0.5\baselineskip}%
    \setlength{\belowcaptionskip}{0.5\baselineskip}%
    \caption{#1}}

% \downcaption — 图题在图下方
\newcommand{\downcaption}[1]{%
    \setlength{\abovecaptionskip}{0.5\baselineskip}%
    \setlength{\belowcaptionskip}{0.5\baselineskip}%
    \caption{#1}}

%% ============================================================================
%%  14. 主要符号表
%% ============================================================================

\newenvironment{denotation}{%
    \cleardoublepage
    \refstepcounter{section}
    \section*{主要符号表}
    \sectionmark{主要符号表}
    \addcontentsline{toc}{section}{主要符号表}
    \begin{list}{}{%
        \renewcommand{\makelabel}[1]{##1\hfil}
        \vskip-30bp\normalsize
        \setlength{\labelwidth}{2.5cm}
        \setlength{\labelsep}{0.5cm}
        \setlength{\itemindent}{ex}
        \setlength{\leftmargin}{3cm}
        \setlength{\rightmargin}{0cm}
        \setlength{\parsep}{0cm}
        \setlength{\itemsep}{0cm}
        \setlength{\listparindent}{0cm}
        \setlength{\topsep}{0pt}
    }
}{\end{list}}

%% ============================================================================
%%  15. 附录
%% ============================================================================

\newcounter{appends}
\setcounter{appends}{0}

\newcommand{\appendixs}[1]{%
    \cleardoublepage
    \refstepcounter{appends}
    \stepcounter{section}
    \sectionmark{ 附录\Alph{appends}  \hspace{0.15cm}#1}
    \section*{附录\Alph{appends}  \hspace{0.15cm}#1}
    \addcontentsline{toc}{section}{附录\Alph{appends} \hspace{0.15cm}#1}
}

%% ============================================================================
%%  16. 参考文献
%% ============================================================================

\let\oldbibliography\bibliography
\renewcommand{\bibliography}[1]{%
    \cleardoublepage
    \refstepcounter{section}%
    \sectionmark{参考文献}
    \addcontentsline{toc}{section}{参考文献}
    \oldbibliography{#1}
}

\bibliographystyle{xjtuBib}
\setcitestyle{square}
\def\bibfont{\five}                       % 五号字
\setlength{\bibsep}{0pt plus 0.2ex}       % 参考文献条目间距
\renewcommand*{\refname}{参考文献}

% 参考文献标题：三号宋体居中，段前2行段后1行（覆盖 natbib 默认的 \section*）
\renewcommand\bibsection{%
    \sectionmark{参考文献}%
    \begin{center}%
        {\vspace*{2\baselineskip plus 1ex minus .2ex}%
         \three 参考文献%
         \vspace*{1\baselineskip plus 1ex minus .2ex}}%
    \end{center}}

% \upcite — 上标引用，如 ^[1]
\newcommand{\upcite}[1]{\textsuperscript{\cite{#1}}}

% 带页码的上标引用支持
\renewcommand\NAT@citesuper[3]{%
    \ifNAT@swa
        \if*#2*\else#2\NAT@spacechar\fi
        \unskip\kern\p@\textsuperscript{\NAT@@open#1\NAT@@close#3}
    \else #1\fi\endgroup
}

% \ref 前加细空格，\eqref 加圆括号
\AtBeginDocument{%
    \let\oldref\ref
    \renewcommand*{\ref}[1]{\thinspace\oldref{#1}}
    \renewcommand*{\eqref}[1]{(\oldref{#1})}
}

%% ============================================================================
%%  17. 脚注
%% ============================================================================
% 使用带圆圈的数字编号（①②③...），每页重新编号

\renewcommand\thefootnote{\ding{\numexpr171+\value{footnote}}}
\MakePerPage{footnote}

%% ============================================================================
%%  18. 致谢
%% ============================================================================

\newcommand{\XJTU@acknowledgment}{致\hspace{2ex}谢}
\newenvironment{acknowledgment}{%
    \cleardoublepage
    \refstepcounter{section}
    \section*{\XJTU@acknowledgment}
    \sectionmark{致谢}
    \addcontentsline{toc}{section}{致谢}
}{\par}

%% ============================================================================
%%  19. 数学字体与公式字号缩放
%% ============================================================================

\RequirePackage{newtxmath}

\DeclareMathSizes{\xjtu@FontSize@eight}{\xjtu@FontSize@eight}{5}{5}
\DeclareMathSizes{\xjtu@FontSize@seven}{\xjtu@FontSize@seven}{5}{5}
\DeclareMathSizes{\xjtu@FontSize@ssix}{\xjtu@FontSize@ssix}{5}{5}
\DeclareMathSizes{\xjtu@FontSize@six}{\xjtu@FontSize@six}{5}{5}
\DeclareMathSizes{\xjtu@FontSize@sfive}{\xjtu@FontSize@sfive}{6}{5}
\DeclareMathSizes{\xjtu@FontSize@five}{\xjtu@FontSize@five}{7}{5}
\DeclareMathSizes{\xjtu@FontSize@sfour}{\xjtu@FontSize@sfour}{8}{6}
\DeclareMathSizes{\xjtu@FontSize@four}{\xjtu@FontSize@four}{\xjtu@FontSize@five}{\xjtu@FontSize@six}
\DeclareMathSizes{\xjtu@FontSize@sthree}{\xjtu@FontSize@sthree}{\xjtu@FontSize@sfour}{\xjtu@FontSize@sfive}
\DeclareMathSizes{\xjtu@FontSize@three}{\xjtu@FontSize@three}{\xjtu@FontSize@four}{\xjtu@FontSize@five}
\DeclareMathSizes{\xjtu@FontSize@stwo}{\xjtu@FontSize@stwo}{\xjtu@FontSize@sthree}{\xjtu@FontSize@sfour}
\DeclareMathSizes{\xjtu@FontSize@two}{\xjtu@FontSize@two}{\xjtu@FontSize@three}{\xjtu@FontSize@four}
\DeclareMathSizes{\xjtu@FontSize@sone}{\xjtu@FontSize@sone}{\xjtu@FontSize@stwo}{\xjtu@FontSize@sthree}
\DeclareMathSizes{\xjtu@FontSize@one}{\xjtu@FontSize@one}{\xjtu@FontSize@two}{\xjtu@FontSize@three}
\DeclareMathSizes{\xjtu@FontSize@szero}{\xjtu@FontSize@szero}{\xjtu@FontSize@sone}{\xjtu@FontSize@stwo}
\DeclareMathSizes{\xjtu@FontSize@zero}{\xjtu@FontSize@zero}{\xjtu@FontSize@one}{\xjtu@FontSize@two}

%% ============================================================================
%%  20. 定理/定义等环境
%% ============================================================================

\renewcommand{\proofname}{\normalfont\bfseries 证明}
\renewenvironment{proof}[1][\hskip 2ex \proofname]{\par
    \pushQED{\qed}%
    \normalfont \topsep6\p@\@plus6\p@\relax
    \trivlist
        \item[\hskip\labelsep\itshape#1\@addpunct{}]\ignorespaces
}{%
    \popQED\endtrivlist\@endpefalse
}

\declaretheoremstyle[
    spaceabove=6pt, spacebelow=6pt,
    headfont=\normalfont\bfseries,
    notefont=\mdseries, notebraces={(}{)},
    bodyfont=\normalfont,
    postheadspace=1em,
    headindent=2ex,
    headpunct={},
]{theoremstyle}

% --- 定理类名称 ---
\newcommand*{\xjtu@cap@definition}{定义}
\newcommand*{\xjtu@cap@notation}{记号}
\newcommand*{\xjtu@cap@theorem}{定理}
\newcommand*{\xjtu@cap@lemma}{引理}
\newcommand*{\xjtu@cap@corollary}{推论}
\newcommand*{\xjtu@cap@proposition}{命题}
\newcommand*{\xjtu@cap@fact}{事实}
\newcommand*{\xjtu@cap@assumption}{假设}
\newcommand*{\xjtu@cap@conjecture}{猜想}
\newcommand*{\xjtu@cap@hypothesis}{假说}
\newcommand*{\xjtu@cap@axiom}{公理}
\newcommand*{\xjtu@cap@postulate}{公设}
\newcommand*{\xjtu@cap@principle}{定律}
\newcommand*{\xjtu@cap@problem}{问题}
\newcommand*{\xjtu@cap@exercise}{练习}
\newcommand*{\xjtu@cap@example}{例}
\newcommand*{\xjtu@cap@remark}{评注}

% --- 注册定理环境 ---
\newtheorem{definition}{\xjtu@cap@definition}[section]
\newtheorem{notation}[definition]{\xjtu@cap@notation}
\newtheorem{theorem}{\xjtu@cap@theorem}[section]
\newtheorem{lemma}[theorem]{\xjtu@cap@lemma}
\newtheorem{corollary}[theorem]{\xjtu@cap@corollary}
\newtheorem{proposition}[theorem]{\xjtu@cap@proposition}
\newtheorem{fact}[theorem]{\xjtu@cap@fact}
\newtheorem{assumption}[theorem]{\xjtu@cap@assumption}
\newtheorem{conjecture}[theorem]{\xjtu@cap@conjecture}
\newtheorem{hypothesis}{\xjtu@cap@hypothesis}[section]
\newtheorem{axiom}{\xjtu@cap@axiom}[section]
\newtheorem{postulate}{\xjtu@cap@postulate}[section]
\newtheorem{principle}{\xjtu@cap@principle}[section]
\newtheorem{problem}{\xjtu@cap@problem}[section]
\newtheorem{exercise}{\xjtu@cap@exercise}[section]
\newtheorem{example}{\xjtu@cap@example}[section]
\newtheorem{remark}{\xjtu@cap@remark}[section]

%% ============================================================================
%%  21. 目录点线样式
%% ============================================================================

\def\@dotsep{2}

\def\@dottedtocline#1#2#3#4#5{%
    \ifnum #1>\c@tocdepth \else
        \vskip \z@ \@plus.2\p@
        {\leftskip #2\relax \rightskip \@tocrmarg \parfillskip -\rightskip
         \parindent #2\relax\@afterindenttrue
         \interlinepenalty\@M
         \leavevmode
         \@tempdima #3\relax
         \advance\leftskip \@tempdima \null\nobreak\hskip -\leftskip
         {#4}\nobreak
         \leaders\hbox{$\m@th\mkern 1.5mu\cdot\mkern 1.5mu$}\hfill
         \nobreak
         \hb@xt@\@pnumwidth{\hfil\normalfont \normalcolor #5}%
         \par}%
    \fi}

% Section 目录是否加点线（默认关闭）
\newif\ifXJTU@SectionDotInContent \XJTU@SectionDotInContentfalse

\ifXJTU@SectionDotInContent
    \renewcommand*\l@section[2]{%
        \ifnum \c@tocdepth >\m@ne
            \addpenalty{-\@highpenalty}%
            \vskip 1.0em \@plus\p@
            \setlength\@tempdima{2em}%
            \begingroup
                \parindent \z@ \rightskip \@pnumwidth
                \parfillskip -\@pnumwidth
                \leavevmode \bfseries
                \advance\leftskip\@tempdima
                \hskip -\leftskip
                #1\nobreak
                \xleaders\hbox{$\m@th\mkern 1.5mu\cdot\mkern 1.5mu$}\hfill
                \nobreak\hb@xt@\@pnumwidth{\hss #2}\par
                \penalty\@highpenalty
            \endgroup
        \fi}
\fi

%% ============================================================================
%%  22. 全局段间距
%% ============================================================================

\AtBeginDocument{\setlength\parskip{0.1em}}

\makeatother

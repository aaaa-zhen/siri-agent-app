# BLOCK-SPECS — iOS 27 Siri Generative UI (AgentCanvasUICore) 排版规范

来源：`/fallback-demos/images/` 13 张真实 harness 截图，逐张量化 → 换算成 pt。
对照：`agent/agent/Render/BlockView.swift` + `agent/agent/Theme/Theme.swift`。

---

## 0. 标定 (calibration) — px→pt 换算

| 项 | 值 | 置信度 |
|---|---|---|
| 截图设备逻辑宽度 | **420 pt** (IMG_4946 原始像素 1260×2736 @3x → 1260/3 = 420) | 直接量到 |
| 像素→pt 比 | **÷3** (@3x) | 直接量到 |
| 其余 12 张 | 经显示端缩放，但**版式比例一致**，按内容宽度归一化后等同 420pt 画布 | 推测 |
| 内容左右边距 | 截图 ≈ 内容从左缘约 20pt 起；与 App 现 `padding(.horizontal, 20)` 一致 | 量到，置信高 |
| 锚点字号 | 导航标题 "Core Response / Callout / …" = iOS 标准 **17pt semibold**，用作所有图的跨图标尺 | 标准值 |

> 颜色规则：截图是**白底黑字**，App 是**纯黑底白字**。
> 「黑字」→ `Theme.text`(白)；「灰字」按估算的黑底透明度 → `Theme.text.opacity(x)`。
> **字号 / 字重 / 间距 / 圆角 / tracking 不受明暗影响，直接用。**
> 截图里灰字是「白底上的黑色 opacity」，反相到黑底应近似相同 opacity（人眼对比度对称，置信中）。

App 现有灰阶：`text2 = white.opacity(0.62)`，`text3 = white.opacity(0.40)`。
建议补一档 `text2 = 0.60`、新增 `textTertiary = 0.45`、`labelGray = 0.50`（大写小标签）。

---

## 1. Callout / Primary Answer (IMG_4948)

大数值答案块：正文导语 → 超大数值+单位 → 第二组数值 → 描述段。中间有 hairline 分隔。

| 元素 | 量出真值 (pt / 字重 / 灰阶) | 当前 BlockView | 建议改成 |
|---|---|---|---|
| 导语 "Mount Everest is the highest…" | 17pt regular，黑 (→白) | `.text` 块 17pt ✓ | 保持 17pt regular `Theme.text` |
| 大数值 "8,849" | **≈54pt**，weight **regular/light**(细笔画)，纯黑(→白) | `primarySize = 76`, weight `.light` | **54pt**, `.regular`（76 太大） |
| 单位 "m"/"ft" | **≈26pt**，regular，**中灰 ~0.55**(→ `text.opacity(0.55)`) | unit 30pt `.text2`(0.62) | 26pt, opacity 0.55, baseline 对齐 |
| 第二数值 "29,032" | 同上 54pt | — | 同上；两组之间 hairline 分隔 |
| hairline 分隔线 | 0.5pt，灰 ~0.12 | `Theme.hairline 0.12` ✓ | 保持 |
| 描述段 | 17pt regular，**中灰 ~0.60**(→0.60) | callout text 17pt `.text2` ✓ | 保持 17pt opacity 0.60 |
| 数值与上下文行距 | 数值组上下 padding ≈ 8–10pt | — | block gap 内消化 |

**注意**：这其实是 `primaryAnswer`，不是带卡片背景的 callout。截图里**没有卡片底/圆角**——是裸排版。
当前 `.callout` 给了 `cardBG`+`cornerRadius:28` 背景，但真版 callout 数值是**无背景裸排**。callout 背景块应仅用于「带 icon 的提示框」，此图不该套背景。

置信度：字号直接量到(±2pt)；灰阶估算(±0.05)。

---

## 2. Quote / Pull Quote (IMG_4949)

衬线、居中、带破折号署名。上下有普通正文段落环绕。

| 元素 | 量出真值 | 当前 BlockView | 建议改成 |
|---|---|---|---|
| 引言文字 | **≈22pt**，**serif (New York)**，weight **regular→medium**，**居中**，纯黑(→白) | 21pt `.medium` `.serif` center ✓ | 22pt `.regular`/`.medium` serif（现已对，微调到 22） |
| 引号 “ ” | 含在 serif 字体内，无特殊放大 | — | 保持 |
| 署名 "— Sir Edmund Hillary" | **≈15pt**，**non-serif** sans，regular，**中灰 ~0.60**，居中 | 14pt `.text2` | 15pt, sans, opacity 0.60, center |
| 引言↔署名间距 | ≈8pt | spacing 8 ✓ | 保持 |
| 环绕正文 | 17pt regular 黑(→白)，左对齐 | text 块 ✓ | 保持 |
| 块上下留白 | quote 块上下各 ≈10–12pt | `.vertical, 4` | 增到 `.vertical, 8` |

置信度：serif/center/居中 直接确认；字号 ±1.5pt。

---

## 3. Heading — 6 级 + Title/Subtitle (IMG_4950)  ★最全字阶参考

截图结构：H1…H6、Body，然后 Title L1 / Subtitle L1（成对），Title L2/Sub L2，Title L3/Sub L3。

### Heading 6 级（递减规律）
| 级 | 量出真值 | 备注 |
|---|---|---|
| **H1** "Heading Level 1" | **≈28pt bold**，纯黑(→白)，tracking ≈ -0.4 | 最大，bold |
| **H2** "Heading Level 2" | **≈22pt semibold**，黑(→白)，tracking ≈ -0.2 | |
| **H3** "HEADING LEVEL 3" | **≈13pt bold，全大写**，**深灰 ~0.75**，tracking **+0.5～0.8** | 大写小标签风开始 |
| **H4** "HEADING LEVEL 4" | **≈13pt semibold，全大写**，**中灰 ~0.45**，tracking +0.6 | 比 H3 浅 |
| **H5** | 同 H4 字号，灰更浅 ~0.42 | 与 H4 几乎只差色 |
| **H6** | 同上，灰 ~0.40 | 最浅 |
| Body | 17pt regular 黑(→白) | |

> 递减规律：**H1→H2 是真字号递减(28→22)**；**H3–H6 字号几乎不变(全 ~13pt 大写)，靠「字重 + 灰度」递减**（bold/0.75 → semibold/0.45 → /0.42 → /0.40）。

### Title / Subtitle 成对（比 Heading 更大更展示性）
| 元素 | 量出真值 |
|---|---|
| **Title L1** "Title Level 1" | **≈34pt bold**，黑(→白) |
| **Subtitle L1** | **≈34pt bold/semibold**，**中灰 ~0.42**（与 Title 同字号、仅变灰）|
| **Title L2** | **≈24pt semibold**，黑(→白) |
| **Subtitle L2** | **≈24pt regular/medium**，灰 ~0.45 |
| **Title L3** | **≈13pt bold 大写**，深灰（= H3 风）|
| **Subtitle L3** | **≈13pt 大写**，更浅灰 |

| 当前 BlockView (`.heading`) | 建议改成 |
|---|---|
| `level>=3` → 13pt bold uppercase tracking 0.6 `.text2`(0.62)；`level==1`→27pt bold；其余 21pt semibold | H1=**28**, H2=**22 semibold**；H3=13 bold/0.72 大写；H4=13 semibold/0.45；H5/H6 再降到 0.42/0.40；tracking H3+ = **+0.6**。**增加 Title/Subtitle 字阶**：T1=34 bold、T2=24 semibold，Subtitle 同字号变灰(~0.45) |

置信度：H1/H2/Title 字号 ±2pt（直接量大写高度反推）；H3–H6 区分主要靠灰度，灰阶 ±0.06（推测）。

---

## 4. Divider / cardSection — 可点击分区 (IMG_4951)

每个分区：**粗标题 + 灰描述**，右侧 chevron（>），分区之间 hairline 分隔线。

| 元素 | 量出真值 | 当前 BlockView | 建议改成 |
|---|---|---|---|
| 分区标题 "Early Exploration" | **≈22pt semibold/bold**，纯黑(→白) | — (无 cardSection 类型) | 22pt semibold `Theme.text` |
| 分区描述 | 17pt regular，**中灰 ~0.60**(→0.60) | — | 17pt opacity 0.60 |
| chevron ">" | ≈14pt，灰 ~0.35，竖直居中右对齐，外圈无可见圆框（细灰圆 ~0.06 底） | — | SF Symbol `chevron.right` 13pt opacity 0.30 |
| 标题↔描述间距 | ≈3–4pt | — | spacing 3 |
| 分区间 hairline | 0.5pt，灰 ~0.12，**横跨整宽** | `Divider().overlay(hairline)` ✓ | 保持 hairline 0.12 |
| 分区垂直 padding | 每区上下 ≈14pt | — | `.vertical 14` |

> 当前只有裸 `.divider`（一条线）。真版的 **cardSection（标题+描述+chevron 行）是缺失的块类型**，建议新增。
> 引导段 "Here's a few…" = 17pt regular 黑(→白)，标准正文。

置信度：标题字号 ±2pt；chevron 灰度推测。

---

## 5. Table (IMG_4952 Nutrition / IMG_4954 2-col)

斑马纹表。表头大写灰小字，单位 `(kcal)` 更浅。

| 元素 | 量出真值 | 当前 BlockView | 建议改成 |
|---|---|---|---|
| 表上方标题 "Nutrition Estimate" | **≈24pt bold**，黑(→白) | (走 heading) | 24pt bold（H2/标题级）|
| 副标题 "Burrito Bowl" | **≈20pt regular/medium**，**中灰 ~0.45** | — | 20pt opacity 0.45 |
| 表头 "PROTEINS / CALORIES" | **≈11–12pt bold，全大写**，**中灰 ~0.50**，tracking **+0.5** | header 11pt bold tracking 0.5 `.text2`(0.62) ✓ | 11pt bold uppercase tracking 0.5, opacity **0.50** |
| 表头单位 "(kcal)/(g)" | 同 11pt，但**更浅 ~0.35**，**非大写、regular** | (统一大写处理) | 单位用 opacity 0.35 regular，**不大写** |
| 表格正文单元 | **≈16pt regular**，黑(→白) | body 16pt regular ✓ | 保持 16pt regular |
| 首列 "Chicken/Beef" | 同 16pt regular（**不加粗**，与其他列同） | ✓ | 保持 |
| **斑马纹** | **偶数行有底**（行1 Chicken=无底，行2 Beef=灰底，行3 Pork=无…实际：第1/3/5 无底，第2/4 有底）→ 即**索引为奇数(从0)的行染色** | `zebra: idx % 2 == 0`（第0/2/4 染色）| **改为 `idx % 2 == 1`**（看图是 2/4 行有底，不是 1/3/5）|
| 斑马纹底色 | 灰 **~0.045**（极浅），白底上的黑 4–5% | `text.opacity(0.05)` ✓ | 保持 ~0.05 |
| 行高 / 垂直 padding | 正文行上下 ≈11pt | `.vertical 11` ✓ | 保持 |
| 列间距 | ≈12–16pt；列内左对齐 | `HStack spacing 12` ✓ | 保持 12 |
| 圆角 | 整表外圈 **~10pt** 轻圆角（斑马底裁切） | `cornerRadius 10` ✓ | 保持 10 |
| 表头底 padding | ≈8pt | `.vertical 8` ✓ | 保持 |

> **斑马纹相位要核对**：截图 IMG_4952 行序 Chicken/Beef/Pork/Lamb/Tofu，染色的是 **Beef(idx1) 和 Lamb(idx3)**。当前 `idx%2==0` 染 idx0/2/4，相位相反 → **必须翻转为 `idx%2==1`**。

置信度：斑马相位 **直接量到（高）**；表头/正文字号 ±1.5pt；灰阶 ±0.05。

---

## 5b. imageCollection + QUICK OVERVIEW (IMG_4954)

| 元素 | 量出真值 | 建议 |
|---|---|---|
| 横向图集卡片 | 图片**圆角 ~12pt**，并排，约 2.x 张可见（横向滚动），卡片宽 ≈ 内容宽的 ~46% | image 卡 cornerRadius 12 |
| 图 caption 主标题 "Warm" | **≈13pt semibold**，黑(→白) | 13pt semibold text |
| 图 caption 副标题 "Interior" | **≈13pt regular**，**中灰 ~0.45** | 13pt opacity 0.45 |
| caption 主↔副间距 | ≈1–2pt（紧贴） | spacing 1 |
| "QUICK OVERVIEW" 小标题 | **≈12pt bold 大写**，**中灰 ~0.50**，tracking +0.6 | = H3 大写标签风 |

---

## 6. List (IMG_4955)  — 序号 + 粗标题 + 灰描述

行内结构："1  **First item** Description of the first block" —— 同一行内：序号(灰) + 标题(粗黑) + 描述(灰)。

| 元素 | 量出真值 | 当前 BlockView | 建议改成 |
|---|---|---|---|
| 序号 "1/2/3" | **≈17pt regular**，**中灰 ~0.45**，**定宽右对齐** | 17pt `.text2`(0.62)，minWidth16 trailing(ordered) ✓ | opacity **0.45**，minWidth 18, 右对齐 ✓ |
| 标题 "First item" | **≈17pt semibold/bold**，纯黑(→白) | 内容统一 17pt regular，**无粗标题区分** | **行内首段加粗**：标题 semibold `.text` |
| 描述 "Description of…" | **≈17pt regular**，**中灰 ~0.60** | 同上 regular `.text`(全白) | 描述 regular opacity **0.60** |
| 标题↔描述 | 同一行内空格分隔（inline run，不换行） | (整体一段) | 用 AttributedString：粗 run + 灰 run 拼接 |
| 序号↔内容间距 | ≈10–12pt | spacing 12 ✓ | 保持 |
| 项间距 | **≈12pt** | spacing 14 | 收到 12 |

> 当前 list 把整条文字按单一 17pt regular 全白渲染，**丢了「粗标题黑 + 描述灰」的分级**。这是 list 块最大的偏差。
> 实现：每个 item 解析 `**bold**` → 标题 run = semibold `.text`，其后 = regular `.text.opacity(0.60)`。

置信度：粗/灰对比 直接确认（高）；字号 ±1.5pt；序号灰 ±0.06。

---

## 7. Math (IMG_4956)  — 衬线斜体公式 + 居中分式

| 元素 | 量出真值 | 当前 BlockView | 建议改成 |
|---|---|---|---|
| 引导句 "The two solutions to … are" | 17pt regular 黑(→白)，**内嵌行内公式 `ax²+bx+c=0` 为 serif 斜体** | (走 text，无公式支持) | 行内公式用 **serif italic** |
| 居中分式 `x = (−b ± √(b²−4ac)) / 2a` | **serif italic**，**居中**，主字号 **≈17–18pt**，分数线居中、分子分母上下排，纯黑(→白) | **无 math 块类型** | 新增 `.math`：serif italic，center，分式用上下两行+hairline 分数线 |
| "where a≠0." | 17pt regular，行内 `a≠0` serif italic | — | serif italic 行内 |
| 公式块上下留白 | ≈10pt | — | `.vertical 10` |

> **serif (New York) + italic + 居中** 三特征确认。当前**完全没有 math 块**——纯缺失，优先级中高。
> 简化实现可用 `Text` + `.font(.system(.body, design: .serif).italic())`，分式用 VStack(分子 / Divider / 分母)。

置信度：serif/italic/center 直接确认（高）；字号 ±2pt。

---

## 8. Code (Screenshot 7.30.53)  — 语言标签 + Copy + 语法高亮

| 元素 | 量出真值 | 当前 BlockView | 建议改成 |
|---|---|---|---|
| 代码块背景 | **极浅灰 ~0.05**（白底上黑 5%）；在黑底 App 应为 **白 opacity 0.06 或 `Color.black.opacity(...)` 提亮** | `Color.black.opacity(0.4)`（黑底上几乎不可见！） | **黑底 App 改 `Theme.text.opacity(0.06)`** 或专用深灰材质 |
| 圆角 | **~12–14pt** | `cornerRadius 16` | 收到 **12** |
| 语言标签 "Swift" | **≈13pt regular**，**中灰 ~0.45**，**左上角**，在 padding 内 | (无标签) | 顶部行左：13pt opacity 0.45 |
| "Copy" + 复制图标 | **≈13pt**，**右上角**，灰 ~0.45（蓝？此图偏灰），图标在文字右 | (无) | 顶部行右：HStack("Copy"+`doc.on.doc`) 13pt 0.45 |
| 代码字号 | **≈13pt monospaced** | 14pt monospaced | 13pt mono |
| 行距 | 紧凑，lineSpacing ≈2 | — | lineSpacing 2 |
| **语法高亮配色**（白底版，黑底需提亮各色明度） | | (全白单色) | 见下表 |
| └ 关键字 `func/return/let` | **紫色** ~#9B2D9B（白底）→ 黑底用 #C586C0 类亮紫 | — | keyword = 亮紫 |
| └ 类型 `Double` | **蓝色** ~#0A66C2 → 黑底亮蓝 #4FC1FF | — | type = 亮蓝 |
| └ 数字 `32 / 5 / 9` | **绿色** ~#2E7D32 → 黑底亮绿 #B5CEA8 | — | number = 亮绿 |
| └ 注释 `// Example…` | **绿色** ~#3C8A3C（偏暗绿）→ 黑底 #6A9955 | — | comment = 暗绿 |
| └ 普通标识符/标点 | 黑(→白) | ✓ | text |
| 顶栏↔代码间距 | ≈8pt | — | spacing 8 |
| 块内 padding | ≈14–16pt | `padding 16` ✓ | 保持 ~14 |

> Code 块两大问题：(1) 背景用 `Color.black.opacity(0.4)` 在**黑底 App 几乎看不见**，必须改成提亮的浅材质；(2) **完全没有语法高亮**，真版有紫/蓝/绿三色 + 语言标签 + Copy 按钮。优先级高。

置信度：配色色相 直接确认（关键字紫、类型蓝、数字/注释绿，高）；具体 hex 推测（黑底映射值需现场调）；字号 ±1pt。

---

## 9. Image / Caption (IMG_4946 license, IMG_4957 kiwano, IMG_4947 rothko)

| 元素 | 量出真值 | 当前 | 建议 |
|---|---|---|---|
| 大图圆角 | **~16–20pt**（IMG_4947 rothko 卡角约 18pt；kiwano ≈16pt） | (无 image 块) | image cornerRadius **18** |
| caption 主标题 "Untitled 1960" / "Cucumis metuliferus" | **≈15pt semibold**，纯黑(→白) | — | 15pt semibold `.text` |
| caption 副标题 "Mark Rothko" / "African horned cucumber" | **≈15pt regular**，**中灰 ~0.42** | — | 15pt opacity 0.42 |
| 主↔副 caption 间距 | ≈2–3pt | — | spacing 2 |
| 图↔caption 间距 | ≈8pt | — | spacing 8 |
| 引导正文（图上方） | 17pt regular 黑(→白) | text ✓ | 保持 |
| "Flavor Profile"(IMG_4957) | ≈22pt bold/semibold = H2 级 | heading ✓ | 22pt semibold |

> caption 结构统一：**主标题黑(→白) semibold + 副标题灰(0.42) regular，同 15pt**。
> IMG_4946 大数值 "D12345678" = **≈40pt regular**，黑(→白)（比 Everest 的 54pt 小，因是字符串非纯数字）。

置信度：圆角 ±3pt；caption 字号 ±1.5pt；灰阶推测。

---

## 10. Combined (IMG_4958)  — 文字 + 大标题 + 多段正文

| 元素 | 量出真值 | 建议 |
|---|---|---|
| 引导正文 | 17pt regular 黑(→白) | text 17 |
| 大标题 "Robert Irwin & Witney Carson" | **≈30pt bold**，黑(→白)，两行，tracking ≈ -0.4 | H1 级 30pt bold |
| 后续正文段 | 17pt regular 黑(→白)，段间距 ≈10pt | text，段间距走 blockGap |
| 段落间距 | **≈10–12pt**（比 blockGap 18 略小） | — |

> 验证 H1 字号：此图大标题 ≈30pt（比 Heading 图 H1 的 28 略大，因换行展示性更强）→ **H1 取 28–30pt bold 合理**。

---

## 全局 token 建议（Theme.swift）

| token | 当前 | 建议 |
|---|---|---|
| `text2` | `white.opacity(0.62)` | **0.60**（描述/正文灰）|
| `text3` | `white.opacity(0.40)` | 保留 0.40 |
| 新增 `textTertiary` | — | `white.opacity(0.45)`（副标题、序号、caption 副）|
| 新增 `labelGray` | — | `white.opacity(0.50)`（大写小标签 H3/表头/QUICK OVERVIEW）|
| `cardRadius` | 28 | callout 提示框 **20**；image **18**；code **12**；table **10**（按块分别用，不要全用 28）|
| `primarySize` | 76 | **54**（真版大数值），weight `.regular` |
| `bodySize` | 21 | 正文实测 **17**；21 偏大。建议 `bodySize=17`，另设 `quoteSize=22` |
| `blockGap` | 18 | 保留 18（块间）；段内段间距另设 10 |
| 新增代码块 token | — | `codeBG = text.opacity(0.06)`、keyword/type/number/comment 四色（黑底亮版）|

---

## 优先级小结（差距最大 → 最该改）

1. **★★★ Code 块** — 背景 `black.opacity(0.4)` 在黑底**几乎不可见**；且零语法高亮、无语言标签/Copy。视觉差距最大，必改。
2. **★★★ List 块** — 丢失「序号灰 / 粗标题黑 / 描述灰」三级结构，全渲染成单色白 17pt。语义层级全平，必改。
3. **★★★ Math 块** — **完全缺失**（无块类型）。serif italic 居中分式是 Siri 标志性排版。
4. **★★☆ cardSection（IMG_4951）** — **缺失**：标题+描述+chevron+hairline 的可点击分区，现仅有裸 divider。
5. **★★☆ Table 斑马纹相位** — `idx%2==0` 相位**反了**，应 `idx%2==1`；表头单位 `(kcal)` 应更浅且不大写。
6. **★★☆ primaryAnswer / Callout** — 大数值 76→54pt、weight 调 regular；且数值块**不该套 cardBG 背景**（真版裸排）。callout 背景仅留给带 icon 的提示框。
7. **★☆☆ Heading 字阶** — H1 27→28、H2 已对；H3–H6 靠灰度递减(0.72/0.45/0.42/0.40) 需细分；**Title/Subtitle 字阶（34/24，副标题同字号变灰）缺失**。
8. **★☆☆ Image caption** — 缺 image 块；主标题 semibold 黑 + 副标题 regular 灰(0.42)，同 15pt。
9. **★☆☆ Quote** — 已基本对（serif/center），仅 21→22、署名 14→15 微调。

> 置信度总览：**字号** 直接量(±1.5–2pt，高)；**字重/serif/居中/斑马相位/高亮色相** 直接确认(高)；**灰阶 opacity** 多为白底→黑底反相推测(±0.05–0.06，中)，落地时应在真机黑底上微调。

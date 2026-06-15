// markdown → blocks 解析器（代理端）。
// Claude 回标准 markdown，这里把它映射成前端那套封闭 blocks 词汇表。
// 与 src/spec/types.ts 的 Block 结构保持一致。
//
// 支持：标题 / 段落（含 **粗体** `code`）/ 列表 / 表格 / 代码块 / 引用 / 分隔线 / callout(> [!info])

// 文件下载基址（App 文件卡/视频卡点击时从这里拉）。配置见 .env
const FILE_BASE = process.env.FILE_BASE || "http://localhost:3000/file";
const FILE_TOKEN = process.env.AUTH_TOKEN || "";
const fsx = require("fs");
const pathx = require("path");
function fileURL(p) {
  return `${FILE_BASE}?path=${encodeURIComponent(p)}&token=${FILE_TOKEN}`;
}
function humanSize(p) {
  try {
    const b = fsx.statSync(p).size;
    if (b < 1024) return b + " B";
    if (b < 1024 * 1024) return (b / 1024).toFixed(0) + " KB";
    return (b / 1024 / 1024).toFixed(1) + " MB";
  } catch { return undefined; }
}

function markdownToBlocks(md) {
  const blocks = [];
  // 先抽出 [send_file:...] / [send_video:...] 标记 → 文件/视频卡，并从正文移除
  const fileBlocks = [];
  md = md.replace(/\[send_video:([^\]]+)\]/g, (_, p) => {
    p = p.trim();
    fileBlocks.push({ type: "video", url: fileURL(p), title: pathx.basename(p) });
    return "";
  });
  md = md.replace(/\[send_file:([^\]]+)\]/g, (_, p) => {
    p = p.trim();
    const ext = pathx.extname(p).replace(".", "").toLowerCase();
    fileBlocks.push({ type: "file", name: pathx.basename(p), ext, size: humanSize(p), url: fileURL(p) });
    return "";
  });
  const lines = md.replace(/\r\n/g, "\n").split("\n");
  let i = 0;

  const flushParagraph = (buf) => {
    const text = buf.join(" ").trim();
    if (text) blocks.push({ type: "text", text });
  };

  let para = [];

  while (i < lines.length) {
    const line = lines[i];
    const trimmed = line.trim();

    // 代码块 ```
    if (trimmed.startsWith("```")) {
      flushParagraph(para); para = [];
      const lang = trimmed.slice(3).trim() || undefined;
      const code = [];
      i++;
      while (i < lines.length && !lines[i].trim().startsWith("```")) { code.push(lines[i]); i++; }
      i++; // 跳过结束 ```
      blocks.push({ type: "code", language: lang, code: code.join("\n") });
      continue;
    }

    // 空行 → 段落分隔
    if (trimmed === "") { flushParagraph(para); para = []; i++; continue; }

    // 扩展标记 ::callout / ::source / ::status（教给 agent 的富卡片语法）
    if (trimmed.startsWith("::")) {
      flushParagraph(para); para = [];
      const ext = parseExtended(trimmed);
      if (ext) { blocks.push(ext); i++; continue; }
      // 已知卡片标签但 JSON 还没收完整（流式中途）→ 吞掉本行别泄漏，
      // 等下一帧 JSON 闭合后再变成卡片（否则会先冒出半行 ::weather {...）。
      // 未知/格式错的 :: 行不吞，掉到下面当文字保底，避免静默丢内容。
      if (/^::(weather|devices|stock|ride|navigation|reminder|train|coffee|coupon|hotel)\b/.test(trimmed)) {
        i++; continue;
      }
    }

    // 图片： ![alt](url) 独占一行 → image 块
    const img = trimmed.match(/^!\[([^\]]*)\]\(([^)]+)\)$/);
    if (img) {
      flushParagraph(para); para = [];
      blocks.push({ type: "image", url: img[2], alt: img[1] || undefined, caption: img[1] || undefined });
      i++; continue;
    }

    // 标题 #
    const h = trimmed.match(/^(#{1,3})\s+(.+)$/);
    if (h) {
      flushParagraph(para); para = [];
      blocks.push({ type: "heading", text: h[2].trim(), level: h[1].length });
      i++; continue;
    }

    // 分隔线
    if (/^(-{3,}|\*{3,}|_{3,})$/.test(trimmed)) {
      flushParagraph(para); para = [];
      blocks.push({ type: "divider" });
      i++; continue;
    }

    // 数学块：独占一行的 $$...$$（块级居中分式）
    const mathBlock = trimmed.match(/^\$\$(.+)\$\$$/);
    if (mathBlock) {
      flushParagraph(para); para = [];
      blocks.push({ type: "math", expr: mathBlock[1].trim(), block: true });
      i++; continue;
    }

    // 可点击分区：::section 标题 | 描述
    const sec = trimmed.match(/^::section\s+(.+)$/);
    if (sec) {
      flushParagraph(para); para = [];
      const parts = sec[1].split("|");
      blocks.push({
        type: "cardSection",
        title: parts[0].trim(),
        description: parts[1] ? parts[1].trim() : undefined,
      });
      i++; continue;
    }

    // callout： > [!info] 标题 \n > 内容    或普通引用 >
    if (trimmed.startsWith(">")) {
      flushParagraph(para); para = [];
      const quoteLines = [];
      while (i < lines.length && lines[i].trim().startsWith(">")) {
        quoteLines.push(lines[i].trim().replace(/^>\s?/, "")); i++;
      }
      const first = quoteLines[0] || "";
      const cm = first.match(/^\[!(info|success|warning|tip|note|warn)\]\s*(.*)$/i);
      if (cm) {
        const toneMap = { tip: "info", note: "info", warn: "warning" };
        const tone = toneMap[cm[1].toLowerCase()] || cm[1].toLowerCase();
        blocks.push({
          type: "callout",
          tone: tone === "success" ? "success" : tone === "warning" ? "warning" : "info",
          title: cm[2] || undefined,
          text: quoteLines.slice(1).join(" ").trim() || cm[2] || "",
        });
      } else {
        blocks.push({ type: "quote", text: quoteLines.join(" ").trim() });
      }
      continue;
    }

    // 表格： | a | b |  \n  | --- | --- |  \n ...
    if (trimmed.startsWith("|") && i + 1 < lines.length && /^\|[\s:|-]+\|?$/.test(lines[i + 1].trim())) {
      flushParagraph(para); para = [];
      const parseRow = (l) => l.trim().replace(/^\||\|$/g, "").split("|").map((c) => c.trim());
      const headers = parseRow(lines[i]);
      i += 2; // 跳过表头 + 分隔行
      const rows = [];
      while (i < lines.length && lines[i].trim().startsWith("|")) { rows.push(parseRow(lines[i])); i++; }
      blocks.push({ type: "table", headers, rows });
      continue;
    }

    // 列表（有序/无序，连续行）
    const li = trimmed.match(/^([-*+]|\d+\.)\s+(.+)$/);
    if (li) {
      flushParagraph(para); para = [];
      const ordered = /^\d+\./.test(li[1]);
      const items = [];
      while (i < lines.length) {
        const m = lines[i].trim().match(/^([-*+]|\d+\.)\s+(.+)$/);
        if (!m) break;
        items.push(m[2].trim()); i++;
      }
      blocks.push({ type: "list", ordered, items });
      continue;
    }

    // 普通段落行（累积）
    para.push(trimmed);
    i++;
  }
  flushParagraph(para);

  // 文件/视频卡追加到末尾
  for (const fb of fileBlocks) blocks.push(fb);
  return blocks.length ? blocks : [{ type: "text", text: md.trim() }];
}

// 解析扩展富卡片标记（给 agent 的 system prompt 里教的语法）
function parseExtended(line) {
  // ::callout[tone]{icon} 标题 | 正文
  let m = line.match(/^::callout(?:\[(\w+)\])?(?:\{([^}]*)\})?\s*(.*)$/);
  if (m) {
    const [title, ...rest] = (m[3] || "").split("|");
    const text = rest.join("|").trim();
    return {
      type: "callout",
      tone: ["info", "success", "warning"].includes(m[1]) ? m[1] : "info",
      icon: m[2] || undefined,
      title: text ? title.trim() : undefined,
      text: text || title.trim(),
    };
  }
  // ::source Name +N
  m = line.match(/^::source\s+(.+?)(?:\s+\+(\d+))?$/);
  if (m) return { type: "source", name: m[1].trim(), extra: m[2] ? Number(m[2]) : undefined };
  // ::status[green] Available
  m = line.match(/^::status(?:\[(\w+)\])?\s+(.+)$/);
  if (m) return { type: "status", text: m[2].trim(), tone: ["green", "red"].includes(m[1]) ? m[1] : "neutral" };

  // 第①层专属卡片：::weather / ::devices / ::stock 后跟一段 JSON
  m = line.match(/^::(weather|devices|stock|ride|navigation|reminder|train|coffee|coupon|hotel)\s+(\{.*\})\s*$/);
  if (m) {
    try { return { type: m[1], ...JSON.parse(m[2]) }; }
    catch { return null; }
  }
  return null;
}
module.exports = { markdownToBlocks };

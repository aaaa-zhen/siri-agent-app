# Siri Agent — a generative-UI personal AI assistant (iOS)

An iOS app that turns your Claude agent into a **generative UI** in the spirit of
iOS 27's new Siri: instead of replying with a wall of text, it assembles the answer
into an interface on the fly — weather cards, stock cards, navigation, train tickets,
coffee orders, hotels, files, video… cards where cards fit, images where images fit.

> ⚠️ **Status: early / experimental.** This was built fast as a proof of concept —
> the goal is to explore *what a Siri-style generative UI on top of a personal agent
> could feel like*, not to ship a polished product. Expect rough edges. Known limitations:
> - **No native OS hooks** — Apple locks EventKit/Contacts/Photos writes; this talks to
>   service APIs instead, so it won't replace system-level Siri integration.
> - **Streaming perf** isn't fully tuned for very long replies.
> - **Error handling is thin** in places (e.g. a failed file download is silent).
> - **WebSocket reconnect** handles the common cases but has edge cases left.
>
> PRs and ideas welcome. Treat it as a starting point, not a finished app.

> The agent **brain** (WeChat entry + Home Assistant + tools) lives in a separate repo:
> **[claude-home-agent](https://github.com/aaaa-zhen/claude-home-agent)**.
> This repo is its **iOS frontend + connection layer**, reusing the same agent.

## What it looks like

- **Streaming character reveal** — per-character spring entrance (offset + blur +
  chromatic aberration + per-line dimming), with cascade staggering between blocks
- **Generative UI cards** — a closed block vocabulary (heading / list / table / code /
  math / callout + a dozen dedicated cards)
- **Multimodal** — send an image, the agent answers about it
- **Files / video** — Excel/Word/PPT/PDF download & preview, inline video playback
- **Graceful fallback** — unrecognized content degrades to text; never errors, never blanks

Typography values are derived in `BLOCK-SPECS.md` (measured from real iOS 27 Siri screenshots).

## Architecture

```
iOS App (SwiftUI)
  └─ WebSocket ──▶ agent-server (Node)
                    └─ ACP ──▶ claude-agent-acp (persistent)
                                └─ claude-home-agent (CLAUDE.md / memory / tools)
```

The model emits markdown + `::cardName {JSON}` markers → the server's `markdownToBlocks`
parses them into a closed block vocabulary → the app's `BlockDecoder` decodes →
`BlockView` dispatches the rendering.

## Quick start

### 1. Backend agent

Deploy your agent first per [claude-home-agent](https://github.com/aaaa-zhen/claude-home-agent),
and install `claude-agent-acp` (`npm i @zed-industries/claude-agent-acp` in the agent dir).

### 2. Connection layer (agent-server)

```bash
cd agent-server
npm install
cp .env.example .env      # fill AUTH_TOKEN / FILE_BASE / AGENT_DIR
node index.js
```

Generate a random `AUTH_TOKEN`:

```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

### 3. iOS app

Open `agent.xcodeproj` in Xcode and edit `agent/Config.swift`:

```swift
static let serverHost = "your-server:3000"
static let authToken  = "same as AUTH_TOKEN in the server .env"
static let useTLS     = false   // false for plain ws (no cert)
```

> To keep secrets out of git, put your config in `agent/Config.local.swift`
> (already in `.gitignore`) and don't commit the real token.

Build to a real device. Requires iOS 26+ (uses Liquid Glass and other new APIs).

## License

MIT

---

<details>
<summary>中文说明</summary>

一个 iOS App，把你的 Claude agent 做成对标 iOS 27 新 Siri 的**生成式 UI**：
不只回你一段文字，而是当场把答案拼成一张界面——天气卡、股票卡、导航卡、
火车票、咖啡、酒店、文件、视频……该上卡片上卡片，该配图配图。

> 后端 agent 大脑（微信入口 + Home Assistant + 各种工具）是另一个项目：
> **[claude-home-agent](https://github.com/aaaa-zhen/claude-home-agent)**。
> 本仓库是它的 **iOS 前端 + 连接层**，复用同一个 agent。

**它长什么样**
- **流式逐字浮现** —— 逐字 spring 入场（位移 + 模糊 + 色差 + 逐行变轻），块间 cascade 错峰
- **生成式 UI 卡片** —— 封闭的块词汇表（标题/列表/表格/代码/数学/Callout + 十几种专属卡）
- **多模态** —— 发图给 agent 看图回答
- **文件 / 视频** —— Excel/Word/PPT/PDF 下载预览、视频内联播放
- **降级安全网** —— 认不出的内容退回文字，从不报错、从不留白

排版数值参考 `BLOCK-SPECS.md`（按 iOS 27 Siri 真实截图量化）。

**架构**：模型吐 markdown + `::卡片名 {JSON}` 标记 → 服务端 `markdownToBlocks`
解析成封闭块词汇表 → App `BlockDecoder` 解码 → `BlockView` 分发渲染。

**快速开始**：先部署 [claude-home-agent](https://github.com/aaaa-zhen/claude-home-agent) 后端；
再 `cd agent-server && npm install && cp .env.example .env`（填 AUTH_TOKEN 等）→ `node index.js`；
最后用 Xcode 改 `agent/Config.swift` 填服务器地址和 token，Build 到真机（需 iOS 26+）。

</details>

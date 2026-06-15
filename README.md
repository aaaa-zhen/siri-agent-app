# Siri Agent — 生成式 UI 的个人 AI 管家（iOS）

一个 iOS App，把你的 Claude agent 做成对标 iOS 27 新 Siri 的**生成式 UI**：
不只回你一段文字，而是当场把答案拼成一张界面——天气卡、股票卡、导航卡、
火车票、咖啡、酒店、文件、视频……该上卡片上卡片，该配图配图。

> 后端 agent 大脑（微信入口 + Home Assistant + 各种工具）是另一个项目：
> **[claude-home-agent](https://github.com/aaaa-zhen/claude-home-agent)**。
> 本仓库是它的 **iOS 前端 + 连接层**，复用同一个 agent。

## 它长什么样

- **流式逐字浮现** —— 逐字 spring 入场（位移 + 模糊 + 色差 + 逐行变轻），块间 cascade 错峰
- **生成式 UI 卡片** —— 封闭的块词汇表（标题/列表/表格/代码/数学/Callout + 十几种专属卡）
- **多模态** —— 发图给 agent 看图回答
- **文件 / 视频** —— Excel/Word/PPT/PDF 下载预览、视频内联播放
- **降级安全网** —— 认不出的内容退回文字，从不报错、从不留白

排版数值参考 `BLOCK-SPECS.md`（按 iOS 27 Siri 真实截图量化）；架构见 `ARCHITECTURE.md`。

## 架构

```
iOS App (SwiftUI)
  └─ WebSocket ──▶ agent-server (Node)
                    └─ ACP ──▶ claude-agent-acp（常驻）
                                └─ claude-home-agent（CLAUDE.md / memory / 工具）
```

模型吐 markdown + `::卡片名 {JSON}` 标记 → 服务端 `markdownToBlocks` 解析成封闭块词汇表
→ App `BlockDecoder` 解码 → `BlockView` 分发渲染。

## 快速开始

### 1. 后端 agent

先按 [claude-home-agent](https://github.com/aaaa-zhen/claude-home-agent) 部署好你的 agent，
并安装 `claude-agent-acp`（在 agent 目录里 `npm i @zed-industries/claude-agent-acp`）。

### 2. 连接层 agent-server

```bash
cd agent-server
npm install
cp .env.example .env      # 填 AUTH_TOKEN / FILE_BASE / AGENT_DIR
node index.js
```

`AUTH_TOKEN` 自己生成一个随机串：
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

### 3. iOS App

用 Xcode 打开 `agent.xcodeproj`，编辑 `agent/Config.swift`：

```swift
static let serverHost = "你的服务器:3000"
static let authToken  = "和服务端 .env 里 AUTH_TOKEN 相同"
static let useTLS     = false   // 自建未配证书用 false
```

> 想保密就把配置放进 `agent/Config.local.swift`（已在 .gitignore），别提交真实 token。

Build 到真机即可。需要 iOS 26+（用了 Liquid Glass 等 API）。

## License

MIT

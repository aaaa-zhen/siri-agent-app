import Foundation
import Combine

// 连 VPS 的 WebSocket 客户端（地址/token 在 Config.swift 配置）。
// 协议：发 {method:"ask",params:{prompt,id}}；收 turn.start/turn.block/turn.done/turn.error。
//
// 连接健壮性：
//   - 自动重连（指数退避，封顶 8s），断线后下次发送/心跳会拉起新连接。
//   - 心跳 ping（20s）保活，避免 NAT/中间设备空闲掐断后「假在线」。
//   - 发送前先确保 socket 真的活着（不再用 guard task==nil 复用死 socket）；
//     发送失败 → 重连后自动重发一次，避免「Socket is not connected」直接报错给用户。

@MainActor
final class AgentClient: ObservableObject {
    // 一条对话回合
    struct Turn: Identifiable {
        let id = UUID()
        let prompt: String
        var blocks: [Block] = []
        var done = false
        var error: String?

        // 这条回复里有没有专属卡片 → 有则整条走 standard（文字也直接出）
        var hasCard: Bool { blocks.contains { $0.isCard } }
    }

    @Published var turns: [Turn] = []
    @Published var connected = false
    @Published var busy = false
    @Published var streamTick = 0   // 仅用于触发滚动，避免在每次 token 上跑滚动动画

    private var task: URLSessionWebSocketTask?
    private let session = URLSession(configuration: .default)
    private let url = Config.websocketURL
    private var currentReqID: String?

    // 重连 / 心跳状态
    private var reconnectAttempts = 0
    private var reconnecting = false
    private var heartbeatTask: Task<Void, Never>?
    // 发送失败时暂存，重连后重发（仅最近一条）
    private var pendingSend: (prompt: String, image: String?, mime: String)?

    func connect() {
        guard task == nil else { return }
        openSocket()
    }

    private func openSocket() {
        let t = session.webSocketTask(with: url)
        task = t
        t.resume()
        connected = true
        reconnecting = false
        listen()
        startHeartbeat()

        // 重连成功后，如果有等待重发的 prompt，补发出去
        if let p = pendingSend {
            pendingSend = nil
            sendAsk(p.prompt, imageB64: p.image, imageMime: p.mime)
        }
    }

    // 带图发送：image 为 JPEG base64（可选）
    func ask(_ prompt: String, imageB64: String? = nil, imageMime: String = "image/jpeg") {
        busy = true
        turns.append(Turn(prompt: prompt.isEmpty && imageB64 != nil ? "🖼️ 图片" : prompt))
        sendAsk(prompt, imageB64: imageB64, imageMime: imageMime)
    }

    // 停止当前回合：解除 busy、把最后一条标记完成（UI 立刻可再输入）。
    // 注：服务端 claude 进程仍会跑完，但前端不再等待/显示后续 token。
    func cancel() {
        guard busy else { return }
        busy = false
        currentReqID = nil   // 作废当前回合 id → 之后到达的旧 frame 全被 handle 丢弃
        if !turns.isEmpty { turns[turns.count - 1].done = true }
    }

    // 实际发送。socket 不可用时拉起重连并把 prompt 暂存，连上后自动重发，
    // 不再直接给用户报「Socket is not connected」。
    private func sendAsk(_ prompt: String, imageB64: String? = nil, imageMime: String = "image/jpeg") {
        guard let t = task, connected else {
            pendingSend = (prompt, imageB64, imageMime)
            scheduleReconnect()
            return
        }

        let id = UUID().uuidString
        currentReqID = id
        var params: [String: Any] = ["prompt": prompt, "id": id]
        if let imageB64 { params["image"] = imageB64; params["imageMime"] = imageMime }
        let payload: [String: Any] = ["method": "ask", "params": params]
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let str = String(data: data, encoding: .utf8) else { return }

        t.send(.string(str)) { [weak self] err in
            guard err != nil else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                // 发送失败 → 当成断线，暂存并重连重发（一次）
                self.pendingSend = (prompt, imageB64, imageMime)
                self.dropSocket()
                self.scheduleReconnect()
            }
        }
    }

    private func listen() {
        task?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let msg):
                if case .string(let s) = msg { Task { @MainActor in self.handle(s) } }
                Task { @MainActor in self.listen() }
            case .failure:
                Task { @MainActor in
                    self.dropSocket()
                    self.scheduleReconnect()
                }
            }
        }
    }

    // 关掉当前 socket，标记离线（不报错给 UI，交给重连处理）
    private func dropSocket() {
        connected = false
        heartbeatTask?.cancel()
        heartbeatTask = nil
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
    }

    // 指数退避重连：0.5s → 1s → 2s … 封顶 8s
    private func scheduleReconnect() {
        guard !reconnecting else { return }
        reconnecting = true
        reconnectAttempts += 1
        let delay = min(0.5 * pow(2, Double(reconnectAttempts - 1)), 8.0)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard self.task == nil else { self.reconnecting = false; return }
            self.openSocket()
        }
    }

    // 心跳保活：每 20s 发一个 ping，失败即触发重连
    private func startHeartbeat() {
        reconnectAttempts = 0   // 连上即重置退避
        heartbeatTask?.cancel()
        heartbeatTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 20_000_000_000)
                guard let self, let t = self.task else { return }
                t.sendPing { [weak self] err in
                    guard err != nil else { return }
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        self.dropSocket()
                        self.scheduleReconnect()
                    }
                }
            }
        }
    }

    private func handle(_ raw: String) {
        guard let data = raw.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let method = obj["method"] as? String else { return }
        let params = obj["params"] as? [String: Any] ?? [:]

        // 只认当前回合的 frame：cancel 旧回合后再提问，旧回合延迟到达的
        // block/done 会带旧 id，这里直接丢弃，避免串台到新回合。
        // （turn.start 等无 id 的不拦；只拦带 id 且不匹配的。）
        if let fid = obj["id"] as? String, let cur = currentReqID, fid != cur { return }

        guard !turns.isEmpty else { return }
        var turn = turns[turns.count - 1]

        switch method {
        case "turn.block":
            if let idx = params["index"] as? Int,
               let blockObj = params["block"] as? [String: Any],
               let block = BlockDecoder.decode(blockObj) {
                if idx < turn.blocks.count { turn.blocks[idx] = block }
                else { turn.blocks.append(block) }
            }
        case "turn.done":
            turn.done = true; busy = false
        case "turn.error":
            turn.error = params["message"] as? String ?? "出错了"; turn.done = true; busy = false
        default:
            break
        }
        turns[turns.count - 1] = turn
        streamTick &+= 1
    }
}

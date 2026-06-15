import Foundation

// ── 连接配置 ──
// 填入你自己的 agent-server 地址和鉴权 token。
// token 必须和 agent-server 的 .env 里的 AUTH_TOKEN 一致。
//
// 本地调试可以直接改这里；要保密就把它放进一个不提交的文件
// （比如 Config.local.swift，并加进 .gitignore）。
enum Config {
    /// 你的 VPS / 服务器地址（不含协议）。例如 "1.2.3.4:3000" 或 "agent.example.com"
    static let serverHost = "YOUR_SERVER_HOST:3000"

    /// 鉴权 token，需与 agent-server 的 .env AUTH_TOKEN 相同
    static let authToken = "YOUR_AUTH_TOKEN"

    /// 是否走 wss（https）。自建未配证书时用 false（ws）。
    static let useTLS = false

    static var websocketURL: URL {
        let scheme = useTLS ? "wss" : "ws"
        return URL(string: "\(scheme)://\(serverHost)?token=\(authToken)")!
    }
}

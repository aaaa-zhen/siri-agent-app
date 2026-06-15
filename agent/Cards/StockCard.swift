import SwiftUI

// 第①层专属卡：股票行情。A股红涨绿跌。真版风：主数据大、涨跌在右下对角、留白。
struct StockCard: View {
    let s: Block.Stock
    private var up: Bool { s.change >= 0 }

    // 涨跌色按市场惯例：A 股/港股红涨绿跌；美股（字母代码，如 AAPL）绿涨红跌。
    private var usMarket: Bool {
        guard let code = s.code, !code.isEmpty else { return false }
        // 全字母代码 → 美股；纯数字（600519/00700）→ A股/港股
        return code.allSatisfy { $0.isLetter }
    }
    private var tint: Color {
        let upColor = usMarket ? Theme.green : Theme.red
        let downColor = usMarket ? Theme.red : Theme.green
        return up ? upColor : downColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 名称 + 代码
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(s.name).font(.system(size: 18, weight: .semibold)).foregroundStyle(Theme.text)
                if let code = s.code {
                    Text(code).font(.system(size: 14)).foregroundStyle(Theme.text2)
                }
                Spacer()
            }
            .padding(.bottom, 10)

            // 价格（大，左下）  ·····  涨跌（右下对角）
            HStack(alignment: .bottom) {
                Text(String(format: "%.2f", s.price))
                    .font(.system(size: 48, weight: .semibold)).kerning(-0.5)
                    .foregroundStyle(tint)
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(up ? "+" : "")\(String(format: "%.2f", s.changePct))%")
                        .font(.system(size: 19, weight: .semibold))
                    Text("\(up ? "+" : "")\(String(format: "%.2f", s.change))")
                        .font(.system(size: 14, weight: .medium)).opacity(0.85)
                }
                .foregroundStyle(tint)
                .padding(.bottom, 6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20).padding(.vertical, 18)
        .background(Theme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
    }
}

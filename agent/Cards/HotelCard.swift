import SwiftUI

// 第①层专属卡：美团酒店。酒店名 + 评分 + 房型/地段 + 标签 + 起价（右下对角）。
struct HotelCard: View {
    let h: Block.Hotel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 顶部酒店图（满宽 banner，有则显示）
            if let url = h.imageURL.flatMap(URL.init) {
                AsyncImage(url: url) { phase in
                    if let img = phase.image {
                        img.resizable().scaledToFill()
                    } else {
                        Rectangle().fill(Theme.cardBG)
                    }
                }
                .frame(height: 130)
                .frame(maxWidth: .infinity)
                .clipped()
            }

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 名称 + 评分
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(h.name).font(.system(size: 18, weight: .semibold)).foregroundStyle(Theme.text)
                    .lineLimit(1)
                Spacer(minLength: 8)
                if let rating = h.rating {
                    HStack(spacing: 3) {
                        Text("★").font(.system(size: 13)).foregroundStyle(Theme.amber)
                        Text(String(format: "%.1f", rating))
                            .font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.amber)
                    }
                }
            }

            // 房型 / 地段
            if h.roomType != nil || h.area != nil {
                Text([h.roomType, h.area].compactMap { $0 }.joined(separator: " · "))
                    .font(.system(size: 15)).foregroundStyle(Theme.text2)
                    .padding(.top, 4)
            }

            // 标签
            if !h.tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(Array(h.tags.prefix(3).enumerated()), id: \.offset) { _, tag in
                        Text(tag).font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.green)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Theme.green.opacity(0.16)).clipShape(Capsule())
                    }
                }
                .padding(.top, 10)
            }

            // 距离（左） ····· 起价（右下对角）
            HStack(alignment: .bottom) {
                if let dist = h.distance {
                    Text(dist).font(.system(size: 13)).foregroundStyle(Theme.textTertiary)
                }
                Spacer()
                if let price = h.price {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("¥\(trimPrice(price))")
                            .font(.system(size: 24, weight: .semibold)).foregroundStyle(Theme.text)
                        Text("起").font(.system(size: 13)).foregroundStyle(Theme.text2)
                    }
                }
            }
            .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20).padding(.vertical, 18)
    }

    private func trimPrice(_ p: Double) -> String {
        p == p.rounded() ? String(Int(p)) : String(format: "%.1f", p)
    }
}

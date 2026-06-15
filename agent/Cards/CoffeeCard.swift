import SwiftUI

// 第①层专属卡：瑞幸点咖啡。像点餐小票：品名大、规格/门店次级、价格右侧、状态 pill。
struct CoffeeCard: View {
    let c: Block.Coffee

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // 有图用真实咖啡图，无图退回 emoji
                if let url = c.imageURL.flatMap(URL.init) {
                    AsyncImage(url: url) { phase in
                        if let img = phase.image {
                            img.resizable().scaledToFill()
                        } else {
                            Text(c.icon ?? "☕️").font(.system(size: 28))
                        }
                    }
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    Text(c.icon ?? "☕️").font(.system(size: 30))
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(c.name).font(.system(size: 18, weight: .semibold)).foregroundStyle(Theme.text)
                        if let badge = c.badge {
                            Text(badge).font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.coffeeAccent)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Theme.coffeeAccent.opacity(0.16)).clipShape(Capsule())
                        }
                    }
                    if let spec = c.spec {
                        Text(spec).font(.system(size: 15)).foregroundStyle(Theme.text2)
                    }
                }
                Spacer(minLength: 8)
                // 价格：到手价大，原价划线在上
                VStack(alignment: .trailing, spacing: 1) {
                    if let orig = c.originalPrice, orig != c.price {
                        Text("¥\(trimPrice(orig))")
                            .font(.system(size: 13)).foregroundStyle(Theme.textTertiary)
                            .strikethrough()
                    }
                    if let price = c.price {
                        Text("¥\(trimPrice(price))")
                            .font(.system(size: 24, weight: .semibold)).foregroundStyle(Theme.text)
                    }
                }
            }

            if c.store != nil || c.pickup != nil {
                Divider().overlay(Theme.hairline).padding(.vertical, 12)
                VStack(alignment: .leading, spacing: 6) {
                    if let store = c.store { metaRow("📍", store) }
                    if let pickup = c.pickup { metaRow("⏱", pickup) }
                }
            }

            if let status = c.status {
                HStack {
                    Spacer()
                    Text(status)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.blue)
                        .padding(.horizontal, 11).padding(.vertical, 5)
                        .background(Theme.blue.opacity(0.16)).clipShape(Capsule())
                }
                .padding(.top, 12)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20).padding(.vertical, 18)
        .background(Theme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
    }

    @ViewBuilder private func metaRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 8) {
            Text(icon).font(.system(size: 13))
            Text(text).font(.system(size: 15)).foregroundStyle(Theme.text2)
            Spacer(minLength: 0)
        }
    }

    private func trimPrice(_ p: Double) -> String {
        p == p.rounded() ? String(Int(p)) : String(format: "%.1f", p)
    }
}

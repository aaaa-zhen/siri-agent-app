import SwiftUI

// 第①层专属卡：美团优惠券。左侧大面额 + 虚线票根 + 右侧券名/门槛/有效期。
struct CouponCard: View {
    let c: Block.Coupon

    var body: some View {
        HStack(spacing: 0) {
            // 左：面额（票根色块）
            VStack(spacing: 2) {
                Text(c.amount ?? "券")
                    .font(.system(size: 28, weight: .bold)).foregroundStyle(.white)
                    .minimumScaleFactor(0.6).lineLimit(1)
                if let th = c.threshold {
                    Text(th).font(.system(size: 11)).foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1).minimumScaleFactor(0.7)
                }
            }
            .frame(width: 96)
            .padding(.vertical, 18)
            .background(
                LinearGradient(colors: [Theme.couponA, Theme.couponB],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )

            // 右：券名 + 范围 + 有效期
            VStack(alignment: .leading, spacing: 4) {
                Text(c.title).font(.system(size: 16, weight: .semibold)).foregroundStyle(Theme.text)
                    .lineLimit(2)
                if let scope = c.scope {
                    Text(scope).font(.system(size: 15)).foregroundStyle(Theme.text2)
                }
                if let brand = c.brand {
                    Text(brand).font(.system(size: 15)).foregroundStyle(Theme.text2)
                }
                if let valid = c.validUntil {
                    Text(valid).font(.system(size: 13)).foregroundStyle(Theme.textTertiary)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

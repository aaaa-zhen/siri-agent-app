import SwiftUI

// 第①层专属卡：打车（行程进度卡，对标 Uber Live Activity）。
// 黑底卡 · 品牌行 · 大标题(ETA/状态) · 副标题(前往目的地) · 带小车的进度轨道。
struct RideCard: View {
    let r: Block.Ride

    private var headline: String {
        r.eta ?? r.status ?? "行程中"
    }
    private var subtitle: String? {
        if let dest = r.dest { return "前往 \(dest)" }
        return r.status
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 品牌/平台
            Text(r.carType)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
                .padding(.bottom, 10)

            // 大标题：到达时间 / 状态
            Text(headline)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)

            // 副标题：前往目的地
            if let sub = subtitle {
                Text(sub)
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.top, 1)
            }

            // 进度轨道（有 progress 才画）
            if let p = r.progress {
                ProgressTrack(progress: max(0, min(1, p)))
                    .frame(height: 28)
                    .padding(.top, 18)
            }

            // 司机/车牌/价格（有则补一行细信息）
            if r.plate != nil || r.driver != nil || r.price != nil {
                HStack(spacing: 8) {
                    if let plate = r.plate {
                        Text(plate).font(.system(size: 14, weight: .medium)).foregroundStyle(.white)
                    }
                    if let driver = r.driver {
                        Text(driver).font(.system(size: 14)).foregroundStyle(.white.opacity(0.55))
                    }
                    Spacer(minLength: 0)
                    if let price = r.price {
                        Text("¥\(Int(price))").font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.top, 16)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 0.5)
        )
    }
}

// 进度轨道：已走白线 + 小车 + 未走深灰线 + 终点方块。车随 progress 滑入。
private struct ProgressTrack: View {
    let progress: Double
    @State private var animated: Double = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let carSize: CGFloat = 26
            let usable = w - carSize
            let x = usable * animated

            ZStack(alignment: .leading) {
                // 未走（深灰底线）
                Capsule().fill(.white.opacity(0.22))
                    .frame(height: 3)
                // 已走（白线，到车头）
                Capsule().fill(.white)
                    .frame(width: max(0, x + carSize / 2), height: 3)
                // 终点方块
                RoundedRectangle(cornerRadius: 2)
                    .fill(.white.opacity(0.5))
                    .frame(width: 10, height: 10)
                    .position(x: w - 5, y: geo.size.height / 2)
                // 小车
                Image(systemName: "car.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .frame(width: carSize, height: carSize)
                    .background(Color.black, in: Circle())
                    .offset(x: x)
            }
            .frame(height: geo.size.height, alignment: .center)
            .onAppear {
                withAnimation(.spring(response: 0.9, dampingFraction: 0.85)) {
                    animated = progress
                }
            }
        }
    }
}

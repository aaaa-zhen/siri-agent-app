import SwiftUI

// 第①层专属卡：天气（像素级对标真版 San Francisco 63°）。
// 真版要点：城市名+定位箭头、温度在左下、天气状况在右下（对角布局）、无 hint（建议放在上方文字）。
struct WeatherCard: View {
    let w: Block.Weather

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 顶部：城市名 + 定位箭头  ·····  天气图标
            HStack(alignment: .top) {
                HStack(spacing: 6) {
                    Text(w.city).font(.system(size: 20, weight: .semibold))
                    Image(systemName: "location.fill").font(.system(size: 13, weight: .semibold))
                }
                Spacer()
                Text(w.icon ?? "☀️").font(.system(size: 30))
            }
            .padding(.bottom, 6)

            // 底部：温度（左下，大）  ·····  状况 + 高低温（右下）
            HStack(alignment: .bottom) {
                Text("\(w.temp)°")
                    .font(.system(size: 64, weight: .regular))
                    .kerning(-1)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(w.condition).font(.system(size: 18, weight: .semibold))
                    if w.high != nil || w.low != nil {
                        Text("H:\(w.high.map(String.init) ?? "–")°  L:\(w.low.map(String.init) ?? "–")°")
                            .font(.system(size: 15, weight: .medium)).opacity(0.95)
                    }
                }
                .padding(.bottom, 6)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 22).padding(.vertical, 18)
        .background(
            LinearGradient(colors: skyColors, startPoint: .top, endPoint: .bottom)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
    }

    // 背景渐变随天气状况变（中英文都认）：晴=蓝、雨=灰蓝、雪=浅灰、阴=暗灰、夜=深蓝紫。
    private var skyColors: [Color] {
        let c = w.condition.lowercased()
        func has(_ kws: String...) -> Bool { kws.contains { c.contains($0) } }

        if has("雪", "snow", "sleet") {
            return [Color(red: 0.62, green: 0.70, blue: 0.80), Color(red: 0.78, green: 0.84, blue: 0.90)]
        }
        if has("雷", "暴", "storm", "thunder") {
            return [Color(red: 0.25, green: 0.28, blue: 0.36), Color(red: 0.38, green: 0.42, blue: 0.52)]
        }
        if has("雨", "rain", "drizzle", "shower") {
            return [Color(red: 0.34, green: 0.42, blue: 0.52), Color(red: 0.50, green: 0.58, blue: 0.66)]
        }
        if has("阴", "雾", "霾", "overcast", "cloud", "fog", "haze", "mist") {
            return [Color(red: 0.44, green: 0.48, blue: 0.54), Color(red: 0.58, green: 0.62, blue: 0.68)]
        }
        if has("夜", "night", "clear night") {
            return [Color(red: 0.16, green: 0.20, blue: 0.36), Color(red: 0.28, green: 0.32, blue: 0.50)]
        }
        // 默认晴天蓝
        return [Color(red: 0.27, green: 0.56, blue: 0.93), Color(red: 0.40, green: 0.72, blue: 0.98)]
    }
}

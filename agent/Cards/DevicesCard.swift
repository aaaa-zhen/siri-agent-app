import SwiftUI

// 第①层专属卡：智能家居设备。苹果风：SF Symbol、克制单色、靠开关状态本身体现，不堆发光/彩色圆。
struct DevicesCard: View {
    let items: [Block.Device]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { idx, d in
                if idx > 0 {
                    Divider().overlay(Theme.hairline).padding(.leading, 56)
                }
                HStack(spacing: 14) {
                    Image(systemName: symbol(d))
                        .font(.system(size: 19))
                        .foregroundStyle(d.on ? Theme.text : Theme.text3)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(d.name).font(.system(size: 16)).foregroundStyle(Theme.text)
                        if d.on, let detail = d.detail {
                            Text(detail).font(.system(size: 13)).foregroundStyle(Theme.text2)
                        }
                    }
                    Spacer()
                    Toggle("", isOn: .constant(d.on))
                        .labelsHidden().tint(Theme.green).allowsHitTesting(false)
                }
                .padding(.horizontal, 18).padding(.vertical, 14)
            }
        }
        .padding(.vertical, 2)
        .background(Theme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
    }

    // SF Symbol：按设备名（中英文都认）选图标，开/关用 fill/非 fill 区分。
    private func symbol(_ d: Block.Device) -> String {
        let n = d.name.lowercased()
        func has(_ kws: String...) -> Bool { kws.contains { n.contains($0) } }

        // 空调 / 风扇 —— AC 要在 light 之前判，避免 "AC" 落到默认
        if has("空调", "制冷", "冷气", "ac", "air condition", "aircon", "fan", "风扇") {
            return d.on ? "fan.fill" : "fan"
        }
        if has("灯", "light", "lamp", "bulb") { return d.on ? "lightbulb.fill" : "lightbulb" }
        if has("门", "door", "lock", "锁") { return "door.left.hand.closed" }
        if has("窗", "帘", "window", "curtain", "blind") { return "window.vertical.closed" }
        if has("电视", "tv", "television") { return "tv" }
        if has("音", "speaker", "audio", "music") { return d.on ? "hifispeaker.fill" : "hifispeaker" }
        if has("插", "plug", "outlet", "socket") { return "powerplug.fill" }
        return d.on ? "poweroutlet.type.f.fill" : "poweroutlet.type.f"
    }
}

import SwiftUI

// Canvas Settings 面板（对应网页右侧抽屉）。
struct SettingsSheet: View {
    @ObservedObject var settings: CanvasSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Canvas Settings")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.text2)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.text2)
                        .frame(width: 30, height: 30)
                        .background(Theme.cardBG).clipShape(Circle())
                }
            }
            .padding(.bottom, 20)

            row("流式文字特效") {
                Picker("", selection: Binding(
                    get: { settings.textEffect },
                    set: { settings.textEffect = $0 })) {
                    ForEach(CanvasSettings.TextEffect.allCases) { e in
                        Text(e.label).tag(e)
                    }
                }
                .tint(Theme.text)
            }

            row("卡片弹簧进场") {
                Toggle("", isOn: $settings.springEnter).labelsHidden().tint(Theme.blue)
            }
            row("块间弹性联动") {
                Toggle("", isOn: $settings.elasticReflow).labelsHidden().tint(Theme.blue)
            }

            Text("对应 Apple 的 CanvasSettings。")
                .font(.system(size: 12)).foregroundStyle(Theme.text3)
                .padding(.top, 16)

            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.black)
        .presentationDetents([.height(320)])
        .presentationBackground(Color.black)
        .preferredColorScheme(.dark)
    }

    @ViewBuilder private func row<Content: View>(_ title: String, @ViewBuilder _ control: () -> Content) -> some View {
        HStack {
            Text(title).font(.system(size: 16)).foregroundStyle(Theme.text)
            Spacer()
            control()
        }
        .padding(.vertical, 13)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.hairline).frame(height: 0.5)
        }
    }
}

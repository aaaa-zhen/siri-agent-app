import SwiftUI
import UIKit

// 文字显现效果（对标苹果 AgentCanvasUICore 的 StreamingTextEffectStyle）。
//   standard     — 整段直接显示/淡入（卡片、正文默认用这个）
//   spectral     — 逐"字符" spring 浮现（位移+模糊→清晰+色差折射+逐行变轻）
//   spectralWord — 逐"词" spring 浮现（长文本更快，不那么碎）
//
// spectral/spectralWord 用每个 token 一个独立子视图（RevealUnit），各自带 spring，
// 已浮现的不重播 → 流式重渲不卡。错峰：按 token 序 + 行号延迟触发（cascade 感）。
struct StreamingText: View {
    let text: String
    let effect: CanvasSettings.TextEffect

    // —— 苹果风真值（BLOCK-SPECS：正文 17pt）——
    private let fontSize: CGFloat = 17
    private static let lineBrightness: [Double] = [1.0, 0.86, 0.72, 0.6, 0.48]  // 逐行变轻
    private let charStagger: Double = 0.018   // 字间隔(s)
    private let wordStagger: Double = 0.05    // 词间隔(s)
    private let lineStagger: Double = 0.045   // 行间隔(s)

    private var clean: String {
        text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }

    var body: some View {
        Group {
            if effect == .standard {
                Text(attributed(clean))
                    .animation(.timingCurve(0.42, 0, 0.58, 1, duration: 0.35), value: clean)
                    .font(.system(size: fontSize))
                    .lineSpacing(6)
            } else {
                spectralView
            }
        }
        .foregroundStyle(Theme.text)
        .tint(Theme.blue)
    }

    // 逐 token spring 浮现。每个 token 一个 RevealUnit，按出现顺序错峰进场。
    // 用 wrap-around 的 flow 布局让中文/英文自然换行，并按 y 行号给逐行亮度。
    private var spectralView: some View {
        let toks = tokenize(plainText(clean))
        return RevealFlow(
            tokens: toks,
            fontSize: fontSize,
            byWord: effect == .spectralWord,
            charStagger: charStagger,
            wordStagger: wordStagger,
            lineStagger: lineStagger,
            lineBrightness: Self.lineBrightness
        )
        .id(effect)   // 切换 effect → 重建重播，设置实时可预览
    }

    private func plainText(_ s: String) -> String {
        s.replacingOccurrences(of: "**", with: "")
         .replacingOccurrences(of: "`", with: "")
    }

    private func tokenize(_ s: String) -> [String] {
        if effect == .spectralWord {
            var out: [String] = []
            var word = ""
            for ch in s {
                if ch == " " { if !word.isEmpty { out.append(word); word = "" }; out.append(" ") }
                else if ch.isLetter && ch.isASCII { word.append(ch) }
                else { if !word.isEmpty { out.append(word); word = "" }; out.append(String(ch)) }
            }
            if !word.isEmpty { out.append(word) }
            return out
        }
        return s.map(String.init)
    }

    private func attributed(_ s: String) -> AttributedString {
        (try? AttributedString(markdown: s)) ?? AttributedString(s)
    }
}

// MARK: - 流式逐字浮现布局
// 用 WrappingHStack 思路：自己量每个 token 宽度做换行，从而拿到行号 → 逐行亮度 + 行错峰。
private struct RevealFlow: View {
    let tokens: [String]
    let fontSize: CGFloat
    let byWord: Bool
    let charStagger: Double
    let wordStagger: Double
    let lineStagger: Double
    let lineBrightness: [Double]

    @State private var availableWidth: CGFloat = 0

    var body: some View {
        // 先用 GeometryReader 拿可用宽度，再排版
        ZStack(alignment: .topLeading) {
            Color.clear.frame(height: 0)
                .background(GeometryReader { geo in
                    Color.clear.onAppear { availableWidth = geo.size.width }
                        .onChange(of: geo.size.width) { _, w in availableWidth = w }
                })
            if availableWidth > 0 {
                content(width: availableWidth)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func content(width: CGFloat) -> some View {
        let laid = layout(width: width)
        return ZStack(alignment: .topLeading) {
            ForEach(laid) { item in
                RevealUnit(
                    token: item.token,
                    fontSize: fontSize,
                    delay: delay(seq: item.seq, line: item.line),
                    brightness: lineBrightness[min(item.line, lineBrightness.count - 1)]
                )
                .alignmentGuide(.leading) { _ in -item.x }
                .alignmentGuide(.top) { _ in -item.y }
            }
        }
        .frame(width: width, height: laid.last.map { $0.y + $0.lineHeight } ?? 0, alignment: .topLeading)
    }

    private func delay(seq: Int, line: Int) -> Double {
        Double(seq) * (byWord ? wordStagger : charStagger) + Double(line) * lineStagger
    }

    // 简易换行排版：逐 token 量宽，超出宽度就换行。返回每个 token 的 x/y/行号。
    private func layout(width: CGFloat) -> [LaidToken] {
        let font = UIFont.systemFont(ofSize: fontSize)
        let lineHeight = font.lineHeight + 6   // 配合 standard 的 lineSpacing
        var out: [LaidToken] = []
        var x: CGFloat = 0, y: CGFloat = 0, line = 0, seq = 0
        for (i, tok) in tokens.enumerated() {
            let w = widthOf(tok, font: font)
            // 换行：当前行放不下且不是行首
            if x + w > width && x > 0 {
                x = 0; y += lineHeight; line += 1
            }
            out.append(LaidToken(id: i, token: tok, x: x, y: y, line: line, lineHeight: lineHeight, seq: seq))
            x += w
            if !tok.trimmingCharacters(in: .whitespaces).isEmpty { seq += 1 }
        }
        return out
    }

    // token 宽度缓存：流式时同一字符反复测宽（中文/重复字符命中率高）→ O(n²) 降到 O(n)
    private static var widthCache: [String: CGFloat] = [:]
    private func widthOf(_ tok: String, font: UIFont) -> CGFloat {
        let key = "\(Int(fontSize))|\(tok)"
        if let w = Self.widthCache[key] { return w }
        let w = (tok as NSString).size(withAttributes: [.font: font]).width
        Self.widthCache[key] = w
        return w
    }

    // id = token 在序列里的位置（流式只在尾部追加 → 已有 token 的 id 不变 →
    // SwiftUI 复用已浮现的 RevealUnit，不重播动画、不丢 appeared 状态、不闪烁）。
    private struct LaidToken: Identifiable {
        let id: Int
        let token: String
        let x: CGFloat
        let y: CGFloat
        let line: Int
        let lineHeight: CGFloat
        let seq: Int
    }
}

// 单个 token 的浮现单元：位移 + 模糊 + 色差 + 透明度，由 spring 驱动。
private struct RevealUnit: View {
    let token: String
    let fontSize: CGFloat
    let delay: Double
    let brightness: Double

    @State private var appeared = false

    private var yOffset: CGFloat { fontSize * 0.35 }   // 苹果：Y Offset = 字号×0.35

    var body: some View {
        Text(token)
            .font(.system(size: fontSize))
            .foregroundStyle(Theme.text.opacity(appeared ? brightness : 0))
            .offset(y: appeared ? 0 : yOffset)
            .blur(radius: appeared ? 0 : 4)
            // 色差折射：未到位时红/青双向偏移，spring 收敛到 0
            .background(chromatic)
            .task {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                withAnimation(.spring(response: 0.40, dampingFraction: 0.65)) {
                    appeared = true
                }
            }
    }

    // 色差：用两层半透明红/青副本做折射感（到位后消失）
    @ViewBuilder private var chromatic: some View {
        if !appeared {
            ZStack {
                Text(token).font(.system(size: fontSize))
                    .foregroundStyle(Color(red: 1, green: 0.16, blue: 0.16).opacity(0.7))
                    .offset(x: -2)
                Text(token).font(.system(size: fontSize))
                    .foregroundStyle(Color(red: 0, green: 0.78, blue: 1).opacity(0.7))
                    .offset(x: 2)
            }
            .blur(radius: 3)
        }
    }
}

// 卡片显现修饰符。
//   standard            — 不介入：进场完全交给外层 transition 的 spring 回弹
//   spectral/spectralWord — 整卡光谱淡入：模糊→清晰 + 微缩放
private struct CardReveal: ViewModifier {
    let effect: CanvasSettings.TextEffect
    @State private var shown = false

    private var spectral: Bool { effect != .standard }

    func body(content: Content) -> some View {
        if !spectral {
            content
        } else {
            content
                .opacity(shown ? 1 : 0)
                .blur(radius: shown ? 0 : 8)
                .scaleEffect(shown ? 1 : 0.98, anchor: .leading)
                .onAppear {
                    withAnimation(.timingCurve(0.42, 0, 0.58, 1, duration: 0.55)) {
                        shown = true
                    }
                }
        }
    }
}

extension View {
    func cardReveal(_ effect: CanvasSettings.TextEffect) -> some View {
        modifier(CardReveal(effect: effect))
    }
}

// MARK: - Cascade 进场
// 块之间的错峰：每个块按它在本轮的次序延迟进场，形成「一个推一个往下码」的节奏
// （对标苹果 RichTextStreamAnimationCoordinator 的 cascadeThreshold —— 上一块进到
// 阈值下一块才开始）。这里用「次序×间隔」近似那条进度曲线。
// 进场只有位移 + 淡入：卡片不加模糊/色差（数字糊成一团会很廉价）；文字块的逐字浮现
// 在本块「出现」后由 StreamingText 自己继续。
struct CascadeReveal: ViewModifier {
    let order: Int              // 该块在本轮里的次序（0,1,2…）
    let enabled: Bool
    var stagger: Double = 0.12  // 块间隔（s）—— 约等于上块进到阈值的时间

    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared || !enabled ? 1 : 0)
            .offset(y: appeared || !enabled ? 0 : 16)
            .task(id: order) {
                guard enabled, !appeared else { return }
                try? await Task.sleep(nanoseconds: UInt64(Double(order) * stagger * 1_000_000_000))
                withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
                    appeared = true
                }
            }
    }
}

extension View {
    func cascadeReveal(order: Int, enabled: Bool) -> some View {
        modifier(CascadeReveal(order: order, enabled: enabled))
    }
}

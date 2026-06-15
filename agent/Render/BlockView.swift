import SwiftUI
import UIKit

// 渲染器：按 block 类型分发到对应视图（等价于 web 的 renderBlock switch）。
// 基础版先覆盖常见块；专属卡片（weather/devices/stock）后续接入。
struct BlockView: View {
    let block: Block
    var effect: CanvasSettings.TextEffect = .standard

    var body: some View {
        switch block {
        case .text(let t):
            StreamingText(text: t, effect: effect)
                .frame(maxWidth: .infinity, alignment: .leading)

        case .heading(let t, let level):
            // 苹果字阶（BLOCK-SPECS §3）：
            //   H1 28 bold / H2 22 semibold（真字号递减）
            //   H3-H6 全 13pt 大写小标签，靠字重+灰度递减（bold/0.72 → semibold/0.45 → 0.42 → 0.40）
            Group {
                switch level {
                case 1:
                    Text(t).font(.system(size: 28, weight: .bold)).tracking(-0.4)
                        .foregroundStyle(Theme.text)
                case 2:
                    Text(t).font(.system(size: 22, weight: .semibold)).tracking(-0.2)
                        .foregroundStyle(Theme.text)
                default:
                    Text(t.uppercased())
                        .font(.system(size: 13, weight: level == 3 ? .bold : .semibold))
                        .tracking(0.6)
                        .foregroundStyle(Color.white.opacity(level == 3 ? 0.72 : level == 4 ? 0.45 : level == 5 ? 0.42 : 0.40))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        case .primaryAnswer(let t, let unit):
            // 大数值：54pt regular 裸排（不套卡片背景），单位 26pt 中灰、baseline 对齐
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(t).font(.system(size: Theme.primarySize, weight: .regular)).foregroundStyle(Theme.text)
                if let u = unit {
                    Text(u).font(.system(size: 26)).foregroundStyle(Color.white.opacity(0.55))
                }
            }.frame(maxWidth: .infinity, alignment: .leading)

        case .callout(let icon, let title, let text, _):
            HStack(alignment: .top, spacing: 12) {
                Text(icon ?? "💡").font(.system(size: 22))
                VStack(alignment: .leading, spacing: 4) {
                    if let title { Text(title).font(.system(size: 16, weight: .semibold)) }
                    Text(inline(text)).font(.system(size: 17)).foregroundStyle(Theme.text2)
                }
                Spacer(minLength: 0)
            }
            .padding(16).background(Theme.cardBG)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))

        case .quote(let text, let author):
            // 苹果 pullQuote：衬线(New York)、居中、克制字重
            VStack(spacing: 8) {
                Text(text)
                    .font(.system(size: Theme.quoteSize, weight: .medium, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.text)
                if let a = author {
                    Text("— \(a)").font(.system(size: 15)).foregroundStyle(Theme.text2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)

        case .list(let ordered, let items):
            // 苹果 list（BLOCK-SPECS §6）：序号灰(0.45)定宽右对齐；
            // 行内「**粗标题**（白）+ 描述（灰 0.60）」三级结构；项间距 12
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(items.enumerated()), id: \.offset) { i, it in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(ordered ? "\(i + 1)" : "•")
                            .font(.system(size: 17))
                            .foregroundStyle(Theme.textTertiary)
                            .frame(minWidth: 18, alignment: ordered ? .trailing : .leading)
                        Text(listItem(it))
                            .font(.system(size: 17)).lineSpacing(4)
                            .tint(Theme.blue)
                    }
                }
            }.frame(maxWidth: .infinity, alignment: .leading)

        case .table(let headers, let rows):
            // 苹果 table（BLOCK-SPECS §5）：大写灰表头(11px)，斑马纹染奇数行(idx 1/3…)
            VStack(spacing: 0) {
                tableRow(headers, header: true, zebra: false)
                ForEach(Array(rows.enumerated()), id: \.offset) { idx, r in
                    tableRow(r, header: false, zebra: idx % 2 == 1)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.tableRadius, style: .continuous))

        case .code(let lang, let code):
            CodeBlock(lang: lang, code: code)

        case .math(let expr, let block):
            MathBlock(expr: expr, block: block)

        case .cardSection(let title, let desc):
            // 可点击分区（BLOCK-SPECS §4）：标题 22 semibold + 描述灰 + chevron，下方 hairline
            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title).font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Theme.text)
                        if let desc {
                            Text(inline(desc)).font(.system(size: 17))
                                .foregroundStyle(Theme.text2)
                        }
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.30))
                }
                .padding(.vertical, 14)
                Divider().overlay(Theme.hairline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        case .divider:
            Divider().overlay(Theme.hairline)

        case .source(let name, let extra):
            pill(text: extra != nil ? "\(name) +\(extra!)" : name, tone: .neutral)
                .frame(maxWidth: .infinity, alignment: .leading)

        case .status(let text, let tone):
            pill(text: text, tone: tone).frame(maxWidth: .infinity, alignment: .leading)

        // 第①层专属卡片。对标苹果：卡片走独立的 calloutTextEffect，默认 standard
        // （正文用 textEffect=spectral，卡片用 standard，两者分开 —— 见 ARCHITECTURE.md §4）。
        // 卡片恒 standard：直接淡入，不跟正文的 spectral 走。
        case .weather(let w):    WeatherCard(w: w).cardReveal(.standard)
        case .devices(let items): DevicesCard(items: items).cardReveal(.standard)
        case .stock(let s):      StockCard(s: s).cardReveal(.standard)
        case .ride(let r):       RideCard(r: r).cardReveal(.standard)
        case .navigation(let n): NavigationCard(n: n).cardReveal(.standard)
        case .reminder(let r):   ReminderCard(r: r).cardReveal(.standard)
        case .train(let t):      TrainCard(t: t).cardReveal(.standard)
        case .coffee(let c):     CoffeeCard(c: c).cardReveal(.standard)
        case .coupon(let c):     CouponCard(c: c).cardReveal(.standard)
        case .hotel(let h):      HotelCard(h: h).cardReveal(.standard)
        case .file(let f):       FileCard(f: f).cardReveal(.standard)
        case .video(let v):      VideoCard(v: v).cardReveal(.standard)
        }
    }

    @ViewBuilder private func tableRow(_ cells: [String], header: Bool, zebra: Bool) -> some View {
        HStack(spacing: 12) {
            ForEach(Array(cells.enumerated()), id: \.offset) { _, c in
                Group {
                    if header {
                        Text(c.uppercased())
                            .font(.system(size: 11, weight: .bold)).tracking(0.5)
                            .foregroundStyle(Theme.labelGray)
                    } else {
                        // 单元格内 **粗体** 要解析（修：之前显示成字面星号）
                        Text(inline(c))
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.text)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, header ? 8 : 11)
        .background(zebra ? Theme.text.opacity(0.05) : Color.clear)
    }

    @ViewBuilder private func pill(text: String, tone: Block.PillTone) -> some View {
        let bg: Color = tone == .green ? Theme.green.opacity(0.18)
                      : tone == .red ? Theme.red.opacity(0.18) : Theme.cardBG
        let fg: Color = tone == .green ? Theme.green : tone == .red ? Theme.red : Theme.text2
        Text(text).font(.system(size: 13, weight: .medium)).foregroundStyle(fg)
            .padding(.horizontal, 11).padding(.vertical, 5)
            .background(bg).clipShape(Capsule())
    }

    // 极简 inline markdown：**粗体** + 去掉未知 <tag>（第④层兜底）
    private func inline(_ s: String) -> AttributedString {
        let stripped = s.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        return (try? AttributedString(markdown: stripped)) ?? AttributedString(stripped)
    }

    // list 项：「**粗标题**（白 semibold）+ 描述（灰 0.60 regular）」分级。
    // 只有当项里确实含 **bold** 时才做白/灰分级；否则整条按正常正文白渲染
    // （没有粗标题的普通列表项不该整条变灰）。
    private func listItem(_ s: String) -> AttributedString {
        let stripped = s.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        let hasBold = stripped.contains("**")
        guard let a0 = try? AttributedString(markdown: stripped) else {
            return AttributedString(stripped)   // 整条白（默认 Theme.text）
        }
        guard hasBold else { return a0 }        // 无粗标题 → 整条白
        var a = a0
        for run in a.runs {
            let isBold = run.inlinePresentationIntent?.contains(.stronglyEmphasized) ?? false
            a[run.range].foregroundColor = isBold ? Color.white : Color.white.opacity(0.60)
        }
        return a
    }
}

// MARK: - Code 块（语言标签 + Copy + 语法高亮，BLOCK-SPECS §8）
private struct CodeBlock: View {
    let lang: String?
    let code: String
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 顶栏：语言标签（左）+ Copy（右）
            HStack {
                Text(lang?.capitalized ?? "Code")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textTertiary)
                Spacer()
                Button {
                    UIPasteboard.general.string = code
                    withAnimation { copied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                        withAnimation { copied = false }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Text(copied ? "Copied" : "Copy")
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(copied ? Theme.green : Theme.textTertiary)
                }
            }
            // 代码 + 语法高亮
            Text(SyntaxHighlighter.highlight(code))
                .font(.system(size: 13, design: .monospaced))
                .lineSpacing(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(Theme.codeBG)
        .clipShape(RoundedRectangle(cornerRadius: Theme.codeRadius, style: .continuous))
    }
}

// MARK: - Math 块（serif italic 居中分式，BLOCK-SPECS §7）
private struct MathBlock: View {
    let expr: String
    let block: Bool

    private var serif: Font {
        .system(size: block ? 18 : 17, design: .serif).italic()
    }

    var body: some View {
        if block {
            content
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        } else {
            content
        }
    }

    @ViewBuilder private var content: some View {
        // 形如 "x = (分子) / (分母)" → 渲染竖排分式；否则整条 serif italic
        if let frac = parseFraction(expr) {
            HStack(spacing: 6) {
                if !frac.lead.isEmpty {
                    Text(frac.lead).font(serif).foregroundStyle(Theme.text)
                }
                VStack(spacing: 3) {
                    Text(frac.num).font(serif).foregroundStyle(Theme.text)
                    Rectangle().fill(Theme.text).frame(height: 1)
                    Text(frac.den).font(serif).foregroundStyle(Theme.text)
                }
                .fixedSize()
            }
        } else {
            Text(expr).font(serif).foregroundStyle(Theme.text)
                .multilineTextAlignment(.center)
        }
    }

    // 解析 "lead = (num) / (den)" 或 "lead = num / den"
    private func parseFraction(_ s: String) -> (lead: String, num: String, den: String)? {
        // 先抓 "前缀 = 余下"
        var lead = ""
        var body = s
        if let eq = s.range(of: "=") {
            lead = String(s[..<eq.upperBound]).trimmingCharacters(in: .whitespaces)
            body = String(s[eq.upperBound...]).trimmingCharacters(in: .whitespaces)
        }
        // body 必须含一个顶层 "/"
        guard let slash = topLevelSlash(body) else { return nil }
        let num = stripParens(String(body[..<slash]).trimmingCharacters(in: .whitespaces))
        let den = stripParens(String(body[body.index(after: slash)...]).trimmingCharacters(in: .whitespaces))
        guard !num.isEmpty, !den.isEmpty else { return nil }
        return (lead, num, den)
    }

    // 找括号外的 "/"（避免切到 √(...) 里的）
    private func topLevelSlash(_ s: String) -> String.Index? {
        var depth = 0
        var i = s.startIndex
        while i < s.endIndex {
            let c = s[i]
            if c == "(" { depth += 1 }
            else if c == ")" { depth = max(0, depth - 1) }
            else if c == "/" && depth == 0 { return i }
            i = s.index(after: i)
        }
        return nil
    }

    private func stripParens(_ s: String) -> String {
        var t = s
        if t.hasPrefix("(") && t.hasSuffix(")") {
            t.removeFirst(); t.removeLast()
        }
        return t.trimmingCharacters(in: .whitespaces)
    }
}

// 轻量语法高亮：关键字/类型/数字/注释/字符串。语言无关的通用规则，够用即可。
enum SyntaxHighlighter {
    private static let keywords: Set<String> = [
        "func", "return", "let", "var", "if", "else", "for", "while", "in", "import",
        "struct", "class", "enum", "guard", "switch", "case", "default", "do", "try",
        "catch", "throws", "async", "await", "self", "init", "static", "private", "public",
        "extension", "protocol", "where", "nil", "true", "false", "def", "const", "function",
        "new", "void", "int", "float", "double", "string", "bool", "print"
    ]

    static func highlight(_ code: String) -> AttributedString {
        var out = AttributedString()
        for line in code.split(separator: "\n", omittingEmptySubsequences: false) {
            let s = String(line)
            // 整行注释
            if s.trimmingCharacters(in: .whitespaces).hasPrefix("//") ||
               s.trimmingCharacters(in: .whitespaces).hasPrefix("#") {
                var a = AttributedString(s)
                a.foregroundColor = Theme.codeComment
                out += a
            } else {
                out += highlightLine(s)
            }
            out += AttributedString("\n")
        }
        return out
    }

    private static func highlightLine(_ s: String) -> AttributedString {
        var out = AttributedString()
        // 按 token 边界切（保留分隔符），逐 token 上色
        var token = ""
        func flush() {
            guard !token.isEmpty else { return }
            var a = AttributedString(token)
            if keywords.contains(token) { a.foregroundColor = Theme.codeKeyword }
            else if Double(token) != nil { a.foregroundColor = Theme.codeNumber }
            else if let f = token.first, f.isUppercase { a.foregroundColor = Theme.codeType }  // 类型(大写开头)
            else { a.foregroundColor = Color.white }
            out += a
            token = ""
        }
        for ch in s {
            if ch.isLetter || ch.isNumber || ch == "_" || ch == "." {
                token.append(ch)
            } else {
                flush()
                var a = AttributedString(String(ch))
                a.foregroundColor = Color.white.opacity(0.85)
                out += a
            }
        }
        flush()
        return out
    }
}

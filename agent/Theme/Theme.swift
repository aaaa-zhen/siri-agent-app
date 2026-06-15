import SwiftUI

// 设计 token（对应 web 的 styler.ts / 苹果 ResponseStyler）。
// 数值按 iOS 27 Siri 真版截图校准；动画值来自你的逆向（spring-findings）。

enum Theme {
    // 颜色（灰阶按 BLOCK-SPECS 真值，白底→黑底反相）
    static let text = Color.white
    static let text2 = Color.white.opacity(0.60)          // 描述/正文灰
    static let text3 = Color.white.opacity(0.40)
    static let textTertiary = Color.white.opacity(0.45)   // 副标题、序号、caption 副
    static let labelGray = Color.white.opacity(0.50)      // 大写小标签（H3/表头/QUICK OVERVIEW）
    static let cardBG = Color(.sRGB, white: 0.46, opacity: 0.24)   // 系统材质灰
    static let codeBG = Color.white.opacity(0.06)         // 代码块底（黑底提亮浅材质）
    static let hairline = Color.white.opacity(0.12)

    static let green = Color(red: 0.20, green: 0.78, blue: 0.35)   // #34C759
    static let red   = Color(red: 1.00, green: 0.27, blue: 0.23)   // #FF453A
    static let blue  = Color(red: 0.04, green: 0.52, blue: 1.00)   // #0A84FF
    static let amber = Color(red: 1.00, green: 0.72, blue: 0.20)   // 评分星
    static let coffeeAccent = Color(red: 0.30, green: 0.55, blue: 1.00)  // 瑞幸蓝（角标）
    // 美团优惠券票根渐变（美团黄→橙）
    static let couponA = Color(red: 1.00, green: 0.78, blue: 0.13)
    static let couponB = Color(red: 1.00, green: 0.55, blue: 0.10)

    // 代码语法高亮（黑底亮版）
    static let codeKeyword = Color(red: 0.78, green: 0.52, blue: 0.75)  // 关键字 亮紫
    static let codeType    = Color(red: 0.31, green: 0.76, blue: 1.00)  // 类型 亮蓝
    static let codeNumber  = Color(red: 0.71, green: 0.81, blue: 0.66)  // 数字 亮绿
    static let codeComment = Color(red: 0.42, green: 0.60, blue: 0.33)  // 注释 暗绿

    // 尺寸（各块圆角不同，不再全用 cardRadius）
    static let cardRadius: CGFloat = 20    // callout 提示框
    static let imageRadius: CGFloat = 18
    static let codeRadius: CGFloat = 12
    static let tableRadius: CGFloat = 10
    static let cardPadding: CGFloat = 20
    static let blockGap: CGFloat = 18

    // 字号
    static let bodySize: CGFloat = 17     // 正文（实测，原 21 偏大）
    static let quoteSize: CGFloat = 22
    static let primarySize: CGFloat = 54  // 大数值（原 76 太大）

    // —— 动画（逆向真值）——
    // 卡片进场：欠阻尼弹簧，明显 overshoot。SwiftUI 用 response/dampingFraction，
    // 正是你逆向出的 ω/ζ 参数化（苹果 SwiftUI Spring 同款）。
    static let cardEnter = Animation.spring(response: 0.44, dampingFraction: 0.66)
    // 块间重排：更稳，几乎不过冲
    static let reflow = Animation.spring(response: 0.38, dampingFraction: 0.9)
    // 流式文字显现：苹果 fluidDots 呼吸曲线 = ease-in-out = cubic-bezier(.42,0,.58,1)
    static let revealText = Animation.timingCurve(0.42, 0, 0.58, 1, duration: 0.42)
}

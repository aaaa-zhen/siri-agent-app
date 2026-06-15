import SwiftUI

// 带小尾巴的用户气泡（对标真版 Siri：右下角一个尖角）。
struct BubbleShape: Shape {
    var radius: CGFloat = 22
    var tail: CGFloat = 7

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = radius
        let w = rect.width, h = rect.height
        // 主体圆角矩形（右下角留给尾巴，圆角小一点）
        p.move(to: CGPoint(x: r, y: 0))
        p.addLine(to: CGPoint(x: w - r, y: 0))
        p.addArc(center: CGPoint(x: w - r, y: r), radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: w, y: h - tail))
        // 尾巴：右下角小尖
        p.addQuadCurve(to: CGPoint(x: w + tail, y: h),
                       control: CGPoint(x: w, y: h - tail / 2))
        p.addQuadCurve(to: CGPoint(x: w - tail - 2, y: h),
                       control: CGPoint(x: w, y: h))
        p.addLine(to: CGPoint(x: r, y: h))
        p.addArc(center: CGPoint(x: r, y: h - r), radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        p.addLine(to: CGPoint(x: 0, y: r))
        p.addArc(center: CGPoint(x: r, y: r), radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        p.closeSubpath()
        return p
    }
}

import SwiftUI
import QuickLook

// 第①层专属卡：办公文件（xlsx/docx/pptx/pdf）。
// 类型图标 + 文件名 + 大小；点击 → 下载到本地 → QuickLook 预览/分享。
struct FileCard: View {
    let f: Block.FileAttach
    @State private var localURL: URL?
    @State private var loading = false
    @State private var showPreview = false

    // 按扩展名取图标色（对标 iOS 文件类型色）
    private var accent: Color {
        switch f.ext.lowercased() {
        case "xlsx", "xls", "csv", "numbers": return Theme.green       // 表格 绿
        case "docx", "doc", "pages":          return Theme.blue        // 文档 蓝
        case "pptx", "ppt", "key":            return Color.orange      // 演示 橙
        case "pdf":                            return Theme.red         // PDF 红
        default:                               return Theme.text2
        }
    }
    private var symbol: String {
        switch f.ext.lowercased() {
        case "xlsx", "xls", "csv", "numbers": return "tablecells"
        case "docx", "doc", "pages":          return "doc.text"
        case "pptx", "ppt", "key":            return "rectangle.on.rectangle"
        case "pdf":                            return "doc.richtext"
        default:                               return "doc"
        }
    }

    var body: some View {
        Button(action: open) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(accent.opacity(0.18))
                        .frame(width: 44, height: 44)
                    if loading {
                        ProgressView().tint(accent)
                    } else {
                        Image(systemName: symbol).font(.system(size: 20)).foregroundStyle(accent)
                    }
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(f.name).font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Theme.text).lineLimit(1)
                    HStack(spacing: 6) {
                        Text(f.ext.uppercased())
                            .font(.system(size: 11, weight: .bold)).tracking(0.4)
                            .foregroundStyle(accent)
                        if let size = f.size {
                            Text(size).font(.system(size: 13)).foregroundStyle(Theme.textTertiary)
                        }
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 20)).foregroundStyle(Theme.text2)
            }
            .padding(14)
            .background(Theme.cardBG)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .quickLookPreview($localURL)
    }

    private func open() {
        if let localURL { showPreview = true; self.localURL = localURL; return }
        guard let url = URL(string: f.url), !loading else { return }
        loading = true
        URLSession.shared.downloadTask(with: url) { tmp, _, _ in
            DispatchQueue.main.async {
                loading = false
                guard let tmp else { return }
                // 重命名为带正确扩展名的文件（QuickLook 靠扩展名识别类型）
                let dest = FileManager.default.temporaryDirectory.appendingPathComponent(f.name)
                try? FileManager.default.removeItem(at: dest)
                try? FileManager.default.moveItem(at: tmp, to: dest)
                localURL = dest
            }
        }.resume()
    }
}

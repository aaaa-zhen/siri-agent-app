import SwiftUI
import Combine

// 对应网页的 CanvasSettings / 苹果 CanvasSettings。控制渲染层的动画行为。
@MainActor
final class CanvasSettings: ObservableObject {
    enum TextEffect: String, CaseIterable, Identifiable {
        case standard, spectral, spectralWord
        var id: String { rawValue }
        var label: String {
            switch self {
            case .standard: return "standard"
            case .spectral: return "spectral · 逐字符"
            case .spectralWord: return "spectralWord · 逐词"
            }
        }
    }

    @Published var textEffect: TextEffect {
        didSet { UserDefaults.standard.set(textEffect.rawValue, forKey: "opt.textEffect") }
    }
    @Published var springEnter: Bool {
        didSet { UserDefaults.standard.set(springEnter, forKey: "opt.springEnter") }
    }
    @Published var elasticReflow: Bool {
        didSet { UserDefaults.standard.set(elasticReflow, forKey: "opt.elasticReflow") }
    }

    init() {
        let d = UserDefaults.standard
        textEffect = TextEffect(rawValue: d.string(forKey: "opt.textEffect") ?? "") ?? .spectral
        springEnter = d.object(forKey: "opt.springEnter") as? Bool ?? true
        elasticReflow = d.object(forKey: "opt.elasticReflow") as? Bool ?? true
    }
}

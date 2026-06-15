import Foundation
import EventKit

// 把 reminder 卡片写进系统「提醒事项」App（EventKit / EKReminder）。
// time 是模型给的自由文本（"今天 18:00"），用 NSDataDetector 尽力解析成到期日；
// 解析不出就存一个无到期日的纯提醒（仍然能加进去）。
@MainActor
final class RemindersService {
    static let shared = RemindersService()
    private let store = EKEventStore()

    enum AddError: LocalizedError {
        case denied
        case saveFailed(String)
        var errorDescription: String? {
            switch self {
            case .denied: return "没有「提醒事项」权限，去设置里打开。"
            case .saveFailed(let m): return "保存失败：\(m)"
            }
        }
    }

    // 请求权限（iOS 17+ 全权限 API）。已授权直接返回 true。
    private func ensureAccess() async throws {
        switch EKEventStore.authorizationStatus(for: .reminder) {
        case .fullAccess:
            return
        case .denied, .restricted, .writeOnly:
            // writeOnly 对提醒不适用；当作不可写处理。仍尝试请求一次。
            fallthrough
        case .notDetermined:
            let granted = (try? await store.requestFullAccessToReminders()) ?? false
            if !granted { throw AddError.denied }
        @unknown default:
            let granted = (try? await store.requestFullAccessToReminders()) ?? false
            if !granted { throw AddError.denied }
        }
    }

    // 加入系统提醒。返回解析到的到期日（nil 表示没解析出时间，存的是无到期日提醒）。
    @discardableResult
    func add(_ r: Block.Reminder) async throws -> Date? {
        try await ensureAccess()

        let reminder = EKReminder(eventStore: store)
        reminder.title = r.title.isEmpty ? "提醒" : r.title
        reminder.notes = r.note
        reminder.calendar = store.defaultCalendarForNewReminders()

        // 优先用机器可读的 due（ISO8601），退回 time 的自然语言解析
        let due = r.due.flatMap(Self.parseISO) ?? r.time.flatMap(Self.parseDate)
        if let due {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: due)
            // 加一个绝对时间闹钟，到点提醒
            reminder.addAlarm(EKAlarm(absoluteDate: due))
        }

        do {
            try store.save(reminder, commit: true)
        } catch {
            throw AddError.saveFailed(error.localizedDescription)
        }
        return due
    }

    // 机器可读的本地 ISO8601（"2026-06-13T12:00:00"，无时区 → 按设备当前时区）。
    static func parseISO(_ text: String) -> Date? {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let d = f.date(from: text) { return d }
        // 容错：模型可能少给秒
        f.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return f.date(from: text)
    }

    // 中文/自然语言时间 → Date。NSDataDetector 认得 "今天18点"/"明天下午3点"/"6月14日18:00" 等。
    static func parseDate(_ text: String) -> Date? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        let match = detector.firstMatch(in: text, options: [], range: range)
        return match?.date
    }
}

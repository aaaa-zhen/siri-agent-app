import SwiftUI
import UIKit

// 第①层专属卡：提醒/日程。对标真版日历事件卡：左侧彩色竖条 + 标题 + 时间/地点。
// 「加入提醒事项」→ 写进系统「提醒事项」App（EventKit），成功后整卡原地变「已加入」态：
// 竖条转绿、显示到期时间 + 实时倒计时 + 「在提醒事项中打开」。
struct ReminderCard: View {
    let r: Block.Reminder

    private let accent = Color(red: 1.0, green: 0.42, blue: 0.36)  // 提醒红

    // idle → adding → added(带到期日) / failed
    enum AddState: Equatable {
        case idle, adding
        case added(due: Date?)
        case failed(String)
    }
    @State private var state: AddState

    // 默认 idle；预览可注入 .added 态直接看「已加入 + 倒计时」样子
    init(r: Block.Reminder, previewState: AddState = .idle) {
        self.r = r
        _state = State(initialValue: previewState)
    }

    // 已加入态的强调色变绿
    private var bar: Color {
        if case .added = state { return Theme.green }
        return accent
    }

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3)
                .fill(bar)
                .frame(width: 5)
                .padding(.vertical, 2)

            VStack(alignment: .leading, spacing: 7) {
                Text(r.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.text)

                if let time = r.time {
                    Label {
                        Text(time).font(.system(size: 15))
                    } icon: {
                        Image(systemName: "clock").font(.system(size: 13))
                    }
                    .foregroundStyle(Theme.text2)
                }
                if let note = r.note {
                    Label {
                        Text(note).font(.system(size: 14))
                    } icon: {
                        Image(systemName: "mappin").font(.system(size: 12))
                    }
                    .foregroundStyle(Theme.text3)
                }

                footer.padding(.top, 4)
            }
            .padding(.leading, 14)
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Theme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .animation(.spring(response: 0.38, dampingFraction: 0.8), value: state)
    }

    @ViewBuilder private var footer: some View {
        switch state {
        case .added(let due):
            VStack(alignment: .leading, spacing: 6) {
                Label("已加入系统提醒", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.green)

                // 倒计时：只有解析出未来的到期日才显示
                if let due, due > .now {
                    HStack(spacing: 5) {
                        Image(systemName: "timer").font(.system(size: 12))
                        // 系统级倒计时文本，自动每秒刷新、不耗电
                        Text(timerInterval: .now...due, countsDown: true)
                            .monospacedDigit()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.text2)
                }

                Button {
                    if let url = URL(string: "x-apple-reminderkit://") { UIApplication.shared.open(url) }
                } label: {
                    Text("在提醒事项中打开")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.blue)
                }
                .buttonStyle(.plain)
            }

        case .failed(let msg):
            Label(msg, systemImage: "exclamationmark.triangle.fill")
                .font(.system(size: 13))
                .foregroundStyle(Theme.red)
                .lineLimit(2)

        case .idle, .adding:
            Button(action: add) {
                HStack(spacing: 6) {
                    if state == .adding {
                        ProgressView().controlSize(.small).tint(accent)
                    } else {
                        Image(systemName: "plus.circle.fill").font(.system(size: 14))
                    }
                    Text("加入提醒事项").font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(accent)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(accent.opacity(0.16))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(state == .adding)
        }
    }

    private func add() {
        state = .adding
        Task {
            do {
                let due = try await RemindersService.shared.add(r)
                state = .added(due: due)
            } catch {
                state = .failed((error as? LocalizedError)?.errorDescription ?? "加入失败")
            }
        }
    }
}

import SwiftUI
import UIKit

// 第①层专属卡：火车票（12306）。对标真版机票卡：超大站名 + Origin/Destination 标签
// + 中间车标 + hairline 分段 + 日期/状态 + 底部圆形 check 席别。
struct TrainCard: View {
    let t: Block.Train

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // —— 站名段：出发  🚆  到达 ——
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(t.fromStation).font(.system(size: 24, weight: .bold)).foregroundStyle(Theme.text)
                    Text(t.departTime).font(.system(size: 15)).foregroundStyle(Theme.text2)
                }
                Spacer()
                Image(systemName: "tram.fill").font(.system(size: 20)).foregroundStyle(Theme.text)
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(t.toStation).font(.system(size: 24, weight: .bold)).foregroundStyle(Theme.text)
                    Text(t.arriveTime).font(.system(size: 15)).foregroundStyle(Theme.text2)
                }
            }
            .padding(.bottom, 16)

            Divider().overlay(Theme.hairline)

            // —— 车次/日期段：车次  ·····  历时 ——
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(t.number).font(.system(size: 18, weight: .semibold)).foregroundStyle(Theme.text)
                if let date = t.date {
                    Text(date).font(.system(size: 14)).foregroundStyle(Theme.textTertiary)
                }
                Spacer()
                if let dur = t.duration {
                    Text(dur).font(.system(size: 14)).foregroundStyle(Theme.textTertiary)
                }
            }
            .padding(.vertical, 14)

            // —— 席别段：圆形 check + 价格（等宽均分，不用 Spacer 撑）——
            if !t.seats.isEmpty {
                Divider().overlay(Theme.hairline)
                HStack(alignment: .top, spacing: 12) {
                    ForEach(t.seats) { seat in
                        seatCol(seat)
                    }
                }
                .padding(.top, 16)
            }

            // —— 去高铁管家购票 ——
            Divider().overlay(Theme.hairline).padding(.vertical, 14)
            Button {
                openGTGJ()
            } label: {
                HStack {
                    Image(systemName: "ticket.fill").font(.system(size: 14))
                    Text("用高铁管家购票").font(.system(size: 16, weight: .medium))
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(Theme.blue)
            }
        }
        .padding(20)
        .background(Theme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
    }

    // 调起高铁管家 App（gtgj://），没装则退回 App Store
    private func openGTGJ() {
        if let app = URL(string: "gtgj://"), UIApplication.shared.canOpenURL(app) {
            UIApplication.shared.open(app)
        } else if let store = URL(string: "https://apps.apple.com/cn/app/id417152958") {
            UIApplication.shared.open(store)
        }
    }

    @ViewBuilder private func seatCol(_ seat: Block.TrainSeat) -> some View {
        let avail = !(seat.remaining?.contains("无") ?? false)
        VStack(spacing: 6) {
            ZStack {
                Circle().fill(avail ? Theme.green : Theme.text3.opacity(0.4))
                    .frame(width: 26, height: 26)
                Image(systemName: avail ? "checkmark" : "xmark")
                    .font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
            }
            Text(seat.name).font(.system(size: 13)).foregroundStyle(Theme.text2)
            if let price = seat.price {
                Text("¥\(Int(price))").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.text)
            }
            if let rem = seat.remaining {
                Text(rem).font(.system(size: 12))
                    .foregroundStyle(avail ? Theme.green : Theme.text3)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

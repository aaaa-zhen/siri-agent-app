import SwiftUI

// 专属卡片预览页 —— 只用于看效果，不接入 chat 功能。
// 在 Xcode 打开本文件，右侧 Canvas 点 Resume 即可预览三张卡片。
struct CardGallery: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                label("天气卡")
                WeatherCard(w: .init(city: "东京", temp: 22, condition: "多云转晴",
                                     icon: "🌤", high: 24, low: 16,
                                     hint: "下午 3 点后转晴，傍晚风稍大，带件薄外套。"))

                label("智能家居设备卡")
                DevicesCard(items: [
                    .init(name: "客厅氛围灯", on: true, icon: "💡", detail: "暖白 60%"),
                    .init(name: "书房灯", on: true, icon: "💡", detail: nil),
                    .init(name: "餐厅灯", on: false, icon: "⚫", detail: nil),
                    .init(name: "客厅空调", on: true, icon: "❄️", detail: "26°C"),
                ])

                label("股票行情卡（涨）")
                StockCard(s: .init(name: "贵州茅台", code: "600519",
                                   price: 1680.5, change: 12.3, changePct: 0.74))

                label("股票行情卡（跌）")
                StockCard(s: .init(name: "宁德时代", code: "300750",
                                   price: 185.6, change: -4.2, changePct: -2.21))

                label("打车卡（Uber 风行程进度）")
                RideCard(r: .init(carType: "滴滴专车", plate: "沪A·8888",
                                  driver: "王师傅 · 4.9★", price: 48,
                                  eta: "20:22 到达", status: "前往目的地",
                                  dest: "浦东国际机场", progress: 0.45))

                label("瑞幸咖啡卡（菜单态 · 带图 + 原价划线 + 角标）")
                CoffeeCard(c: .init(name: "生椰拿铁", spec: "大杯 · 冰",
                                    price: 16.6, originalPrice: 20, badge: "首创", icon: "☕️",
                                    imageURL: "https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=200&q=80"))

                label("瑞幸咖啡卡（已下单态）")
                CoffeeCard(c: .init(name: "生椰杨枝甘露", spec: "大杯 · 冰 · 少甜",
                                    price: 14.9, store: "南方软件园南门店",
                                    pickup: "预计 15 分钟可取", status: "已下单", icon: "🥥"))

                label("美团优惠券卡")
                CouponCard(c: .init(title: "全场通用券 满30减15", amount: "¥15",
                                    threshold: "满30元可用", validUntil: "6月30日到期",
                                    scope: "全场通用", brand: "美团外卖"))

                label("美团酒店卡（带图）")
                HotelCard(h: .init(name: "全季酒店(人民广场店)", rating: 4.8, price: 328,
                                   area: "南京路步行街", roomType: "高级大床房",
                                   distance: "距您 1.2km", tags: ["免费取消", "含早餐"],
                                   imageURL: "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400&q=80"))

                label("文件卡（Excel / Word / PPT / PDF）")
                VStack(spacing: 12) {
                    FileCard(f: .init(name: "Q2 销售报表.xlsx", ext: "xlsx", size: "24 KB", url: ""))
                    FileCard(f: .init(name: "项目方案.docx", ext: "docx", size: "156 KB", url: ""))
                    FileCard(f: .init(name: "季度汇报.pptx", ext: "pptx", size: "3.2 MB", url: ""))
                    FileCard(f: .init(name: "合同.pdf", ext: "pdf", size: "890 KB", url: ""))
                }

                label("视频卡（内联播放）")
                VideoCard(v: .init(
                    url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
                    poster: "https://images.unsplash.com/photo-1574375927938-d5a98e8ffe85?w=600&q=80",
                    title: "演示视频 · Big Buck Bunny", duration: "0:42"))

                label("导航卡（真实地图）")
                NavigationCard(n: .init(from: "人民广场", to: "浦东国际机场",
                                        distance: "42.5 公里", duration: "约 48 分钟",
                                        summary: "走 S1 沪芦高速，全程较顺畅",
                                        amapURL: "iosamap://navi?sourceApplication=agent",
                                        toLat: 31.1443, toLng: 121.8083,
                                        fromLat: 31.2304, fromLng: 121.4737))

                label("提醒卡（默认 · 可加入）")
                ReminderCard(r: .init(title: "和 Ken 吃午饭",
                                      time: "今天 12:00 – 13:30",
                                      due: "2026-06-14T12:00:00",
                                      note: "东南角石凳那边，停车场旁"))

                label("提醒卡（已加入 · 倒计时）")
                ReminderCard(r: .init(title: "组会评审",
                                      time: "今天 16:30",
                                      due: nil,
                                      note: "三楼会议室"),
                             previewState: .added(due: Date().addingTimeInterval(2 * 3600 + 13 * 60)))

                label("火车票卡（12306）")
                TrainCard(t: .init(number: "G1234", date: "7月1日",
                                   fromStation: "上海虹桥", toStation: "北京南",
                                   departTime: "09:15", arriveTime: "13:48",
                                   duration: "4h33m",
                                   seats: [
                                    .init(name: "二等座", price: 553, remaining: "有票"),
                                    .init(name: "一等座", price: 933, remaining: "12张"),
                                    .init(name: "商务座", price: 1748, remaining: "无"),
                                   ]))
            }
            .padding(20)
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
    }

    private func label(_ t: String) -> some View {
        Text(t).font(.system(size: 13)).foregroundStyle(Theme.text3)
    }
}

#Preview {
    CardGallery()
}

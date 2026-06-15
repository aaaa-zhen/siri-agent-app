import Foundation

// 第①层契约：封闭的块词汇表。等价于 web 的 TS discriminated union。
// 模型只能用这些块；不认识的 → 兜底降级成 .text（第②层）。

enum Block: Identifiable, Equatable {
    case text(String)
    case heading(text: String, level: Int)
    case primaryAnswer(text: String, unit: String?)
    case callout(icon: String?, title: String?, text: String, tone: Tone)
    case quote(text: String, author: String?)
    case list(ordered: Bool, items: [String])
    case table(headers: [String], rows: [[String]])
    case code(language: String?, code: String)
    case math(expr: String, block: Bool)             // block=true 居中独占；false 行内
    case cardSection(title: String, description: String?)  // 可点击分区（标题+描述+chevron）
    case divider
    case source(name: String, extra: Int?)
    case status(text: String, tone: PillTone)

    // —— 第①层专属卡片 ——
    case weather(Weather)
    case devices([Device])
    case stock(Stock)
    case ride(Ride)
    case navigation(Navigation)
    case reminder(Reminder)
    case train(Train)
    case coffee(Coffee)       // 瑞幸点咖啡
    case coupon(Coupon)       // 美团优惠券
    case hotel(Hotel)         // 美团酒店
    case file(FileAttach)     // 办公文件（xlsx/docx/pptx/pdf）
    case video(Video)         // 视频（内联播放）

    enum Tone: String { case info, success, warning }
    enum PillTone: String { case neutral, green, red }

    struct Weather: Equatable {
        var city: String; var temp: Int; var condition: String
        var icon: String?; var high: Int?; var low: Int?; var hint: String?
    }
    struct Device: Equatable, Identifiable {
        var id = UUID()
        var name: String; var on: Bool; var icon: String?; var detail: String?
    }
    struct Stock: Equatable {
        var name: String; var code: String?; var price: Double
        var change: Double; var changePct: Double
    }
    // 打车卡（滴滴/Uber 风行程进度卡）
    struct Ride: Equatable {
        var carType: String      // 车型/平台，如"滴滴专车"
        var plate: String?       // 车牌
        var driver: String?      // 司机+评分
        var price: Double?       // 预估价
        var eta: String?         // "3 分钟到达" / "8:22 到达"
        var status: String?      // "已叫到车" / "等待接驾" / "前往目的地"
        var dest: String?        // 目的地（副标题 "前往 xxx"）
        var progress: Double?    // 行程进度 0~1（小车在轨道上的位置；nil 则不画轨道）
    }
    // 导航卡（高德）。带坐标则渲染真实地图。
    struct Navigation: Equatable {
        var from: String; var to: String
        var distance: String?    // "12.5 公里"
        var duration: String?    // "约 28 分钟"
        var summary: String?     // 路线摘要
        var amapURL: String?     // 高德唤起链接
        // 坐标（可选）：有终点坐标就渲染地图标注
        var toLat: Double?; var toLng: Double?
        var fromLat: Double?; var fromLng: Double?
    }
    // 提醒卡
    struct Reminder: Equatable {
        var title: String
        var time: String?        // "今天 18:00" / "12:00–13:30"（给人看的中文）
        var due: String?         // 机器可读本地 ISO8601 "2026-06-13T12:00:00"（加入系统提醒/倒计时用）
        var note: String?        // 备注
    }
    // 火车票卡（12306）
    struct Train: Equatable {
        var number: String           // 车次 G1234
        var date: String?            // "7月1日"
        var fromStation: String      // 出发站
        var toStation: String        // 到达站
        var departTime: String       // 出发时刻 09:15
        var arriveTime: String       // 到达时刻 12:40
        var duration: String?        // 历时 3h25m
        var seats: [TrainSeat]       // 座位类型
    }
    struct TrainSeat: Equatable, Identifiable {
        var id = UUID()
        var name: String             // "二等座"/"一等座"/"商务座"
        var price: Double?
        var remaining: String?       // "有票"/"12张"/"无"
    }

    // 瑞幸点咖啡卡（兼容「菜单态」和「已下单态」）
    struct Coffee: Equatable {
        var name: String             // "生椰拿铁"
        var spec: String?            // "大杯 / 冰 / 少甜"
        var price: Double?           // 到手价/单价
        var originalPrice: Double?   // 原价（划线，菜单态显示优惠）
        var badge: String?           // 角标，如 "新品" / "首创"
        var store: String?           // 门店
        var pickup: String?          // "预计 15 分钟可取" / 取餐号
        var status: String?          // "已下单" / "制作中" / "待取餐"
        var icon: String?            // emoji，如 ☕️（无图时的占位）
        var imageURL: String?        // 咖啡图片（有则替代 emoji）
    }

    // 美团优惠券卡
    struct Coupon: Equatable {
        var title: String            // 券名 "满30减15"
        var amount: String?          // 面额 "¥15" / "8.5折"
        var threshold: String?       // 门槛 "满30元可用"
        var validUntil: String?      // 有效期 "6月30日到期"
        var scope: String?           // 适用范围 "全场通用" / "仅限餐饮"
        var brand: String?           // 品牌/商家
    }

    // 美团酒店卡
    struct Hotel: Equatable {
        var name: String             // 酒店名
        var rating: Double?          // 评分 4.8
        var price: Double?           // 起价/晚
        var area: String?            // 地段 "南京路步行街"
        var roomType: String?        // 房型 "高级大床房"
        var distance: String?        // "距您 1.2km"
        var tags: [String]           // 标签 ["免费取消","含早餐"]
        var imageURL: String?        // 酒店缩略图
    }

    // 办公文件卡（xlsx/docx/pptx/pdf/csv…）
    struct FileAttach: Equatable {
        var name: String             // 文件名 "销售报表.xlsx"
        var ext: String              // 扩展名 "xlsx"（决定图标/色）
        var size: String?            // "24 KB"
        var url: String              // 下载地址（VPS /file?path=...）
    }

    // 视频卡（内联播放）
    struct Video: Equatable {
        var url: String              // 视频地址
        var poster: String?          // 封面图（可选）
        var title: String?           // 标题
        var duration: String?        // "0:42"
    }

    // 稳定 id：用于 SwiftUI diff（流式时同一块更新而非重建）
    var id: String {
        switch self {
        case .text: return "text"
        case .heading: return "heading"
        case .primaryAnswer: return "primary"
        case .callout: return "callout"
        case .quote: return "quote"
        case .list: return "list"
        case .table: return "table"
        case .code: return "code"
        case .math: return "math"
        case .cardSection: return "cardSection"
        case .divider: return "divider"
        case .source: return "source"
        case .status: return "status"
        case .weather: return "weather"
        case .devices: return "devices"
        case .stock: return "stock"
        case .ride: return "ride"
        case .navigation: return "navigation"
        case .reminder: return "reminder"
        case .train: return "train"
        case .coffee: return "coffee"
        case .coupon: return "coupon"
        case .hotel: return "hotel"
        case .file: return "file"
        case .video: return "video"
        }
    }

    // 是不是第①层专属卡片（用于：含卡片的回复整条走 standard，不跑文字动画）
    var isCard: Bool {
        switch self {
        case .weather, .devices, .stock, .ride, .navigation, .reminder, .train,
             .coffee, .coupon, .hotel, .file, .video:
            return true
        default:
            return false
        }
    }
}

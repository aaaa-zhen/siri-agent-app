import Foundation

// JSON 字典 → Block。不认识的 type → 第②层兜底降级成 .text。
enum BlockDecoder {
    static func decode(_ d: [String: Any]) -> Block? {
        guard let type = d["type"] as? String else { return nil }
        let s = { (k: String) -> String? in d[k] as? String }
        let i = { (k: String) -> Int? in (d[k] as? Int) ?? (d[k] as? Double).map { Int($0) } }
        let dbl = { (k: String) -> Double? in (d[k] as? Double) ?? (d[k] as? Int).map(Double.init) }

        switch type {
        case "text": return .text(s("text") ?? "")
        case "heading": return .heading(text: s("text") ?? "", level: i("level") ?? 2)
        case "primaryAnswer": return .primaryAnswer(text: s("text") ?? "", unit: s("unit"))
        case "callout":
            return .callout(icon: s("icon"), title: s("title"), text: s("text") ?? "",
                            tone: Block.Tone(rawValue: s("tone") ?? "info") ?? .info)
        case "quote": return .quote(text: s("text") ?? "", author: s("author"))
        case "list":
            return .list(ordered: d["ordered"] as? Bool ?? false, items: (d["items"] as? [String]) ?? [])
        case "table":
            return .table(headers: (d["headers"] as? [String]) ?? [],
                          rows: (d["rows"] as? [[String]]) ?? [])
        case "code": return .code(language: s("language"), code: s("code") ?? "")
        case "math": return .math(expr: s("expr") ?? "", block: (d["block"] as? Bool) ?? true)
        case "cardSection": return .cardSection(title: s("title") ?? "", description: s("description"))
        case "divider": return .divider
        case "source": return .source(name: s("name") ?? "", extra: i("extra"))
        case "status":
            return .status(text: s("text") ?? "", tone: Block.PillTone(rawValue: s("tone") ?? "neutral") ?? .neutral)

        // 专属卡片（暂未渲染，先解码，避免丢数据）
        case "weather":
            return .weather(.init(city: s("city") ?? "", temp: i("temp") ?? 0,
                condition: s("condition") ?? "", icon: s("icon"),
                high: i("high"), low: i("low"), hint: s("hint")))
        case "devices":
            let arr = (d["items"] as? [[String: Any]]) ?? []
            return .devices(arr.map { .init(name: $0["name"] as? String ?? "",
                on: $0["on"] as? Bool ?? false, icon: $0["icon"] as? String, detail: $0["detail"] as? String) })
        case "stock":
            return .stock(.init(name: s("name") ?? "", code: s("code"),
                price: dbl("price") ?? 0, change: dbl("change") ?? 0, changePct: dbl("changePct") ?? 0))
        case "ride":
            return .ride(.init(carType: s("carType") ?? "打车", plate: s("plate"),
                driver: s("driver"), price: dbl("price"), eta: s("eta"), status: s("status"),
                dest: s("dest"), progress: dbl("progress")))
        case "navigation":
            return .navigation(.init(from: s("from") ?? "", to: s("to") ?? "",
                distance: s("distance"), duration: s("duration"),
                summary: s("summary"), amapURL: s("amapURL"),
                toLat: dbl("toLat"), toLng: dbl("toLng"),
                fromLat: dbl("fromLat"), fromLng: dbl("fromLng")))
        case "reminder":
            return .reminder(.init(title: s("title") ?? "", time: s("time"), due: s("due"), note: s("note")))
        case "train":
            let seatArr = (d["seats"] as? [[String: Any]]) ?? []
            return .train(.init(number: s("number") ?? "", date: s("date"),
                fromStation: s("fromStation") ?? "", toStation: s("toStation") ?? "",
                departTime: s("departTime") ?? "", arriveTime: s("arriveTime") ?? "",
                duration: s("duration"),
                seats: seatArr.map { .init(name: $0["name"] as? String ?? "",
                    price: ($0["price"] as? Double) ?? ($0["price"] as? Int).map(Double.init),
                    remaining: $0["remaining"] as? String) }))

        case "coffee":
            return .coffee(.init(name: s("name") ?? "", spec: s("spec"), price: dbl("price"),
                originalPrice: dbl("originalPrice"), badge: s("badge"),
                store: s("store"), pickup: s("pickup"), status: s("status"),
                icon: s("icon"), imageURL: s("imageURL")))
        case "coupon":
            return .coupon(.init(title: s("title") ?? "", amount: s("amount"),
                threshold: s("threshold"), validUntil: s("validUntil"),
                scope: s("scope"), brand: s("brand")))
        case "hotel":
            return .hotel(.init(name: s("name") ?? "", rating: dbl("rating"), price: dbl("price"),
                area: s("area"), roomType: s("roomType"), distance: s("distance"),
                tags: (d["tags"] as? [String]) ?? [], imageURL: s("imageURL")))
        case "file":
            return .file(.init(name: s("name") ?? "文件", ext: s("ext") ?? "",
                size: s("size"), url: s("url") ?? ""))
        case "video":
            return .video(.init(url: s("url") ?? "", poster: s("poster"),
                title: s("title"), duration: s("duration")))

        // 第②层兜底：不认识 → 降级成文字
        default:
            let salvage = s("text") ?? s("title") ?? s("caption") ?? "（未知块 \(type)）"
            return .text(salvage)
        }
    }
}

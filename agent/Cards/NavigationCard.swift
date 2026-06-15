import SwiftUI
import UIKit
import MapKit

// 第①层专属卡：导航（高德）。有坐标时嵌真实地图（对标真版地图卡），否则退回连线布局。
struct NavigationCard: View {
    let n: Block.Navigation

    private var hasMap: Bool { n.toLat != nil && n.toLng != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if hasMap {
                mapView
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .padding(.bottom, 16)
            }

            // 终点 + 距离/时长
            VStack(alignment: .leading, spacing: 6) {
                if let dur = n.duration {
                    Text(dur).font(.system(size: 24, weight: .bold)).foregroundStyle(Theme.text)
                }
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill").font(.system(size: 15)).foregroundStyle(Theme.red)
                    Text(n.to).font(.system(size: 16, weight: .medium)).foregroundStyle(Theme.text)
                    if let dist = n.distance {
                        Text("· \(dist)").font(.system(size: 15)).foregroundStyle(Theme.text2)
                    }
                }
                if let summary = n.summary {
                    Text(summary).font(.system(size: 14)).foregroundStyle(Theme.text2)
                }
            }

            if let url = amapDeepLink() {
                Divider().overlay(Theme.hairline).padding(.vertical, 14)
                Button {
                    UIApplication.shared.open(url) { ok in
                        // 高德没装/打不开 → 退回 https 网页
                        if !ok, let urlStr = n.amapURL, let web = URL(string: urlStr) {
                            UIApplication.shared.open(web)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "location.fill").font(.system(size: 13))
                        Text("在高德打开").font(.system(size: 16, weight: .medium))
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(Theme.blue)
                }
            }
        }
        .padding(hasMap ? 12 : 20)
        .background(Theme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
    }

    // 构建高德 App 直接调起的 URL Scheme（iosamap://），优先用坐标
    private func amapDeepLink() -> URL? {
        if let lat = n.toLat, let lng = n.toLng {
            let name = n.to.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? n.to
            // iosamap 路线规划：dev=0 表示 gcj02(高德)坐标，t=0 驾车
            let s = "iosamap://path?sourceApplication=agent&dlat=\(lat)&dlon=\(lng)&dname=\(name)&dev=0&t=0"
            return URL(string: s)
        }
        // 没坐标但 agent 给了 iosamap:// 链接也用
        if let urlStr = n.amapURL, urlStr.hasPrefix("iosamap://") { return URL(string: urlStr) }
        return nil
    }

    private var mapView: some View {
        let to = CLLocationCoordinate2D(latitude: n.toLat!, longitude: n.toLng!)
        return Map(initialPosition: .region(MKCoordinateRegion(
            center: to,
            span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)))) {
            if let fLat = n.fromLat, let fLng = n.fromLng {
                Marker(n.from, systemImage: "location.fill",
                       coordinate: CLLocationCoordinate2D(latitude: fLat, longitude: fLng))
                    .tint(.green)
            }
            Marker(n.to, coordinate: to).tint(.red)
        }
        .mapStyle(.standard)
        .allowsHitTesting(false)
    }
}

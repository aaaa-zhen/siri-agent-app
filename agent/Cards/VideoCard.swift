import SwiftUI
import AVKit

// 第①层专属卡：视频。内联播放器（点击播放），可带封面/标题/时长。
struct VideoCard: View {
    let v: Block.Video
    @State private var player: AVPlayer?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                if let player {
                    VideoPlayer(player: player)
                } else {
                    // 未播放：封面 + 播放按钮
                    poster
                    Button(action: play) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(.white.opacity(0.95))
                            .shadow(radius: 8)
                    }
                    if let dur = v.duration {
                        VStack { Spacer()
                            HStack { Spacer()
                                Text(dur).font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 7).padding(.vertical, 3)
                                    .background(.black.opacity(0.55), in: Capsule())
                            }
                        }
                        .padding(10)
                    }
                }
            }
            .aspectRatio(16.0/9.0, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .background(Color.black)

            if let title = v.title {
                Text(title).font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.text)
                    .padding(.horizontal, 14).padding(.vertical, 12)
            }
        }
        .background(Theme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: Theme.imageRadius, style: .continuous))
    }

    @ViewBuilder private var poster: some View {
        if let p = v.poster.flatMap(URL.init) {
            AsyncImage(url: p) { img in img.resizable().scaledToFill() }
            placeholder: { Color.black }
        } else {
            Color.black
        }
    }

    private func play() {
        guard let url = URL(string: v.url) else { return }
        let p = AVPlayer(url: url)
        player = p
        p.play()
    }
}

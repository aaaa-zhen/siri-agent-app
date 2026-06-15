import SwiftUI
import PhotosUI

struct ContentView: View {
    @StateObject private var client = AgentClient()
    @StateObject private var settings = CanvasSettings()
    @State private var input = ""
    @State private var pickerItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?
    @State private var showGallery = false
    @FocusState private var focused: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 28) {
                            if client.turns.isEmpty {
                                hero.padding(.top, 60)
                            }
                            ForEach(client.turns) { turn in
                                turnView(turn).id(turn.id)
                            }
                            Color.clear.frame(height: 1).id("bottom")
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 24)
                    }
                    .scrollDismissesKeyboard(.interactively)   // 下拉滚动时收键盘
                    .onChange(of: client.streamTick) { _, _ in
                        // 流式时无动画滚到底（带动画每秒十几次是卡顿主因）
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                    // 新一轮对话开始（发送后 turns 增加）→ 滚到底，让新内容露出
                    .onChange(of: client.turns.count) { _, _ in
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                    // 键盘弹起 → 滚到底，避免最后内容被键盘/输入框遮住
                    .onChange(of: focused) { _, isFocused in
                        if isFocused {
                            withAnimation(.easeOut(duration: 0.25)) {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                }

                composer
            }
            // 点对话区空白处收键盘
            .contentShape(Rectangle())
            .onTapGesture { focused = false }
        }
        .preferredColorScheme(.dark)
        .onAppear { client.connect() }
        .sheet(isPresented: $showGallery) { CardGallery() }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personal Assistant").font(.system(size: 28, weight: .bold))
                .foregroundStyle(Theme.text)
                // 长按标题 → 打开卡片画廊（开发预览，隐藏入口）
                .onLongPressGesture { showGallery = true }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private func turnView(_ turn: AgentClient.Turn) -> some View {
        HStack {
            Spacer(minLength: 56)
            Text(turn.prompt)
                .font(.system(size: 17)).foregroundStyle(Theme.text)
                .padding(.horizontal, 17).padding(.vertical, 12)
                .background(Theme.cardBG)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }

        // 正文走 settings.textEffect（默认 spectral）；卡片在 BlockView 内恒 standard。
        // 块之间用 cascadeReveal 错峰进场：每块按次序延迟浮现（位移+淡入），
        // 形成「文字→卡片→卡片」一个推一个往下码的节奏（对标苹果 cascadeThreshold）。
        VStack(alignment: .leading, spacing: Theme.blockGap) {
            // key = 下标 + 块类型：同位置块类型变了才重建（避免 reveal 状态串台/闪），
            // 同位置文字增长（同类型）则复用 view，不重播动画。
            ForEach(keyedBlocks(turn.blocks)) { item in
                BlockView(block: item.block, effect: settings.textEffect)
                    .cascadeReveal(order: item.index, enabled: settings.springEnter)
                    .id("blk-\(item.index)")
            }
            if let err = turn.error {
                Text("⚠️ \(err)").font(.system(size: 15)).foregroundStyle(Theme.red)
            }
            if !turn.done && turn.blocks.isEmpty {
                ProgressView().tint(Theme.text2).padding(.vertical, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(reflowAnimation, value: turn.blocks.count)
    }

    // ForEach 用的稳定 key：下标 + 块类型。同位置块类型变了 → id 变 → 重建（reveal 状态不串台）；
    // 同位置同类型（文字流式增长）→ id 不变 → 复用 view，不重播。
    private struct KeyedBlock: Identifiable {
        let index: Int
        let block: Block
        var id: String { "\(index)-\(block.id)" }
    }
    private func keyedBlocks(_ blocks: [Block]) -> [KeyedBlock] {
        blocks.enumerated().map { KeyedBlock(index: $0.offset, block: $0.element) }
    }

    // 块重排/进场动画的择一逻辑：进场弹簧优先，否则用弹性联动，再否则不动画。
    private var reflowAnimation: Animation? {
        if settings.springEnter { return Theme.cardEnter }
        if settings.elasticReflow { return Theme.reflow }
        return nil
    }

    private var composer: some View {
        // 整个输入区是一个连贯容器：缩略图行（在内部上方）+ 输入行（对标 ChatGPT）
        VStack(alignment: .leading, spacing: 0) {
            // 选中的图片缩略图预览（放在容器内部上方，带删除）
            if let img = pickedImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: img)
                        .resizable().scaledToFill()
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    Button {
                        pickedImage = nil; pickerItem = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(.black.opacity(0.55), in: Circle())
                            .overlay(Circle().stroke(.white.opacity(0.25), lineWidth: 0.5))
                    }
                    .padding(5)
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 2)
            }

            HStack(alignment: .bottom, spacing: 6) {
                // “+” 加图片
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Theme.text2)
                        .frame(width: 36, height: 36)
                        .background(Theme.cardBG)
                        .clipShape(Circle())
                }
                .padding(.leading, 6).padding(.bottom, 6)

                TextField("Ask anything…", text: $input, axis: .vertical)
                    .focused($focused)
                    .font(.system(size: 17))
                    .foregroundStyle(Theme.text)
                    .tint(Theme.blue)
                    .lineLimit(1...6)
                    .padding(.vertical, 12)
                    .frame(minHeight: 36)

                // busy → 停止方块；否则 → 发送箭头
                Button(action: client.busy ? stop : send) {
                    Image(systemName: client.busy ? "stop.fill" : "arrow.up")
                        .font(.system(size: client.busy ? 15 : 18, weight: .bold))
                        .foregroundStyle(client.busy || canSend ? .black : Theme.text3)
                        .frame(width: 36, height: 36)
                        .background(client.busy || canSend ? Color.white : Theme.cardBG)
                        .clipShape(Circle())
                }
                .disabled(!client.busy && !canSend)
                .padding(6)
            }
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .frame(maxWidth: 440)                    // 收窄，宽屏不撑满
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let ui = UIImage(data: data) {
                    pickedImage = ui
                }
            }
        }
    }

    private var canSend: Bool {
        !client.busy && (!input.trimmingCharacters(in: .whitespaces).isEmpty || pickedImage != nil)
    }

    private func send() {
        let p = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let imgB64 = pickedImage.flatMap { $0.jpegData(compressionQuality: 0.7)?.base64EncodedString() }
        guard !p.isEmpty || imgB64 != nil else { return }
        input = ""
        pickedImage = nil; pickerItem = nil
        focused = false
        client.ask(p, imageB64: imgB64)
    }

    private func stop() {
        client.cancel()
    }
}

#Preview { ContentView() }

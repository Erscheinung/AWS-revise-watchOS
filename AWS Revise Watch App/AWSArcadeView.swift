import SwiftUI
import WatchKit

// MARK: - Shared arcade content

private enum ArcadeGame: String, CaseIterable, Identifiable {
    case catcher, sorter, scaleOps
    var id: String { rawValue }
    var title: String {
        switch self {
        case .catcher: return "Service Catcher"
        case .sorter: return "Service Sorter"
        case .scaleOps: return "Scale Ops"
        }
    }
    var subtitle: String {
        switch self {
        case .catcher: return "Catch the right services. Dodge the noise."
        case .sorter: return "Sort a live conveyor under pressure."
        case .scaleOps: return "Balance traffic, capacity, and cost."
        }
    }
    var detail: String {
        switch self {
        case .catcher: return "Crown steers the collector"
        case .sorter: return "Crown picks the category"
        case .scaleOps: return "Crown sets EC2 instance capacity"
        }
    }
    var symbol: String {
        switch self {
        case .catcher: return "arrow.down.to.line.compact"
        case .sorter: return "arrow.left.arrow.right"
        case .scaleOps: return "server.rack"
        }
    }
    var tint: Color {
        switch self {
        case .catcher: return .cyan
        case .sorter: return .orange
        case .scaleOps: return .green
        }
    }
}

private extension ServiceCategory {
    var tint: Color {
        switch self {
        case .compute: return .orange
        case .storage: return .cyan
        case .network: return .purple
        case .security: return .green
        case .data: return .yellow
        }
    }
}

private struct ArcadeHeader: View {
    let title: String
    let tint: Color
    let onPause: (() -> Void)?
    var body: some View {
        HStack(spacing: 5) {
            Text(title.uppercased()).font(.system(size: 10, weight: .heavy, design: .rounded)).foregroundStyle(tint)
            Spacer(minLength: 0)
            if let onPause {
                Button(action: onPause) { Image(systemName: "pause.fill").font(.system(size: 10, weight: .bold)).frame(width: 20, height: 18) }
                    .buttonStyle(.plain).tint(.secondary).accessibilityLabel("Pause game")
            }
        }
    }
}

private struct ArcadePauseOverlay: View {
    let tint: Color
    let onResume: () -> Void
    let onQuit: () -> Void
    var body: some View {
        ZStack {
            Color.black.opacity(0.82)
            VStack(spacing: 7) {
                Image(systemName: "pause.circle.fill").font(.system(size: 30)).foregroundStyle(tint)
                Text("Paused").font(.system(.headline, design: .rounded, weight: .bold))
                HStack(spacing: 6) {
                    Button("Resume", action: onResume).tint(tint)
                    Button("Quit", action: onQuit).tint(.secondary)
                }.buttonStyle(.borderedProminent)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .contain).accessibilityLabel("Game paused")
    }
}

private struct ArcadeResultView: View {
    let game: ArcadeGame
    let score: Int
    let best: Int
    let summary: String
    let fact: String
    let onReplay: () -> Void
    let onDone: () -> Void
    var body: some View {
        VStack(spacing: 5) {
            ScrollViewReader { scroll in
                ScrollView {
                    VStack(spacing: 6) {
                        Image(systemName: score > 0 ? "sparkles" : "arrow.counterclockwise.circle.fill")
                            .resizable().scaledToFit().frame(width: 24, height: 24).foregroundStyle(game.tint)
                        Text(score > 0 ? "Run complete" : "Keep tuning").font(.system(size: 15, weight: .bold, design: .rounded))
                        Text("\(score) pts · best \(best)").font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundStyle(.secondary)
                        Text(summary).font(.system(size: 11, weight: .medium, design: .rounded))
                        Text(fact).font(.system(size: 10, design: .rounded)).foregroundStyle(.secondary)
                    }.multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .top)
                        .padding(.horizontal, 7).padding(.top, 10).padding(.bottom, 8).id("resultTop")
                }.defaultScrollAnchor(.top)
                    .onAppear { scroll.scrollTo("resultTop", anchor: .top) }
            }
            HStack(spacing: 6) {
                resultButton("Replay", tint: game.tint, action: onReplay)
                resultButton("Arcade", tint: .gray, action: onDone)
            }.padding(.horizontal, 9).padding(.bottom, 8)
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    private func resultButton(_ title: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.system(size: 12, weight: .bold))
                .frame(maxWidth: .infinity).frame(height: 30)
                .background(tint.opacity(0.28), in: Capsule())
        }.buttonStyle(.plain)
    }
}

// This leaf exists only while a game is on screen. Do not put Crown modifiers
// around the intro/result ScrollViews: they already own their scroll sequencers.
// Keep the focusable surface separate from buttons so its focus does not wrap
// their interaction hierarchy, and never register a Crown on a nonfocusable view.
private struct ArcadeCrownSurface: View {
    @Binding var value: Double
    let lower: Double
    let upper: Double
    let step: Double
    let sensitivity: DigitalCrownRotationalSensitivity
    let continuous: Bool
    let active: Bool
    @State private var detent = 0
    @FocusState private var focused: Bool

    private var detentCount: Int { max(1, Int(((upper - lower) / step).rounded())) }
    private func position(for value: Double) -> Int {
        min(detentCount, max(0, Int(((value - lower) / (upper - lower) * Double(detentCount)).rounded())))
    }

    var body: some View {
        Rectangle().fill(.black)
            .focusable()
            .digitalCrownRotation(
                detent: $detent, from: 0, through: detentCount, by: 1,
                sensitivity: sensitivity, isContinuous: continuous,
                isHapticFeedbackEnabled: false
            )
            .focused($focused)
            .onChange(of: detent) { _, newValue in
                guard active else { return }
                value = lower + Double(newValue) / Double(detentCount) * (upper - lower)
            }
            .onChange(of: value) { _, newValue in
                let newPosition = position(for: newValue)
                if detent != newPosition { detent = newPosition }
            }
            .task(id: active) {
                focused = false
                guard active else { return }
                detent = position(for: value)
                // Let the native surface attach before asking for focus.
                do { try await Task.sleep(for: .milliseconds(100)) } catch { return }
                guard !Task.isCancelled else { return }
                focused = true
            }
            .onDisappear { focused = false }
            .accessibilityLabel("Digital Crown game control")
    }
}

// The native Crown value is cumulative and never receives selection echoes.
// The tested reducer makes each accepted movement one deliberate visible step.
private struct ArcadeIntegerCrown: View {
    @Binding var value: Int
    let active: Bool
    let label: String
    let fontSize: CGFloat
    let focusRequest: Int
    @State private var rawPosition = 0
    @State private var input: CrownStepReducer
    @FocusState private var focused: Bool

    init(value: Binding<Int>, lower: Int, upper: Int, active: Bool, label: String,
         fontSize: CGFloat = 10, focusRequest: Int = 0) {
        _value = value
        self.active = active
        self.label = label
        self.fontSize = fontSize
        self.focusRequest = focusRequest
        _input = State(initialValue: CrownStepReducer(position: value.wrappedValue, lower: lower, upper: upper))
    }

    var body: some View {
        Text(label)
            .font(.system(size: fontSize, weight: .semibold, design: .rounded))
            .foregroundStyle(.cyan)
            .lineLimit(1).minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity)
            .focusable()
            .digitalCrownRotation(detent: $rawPosition, from: -10_000, through: 10_000, by: 1,
                                  sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: false)
            .focused($focused)
            .onChange(of: rawPosition) { _, raw in
                if let next = input.consume(raw: raw, at: ProcessInfo.processInfo.systemUptime, enabled: active) {
                    value = next
                }
            }
            .onChange(of: value) { _, selected in input.select(selected) }
            .task(id: "\(active)-\(focusRequest)") {
                focused = false
                guard active else { return }
                do { try await Task.sleep(for: .milliseconds(100)) } catch { return }
                guard !Task.isCancelled else { return }
                focused = true
            }
            .onDisappear { focused = false }
            .accessibilityLabel(label + ". Turn the Digital Crown slowly to adjust one step.")
    }
}

// MARK: - Arcade hub

struct AWSArcadeView: View {
    @State private var selectedGame: ArcadeGame?
    @State private var showingHowTo = false
    @AppStorage("serviceCatcherBest") private var catcherBest = 0
    @AppStorage("serviceSorterBest") private var sorterBest = 0
    @AppStorage("scaleOpsBest") private var scaleOpsBest = 0

    var body: some View {
        GeometryReader { available in
            // Measure the navigation container's safe content area. Games must fit
            // this proposal; their arenas shrink instead of displacing the HUD.
            Group {
                switch selectedGame {
                case .none: hub
                case .catcher: ServiceCatcherView(onDone: { selectedGame = nil })
                case .sorter: ServiceSorterView(onDone: { selectedGame = nil })
                case .scaleOps: ScaleOpsView(onDone: { selectedGame = nil })
                }
            }.frame(width: available.size.width, height: available.size.height)
        }
        .navigationTitle(selectedGame == nil ? "Arcade" : "")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingHowTo) { arcadeHowTo }
    }

    private var hub: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 9) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("CROWN ARCADE").font(.system(size: 10, weight: .heavy, design: .rounded)).foregroundStyle(.cyan)
                        Text("Learn by moving").font(.system(.title3, design: .rounded, weight: .bold))
                    }
                    Spacer(minLength: 0)
                    Button { showingHowTo = true } label: { Image(systemName: "questionmark.circle").font(.system(size: 18, weight: .semibold)) }
                        .buttonStyle(.plain).tint(.secondary).accessibilityLabel("How to play the arcade")
                }
                Text("Three short skill games. Catch services, sort categories, and keep EC2 capacity ahead of traffic.")
                    .font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                ForEach(ArcadeGame.allCases) { game in
                    Button { selectedGame = game } label: { ArcadeGameCard(game: game, best: best(for: game)) }
                        .buttonStyle(.plain).accessibilityLabel("Play \(game.title). \(game.subtitle). Best \(best(for: game))")
                }
                Text("Turn the Crown, feel the timing, then read the AWS fact after each run.")
                    .font(.system(size: 10, design: .rounded)).foregroundStyle(.secondary).multilineTextAlignment(.center).frame(maxWidth: .infinity).padding(.top, 2)
            }.padding(.horizontal, 4).padding(.bottom, 12)
        }
    }

    private var arcadeHowTo: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 9) {
                Text("PLAY WITH THE CROWN").font(.system(size: 11, weight: .heavy, design: .rounded)).foregroundStyle(.cyan)
                Text("Service Catcher").font(.system(.headline, design: .rounded, weight: .bold))
                Text("Steer the collector left and right. Catch the glowing target category, dodge other services and red hazards. The fall speeds up as your streak grows.")
                Text("Service Sorter").font(.system(.headline, design: .rounded, weight: .bold)).foregroundStyle(.orange)
                Text("All five category bins stay visible. Turn the Crown to highlight a destination; the timer sends the service there. Tap any bin to send immediately.")
                Text("Scale Ops").font(.system(.headline, design: .rounded, weight: .bold)).foregroundStyle(.purple)
                Text("Turn the Crown to choose EC2 instances. Watch demand and the next traffic wave: capacity changes take two game seconds. Avoid queue overflows and save budget by scaling down after peaks.")
                Text("Use the Crown to steer, choose, or scale. Leaving the app pauses an active run; it never drains time or resumes by itself.").font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(.secondary)
            }.font(.system(size: 11, design: .rounded)).padding(14)
        }.navigationTitle("How to play")
    }

    private func best(for game: ArcadeGame) -> Int {
        switch game { case .catcher: return catcherBest; case .sorter: return sorterBest; case .scaleOps: return scaleOpsBest }
    }
}

private struct ArcadeGameCard: View {
    let game: ArcadeGame
    let best: Int
    var body: some View {
        HStack(spacing: 9) {
            ZStack { Circle().fill(game.tint.opacity(0.18)); Image(systemName: game.symbol).font(.system(size: 16, weight: .bold)).foregroundStyle(game.tint) }.frame(width: 29, height: 29)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(game.title.uppercased()).font(.system(size: 12, weight: .heavy, design: .rounded))
                    Spacer(minLength: 0)
                    Text("BEST \(best)").font(.system(size: 8, weight: .bold, design: .monospaced)).foregroundStyle(.secondary)
                }
                Text(game.subtitle).font(.system(size: 10, weight: .medium, design: .rounded)).foregroundStyle(.secondary).lineLimit(1)
                Text(game.detail).font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(game.tint)
            }
            Image(systemName: "chevron.right").font(.caption2.weight(.bold)).foregroundStyle(.tertiary)
        }
        .padding(9).background(game.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(game.tint.opacity(0.33), lineWidth: 1) }
    }
}

// MARK: - Service Catcher

private struct ServiceCatcherView: View {
    let onDone: () -> Void
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("serviceCatcherBest") private var best = 0
    @State private var game = CatcherState()
    @State private var lastTick: Date?
    @State private var lastHaptic = Date.distantPast
    @State private var crownX: Double = 0.5

    var body: some View {
        VStack(spacing: 0) {
            switch game.status {
            case .intro: intro
            case .playing, .paused: playing
            case .results: results
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 6)
        .task(id: game.status) {
            guard game.status == .playing else { lastTick = nil; return }
            lastTick = Date()
            while !Task.isCancelled {
                do { try await Task.sleep(for: .milliseconds(33)) } catch { return }
                tick(at: Date())
            }
        }
        .onDisappear { lastTick = nil }
        .onChange(of: scenePhase) { _, phase in
            guard phase != .active, game.status == .playing else { return }
            game.status = .paused; lastTick = nil
        }
        .onChange(of: crownX) { _, value in game.playerX = value }
        .onChange(of: game.hapticPulse) { _, _ in
            let now = Date()
            guard now.timeIntervalSince(lastHaptic) >= 0.25 else { return }
            lastHaptic = now
            WKInterfaceDevice.current().play(.click)
        }
    }

    private var intro: some View {
        ScrollView {
        VStack(spacing: 8) {
            Image(systemName: ArcadeGame.catcher.symbol).font(.system(size: 34, weight: .bold)).foregroundStyle(.cyan)
            Text("SERVICE CATCHER").font(.system(.headline, design: .rounded, weight: .heavy))
            Text("Catch the glowing category. Dodge other services and red hazards as the cloud accelerates.")
                .font(.system(size: 11, design: .rounded)).multilineTextAlignment(.center).foregroundStyle(.secondary)
            Text("CROWN  steer left / right").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(.cyan)
            Button("Start run") { start() }.buttonStyle(.borderedProminent).tint(.cyan)
        }.padding(.horizontal, 8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Service Catcher. Catch the glowing category and dodge hazards. Turn the Digital Crown to steer.")
        }
    }

    private var playing: some View {
        ZStack {
            ArcadeCrownSurface(value: $crownX, lower: 0.09, upper: 0.91, step: 0.035, sensitivity: .high, continuous: false, active: game.status == .playing)
            VStack(spacing: 4) {
                ArcadeHeader(title: "Catcher · \(game.score) pts", tint: .cyan, onPause: pause)
                HStack {
                    Text("Catch \(game.targetCategory.rawValue)").foregroundStyle(game.targetCategory.tint)
                    Spacer(minLength: 2)
                    Label("\(game.lives)", systemImage: "heart.fill").foregroundStyle(.pink)
                }.font(.system(size: 11, weight: .bold, design: .rounded))
                CatcherArena(game: game).frame(maxWidth: .infinity, maxHeight: .infinity)
                    .layoutPriority(-1)
                    .accessibilityLabel("Falling services. Turn Crown to steer")
                Text(game.lastEvent.isEmpty ? "Crown moves the blue catcher" : game.lastEvent)
                    .font(.system(size: 10, weight: .semibold, design: .rounded)).lineLimit(1).minimumScaleFactor(0.8)
            }.padding(.horizontal, 5).padding(.bottom, 5)
            if game.status == .paused { ArcadePauseOverlay(tint: .cyan, onResume: resume, onQuit: onDone) }
        }
    }

    private var results: some View {
        ArcadeResultView(game: .catcher, score: game.score, best: best, summary: "\(game.caught) target services caught · \(game.lives) hull left", fact: game.lastFact, onReplay: start, onDone: onDone)
    }

    private func start() { crownX = 0.5; game.start(); lastTick = Date(); WKInterfaceDevice.current().play(.start) }
    private func pause() { guard game.status == .playing else { return }; game.status = .paused; lastTick = nil }
    private func resume() { guard game.status == .paused else { return }; game.status = .playing; lastTick = Date() }
    private func tick(at date: Date) {
        guard game.status == .playing else { lastTick = nil; return }
        let delta = min(0.1, max(0, date.timeIntervalSince(lastTick ?? date))); lastTick = date; game.tick(delta)
        if game.status == .results { best = max(best, game.score); WKInterfaceDevice.current().play(.failure) }
    }
}

private struct CatcherArena: View {
    let game: CatcherState
    var body: some View {
        Canvas { context, size in
            let w = size.width, h = size.height
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color.black.opacity(0.28)))
            for line in stride(from: 0, through: h, by: 22) {
                var path = Path(); path.move(to: CGPoint(x: 0, y: line)); path.addLine(to: CGPoint(x: w, y: line)); context.stroke(path, with: .color(.cyan.opacity(0.08)), lineWidth: 1)
            }
            for item in game.items {
                let x = CGFloat(item.x) * w, y = CGFloat(item.y) * h
                let tint: Color = item.kind == .hazard ? .red : (item.kind == .target ? game.targetCategory.tint : .gray)
                let rect = CGRect(x: x - 17, y: y - 10, width: 34, height: 20)
                context.fill(Path(roundedRect: rect, cornerRadius: 7), with: .color(tint.opacity(0.88)))
                context.draw(Text(item.kind == .hazard ? "!" : (item.service?.name ?? "?")).font(.system(size: 8, weight: .heavy, design: .rounded)).foregroundStyle(.black), at: CGPoint(x: x, y: y))
            }
            let catcher = CGRect(x: CGFloat(game.playerX) * w - 22, y: h * 0.84, width: 44, height: 18)
            context.fill(Path(roundedRect: catcher, cornerRadius: 8), with: .color(.cyan.opacity(0.9)))
            context.stroke(Path(roundedRect: catcher, cornerRadius: 8), with: .color(.white.opacity(0.8)), lineWidth: 1)
            context.draw(Text("CATCH").font(.system(size: 8, weight: .heavy, design: .monospaced)).foregroundStyle(.black), at: CGPoint(x: CGFloat(game.playerX) * w, y: h * 0.84 + 9))
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(.cyan.opacity(0.34), lineWidth: 1) }
    }
}

// MARK: - Service Sorter

private struct ServiceSorterView: View {
    let onDone: () -> Void
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("serviceSorterBest") private var best = 0
    @State private var game = SorterState()
    @State private var crownSelection = 0
    @State private var crownFocusRequest = 0
    @State private var lastTick: Date?
    @State private var lastHaptic = Date.distantPast

    var body: some View {
        VStack(spacing: 0) {
            switch game.status {
            case .intro: intro
            case .playing, .paused: playing
            case .results: results
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 6)
        .task(id: game.status) {
            guard game.status == .playing else { lastTick = nil; return }
            lastTick = Date()
            while !Task.isCancelled {
                do { try await Task.sleep(for: .milliseconds(33)) } catch { return }
                tick(at: Date())
            }
        }
        .onDisappear { lastTick = nil }
        .onChange(of: scenePhase) { _, phase in
            guard phase != .active, game.status == .playing else { return }
            game.status = .paused; lastTick = nil
        }
        .onChange(of: crownSelection) { _, value in game.selectCategory(at: value) }
        .onChange(of: game.hapticPulse) { _, _ in
            let now = Date()
            guard now.timeIntervalSince(lastHaptic) >= 0.25 else { return }
            lastHaptic = now
            WKInterfaceDevice.current().play(.click)
        }
    }

    private var intro: some View {
        VStack(spacing: 6) {
            Text("SERVICE SORTER").font(.system(size: 16, weight: .heavy, design: .rounded)).foregroundStyle(.orange)
            ScrollView {
                VStack(spacing: 7) {
                    Text("Match each AWS service to a category.")
                    Text("Turn the Crown to highlight a bin. The timer sends the service there. Tap any bin to send now.")
                    Text("All five destinations stay visible.").foregroundStyle(.secondary)
                }.font(.system(size: 12, design: .rounded)).multilineTextAlignment(.center)
                    .padding(.vertical, 5).padding(.horizontal, 4)
            }.defaultScrollAnchor(.top)
            Button(action: start) {
                Text("Start sorting").font(.system(size: 13, weight: .bold))
                    .frame(maxWidth: .infinity).frame(height: 32)
                    .background(.orange.opacity(0.28), in: Capsule())
            }.buttonStyle(.plain)
        }.padding(.horizontal, 7).padding(.top, 5).padding(.bottom, 8)
    }

    private var playing: some View {
        ZStack {
            VStack(spacing: 4) {
                ArcadeHeader(title: "Sort · \(game.score) pts · \(game.mistakes)/5 misses", tint: .orange, onPause: pause)
                Text(game.isShowingFeedback ? game.lastEvent : "Where does this service belong?")
                    .font(.system(size: 10, weight: .semibold, design: .rounded)).lineLimit(2).multilineTextAlignment(.center)
                SorterCard(game: game).frame(maxWidth: .infinity, maxHeight: .infinity).layoutPriority(-1)
                ArcadeIntegerCrown(value: $crownSelection, lower: 0, upper: ServiceCategory.allCases.count - 1, active: game.status == .playing,
                                   label: "Crown selects · tap a bin to send", fontSize: 9, focusRequest: crownFocusRequest)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 3), spacing: 4) {
                    ForEach(ServiceCategory.allCases) { category in
                        Button { dispatch(to: category) } label: {
                            Text(category.rawValue)
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .lineLimit(1).minimumScaleFactor(0.8)
                                .foregroundStyle(game.selectedCategory == category ? .black : category.tint)
                                .frame(maxWidth: .infinity).frame(height: 23)
                                .background(game.selectedCategory == category ? category.tint : category.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 7))
                                .overlay { RoundedRectangle(cornerRadius: 7).stroke(game.selectedCategory == category ? .white : .clear, lineWidth: 1.5) }
                        }.buttonStyle(.plain).disabled(game.isShowingFeedback)
                            .accessibilityLabel("Send to \(category.rawValue)")
                            .accessibilityAddTraits(game.selectedCategory == category ? .isSelected : [])
                    }
                }
            }.padding(.horizontal, 5).padding(.bottom, 5)
            if game.status == .paused { ArcadePauseOverlay(tint: .orange, onResume: resume, onQuit: onDone) }
        }
    }

    private var results: some View {
        ArcadeResultView(game: .sorter, score: game.score, best: best, summary: "\(game.dispatched) services dispatched · \(game.mistakes) mistakes", fact: game.lastFact, onReplay: start, onDone: onDone)
    }

    private func start() { crownSelection = 0; game.start(); lastTick = Date(); WKInterfaceDevice.current().play(.start) }
    private func pause() { guard game.status == .playing else { return }; game.status = .paused; lastTick = nil }
    private func resume() { guard game.status == .paused else { return }; game.status = .playing; lastTick = Date() }
    private func dispatch(to category: ServiceCategory) {
        guard game.status == .playing, !game.isShowingFeedback else { return }
        crownSelection = ServiceCategory.allCases.firstIndex(of: category) ?? 0
        game.dispatch(to: category)
        crownFocusRequest += 1; if game.status == .results { best = max(best, game.score); WKInterfaceDevice.current().play(.failure) } }
    private func tick(at date: Date) {
        guard game.status == .playing else { lastTick = nil; return }
        let delta = min(0.1, max(0, date.timeIntervalSince(lastTick ?? date))); lastTick = date; game.tick(delta)
        if game.status == .results { best = max(best, game.score); WKInterfaceDevice.current().play(.failure) }
    }
}

private struct SorterCard: View {
    let game: SorterState
    var body: some View {
        VStack(spacing: 2) {
            Text(game.current?.name ?? "Next service")
                .font(.system(size: 20, weight: .heavy, design: .rounded)).lineLimit(1).minimumScaleFactor(0.55)
            Text(game.isShowingFeedback ? "Next card…" : String(format: "Sends in %.1fs", max(0, game.timeRemaining)))
                .font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.orange.opacity(0.13), in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Scale Ops

private struct ScaleOpsView: View {
    let onDone: () -> Void
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("scaleOpsBest") private var best = 0
    @State private var game = ScaleOpsState()
    @State private var crownInstances = 2
    @State private var crownFocusRequest = 0
    @State private var lastTick: Date?
    @State private var lastHaptic = Date.distantPast

    var body: some View {
        VStack(spacing: 0) {
            switch game.status {
            case .intro: intro
            case .playing, .paused: playing
            case .results: results
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 6)
        .task(id: game.status) {
            guard game.status == .playing else { lastTick = nil; return }
            lastTick = Date()
            while !Task.isCancelled {
                do { try await Task.sleep(for: .milliseconds(33)) } catch { return }
                tick(at: Date())
            }
        }
        .onDisappear { lastTick = nil }
        .onChange(of: scenePhase) { _, phase in
            guard phase != .active, game.status == .playing else { return }
            game.status = .paused; lastTick = nil
        }
        .onChange(of: crownInstances) { _, value in game.requestCapacity(value) }
        .onChange(of: game.hapticPulse) { _, _ in
            let now = Date()
            guard now.timeIntervalSince(lastHaptic) >= 0.25 else { return }
            lastHaptic = now
            WKInterfaceDevice.current().play(.click)
        }
    }

    private var intro: some View {
        VStack(spacing: 7) {
            Text("SCALE OPS").font(.system(size: 17, weight: .heavy, design: .rounded)).foregroundStyle(.green)
            ScrollView {
                VStack(spacing: 8) {
                    Text("Run a flash sale.").font(.system(size: 15, weight: .bold, design: .rounded))
                    Text("Keep requests flowing without spending all your budget.")
                    Text("First, try adding and removing a server. Practice is untimed and costs nothing.").foregroundStyle(.secondary)
                }.font(.system(size: 12, design: .rounded)).multilineTextAlignment(.center)
                    .padding(.vertical, 6).padding(.horizontal, 4)
            }.defaultScrollAnchor(.top)
            Button(action: start) {
                Text("Learn the controls").font(.system(size: 13, weight: .bold))
                    .frame(maxWidth: .infinity).frame(height: 32)
                    .background(.green.opacity(0.25), in: Capsule())
            }.buttonStyle(.plain)
        }.padding(.horizontal, 7).padding(.top, 5).padding(.bottom, 8)
    }

    private var playing: some View {
        GeometryReader { available in
        let compact = available.size.height < 195
        ZStack {
            VStack(spacing: compact ? 2 : 3) {
                ArcadeHeader(title: game.isTutorial ? "Practice · no cost or timer" : "Flash sale · \(Int(ceil(game.timeRemaining)))s", tint: .green, onPause: pause)
                Text(game.isTutorial ? (game.tutorialStep == .addServer ? "1. Add a server for more traffic" : "2. Remove a server to save cost") :
                     (game.nextDemand.map { "Next traffic: \(Int($0))/s in \(Int(ceil(game.nextWaveIn)))s" } ?? "Final wave · save your budget"))
                    .font(.system(size: 10, weight: .bold, design: .rounded)).foregroundStyle(.yellow)
                    .lineLimit(1).minimumScaleFactor(0.75)
                Group {
                    if compact {
                        HStack(spacing: 5) {
                            compactMetric("Traffic needs", value: game.demand, tint: .orange)
                            compactMetric("Servers handle", value: game.capacity, tint: .green)
                        }
                    } else {
                        VStack(spacing: 4) {
                            ScaleCapacityMeter(title: "Traffic needs", value: game.demand, tint: .orange)
                            ScaleCapacityMeter(title: "Servers handle", value: game.capacity, tint: .green)
                        }
                    }
                }.frame(maxHeight: .infinity)
                ArcadeIntegerCrown(value: $crownInstances, lower: ScaleOpsState.instanceRange.lowerBound, upper: ScaleOpsState.instanceRange.upperBound,
                                  active: game.status == .playing && game.tutorialStep != .ready,
                                  label: "Crown: \(game.desiredInstances) servers", fontSize: compact ? 16 : 18, focusRequest: crownFocusRequest)
                serverStrip(compact: compact)
                Text(game.provisioningMessage).font(.system(size: compact ? 9 : 10, weight: .medium, design: .rounded))
                    .foregroundStyle(game.scalingRemaining > 0 ? .orange : .green).lineLimit(1).minimumScaleFactor(0.8)
                Text(game.guidance).font(.system(size: compact ? 10 : 11, weight: .bold, design: .rounded))
                    .foregroundStyle(game.desiredInstances > game.recommendedInstances ? .orange : .white)
                    .lineLimit(2).multilineTextAlignment(.center).minimumScaleFactor(0.85)
                if game.tutorialStep == .ready {
                    Button(action: beginRun) {
                        Text("Start the flash sale").font(.system(size: 12, weight: .bold))
                            .frame(maxWidth: .infinity).frame(height: 27)
                            .background(.green.opacity(0.25), in: Capsule())
                    }.buttonStyle(.plain)
                } else if !game.isTutorial {
                    HStack(spacing: 3) {
                        Text("Queue \(Int(ceil(game.queue)))/18").foregroundStyle(game.queue > 9 ? .pink : .white)
                        Spacer(minLength: 1)
                        Text("Budget \(Int(ceil(game.budget)))").foregroundStyle(game.budget < 20 ? .pink : .cyan)
                        Text("\(game.outages)/3!").foregroundStyle(.pink)
                    }.font(.system(size: 10, weight: .bold, design: .rounded)).lineLimit(1).minimumScaleFactor(0.8)
                }
            }.padding(.horizontal, 5).padding(.bottom, 5)
            if game.status == .paused { ArcadePauseOverlay(tint: .green, onResume: resume, onQuit: onDone) }
        }
        }
    }

    private func compactMetric(_ title: String, value: Double, tint: Color) -> some View {
        VStack(spacing: 1) {
            Text(title).font(.system(size: 9, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.85)
            Text("\(Int(value))/s").font(.system(size: 18, weight: .bold, design: .rounded)).monospacedDigit()
        }.foregroundStyle(tint).frame(maxWidth: .infinity)
            .padding(.vertical, 3).background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }

    private func serverStrip(compact: Bool) -> some View {
        GeometryReader { viewport in
            let chipWidth: CGFloat = 30
            ScrollViewReader { strip in
                ScrollView(.horizontal) {
                    HStack(spacing: 5) {
                        ForEach(ScaleOpsState.instanceRange, id: \.self) { count in
                            Button { chooseServers(count) } label: {
                                Text("\(count)").font(.system(size: 11, weight: .bold, design: .rounded)).monospacedDigit()
                                    .frame(width: chipWidth, height: compact ? 21 : 24)
                                    .foregroundStyle(count <= game.onlineInstances ? .black : .white)
                                    .background(serverColor(count), in: RoundedRectangle(cornerRadius: 5))
                                    .overlay { RoundedRectangle(cornerRadius: 5).stroke(count == game.desiredInstances ? .white : .clear, lineWidth: 1.5) }
                            }.buttonStyle(.plain).disabled(game.tutorialStep == .ready)
                                .accessibilityLabel("Choose \(count) servers")
                                .accessibilityAddTraits(count == game.desiredInstances ? .isSelected : [])
                                .id(count)
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 2)
                }
                .scrollIndicators(.hidden)
                // This strip follows the game control; it must not compete with
                // the visible Crown host for scrolling focus.
                .scrollDisabled(true)
                .onAppear { strip.scrollTo(game.desiredInstances, anchor: .center) }
                .onChange(of: game.desiredInstances) { _, selected in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        strip.scrollTo(selected, anchor: .center)
                    }
                }
                .onChange(of: viewport.size.width) { _, _ in
                    strip.scrollTo(game.desiredInstances, anchor: .center)
                }
            }
        }.frame(height: compact ? 25 : 28)
    }

    private func serverColor(_ count: Int) -> Color {
        if count > min(game.onlineInstances, game.desiredInstances), count <= max(game.onlineInstances, game.desiredInstances) { return .orange.opacity(0.8) }
        return count <= game.onlineInstances ? .green : .gray.opacity(0.22)
    }
    private func chooseServers(_ count: Int) {
        guard game.status == .playing, game.tutorialStep != .ready else { return }
        crownInstances = count
        game.requestCapacity(count)
        crownFocusRequest += 1
    }
    private func beginRun() {
        game.beginRun()
        crownInstances = game.desiredInstances
        crownFocusRequest += 1
        lastTick = Date()
    }

    private var results: some View {
        ArcadeResultView(game: .scaleOps, score: game.score, best: best,
                         summary: "\(game.endReason). \(Int(game.served)) served · \(Int(game.dropped)) dropped · \(Int(game.budget)) budget left",
                         fact: game.lesson, onReplay: start, onDone: onDone)
    }

    private func start() { game.start(guided: true); crownInstances = 2; lastTick = Date(); WKInterfaceDevice.current().play(.start) }
    private func pause() { guard game.status == .playing else { return }; game.status = .paused; lastTick = nil }
    private func resume() { guard game.status == .paused else { return }; game.status = .playing; lastTick = Date() }
    private func tick(at date: Date) {
        guard game.status == .playing else { lastTick = nil; return }
        let delta = min(0.1, max(0, date.timeIntervalSince(lastTick ?? date)))
        lastTick = date
        game.tick(delta)
        if game.status == .results {
            best = max(best, game.score)
            WKInterfaceDevice.current().play(game.completed ? .success : .failure)
        }
    }
}

private struct ScaleCapacityMeter: View {
    let title: String
    let value: Double
    let tint: Color
    var body: some View {
        VStack(spacing: 2) {
            HStack {
                Text(title)
                Spacer(minLength: 1)
                Text("\(Int(value))/s").monospacedDigit()
            }.font(.system(size: 12, weight: .bold, design: .rounded)).lineLimit(1).minimumScaleFactor(0.8)
            GeometryReader { available in
                ZStack(alignment: .leading) {
                    Capsule().fill(tint.opacity(0.15))
                    Capsule().fill(tint).frame(width: available.size.width * min(1, max(0, value / Double(ScaleOpsState.instanceRange.upperBound * 2))))
                }
            }.frame(height: 9)
        }.foregroundStyle(tint)
            .accessibilityElement(children: .combine)
    }
}

#Preview { NavigationStack { AWSArcadeView() } }

import SwiftUI
import WatchKit

// MARK: - Shared arcade content

private enum ArcadeGame: String, CaseIterable, Identifiable {
    case catcher, sorter, vault
    var id: String { rawValue }
    var title: String {
        switch self {
        case .catcher: return "Service Catcher"
        case .sorter: return "Service Sorter"
        case .vault: return "Cloud Vault"
        }
    }
    var subtitle: String {
        switch self {
        case .catcher: return "Catch the right services. Dodge the noise."
        case .sorter: return "Sort a live conveyor under pressure."
        case .vault: return "Crack a moving cloud lock by feel."
        }
    }
    var detail: String {
        switch self {
        case .catcher: return "Crown steers the collector"
        case .sorter: return "Crown picks the category"
        case .vault: return "Crown turns the safe dial"
        }
    }
    var symbol: String {
        switch self {
        case .catcher: return "arrow.down.to.line.compact"
        case .sorter: return "arrow.left.arrow.right"
        case .vault: return "dial.medium.fill"
        }
    }
    var tint: Color {
        switch self {
        case .catcher: return .cyan
        case .sorter: return .orange
        case .vault: return .purple
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
        VStack(spacing: 7) {
            Image(systemName: score > 0 ? "sparkles" : "arrow.counterclockwise.circle.fill").font(.system(size: 32, weight: .bold)).foregroundStyle(game.tint)
            Text(score > 0 ? "Run complete" : "Keep tuning").font(.system(.headline, design: .rounded, weight: .bold))
            Text("\(score) pts · best \(best)").font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundStyle(.secondary)
            Text(summary).font(.system(size: 11, weight: .medium, design: .rounded)).multilineTextAlignment(.center).lineLimit(3)
            Text(fact).font(.system(size: 10, design: .rounded)).foregroundStyle(.secondary).multilineTextAlignment(.center).lineLimit(4)
            HStack(spacing: 6) {
                Button("Replay", action: onReplay).tint(game.tint)
                Button("Arcade", action: onDone).tint(.secondary)
            }.buttonStyle(.borderedProminent)
        }.padding(.horizontal, 5)
    }
}

// MARK: - Arcade hub

struct AWSArcadeView: View {
    @State private var selectedGame: ArcadeGame?
    @State private var showingHowTo = false
    @AppStorage("serviceCatcherBest") private var catcherBest = 0
    @AppStorage("serviceSorterBest") private var sorterBest = 0
    @AppStorage("cloudVaultBest") private var vaultBest = 0

    var body: some View {
        Group {
            switch selectedGame {
            case .none: hub
            case .catcher: ServiceCatcherView(onDone: { selectedGame = nil })
            case .sorter: ServiceSorterView(onDone: { selectedGame = nil })
            case .vault: CloudVaultView(onDone: { selectedGame = nil })
            }
        }
        .navigationTitle(selectedGame?.title ?? "Arcade")
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
                Text("Three short skill games. Every catch, sort, and lock teaches a real AWS pattern.")
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
                Text("Rotate to the category that matches the conveyor card. Dispatch before the countdown expires—or let the deadline resolve it for you.")
                Text("Cloud Vault").font(.system(.headline, design: .rounded, weight: .bold)).foregroundStyle(.purple)
                Text("Turn the dial to find the warmest signal. Hold in the narrow zone or tap SET PIN. Crack three moving stages before time runs out.")
                Text("The lower buttons are touch fallbacks. Leaving the app pauses an active run; it never drains time or resumes by itself.").font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(.secondary)
            }.font(.system(size: 11, design: .rounded)).padding(14)
        }.navigationTitle("How to play")
    }

    private func best(for game: ArcadeGame) -> Int {
        switch game { case .catcher: return catcherBest; case .sorter: return sorterBest; case .vault: return vaultBest }
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
    @FocusState private var crownFocused: Bool

    var body: some View {
        Group {
            switch game.status {
            case .intro: intro
            case .playing, .paused: playing
            case .results: results
            }
        }
        .onAppear { crownFocused = true; lastTick = Date() }
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
        VStack(spacing: 8) {
            Image(systemName: ArcadeGame.catcher.symbol).font(.system(size: 34, weight: .bold)).foregroundStyle(.cyan)
            Text("SERVICE CATCHER").font(.system(.headline, design: .rounded, weight: .heavy))
            Text("Catch the glowing category. Dodge other services and red hazards as the cloud accelerates.")
                .font(.system(size: 11, design: .rounded)).multilineTextAlignment(.center).foregroundStyle(.secondary)
            Text("CROWN  steer   ·   TAP  nudge").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(.cyan)
            Button("Start run") { start() }.buttonStyle(.borderedProminent).tint(.cyan)
        }.padding(.horizontal, 8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Service Catcher. Catch the glowing category and dodge hazards. Turn the Digital Crown to steer.")
    }

    private var playing: some View {
        ZStack {
            VStack(spacing: 4) {
                ArcadeHeader(title: "Catcher", tint: .cyan, onPause: pause)
                HStack(spacing: 6) {
                    Label("\(game.lives)", systemImage: "heart.fill").foregroundStyle(.pink)
                    Spacer(); Text("CATCH \(game.targetCategory.rawValue.uppercased())").foregroundStyle(game.targetCategory.tint); Spacer(); Text("\(game.score)").foregroundStyle(.yellow)
                }.font(.system(size: 9, weight: .heavy, design: .monospaced))
                CatcherArena(game: game).frame(maxWidth: .infinity, minHeight: 135, maxHeight: 153)
                    .focusable(true).focused($crownFocused)
                    .digitalCrownRotation($crownX, from: 0.09, through: 0.91, by: 0.035, sensitivity: .high, isContinuous: false, isHapticFeedbackEnabled: true)
                    .accessibilityLabel("Falling service arena. Crown position \(Int(crownX * 100)) percent")
                HStack(spacing: 8) {
                    Button { game.nudge(-0.18); crownX = game.playerX } label: { Image(systemName: "chevron.left") }
                    Text(game.lastEvent.isEmpty ? "x\(game.combo) combo" : game.lastEvent).font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(game.lastEvent.contains("+") ? .green : .secondary).lineLimit(1).minimumScaleFactor(0.7)
                    Button { game.nudge(0.18); crownX = game.playerX } label: { Image(systemName: "chevron.right") }
                }.buttonStyle(.bordered).tint(.cyan)
                Text(game.lastFact).font(.system(size: 8, design: .rounded)).foregroundStyle(.secondary).lineLimit(2).multilineTextAlignment(.center)
            }.padding(.horizontal, 3)
            if game.status == .paused { ArcadePauseOverlay(tint: .cyan, onResume: resume, onQuit: onDone).padding(.top, 1) }
        }
        .onChange(of: game.status) { _, status in if status == .playing { crownFocused = true } }
        .modifier(CatcherTimeline(tick: tick))
    }

    private var results: some View {
        ArcadeResultView(game: .catcher, score: game.score, best: best, summary: "\(game.caught) target services caught · \(game.lives) hull left", fact: game.lastFact, onReplay: start, onDone: onDone)
    }

    private func start() { crownX = 0.5; game.start(); crownFocused = true; lastTick = Date(); WKInterfaceDevice.current().play(.start) }
    private func pause() { guard game.status == .playing else { return }; game.status = .paused; lastTick = nil }
    private func resume() { guard game.status == .paused else { return }; game.status = .playing; lastTick = Date(); crownFocused = true }
    private func tick(at date: Date) {
        guard game.status == .playing else { lastTick = nil; return }
        let delta = min(0.1, max(0, date.timeIntervalSince(lastTick ?? date))); lastTick = date; game.tick(delta)
        if game.status == .results { best = max(best, game.score); WKInterfaceDevice.current().play(.failure) }
    }
}

private struct CatcherTimeline: ViewModifier {
    let tick: (Date) -> Void
    func body(content: Content) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            content.onChange(of: context.date) { _, date in tick(date) }
        }
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
    @State private var lastTick: Date?
    @State private var lastHaptic = Date.distantPast
    @FocusState private var crownFocused: Bool

    var body: some View {
        Group {
            switch game.status {
            case .intro: intro
            case .playing, .paused: playing
            case .results: results
            }
        }
        .onAppear { crownFocused = true; lastTick = Date() }
        .onChange(of: scenePhase) { _, phase in
            guard phase != .active, game.status == .playing else { return }
            game.status = .paused; lastTick = nil
        }
        .onChange(of: game.hapticPulse) { _, _ in
            let now = Date()
            guard now.timeIntervalSince(lastHaptic) >= 0.25 else { return }
            lastHaptic = now
            WKInterfaceDevice.current().play(.click)
        }
    }

    private var intro: some View {
        VStack(spacing: 8) {
            Image(systemName: ArcadeGame.sorter.symbol).font(.system(size: 34, weight: .bold)).foregroundStyle(.orange)
            Text("SERVICE SORTER").font(.system(.headline, design: .rounded, weight: .heavy))
            Text("A service arrives on the conveyor. Rotate to its category, then dispatch—or let the deadline decide.")
                .font(.system(size: 11, design: .rounded)).multilineTextAlignment(.center).foregroundStyle(.secondary)
            Text("CROWN  choose category   ·   TAP  dispatch").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(.orange)
            Button("Start sort") { start() }.buttonStyle(.borderedProminent).tint(.orange)
        }.padding(.horizontal, 8).accessibilityLabel("Service Sorter. Turn the Crown to choose the category, then dispatch each arriving service.")
    }

    private var playing: some View {
        ZStack {
            VStack(spacing: 5) {
                ArcadeHeader(title: "Sorter", tint: .orange, onPause: pause)
                HStack {
                    Label("\(game.mistakes)/5", systemImage: "xmark.circle.fill").foregroundStyle(.pink)
                    Spacer(); Text("ROUND \(game.round)").foregroundStyle(.secondary); Spacer(); Text("\(game.score)").foregroundStyle(.yellow)
                }.font(.system(size: 9, weight: .heavy, design: .monospaced))
                SorterCard(game: game).frame(maxWidth: .infinity, minHeight: 65, maxHeight: 74)
                HStack(spacing: 5) {
                    Image(systemName: game.selectedCategory.symbol).foregroundStyle(game.selectedCategory.tint)
                    Text(game.selectedCategory.rawValue.uppercased()).font(.system(size: 12, weight: .heavy, design: .rounded)).foregroundStyle(game.selectedCategory.tint)
                    Spacer(); Text(String(format: "%.1f", max(0, game.timeRemaining))).font(.system(size: 14, weight: .heavy, design: .monospaced)).foregroundStyle(game.timeRemaining < 0.6 ? .pink : .white)
                }
                .padding(.horizontal, 8).padding(.vertical, 5).background(game.selectedCategory.tint.opacity(0.13), in: Capsule())
                .focusable(true).focused($crownFocused)
                .digitalCrownRotation($game.crownIndex, from: 0, through: Double(ServiceCategory.allCases.count - 1), by: 1, sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: true)
                HStack(spacing: 7) {
                    Button { game.nudgeCategory(-1) } label: { Image(systemName: "chevron.left") }.accessibilityLabel("Previous category")
                    Button("Dispatch") { dispatch() }.tint(.orange).accessibilityLabel("Dispatch service into selected category")
                    Button { game.nudgeCategory(1) } label: { Image(systemName: "chevron.right") }.accessibilityLabel("Next category")
                }.buttonStyle(.borderedProminent)
                Text(game.lastEvent.isEmpty ? "x\(game.combo) combo" : game.lastEvent).font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(game.lastEvent.contains("+") ? .green : .secondary)
                Text(game.lastFact).font(.system(size: 8, design: .rounded)).foregroundStyle(.secondary).lineLimit(2).multilineTextAlignment(.center)
            }.padding(.horizontal, 3)
            if game.status == .paused { ArcadePauseOverlay(tint: .orange, onResume: resume, onQuit: onDone).padding(.top, 1) }
        }.modifier(SorterTimeline(tick: tick))
    }

    private var results: some View {
        ArcadeResultView(game: .sorter, score: game.score, best: best, summary: "\(game.dispatched) services dispatched · \(game.mistakes) mistakes", fact: game.lastFact, onReplay: start, onDone: onDone)
    }

    private func start() { game.start(); crownFocused = true; lastTick = Date(); WKInterfaceDevice.current().play(.start) }
    private func pause() { guard game.status == .playing else { return }; game.status = .paused; lastTick = nil }
    private func resume() { guard game.status == .paused else { return }; game.status = .playing; lastTick = Date(); crownFocused = true }
    private func dispatch() { game.resolve(); if game.status == .results { best = max(best, game.score); WKInterfaceDevice.current().play(.failure) } }
    private func tick(at date: Date) {
        guard game.status == .playing else { lastTick = nil; return }
        let delta = min(0.1, max(0, date.timeIntervalSince(lastTick ?? date))); lastTick = date; game.tick(delta)
        if game.status == .results { best = max(best, game.score); WKInterfaceDevice.current().play(.failure) }
    }
}

private struct SorterTimeline: ViewModifier {
    let tick: (Date) -> Void
    func body(content: Content) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { context in
            content.onChange(of: context.date) { _, date in tick(date) }
        }
    }
}

private struct SorterCard: View {
    let game: SorterState
    var body: some View {
        ZStack {
            HStack(spacing: 13) {
                ForEach(0..<5, id: \.self) { _ in Capsule().fill(.orange.opacity(0.18)).frame(width: 20, height: 2) }
            }.offset(x: CGFloat(game.cardTravel * 26 - 13))
            RoundedRectangle(cornerRadius: 13, style: .continuous).fill(.orange.opacity(0.13))
            RoundedRectangle(cornerRadius: 13, style: .continuous).stroke(.orange.opacity(0.4), lineWidth: 1)
            HStack(spacing: 10) {
                Image(systemName: game.current?.category.symbol ?? "shippingbox.fill").font(.system(size: 22, weight: .bold)).foregroundStyle(game.current?.category.tint ?? .orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text(game.current?.name ?? "NEXT SERVICE").font(.system(.headline, design: .rounded, weight: .heavy))
                    Text("CONVEYOR CARD").font(.system(size: 8, weight: .bold, design: .monospaced)).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0); Image(systemName: "arrow.right.circle.fill").foregroundStyle(.orange)
            }.padding(.horizontal, 12)
        }
        .accessibilityElement(children: .combine).accessibilityLabel("Incoming service \(game.current?.name ?? "unknown")")
    }
}

// MARK: - Cloud Vault

private struct CloudVaultView: View {
    let onDone: () -> Void
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("cloudVaultBest") private var best = 0
    @State private var game = VaultState()
    @State private var lastTick: Date?
    @State private var lastHaptic = Date.distantPast
    @FocusState private var crownFocused: Bool

    var body: some View {
        Group {
            switch game.status {
            case .intro: intro
            case .playing, .paused: playing
            case .results: results
            }
        }
        .onAppear { crownFocused = true; lastTick = Date() }
        .onChange(of: scenePhase) { _, phase in
            guard phase != .active, game.status == .playing else { return }
            game.status = .paused; lastTick = nil
        }
        .onChange(of: game.hapticPulse) { _, _ in
            let now = Date()
            guard now.timeIntervalSince(lastHaptic) >= 0.25 else { return }
            lastHaptic = now
            WKInterfaceDevice.current().play(.click)
        }
    }

    private var intro: some View {
        VStack(spacing: 8) {
            Image(systemName: ArcadeGame.vault.symbol).font(.system(size: 34, weight: .bold)).foregroundStyle(.purple)
            Text("CLOUD VAULT").font(.system(.headline, design: .rounded, weight: .heavy))
            Text("Turn the physical dial until the signal warms. Hold the narrow zone or tap SET PIN to crack three moving locks.")
                .font(.system(size: 11, design: .rounded)).multilineTextAlignment(.center).foregroundStyle(.secondary)
            Text("CROWN  turn   ·   TAP  set pin").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(.purple)
            Button("Crack vault") { start() }.buttonStyle(.borderedProminent).tint(.purple)
        }.padding(.horizontal, 8).accessibilityLabel("Cloud Vault. Turn the Crown to find the warm signal, then hold or tap Set Pin to crack three locks.")
    }

    private var playing: some View {
        ZStack {
            VStack(spacing: 4) {
                ArcadeHeader(title: "Vault", tint: .purple, onPause: pause)
                HStack { Text("LOCK \(game.stage)/3").foregroundStyle(.purple); Spacer(); Text(String(format: "%02d", max(0, Int(game.timeRemaining)))).foregroundStyle(game.timeRemaining < 7 ? .pink : .white); Spacer(); Text("\(game.score)").foregroundStyle(.yellow) }
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                VaultDial(game: game).frame(maxWidth: .infinity, minHeight: 139, maxHeight: 154)
                    .focusable(true).focused($crownFocused)
                    .digitalCrownRotation($game.dial, from: 0, through: 359, by: 2, sensitivity: .high, isContinuous: true, isHapticFeedbackEnabled: true)
                    .accessibilityLabel("Vault dial. Signal warmth \(Int(game.warmth * 100)) percent. Hold when aligned.")
                HStack(spacing: 7) {
                    Button { game.nudge(-14) } label: { Image(systemName: "chevron.left") }.accessibilityLabel("Turn dial left")
                    Button("SET PIN") { pin() }.tint(.purple).accessibilityLabel("Set pin at current dial position")
                    Button { game.nudge(14) } label: { Image(systemName: "chevron.right") }.accessibilityLabel("Turn dial right")
                }.buttonStyle(.borderedProminent)
                Text(game.lastEvent).font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(game.lastEvent.contains("OPEN") ? .green : .secondary).lineLimit(1)
                Text(game.lastFact).font(.system(size: 8, design: .rounded)).foregroundStyle(.secondary).lineLimit(2).multilineTextAlignment(.center)
            }.padding(.horizontal, 3)
            if game.status == .paused { ArcadePauseOverlay(tint: .purple, onResume: resume, onQuit: onDone).padding(.top, 1) }
        }.modifier(VaultTimeline(tick: tick))
    }

    private var results: some View {
        ArcadeResultView(game: .vault, score: game.score, best: best, summary: game.completed ? "All three locks opened" : "Reached lock \(game.stage) with \(game.score) points", fact: game.lastFact, onReplay: start, onDone: onDone)
    }

    private func start() { game.start(); crownFocused = true; lastTick = Date(); WKInterfaceDevice.current().play(.start) }
    private func pause() { guard game.status == .playing else { return }; game.status = .paused; lastTick = nil }
    private func resume() { guard game.status == .paused else { return }; game.status = .playing; lastTick = Date(); crownFocused = true }
    private func pin() { game.setPin(); if game.status == .results { best = max(best, game.score); WKInterfaceDevice.current().play(.success) } }
    private func tick(at date: Date) {
        guard game.status == .playing else { lastTick = nil; return }
        let delta = min(0.1, max(0, date.timeIntervalSince(lastTick ?? date))); lastTick = date; game.tick(delta)
        if game.status == .results { best = max(best, game.score); WKInterfaceDevice.current().play(.success) }
    }
}

private struct VaultTimeline: ViewModifier {
    let tick: (Date) -> Void
    func body(content: Content) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { context in
            content.onChange(of: context.date) { _, date in tick(date) }
        }
    }
}

private struct VaultDial: View {
    let game: VaultState
    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            ZStack {
                Circle().fill(Color.black.opacity(0.34))
                Circle().stroke(.purple.opacity(0.25), lineWidth: 12)
                Circle().trim(from: 0, to: CGFloat(game.warmth)).stroke(Color(red: 0.45 + game.warmth * 0.45, green: 0.15 + game.warmth * 0.6, blue: 0.95), style: StrokeStyle(lineWidth: 9, lineCap: .round)).rotationEffect(.degrees(-90))
                ForEach(0..<12, id: \.self) { index in
                    Capsule().fill(.white.opacity(index % 3 == 0 ? 0.7 : 0.25)).frame(width: 2, height: index % 3 == 0 ? 10 : 5).offset(y: -size * 0.39).rotationEffect(.degrees(Double(index) * 30))
                }
                Capsule().fill(game.warmth > 0.78 ? .yellow : .white).frame(width: 4, height: size * 0.27).offset(y: -size * 0.18).rotationEffect(.degrees(game.dial))
                Circle().fill(game.warmth > 0.82 ? .yellow : .purple).frame(width: 28, height: 28).overlay(Image(systemName: game.isAligned ? "lock.open.fill" : "lock.fill").font(.system(size: 12, weight: .bold)).foregroundStyle(.black))
                VStack(spacing: 0) { Text("SIGNAL").font(.system(size: 7, weight: .bold, design: .monospaced)); Text("\(Int(game.warmth * 100))%").font(.system(size: 11, weight: .heavy, design: .monospaced)) }.foregroundStyle(.white.opacity(0.85)).offset(y: size * 0.29)
            }.frame(maxWidth: .infinity, maxHeight: .infinity).contentShape(Circle()).accessibilityElement(children: .combine).accessibilityLabel("Dial signal \(Int(game.warmth * 100)) percent warm")
        }
    }
}

#Preview { NavigationStack { AWSArcadeView() } }

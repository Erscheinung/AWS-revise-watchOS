import Foundation

// Pure, watch-independent game rules. The SwiftUI file only renders these states and
// routes Crown/touch events, which keeps the timing and collision rules testable.

enum ServiceCategory: String, CaseIterable, Identifiable {
    case compute = "Compute"
    case storage = "Storage"
    case network = "Network"
    case security = "Security"
    case data = "Data"

    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .compute: return "cpu"
        case .storage: return "externaldrive.fill"
        case .network: return "point.3.connected.trianglepath.dotted"
        case .security: return "lock.shield.fill"
        case .data: return "chart.bar.xaxis"
        }
    }
}

struct ArcadeService: Identifiable {
    let name: String
    let category: ServiceCategory
    let fact: String
    var id: String { name }
}

enum ArcadeCatalog {
    static let services: [ArcadeService] = [
        .init(name: "EC2", category: .compute, fact: "EC2 provides resizable virtual servers; choose an instance size for the workload."),
        .init(name: "Lambda", category: .compute, fact: "Lambda runs code without managing servers and scales with events."),
        .init(name: "ECS", category: .compute, fact: "ECS orchestrates containers; Fargate removes the need to manage EC2 hosts."),
        .init(name: "S3", category: .storage, fact: "S3 stores objects durably; buckets are the container for objects and their keys."),
        .init(name: "EBS", category: .storage, fact: "EBS is block storage attached to an EC2 instance, with snapshots for backup."),
        .init(name: "EFS", category: .storage, fact: "EFS is a managed NFS file system that can be shared across Availability Zones."),
        .init(name: "VPC", category: .network, fact: "A VPC is an isolated network; subnets and route tables shape its traffic paths."),
        .init(name: "CloudFront", category: .network, fact: "CloudFront caches content at edge locations close to viewers worldwide."),
        .init(name: "Route 53", category: .network, fact: "Route 53 provides DNS and health-aware routing for application endpoints."),
        .init(name: "IAM", category: .security, fact: "IAM roles provide temporary credentials and avoid putting long-lived keys in code."),
        .init(name: "KMS", category: .security, fact: "KMS manages encryption keys; envelope encryption protects large payloads efficiently."),
        .init(name: "WAF", category: .security, fact: "AWS WAF filters HTTP(S) requests with rules in a web access control list."),
        .init(name: "DynamoDB", category: .data, fact: "DynamoDB is a serverless key-value and document database built for predictable scale."),
        .init(name: "RDS", category: .data, fact: "RDS Multi-AZ keeps a standby for failover; a read replica is for read scaling."),
        .init(name: "Redshift", category: .data, fact: "Redshift is a managed analytical warehouse designed for SQL over large datasets."),
        .init(name: "SQS", category: .data, fact: "SQS decouples producers and consumers by buffering work in a queue."),
        .init(name: "SNS", category: .data, fact: "SNS fans one published message out to many subscribed endpoints."),
        .init(name: "Step Functions", category: .data, fact: "Step Functions coordinates multi-step workflows with retries and branches.")
    ]

    static func service(for category: ServiceCategory? = nil) -> ArcadeService {
        let pool = category.map { wanted in services.filter { $0.category == wanted } } ?? services
        return pool.randomElement() ?? services[0]
    }
}

enum ArcadeStatus { case intro, playing, paused, results }

enum CatcherItemKind { case target, wrong, hazard }

struct CatcherItem: Identifiable {
    let id = UUID()
    let service: ArcadeService?
    let kind: CatcherItemKind
    let x: Double
    var y: Double
}

struct CatcherState {
    var status = ArcadeStatus.intro
    var playerX = 0.5
    var items: [CatcherItem] = []
    var elapsed: TimeInterval = 0
    var spawnClock: TimeInterval = 0.2
    var score = 0
    var lives = 3
    var combo = 0
    var caught = 0
    var targetCategory: ServiceCategory = .storage
    var lastFact = "Catch a target to reveal its architecture pattern."
    var lastEvent = ""
    var hapticPulse = 0

    mutating func start() {
        status = .playing; playerX = 0.5; items = []; elapsed = 0; spawnClock = 0.25; score = 0; lives = 3; combo = 0; caught = 0
        targetCategory = ServiceCategory.allCases.randomElement() ?? .storage
        lastFact = "Catch a target to reveal its architecture pattern."; lastEvent = ""; hapticPulse = 0
    }

    mutating func tick(_ delta: TimeInterval) {
        guard status == .playing else { return }
        let delta = min(0.1, max(0, delta))
        elapsed += delta
        let speed = min(0.62, 0.25 + elapsed * 0.012)
        let interval = max(0.34, 0.92 - elapsed * 0.009)
        spawnClock -= delta
        if spawnClock <= 0 {
            spawnClock += interval
            let roll = Int.random(in: 0..<10)
            let kind: CatcherItemKind = roll == 0 ? .hazard : (roll < 4 ? .wrong : .target)
            let service = kind == .hazard ? nil : ArcadeCatalog.service(for: kind == .target ? targetCategory : nil)
            items.append(CatcherItem(service: service, kind: kind, x: Double.random(in: 0.08...0.92), y: 0.02))
        }
        for index in items.indices { items[index].y += speed * delta }
        var remaining: [CatcherItem] = []
        for item in items {
            let inCollector = item.y > 0.77 && item.y < 0.92 && abs(item.x - playerX) < 0.17
            if inCollector {
                if item.kind == .target && item.service?.category == targetCategory { catchTarget(item) }
                else if item.kind == .hazard { loseLife("Hazard hit") }
                else { loseLife("Wrong service") }
            } else if item.y > 1.04 {
                if item.kind == .target { loseLife("Target missed") }
            } else { remaining.append(item) }
        }
        items = remaining
        if lives <= 0 { status = .results }
    }

    mutating private func catchTarget(_ item: CatcherItem) {
        guard let service = item.service else { return }
        caught += 1; combo += 1; score += 10 + min(20, combo * 2)
        lastFact = "\(service.name): \(service.fact)"; lastEvent = "+\(10 + min(20, combo * 2))  \(service.name)"; hapticPulse += 1
        if caught % 4 == 0 { targetCategory = ServiceCategory.allCases.randomElement() ?? targetCategory }
    }

    mutating private func loseLife(_ event: String) { lives -= 1; combo = 0; lastEvent = event; hapticPulse += 1 }
    mutating func nudge(_ amount: Double) { guard status == .playing else { return }; playerX = min(0.91, max(0.09, playerX + amount)) }
}

struct SorterState {
    var status = ArcadeStatus.intro
    var crownIndex: Double = 0
    var current: ArcadeService?
    var timeRemaining: TimeInterval = 1.8
    var feedbackRemaining: TimeInterval = 0
    var isShowingFeedback: Bool { feedbackRemaining > 0 }
    var cardTravel: Double = 0
    var elapsed: TimeInterval = 0
    var round = 0
    var score = 0
    var mistakes = 0
    var combo = 0
    var dispatched = 0
    var lastFact = "Dispatch a card to reveal the pattern."
    var lastEvent = ""
    var hapticPulse = 0

    var selectedCategory: ServiceCategory { ServiceCategory.allCases[min(ServiceCategory.allCases.count - 1, max(0, Int(crownIndex.rounded())))] }
    mutating func start() {
        status = .playing; crownIndex = 0; current = nil; feedbackRemaining = 0; timeRemaining = 5; cardTravel = 0; elapsed = 0; round = 0; score = 0; mistakes = 0; combo = 0; dispatched = 0
        lastFact = "Dispatch a card to reveal the pattern."; lastEvent = ""; hapticPulse = 0; deal()
    }
    mutating private func deal() { current = ArcadeCatalog.service(); round += 1; cardTravel = 0; timeRemaining = max(3, 6 - Double(round - 1) * 0.12) }
    mutating func tick(_ delta: TimeInterval) {
        guard status == .playing else { return }
        let delta = min(0.1, max(0, delta))
        if isShowingFeedback {
            feedbackRemaining = max(0, feedbackRemaining - delta)
            if feedbackRemaining == 0 { deal() }
            return
        }
        elapsed += delta; timeRemaining -= delta; cardTravel = min(1, cardTravel + delta / max(0.82, timeRemaining + delta))
        if timeRemaining <= 0 { resolve() }
    }
    mutating func resolve() {
        guard status == .playing, !isShowingFeedback, let current else { return }
        dispatched += 1
        if current.category == selectedCategory {
            combo += 1; score += 12 + min(18, combo * 3); lastEvent = "Correct · \(current.category.rawValue)"; lastFact = "\(current.name): \(current.fact)"; hapticPulse += 1
        } else {
            mistakes += 1; combo = 0; score = max(0, score - 4); lastEvent = "Answer: \(current.category.rawValue)"; lastFact = "\(current.name) belongs to \(current.category.rawValue): \(current.fact)"; hapticPulse += 1
        }
        if mistakes >= 5 { status = .results } else { feedbackRemaining = 1.25 }
    }
    mutating func selectCategory(at index: Int) {
        guard status == .playing else { return }
        crownIndex = Double(min(ServiceCategory.allCases.count - 1, max(0, index)))
    }
    mutating func dispatch(to category: ServiceCategory) {
        guard status == .playing, !isShowingFeedback,
              let index = ServiceCategory.allCases.firstIndex(of: category) else { return }
        crownIndex = Double(index)
        resolve()
    }
    mutating func nudgeCategory(_ amount: Int) { guard status == .playing else { return }; let count = ServiceCategory.allCases.count; crownIndex = Double((Int(crownIndex.rounded()) + amount + count) % count) }
}

// Native Crown acceleration can skip several detents in one callback. Keep its
// raw cumulative position separate from the visible selection. No event can
// move more than one item, and fast same-direction events are rate-limited.
struct CrownStepReducer {
    let lower: Int
    let upper: Int
    private(set) var position: Int
    private(set) var lastRaw = 0
    private var lastStepTime = -Double.infinity
    private var lastDirection = 0

    init(position: Int, lower: Int, upper: Int) {
        self.lower = lower
        self.upper = upper
        self.position = min(upper, max(lower, position))
    }

    mutating func select(_ value: Int) {
        position = min(upper, max(lower, value))
        // Touch selection must not recenter or write back to the native Crown.
    }

    mutating func consume(raw: Int, at time: TimeInterval, enabled: Bool = true) -> Int? {
        let delta = raw - lastRaw
        lastRaw = raw
        guard enabled, delta != 0 else { return nil }
        let direction = delta > 0 ? 1 : -1
        let cadence = direction == lastDirection ? 0.16 : 0.08
        guard time - lastStepTime >= cadence else { return nil }
        let next = min(upper, max(lower, position + direction))
        guard next != position else { return nil }
        position = next
        lastStepTime = time
        lastDirection = direction
        return next
    }
}

enum ScaleTutorialStep { case addServer, removeServer, ready, complete }

// A deliberately compressed capacity-planning simulation, not AWS pricing or
// provisioning-time estimates. Each instance serves two game requests/second.
struct ScaleOpsState {
    static let duration: TimeInterval = 42
    static let scaleDelay: TimeInterval = 2
    static let queueLimit: Double = 18
    static let traffic: [Double] = [3, 6, 11, 5, 14, 8, 3]

    var status = ArcadeStatus.intro
    var elapsed: TimeInterval = 0
    var tutorialStep = ScaleTutorialStep.complete
    var isTutorial: Bool { tutorialStep != .complete }
    var desiredInstances = 2
    var onlineInstances = 2
    var scalingRemaining: TimeInterval = 0
    var queue: Double = 0
    var budget: Double = 100
    var served: Double = 0
    var dropped: Double = 0
    var outages = 0
    var hapticPulse = 0
    var completed = false
    var endReason = ""

    var wave: Int { min(Self.traffic.count - 1, Int(elapsed / 6)) }
    var demand: Double {
        switch tutorialStep {
        case .addServer: return 6
        case .removeServer, .ready: return 4
        case .complete: return Self.traffic[wave]
        }
    }
    var capacity: Double { Double(onlineInstances * 2) }
    var timeRemaining: TimeInterval { max(0, Self.duration - elapsed) }
    var nextDemand: Double? { !isTutorial && wave + 1 < Self.traffic.count ? Self.traffic[wave + 1] : nil }
    var nextWaveIn: TimeInterval { max(0, Double(wave + 1) * 6 - elapsed) }
    var score: Int { max(0, Int(served) + Int(budget) - Int(dropped) * 2) }
    var recommendedInstances: Int {
        let anticipated = nextWaveIn <= 2.5 ? max(demand, nextDemand ?? demand) : demand
        return min(8, Int(ceil((anticipated + (queue > 1 ? 2 : 0)) / 2)))
    }
    var guidance: String {
        switch tutorialStep {
        case .addServer: return desiredInstances == 3 ? "Wait: the third server is starting" : "Turn Crown: choose 3 servers"
        case .removeServer: return desiredInstances == 2 ? "Wait: removing the spare server" : "Traffic fell! Turn down to 2"
        case .ready: return "You matched traffic and saved cost"
        case .complete:
            if desiredInstances < recommendedInstances {
                return queue > 1 ? "Queue growing: turn UP" : "More traffic coming: turn UP"
            }
            if desiredInstances > recommendedInstances { return "Too many servers: turn DOWN" }
            if scalingRemaining > 0 { return "Capacity changing: watch the queue" }
            return "Matched: ready for the next wave"
        }
    }
    var provisioningMessage: String {
        if scalingRemaining > 0 { return "\(onlineInstances) online · change in \(String(format: "%.1f", scalingRemaining))s" }
        return "\(onlineInstances) online × 2 = \(Int(capacity)) requests/s"
    }
    var lesson: String {
        "EC2 Auto Scaling capacity takes time to become ready. Scale ahead of demand, then scale in to save cost. Points reward served requests and budget left. Timing and costs here are game units."
    }

    mutating func start(guided: Bool = false) {
        self = ScaleOpsState()
        status = .playing
        tutorialStep = guided ? .addServer : .complete
    }

    mutating func beginRun() {
        guard status == .playing, tutorialStep == .ready else { return }
        start()
    }

    mutating func requestCapacity(_ count: Int) {
        guard status == .playing, tutorialStep != .ready else { return }
        let count = min(8, max(1, count))
        guard count != desiredInstances else { return }
        desiredInstances = count
        scalingRemaining = count == onlineInstances ? 0 : Self.scaleDelay
    }

    mutating func tick(_ delta: TimeInterval) {
        guard status == .playing else { return }
        let delta = min(0.1, max(0, delta), timeRemaining)
        if scalingRemaining > 0 {
            scalingRemaining = max(0, scalingRemaining - delta)
            if scalingRemaining < 0.000001 {
                scalingRemaining = 0
                onlineInstances = desiredInstances
                hapticPulse += 1
            }
        }
        if isTutorial {
            // Practice never spends budget, adds backlog, or consumes run time.
            if tutorialStep == .addServer, onlineInstances == 3, scalingRemaining == 0 {
                tutorialStep = .removeServer
                hapticPulse += 1
            } else if tutorialStep == .removeServer, onlineInstances == 2, scalingRemaining == 0 {
                tutorialStep = .ready
                hapticPulse += 1
            }
            return
        }
        let waiting = queue + demand * delta
        let processed = min(waiting, capacity * delta)
        served += processed
        queue = max(0, waiting - processed)
        budget = max(0, budget - Double(onlineInstances) * 0.45 * delta)
        if queue >= Self.queueLimit {
            // A full queue sheds work, creating one visible service outage.
            let discarded = queue - Self.queueLimit / 2
            dropped += discarded
            queue -= discarded
            outages += 1
            hapticPulse += 1
        }
        elapsed = min(Self.duration, elapsed + delta)
        if outages >= 3 { endReason = "Three queue overflows"; status = .results }
        else if budget <= 0 { endReason = "Budget exhausted"; status = .results }
        else if timeRemaining < 0.000001 {
            elapsed = Self.duration
            completed = true
            endReason = "Traffic shift handled"
            status = .results
        }
    }
}

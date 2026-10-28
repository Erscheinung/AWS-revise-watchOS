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
        status = .playing; crownIndex = 0; current = nil; timeRemaining = 1.8; cardTravel = 0; elapsed = 0; round = 0; score = 0; mistakes = 0; combo = 0; dispatched = 0
        lastFact = "Dispatch a card to reveal the pattern."; lastEvent = ""; hapticPulse = 0; deal()
    }
    mutating private func deal() { current = ArcadeCatalog.service(); round += 1; cardTravel = 0; timeRemaining = max(0.82, 1.9 - elapsed * 0.012) }
    mutating func tick(_ delta: TimeInterval) {
        guard status == .playing else { return }
        let delta = min(0.1, max(0, delta))
        elapsed += delta; timeRemaining -= delta; cardTravel = min(1, cardTravel + delta / max(0.82, timeRemaining + delta))
        if timeRemaining <= 0 { resolve() }
    }
    mutating func resolve() {
        guard status == .playing, let current else { return }
        dispatched += 1
        if current.category == selectedCategory {
            combo += 1; score += 12 + min(18, combo * 3); lastEvent = "+\(12 + min(18, combo * 3))  MATCH"; lastFact = "\(current.name): \(current.fact)"; hapticPulse += 1
        } else {
            mistakes += 1; combo = 0; score = max(0, score - 4); lastEvent = "MISS  \(current.category.rawValue.uppercased())"; lastFact = "\(current.name) belongs to \(current.category.rawValue): \(current.fact)"; hapticPulse += 1
        }
        if mistakes >= 5 { status = .results } else { deal() }
    }
    mutating func nudgeCategory(_ amount: Int) { guard status == .playing else { return }; let count = ServiceCategory.allCases.count; crownIndex = Double((Int(crownIndex.rounded()) + amount + count) % count) }
}

struct VaultState {
    var status = ArcadeStatus.intro
    var dial: Double = 0
    var target: Double = 140
    var targetWidth: Double = 42
    var stage = 1
    var timeRemaining: TimeInterval = 24
    var elapsed: TimeInterval = 0
    var score = 0
    var completed = false
    var combo = 0
    var holdProgress: TimeInterval = 0
    var lastFact = "The lock responds to proximity, not a memorized answer."
    var lastEvent = "Find the warm signal"
    var hapticPulse = 0
    var didPulseWarm = false

    var distance: Double {
        let raw = abs(dial - target).truncatingRemainder(dividingBy: 360)
        return min(raw, 360 - raw)
    }
    var warmth: Double { max(0, 1 - distance / 150) }
    var isAligned: Bool { distance <= targetWidth / 2 }

    mutating func start() {
        status = .playing; dial = 0; target = Double.random(in: 0..<360); targetWidth = 44; stage = 1; timeRemaining = 24; elapsed = 0; score = 0; completed = false; combo = 0; holdProgress = 0
        lastFact = "The lock responds to proximity, not a memorized answer."; lastEvent = "Find the warm signal"; hapticPulse = 0; didPulseWarm = false
    }
    mutating func tick(_ delta: TimeInterval) {
        guard status == .playing else { return }
        let delta = min(0.1, max(0, delta))
        elapsed += delta; timeRemaining -= delta
        target = (target + sin(elapsed * (1.0 + Double(stage) * 0.26)) * delta * (8 + Double(stage) * 2)).truncatingRemainder(dividingBy: 360)
        if isAligned { holdProgress += delta } else { holdProgress = max(0, holdProgress - delta * 1.8) }
        if warmth > 0.82 && !didPulseWarm { hapticPulse += 1; didPulseWarm = true }
        if warmth < 0.68 { didPulseWarm = false }
        if holdProgress >= 0.58 { unlockStage() }
        if timeRemaining <= 0 { status = .results }
    }
    mutating func setPin() {
        guard status == .playing else { return }
        if isAligned { unlockStage() } else { timeRemaining = max(0, timeRemaining - 2.2); combo = 0; lastEvent = "PIN REJECTED  keep searching"; hapticPulse += 1 }
    }
    mutating private func unlockStage() {
        score += 30 + stage * 12 + combo * 4; combo += 1; lastEvent = "STAGE \(stage) OPEN  +\(30 + stage * 12 + (combo - 1) * 4)"
        lastFact = stage == 1 ? "IAM roles keep credentials temporary and out of your app." : (stage == 2 ? "KMS protects data keys with a managed encryption key." : "Defense in depth combines identity, encryption, and network boundaries.")
        hapticPulse += 1; holdProgress = 0; didPulseWarm = false
        if stage >= 3 { completed = true; status = .results } else { stage += 1; targetWidth = max(17, targetWidth - 11); timeRemaining += 5; target = Double.random(in: 0..<360) }
    }
    mutating func rotate(_ value: Double) { guard status == .playing else { return }; dial = value.truncatingRemainder(dividingBy: 360) }
    mutating func nudge(_ amount: Double) { rotate((dial + amount).truncatingRemainder(dividingBy: 360)) }
}

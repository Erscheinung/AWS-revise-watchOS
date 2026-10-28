import Foundation

// Run from the repository root:
// swiftc "AWS Revise Watch App/AWSArcadeLogic.swift" ArcadeLogicHarness.swift -o /tmp/aws-arcade-logic && /tmp/aws-arcade-logic

@inline(__always) func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
struct ArcadeLogicHarness {
    static func main() {

// Catcher: a target in the collector scores; a wrong service costs a life; three
// misses end the run. A large frame delta is clamped inside the production model.
var catcher = CatcherState()
catcher.status = .playing
catcher.targetCategory = .storage
catcher.playerX = 0.5
catcher.items = [CatcherItem(service: ArcadeCatalog.service(for: .storage), kind: .target, x: 0.5, y: 0.80)]
catcher.tick(0.01)
check(catcher.caught == 1 && catcher.score > 0 && catcher.lives == 3, "Catcher target collision")

catcher.items = [CatcherItem(service: ArcadeCatalog.service(for: .compute), kind: .wrong, x: 0.5, y: 0.80)]
catcher.tick(0.01)
check(catcher.lives == 2 && catcher.combo == 0, "Catcher wrong-service collision")

catcher.lives = 1
catcher.items = [CatcherItem(service: ArcadeCatalog.service(for: .compute), kind: .wrong, x: 0.5, y: 0.80)]
catcher.tick(0.01)
check(catcher.status == .results, "Catcher game over")

var clamped = CatcherState()
clamped.status = .playing
clamped.tick(2.0)
check(clamped.elapsed == 0.1, "Catcher delta clamp")

// Sorter: deadline resolves automatically and a mismatch increments mistakes;
// reaching five mistakes ends the run. Dispatching a matching card scores.
var sorter = SorterState()
sorter.status = .playing
sorter.current = ArcadeCatalog.service(for: .compute)
sorter.crownIndex = 0
sorter.timeRemaining = 0.05
sorter.tick(1.0)
check(sorter.dispatched == 1 && sorter.score > 0 && sorter.mistakes == 0, "Sorter automatic matching deadline")

sorter.status = .playing
sorter.current = ArcadeCatalog.service(for: .storage)
sorter.crownIndex = 0
sorter.mistakes = 4
sorter.resolve()
check(sorter.status == .results && sorter.mistakes == 5, "Sorter deadline game over")

// Vault: circular proximity wraps at 0/360, a held aligned dial opens a stage,
// and a paused model does not drain its timer.
var vault = VaultState()
vault.status = .playing
vault.target = 359
vault.dial = 1
check(vault.distance == 2 && vault.isAligned, "Vault circular distance")
vault.target = 0
vault.dial = 0
vault.timeRemaining = 10
for _ in 0..<6 { vault.tick(0.1) }
check(vault.stage == 2 && vault.score > 0, "Vault held-pin stage unlock")

let beforePause = vault.timeRemaining
vault.status = .paused
vault.tick(1.0)
check(vault.timeRemaining == beforePause, "Paused vault does not drain")

var timeout = VaultState()
timeout.status = .playing
timeout.target = 0
timeout.dial = 180
timeout.timeRemaining = 0.05
timeout.tick(1.0)
check(timeout.status == .results, "Vault timeout")

print("AWS arcade production logic harness passed")
    }
}

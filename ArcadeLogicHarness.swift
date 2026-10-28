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
let resolvedServiceName = sorter.current?.name
sorter.timeRemaining = 0.05
sorter.tick(1.0)
check(sorter.dispatched == 1 && sorter.score > 0 && sorter.mistakes == 0, "Sorter automatic matching deadline")

check(sorter.isShowingFeedback && sorter.current?.name == resolvedServiceName, "Sorter retains resolved card for feedback")
let dispatchCount = sorter.dispatched
sorter.resolve()
check(sorter.dispatched == dispatchCount, "Sorter blocks repeated dispatch during feedback")
for _ in 0..<13 { sorter.tick(0.1) }
check(!sorter.isShowingFeedback && sorter.timeRemaining >= 3, "Sorter deals after feedback with readable deadline")
var firstSort = SorterState()
firstSort.start()
check(firstSort.timeRemaining == 6, "Sorter first card allows six seconds to learn controls")
firstSort.round = 100
firstSort.feedbackRemaining = 0.05
firstSort.tick(0.1)
check(firstSort.timeRemaining == 3, "Sorter later cards retain three-second minimum")
firstSort.status = .paused
let pausedSortTime = firstSort.timeRemaining
firstSort.tick(10)
check(firstSort.timeRemaining == pausedSortTime, "Sorter pause preserves deadline")
sorter.status = .playing
sorter.current = ArcadeCatalog.service(for: .storage)
sorter.crownIndex = 0
sorter.mistakes = 4
sorter.resolve()
check(sorter.status == .results && sorter.mistakes == 5, "Sorter deadline game over")

// Every visible bin uses the same production category mapping as the Crown.
for category in ServiceCategory.allCases {
    var tapped = SorterState()
    tapped.status = .playing
    tapped.current = ArcadeCatalog.service(for: category)
    tapped.dispatch(to: category)
    check(tapped.selectedCategory == category && tapped.dispatched == 1 && tapped.mistakes == 0, "Sorter direct bin mapping")
    tapped.dispatch(to: .compute)
    check(tapped.dispatched == 1 && tapped.selectedCategory == category, "Sorter bin taps blocked during feedback")
}

// Crown selection visits every category in both directions and stays put when
// a new card is dealt. The SwiftUI input binds directly to this integer index.
var traversal = SorterState()
traversal.start()
for index in Array(0..<ServiceCategory.allCases.count) + Array((0..<ServiceCategory.allCases.count).reversed()) {
    traversal.selectCategory(at: index)
    check(traversal.selectedCategory == ServiceCategory.allCases[index], "Sorter full bidirectional category traversal")
}
traversal.selectCategory(at: 4)
traversal.current = ArcadeCatalog.service(for: .data)
traversal.resolve()
for _ in 0..<13 { traversal.tick(0.1) }
check(traversal.selectedCategory == .data, "Sorter next card preserves Crown selection")

// Production input reducer: native acceleration never skips a visible bin.
var input = CrownStepReducer(position: 0, lower: 0, upper: 4)
check(input.consume(raw: 40, at: 0) == 1, "Large native jump advances exactly one bin")
check(input.consume(raw: 80, at: 0.04) == nil && input.position == 1, "Fast acceleration is rate limited")
check(input.consume(raw: 120, at: 0.17) == 2, "Deliberate next movement advances one more bin")
check(input.consume(raw: 119, at: 0.19) == nil, "Tiny immediate reversal jitter is ignored")
check(input.consume(raw: 118, at: 0.26) == 1, "Deliberate reversal responds in eighty milliseconds")
check(input.consume(raw: 118, at: 1) == nil, "No delayed catch-up when Crown stops")
input.select(4)
let rawAfterTouch = input.lastRaw
check(input.consume(raw: rawAfterTouch - 50, at: 1.1) == 3, "Tap selection preserves raw Crown and next reverse step")
for (offset, expected) in [2, 1, 0].enumerated() {
    check(input.consume(raw: rawAfterTouch - 100 - offset * 50, at: 1.3 + Double(offset) * 0.2) == expected, "Reverse traversal visits each bin")
}
check(input.consume(raw: -1000, at: 2) == nil && input.position == 0, "Lower bound clamps")
for expected in 1...4 {
    check(input.consume(raw: -1000 + expected * 70, at: 2 + Double(expected) * 0.2) == expected, "Forward traversal visits each bin despite large jumps")
}
check(input.consume(raw: 1000, at: 3) == nil && input.position == 4, "Upper bound clamps")
check(input.consume(raw: 999, at: 3.1) == 3, "Direction reverses after hitting end without unwinding raw distance")

// Guided practice freezes all stakes and teaches both adding and removing.
var tutorial = ScaleOpsState()
tutorial.start(guided: true)
for _ in 0..<100 { tutorial.tick(0.1) }
check(tutorial.elapsed == 0 && tutorial.budget == 100 && tutorial.queue == 0 && tutorial.outages == 0, "Idle tutorial has no time or cost penalty")
tutorial.requestCapacity(3)
for _ in 0..<19 { tutorial.tick(0.1) }
check(tutorial.tutorialStep == .addServer && tutorial.onlineInstances == 2, "Tutorial exposes provisioning delay")
tutorial.tick(0.1)
check(tutorial.tutorialStep == .removeServer && tutorial.demand == 4 && tutorial.capacity == 6, "Added server visibly handles more traffic before scale-in lesson")
tutorial.requestCapacity(2)
for _ in 0..<20 { tutorial.tick(0.1) }
check(tutorial.tutorialStep == .ready && tutorial.capacity == 4 && tutorial.budget == 100, "Removing spare capacity completes guided practice")
tutorial.beginRun()
check(!tutorial.isTutorial && tutorial.timeRemaining == 42 && tutorial.onlineInstances == 2, "Flash sale begins only after explicit tutorial completion")
var waste = ScaleOpsState()
waste.start()
waste.requestCapacity(8)
for _ in 0..<20 { waste.tick(0.1) }
check(waste.guidance.contains("Too many servers") && waste.guidance.contains("DOWN"), "Overprovisioning explicitly tells player to reduce servers")

// Scale Ops: desired capacity is distinct from capacity actually online.
var scaling = ScaleOpsState()
scaling.start()
scaling.requestCapacity(4)
for _ in 0..<19 { scaling.tick(0.1) }
check(scaling.onlineInstances == 2 && scaling.desiredInstances == 4, "Scaling lag retains old capacity")
let remainingScale = scaling.scalingRemaining
scaling.requestCapacity(4)
check(scaling.scalingRemaining == remainingScale, "Repeated desired capacity does not restart provisioning")
scaling.tick(0.1)
check(scaling.onlineInstances == 4 && scaling.scalingRemaining == 0, "Requested capacity becomes available after two seconds")
scaling.requestCapacity(7)
scaling.status = .paused
let pausedBudget = scaling.budget, pausedTime = scaling.elapsed, pausedProvisioning = scaling.scalingRemaining
scaling.tick(10)
scaling.requestCapacity(1)
check(scaling.budget == pausedBudget && scaling.elapsed == pausedTime && scaling.scalingRemaining == pausedProvisioning && scaling.desiredInstances == 7, "Paused simulation freezes resources, provisioning and input")

var capped = ScaleOpsState()
capped.start()
capped.tick(10)
check(capped.elapsed == 0.1, "Scale Ops clamps large frame delta")
var overflow = ScaleOpsState()
overflow.start()
overflow.elapsed = 24 // peak traffic
for _ in 0..<100 { overflow.tick(0.1) }
check(overflow.outages == 3 && overflow.dropped > 0 && overflow.status == .results, "Under-capacity causes backlog, dropped work, and outages")
var insolvent = ScaleOpsState()
insolvent.start()
insolvent.budget = 0.01
insolvent.tick(0.1)
check(insolvent.status == .results && insolvent.budget == 0, "Zero budget ends the run")

// Exercise complete policies against actual production traffic and costs.
func simulate(_ policy: (ScaleOpsState) -> Int) -> ScaleOpsState {
    var run = ScaleOpsState()
    run.start()
    for _ in 0..<500 {
        guard run.status == .playing else { break }
        run.requestCapacity(policy(run))
        run.tick(0.1)
    }
    return run
}
let planned = simulate { run in
    // Start adding capacity just before the two-second provisioning window.
    // Keep it during a downshift until the lower traffic actually arrives.
    let incoming = run.nextDemand ?? run.demand
    let expected = run.nextWaveIn <= 2.2 ? max(run.demand, incoming) : run.demand
    return Int(ceil(expected / 2))
}
check(planned.completed && planned.outages == 0 && planned.budget > 0, "Forecast-following policy survives all waves within budget")
let maximum = simulate { _ in 8 }
check(!maximum.completed && maximum.budget == 0 && maximum.elapsed < ScaleOpsState.duration, "Always-max capacity wastes the budget before completion")
let minimum = simulate { _ in 1 }
check(!minimum.completed && minimum.outages == 3, "Always-min capacity cannot handle traffic")
check(planned.score > maximum.score && planned.score > minimum.score, "Useful capacity planning beats both fixed extremes")
print("Scale Ops policies: planned \(planned.score) pts, \(Int(planned.budget)) budget; max \(maximum.score) pts; min \(minimum.score) pts")

print("AWS arcade production logic harness passed")
    }
}

import SwiftUI
import WatchKit

struct ContentView: View {
    @AppStorage("masteredCount") private var masteredCount = 0
    @State private var selectedCategory: Flashcard.Category?
    @State private var currentIndex = 0
    @State private var showingAnswer = false
    @State private var showingDeckPicker = false
    @State private var crownValue = 0.0

    private var activeDeck: [Flashcard] {
        let cards = selectedCategory.map { category in
            Flashcard.deck.filter { $0.category == category }
        } ?? Flashcard.deck
        return cards.isEmpty ? Flashcard.deck : cards
    }

    private var currentCard: Flashcard {
        activeDeck[currentIndex % activeDeck.count]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                HStack {
                    Text("AWS REVISE")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.orange)
                    Spacer()
                    Text("✓ \(masteredCount)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.green)
                }
                .padding(.horizontal, 3)

                FlashcardView(card: currentCard, isShowingAnswer: showingAnswer)
                    .id(currentCard.id)
                    .contentShape(Rectangle())
                    .onTapGesture { revealOrAdvance() }
                    .accessibilityAction(named: "Reveal or next card") { revealOrAdvance() }

                if showingAnswer {
                    HStack(spacing: 8) {
                        Button { advance(mastered: false) } label: {
                            Label("Again", systemImage: "arrow.counterclockwise")
                        }
                        .tint(.red)

                        Button { advance(mastered: true) } label: {
                            Label("Got it", systemImage: "checkmark")
                        }
                        .tint(.green)
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 2)
            .navigationTitle(selectedCategory?.rawValue ?? "Quick Review")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingDeckPicker = true } label: {
                        Image(systemName: "square.grid.2x2")
                    }
                    .accessibilityLabel("Choose study deck")
                }
            }
            .focusable(true)
            .digitalCrownRotation($crownValue, from: -1000, through: 1000, by: 1, sensitivity: .medium, isContinuous: false, isHapticFeedbackEnabled: true)
            .onChange(of: crownValue) { _, _ in
                guard showingAnswer else { return }
                advance(mastered: false)
            }
            .sheet(isPresented: $showingDeckPicker) {
                DeckPicker(selectedCategory: $selectedCategory) {
                    currentIndex = 0
                    showingAnswer = false
                    showingDeckPicker = false
                }
            }
        }
    }

    private func revealOrAdvance() {
        if showingAnswer {
            advance(mastered: false)
        } else {
            WKInterfaceDevice.current().play(.click)
            withAnimation(.easeInOut(duration: 0.2)) { showingAnswer = true }
        }
    }

    private func advance(mastered: Bool) {
        if mastered { masteredCount += 1; WKInterfaceDevice.current().play(.success) }
        else { WKInterfaceDevice.current().play(.click) }
        withAnimation(.easeInOut(duration: 0.18)) {
            currentIndex = (currentIndex + 1) % activeDeck.count
            showingAnswer = false
        }
    }
}

private struct DeckPicker: View {
    @Binding var selectedCategory: Flashcard.Category?
    let done: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Button {
                    selectedCategory = nil
                    done()
                } label: {
                    Label("All concepts", systemImage: "square.stack.3d.up")
                }
                ForEach(Flashcard.Category.allCases) { category in
                    Button {
                        selectedCategory = category
                        done()
                    } label: {
                        Label(category.rawValue, systemImage: category.symbol)
                            .foregroundStyle(category.tint)
                    }
                }
            }
            .navigationTitle("Study deck")
        }
    }
}

#Preview {
    ContentView()
}

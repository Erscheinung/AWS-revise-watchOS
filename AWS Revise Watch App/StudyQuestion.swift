import Foundation

struct StudyQuestion: Identifiable {
    let id = UUID()
    let service: String
    let category: Flashcard.Category
    let prompt: String
    let options: [String]
    let correctIndex: Int
    let explanation: String
}

enum QuestionBank {
    /// Interleave categories so each run covers the deck instead of only its first entries.
    static func questions(for mode: LearningMode, category: Flashcard.Category? = nil) -> [StudyQuestion] {
        let deck = category.map { selected in Flashcard.deck.filter { $0.category == selected } } ?? interleavedDeck()
        let cards = Array(deck.prefix(36))
        let fallback = Flashcard.deck
        return cards.indices.map { index in
            let card = cards[index]
            let distractors = wrongAnswers(for: card, in: fallback, offset: index)
            switch mode {
            case .review:
                return StudyQuestion(service: card.service, category: card.category, prompt: card.prompt,
                                     options: [], correctIndex: 0, explanation: card.answer + "  " + card.takeaway)
            case .sprint:
                let answers = shuffled([card.answer] + distractors, seed: index)
                return StudyQuestion(service: card.service, category: card.category,
                                     prompt: card.prompt, options: answers,
                                     correctIndex: answers.firstIndex(of: card.answer) ?? 0, explanation: card.takeaway)
            case .scenario:
                let answers = shuffled([card.answer] + distractors, seed: index + 11)
                return StudyQuestion(service: card.service, category: card.category,
                                     prompt: scenarioPrompt(for: card), options: answers,
                                     correctIndex: answers.firstIndex(of: card.answer) ?? 0, explanation: card.takeaway)
            case .trueFalse:
                let isTrue = index.isMultiple(of: 2)
                let statement = isTrue ? card.answer : falseStatement(for: card, replacement: distractors.first ?? "another service")
                return StudyQuestion(service: card.service, category: card.category,
                                     prompt: "True or false?\n" + statement, options: ["True", "False"],
                                     correctIndex: isTrue ? 0 : 1, explanation: card.answer + "  " + card.takeaway)
            case .match:
                let answers = shuffled([card.service] + wrongServices(for: card, in: fallback, offset: index), seed: index + 23)
                return StudyQuestion(service: card.service, category: card.category,
                                     prompt: "Which service best fits?\n" + card.answer, options: answers,
                                     correctIndex: answers.firstIndex(of: card.service) ?? 0, explanation: card.takeaway)
            case .daily:
                let answers = shuffled([card.answer] + distractors, seed: index + 37)
                return StudyQuestion(service: card.service, category: card.category,
                                     prompt: dailyPrompt(for: card, index: index), options: answers,
                                     correctIndex: answers.firstIndex(of: card.answer) ?? 0, explanation: card.takeaway)
            }
        }
    }

    private static func interleavedDeck() -> [Flashcard] {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
        let groups = Flashcard.Category.allCases.map { category -> [Flashcard] in
            let cards = Flashcard.deck.filter { $0.category == category }
            guard !cards.isEmpty else { return [] }
            let offset = day % cards.count
            return Array(cards[offset...] + cards[..<offset])
        }
        let longest = groups.map(\.count).max() ?? 0
        return (0..<longest).flatMap { index in groups.compactMap { index < $0.count ? $0[index] : nil } }
    }

    private static func wrongAnswers(for card: Flashcard, in deck: [Flashcard], offset: Int) -> [String] {
        let candidates = Array(Set(deck.filter { $0.id != card.id }.map(\.answer))).sorted()
        guard !candidates.isEmpty else { return ["Not applicable", "A different AWS service", "Manual management"] }
        let start = offset * 5 % candidates.count
        return (0..<3).map { candidates[(start + $0) % candidates.count] }
    }

    private static func wrongServices(for card: Flashcard, in deck: [Flashcard], offset: Int) -> [String] {
        let services = Array(Set(deck.map(\.service).filter { $0 != card.service })).sorted()
        guard !services.isEmpty else { return ["Lambda", "Amazon S3", "Amazon RDS"] }
        let start = offset * 7 % services.count
        return (0..<3).map { services[(start + $0) % services.count] }
    }

    private static func scenarioPrompt(for card: Flashcard) -> String {
        "A team needs a solution with this outcome: \(card.answer)\n\nWhat is the best answer?"
    }

    private static func dailyPrompt(for card: Flashcard, index: Int) -> String {
        let starters = ["Choose the best fit:", "Fast recall:", "Exam signal:", "Architecture clue:"]
        return starters[index % starters.count] + "\n" + card.prompt
    }

    private static func falseStatement(for card: Flashcard, replacement: String) -> String {
        "\(card.service) is best remembered as: \(replacement)"
    }

    private static func shuffled(_ items: [String], seed: Int) -> [String] {
        guard !items.isEmpty else { return [] }
        let shift = seed % items.count
        return Array(items[shift...] + items[..<shift])
    }
}

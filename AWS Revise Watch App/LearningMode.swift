import SwiftUI

enum LearningMode: String, CaseIterable, Identifiable {
    case review = "Quick Review"
    case sprint = "Sprint Quiz"
    case scenario = "Scenario Lab"
    case trueFalse = "True / False"
    case match = "Match-Up"
    case daily = "Daily Mix"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .review: "Tap, reveal, remember"
        case .sprint: "36 quick-fire choices"
        case .scenario: "Pick the best architecture"
        case .trueFalse: "Catch the AWS myth"
        case .match: "Connect service to use case"
        case .daily: "A fresh mixed challenge"
        }
    }

    var symbol: String {
        switch self {
        case .review: "rectangle.stack"
        case .sprint: "bolt.fill"
        case .scenario: "point.3.connected.trianglepath.dotted"
        case .trueFalse: "checkmark.seal"
        case .match: "arrow.left.arrow.right"
        case .daily: "sparkles"
        }
    }

    var tint: Color {
        switch self {
        case .review: .orange
        case .sprint: .yellow
        case .scenario: .pink
        case .trueFalse: .green
        case .match: .cyan
        case .daily: .purple
        }
    }

    var detail: String {
        switch self {
        case .review: "36 focused recall cards"
        case .sprint: "36 multiple-choice questions"
        case .scenario: "36 exam-style situations"
        case .trueFalse: "36 misconception checks"
        case .match: "36 service-to-need matches"
        case .daily: "36 rotating mixed prompts"
        }
    }
}

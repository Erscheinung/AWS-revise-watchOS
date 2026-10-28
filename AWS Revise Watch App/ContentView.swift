import SwiftUI
import WatchKit

struct ContentView: View {
    @AppStorage("masteredCount") private var masteredCount = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("AWS REVISE").font(.system(size: 10, weight: .bold, design: .rounded)).foregroundStyle(.orange)
                            Text("Learn your way").font(.system(.title3, design: .rounded, weight: .bold))
                        }
                        Spacer()
                        Label("\(masteredCount)", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(.green)
                    }
                    Text("Study, play, and build AWS instincts.")
                        .font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(.secondary)

                    NavigationLink { AWSArcadeView() } label: { ArcadeRow() }
                        .buttonStyle(.plain)

                    ForEach(LearningMode.allCases) { mode in
                        NavigationLink { StudySessionView(mode: mode) } label: { ModeRow(mode: mode) }
                            .buttonStyle(.plain)
                    }

                    Text("FOCUS A DOMAIN").font(.system(size: 10, weight: .bold, design: .rounded)).foregroundStyle(.secondary).padding(.top, 4)
                    ForEach(Flashcard.Category.allCases) { category in
                        NavigationLink { StudySessionView(mode: .review, category: category) } label: {
                            Label(category.rawValue + " review", systemImage: category.symbol)
                                .font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(category.tint)
                                .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 5)
                        }.buttonStyle(.plain)
                    }
                }.padding(.horizontal, 4).padding(.bottom, 12)
            }.navigationTitle("Study")
        }
    }
}

private struct ArcadeRow: View {
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(.cyan.opacity(0.18))
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.cyan)
            }
            .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text("CROWN ARCADE")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Text("Three watch-native AWS skill games")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(10)
        .background(
            LinearGradient(colors: [.cyan.opacity(0.22), .purple.opacity(0.14)], startPoint: .leading, endPoint: .trailing),
            in: RoundedRectangle(cornerRadius: 15, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(.cyan.opacity(0.42), lineWidth: 1)
        }
    }
}

private struct ModeRow: View {
    let mode: LearningMode
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: mode.symbol).font(.system(size: 16, weight: .bold)).foregroundStyle(mode.tint).frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(mode.rawValue).font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(.white)
                Text(mode.subtitle).font(.system(size: 10, weight: .medium, design: .rounded)).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.caption2.weight(.bold)).foregroundStyle(.tertiary)
        }
        .padding(10).background(mode.tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(mode.tint.opacity(0.28), lineWidth: 1) }
    }
}

private struct StudySessionView: View {
    let mode: LearningMode
    let category: Flashcard.Category?
    @AppStorage("masteredCount") private var masteredCount = 0
    @State private var currentIndex = 0
    @State private var selectedAnswer: Int?
    @State private var revealed = false
    @State private var finished = false

    init(mode: LearningMode, category: Flashcard.Category? = nil) { self.mode = mode; self.category = category }
    private var questions: [StudyQuestion] { QuestionBank.questions(for: mode, category: category) }
    private var question: StudyQuestion { questions[currentIndex] }

    var body: some View {
        Group {
            if finished { completionView }
            else if mode == .review { reviewView }
            else { quizView }
        }
        .navigationTitle(category?.rawValue ?? mode.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var progress: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack { Text("\(currentIndex + 1) OF \(questions.count)"); Spacer(); Text(mode.detail) }
                .font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(.secondary)
            ProgressView(value: Double(currentIndex + 1), total: Double(questions.count)).tint(mode.tint)
        }
    }

    private var reviewView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                progress
                FlashcardView(card: Flashcard(service: question.service, category: question.category, prompt: question.prompt, answer: question.explanation, takeaway: ""), isShowingAnswer: revealed)
                    .contentShape(Rectangle()).onTapGesture { withAnimation(.easeInOut(duration: 0.2)) { revealed = true } }
                if revealed {
                    HStack(spacing: 8) {
                        Button("Again") { next(mastered: false) }.tint(.red)
                        Button("Got it") { next(mastered: true) }.tint(.green)
                    }.buttonStyle(.borderedProminent).frame(maxWidth: .infinity)
                }
            }.padding(.horizontal, 4).padding(.bottom, 10)
        }
    }

    private var quizView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                progress
                Text(question.service.uppercased()).font(.system(size: 10, weight: .bold, design: .rounded)).foregroundStyle(question.category.tint)
                Text(question.prompt).font(.system(.body, design: .rounded, weight: .semibold)).fixedSize(horizontal: false, vertical: true)
                ForEach(question.options.indices, id: \.self) { index in
                    Button { choose(index) } label: {
                        HStack(alignment: .top, spacing: 7) {
                            Text(["A", "B", "C", "D"][index]).font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(optionColor(for: index))
                            Text(question.options[index]).font(.system(size: 12, weight: .semibold, design: .rounded)).multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(9)
                            .background(optionColor(for: index).opacity(selectedAnswer == nil ? 0.12 : 0.18), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }.buttonStyle(.plain).disabled(selectedAnswer != nil)
                }
                if let selectedAnswer {
                    Text(selectedAnswer == question.correctIndex ? "Correct — \(question.explanation)" : "Not quite — \(question.explanation)")
                        .font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    Button("Next") { next(mastered: selectedAnswer == question.correctIndex) }.buttonStyle(.borderedProminent).tint(mode.tint).frame(maxWidth: .infinity)
                }
            }.padding(.horizontal, 4).padding(.bottom, 12)
        }
    }

    private var completionView: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill").font(.system(size: 36)).foregroundStyle(mode.tint)
            Text("Run complete").font(.system(.title3, design: .rounded, weight: .bold))
            Text("You explored all \(questions.count) \(mode.rawValue.lowercased()) prompts.").font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button("Start again") { restart() }.buttonStyle(.borderedProminent).tint(mode.tint)
        }.padding()
    }

    private func choose(_ index: Int) {
        selectedAnswer = index
        WKInterfaceDevice.current().play(index == question.correctIndex ? .success : .failure)
    }
    private func next(mastered: Bool) {
        if mastered { masteredCount += 1; WKInterfaceDevice.current().play(.success) }
        withAnimation(.easeInOut(duration: 0.18)) {
            if currentIndex + 1 == questions.count { finished = true }
            else { currentIndex += 1; selectedAnswer = nil; revealed = false }
        }
    }
    private func restart() { currentIndex = 0; selectedAnswer = nil; revealed = false; finished = false }
    private func optionColor(for index: Int) -> Color {
        guard let selectedAnswer else { return mode.tint }
        if index == question.correctIndex { return .green }
        if index == selectedAnswer { return .red }
        return .gray
    }
}

#Preview { ContentView() }

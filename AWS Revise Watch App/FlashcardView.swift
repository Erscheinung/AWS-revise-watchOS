import SwiftUI

struct FlashcardView: View {
    let card: Flashcard
    let isShowingAnswer: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 5) {
                Image(systemName: card.category.symbol)
                Text(card.category.rawValue.uppercased())
                    .lineLimit(1)
            }
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundStyle(card.category.tint)

            Text(card.service)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Divider().overlay(.white.opacity(0.16))

            Text(isShowingAnswer ? card.answer : card.prompt)
                .font(.system(isShowingAnswer ? .title3 : .body, design: .rounded, weight: .semibold))
                .foregroundStyle(isShowingAnswer ? card.category.tint : .white)
                .fixedSize(horizontal: false, vertical: true)

            if isShowingAnswer {
                Text(card.takeaway)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !isShowingAnswer {
                Label("Tap to reveal", systemImage: "hand.tap")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(15)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(red: 0.07, green: 0.08, blue: 0.13))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(card.category.tint.opacity(0.4), lineWidth: 1)
                }
        }
    }
}

#Preview {
    FlashcardView(card: Flashcard.deck[0], isShowingAnswer: false)
        .padding()
}

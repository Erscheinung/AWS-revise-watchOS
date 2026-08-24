import SwiftUI

struct FlashcardView: View {
    let card: Flashcard
    let isShowingAnswer: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: card.category.symbol)
                Text(card.category.rawValue.uppercased())
                    .lineLimit(1)
            }
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundStyle(card.category.tint)

            Text(card.service)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)

            Divider().overlay(.white.opacity(0.16))

            Text(isShowingAnswer ? card.answer : card.prompt)
                .font(.system(isShowingAnswer ? .title3 : .body, design: .rounded, weight: .semibold))
                .foregroundStyle(isShowingAnswer ? card.category.tint : .white)
                .minimumScaleFactor(0.68)
                .lineLimit(isShowingAnswer ? 4 : 5)

            if isShowingAnswer {
                Text(card.takeaway)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(4)
                    .minimumScaleFactor(0.72)
            } else {
                Spacer(minLength: 0)
                Label("Tap to reveal", systemImage: "hand.tap")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(14)
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

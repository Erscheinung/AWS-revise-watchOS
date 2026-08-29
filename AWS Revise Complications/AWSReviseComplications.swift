import WidgetKit
import SwiftUI

@main
struct AWSReviseComplications: WidgetBundle {
    var body: some Widget {
        AWSReviseComplication()
    }
}

private struct AWSReviseComplication: Widget {
    // Keep this versioned when the rendered mark changes. WidgetKit aggressively
    // caches complication snapshots, including failed image renders.
    let kind = "com.Erscheinung.AWSReviseWatch.complication.logo.v4"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            AWSReviseComplicationView(entry: entry)
        }
        .configurationDisplayName("AWS Revise")
        .description("Open a quick AWS revision card.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner,
        ])
    }
}

private struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry {
        Entry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        completion(Entry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let entry = Entry(date: .now)
        completion(Timeline(entries: [entry], policy: .never))
    }
}

private struct Entry: TimelineEntry {
    let date: Date
}

/// The smile and arrow from the AWS mark. Drawing it in SwiftUI avoids asset
/// lookup and gives WidgetKit a clean alpha mask for accented watch faces.
private struct AWSSmileArrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX + rect.width * 0.08,
                              y: rect.minY + rect.height * 0.18))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.84,
                        y: rect.minY + rect.height * 0.16),
            control: CGPoint(x: rect.midX,
                             y: rect.minY + rect.height * 0.92)
        )

        path.move(to: CGPoint(x: rect.minX + rect.width * 0.70,
                              y: rect.minY + rect.height * 0.04))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.87,
                        y: rect.minY + rect.height * 0.38),
            control: CGPoint(x: rect.minX + rect.width * 0.94,
                             y: rect.minY + rect.height * 0.02)
        )

        return path
    }
}

private struct AWSReviseComplicationView: View {
    let entry: Entry
    @Environment(\.widgetFamily) private var family

    private var icon: some View {
        ZStack {
            AccessoryWidgetBackground()

            ZStack {
                Circle()
                    .strokeBorder(lineWidth: 2.6)

                VStack(spacing: -2) {
                    Text("aws")
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .tracking(-1)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    AWSSmileArrow()
                        .stroke(
                            style: StrokeStyle(
                                lineWidth: 2.6,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                        .frame(height: 12)
                }
                .padding(.horizontal, 7)
                .padding(.bottom, 2)
            }
            // Orange is retained in full-colour contexts. On an accented watch
            // face, WidgetKit substitutes the face's selected tint
            // blood orange -> .foregroundStyle(Color(red: 0.98, green: 0.28, blue: 0.12))
            // deep tangerine -> .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.0))
            // vibrant/high-visibility (but meh) -> .foregroundStyle(Color(red: 1.0, green: 0.35, blue: 0.0))
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.55, blue: 0.0), // Warm bright orange
                        Color(red: 0.95, green: 0.25, blue: 0.0)  // Deep intense orange
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .widgetAccentable()
        }
        .padding(1)
    }

    var body: some View {
        switch family {
        case .accessoryCircular, .accessoryCorner:
            icon
                .privacySensitive(false)
                .containerBackground(.clear, for: .widget)
        case .accessoryRectangular:
            icon
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .privacySensitive(false)
                .containerBackground(.clear, for: .widget)
        default:
            icon
                .privacySensitive(false)
                .containerBackground(.clear, for: .widget)
        }
    }
}

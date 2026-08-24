import WidgetKit
import SwiftUI

@main
struct AWSReviseComplications: WidgetBundle {
    var body: some Widget {
        AWSReviseComplication()
    }
}

private struct AWSReviseComplication: Widget {
    let kind = "com.Erscheinung.AWSReviseWatch.complication.icon"

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

private struct SmileCurve: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.25))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.2),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        return path
    }
}

private struct AWSReviseComplicationView: View {
    let entry: Entry
    @Environment(\.widgetFamily) private var family

    /// Circular and corner complications render as tinted template content on
    /// many watch faces, so the transparent full-color launcher PNG can become
    /// invisible. This draws a complication-safe version of the same AWS mark.
    private var icon: some View {
        ZStack {
            Circle()
                .strokeBorder(lineWidth: 2)
                .widgetAccentable()

            VStack(spacing: -3) {
                Text("aws")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                SmileCurve()
                    .stroke(style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .frame(height: 7)
                    .widgetAccentable()
            }
            .padding(.horizontal, 5)
        }
        .padding(2)
        .privacySensitive(false)
    }

    var body: some View {
        switch family {
        case .accessoryCircular, .accessoryCorner:
            icon
                .containerBackground(.clear, for: .widget)
        case .accessoryRectangular:
            icon
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .containerBackground(.clear, for: .widget)
        default:
            icon
                .containerBackground(.clear, for: .widget)
        }
    }
}

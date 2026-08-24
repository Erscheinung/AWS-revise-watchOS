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

private struct AWSReviseComplicationView: View {
    let entry: Entry
    @Environment(\.widgetFamily) private var family

    /// Circular and corner complications render in accented/vibrant modes on
    /// watchOS, so transparent full-color logo pixels can disappear on black.
    /// Draw the app-icon artwork as a visible complication-safe badge instead.
    private var icon: some View {
        ZStack {
            Circle()
                .fill(.white)

            Image("ComplicationIcon")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(.tint)
                .widgetAccentable()
                .padding(6)
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

import WidgetKit
import SwiftUI

@main
struct AWSReviseComplications: WidgetBundle {
    var body: some Widget {
        AWSReviseComplication()
    }
}

private struct AWSReviseComplication: Widget {
    let kind = "AWSReviseComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            AWSReviseComplicationView(entry: entry)
        }
        .configurationDisplayName("AWS Revise")
        .description("Open a quick AWS revision card.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner,
            .accessoryInline,
            .accessoryRectangular,
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

    var body: some View {
        switch family {
        case .accessoryCircular:
            Image(systemName: "cloud.fill")
                .widgetLabel("AWS")
        case .accessoryCorner:
            Text("AWS")
                .widgetCurvesContent()
        case .accessoryInline:
            Label("AWS Revise", systemImage: "cloud.fill")
        case .accessoryRectangular:
            HStack {
                Image(systemName: "cloud.fill")
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text("AWS REVISE")
                        .font(.caption2)
                    Text("Quick review")
                        .font(.caption)
                }
            }
        default:
            Text("AWS")
        }
    }
}

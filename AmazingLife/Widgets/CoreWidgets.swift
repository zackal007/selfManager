import SwiftUI
import WidgetKit

struct CoreWidgetEntry: TimelineEntry {
    let date: Date
    let goalNames: [String]
    let contactNames: [String]
}

struct CoreWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> CoreWidgetEntry {
        CoreWidgetEntry(date: Date(), goalNames: ["目标A", "目标B"], contactNames: ["联系人A", "联系人B"]) 
    }

    func getSnapshot(in context: Context, completion: @escaping (CoreWidgetEntry) -> Void) {
        let s = readSummary()
        completion(CoreWidgetEntry(date: Date(), goalNames: s.0, contactNames: s.1))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CoreWidgetEntry>) -> Void) {
        let s = readSummary()
        let entry = CoreWidgetEntry(date: Date(), goalNames: s.0, contactNames: s.1)
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func readSummary() -> ([String], [String]) {
        let defaults = UserDefaults(suiteName: "group.amazinglife.widget")
        let goalNames = defaults?.stringArray(forKey: "widget_pinned_goals_names") ?? []
        let contactNames = defaults?.stringArray(forKey: "widget_pinned_contacts_names") ?? []
        return (goalNames, contactNames)
    }
}

struct SmallCoreWidgetView: View {
    let entry: CoreWidgetEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !entry.goalNames.isEmpty {
                Text(WidgetLocalization.localized("goals"))
                    .font(.system(size: 12, weight: .medium))
                ForEach(entry.goalNames.prefix(2), id: \.self) { name in
                    HStack(spacing: 6) {
                        Text("🎯")
                            .font(.system(size: 14))
                        Text(name)
                            .font(.system(size: 14, weight: .regular))
                            .lineLimit(1)
                    }
                }
            } else if !entry.contactNames.isEmpty {
                Text(WidgetLocalization.localized("contacts"))
                    .font(.system(size: 12, weight: .medium))
                ForEach(entry.contactNames.prefix(2), id: \.self) { name in
                    HStack(spacing: 6) {
                        Text("🧑‍🤝‍🧑")
                            .font(.system(size: 14))
                        Text(name)
                            .font(.system(size: 14, weight: .regular))
                            .lineLimit(1)
                    }
                }
            } else {
                Text(WidgetLocalization.localized("goals"))
                    .font(.system(size: 12, weight: .medium))
                Text("-")
                    .font(.system(size: 14, weight: .regular))
            }
        }
        .padding(10)
        .containerBackground(.background, for: .widget)
    }
}

struct MediumCoreWidgetView: View {
    let entry: CoreWidgetEntry
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(WidgetLocalization.localized("goals"))
                    .font(.system(size: 12, weight: .medium))
                ForEach(entry.goalNames.prefix(3), id: \.self) { name in
                    HStack(spacing: 6) {
                        Text("🎯")
                            .font(.system(size: 14))
                        Text(name)
                            .font(.system(size: 14, weight: .regular))
                            .lineLimit(1)
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text(WidgetLocalization.localized("contacts"))
                    .font(.system(size: 12, weight: .medium))
                ForEach(entry.contactNames.prefix(3), id: \.self) { name in
                    HStack(spacing: 6) {
                        Text("🧑‍🤝‍🧑")
                            .font(.system(size: 14))
                        Text(name)
                            .font(.system(size: 14, weight: .regular))
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(12)
        .containerBackground(.background, for: .widget)
    }
}

struct LargeCoreWidgetView: View {
    let entry: CoreWidgetEntry
    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(WidgetLocalization.localized("goals"))
                        .font(.system(size: 12, weight: .medium))
                    ForEach(entry.goalNames.prefix(6), id: \.self) { name in
                        HStack(spacing: 6) {
                            Text("🎯")
                                .font(.system(size: 14))
                            Text(name)
                                .font(.system(size: 14, weight: .regular))
                                .lineLimit(1)
                        }
                    }
                }
                Spacer()
                VStack(alignment: .leading, spacing: 6) {
                    Text(WidgetLocalization.localized("contacts"))
                        .font(.system(size: 12, weight: .medium))
                    ForEach(entry.contactNames.prefix(6), id: \.self) { name in
                        HStack(spacing: 6) {
                            Text("🧑‍🤝‍🧑")
                                .font(.system(size: 14))
                            Text(name)
                                .font(.system(size: 14, weight: .regular))
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .padding(14)
        .containerBackground(.background, for: .widget)
    }
}

struct CoreWidgetView: View {
    let entry: CoreWidgetEntry
    @Environment(\.widgetFamily) var family
    var body: some View {
        switch family {
        case .systemSmall:
            SmallCoreWidgetView(entry: entry)
        case .systemMedium:
            MediumCoreWidgetView(entry: entry)
        default:
            LargeCoreWidgetView(entry: entry)
        }
    }
}

struct CoreWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "amazinglife.core", provider: CoreWidgetProvider()) { entry in
            CoreWidgetView(entry: entry)
        }
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .configurationDisplayName("AmazingLife")
        .description("Show goals, contacts and records")
    }
}

@main
struct CoreWidgetBundle: WidgetBundle {
    var body: some Widget {
        CoreWidget()
    }
}

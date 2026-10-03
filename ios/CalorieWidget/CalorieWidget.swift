import SwiftUI
import WidgetKit

/// Reads the App Group snapshot written by `CalorieWidgetSnapshot`.
/// The day boundary matches `DayBoundaryCalc`: subtract the offset, then
/// take the local calendar day. When that day id no longer matches, the
/// widget shows a placeholder instead of yesterday's intake.
private enum CalorieWidgetKeys {
    static let appGroupId = "group.com.opennutritracker.ont.opennutritracker"
    static let hasData = "ont_calorie_has_data"
    static let day = "ont_calorie_day"
    static let offset = "ont_calorie_offset_minutes"
    static let consumed = "ont_calorie_consumed"
    static let goal = "ont_calorie_goal"
}

private struct CalorieReading {
    var hasData: Bool
    var dayId: String
    var offsetMinutes: Int
    var consumed: Int
    var goal: Int

    static func load() -> CalorieReading {
        let defaults = UserDefaults(suiteName: CalorieWidgetKeys.appGroupId)
        return CalorieReading(
            hasData: defaults?.string(forKey: CalorieWidgetKeys.hasData) == "1",
            dayId: defaults?.string(forKey: CalorieWidgetKeys.day) ?? "",
            offsetMinutes: Int(defaults?.string(forKey: CalorieWidgetKeys.offset) ?? "") ?? 0,
            consumed: Int(defaults?.string(forKey: CalorieWidgetKeys.consumed) ?? "") ?? 0,
            goal: Int(defaults?.string(forKey: CalorieWidgetKeys.goal) ?? "") ?? 0
        )
    }

    func isCurrent(at moment: Date) -> Bool {
        guard hasData, goal > 0, !dayId.isEmpty else { return false }
        return dayId == Self.dayId(for: moment, offsetMinutes: offsetMinutes)
    }

    func nextBoundary(after moment: Date) -> Date {
        let offset = Self.sanitisedOffset(offsetMinutes)
        let start = Self.logicalDayStart(for: moment, offsetMinutes: offset)
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? moment
        return nextDay.addingTimeInterval(TimeInterval(offset * 60))
    }

    private static func sanitisedOffset(_ minutes: Int) -> Int {
        if minutes < 0 || minutes >= 24 * 60 { return 0 }
        return minutes
    }

    private static func logicalDayStart(for moment: Date, offsetMinutes: Int) -> Date {
        let offset = sanitisedOffset(offsetMinutes)
        let shifted = moment.addingTimeInterval(TimeInterval(-offset * 60))
        return Calendar.current.startOfDay(for: shifted)
    }

    private static func dayId(for moment: Date, offsetMinutes: Int) -> String {
        let start = logicalDayStart(for: moment, offsetMinutes: offsetMinutes)
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: start)
    }
}

private struct CalorieEntry: TimelineEntry {
    var date: Date
    var reading: CalorieReading
    var showsNumbers: Bool
}

private struct CalorieProvider: TimelineProvider {
    func placeholder(in context: Context) -> CalorieEntry {
        CalorieEntry(
            date: Date(),
            reading: CalorieReading(hasData: false, dayId: "", offsetMinutes: 0, consumed: 0, goal: 0),
            showsNumbers: false
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CalorieEntry) -> Void) {
        let reading = CalorieReading.load()
        let now = Date()
        completion(
            CalorieEntry(
                date: now,
                reading: reading,
                showsNumbers: reading.isCurrent(at: now)
            )
        )
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalorieEntry>) -> Void) {
        let reading = CalorieReading.load()
        let now = Date()
        let boundary = reading.nextBoundary(after: now)
        let current = CalorieEntry(
            date: now,
            reading: reading,
            showsNumbers: reading.isCurrent(at: now)
        )
        let expired = CalorieEntry(
            date: boundary,
            reading: reading,
            showsNumbers: false
        )
        completion(Timeline(entries: [current, expired], policy: .after(boundary)))
    }
}

private struct CalorieWidgetView: View {
    var entry: CalorieEntry

    var body: some View {
        Group {
            if entry.showsNumbers {
                progressBody
            } else {
                placeholderBody
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetBackground()
    }

    private var progressBody: some View {
        let goal = max(entry.reading.goal, 1)
        let progress = min(max(Double(entry.reading.consumed) / Double(goal), 0), 1)
        return VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.25), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color.accentColor,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(entry.reading.consumed)")
                        .font(.title2.weight(.semibold))
                        .minimumScaleFactor(0.6)
                    Text("kcal")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 8)
            Text("of \(entry.reading.goal)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(entry.reading.consumed) of \(entry.reading.goal) kilocalories")
    }

    private var placeholderBody: some View {
        VStack(spacing: 4) {
            Text("Calories")
                .font(.headline)
            Text("Open the app")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .accessibilityElement(children: .combine)
    }
}

private extension View {
    @ViewBuilder
    func widgetBackground() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(.fill.tertiary, for: .widget)
        } else {
            background(Color(.systemBackground))
        }
    }
}

struct CalorieProgressWidget: Widget {
    let kind = "CalorieProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalorieProvider()) { entry in
            CalorieWidgetView(entry: entry)
        }
        .configurationDisplayName("Calories")
        .description("Today's calories eaten and your goal.")
        .supportedFamilies([.systemSmall])
    }
}

@main
struct CalorieWidgetBundle: WidgetBundle {
    var body: some Widget {
        CalorieProgressWidget()
    }
}

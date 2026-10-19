import SwiftUI
import WidgetKit

/// Reads the App Group snapshot written by `CalorieWidgetSnapshot`.
/// The day boundary matches `DayBoundaryCalc`: subtract the offset, then
/// take the local calendar day. When that day id no longer matches, the
/// widget shows a placeholder instead of yesterday's intake.
private enum CalorieWidgetKeys {
    /// Per flavour, from the `ONT_APP_GROUP_ID` build setting via Info.plist,
    /// so a develop install never reads or clears the App Store build's data.
    static let appGroupId =
        Bundle.main.object(forInfoDictionaryKey: "ONTAppGroupId") as? String
        ?? "group.com.opennutritracker.ont.opennutritracker"
    /// The figures and the labels that describe them, as one JSON string
    /// (`CalorieWidgetSnapshot.encode`). One value is one write, so a
    /// reading is either the old snapshot or the new one, never a mix.
    static let snapshot = "ont_calorie_snapshot"
    /// The labels that depend only on the language, as one JSON string
    /// (`CalorieWidgetLabels.encodeLanguage`). A wipe keeps them.
    static let labels = "ont_calorie_labels"

    static func decode<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard
            let json = UserDefaults(suiteName: appGroupId)?.string(forKey: key),
            let data = json.data(using: .utf8)
        else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

private struct StoredLanguageLabels: Decodable {
    var title: String?
    var unit: String?
    var openApp: String?
    var description: String?
}

private struct StoredFigureLabels: Decodable {
    var goal: String?
    var accessibility: String?
}

private struct StoredSnapshot: Decodable {
    var hasData: Bool
    var day: String
    var offsetMinutes: Int
    var consumed: Int
    var goal: Int
    var labels: StoredFigureLabels?
}

/// Copy the app writes in its own language (`CalorieWidgetLabels` in Dart),
/// so translations come through the ARB/Weblate pipeline. The English
/// fallbacks only cover the time before the app's first write.
private struct CalorieLabels {
    var title: String
    var unit: String
    var goal: String
    var accessibility: String
    var openApp: String
    var description: String

    /// The goal and VoiceOver lines come from `reading`, which decoded
    /// them from the same stored value as its figures.
    static func load(for reading: CalorieReading? = nil) -> CalorieLabels {
        let language = CalorieWidgetKeys.decode(
            StoredLanguageLabels.self,
            forKey: CalorieWidgetKeys.labels
        )
        func stored(_ value: String?, or fallback: String) -> String {
            guard let value = value, !value.isEmpty else { return fallback }
            return value
        }
        let consumed = reading?.consumed ?? 0
        let goal = reading?.goal ?? 0
        return CalorieLabels(
            title: stored(language?.title, or: "Calories"),
            unit: stored(language?.unit, or: "kcal"),
            goal: stored(reading?.goalLabel, or: "of \(goal)"),
            accessibility: stored(
                reading?.accessibilityLabel,
                or: "\(consumed) of \(goal) kilocalories"
            ),
            openApp: stored(language?.openApp, or: "Open the app"),
            description: stored(
                language?.description,
                or: "Today's calories eaten and your goal."
            )
        )
    }
}

private struct CalorieReading {
    var hasData: Bool
    var dayId: String
    var offsetMinutes: Int
    var consumed: Int
    var goal: Int
    var goalLabel: String? = nil
    var accessibilityLabel: String? = nil

    /// One read and one decode, so the day, the figures and their labels
    /// all come from the same write.
    static func load() -> CalorieReading {
        guard let stored = CalorieWidgetKeys.decode(
            StoredSnapshot.self,
            forKey: CalorieWidgetKeys.snapshot
        ) else {
            return CalorieReading(hasData: false, dayId: "", offsetMinutes: 0, consumed: 0, goal: 0)
        }
        return CalorieReading(
            hasData: stored.hasData,
            dayId: stored.day,
            offsetMinutes: stored.offsetMinutes,
            consumed: stored.consumed,
            goal: stored.goal,
            goalLabel: stored.labels?.goal,
            accessibilityLabel: stored.labels?.accessibility
        )
    }

    func isCurrent(at moment: Date) -> Bool {
        guard hasData, goal > 0, !dayId.isEmpty else { return false }
        return dayId == Self.dayId(for: moment, offsetMinutes: offsetMinutes)
    }

    func nextBoundary(after moment: Date) -> Date {
        let offset = Self.sanitisedOffset(offsetMinutes)
        let start = Self.logicalDayStart(for: moment, offsetMinutes: offset)
        let nextDay = Self.calendar.date(byAdding: .day, value: 1, to: start) ?? moment
        return nextDay.addingTimeInterval(TimeInterval(offset * 60))
    }

    /// Dart's `DateTime` is always Gregorian, so the day id has to be too.
    /// `Calendar.current` follows the device setting (Buddhist, Hebrew,
    /// Islamic, ...) and would format a different year and day.
    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
        return calendar
    }

    private static func sanitisedOffset(_ minutes: Int) -> Int {
        if minutes < 0 || minutes >= 24 * 60 { return 0 }
        return minutes
    }

    private static func logicalDayStart(for moment: Date, offsetMinutes: Int) -> Date {
        let offset = sanitisedOffset(offsetMinutes)
        let shifted = moment.addingTimeInterval(TimeInterval(-offset * 60))
        return calendar.startOfDay(for: shifted)
    }

    private static func dayId(for moment: Date, offsetMinutes: Int) -> String {
        let start = logicalDayStart(for: moment, offsetMinutes: offsetMinutes)
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: start)
    }
}

private struct CalorieEntry: TimelineEntry {
    var date: Date
    var reading: CalorieReading
    var labels: CalorieLabels
    var showsNumbers: Bool
}

private struct CalorieProvider: TimelineProvider {
    func placeholder(in context: Context) -> CalorieEntry {
        CalorieEntry(
            date: Date(),
            reading: CalorieReading(hasData: false, dayId: "", offsetMinutes: 0, consumed: 0, goal: 0),
            labels: CalorieLabels.load(),
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
                labels: CalorieLabels.load(for: reading),
                showsNumbers: reading.isCurrent(at: now)
            )
        )
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalorieEntry>) -> Void) {
        let reading = CalorieReading.load()
        let labels = CalorieLabels.load(for: reading)
        let now = Date()
        let boundary = reading.nextBoundary(after: now)
        let current = CalorieEntry(
            date: now,
            reading: reading,
            labels: labels,
            showsNumbers: reading.isCurrent(at: now)
        )
        let expired = CalorieEntry(
            date: boundary,
            reading: reading,
            labels: labels,
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
                    Text(entry.labels.unit)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 8)
            Text(entry.labels.goal)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(entry.labels.accessibility))
    }

    private var placeholderBody: some View {
        VStack(spacing: 4) {
            Text(entry.labels.title)
                .font(.headline)
            Text(entry.labels.openApp)
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
        .configurationDisplayName(CalorieLabels.load().title)
        .description(CalorieLabels.load().description)
        .supportedFamilies([.systemSmall])
    }
}

@main
struct CalorieWidgetBundle: WidgetBundle {
    var body: some Widget {
        CalorieProgressWidget()
    }
}

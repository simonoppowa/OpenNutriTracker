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
    // Added for the one-row widget. Absent in a write from an older app.
    var protein: String?
    var carbs: String?
    var fat: String?
    var gram: String?
    var water: String?
    var milliliter: String?
    var rowTitle: String?
    var rowDescription: String?
}

private struct StoredFigureLabels: Decodable {
    var goal: String?
    var accessibility: String?
    var rowAccessibility: String?
}

/// One macro row or the water figure, as the app wrote it. Every field is
/// optional so a write from an older or newer app never fails the decode of
/// the calorie figures beside it.
private struct StoredMacroRow: Decodable {
    var g: Int?
    var goalG: Int?
}

private struct StoredMacros: Decodable {
    var protein: StoredMacroRow?
    var carbs: StoredMacroRow?
    var fat: StoredMacroRow?
}

private struct StoredWater: Decodable {
    var ml: Int?
    var goalMl: Int?
}

private struct StoredSnapshot: Decodable {
    var hasData: Bool
    var day: String
    var offsetMinutes: Int
    var consumed: Int
    var goal: Int
    var labels: StoredFigureLabels?
    var macros: StoredMacros?
    var water: StoredWater?
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
    // The one-row widget. Read from the same stored values.
    var protein: String
    var carbs: String
    var fat: String
    var gram: String
    var water: String
    var milliliter: String
    var rowTitle: String
    var rowDescription: String
    var rowAccessibility: String

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
        let accessibility = stored(
            reading?.accessibilityLabel,
            or: "\(consumed) of \(goal) kilocalories"
        )
        return CalorieLabels(
            title: stored(language?.title, or: "Calories"),
            unit: stored(language?.unit, or: "kcal"),
            goal: stored(reading?.goalLabel, or: "of \(goal)"),
            accessibility: accessibility,
            openApp: stored(language?.openApp, or: "Open the app"),
            description: stored(
                language?.description,
                or: "Today's calories eaten and your goal."
            ),
            protein: stored(language?.protein, or: "protein"),
            carbs: stored(language?.carbs, or: "carbs"),
            fat: stored(language?.fat, or: "fat"),
            gram: stored(language?.gram, or: "g"),
            water: stored(language?.water, or: "Water"),
            milliliter: stored(language?.milliliter, or: "ml"),
            rowTitle: stored(language?.rowTitle, or: "Nutrition"),
            rowDescription: stored(
                language?.rowDescription,
                or: "Today's calories, macros and water in one row."
            ),
            // Without macros or water the app writes no row sentence, so
            // the calorie sentence is read instead of a missing figure.
            rowAccessibility: stored(
                reading?.rowAccessibilityLabel,
                or: accessibility
            )
        )
    }
}

/// A consumed amount and its goal, in grams for a macro and in millilitres
/// for water. A goal of zero or less has no bar.
private struct NutrientFigure {
    var value: Int
    var goal: Int

    init?(_ row: StoredMacroRow?) {
        guard let row = row, let value = row.g else { return nil }
        self.value = max(value, 0)
        self.goal = row.goalG ?? 0
    }

    init?(_ water: StoredWater?) {
        guard let water = water, let value = water.ml else { return nil }
        self.value = max(value, 0)
        self.goal = water.goalMl ?? 0
    }

    var progress: Double? {
        guard goal > 0 else { return nil }
        return min(max(Double(value) / Double(goal), 0), 1)
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
    var rowAccessibilityLabel: String? = nil
    // The one-row widget's cells. Nil means the app did not write that
    // figure, and the cell is left out.
    var carbs: NutrientFigure? = nil
    var fat: NutrientFigure? = nil
    var protein: NutrientFigure? = nil
    var water: NutrientFigure? = nil

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
            accessibilityLabel: stored.labels?.accessibility,
            rowAccessibilityLabel: stored.labels?.rowAccessibility,
            carbs: NutrientFigure(stored.macros?.carbs),
            fat: NutrientFigure(stored.macros?.fat),
            protein: NutrientFigure(stored.macros?.protein),
            water: NutrientFigure(stored.water)
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
        CalorieWidgetPlaceholder(labels: entry.labels)
    }
}

/// Shown until the app has written today's figures, and again once the
/// day boundary has passed. Both widgets use it.
private struct CalorieWidgetPlaceholder: View {
    var labels: CalorieLabels

    var body: some View {
        VStack(spacing: 4) {
            Text(labels.title)
                .font(.headline)
            Text(labels.openApp)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .accessibilityElement(children: .combine)
    }
}

/// The one-row widget's colours. The three macro colours are the app's own
/// (`AppPalette`), which stay the same across every accent theme. The app
/// has no water colour, so water uses the neutral secondary colour.
private enum NutritionRowColors {
    static let carbs = dynamic(light: 0xB87410, dark: 0xF2B45A)
    static let fat = dynamic(light: 0xD05536, dark: 0xFF937B)
    static let protein = dynamic(light: 0x1F8E80, dark: 0x49C9B8)
    static let water = Color.secondary
    static let track = Color.secondary.opacity(0.25)

    private static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1
            )
        })
    }
}

/// Thin bar, consumed over goal, clamped to 0...1. A goal of zero or less
/// leaves the space empty so the cells stay level.
private struct NutrientBar: View {
    var progress: Double?
    var color: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(NutritionRowColors.track)
                if let progress = progress {
                    Capsule()
                        .fill(color)
                        .frame(width: proxy.size.width * CGFloat(progress))
                }
            }
        }
        .frame(height: 4)
        .accessibilityHidden(true)
    }
}

/// Grams or millilitres, a thin bar, and the name in words.
private struct NutrientCell: View {
    var figure: NutrientFigure
    var unit: String
    var label: String
    var color: Color

    var body: some View {
        VStack(spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(figure.value)")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            NutrientBar(progress: figure.progress, color: color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }
}

/// Calories eaten, the unit, and the goal. No bar: the ring widget has one.
private struct CaloriesCell: View {
    var labels: CalorieLabels
    var consumed: Int
    /// The wrapped layout has less height, so the number and unit share
    /// one line there.
    var compact: Bool

    var body: some View {
        VStack(spacing: 1) {
            if compact {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    number
                    unit
                }
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            } else {
                number.lineLimit(1).minimumScaleFactor(0.5)
                unit.lineLimit(1).minimumScaleFactor(0.6)
            }
            Text(labels.goal)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }

    private var number: some View {
        Text("\(consumed)")
            .font(.title2.weight(.semibold))
            .foregroundStyle(.primary)
    }

    private var unit: some View {
        Text(labels.unit)
            .font(.caption2)
            .foregroundStyle(.secondary)
    }
}

private struct NutritionRowView: View {
    var entry: CalorieEntry

    @Environment(\.dynamicTypeSize) private var typeSize

    private enum Kind: Hashable {
        case calories, carbs, fat, protein, water
    }

    /// Spacing between cells, and the room the calorie cell gets over the
    /// others: it holds the longest number and the goal phrase.
    private let spacing: CGFloat = 8
    private let caloriesWeight: CGFloat = 1.25

    /// At larger text sizes five cells no longer fit one row without
    /// shrinking the numbers, so the same cells wrap onto two lines.
    private var wraps: Bool { typeSize >= .xLarge }

    private var kinds: [Kind] {
        var kinds: [Kind] = [.calories]
        if entry.reading.carbs != nil { kinds.append(.carbs) }
        if entry.reading.fat != nil { kinds.append(.fat) }
        if entry.reading.protein != nil { kinds.append(.protein) }
        if entry.reading.water != nil { kinds.append(.water) }
        return kinds
    }

    var body: some View {
        Group {
            if entry.showsNumbers {
                rowBody
            } else {
                CalorieWidgetPlaceholder(labels: entry.labels)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Text may grow to accessibility1 and no further, so the cells
        // keep fitting the widget.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .widgetBackground()
    }

    private var rowBody: some View {
        GeometryReader { proxy in
            content(width: proxy.size.width)
                .frame(
                    width: proxy.size.width,
                    height: proxy.size.height,
                    alignment: .center
                )
        }
        .rowInset()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(entry.labels.rowAccessibility))
    }

    @ViewBuilder
    private func content(width: CGFloat) -> some View {
        if wraps {
            let columns = 3
            let first = Array(kinds.prefix(columns))
            let second = Array(kinds.dropFirst(columns))
            let cellWidth = (width - spacing * CGFloat(columns - 1))
                / CGFloat(columns)
            VStack(spacing: 10) {
                cellRow(first, cellWidth: cellWidth)
                if !second.isEmpty {
                    cellRow(second, cellWidth: cellWidth)
                }
            }
        } else {
            let weights = kinds.map { $0 == .calories ? caloriesWeight : 1 }
            let room = width - spacing * CGFloat(kinds.count - 1)
            let unit = room / weights.reduce(0, +)
            HStack(spacing: spacing) {
                ForEach(kinds, id: \.self) { kind in
                    cell(kind)
                        .frame(
                            width: unit * (kind == .calories ? caloriesWeight : 1)
                        )
                }
            }
        }
    }

    private func cellRow(_ row: [Kind], cellWidth: CGFloat) -> some View {
        HStack(spacing: spacing) {
            ForEach(row, id: \.self) { kind in
                cell(kind).frame(width: cellWidth)
            }
        }
    }

    @ViewBuilder
    private func cell(_ kind: Kind) -> some View {
        let labels = entry.labels
        switch kind {
        case .calories:
            CaloriesCell(
                labels: labels,
                consumed: entry.reading.consumed,
                compact: wraps
            )
        case .carbs:
            if let figure = entry.reading.carbs {
                NutrientCell(
                    figure: figure,
                    unit: labels.gram,
                    label: labels.carbs,
                    color: NutritionRowColors.carbs
                )
            }
        case .fat:
            if let figure = entry.reading.fat {
                NutrientCell(
                    figure: figure,
                    unit: labels.gram,
                    label: labels.fat,
                    color: NutritionRowColors.fat
                )
            }
        case .protein:
            if let figure = entry.reading.protein {
                NutrientCell(
                    figure: figure,
                    unit: labels.gram,
                    label: labels.protein,
                    color: NutritionRowColors.protein
                )
            }
        case .water:
            if let figure = entry.reading.water {
                NutrientCell(
                    figure: figure,
                    unit: labels.milliliter,
                    label: labels.water,
                    color: NutritionRowColors.water
                )
            }
        }
    }
}

private extension View {
    /// From iOS 17 the system already insets widget content. Before that
    /// the content has to leave its own margin, as the ring widget does.
    @ViewBuilder
    func rowInset() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            self
        } else {
            padding(.horizontal, 12)
        }
    }

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

/// Calories, macros and water in one row, medium size only. It reads the
/// same snapshot and uses the same timeline as the ring widget, so the day
/// boundary and the "Open the app" placeholder behave the same.
struct OneRowNutritionWidget: Widget {
    let kind = "NutritionRowWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalorieProvider()) { entry in
            NutritionRowView(entry: entry)
        }
        .configurationDisplayName(CalorieLabels.load().rowTitle)
        .description(CalorieLabels.load().rowDescription)
        .supportedFamilies([.systemMedium])
    }
}

@main
struct CalorieWidgetBundle: WidgetBundle {
    var body: some Widget {
        CalorieProgressWidget()
        OneRowNutritionWidget()
    }
}

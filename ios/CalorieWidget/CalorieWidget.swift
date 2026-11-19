import AppIntents
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

/// Decodes to nil instead of failing. One value of a type this extension
/// does not know must not throw away the calorie figures beside it, so the
/// lists and maps the nutrient widget added are read through this.
private struct Lossy<Value: Decodable>: Decodable {
    var value: Value?

    init(from decoder: Decoder) throws {
        value = try? decoder.singleValueContainer().decode(Value.self)
    }
}

/// One name the Edit Widget picker offers. A list, not a map, so the
/// picker keeps the order the app wrote.
private struct StoredNutrientName: Decodable {
    var id: String?
    var name: String?
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
    // Added for the nutrient picker. Absent in a write from an older app.
    var nutrients: Lossy<[Lossy<StoredNutrientName>]>?
    // Added for the small macros and water widgets.
    var macrosTitle: String?
    var macrosDescription: String?
    var waterDescription: String?
}

/// What the app says about one nutrient: the goal phrase, such as "of 30",
/// left out when there is no goal, and the VoiceOver sentence.
private struct StoredFigureNutrient: Decodable {
    /// The amount, written in the app's language with the goal's format.
    var value: String?
    var goal: String?
    var accessibility: String?
}

private struct StoredFigureLabels: Decodable {
    var goal: String?
    var accessibility: String?
    var rowAccessibility: String?
    var nutrients: Lossy<[String: Lossy<StoredFigureNutrient>]>?
    // The small macros and water widgets. Each is left out when the app
    // wrote no such figure.
    var macrosAccessibility: String?
    var waterAccessibility: String?
    var waterGoal: String?
}

/// One macro row or the water figure, as the app wrote it. The amounts are
/// read as `Double` and rounded when they are used, so a fraction such as
/// 9.5 never fails the decode. Today's app writes whole numbers.
private struct StoredMacroRow: Decodable {
    var g: Double?
    var goalG: Double?
}

private struct StoredMacros: Decodable {
    var protein: Lossy<StoredMacroRow>?
    var carbs: Lossy<StoredMacroRow>?
    var fat: Lossy<StoredMacroRow>?
}

private struct StoredWater: Decodable {
    var ml: Double?
    var goalMl: Double?
}

/// One nutrient the app tracks, in its own unit. A missing goal means the
/// app has none to show.
private struct StoredNutrient: Decodable {
    var id: String?
    var consumed: Double?
    var goal: Double?
    var unit: String?
}

private struct StoredSnapshot: Decodable {
    var hasData: Bool
    var day: String
    var offsetMinutes: Int
    var consumed: Int
    var goal: Int
    // Everything after `goal` is read through `Lossy`, so a value of a
    // shape this extension does not know is skipped and the calorie figures
    // above still show. `consumed` and `goal` are the exception: they are
    // what the widget cannot do without, and stay whole numbers.
    var labels: Lossy<StoredFigureLabels>?
    var macros: Lossy<StoredMacros>?
    var water: Lossy<StoredWater>?
    var nutrients: Lossy<[Lossy<StoredNutrient>]>?
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
    /// The names the Edit Widget picker offers, in the app's order.
    var nutrientNames: [NutrientName]
    /// Goal phrases and VoiceOver sentences by nutrient id.
    var nutrientFigures: [String: StoredFigureNutrient]
    // The small macros and water widgets.
    var macrosTitle: String
    var macrosDescription: String
    var waterDescription: String
    var macrosAccessibility: String
    var waterAccessibility: String
    var waterGoal: String

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
            ),
            nutrientNames: NutrientName.list(from: language?.nutrients?.value),
            nutrientFigures: reading?.nutrientFigureLabels ?? [:],
            macrosTitle: stored(language?.macrosTitle, or: "Macros"),
            macrosDescription: stored(
                language?.macrosDescription,
                or: "Today's protein, fat and carbs against your goals."
            ),
            waterDescription: stored(
                language?.waterDescription,
                or: "Today's water against your goal."
            ),
            macrosAccessibility: stored(
                reading?.macrosAccessibilityLabel,
                or: Self.macrosFallbackSentence(reading)
            ),
            waterAccessibility: stored(
                reading?.waterAccessibilityLabel,
                or: Self.waterFallbackSentence(reading)
            ),
            waterGoal: stored(
                reading?.waterGoalLabel,
                or: "of \(reading?.water?.goal ?? 0)"
            )
        )
    }

    /// English only until the app has written its own sentence.
    private static func macrosFallbackSentence(_ reading: CalorieReading?) -> String {
        func part(_ name: String, _ figure: AmountFigure?) -> String? {
            guard let figure = figure else { return nil }
            return figure.goal > 0
                ? "\(name) \(figure.value) of \(figure.goal) grams"
                : "\(name) \(figure.value) grams"
        }
        return [
            part("Protein", reading?.protein),
            part("Fat", reading?.fat),
            part("Carbs", reading?.carbs),
        ].compactMap { $0 }.joined(separator: ". ")
    }

    private static func waterFallbackSentence(_ reading: CalorieReading?) -> String {
        guard let water = reading?.water else { return "" }
        return water.goal > 0
            ? "Water \(water.value) of \(water.goal) millilitres"
            : "Water \(water.value) millilitres"
    }

    /// The name the app wrote for a nutrient, if it wrote one.
    func name(forNutrient id: String) -> String? {
        nutrientNames.first { $0.id == id }?.name
    }
}

/// A nutrient the picker offers, with its name in the app's language.
private struct NutrientName {
    var id: String
    var name: String

    static func list(from stored: [Lossy<StoredNutrientName>]?) -> [NutrientName] {
        (stored ?? []).compactMap { entry in
            guard
                let id = entry.value?.id, !id.isEmpty,
                let name = entry.value?.name, !name.isEmpty
            else { return nil }
            return NutrientName(id: id, name: name)
        }
    }
}

/// The ids the snapshot already carries as top-level figures. Every other
/// id is one the app wrote in its `nutrients` list.
private enum NutrientId {
    static let calories = "calories"
    static let protein = "protein"
    static let carbs = "carbs"
    static let fat = "fat"
}

/// A consumed amount and its goal as whole numbers: grams for a macro and
/// millilitres for water. A goal of zero or less has no bar.
private struct AmountFigure {
    var value: Int
    var goal: Int

    init?(value: Double?, goal: Double?) {
        guard let value = value, let rounded = Self.whole(value) else { return nil }
        self.value = max(rounded, 0)
        self.goal = goal.flatMap { Self.whole($0) } ?? 0
    }

    init?(_ row: Lossy<StoredMacroRow>?) {
        self.init(value: row?.value?.g, goal: row?.value?.goalG)
    }

    init?(_ water: Lossy<StoredWater>?) {
        self.init(value: water?.value?.ml, goal: water?.value?.goalMl)
    }

    /// Nil for a number that is not finite or is too large to hold.
    private static func whole(_ number: Double) -> Int? {
        guard number.isFinite, abs(number) < 1_000_000_000 else { return nil }
        return Int(number.rounded())
    }

    var progress: Double? {
        guard goal > 0 else { return nil }
        return min(max(Double(value) / Double(goal), 0), 1)
    }
}

/// One nutrient in its own unit. A goal of zero or less is no goal.
private struct NutrientReading {
    var value: Double
    var goal: Double?
    var unit: String

    var progress: Double? {
        guard let goal = goal else { return nil }
        return min(max(value / goal, 0), 1)
    }

    static func byId(from stored: [Lossy<StoredNutrient>]?) -> [String: NutrientReading] {
        var readings: [String: NutrientReading] = [:]
        for entry in stored ?? [] {
            guard
                let nutrient = entry.value,
                let id = nutrient.id, !id.isEmpty,
                let consumed = nutrient.consumed, consumed.isFinite,
                let unit = nutrient.unit, !unit.isEmpty
            else { continue }
            let goal = nutrient.goal.flatMap { $0.isFinite && $0 > 0 ? $0 : nil }
            readings[id] = NutrientReading(
                value: max(consumed, 0),
                goal: goal,
                unit: unit
            )
        }
        return readings
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
    var carbs: AmountFigure? = nil
    var fat: AmountFigure? = nil
    var protein: AmountFigure? = nil
    var water: AmountFigure? = nil
    // The nutrient widget's figures, by id, and what the app says about
    // them. Empty when the app is older or wrote none.
    var nutrients: [String: NutrientReading] = [:]
    var nutrientFigureLabels: [String: StoredFigureNutrient] = [:]
    var macrosAccessibilityLabel: String? = nil
    var waterAccessibilityLabel: String? = nil
    var waterGoalLabel: String? = nil

    /// One read and one decode, so the day, the figures and their labels
    /// all come from the same write.
    static func load() -> CalorieReading {
        guard let stored = CalorieWidgetKeys.decode(
            StoredSnapshot.self,
            forKey: CalorieWidgetKeys.snapshot
        ) else {
            return CalorieReading(hasData: false, dayId: "", offsetMinutes: 0, consumed: 0, goal: 0)
        }
        let labels = stored.labels?.value
        return CalorieReading(
            hasData: stored.hasData,
            dayId: stored.day,
            offsetMinutes: stored.offsetMinutes,
            consumed: stored.consumed,
            goal: stored.goal,
            goalLabel: labels?.goal,
            accessibilityLabel: labels?.accessibility,
            rowAccessibilityLabel: labels?.rowAccessibility,
            carbs: AmountFigure(stored.macros?.value?.carbs),
            fat: AmountFigure(stored.macros?.value?.fat),
            protein: AmountFigure(stored.macros?.value?.protein),
            water: AmountFigure(stored.water),
            nutrients: NutrientReading.byId(from: stored.nutrients?.value),
            nutrientFigureLabels: labels?.nutrients?.value?.compactMapValues { $0.value } ?? [:],
            macrosAccessibilityLabel: labels?.macrosAccessibility,
            waterAccessibilityLabel: labels?.waterAccessibility,
            waterGoalLabel: labels?.waterGoal
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
        calendar.timeZone = TimeZone.autoupdatingCurrent
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
    /// Which nutrient the small calorie widget shows. Calories until the
    /// person picks another one (iOS 17 and later).
    var nutrientId: String = NutrientId.calories
}

/// The one place the day boundary and the placeholder are decided. The
/// classic provider and the iOS 17 configurable one both call it, so a
/// widget can never disagree with another about when to expire.
private enum CalorieEntries {
    static func placeholder(nutrientId: String = NutrientId.calories) -> CalorieEntry {
        CalorieEntry(
            date: Date(),
            reading: CalorieReading(hasData: false, dayId: "", offsetMinutes: 0, consumed: 0, goal: 0),
            labels: CalorieLabels.load(),
            showsNumbers: false,
            nutrientId: nutrientId
        )
    }

    static func snapshot(nutrientId: String = NutrientId.calories) -> CalorieEntry {
        let reading = CalorieReading.load()
        let now = Date()
        return CalorieEntry(
            date: now,
            reading: reading,
            labels: CalorieLabels.load(for: reading),
            showsNumbers: reading.isCurrent(at: now),
            nutrientId: nutrientId
        )
    }

    static func timeline(nutrientId: String = NutrientId.calories) -> Timeline<CalorieEntry> {
        let reading = CalorieReading.load()
        let labels = CalorieLabels.load(for: reading)
        let now = Date()
        let boundary = reading.nextBoundary(after: now)
        let current = CalorieEntry(
            date: now,
            reading: reading,
            labels: labels,
            showsNumbers: reading.isCurrent(at: now),
            nutrientId: nutrientId
        )
        let expired = CalorieEntry(
            date: boundary,
            reading: reading,
            labels: labels,
            showsNumbers: false,
            nutrientId: nutrientId
        )
        return Timeline(entries: [current, expired], policy: .after(boundary))
    }
}

private struct CalorieProvider: TimelineProvider {
    func placeholder(in context: Context) -> CalorieEntry {
        CalorieEntries.placeholder()
    }

    func getSnapshot(in context: Context, completion: @escaping (CalorieEntry) -> Void) {
        completion(CalorieEntries.snapshot())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalorieEntry>) -> Void) {
        completion(CalorieEntries.timeline())
    }
}

/// What the small calorie widget shows for one nutrient: the number, its
/// unit, the goal phrase and a ring when there is a goal, and the words
/// VoiceOver reads.
private struct NutrientDisplay {
    /// Nil for calories, which keep the look the widget always had.
    var name: String?
    var value: String
    var unit: String
    /// Nil when there is no goal. Then there is no ring and no "of".
    var goalPhrase: String?
    var progress: Double?
    var accessibility: String

    /// Nil when the app has not written this nutrient: the person hid it,
    /// the app is older, or it has not written yet. The widget then shows
    /// its placeholder, never a number that is not there.
    static func make(id: String, reading: CalorieReading, labels: CalorieLabels) -> NutrientDisplay? {
        switch id {
        case NutrientId.calories:
            let goal = max(reading.goal, 1)
            return NutrientDisplay(
                name: nil,
                value: "\(reading.consumed)",
                unit: labels.unit,
                goalPhrase: labels.goal,
                progress: min(max(Double(reading.consumed) / Double(goal), 0), 1),
                accessibility: labels.accessibility
            )
        case NutrientId.protein:
            return macro(id, reading.protein, labels: labels)
        case NutrientId.carbs:
            return macro(id, reading.carbs, labels: labels)
        case NutrientId.fat:
            return macro(id, reading.fat, labels: labels)
        default:
            guard let nutrient = reading.nutrients[id] else { return nil }
            let figure = labels.nutrientFigures[id]
            let name = labels.name(forNutrient: id) ?? id
            // The app writes the amount and the goal phrase with one
            // format. Before it has, both fall back to one Swift format, so
            // the two never disagree.
            let value = stored(figure?.value, or: format(nutrient.value))
            let goalText = nutrient.goal.map { format($0) }
            return NutrientDisplay(
                name: name,
                value: value,
                unit: nutrient.unit,
                goalPhrase: goalText.map { stored(figure?.goal, or: "of \($0)") },
                progress: nutrient.progress,
                accessibility: stored(
                    figure?.accessibility,
                    or: [name, value, nutrient.unit].joined(separator: " ")
                )
            )
        }
    }

    private static func macro(_ id: String, _ figure: AmountFigure?, labels: CalorieLabels) -> NutrientDisplay? {
        guard let figure = figure else { return nil }
        let name = labels.name(forNutrient: id) ?? id
        let storedFigure = labels.nutrientFigures[id]
        return NutrientDisplay(
            name: name,
            value: "\(figure.value)",
            unit: labels.gram,
            goalPhrase: figure.progress == nil
                ? nil
                : stored(storedFigure?.goal, or: "of \(figure.goal)"),
            progress: figure.progress,
            accessibility: stored(
                storedFigure?.accessibility,
                or: "\(name) \(figure.value) \(labels.gram)"
            )
        )
    }

    /// Up to one decimal place and no digit grouping, which is the format
    /// the app writes. The decimal mark is the device's.
    private static func format(_ amount: Double) -> String {
        amount.formatted(.number.grouping(.never).precision(.fractionLength(0...1)))
    }

    private static func stored(_ value: String?, or fallback: String) -> String {
        guard let value = value, !value.isEmpty else { return fallback }
        return value
    }
}

/// A figure as a number and its unit, with a ring and a goal phrase when
/// there is a goal. The ring widget and the water widget both use it.
private struct RingFigureView: View {
    var name: String?
    var value: String
    var unit: String
    var goalPhrase: String?
    var progress: Double?
    var ringColor: Color
    var accessibility: String

    var body: some View {
        VStack(spacing: 6) {
            if let name = name {
                Text(name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            if let progress = progress {
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.25), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            ringColor,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    figure(font: .title2)
                }
                .padding(.horizontal, 8)
                if let goalPhrase = goalPhrase {
                    Text(goalPhrase)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            } else {
                // No goal, so nothing to measure against: the amount alone.
                figure(font: .title)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibility))
    }

    private func figure(font: Font) -> some View {
        VStack(spacing: 0) {
            Text(value)
                .font(font.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }
}

private struct CalorieWidgetView: View {
    var entry: CalorieEntry

    var body: some View {
        Group {
            if entry.showsNumbers,
               let display = NutrientDisplay.make(
                   id: entry.nutrientId,
                   reading: entry.reading,
                   labels: entry.labels
               ) {
                RingFigureView(
                    name: display.name,
                    value: display.value,
                    unit: display.unit,
                    goalPhrase: display.goalPhrase,
                    progress: display.progress,
                    ringColor: Color.accentColor,
                    accessibility: display.accessibility
                )
            } else {
                CalorieWidgetPlaceholder(labels: entry.labels)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Text may grow to accessibility1 and no further, so the ring and
        // the number keep fitting the small widget.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .widgetBackground()
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
    var figure: AmountFigure
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

/// One macro in the small macros widget: its name, grams over goal grams,
/// and a thin bar. The name and the numbers carry the meaning, so the bar
/// colour is never the only cue.
private struct MacroRow: View {
    var label: String
    var figure: AmountFigure
    var unit: String
    var color: Color

    private var amount: String {
        figure.goal > 0
            ? "\(figure.value) / \(figure.goal) \(unit)"
            : "\(figure.value) \(unit)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Spacer(minLength: 4)
                // The numbers shrink before the name does, and are never cut.
                Text(amount)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .layoutPriority(1)
            }
            NutrientBar(progress: figure.progress, color: color)
        }
    }
}

/// Protein, fat and carbs as three stacked rows. It reads the same macros
/// the one-row widget reads. If the app wrote none, it shows the same
/// placeholder as the other widgets.
private struct MacrosSmallView: View {
    var entry: CalorieEntry

    private var rows: [(label: String, figure: AmountFigure, color: Color)] {
        let labels = entry.labels
        let reading = entry.reading
        return [
            reading.protein.map { (labels.protein, $0, NutritionRowColors.protein) },
            reading.fat.map { (labels.fat, $0, NutritionRowColors.fat) },
            reading.carbs.map { (labels.carbs, $0, NutritionRowColors.carbs) },
        ].compactMap { $0 }
    }

    var body: some View {
        Group {
            if entry.showsNumbers, !rows.isEmpty {
                VStack(spacing: 12) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                        MacroRow(
                            label: row.label,
                            figure: row.figure,
                            unit: entry.labels.gram,
                            color: row.color
                        )
                    }
                }
                .padding(12)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(entry.labels.macrosAccessibility))
            } else {
                CalorieWidgetPlaceholder(labels: entry.labels)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Text may grow to accessibility1 and no further, so three rows
        // keep fitting the small widget.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .widgetBackground()
    }
}

/// Today's water over its goal, in millilitres, in a neutral ring: the app
/// has no water colour. The number and the unit are always written.
private struct WaterSmallView: View {
    var entry: CalorieEntry

    var body: some View {
        Group {
            if entry.showsNumbers, let water = entry.reading.water {
                RingFigureView(
                    name: entry.labels.water,
                    value: "\(water.value)",
                    unit: entry.labels.milliliter,
                    goalPhrase: water.progress == nil ? nil : entry.labels.waterGoal,
                    progress: water.progress,
                    ringColor: NutritionRowColors.water,
                    accessibility: entry.labels.waterAccessibility
                )
            } else {
                CalorieWidgetPlaceholder(labels: entry.labels)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .widgetBackground()
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

/// The kind of the small calorie widget. It never changes, so a widget
/// already on a Home Screen keeps its place when the app is updated.
private enum CalorieWidgetKind {
    static let calories = "CalorieProgressWidget"
}

/// iOS 15.5 to 16.x: the small calorie widget as it always was. It shows
/// calories, because choosing a nutrient needs an App Intent
/// configuration, which starts at iOS 17.
struct CalorieProgressWidget: Widget {
    let kind = CalorieWidgetKind.calories

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

/// Protein, fat and carbs in the small size. It reads the same snapshot and
/// uses the same timeline as the other widgets, so the day boundary and the
/// "Open the app" placeholder behave the same.
struct MacrosSmallWidget: Widget {
    let kind = "MacrosSmallWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalorieProvider()) { entry in
            MacrosSmallView(entry: entry)
        }
        .configurationDisplayName(CalorieLabels.load().macrosTitle)
        .description(CalorieLabels.load().macrosDescription)
        .supportedFamilies([.systemSmall])
    }
}

/// Today's water in the small size, with the same timeline as the others.
struct WaterSmallWidget: Widget {
    let kind = "WaterSmallWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalorieProvider()) { entry in
            WaterSmallView(entry: entry)
        }
        .configurationDisplayName(CalorieLabels.load().water)
        .description(CalorieLabels.load().waterDescription)
        .supportedFamilies([.systemSmall])
    }
}

/// One nutrient in the Edit Widget picker. The names are the app's own
/// strings in the app's language: the app writes them into the App Group
/// and this query offers them, so none of them is Swift copy.
@available(iOS 17.0, *)
struct NutrientEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Nutrient")
    static let defaultQuery = NutrientQuery()

    var id: String
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

@available(iOS 17.0, *)
struct NutrientQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [NutrientEntity] {
        Self.offered().filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [NutrientEntity] {
        Self.offered()
    }

    /// Calories, as the widget has always shown.
    func defaultResult() async -> NutrientEntity? {
        Self.offered().first { $0.id == NutrientId.calories }
    }

    /// What the app last wrote. Before its first write there is only
    /// Calories, under the same English fallback the widget itself uses.
    private static func offered() -> [NutrientEntity] {
        let names = CalorieLabels.load().nutrientNames
        guard !names.isEmpty else {
            return [NutrientEntity(id: NutrientId.calories, name: CalorieLabels.load().title)]
        }
        return names.map { NutrientEntity(id: $0.id, name: $0.name) }
    }
}

/// The Edit Widget sheet of the small calorie widget. No choice made means
/// calories.
@available(iOS 17.0, *)
struct NutrientIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Nutrient"

    @Parameter(title: "Nutrient")
    var nutrient: NutrientEntity?
}

@available(iOS 17.0, *)
private struct NutrientProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> CalorieEntry {
        CalorieEntries.placeholder()
    }

    func snapshot(for configuration: NutrientIntent, in context: Context) async -> CalorieEntry {
        CalorieEntries.snapshot(nutrientId: configuration.nutrient?.id ?? NutrientId.calories)
    }

    func timeline(for configuration: NutrientIntent, in context: Context) async -> Timeline<CalorieEntry> {
        CalorieEntries.timeline(nutrientId: configuration.nutrient?.id ?? NutrientId.calories)
    }
}

/// iOS 17 and later: the same widget, with the nutrient chosen in its Edit
/// Widget sheet. It has the same kind as the classic one, and the day
/// boundary and placeholder come from the same code.
@available(iOS 17.0, *)
struct NutrientCalorieWidget: Widget {
    let kind = CalorieWidgetKind.calories

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: NutrientIntent.self,
            provider: NutrientProvider()
        ) { entry in
            CalorieWidgetView(entry: entry)
        }
        .configurationDisplayName(CalorieLabels.load().title)
        .description(CalorieLabels.load().description)
        .supportedFamilies([.systemSmall])
    }
}

/// The widgets on iOS 17 and later: the small calorie widget with its
/// Edit Widget picker.
@available(iOS 17.0, *)
private struct CalorieWidgetBundleModern: WidgetBundle {
    var body: some Widget {
        NutrientCalorieWidget()
        OneRowNutritionWidget()
        MacrosSmallWidget()
        WaterSmallWidget()
    }
}

/// The widgets before iOS 17: the small calorie widget as it was.
private struct CalorieWidgetBundleClassic: WidgetBundle {
    var body: some Widget {
        CalorieProgressWidget()
        OneRowNutritionWidget()
        MacrosSmallWidget()
        WaterSmallWidget()
    }
}

/// `WidgetBundleBuilder` accepts `if #available` but not `else`, and the
/// classic and the configurable small calorie widget share one kind, so
/// they cannot both be listed. The bundle is chosen here instead, once, as
/// the extension starts.
@main
struct CalorieWidgetEntry {
    static func main() {
        if #available(iOSApplicationExtension 17.0, *) {
            CalorieWidgetBundleModern.main()
        } else {
            CalorieWidgetBundleClassic.main()
        }
    }
}

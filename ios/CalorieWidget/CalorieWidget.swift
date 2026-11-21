import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Stored snapshot and labels

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
    // What the small widgets say when the app is up to date but has no
    // figure for them. Absent in a write from an older app, which is how
    // the widget tells that case from "the app has not written yet".
    var nutrientNotShown: String?
    var waterNoGoal: String?
    // The widget background styles' names, as a list of id and name. Absent
    // in a write from an older app, which then offers the English names.
    var styles: Lossy<[Lossy<StoredNutrientName>]>?
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

// MARK: - Labels

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
    /// The names of the background styles, in the app's order. Empty until
    /// the app has written them.
    var styleNames: [NutrientName]
    /// Goal phrases and VoiceOver sentences by nutrient id.
    var nutrientFigures: [String: StoredFigureNutrient]
    // The small macros and water widgets.
    var macrosTitle: String
    var macrosDescription: String
    var waterDescription: String
    var macrosAccessibility: String
    var waterAccessibility: String
    var waterGoal: String
    /// Nil when the app has not written these lines, so the widget says
    /// "Open the app" instead.
    var nutrientNotShown: String?
    var waterNoGoal: String?

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
            styleNames: NutrientName.list(from: language?.styles?.value),
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
            ),
            nutrientNotShown: language?.nutrientNotShown.flatMap { $0.isEmpty ? nil : $0 },
            waterNoGoal: language?.waterNoGoal.flatMap { $0.isEmpty ? nil : $0 }
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

    /// The name of a background style: the app's, else the English word.
    func styleName(forStyle id: String) -> String {
        styleNames.first { $0.id == id }?.name ?? WidgetStyleId.englishName(id)
    }

    /// The heading of the small calorie widget for a nutrient, also when
    /// it has no figure: the nutrient's name, or "Calories".
    func heading(forNutrient id: String) -> String {
        id == NutrientId.calories ? title : (name(forNutrient: id) ?? title)
    }

    /// The name to print for a nutrient: the app's, else the fixed label of
    /// calories or a macro, else the English sample name, else the id. The
    /// last two only apply before the app has written a name list.
    func displayName(forNutrient id: String) -> String {
        if let name = name(forNutrient: id) { return name }
        switch id {
        case NutrientId.calories: return title
        case NutrientId.protein: return protein
        case NutrientId.carbs: return carbs
        case NutrientId.fat: return fat
        default: return SampleReading.englishNames[id] ?? id
        }
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

// MARK: - Readings and figures

/// A consumed amount and its goal as whole numbers: grams for a macro and
/// millilitres for water. A goal of zero or less has no bar.
private struct AmountFigure {
    var value: Int
    var goal: Int

    init(whole value: Int, goal: Int) {
        self.value = value
        self.goal = goal
    }

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

    /// Above a goal that exists. At the goal is not over it.
    var isOver: Bool { goal > 0 && value > goal }
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

// MARK: - Entries and providers

private struct CalorieEntry: TimelineEntry {
    var date: Date
    var reading: CalorieReading
    var labels: CalorieLabels
    var showsNumbers: Bool
    /// Which nutrient the small calorie widget shows. Calories until the
    /// person picks another one (iOS 17 and later).
    var nutrientId: String = NutrientId.calories
    /// The background style the person chose in the Edit Widget sheet, or
    /// the system look when none was chosen or the id is not known.
    var styleId: String = WidgetStyleId.system
}

/// Made-up figures for the widget gallery and the Edit Widget picker, shown
/// before the app has written today's figures. They are not the person's.
/// The names are English and only apply until the app has written its own.
private enum SampleReading {
    static let englishNames: [String: String] = [
        "fiber": "fiber",
        "sodium": "sodium",
        "saturated_fat": "saturated fat",
        "sugar": "sugar",
        "calcium": "calcium",
        "iron": "iron",
        "potassium": "potassium",
        "vitamin_d": "vitamin D",
        "vitamin_b12": "vitamin B12",
        "magnesium": "magnesium",
    ]

    static let reading = CalorieReading(
        hasData: true,
        dayId: "",
        offsetMinutes: 0,
        consumed: 1450,
        goal: 2000,
        carbs: AmountFigure(whole: 180, goal: 250),
        fat: AmountFigure(whole: 45, goal: 70),
        protein: AmountFigure(whole: 85, goal: 120),
        water: AmountFigure(whole: 1200, goal: 2000),
        nutrients: [
            "fiber": NutrientReading(value: 18, goal: 30, unit: "g"),
            "sodium": NutrientReading(value: 1200, goal: 2300, unit: "mg"),
            "saturated_fat": NutrientReading(value: 12, goal: 20, unit: "g"),
            "sugar": NutrientReading(value: 30, goal: 50, unit: "g"),
            "calcium": NutrientReading(value: 600, goal: 1000, unit: "mg"),
            "iron": NutrientReading(value: 9, goal: 14, unit: "mg"),
            "potassium": NutrientReading(value: 2400, goal: 3500, unit: "mg"),
            "vitamin_d": NutrientReading(value: 8, goal: 15, unit: "µg"),
            "vitamin_b12": NutrientReading(value: 1.6, goal: 2.4, unit: "µg"),
            "magnesium": NutrientReading(value: 220, goal: 355, unit: "mg"),
        ]
    )
}

/// The one place the day boundary and the placeholder are decided. The
/// classic provider and the iOS 17 configurable one both call it, so a
/// widget can never disagree with another about when to expire.
private enum CalorieEntries {
    /// An id the extension does not know is the system look, so a style
    /// from a newer app, or none, never breaks a widget.
    static func resolvedStyle(_ id: String?) -> String {
        guard let id = id, WidgetStyleId.all.contains(id) else {
            return WidgetStyleId.system
        }
        return id
    }

    static func placeholder(
        nutrientId: String = NutrientId.calories,
        styleId: String? = nil
    ) -> CalorieEntry {
        let style = resolvedStyle(styleId)
        return CalorieEntry(
            date: Date(),
            reading: CalorieReading(hasData: false, dayId: "", offsetMinutes: 0, consumed: 0, goal: 0),
            labels: CalorieLabels.load(),
            showsNumbers: false,
            nutrientId: nutrientId,
            styleId: style
        )
    }

    /// In the gallery or the picker (`isPreview`), with no current figures
    /// to show, the entry is a sample with numbers, so the person sees the
    /// widget and not a text placeholder. Anywhere else it is the real
    /// reading, expired or not.
    static func snapshot(
        nutrientId: String = NutrientId.calories,
        isPreview: Bool = false,
        styleId: String? = nil
    ) -> CalorieEntry {
        let style = resolvedStyle(styleId)
        let reading = CalorieReading.load()
        let now = Date()
        let current = reading.isCurrent(at: now)
        if isPreview && !current {
            return CalorieEntry(
                date: now,
                reading: SampleReading.reading,
                labels: CalorieLabels.load(for: SampleReading.reading),
                showsNumbers: true,
                nutrientId: nutrientId,
                styleId: style
            )
        }
        return CalorieEntry(
            date: now,
            reading: reading,
            labels: CalorieLabels.load(for: reading),
            showsNumbers: current,
            nutrientId: nutrientId,
            styleId: style
        )
    }

    static func timeline(
        nutrientId: String = NutrientId.calories,
        styleId: String? = nil
    ) -> Timeline<CalorieEntry> {
        let style = resolvedStyle(styleId)
        let reading = CalorieReading.load()
        let labels = CalorieLabels.load(for: reading)
        let now = Date()
        let boundary = reading.nextBoundary(after: now)
        let current = CalorieEntry(
            date: now,
            reading: reading,
            labels: labels,
            showsNumbers: reading.isCurrent(at: now),
            nutrientId: nutrientId,
            styleId: style
        )
        let expired = CalorieEntry(
            date: boundary,
            reading: reading,
            labels: labels,
            showsNumbers: false,
            nutrientId: nutrientId,
            styleId: style
        )
        return Timeline(entries: [current, expired], policy: .after(boundary))
    }
}

private struct CalorieProvider: TimelineProvider {
    func placeholder(in context: Context) -> CalorieEntry {
        CalorieEntries.placeholder()
    }

    func getSnapshot(in context: Context, completion: @escaping (CalorieEntry) -> Void) {
        completion(CalorieEntries.snapshot(isPreview: context.isPreview))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalorieEntry>) -> Void) {
        completion(CalorieEntries.timeline())
    }
}

// MARK: - Views

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
    /// Above its goal. The widget then adds the arrow to the goal phrase.
    var overGoal: Bool = false

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
                accessibility: labels.accessibility,
                overGoal: reading.goal > 0 && reading.consumed > reading.goal
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
            let name = labels.displayName(forNutrient: id)
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
                ),
                overGoal: nutrient.goal.map { nutrient.value > $0 } ?? false
            )
        }
    }

    private static func macro(_ id: String, _ figure: AmountFigure?, labels: CalorieLabels) -> NutrientDisplay? {
        guard let figure = figure else { return nil }
        let name = labels.displayName(forNutrient: id)
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
            ),
            overGoal: figure.isOver
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

/// A number with its unit under it. The ring in the small widgets and the
/// ring in the wide widget both print their figure with it.
private struct FigureText: View {
    var value: String
    var unit: String
    var font: Font

    @Environment(\.widgetTheme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            Text(value)
                .font(font.weight(.semibold))
                .foregroundStyle(theme.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(unit)
                .font(.caption2)
                .foregroundStyle(theme.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }
}

/// A grey track and a round-capped arc from the top, clockwise, 8 pt wide
/// (9 pt in a high-contrast look). `progress` is consumed over goal, already
/// clamped to 0...1. The small ring widgets and the wide widget draw the
/// ring with it, so they match. The arc is the accent group in a tinted or
/// clear Home Screen, and the track is the primary group.
private struct ProgressRing<Content: View>: View {
    var progress: Double
    var color: Color
    @ViewBuilder var content: () -> Content

    @Environment(\.widgetTheme) private var theme

    var body: some View {
        let width = 8 + theme.strokeBoost
        ZStack {
            Circle()
                .stroke(theme.track, lineWidth: width)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: width, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .accentable()
            // The stroke and a 4 pt gap stay clear of the figure, which
            // shrinks to fit instead of touching the ring.
            content()
                .padding(.horizontal, 12 + theme.strokeBoost)
        }
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
    /// Above the goal: the goal phrase gets the arrow, so the state does
    /// not depend on colour. The ring is full either way.
    var overGoal = false

    @Environment(\.widgetTheme) private var theme

    var body: some View {
        VStack(spacing: 6) {
            if let name = name {
                Text(name)
                    .font(.caption)
                    .foregroundStyle(theme.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            if let progress = progress {
                ProgressRing(progress: progress, color: ringColor) {
                    FigureText(value: value, unit: unit, font: .title2)
                }
                .padding(.horizontal, 8)
                if let goalPhrase = goalPhrase {
                    Text(overGoal ? "\(WidgetCue.over) \(goalPhrase)" : goalPhrase)
                        .font(.caption)
                        .foregroundStyle(theme.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            } else {
                // No goal, so nothing to measure against: the amount alone.
                FigureText(value: value, unit: unit, font: .title)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .contentInset()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibility))
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
                    ringColor: NutritionRowColors.ring,
                    accessibility: display.accessibility,
                    overGoal: display.overGoal
                )
            } else {
                // The nutrient's name stays. With current figures but not
                // this one, say so instead of asking to open the app.
                CalorieWidgetPlaceholder(
                    title: entry.labels.heading(forNutrient: entry.nutrientId),
                    message: (entry.showsNumbers ? entry.labels.nutrientNotShown : nil)
                        ?? entry.labels.openApp
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Text stops growing at xxxLarge. The ring is about 50 pt wide
        // inside its stroke, and above that size the number and its unit
        // would no longer fit. The numbers shrink before they are cut.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .themed(entry.styleId)
    }
}

/// Shown until the app has written today's figures, and again once the
/// day boundary has passed. Every widget uses it, each with its own name
/// as the title. The message is "Open the app", or a line that says why
/// there is no figure when the app is up to date.
private struct CalorieWidgetPlaceholder: View {
    var title: String
    var message: String

    @Environment(\.widgetTheme) private var theme

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundStyle(theme.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            Text(message)
                .font(.caption)
                .foregroundStyle(theme.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.7)
        }
        .contentInset()
        .accessibilityElement(children: .combine)
    }
}

/// The widgets' fixed colours. The three macro colours are the app's own
/// (`AppPalette`), which stay the same across every accent theme. The ring
/// is the app's brand green. The app has no water colour, so water has its
/// own aqua blue, defined here. A dark style forces the dark scheme, so each
/// of these resolves to its dark value there.
private enum NutritionRowColors {
    static let carbs = dynamicColor(light: 0xB87410, dark: 0xF2B45A)
    static let fat = dynamicColor(light: 0xD05536, dark: 0xFF937B)
    static let protein = dynamicColor(light: 0x1F8E80, dark: 0x49C9B8)
    /// Water, in the small widget's ring and the wide widget's level: an
    /// aqua blue, bluer than the protein teal so the two stay apart. The app
    /// has no water colour. At least 3:1 against the track and the widget
    /// background in both modes.
    static let water = dynamicColor(light: 0x1478A0, dark: 0x56C2E6)
    /// The ring colour of the calorie and nutrient rings, small and wide.
    /// The app's brand green. The extension has no AccentColor asset, so
    /// `Color.accentColor` would be the system blue here.
    static let ring = dynamicColor(light: 0x0E7A4D, dark: 0x34D08A)
}

private func dynamicColor(
    light: UInt32,
    dark: UInt32,
    lightAlpha: CGFloat = 1,
    darkAlpha: CGFloat = 1
) -> Color {
    Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: dark, alpha: darkAlpha)
            : UIColor(hex: light, alpha: lightAlpha)
    })
}

private func fixedColor(_ hex: UInt32, alpha: CGFloat = 1) -> Color {
    Color(UIColor(hex: hex, alpha: alpha))
}

private extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

/// The mark that says a figure is above its goal. It is a word-free symbol
/// in the figure's own line, so the state never depends on colour. The Dart
/// side adds the same fact to the VoiceOver sentence in words.
private enum WidgetCue {
    static let over = "\u{2191}"
}

// MARK: - Styles and themes

/// The background styles the Edit Widget sheet offers. The ids are stable
/// and the names come from the app, in its language.
private enum WidgetStyleId {
    static let system = "system"
    static let paper = "paper"
    static let dark = "dark"
    static let highContrast = "highContrast"
    static let all = [system, paper, dark, highContrast]

    /// Only until the app has written its own names.
    static func englishName(_ id: String) -> String {
        switch id {
        case paper: return "Paper"
        case dark: return "Dark"
        case highContrast: return "High contrast"
        default: return "System"
        }
    }
}

/// Everything a style decides, once: the container background, the two
/// text colours, the track, the stroke width, and the colour scheme the
/// fixed colours resolve in. The three accessibility settings and the
/// rendering mode adjust it in `make`.
private struct WidgetTheme {
    /// Nil is the system's own widget fill.
    var background: Color?
    var primary: Color
    var secondary: Color
    /// The unfilled part of a ring, a bar or the water level.
    var track: Color
    /// Extra stroke width in points, for Increase Contrast and the
    /// high-contrast style.
    var strokeBoost: CGFloat
    /// A style that forces a scheme, so the fixed colours resolve in it.
    var scheme: ColorScheme?
    /// An outline round the tracks, for Increase Contrast and Differentiate
    /// Without Colour.
    var outlined: Bool

    static func make(
        styleId: String,
        accented: Bool,
        increasedContrast: Bool,
        reduceTransparency: Bool,
        differentiate: Bool
    ) -> WidgetTheme {
        let paperSecondary = dynamicColor(light: 0x6E685E, dark: 0xA39E94)
        let darkSecondary = fixedColor(0xA39E94)
        let strongSecondary = dynamicColor(light: 0x404040, dark: 0xD0D0D0)
        var theme: WidgetTheme
        switch styleId {
        case WidgetStyleId.paper:
            theme = WidgetTheme(
                background: dynamicColor(light: 0xF7F4EF, dark: 0x1B1A18),
                primary: dynamicColor(light: 0x2B2A27, dark: 0xECE8E1),
                secondary: paperSecondary,
                // Light: about 10 percent, so the macro colours keep 3:1
                // against the track. Dark: 25 percent.
                track: dynamicColor(
                    light: 0x6E685E, dark: 0xA39E94,
                    lightAlpha: 0.10, darkAlpha: 0.25
                ),
                strokeBoost: 0,
                scheme: nil,
                outlined: false
            )
        case WidgetStyleId.dark:
            theme = WidgetTheme(
                background: fixedColor(0x1B1A18),
                primary: fixedColor(0xECE8E1),
                secondary: darkSecondary,
                track: fixedColor(0xA39E94, alpha: 0.25),
                strokeBoost: 0,
                scheme: .dark,
                outlined: false
            )
        case WidgetStyleId.highContrast:
            theme = WidgetTheme(
                background: dynamicColor(light: 0xFFFFFF, dark: 0x000000),
                primary: dynamicColor(light: 0x000000, dark: 0xFFFFFF),
                secondary: strongSecondary,
                track: dynamicColor(
                    light: 0x404040, dark: 0xD0D0D0,
                    lightAlpha: 0.12, darkAlpha: 0.25
                ),
                strokeBoost: 1,
                scheme: nil,
                outlined: true
            )
        default:
            theme = WidgetTheme(
                // The translucent system fill, or an opaque one when the
                // person turned Reduce Transparency on.
                background: reduceTransparency
                    ? dynamicColor(light: 0xF2F2F7, dark: 0x1C1C1E)
                    : nil,
                primary: .primary,
                secondary: .secondary,
                track: Color.secondary.opacity(0.25),
                strokeBoost: 0,
                scheme: nil,
                outlined: false
            )
        }
        if increasedContrast {
            theme.secondary = theme.primary.opacity(0.85)
            theme.strokeBoost = max(theme.strokeBoost, 1)
            theme.outlined = true
        }
        if differentiate {
            theme.outlined = true
        }
        if accented {
            // The system removes the background and paints the content with
            // its own white or tint, so nothing here may depend on hue. Text
            // is the system primary, and the arc is the accent group.
            theme.background = nil
            theme.primary = .primary
            theme.secondary = Color.primary.opacity(0.85)
            theme.track = Color.primary.opacity(increasedContrast ? 0.4 : 0.25)
            theme.scheme = nil
        }
        return theme
    }
}

private struct WidgetThemeKey: EnvironmentKey {
    static let defaultValue = WidgetTheme.make(
        styleId: WidgetStyleId.system,
        accented: false,
        increasedContrast: false,
        reduceTransparency: false,
        differentiate: false
    )
}

private extension EnvironmentValues {
    var widgetTheme: WidgetTheme {
        get { self[WidgetThemeKey.self] }
        set { self[WidgetThemeKey.self] = newValue }
    }
}

/// Reads the three accessibility settings and, from iOS 16, the rendering
/// mode, then gives the content its theme, its colour scheme and its
/// container background. The container background is the only place a
/// background is set from iOS 17, so a tinted or clear Home Screen can
/// replace it.
private struct ThemedRoot<Content: View>: View {
    var styleId: String
    var content: Content

    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiate

    var body: some View {
        if #available(iOSApplicationExtension 16.0, *) {
            RenderingModeReader(
                styleId: styleId,
                increasedContrast: contrast == .increased,
                reduceTransparency: reduceTransparency,
                differentiate: differentiate,
                content: content
            )
        } else {
            ThemeApplied(
                theme: .make(
                    styleId: styleId,
                    accented: false,
                    increasedContrast: contrast == .increased,
                    reduceTransparency: reduceTransparency,
                    differentiate: differentiate
                ),
                content: content
            )
        }
    }
}

@available(iOS 16.0, *)
private struct RenderingModeReader<Content: View>: View {
    var styleId: String
    var increasedContrast: Bool
    var reduceTransparency: Bool
    var differentiate: Bool
    var content: Content

    @Environment(\.widgetRenderingMode) private var mode

    var body: some View {
        ThemeApplied(
            theme: .make(
                styleId: styleId,
                accented: mode == .accented,
                increasedContrast: increasedContrast,
                reduceTransparency: reduceTransparency,
                differentiate: differentiate
            ),
            content: content
        )
    }
}

private struct ThemeApplied<Content: View>: View {
    var theme: WidgetTheme
    var content: Content

    var body: some View {
        content
            .environment(\.widgetTheme, theme)
            .forcingScheme(theme.scheme)
            .themedContainer(theme)
    }
}

/// Thin bar, consumed over goal, clamped to 0...1. A goal of zero or less
/// leaves the space empty so the cells stay level.
private struct NutrientBar: View {
    var progress: Double?
    var color: Color

    @Environment(\.widgetTheme) private var theme

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(theme.track)
                if let progress = progress {
                    Capsule()
                        .fill(color)
                        .frame(width: proxy.size.width * CGFloat(progress))
                        .accentable()
                }
            }
            .overlay {
                if theme.outlined {
                    Capsule().strokeBorder(theme.primary.opacity(0.5), lineWidth: 0.5)
                }
            }
        }
        .frame(height: 4 + theme.strokeBoost)
        .accessibilityHidden(true)
    }
}

/// The text styles of the wide widget's small figures. The macro amounts and
/// the water amount share `amount`, and the macro names and the water unit
/// share `name`, so the three never drift apart.
private enum WideTextStyle {
    static let amount = Font.caption2.weight(.semibold)
    static let name = Font.caption2
}

/// Water as a tall capsule that fills from the bottom, consumed over goal.
/// The top of the fill is flat, like a liquid level. A goal of zero or less
/// leaves the capsule empty. The fill is the accent group in a tinted or
/// clear Home Screen.
private struct WaterLevel: View {
    var progress: Double?

    @Environment(\.widgetTheme) private var theme

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                Rectangle().fill(theme.track)
                if let progress = progress {
                    Rectangle()
                        .fill(NutritionRowColors.water)
                        .frame(height: proxy.size.height * CGFloat(progress))
                        .accentable()
                }
            }
            .clipShape(Capsule())
            .overlay {
                if theme.outlined {
                    Capsule().strokeBorder(theme.primary.opacity(0.5), lineWidth: 0.5)
                }
            }
        }
        .frame(width: 24 + theme.strokeBoost)
        .accessibilityHidden(true)
    }
}

/// The wide widget, left to right: calories in a ring, the three macros
/// stacked, and water as a level at the trailing edge.
private struct NutritionRowView: View {
    var entry: CalorieEntry

    var body: some View {
        Group {
            if entry.showsNumbers {
                NutritionRowContent(entry: entry)
            } else {
                CalorieWidgetPlaceholder(
                    title: entry.labels.rowTitle,
                    message: entry.labels.openApp
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Text stops growing at xxxLarge, as in the small widgets. Above
        // that, a ring, three macro rows and a water level would no longer
        // fit one 4x2 widget. Every number shrinks before it is cut.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .themed(entry.styleId)
    }
}

/// The wide widget's figures. A separate view, so that it reads the theme
/// that `themed` puts in the environment.
private struct NutritionRowContent: View {
    var entry: CalorieEntry

    @Environment(\.widgetTheme) private var theme
    @Environment(\.dynamicTypeSize) private var typeSize
    /// From xLarge the ring gets smaller, so the macros keep their width.
    /// Every number stays.
    private var compact: Bool { typeSize >= .xLarge }

    /// The calorie figure in the ring: 4 pt under `title2` (22 pt at the
    /// default size), and it still scales with text size.
    @ScaledMetric(relativeTo: .title2) private var calorieSize: CGFloat = 18

    private let spacing: CGFloat = 10
    private var maxRing: CGFloat { compact ? 80 : 88 }

    private var macroRows: [(label: String, figure: AmountFigure, color: Color)] {
        let labels = entry.labels
        let reading = entry.reading
        return [
            reading.protein.map { (labels.protein, $0, NutritionRowColors.protein) },
            reading.fat.map { (labels.fat, $0, NutritionRowColors.fat) },
            reading.carbs.map { (labels.carbs, $0, NutritionRowColors.carbs) },
        ].compactMap { $0 }
    }

    var body: some View {
        GeometryReader { proxy in
            content(height: proxy.size.height)
                .frame(
                    width: proxy.size.width,
                    height: proxy.size.height,
                    alignment: .center
                )
        }
        .contentInset()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(entry.labels.rowAccessibility))
    }

    private func content(height: CGFloat) -> some View {
        let labels = entry.labels
        // The stroke is drawn 4 pt outside the ring's frame, so the frame
        // leaves 8 pt of the height and the column adds it back to its width.
        let ring = max(min(height - 8, maxRing), 0)
        let caloriesOver = entry.reading.goal > 0
            && entry.reading.consumed > entry.reading.goal
        return HStack(spacing: spacing) {
            ProgressRing(progress: calorieProgress, color: NutritionRowColors.ring) {
                FigureText(
                    value: "\(entry.reading.consumed)",
                    unit: caloriesOver ? "\(WidgetCue.over) \(labels.unit)" : labels.unit,
                    font: .system(size: calorieSize)
                )
            }
            .frame(width: ring, height: ring)
            .padding(4)
            .layoutPriority(1)
            if !macroRows.isEmpty {
                VStack(spacing: 10) {
                    ForEach(Array(macroRows.enumerated()), id: \.offset) { _, row in
                        MacroRow(
                            label: row.label,
                            figure: row.figure,
                            unit: labels.gram,
                            color: row.color,
                            namePriority: 1,
                            short: true
                        )
                    }
                }
                .frame(maxWidth: .infinity)
                // The text boxes carry empty space above the ink, so the
                // visible rows sit low. Measured in the render, in points.
                .offset(y: compact ? -2 : -1)
            } else {
                Spacer(minLength: 0)
            }
            if let water = entry.reading.water {
                // The level sits at the trailing edge with its label under
                // it: the number and the unit only. The goal is in the
                // VoiceOver sentence, and the level shows the progress. From
                // xLarge the unit goes first. The number never does.
                VStack(spacing: 4) {
                    WaterLevel(progress: water.progress)
                    VStack(spacing: 0) {
                        Text(verbatim: water.isOver ? "\(WidgetCue.over)\(water.value)" : "\(water.value)")
                            .font(WideTextStyle.amount)
                            .foregroundStyle(theme.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        if !compact {
                            Text(labels.milliliter)
                                .font(WideTextStyle.name)
                                .foregroundStyle(theme.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }
                    }
                }
                .layoutPriority(1)
                // The unit line carries empty space below its ink, so the
                // visible column sits high. Measured in the render.
                .offset(y: 2)
            }
        }
    }

    /// Consumed over goal, clamped to 0...1, as the small ring does.
    private var calorieProgress: Double {
        let goal = max(entry.reading.goal, 1)
        return min(max(Double(entry.reading.consumed) / Double(goal), 0), 1)
    }
}

/// One macro in the small macros widget: its name, grams over goal grams,
/// and a thin bar. The name and the numbers carry the meaning, so the bar
/// colour is never the only cue. A figure above its goal starts with the
/// arrow.
private struct MacroRow: View {
    var label: String
    var figure: AmountFigure
    var unit: String
    var color: Color
    /// The wide widget gives the name the room first, so at large text the
    /// numbers shrink and the name is never cut to an ellipsis.
    var namePriority: Double = 0
    /// The wide widget's shorter row: "102/116" with no unit and no spaces,
    /// in a smaller size. The name and the Dart sentence carry the rest.
    var short = false

    @Environment(\.widgetTheme) private var theme

    private var amount: String {
        let text: String
        if short {
            text = figure.goal > 0 ? "\(figure.value)/\(figure.goal)" : "\(figure.value)"
        } else {
            text = figure.goal > 0
                ? "\(figure.value) / \(figure.goal) \(unit)"
                : "\(figure.value) \(unit)"
        }
        return figure.isOver ? "\(WidgetCue.over)\(text)" : text
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(label)
                    .font(WideTextStyle.name)
                    .foregroundStyle(theme.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .layoutPriority(namePriority)
                Spacer(minLength: 4)
                // The numbers shrink before the name does, and are never cut.
                Text(amount)
                    .font(short ? WideTextStyle.amount : Font.caption.weight(.semibold))
                    .foregroundStyle(theme.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .layoutPriority(namePriority > 0 ? 0 : 1)
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
                .contentInset()
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(entry.labels.macrosAccessibility))
            } else {
                CalorieWidgetPlaceholder(
                    title: entry.labels.macrosTitle,
                    message: entry.labels.openApp
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Text stops growing at xxxLarge. Three one-line rows with their
        // bars and gaps are estimated to fit the small widget there; above
        // it they would not. This is an estimate, not a render.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .themed(entry.styleId)
    }
}

/// Today's water over its goal, in millilitres, in an aqua ring. The number
/// and the unit are always written.
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
                    accessibility: entry.labels.waterAccessibility,
                    overGoal: water.isOver
                )
            } else {
                CalorieWidgetPlaceholder(
                    title: entry.labels.water,
                    // Water is left out when there is no daily goal. If the
                    // app is up to date, say so instead of "Open the app".
                    message: (entry.showsNumbers && entry.reading.water == nil
                        ? entry.labels.waterNoGoal : nil) ?? entry.labels.openApp
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .themed(entry.styleId)
    }
}

private extension View {
    /// From iOS 17 the system already insets widget content, so the
    /// content adds nothing. Before that it has to leave its own 12 pt
    /// margin. Every widget view uses this, so none is inset twice.
    @ViewBuilder
    func contentInset(_ edges: Edge.Set = .all) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            self
        } else {
            padding(edges, 12)
        }
    }

    /// Gives the content the theme of the chosen style, and its container
    /// background.
    func themed(_ styleId: String) -> some View {
        ThemedRoot(styleId: styleId, content: self)
    }

    /// Puts the arc, the bar fill or the water level in the accent group of
    /// a tinted or clear Home Screen. A full-colour widget does not change.
    @ViewBuilder
    func accentable() -> some View {
        if #available(iOSApplicationExtension 16.0, *) {
            widgetAccentable()
        } else {
            self
        }
    }

    @ViewBuilder
    func forcingScheme(_ scheme: ColorScheme?) -> some View {
        if let scheme = scheme {
            environment(\.colorScheme, scheme)
        } else {
            self
        }
    }

    /// The only place a background is set from iOS 17. The system can then
    /// replace it with Liquid Glass or a tint. Before iOS 17 there is no
    /// container background, so a plain background is the fallback.
    @ViewBuilder
    func themedContainer(_ theme: WidgetTheme) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            if let background = theme.background {
                containerBackground(for: .widget) { background }
            } else {
                containerBackground(.fill.tertiary, for: .widget)
            }
        } else {
            background(theme.background ?? Color(.systemBackground))
        }
    }
}

// MARK: - Widgets

/// The kind strings of the four widgets, in one place. Dart reloads them by
/// name (`CalorieWidgetSnapshot`). They never change: the calorie kind keeps
/// a widget already on a Home Screen in place when the app is updated.
private enum CalorieWidgetKind {
    static let calories = "CalorieProgressWidget"
    static let row = "NutritionRowWidget"
    static let macros = "MacrosSmallWidget"
    static let water = "WaterSmallWidget"
}

/// iOS 15.5 to 16.x: the small calorie widget as it always was. It shows
/// calories, because choosing a nutrient needs an App Intent
/// configuration, which starts at iOS 17.
struct CalorieProgressWidget: Widget {
    let kind = CalorieWidgetKind.calories

    var body: some WidgetConfiguration {
        let labels = CalorieLabels.load()
        return StaticConfiguration(kind: kind, provider: CalorieProvider()) { entry in
            CalorieWidgetView(entry: entry)
        }
        .configurationDisplayName(labels.title)
        .description(labels.description)
        .supportedFamilies([.systemSmall])
    }
}

/// Calories, macros and water in one row, medium size only. It reads the
/// same snapshot and uses the same timeline as the ring widget, so the day
/// boundary and the "Open the app" placeholder behave the same.
struct OneRowNutritionWidget: Widget {
    let kind = CalorieWidgetKind.row

    var body: some WidgetConfiguration {
        let labels = CalorieLabels.load()
        return StaticConfiguration(kind: kind, provider: CalorieProvider()) { entry in
            NutritionRowView(entry: entry)
        }
        .configurationDisplayName(labels.rowTitle)
        .description(labels.rowDescription)
        .supportedFamilies([.systemMedium])
    }
}

/// Protein, fat and carbs in the small size. It reads the same snapshot and
/// uses the same timeline as the other widgets, so the day boundary and the
/// "Open the app" placeholder behave the same.
struct MacrosSmallWidget: Widget {
    let kind = CalorieWidgetKind.macros

    var body: some WidgetConfiguration {
        let labels = CalorieLabels.load()
        return StaticConfiguration(kind: kind, provider: CalorieProvider()) { entry in
            MacrosSmallView(entry: entry)
        }
        .configurationDisplayName(labels.macrosTitle)
        .description(labels.macrosDescription)
        .supportedFamilies([.systemSmall])
    }
}

/// Today's water in the small size, with the same timeline as the others.
struct WaterSmallWidget: Widget {
    let kind = CalorieWidgetKind.water

    var body: some WidgetConfiguration {
        let labels = CalorieLabels.load()
        return StaticConfiguration(kind: kind, provider: CalorieProvider()) { entry in
            WaterSmallView(entry: entry)
        }
        .configurationDisplayName(labels.water)
        .description(labels.waterDescription)
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Styled widgets (iOS 17)

/// The same three kinds, with a Style choice in the Edit Widget sheet. Each
/// keeps its kind string, so a widget already on a Home Screen stays in
/// place. Before iOS 17 the classic widgets above stay, with the system look.
@available(iOS 17.0, *)
struct StyledNutritionRowWidget: Widget {
    let kind = CalorieWidgetKind.row

    var body: some WidgetConfiguration {
        let labels = CalorieLabels.load()
        return AppIntentConfiguration(
            kind: kind,
            intent: StyleIntent.self,
            provider: StyleProvider()
        ) { entry in
            NutritionRowView(entry: entry)
        }
        .configurationDisplayName(labels.rowTitle)
        .description(labels.rowDescription)
        .supportedFamilies([.systemMedium])
    }
}

@available(iOS 17.0, *)
struct StyledMacrosSmallWidget: Widget {
    let kind = CalorieWidgetKind.macros

    var body: some WidgetConfiguration {
        let labels = CalorieLabels.load()
        return AppIntentConfiguration(
            kind: kind,
            intent: StyleIntent.self,
            provider: StyleProvider()
        ) { entry in
            MacrosSmallView(entry: entry)
        }
        .configurationDisplayName(labels.macrosTitle)
        .description(labels.macrosDescription)
        .supportedFamilies([.systemSmall])
    }
}

@available(iOS 17.0, *)
struct StyledWaterSmallWidget: Widget {
    let kind = CalorieWidgetKind.water

    var body: some WidgetConfiguration {
        let labels = CalorieLabels.load()
        return AppIntentConfiguration(
            kind: kind,
            intent: StyleIntent.self,
            provider: StyleProvider()
        ) { entry in
            WaterSmallView(entry: entry)
        }
        .configurationDisplayName(labels.water)
        .description(labels.waterDescription)
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Nutrient picker (iOS 17)

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
    /// Resolves by id and never loses one, so a saved choice survives a
    /// missing or older name list. A name the app did not write falls back
    /// to the fixed labels, and then to the id. The widget itself shows its
    /// placeholder for a nutrient it has no figure for.
    func entities(for identifiers: [String]) async throws -> [NutrientEntity] {
        let labels = CalorieLabels.load()
        return identifiers.map { NutrientEntity(id: $0, name: Self.name(for: $0, labels: labels)) }
    }

    /// Calories, the three macros, and the nutrients that are in the
    /// snapshot now, so the picker does not list ones the app hides. The
    /// order is the app's. Before the app has written a list, only
    /// calories and the macros are offered.
    func suggestedEntities() async throws -> [NutrientEntity] {
        let labels = CalorieLabels.load()
        let present = Set(CalorieReading.load().nutrients.keys)
        let fixed = [NutrientId.calories, NutrientId.protein, NutrientId.carbs, NutrientId.fat]
        var ids = fixed
        for entry in labels.nutrientNames where present.contains(entry.id) && !ids.contains(entry.id) {
            ids.append(entry.id)
        }
        return ids.map { NutrientEntity(id: $0, name: Self.name(for: $0, labels: labels)) }
    }

    /// Calories, built here so it does not depend on the app's name list.
    func defaultResult() async -> NutrientEntity? {
        NutrientEntity(
            id: NutrientId.calories,
            name: Self.name(for: NutrientId.calories, labels: CalorieLabels.load())
        )
    }

    private static func name(for id: String, labels: CalorieLabels) -> String {
        labels.displayName(forNutrient: id)
    }
}

/// One background style in the Edit Widget sheet. The names are the app's
/// own strings in the app's language, written into the App Group, so none
/// of them is Swift copy. Only the parameter's title is fixed English.
@available(iOS 17.0, *)
struct StyleEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Style")
    static let defaultQuery = StyleQuery()

    var id: String
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

@available(iOS 17.0, *)
struct StyleQuery: EntityQuery {
    /// Resolves by id. An id this extension does not know is left out, so a
    /// style from a newer app falls back to the default instead of failing.
    func entities(for identifiers: [String]) async throws -> [StyleEntity] {
        let labels = CalorieLabels.load()
        return identifiers
            .filter { WidgetStyleId.all.contains($0) }
            .map { StyleEntity(id: $0, name: labels.styleName(forStyle: $0)) }
    }

    func suggestedEntities() async throws -> [StyleEntity] {
        let labels = CalorieLabels.load()
        return WidgetStyleId.all.map {
            StyleEntity(id: $0, name: labels.styleName(forStyle: $0))
        }
    }

    /// The system look, built here so it does not depend on the app's names.
    func defaultResult() async -> StyleEntity? {
        StyleEntity(
            id: WidgetStyleId.system,
            name: CalorieLabels.load().styleName(forStyle: WidgetStyleId.system)
        )
    }
}

/// The Edit Widget sheet of the small calorie widget. No choice made means
/// calories in the system look.
@available(iOS 17.0, *)
struct NutrientIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Nutrient"

    @Parameter(title: "Nutrient")
    var nutrient: NutrientEntity?

    @Parameter(title: "Style")
    var style: StyleEntity?
}

/// The Edit Widget sheet of the widgets that have only a style to choose.
@available(iOS 17.0, *)
struct StyleIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Style"

    @Parameter(title: "Style")
    var style: StyleEntity?
}

@available(iOS 17.0, *)
private struct StyleProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> CalorieEntry {
        CalorieEntries.placeholder()
    }

    func snapshot(for configuration: StyleIntent, in context: Context) async -> CalorieEntry {
        CalorieEntries.snapshot(
            isPreview: context.isPreview,
            styleId: configuration.style?.id
        )
    }

    func timeline(for configuration: StyleIntent, in context: Context) async -> Timeline<CalorieEntry> {
        CalorieEntries.timeline(styleId: configuration.style?.id)
    }
}

@available(iOS 17.0, *)
private struct NutrientProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> CalorieEntry {
        CalorieEntries.placeholder()
    }

    func snapshot(for configuration: NutrientIntent, in context: Context) async -> CalorieEntry {
        CalorieEntries.snapshot(
            nutrientId: configuration.nutrient?.id ?? NutrientId.calories,
            isPreview: context.isPreview,
            styleId: configuration.style?.id
        )
    }

    func timeline(for configuration: NutrientIntent, in context: Context) async -> Timeline<CalorieEntry> {
        CalorieEntries.timeline(
            nutrientId: configuration.nutrient?.id ?? NutrientId.calories,
            styleId: configuration.style?.id
        )
    }
}

/// iOS 17 and later: the same widget, with the nutrient chosen in its Edit
/// Widget sheet. It has the same kind as the classic one, and the day
/// boundary and placeholder come from the same code.
@available(iOS 17.0, *)
struct NutrientCalorieWidget: Widget {
    let kind = CalorieWidgetKind.calories

    var body: some WidgetConfiguration {
        let labels = CalorieLabels.load()
        return AppIntentConfiguration(
            kind: kind,
            intent: NutrientIntent.self,
            provider: NutrientProvider()
        ) { entry in
            CalorieWidgetView(entry: entry)
        }
        .configurationDisplayName(labels.title)
        .description(labels.description)
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Bundles

/// The widgets on iOS 17 and later: the small calorie widget with its
/// Edit Widget picker.
@available(iOS 17.0, *)
private struct CalorieWidgetBundleModern: WidgetBundle {
    var body: some Widget {
        NutrientCalorieWidget()
        StyledNutritionRowWidget()
        StyledMacrosSmallWidget()
        StyledWaterSmallWidget()
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

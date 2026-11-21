# iOS calorie widget

A small, read-only Home Screen widget shows today's calories eaten, the daily goal, and a progress ring. It reads an App Group snapshot written when Home finishes loading. It does not open the encrypted Hive database.

Android stores the same snapshot and has no widget UI yet. That work is tracked separately.

## One-row nutrition widget

A second widget shows calories, protein, fat, carbs and water side by side. Calories are a ring of completion with the amount and unit inside it and no goal line. The three macros are stacked rows that read like "102/116". Water is a tall level gauge at the trailing edge, filled from the bottom, with its amount and unit under it. Its kind is `NutritionRowWidget`. It supports the medium family only. It is declared in `CalorieWidget.swift` next to the ring widget and is part of the same extension and the same widget bundle.

It reads the same snapshot, the same labels and the same timeline as the ring widget. The day boundary and the "Open the app" placeholder are shared code. Each write from the app reloads both kinds.

The snapshot gains two optional parts. Both are left out when the app has no figure:

- `macros`: `protein`, `carbs` and `fat`, each `{"g": consumed grams, "goalG": goal grams}`. The ring widget's data already had this.
- `water`: `{"ml": consumed millilitres, "goalMl": goal millilitres}`. It is left out when the goal is zero or less.

All figures are whole numbers. Water is stored in millilitres. The fluid-ounce preference is not applied, just as the kilojoule preference is not applied to calories. A region whose figure is missing is not drawn. A goal of zero or less draws the number without a bar.

The labels travel the same way as before. The language-only labels gain `water`, `milliliter`, `rowTitle` and `rowDescription`. The figure labels gain `rowAccessibility`, one VoiceOver sentence with every figure. It is written only when macros and water are both present. Otherwise the widget reads the calorie sentence. Old and new writes decode in old and new extensions, because every new field is optional.

From `xLarge` the ring gets smaller and the water label drops its unit, so the numbers keep their room. Text stops growing at `xxxLarge`. The goal of each figure is in the VoiceOver sentence.

The stored keys do not name a platform. Android does not show this widget. Its provider ignores the new keys.

## Small widgets

Three widgets use the small size. That is the 2x2 slot on the Home Screen. With the one-row widget, the extension has four widget kinds:

- `CalorieProgressWidget`: small. Calories as a ring. On iOS 17 and later it can show another nutrient.
- `NutritionRowWidget`: medium. A calorie ring, stacked macros and a water level.
- `MacrosSmallWidget`: small. Protein, fat and carbs as three rows.
- `WaterSmallWidget`: small. Water as a ring.

All four read the same snapshot. They share the day boundary and the "Open the app" placeholder. Each write from the app reloads every kind.

### Nutrient picker

The kind `CalorieProgressWidget` is unchanged. A widget already on a Home Screen stays there. To pick a nutrient, long-press the widget and choose Edit Widget. Calories are the default.

The picker needs iOS 17. It is an App Intent configuration. The extension targets iOS 15.5. Below iOS 17 the widget is the one it always was, and it shows calories.

The extension picks one of two widget bundles at start-up. `WidgetBundleBuilder` accepts `if #available` but not `else`. Both versions of this widget have the same kind, so both cannot be listed.

The picker offers calories, protein, carbs, fat and the nutrients of the Diary panel that are in the snapshot now. A nutrient the person hid in the app is not offered. The app writes the names into the language labels as an ordered list of `{id, name}`. The names are in the app's own language. The widget's query reads that list. No name is Swift copy.

A saved choice is never lost. The query resolves an id even when the name list is missing. Then it uses the fixed label for calories or a macro, and else the id. The default is built as calories, and the parameter is optional. No choice means calories.

Two strings are fixed English: the intent's title and its parameter label. App Intents reads those at build time.

If a nutrient has a goal, the widget shows its amount, its unit, "of GOAL" and a ring. If it has no goal, the widget shows the amount alone.

The amount and the goal phrase come from the app as strings, with one format: up to one decimal, no digit grouping, and the decimal mark of the app's language. So a cell reads "3456,7" over "von 3500". Before the app has written them, the widget uses one ungrouped format for both.

If the chosen nutrient is not in the snapshot, the widget shows its name and a line. If the app is up to date, the line is "Not shown in the app". That happens when the person hid the nutrient. Before the app has written, or after a write from an older app, the line is "Open the app".

### Placeholders and the gallery

Every widget shows its own name as the title of its placeholder: Calories or the chosen nutrient, Macros, Water, or Nutrition. The line under it is "Open the app", except for two cases. A nutrient that the app does not show says "Not shown in the app". Water with no daily goal says "No water goal set". Both lines are language-only labels, written by the app. A write from an older app has neither, so the widget says "Open the app".

In the widget gallery and the Edit Widget picker, a widget with no current figures shows a made-up sample with numbers. The sample covers all four kinds and every nutrient the picker offers. It is never used on a Home Screen. Its names and goal phrases are English until the app has written its own names.

### Macros and water

The macros widget shows three rows. Each row has the name, grams over goal grams, and a thin bar. The colours are the app's macro colours.

The water widget shows millilitres over the goal in an aqua ring. The app has no water colour, so the extension defines one: `1478A0` in light mode and `56C2E6` in dark mode. The wide widget's water level uses the same colour.

If the app wrote no macros, the macros widget shows the placeholder. If it wrote no water, the water widget does.

### Text size and insets

The ring, macros and water widgets stop growing text at `xxxLarge`. Above that, the number and unit inside the ring, and three rows in the small widget, would not fit. The numbers also shrink before they are cut. This cap applies to the old calorie widget too. Its text no longer grows above `xxxLarge`. The wide widget stops at `xxxLarge` too, and from `xLarge` it drops the water unit. The calorie and nutrient rings use the app's brand green, `0E7A4D` in light mode and `34D08A` in dark mode, because the extension has no accent colour asset. The water ring and level use the aqua blue. The sizes were checked in the iOS 27 simulator.

From iOS 17 the system insets widget content. Below iOS 17 each widget adds 12 pt itself. One helper does this for every view, so no widget is inset twice.

### Background styles

On iOS 17 and later every widget has a Style choice in its Edit Widget sheet. Before iOS 17 the widgets keep the system look. The four styles are:

- System: the standard widget background. This is the default, so nothing changes until a person picks another style.
- Paper: the app's warm canvas, `F7F4EF` in light mode and `1B1A18` in dark mode, with the app's text colours. It follows the system appearance.
- Dark: always the app's dark canvas `1B1A18` with the dark colours, also in light mode.
- High contrast: white with black text in light mode and black with white text in dark mode, with bars 1 pt thicker.

The three widgets that had no setting before (Macros, Water and the wide Nutrition widget) moved from a static configuration to an App Intent configuration on iOS 17 and later. They keep their kind strings, so a widget already on a Home Screen stays in place and shows the system look until a style is chosen. The small calorie widget gets the same Style parameter next to Nutrient. The style also applies to the placeholder and to the gallery sample.

The style names are written by the app in its language, as a `styles` list of id and name in the language-only labels. The extension offers them as an `AppEntity`, so they are translated through the ARB files. An older write has no list, and the extension then offers the English words System, Paper, Dark and High contrast. Two strings stay English because App Intents reads them at build time: the intent title and the parameter title "Style". The ids are `system`, `paper`, `dark` and `highContrast`. An id the extension does not know is the system look.

### Tinted and clear Home Screens, and accessibility

From iOS 18 a person can pick a tinted or a clear Home Screen. The system then removes the widget background and paints the content in white or the tint. The background is set only with `containerBackground`, so the system can replace it. The ring arcs, the bar fills and the water level are marked as the accent group. The tracks and the text are the primary group. In that mode the text uses the system primary colour, and secondary labels use it at 85 percent, whatever style was chosen. Nothing depends on hue.

- Increase Contrast: strokes are 1 pt thicker, the tracks get a thin outline, and secondary text is the primary colour at 85 percent.
- Differentiate Without Colour: the tracks get the same outline. Every bar already has its name and numbers, and the water level has its number.
- Reduce Transparency: the System style uses an opaque fill instead of the translucent one.
- Above the goal: a figure above its goal starts with an arrow, for example "↑ 96/86", and the goal line of a ring reads "↑ of 38". The Dart sentences add the same fact in words, for example "fat is over the goal."
- VoiceOver is still one sentence per widget, written by Dart.

Every fill reaches 3:1 against its track and against the widget fill in every style, and the secondary text reaches 4.5:1. The System style uses an explicit grey, `606060`, for secondary text in light mode, and a very light track in light mode (the track is close to the fill colour on purpose, because a darker track lowers the contrast of the fill against it). The Paper and High contrast styles do the same with their own tracks. The cost is a faint track, about 1.1:1 against the background, so the numbers carry the goal. Increase Contrast and Differentiate Without Colour outline the tracks.

### New snapshot fields

The snapshot gains one optional key. If the app has no figure, the key is left out:

- `nutrients`: a list of `{"id", "consumed", "goal", "unit"}`. The id is a key from the Diary nutrient panel, such as `fiber` or `vitamin_b12`. `consumed` and `goal` have one decimal, in the unit of the nutrient. `unit` is `g`, `mg` or `µg`. If there is no goal, `goal` is left out. If the person hid a nutrient, it is not in the list.

The goal is the one the Diary panel shows. It is the goal set for the day. If there is none, it is the reference for the person's age and gender. If there is none of those, it is the published default.

Calories and the three macros are not repeated in this list. The widget takes them from `consumed`, `goal` and `macros`.

The unit rule is the existing one. The kilojoule and fluid-ounce preferences are not applied.

The label rule is the existing one too:

- `ont_calorie_labels` holds the language-only labels. It gains `macrosTitle`, `macrosDescription`, `waterDescription`, `nutrientNotShown`, `waterNoGoal` and `nutrients`. The last is the ordered list of names.
- The snapshot holds the labels that describe figures. They are `macrosAccessibility`, `waterAccessibility`, `waterGoal` and `nutrients`. The last is a map from id to `{"value", "goal", "accessibility"}`. `value` is written only for the panel nutrients. The macros are whole numbers, and the widget prints those itself. If the nutrient has no goal, the goal phrase is left out.
- If the language changes, the app rewrites both. Home does not need to reload.

Every new field is optional. A write from an older app decodes in the new extension. A new write decodes in an older one.

The extension reads `macros`, `water`, `labels` and `nutrients` through a decoder that skips a value of the wrong shape. Each macro row and each entry of the label map is skipped alone. The figure fields are read as numbers with a fraction and rounded, so `9.5` in a gram field does not make the snapshot unreadable. The calorie figures `consumed` and `goal` must be whole numbers. If either has a fraction or the wrong type, the whole snapshot is unreadable and every widget shows its placeholder.

Home does not read the intakes again. It sums the intakes it already holds, with the same code as the panel. It reads the tracked day once more, for the goals the person set. If that read fails, the goals fall back to the references.

### Not covered

These widgets are for iOS only. This change does not touch the Android provider or its layout. The provider ignores the new keys.

## App Group

Each flavor has its own App Group, so a develop install (for example `just dev_seed`) next to the App Store build can never overwrite or clear that build's widget:

- full: `group.com.opennutritracker.ont.opennutritracker`
- develop: `group.com.opennutritracker.ont.opennutritracker.develop`

The extension bundle ids are:

- full: `com.opennutritracker.ont.opennutritracker.widget`
- develop: `com.opennutritracker.ont.opennutritracker.develop.widget`

They were `….CalorieWidget` until 2.5.0's release. That id turned out to be registered to another developer team, and bundle ids are unique across Apple, so the release team could not register it. The Xcode target is still called `CalorieWidget`; only the bundle id changed.

Each flavor's parent app id must stay a prefix of its extension id.

The group is chosen by build configuration. Every Runner and CalorieWidget configuration sets the build setting `ONT_APP_GROUP_ID`; both entitlement files grant `$(ONT_APP_GROUP_ID)`, and the extension's `Info.plist` passes it to Swift as `ONTAppGroupId`. The Dart side picks the same group from the running bundle id (`CalorieWidgetSnapshot.appGroupIdFor`: a `.develop` suffix means the develop group). The two Dart constants and the build settings must stay the same strings.

## Local development

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Select the Runner target, then Signing & Capabilities. Confirm the App Groups capability lists the group for the flavor you build. Repeat for the CalorieWidget target.
3. For a simulator build, the entitlement file in the project is enough. Sign with your Apple team if Xcode asks. The project file records the maintainer team used for release; a local debug build can use another team as long as both targets share it.
4. Run the app once so Home writes today's numbers, then add the Calories widget from the Home Screen.

The widget shows "Open the app" until that first write, and again after the configured day boundary, until the app writes the new day.

## Release signing

App Store and TestFlight archives, and develop builds on a device, need both groups and both extension bundle ids registered on the Apple Developer team that signs OpenNutriTracker (`DEVELOPMENT_TEAM` `79AJPC6DP3`).

1. In Certificates, Identifiers & Profiles, create both App Groups: `group.com.opennutritracker.ont.opennutritracker` and `group.com.opennutritracker.ont.opennutritracker.develop`.
2. Enable the full group on `com.opennutritracker.ont.opennutritracker`, and the develop group on `com.opennutritracker.ont.opennutritracker.develop`.
3. Register the two extension bundle ids and enable the matching group on each: the full group on the full extension, the develop group on the develop extension.
4. Regenerate the signing profiles (the project uses fastlane match for Release and Profile) so the new ids and the group are included. `ios/fastlane/Matchfile` lists the full extension id, and the `build` lane signs the `CalorieWidget` target with `match AppStore com.opennutritracker.ont.opennutritracker.widget`. CI runs match read-only, so that profile has to exist in the match repository before the next release: run `MATCH_READONLY=false bundle exec fastlane ios certs` from `ios/` once, and make sure the Runner profile is regenerated too, since it now carries the App Group. Debug stays on automatic signing.
5. Archive from the `full` scheme. The extension is embedded by the Runner target.

`flutter build ios --no-codesign` does not need those profiles. A signed archive does.

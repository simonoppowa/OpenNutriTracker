# iOS calorie widget

A small, read-only Home Screen widget shows today's calories eaten, the daily goal, and a progress ring. It reads an App Group snapshot written when Home finishes loading. It does not open the encrypted Hive database.

Android stores the same snapshot and has no widget UI yet. That work is tracked separately.

## One-row nutrition widget

A second widget shows calories, carbs, fat, protein and water in one horizontal row. Its kind is `NutritionRowWidget`. It supports the medium family only. It is declared in `CalorieWidget.swift` next to the ring widget and is part of the same extension and the same widget bundle.

It reads the same snapshot, the same labels and the same timeline as the ring widget. The day boundary and the "Open the app" placeholder are shared code. Each write from the app reloads both kinds.

The snapshot gains two optional parts. Both are left out when the app has no figure:

- `macros`: `protein`, `carbs` and `fat`, each `{"g": consumed grams, "goalG": goal grams}`. The ring widget's data already had this.
- `water`: `{"ml": consumed millilitres, "goalMl": goal millilitres}`. It is left out when the goal is zero or less.

All figures are whole numbers. Water is stored in millilitres. The fluid-ounce preference is not applied, just as the kilojoule preference is not applied to calories. A cell whose figure is missing is not drawn. A goal of zero or less draws the number without a bar.

The labels travel the same way as before. The language-only labels gain `water`, `milliliter`, `rowTitle` and `rowDescription`. The figure labels gain `rowAccessibility`, one VoiceOver sentence with every figure. It is written only when macros and water are both present. Otherwise the widget reads the calorie sentence. Old and new writes decode in old and new extensions, because every new field is optional.

From the larger Dynamic Type sizes the cells wrap onto two lines. Text stops growing at `accessibility1`.

The stored keys do not name a platform. Android does not show this widget. Its provider ignores the new keys.

## Small widgets

Three widgets use the small size. That is the 2x2 slot on the Home Screen. With the one-row widget, the extension has four widget kinds:

- `CalorieProgressWidget`: small. Calories as a ring. On iOS 17 and later it can show another nutrient.
- `NutritionRowWidget`: medium. Calories, macros and water in one row.
- `MacrosSmallWidget`: small. Protein, fat and carbs as three rows.
- `WaterSmallWidget`: small. Water as a ring.

All four read the same snapshot. They share the day boundary and the "Open the app" placeholder. Each write from the app reloads every kind.

### Nutrient picker

The kind `CalorieProgressWidget` is unchanged. A widget already on a Home Screen stays there. To pick a nutrient, long-press the widget and choose Edit Widget. Calories are the default.

The picker needs iOS 17. It is an App Intent configuration. The extension targets iOS 15.5. Below iOS 17 the widget is the one it always was, and it shows calories.

The extension picks one of two widget bundles at start-up. `WidgetBundleBuilder` accepts `if #available` but not `else`. Both versions of this widget have the same kind, so both cannot be listed.

The picker offers calories, protein, carbs, fat and the ten nutrients of the Diary panel. The app writes their names into the language labels as an ordered list of `{id, name}`. The names are in the app's own language. The widget's query reads that list. No name is Swift copy.

Two strings are fixed English: the intent's title and its parameter label. App Intents reads those at build time.

If a nutrient has a goal, the widget shows its amount, its unit, "of GOAL" and a ring. If it has no goal, the widget shows the amount alone. If the chosen nutrient is not in the snapshot, the widget shows the placeholder. That happens when the person hid the nutrient in the app settings, and before the app has written.

### Macros and water

The macros widget shows three rows. Each row has the name, grams over goal grams, and a thin bar. The colours are the app's macro colours.

The water widget shows millilitres over the goal in a neutral ring. The app has no water colour.

If the app wrote no macros, the macros widget shows the placeholder. If it wrote no water, the water widget does. Text stops growing at `accessibility1`.

### New snapshot fields

The snapshot gains one optional key. If the app has no figure, the key is left out:

- `nutrients`: a list of `{"id", "consumed", "goal", "unit"}`. The id is a key from the Diary nutrient panel, such as `fiber` or `vitamin_b12`. `consumed` and `goal` have one decimal, in the unit of the nutrient. `unit` is `g`, `mg` or `µg`. If there is no goal, `goal` is left out. If the person hid a nutrient, it is not in the list.

The goal is the one the Diary panel shows. It is the goal set for the day. If there is none, it is the reference for the person's age and gender. If there is none of those, it is the published default.

Calories and the three macros are not repeated in this list. The widget takes them from `consumed`, `goal` and `macros`.

The unit rule is the existing one. The kilojoule and fluid-ounce preferences are not applied.

The label rule is the existing one too:

- `ont_calorie_labels` holds the language-only labels. It gains `macrosTitle`, `macrosDescription`, `waterDescription` and `nutrients`. The last is the ordered list of names.
- The snapshot holds the labels that describe figures. They are `macrosAccessibility`, `waterAccessibility`, `waterGoal` and `nutrients`. The last is a map from id to `{"goal", "accessibility"}`. If the nutrient has no goal, the goal phrase is left out.
- If the language changes, the app rewrites both. Home does not need to reload.

Every new field is optional. A write from an older app decodes in the new extension. A new write decodes in an older one. If a value has the wrong shape, the extension skips it. It never drops the calorie figures.

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

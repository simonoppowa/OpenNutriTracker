# iOS calorie widget

A small, read-only Home Screen widget shows today's calories eaten, the daily goal, and a progress ring. It reads an App Group snapshot written when Home finishes loading. It does not open the encrypted Hive database.

Android stores the same snapshot and has no widget UI yet. That work is tracked separately.

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

# App Store screenshots — en-US

Twelve captioned assets: six at 1290x2796 (6.9" iPhone) and six at 2064x2752
(13" iPad), in the order #1072 specifies. Captions come from
`tools/screenshots/captions.en-US.json` and are composited by
`tools/screenshots/compose.py`, which is shared with the Play set.

## Where these came from

Captured by hand on a Mac with `xcrun simctl io booted screenshot`.

There was a dispatch-only macOS CI lane for this. It never worked and has been
removed (#1076): it drove the app with `flutter test`, and `flutter test`
uninstalls the app when it finishes, so iOS deleted the data container the
capture had been written into. Three dispatches confirmed it — the app was
absent from `simctl listapps` while 131 unrelated containers survived, and
every PNG left on the device belonged to the GeoServices cache.

`simctl io` writes host-side, so nothing has to survive the sandbox, which is
why the manual route worked first time. Reviving CI capture would mean
`flutter drive` + `onScreenshot`; that was judged not worth the macOS runner
budget against a cap of five concurrent macOS jobs (#1016) for a set that is
re-shot about once a release.

`integration_test/store_screenshots_test.dart` is still here, but for what it
encodes rather than as a working way to get files: the shot order, the
finders, the demo fixture, and the assertions that refuse to capture a
loading or banner-covered frame.

It cannot hand you the images. `takeScreenshot` writes into the app's
Documents directory — `getApplicationDocumentsDirectory()` — and `flutter
test` uninstalls the app on exit, so the container goes and the PNGs with it.
That is the same defect that killed the lane, and it belongs to the test
rather than to CI: running it by hand hits it too, on an Android emulator as
readily as on an iOS simulator. Exporting means the `flutter drive` +
`onScreenshot` conversion above.

## Two frames still owed

- **`03-micronutrients`, both devices.** The card is scrolled to a position
  where its own header is half-cut by the app bar. On iPhone that slices the
  `Day | Week` segmented control through the middle of the glyphs; on iPad it
  leaves two orphaned calendar rows with the month header gone. Both read as
  a rendering fault rather than a scroll position.
- **`04-trends`, iPhone only.** The caption is "See the pattern, not the
  day", and the frame shows a Calories chart that is a flat zigzag along the
  goal line with no axis labels — no pattern to see. The iPad frame of the
  same screen scrolls far enough to reach the Weight chart, which has a real
  curve. Scroll the iPhone capture to match, or change the caption.

The other nine are good as they stand.

## Only with a release

App Store Connect will not take screenshots against a released version. It is
read-only: every field on the version page reports `disabled`, Save is
disabled, and Media Manager renders no upload target at all. Screenshots need
a version in "Prepare for Submission", and that version needs a build before
it can be submitted — so the listing change ships with a release rather than
on its own. This is the answer to #1080.

Play is not like this, which is easy to over-generalise from: a listing-only
edit there went through to the live listing with no binary
(`.github/workflows/play-screenshots.yml`).

## What 2.4.0 shipped

2.4.0 (build 66, submitted 2026-10-02) carries nine of the twelve — the three
owed frames above were left out:

| Slot | Files, in listing order |
| :-- | :-- |
| iPhone 6.9" | `01-home`, `02-diary-meals`, `05-diary-calendar`, `06-profile` |
| iPad 13" | `01-home`, `02-diary-meals`, `06-profile`, `04-trends`, `05-diary-calendar` |

The iPad order differs from the file order and was accepted as it stands.
The 6.5" and 5.5" iPhone slots are empty; 5.5" had held a legacy set from
2.2.0, removed so no older device shows it.

## Uploading on an editable version

- **The 1290x2796 set goes in the 6.9" slot, not 6.5".** The 6.5" slot rejects
  it — it accepts only 1242x2688 and 1284x2778. Media Manager did not list a
  6.9" slot at first, on the released v2.2.0 or on the new 2.4.0, while the
  6.5" slot held the 2.2.0 images; it was there after the 6.5" set had been
  deleted. Which of the two made it appear is not known. Once 6.9" is filled,
  6.5" reads "Using 6.9" Display" and stops being required.
- **"Add for Review" locks the screenshots.** Choose File and Delete All
  disappear. Remove the version from the Draft Submission panel (the item's
  Delete button — the version and its metadata survive), edit, and add it
  again.
- **Listing order is the order Apple finishes processing, not the order the
  files were chosen.** A multi-file upload landed reversed, and
  `02-diary-meals` came out last on both devices even uploaded one at a time.
  Check the order after the upload and drag to fix it.

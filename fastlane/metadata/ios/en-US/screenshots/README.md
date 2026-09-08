# App Store screenshots — en-US

Twelve captioned assets: six at 1290x2796 (6.9" iPhone) and six at 2064x2752
(13" iPad), in the order #1072 specifies. Captions come from
`tools/screenshots/captions.en-US.json` and are composited by
`tools/screenshots/compose.py`, which is shared with the Play set.

## Where these came from

Captured by hand on a Mac with `xcrun simctl io booted screenshot`, not by
`.github/workflows/ios-screenshots.yml`.

That is not a preference. The CI lane cannot currently get an image off the
simulator: it drives the app with `flutter test`, and `flutter test`
uninstalls the app when it finishes, so iOS deletes the data container the
capture was written into. Three dispatches confirmed it — the app was absent
from `simctl listapps` while 131 unrelated containers survived, and every PNG
left on the device belonged to the GeoServices cache. `simctl io` sidesteps
the whole problem by writing host-side, which is why the manual route worked
first time. Fixing the lane means converting it to `flutter drive` +
`onScreenshot`; see #1076.

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

## These cannot be uploaded yet

App Store Connect will not accept them against v2.2.0. A released version is
read-only: every field on the version page reports `disabled`, Save is
disabled, and Media Manager renders no upload target at all. Screenshots need
a version in "Prepare for Submission", and that version needs a build before
it can be submitted — so the listing change ships with the next release
rather than on its own. This is the answer to #1080.

Play is not like this, which is easy to over-generalise from: a listing-only
edit there went through to the live listing with no binary
(`play-screenshots.yml`).

## One thing to confirm on an editable version

The iPad set matches App Store Connect's **13" Display** slot exactly. The
iPhone side is less certain: Media Manager for this app lists 6.5", 6.3",
6.1", 5.5", 4.7", 4" and 3.5" and shows **no 6.9" slot** — checked twice,
with no "6.9" anywhere in the page text — while 1290x2796 is Apple's 6.9"
size. Older app records did accept 1290x2796 under the 6.5" slot, so this may
be a non-issue, but it cannot be settled against a read-only page. Check it
before assuming the iPhone set drops straight in.

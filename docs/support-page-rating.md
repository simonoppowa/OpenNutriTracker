# Support page: in-app review prompt vs store-listing link

Research notes for [#1528](https://github.com/simonoppowa/OpenNutriTracker/issues/1528), part of the Support page map [#1526](https://github.com/simonoppowa/OpenNutriTracker/issues/1526). The question: how do the native review prompts on Android and iOS behave, and how does that compare with linking to the store listing, for a **user-tapped "Rate the app" row** (the app never prompts unasked). Written against `main` at `2.6.0+68` (`ca8f51de`). Every source was read on **2026-11-07**; URLs are in [Sources](#sources).

## Verdict

**Use a plain store link through `url_launcher`. Don't call the native prompt, and don't add `in_app_review`.**

Both stores tell developers not to call the native prompt from a button. The prompt is quota-limited, can silently not appear, and neither API tells the app whether it appeared. A "Rate the app" row backed by it would sometimes do nothing when tapped. Apple's docs recommend the alternative directly: a persistent link in settings with `action=write-review`. Google says the same in other words: "redirect the user to the Play Store instead".

`url_launcher` is already a dependency, and the `<queries>` entry for `https` VIEW intents is already in `android/app/src/main/AndroidManifest.xml`, so the link needs no new package and no manifest change. `in_app_review`'s `openStoreListing()` does the same thing the link does (see [§3](#3-the-flutter-package-in_app_review)). Adding the package would also pull two libraries onto F-Droid's non-free list into the Android build.

| | Android: Play In-App Review API | Android: store link | iOS: `requestReview` (StoreKit) | iOS: store link |
| --- | --- | --- | --- | --- |
| What the user sees | Rating card over the app (1–5 stars, optional comment) | Play Store app on the OpenNutriTracker listing; user scrolls to the rating section | System rating alert over the app (stars, optional review) | App Store app on the **write-a-review form** |
| Quota | Time-bound; exact value undocumented and "can be changed by Google Play without any notice"; more than one call in "less than a month" might not show | None | At most **3 times per 365 days** per app if the user hasn't rated on this device; after rating, only for a new version and after 365 days | None |
| Silently doesn't show when | Quota reached; already reviewed; app not in user's Play library; no Play Store / sideloaded Play Store; enterprise account; non-primary account selected | — (only if no handler for the URL) | Quota reached; user turned off review requests for all apps; **TestFlight builds (no effect at all)** | — |
| Can the app tell it showed? | **No.** "The API does not indicate whether the user reviewed or not, or even whether the review dialog was shown." | Only that the URL launched | **No.** The call returns nothing, and the docs say it "may not present an alert" | Only that the URL launched |
| Calling it from a button | **Forbidden by guidance:** "you should not have a call-to-action option (such as a button) to trigger the API" | Recommended for that case | **Forbidden by guidance:** "don't call it in response to a button tap or other user action" | Recommended for that case ("persistent link … in your app's settings") |
| Dependency | `com.google.android.play:review` (Play Core, proprietary) | None (`url_launcher`, already present) | StoreKit (system framework) | None (`url_launcher`, already present) |
| F-Droid scanner (SUSS) | `com.google.android.play:review` → NonFree | Clean | n/a | n/a |
| Fits "never prompts unasked" | Only if user-triggered, which the guidance forbids | Yes | Only if user-triggered, which the guidance forbids | Yes |

**Platform gap:** iOS has a documented URL that opens the review form directly. Google Play has none: its current link reference documents only the listing URL. On Android the row lands on the listing page and the user scrolls to the rating section.

---

## 1. The exact links for this app

| Platform | Use this | Opens |
| --- | --- | --- |
| iOS | `https://apps.apple.com/app/id6451490901?action=write-review` | App Store write-a-review form for OpenNutriTracker |
| Android | `https://play.google.com/store/apps/details?id=com.opennutritracker.ont.opennutritracker` | Play Store listing (no documented review-form deep link exists) |
| Android, legacy scheme | `market://details?id=com.opennutritracker.ont.opennutritracker` | Play Store app only; **not in Google's current URL table** (see below) |

**App Store id `6451490901`** comes from the repo, not the web: `README.md:46` and `README.md:234` link `https://apps.apple.com/us/app/opennutritracker/id6451490901`. Checked live: that URL returns 200 with the title "OpenNutriTracker App - App Store", and `https://apps.apple.com/app/id6451490901` redirects to it. `ios/fastlane/Appfile` only carries the bundle id, not the numeric id. The URL shape `https://apps.apple.com/app/id<ID>?action=write-review` is the one in Apple's own sample code ("Requesting App Store reviews", section *Manually request a review*), and it's the exact string `in_app_review` builds on iOS.

**Play package id** `com.opennutritracker.ont.opennutritracker` (`README.md:234`). The listing URL returned 200 on 2026-11-07.

**About `market://`.** Google's "Linking to Google Play" page now documents only the `https://play.google.com/store/apps/details?id=` form for listings. Its URL summary table lists `market://` only for `market://launch` (Play Instant). For opening the Play Store app rather than a browser, Google recommends the https URL plus `Intent.setPackage("com.android.vending")`. `url_launcher` can't set the target package. The practical choice from Dart is the https URL launched as an external app; `market://` stays an undocumented fallback. Which app actually catches the https link on a given phone (Play Store or browser) **was not checked on a device** and belongs in the implementation ticket's device check.

## 2. Native prompt behaviour, per platform

### Android: Play In-App Review API

- **Requirements:** Android 5.0 (API 21)+ with the Google Play Store installed, or ChromeOS with Play Store. This app's `minSdkVersion` is 26.
- **Quota:** "Google Play enforces a time-bound quota on how often a user can be shown the review dialog … calling the `launchReviewFlow` method more than once during a short period of time (for example, less than a month) might not always display a dialog." The value "is an implementation detail, and it can be changed by Google Play without any notice."
- **Button guidance (verbatim):** "you should not have a call-to-action option (such as a button) to trigger the API, as a user might have already hit their quota and the flow won't be shown, presenting a broken experience to the user. For this use case, redirect the user to the Play Store instead."
- **No feedback to the app:** Google's own sample says: "The API does not indicate whether the user reviewed or not, or even whether the review dialog was shown." On error: "do not inform the user or change your app's normal user flow."
- **Other rules:** no questions before or during the prompt ("Do you like the app?" or "Would you rate this app 5 stars"). The card must be shown unmodified with no overlay, and must not be removed programmatically.
- **When it silently fails** (Google's troubleshooting table): app not in the user's Play library; non-primary account selected in Play; protected/enterprise account; user already reviewed; quota reached; sideloaded or broken Play Store / Play Services.
- **Testing:** quota is not enforced on the internal test track. On internal app sharing, reviews "can't be submitted" (the button is disabled).
- **Data safety:** Play Core declares that it collects the rating and free-text review and sends them to the Play Store.

### iOS: `SKStoreReviewController` / `AppStore.requestReview` / `RequestReviewAction`

- **API status:** `SKStoreReviewController` is deprecated (iOS 18.0); its replacements are `AppStore.requestReview(in:)` (iOS 16+, UIKit scene) and SwiftUI's `RequestReviewAction` (iOS 16+).
- **Quota (verbatim, same text on all three APIs):** "If the person hasn't rated or reviewed your app on this device, StoreKit displays the ratings and review request a maximum of three times within a 365-day period." and "If the person has rated or reviewed your app on this device, StoreKit displays the ratings and review request if the app version is new, and if more than 365 days have passed since the person's previous review."
- **User opt-out:** people "can also opt out of receiving these prompts for all apps they have installed" (HIG).
- **Button guidance (verbatim):** "Because this API may not present an alert, don't call it in response to a button tap or other user action." The "Requesting App Store reviews" article adds: "Avoid requesting a review as the result of a user action."
- **No feedback to the app:** the call returns nothing. Apple says only that it "may not present an alert" and that "App Store policy governs the actual display".
- **Testing:** always shown in development builds; "no effect in apps that you distribute for beta testing using TestFlight."
- **Persistent link endorsed (verbatim):** "you may include a persistent link to your App Store product page in your app's settings or configuration screens. Append the query parameter `action=write-review` to your product page URL to automatically open the App Store page where users can write a review."
- **App Review Guideline 5.6.1:** "Use the provided API to prompt users to review your app … we will disallow custom review prompts." A settings row that opens the App Store isn't a custom in-app prompt. Apple's own StoreKit docs describe exactly this link as the user-initiated path. Guideline 3.2.2(x) also bans forcing a rating to unlock functionality, which the Support page doesn't do.

## 3. The Flutter package: `in_app_review`

- **Package:** [`in_app_review`](https://pub.dev/packages/in_app_review) 2.0.12 (published 2026-05-15), publisher `britannio.dev`, repo [`britannio/in_app_review`](https://github.com/britannio/in_app_review) (not archived; master `ab14e637`, 2026-05-15). 160/160 pub points.
- **Licence:** MIT (`in_app_review/LICENSE`, "Copyright (c) 2020 Britannio Jarrett"). Compatible with this repo's GPL-3.0.
- **Platforms:** Android, iOS, macOS (`pubspec.yaml` plugin block). `openStoreListing()` also covers Windows via `url_launcher`. Android needs API 21+ and the Play Store.
- **What it pulls in on Android** (`in_app_review/android/build.gradle:54-57`):
  - `com.google.android.play:review:2.0.2` and `review-ktx:2.0.2`: Play Core, **NonFree** in F-Droid's SUSS ("Google Play Core", gradle signature `com.google.android.play:review`, code signature `com/google/android/play/review`).
  - `com.google.android.gms:play-services-base:18.7.2`: **NonFree** in SUSS ("Google Mobile Services", code signature `com/google/android/gms`). Added in commit `d258bcba` (2023-09-16) so `isAvailable()` can check Play Services.
  - The platform interface also depends on `url_launcher ^6.1.0` and `platform ^3.0.0`.
  - F-Droid is already blocked by ML Kit (`docs/fdroid-submission-feasibility.md`). This package would add two more non-free hits that a FOSS build flavour would have to strip.
- **`requestReview()`:** Android calls `requestReviewFlow()` then `launchReviewFlow()` and returns `null` either way. Its own comment says "The API does not indicate whether the user reviewed or if the dialog was shown." iOS calls `AppStore.requestReview(in:)` on 16+, `SKStoreReviewController.requestReview(in:)` on 14+, and returns `nil` immediately. The README warns against "Triggering this via a button in your app".
- **Does `openStoreListing()` cover the write-review deep link?**
  - **iOS/macOS: yes.** It builds `https://apps.apple.com/app/id\(storeId)?action=write-review` (`InAppReviewPlugin.swift:73`) and opens it with `UIApplication.shared.open`. `appStoreId` is required, or it throws `no-store-id`.
  - **Android: no.** It fires a plain `Intent.ACTION_VIEW` on `https://play.google.com/store/apps/details?id=$packageName` (`InAppReviewPlugin.kt:136-137`), without `setPackage("com.android.vending")`, so it's the same listing link `url_launcher` would open. There is no review-form link on Play to cover.
  - The README itself recommends `openStoreListing()` "if you want to permanently provide a button or other call-to-action", because "it isn't restricted by a quota".

**Conclusion for this app:** for a tapped row, the only part of `in_app_review` worth using is `openStoreListing()`, and it adds nothing over two hard-coded URLs and `url_launcher`. The package costs two non-free Android libraries and a Play Core data-collection declaration. The map's no-tracking, outbound-link-only stance argues against that.

## 4. Open items for the implementation ticket

1. On a real Android phone, check which app opens `https://play.google.com/store/apps/details?id=…` from `url_launcher` (Play Store vs browser) under each `LaunchMode`, and whether a `market://` fallback is worth adding. Not verified here.
2. On a real iPhone, check that the `action=write-review` link opens the review form. The simulator has no App Store app, per the `in_app_review` README.
3. Non-store installs (debug builds, any future F-Droid build): decide whether the row is hidden or still opens the store listing.

## Sources

All read 2026-11-07.

| Source | URL |
| --- | --- |
| Google: In-app reviews overview (quotas, button guidance, device requirements) | https://developer.android.com/guide/playcore/in-app-review |
| Google: Integrate in-app reviews (Kotlin/Java) | https://developer.android.com/guide/playcore/in-app-review/kotlin-java |
| Google: Test in-app reviews (troubleshooting table) | https://developer.android.com/guide/playcore/in-app-review/test |
| Google: Linking to Google Play | https://developer.android.com/distribute/marketing-tools/linking-to-google-play |
| Apple: `SKStoreReviewController` (deprecation) | https://developer.apple.com/documentation/storekit/skstorereviewcontroller |
| Apple: `SKStoreReviewController.requestReview()` | https://developer.apple.com/documentation/storekit/skstorereviewcontroller/requestreview() |
| Apple: `SKStoreReviewController.requestReview(in:)` | https://developer.apple.com/documentation/storekit/skstorereviewcontroller/requestreview(in:) |
| Apple: `AppStore.requestReview(in:)` | https://developer.apple.com/documentation/storekit/appstore/requestreview(in:)-1q8qs |
| Apple: `RequestReviewAction` | https://developer.apple.com/documentation/storekit/requestreviewaction |
| Apple: Requesting App Store reviews (sample, `action=write-review` URL) | https://developer.apple.com/documentation/storekit/requesting-app-store-reviews |
| Apple: HIG, Ratings and reviews | https://developer.apple.com/design/human-interface-guidelines/ratings-and-reviews |
| Apple: App Review Guidelines (3.2.2, 5.6.1, 5.6.3) | https://developer.apple.com/app-store/review/guidelines/ |
| pub.dev: `in_app_review` | https://pub.dev/packages/in_app_review |
| GitHub: `britannio/in_app_review` (source, README, LICENSE, CHANGELOG) | https://github.com/britannio/in_app_review |
| F-Droid SUSS signature database | https://fdroid.gitlab.io/fdroid-suss/suss.json |
| App Store listing (id check) | https://apps.apple.com/us/app/opennutritracker/id6451490901 |
| Play listing (id check) | https://play.google.com/store/apps/details?id=com.opennutritracker.ont.opennutritracker |

Apple's doc pages render client-side. Their text was read from the matching DocC JSON under `https://developer.apple.com/tutorials/data/documentation/storekit/…json` (and `…/tutorials/data/design/human-interface-guidelines/ratings-and-reviews.json`).

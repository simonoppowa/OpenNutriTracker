# In-app tips on the App Store and Google Play

Research notes for [#1533](https://github.com/simonoppowa/OpenNutriTracker/issues/1533) ("What does it take to offer one-time in-app tips on both stores?"), part of the Support page map [#1526](https://github.com/simonoppowa/OpenNutriTracker/issues/1526). It builds on the decision in [#1530](https://github.com/simonoppowa/OpenNutriTracker/issues/1530): *Donate* is a tip jar of consumable, one-time tips that unlock nothing, sold through In-App Purchase on iOS and Play Billing on Android. Tip count, amounts and the post-tip screen are [#1534](https://github.com/simonoppowa/OpenNutriTracker/issues/1534)'s job and are not decided here.

Written against `main` at `ca8f51de` (version `2.6.0+68`, Flutter 3.44.6 / Dart 3.12.2 via FVM). Every store and plugin source below was read on **2026-11-07**. None of the Apple or Google help pages read carried a revision date. Plugin facts come from the published pub.dev archives and Google's Maven POM, not from summaries. Anything not confirmed from a primary source is listed under [Not verified](#not-verified).

## Verdict

**Doable with the first-party plugin and no server. Three things gate it, and none of them is code:**

1. **Store paperwork has to come first.** On Apple: the Paid Apps Agreement, tax forms and banking. Sandbox testing doesn't work until the agreement is signed. On Google: a payments profile, plus an app build containing the billing library published to a test track **before** any product can be created.
2. **Selling tips probably makes the maintainer a "trader" under the EU Digital Services Act on both stores.** Both stores name in-app purchases as a sign of trader status. For an individual trader, both stores **publish a postal address and phone number** on the EU product page. Apple accepts a P.O. Box for individuals. Google needs the declaration from every account by **2027-02-01** in any case. This is a personal-privacy decision for the maintainer, not a technical one.
3. **The Android build gains a closed-source Google library.** `in_app_purchase_android` 0.5.5 pulls in Play Billing Library 9.1.0 (Android SDK License). That library depends on `play-services-base`, `play-services-location` and Google's `datatransport` telemetry pipeline, and it adds the `com.android.vending.BILLING` permission. The README's permission list and its "zero advertising or analytics SDKs" wording need checking against that. The Data safety answer depends on whether the library sends anything itself, which wasn't checked here (see [5.3](#53-the-dependency-question-left-open)).

Everything else is routine:

- The plugin (`in_app_purchase` 3.3.1, BSD-3-Clause) uses StoreKit 2 on every iOS version this app supports (15.5+) and Play Billing 9.1.0 on Android. Its minimums (iOS 13, Android API 23) are below the app's.
- A consumable tip needs no receipt server and no Restore button.
- Neither privacy label changes, as long as the app sends nothing about the purchase anywhere (Sentry included). On Android that also depends on point 3.

The plugin source shows one trap: **Android auto-consume only remembers products bought in the current app process.** A tip that finishes after an app restart (a pending payment, or a kill mid-purchase) comes back as `restored` and is never consumed. The user then can't buy that tip again, and Google auto-refunds it after three days. The app has to query and consume leftover tips at startup itself ([6.2](#62-android-pending-purchases-and-the-auto-consume-gap)).

---

## Implementation checklist

### A. Accounts and agreements (maintainer, before code lands)

**Apple (App Store Connect → Business):**

- [ ] **Account Holder signs the Paid Apps Agreement.** This can't be undone. You can't create an In-App Purchase until the latest version is accepted, and the agreement must be active to submit one.
- [ ] **Tax forms.** A US tax form is required for every developer. Non-US developers answer a questionnaire that picks W-8BEN, W-8BEN-E or W-8ECI. The forms can't be edited in App Store Connect once submitted. Roles: Account Holder, Admin or Finance.
- [ ] **Banking.** Needs the agreement signed and all tax forms submitted first. Payments go to one bank only, with the account in the name of the enrolled individual, entered exactly as the bank has it. Use an IBAN.
- [ ] **App Store Small Business Program**, for the 15% commission. Requires the Account Holder, the latest Paid Apps Agreement, and a list of any associated developer accounts. The rate applies from 15 days after the end of the fiscal month in which enrolment is approved, so enrol before launch.
- [ ] **DSA trader status for this app** (Business → compliance). Revenue from In-App Purchases is one of Apple's listed trader indicators. An individual trader must provide an address (P.O. Box allowed), phone and email, which Apple publishes on the product page in all 27 EU territories. Declaring non-trader means EU users are told consumer-protection rights don't apply.

**Google (Play Console):**

- [ ] **Payments profile.** Needs a legal name and a physical address (no P.O. Box), and is auto-linked to Play Console once created. The business country can't be changed later.
- [ ] **Bank account** in the same country as the payments profile, plus merchant tax info. Google determines, charges and remits EU VAT. Play prices in Germany are tax-inclusive.
- [ ] **Service fee.** The 15% tier needs manual enrolment (account group, terms), but the page read says it covers only the "remaining markets". For the EEA, UK and US, the regional table read on 2026-11-07 lists a higher service fee for one-time products plus a 5% billing fee (see [4.2](#42-google)). Confirm in Play Console before quoting a figure to users.
- [ ] **Trader declaration** before 2027-02-01. A trader with an individual account has a phone number and address displayed. "Remuneration for your apps", including in-app purchases, is a listed indicator.
- [ ] **License testers** added in Play Console for whoever runs device tests.

### B. Store product setup

Use the **same product IDs on both stores** so the Dart side has one constant set. Example: `tip_small`, `tip_medium`, `tip_large`, with amounts from #1534. Product IDs can never be reused on either store, even after deletion.

**App Store Connect** (Apps → app → Monetization → In-App Purchases → +):

- [ ] Type **Consumable**.
- [ ] Reference name: up to 64 characters, editable at any time without review.
- [ ] Product ID: letters, numbers, `-`, `.` and `_`, up to 100 characters. It can't be edited after saving.
- [ ] Price: pick a base country (Germany), and Apple generates the other storefronts. Up to 800 price points are available by default, and a price must be set before submission.
- [ ] Localisation for at least one language: display name 2–30 characters, description up to 45 characters. Changes to them need review. More languages can follow from the ARBs.
- [ ] **App Review screenshot**: one screenshot of the tip jar that shows what is offered. Reviewers use it, and it is never shown on the store. It can be replaced but not removed.
- [ ] Review notes (up to 4000 characters): say the tips unlock nothing, where the Support page is, and that the develop build hides it.
- [ ] **Submit the first consumable together with a new app version.** Later consumables can go in without one. Changes take up to an hour to reach the sandbox.

**Play Console:**

- [ ] **Publish an AAB that contains the billing library to any track first.** The internal track is enough. Google says this step is what unlocks product configuration.
- [ ] Create one-time products ("managed products" / "in-app products" in Play Console):
  - Product ID: must start with a number or lowercase letter, and may contain lowercase letters, numbers, `_` and `.`. It can't be changed or reused, and `android.test*` is reserved. The help page gives no length limit.
  - Title up to 55 characters (25 recommended); description up to 200 characters.
  - Default price, converted to local prices.
  - EEA withdrawal-right field set to `DIGITAL_CONTENT` or `SERVICE`.
  - Then **Activate**. A product must be active to be purchasable, even in an unpublished app.
- [ ] Draft and internal-track purchases are subject to spend limits. Use a closed track if testing hits them.

### C. Code

- [ ] Add `in_app_purchase: ^3.3.1`. It resolves `in_app_purchase_storekit` 0.4.17 and `in_app_purchase_android` 0.5.5. Make sure the lock file has **storekit ≥ 0.4.17**: its changelog fixes "purchases never completing on iOS 27 and iPadOS 27". The Android package needs Flutter ≥ 3.44.0 and Dart ^3.12.0, which the pinned 3.44.6 / 3.12.2 satisfies.
- [ ] **Subscribe to `InAppPurchase.instance.purchaseStream` at app start**, not only when the Support page opens. The plugin README says to listen "as early as possible … including the ones from the previous app session". StoreKit redelivers unfinished transactions at launch.
- [ ] Call `isAvailable()` before showing tips. If it returns `false`, hide the tip jar. On Android the external links still show; on iOS show nothing.
- [ ] Call `queryProductDetails(ids)`. If `notFoundIDs` is non-empty or there's an error, drop the missing tiers. If nothing loads, treat it like `isAvailable() == false`.
  - Show only the store-formatted `ProductDetails.price`, never a hard-coded amount. Play's Payments policy §6 requires in-app pricing to match the billing UI.
  - Sort by `rawPrice`.
- [ ] `buyConsumable(purchaseParam: …)`, leaving `autoConsume` at its default `true`.
- [ ] Handle each status in the stream:
  - `pending`: say the payment is waiting and don't thank yet.
  - `purchased`: thank the user.
  - `error`: short message.
  - `canceled`: nothing.
  - Always call `completePurchase` when `pendingCompletePurchase` is true. On Android, unacknowledged purchases are refunded after three days. On iOS, unfinished transactions block re-buying the same product and are redelivered at every launch.
- [ ] **Android: at startup (and on resume), call `restorePurchases()` and consume every tip that comes back** with `InAppPurchaseAndroidPlatformAddition.consumePurchase(...)`. On Android this method returns unconsumed purchases as `restored`. The reason is the auto-consume gap in [6.2](#62-android-pending-purchases-and-the-auto-consume-gap).
- [ ] **No Restore button and no receipt validation.** Consumables aren't restorable, and nothing is unlocked that needs protecting ([2.3](#23-restore-and-receipt-validation)).
- [ ] **Never log or report `PurchaseDetails`.** It carries `verificationData`, which is the purchase token on Android and the signed transaction on iOS. Keep it out of `logging` output and Sentry breadcrumbs. Otherwise the [privacy answers](#d-privacy-declarations) stop holding.
- [ ] Decide what, if anything, the app stores after a tip (#1534). A local "has tipped" flag in Hive stays on the device. Anything sent off-device changes the privacy answers.
- [ ] Re-check the Android merged manifest after adding the plugin (`build/app/intermediates/merged_manifests/…`). Expect:
  - `com.android.vending.BILLING`.
  - `ACCESS_NETWORK_STATE`, unless another plugin already adds it.
  - `<queries>` entries for the billing service and Play Billing Lab.
  - Two non-exported `ProxyBillingActivity` activities.
  - Billing-version meta-data.

### D. Privacy declarations

- [ ] **App Store privacy label: no change**, provided nothing about a purchase leaves the device through the app. Apple defines "collect" as transmitting off the device, and says "You are not responsible for disclosing data collected by Apple." *Purchase History* stays undeclared, and `PrivacyInfo.xcprivacy` gains nothing.
- [ ] **Play Data safety: no change for the payment itself.** Data collected by "Google Play's billing system" need not be declared if the app never accesses it and the payment service collects it directly. *Purchase history* is not collected, because the app doesn't transmit it. **Open condition:** SDK transmissions count as the app's. Confirm what Play Billing 9.1.0's `datatransport` dependency sends before answering "no change" ([5.3](#53-the-dependency-question-left-open)). Then update [`play-data-safety.md`](play-data-safety.md).
- [ ] **README → Privacy:**
  - Add tips to the "What leaves your device" table: the payment goes to Apple or Google under their terms, and the app sees only the product ID, status and a token it doesn't store.
  - Add the billing permission to the **Permissions** line.
  - Re-read the "**Free**" row ("No paid tier", "zero advertising or analytics SDKs"). A tip unlocks nothing, so "no paid tier" still holds. The SDK sentence depends on the `datatransport` finding.
- [ ] **Formal privacy policy (iubenda, `docs/privacy-policy/`):** consider adding Apple and Google as payment processors. This is a recommendation; no source read today requires it.

### E. Device tests

**iOS** (TestFlight or a development-signed build with a Sandbox Apple Account; TestFlight always runs in sandbox, so no real charges):

- [ ] Each tip completes, the thank-you shows, and buying the same tip again works.
- [ ] Cancel in the payment sheet: no message, no thanks.
- [ ] **Interrupted purchase**: enable "Interrupt Purchases for This Tester" in App Store Connect, buy, accept terms, then confirm the purchase arrives and is finished.
- [ ] Kill the app after paying, before the thank-you. On relaunch the transaction is redelivered and finished, with no duplicate thanks.
- [ ] Airplane mode on opening Support: the tip jar is hidden or shows a neutral state, and nothing crashes.
- [ ] `develop` scheme (`…opennutritracker.develop` bundle ID, which has no products): the tip jar is hidden.

**Android** (license tester; the `full` flavour, because the package name must match Play's):

- [ ] "Test instrument, always approves": tip granted, consumed, and buyable again.
- [ ] "Test instrument, always declines": no thanks.
- [ ] **"Slow test card, approves after a few minutes"**: kill the app while pending, wait, relaunch. The tip is consumed at startup and is buyable again.
- [ ] "Slow test card, declines after a few minutes": restart and confirm nothing is granted.
- [ ] Play Console → Orders: no test order refunded. License-tester purchases that aren't acknowledged are refunded after **3 minutes**.
- [ ] `develop` flavour (`.develop` application ID) and a device without the Play Store: the tip jar is hidden and the external links still show.
- [ ] The GitHub-release APK installed over nothing: the expected result is hidden, because billing is "blocked for apps that aren't signed and uploaded to Google Play".

---

## Evidence

### 1. The plugin

| Package | Version (pub.dev, 2026-11-07) | Role | Licence |
| --- | --- | --- | --- |
| `in_app_purchase` | 3.3.1 (2026-09-18) | App-facing API; depends on `_android ^0.5.0`, `_storekit ^0.4.0` | BSD-3-Clause (Flutter Authors) |
| `in_app_purchase_android` | 0.5.5 (2026-10-19) | Play Billing; `com.android.billingclient:billing:9.1.0`, `minSdk = 23`; Flutter ≥ 3.44.0, Dart ^3.12.0 | BSD-3-Clause |
| `in_app_purchase_storekit` | 0.4.17 (2026-11-04) | StoreKit; `s.ios.deployment_target = '13.0'` | BSD-3-Clause |
| `com.android.billingclient:billing` | 9.1.0 | Google's billing client | "Android Software Development Kit License" (POM) |

**StoreKit 1 vs 2.** StoreKit 2 has been the default since storekit 0.4.0 ("StoreKit 2 is now the default for all devices that support it"), and `_useStoreKit2 = true` in `in_app_purchase_storekit_platform.dart`. StoreKit 1 remains only "as the fallback on iOS < 15". This app's iOS target is 15.5 (`ios/Podfile`, `IPHONEOS_DEPLOYMENT_TARGET` for Runner), so it always runs StoreKit 2.

**Play Billing.** Billing 9.1.0 is the version in the plugin's `build.gradle` and the one Google's integration page currently shows. Google's deprecation table gives version 9 a "new app and update deadline" of 2028-08-31 (version 8: 2027-08-31). The 0.5.5 changelog notes that Billing 9 reports `billingUnavailable` (previously `error`) when the Play Store is blocked by the system, for example OEM kids mode.

**Minimum OS.** The plugin's README table says "SDK 24+" for Android and "13.0+" for iOS, while its Gradle file says `minSdk = 23`. The app is at `minSdkVersion 26` (`android/app/build.gradle:74`) and iOS 15.5, so there is no conflict either way.

**What it adds to the Android build.** This was read from the AAR manifests and POM on Google's Maven:

- `billing-9.1.0.aar` declares `com.android.vending.BILLING`.
- It adds `<queries>` for `com.android.vending.billing.InAppBillingService.BIND` and the Play Billing Lab override service.
- It adds two non-exported `ProxyBillingActivity` / `ProxyBillingActivityV2` activities and `com.google.android.play.billingclient.version` meta-data.
- Compile-scope dependencies: `androidx.activity`, `androidx.core`, `com.google.android.datatransport:transport-api/-backend-cct/-runtime` (3.x), and `com.google.android.gms:play-services-base/-basement/-location (19.0.0)/-tasks`.
- `transport-backend-cct` and `transport-runtime` declare `INTERNET` and `ACCESS_NETWORK_STATE`. `play-services-location` 19.0.0 declares no permissions.

Bundle IDs and application IDs for the two flavours are `com.opennutritracker.ont.opennutritracker` (`full`) and `…opennutritracker.develop` (`develop`), on both platforms (`android/app/build.gradle` `productFlavors`, `ios/Runner.xcodeproj/project.pbxproj`).

### 2. Products

#### 2.1 App Store Connect

From [In-App Purchase information](https://developer.apple.com/help/app-store-connect/reference/in-app-purchases-and-subscriptions/in-app-purchase-information):

- Reference name: "can include any characters and can be as long as 64 characters".
- Product ID: "can contain letters, numbers, hyphens, periods, and underscores, and can be as long as 100 characters", "isn't editable after you save", "can't be reused … even if you delete the original".
- Display name: "at least two characters and no more than 30 characters".
- Description: "no more than 45 characters".
- App Review screenshot: "used for review only and isn't displayed on the App Store".
- Review notes: "should not exceed 4000 characters".

From [Set a price](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/set-a-price-for-an-in-app-purchase): "up to 800 price points by default", generated across "174 storefronts and 43 currencies" from one base country, and "You'll need to set pricing … before you submit it for review."

From [Submit an In-App Purchase](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase): "The first consumable, non-consumable, auto-renewable subscription, and non-renewing subscription In-App Purchase of each type must be submitted with a new app version."

#### 2.2 Play Console

From [Create an in-app product](https://support.google.com/googleplay/android-developer/answer/1153481?hl=en):

- Product IDs "must start with a number or lowercase letter". They can't be changed or reused, and `android.test` is reserved.
- Title "up to 55 characters" (25 recommended); description "up to 200 characters".
- Single default price with locally converted prices.
- EEA withdrawal-right value `DIGITAL_CONTENT` or `SERVICE`.
- "Activate".
- The page also lists a 512 × 512 icon among the fields. That wasn't checked against the live console.

From [Getting ready](https://developer.android.com/google/play/billing/getting-ready): you "must publish a version of your app that includes the Google Play Billing Library. This step is required to enable billing-related features in the Google Play Console", and any track, including internal, will do. You also need a payments profile linked to the developer account.

#### 2.3 Restore and receipt validation

- **Apple.** [Guideline 3.1.1](https://developer.apple.com/app-store/review/guidelines/#in-app-purchase) asks for "a restore mechanism for any restorable in-app purchases". Consumables aren't restorable: [`Transaction.all`](https://developer.apple.com/documentation/storekit/transaction/all) "excludes finished consumables (unless refunded or revoked)" by default. The plugin README agrees: "the App Store does not have any APIs for querying consumable products".
- **Google.** The [integration guide](https://developer.android.com/google/play/billing/integrate) recommends server-side consumption only "if your app has a secure backend". It says "If your app is client-only without a backend, use `consumeAsync()`", which "fulfill[s] the acknowledgement requirement". For a tip that grants nothing, a forged purchase gains the forger nothing, so no server is warranted.

### 3. Review rules

**Apple** ([App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)):

- 3.1.1: "Apps may use in-app purchase currencies to enable customers to "tip" the developer or digital content providers in the app."
- 2.1(b): in-app purchases must be "complete, up-to-date, visible to the reviewer and functional". If a configured item "cannot be found or reviewed in your app, explain the reason in your review notes". This is why the review notes should say where the Support page is, and why products must not be hidden from the reviewer by a storefront or flavour check.
- iOS shows no external donation links (decided in #1530). The tip jar is the whole Donate way on iOS.

**Google** ([Payments policy](https://support.google.com/googleplay/android-developer/answer/9858738?hl=en)):

- §2 puts "payment for access to in-app features or services" in scope.
- §6: "Developers must clearly and accurately inform users about the terms and pricing" and "In-app pricing must match the pricing displayed in the user-facing Play billing interface."
- The policy says nothing specific about tips sold through Play Billing.
- The external Sponsors and Ko-fi links shown next to the tip jar on Android rely on the peer-to-peer reading established in [the donation-policy note](https://github.com/simonoppowa/OpenNutriTracker/blob/research/support-page-donations/docs/support-page-donation-links.md).

### 4. Accounts

#### 4.1 Apple

- [Sign and update agreements](https://developer.apple.com/help/app-store-connect/manage-agreements/sign-and-update-agreements): "To sell your apps on the App Store or offer In-App Purchases, the Account Holder must sign the Paid Apps Agreement". Also: "Once you've accepted the terms of this agreement, you can't undo this action", and "You won't be able to create a new app or In-App Purchase until you've agreed to the most recent version".
- [Provide tax information](https://developer.apple.com/help/app-store-connect/manage-tax-information/provide-tax-information): "All developers must complete a US tax form". Outside the US, "the W-8BEN, W-8BEN-E, or W-8ECI may be required", picked by questionnaire. "In order to submit tax forms, you first need to sign the Paid Apps Agreement." The country-specific sections seen (Australia, Brazil, Canada, Ireland, …) include none for Germany.
- [Enter banking information](https://developer.apple.com/help/app-store-connect/manage-banking-information/enter-banking-information): "You must submit all required tax forms … in order for us to process banking information". "enter the bank account number of the legal entity or individual enrolled". "You may only receive payments at one bank."
- [Small Business Program](https://developer.apple.com/app-store/small-business-program/): "a reduced commission rate of 15% … on Apple In-App Purchases". Eligible up to 1 million USD in proceeds. Enrolment needs the Account Holder and acceptance of the latest Paid Apps agreement. Proceeds are adjusted "fifteen (15) days after the end of the fiscal calendar month in which your enrollment is approved". The page doesn't state the standard rate.
- [DSA trader requirements](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements):
  - Trader indicators include "if your app includes In-App Purchases".
  - Individuals provide "Address or P.O. Box, Phone number, Email address".
  - "Apple will publish this information on your App Store product page when your app is distributed in any of the 27 territories of the EU."
  - Status can be set per app.

#### 4.2 Google

- [Create a payments profile](https://support.google.com/googleplay/android-developer/answer/7161426?hl=en): legal name, physical address ("We don't allow you to use a PO box address"). It's auto-linked to Play Console. The bank account must be in the profile's country, and "You can't change your business location country."
- [Tax rates and VAT](https://support.google.com/googleplay/android-developer/answer/138000?hl=en): "Google is responsible for determining, charging, and remitting VAT" for EU purchases through Play billing. Germany supports tax-inclusive pricing.
- [Service fees](https://support.google.com/googleplay/android-developer/answer/112622?hl=en):
  - Remaining markets: "15% for the first $1M (USD) revenue earned by the developer each year".
  - EEA, UK and US (rollout date 2026-06-30): a separate regional table. Read as best the flattened table allowed, "other transactions" for the first $1M carry a 20% (new installs) or 25% (existing installs) service fee plus a 5% billing fee. Lower rates apply in Google's Apps Experience programme.
- [15% tier enrolment](https://support.google.com/googleplay/android-developer/answer/10632485?hl=en): manual, via an account group and the tier's terms.
- [Trader status declaration](https://support.google.com/googleplay/android-developer/answer/17594752?hl=en):
  - Trader indicators include "you receive or intend to receive remuneration for your apps".
  - "if you have an individual account and are a trader, a phone number and address will now be displayed".
  - Existing accounts "must submit the declaration by February 1, 2027".

### 5. Privacy

#### 5.1 App Store

[App privacy details](https://developer.apple.com/app-store/app-privacy-details/):

- "'Collect' refers to transmitting data off the device in a way that allows you and/or your third-party partners to access it".
- Purchase History is "An account's or individual's purchases or purchase tendencies".
- "You are not responsible for disclosing data collected by Apple."
- For payment info: "If your app uses a payment service, the payment information is entered outside your app, and you as the developer never have access to the payment information, it is not collected".

The page doesn't mention In-App Purchase by name. The no-change answer follows from the "collect" definition plus the not-responsible-for-Apple line.

#### 5.2 Play Data safety

[Data safety form help](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en):

- "'Collect' means transmitting data from your app off a user's device."
- If you use "Google Play's billing system, or similar services", you "don't need to declare collection of the data that the payment service collects" when "Your app never accesses this information" and "The payment service collects this information directly from the user". It adds that you "should also consider whether your app collects other financial information, like purchase history".
- Collection includes "user data transmitted off device from your app by libraries and/or SDKs used in your app".

#### 5.3 The dependency question left open

Billing 9.1.0's POM lists `transport-backend-cct` (Google's client-side telemetry transport) and `play-services-location` as compile dependencies. No page read today says whether the billing library uses them to send its own diagnostics, or what it would send. Under the Data safety SDK rule above, that decides whether the form and the README's "no analytics SDKs" line still hold. **Settle it with a network capture of the `full` release build on a device before shipping**, and record the result in [`play-data-safety.md`](play-data-safety.md).

### 6. Edge cases

#### 6.1 Purchase lifecycle the app must handle

- **Pending (Play).** "Your app must enable and support pending transactions for one-time products". Grant "only when the state is `PURCHASED`". The three-day acknowledgement window "begins only when the purchase state transitions from 'PENDING' to 'PURCHASED'" ([integrate](https://developer.android.com/google/play/billing/integrate#pending)). The plugin enables pending one-time purchases when it builds the client (`BillingClientFactoryImpl.java`, `enablePendingPurchases(...)`).
- **Purchases finishing while the app is closed (Play).** "If your application is not running … `onPurchasesUpdated` won't be invoked." Google says to call `queryPurchasesAsync()` on connect and "in your app's `onResume()`". The plugin doesn't do this by itself. It only queries in `restorePurchases()` and `queryPastPurchases()`.
- **Interrupted purchases and Ask to Buy (Apple).** "An interrupted purchase is a transaction that requires the user to perform some action outside of your app" ([testing an interrupted purchase](https://developer.apple.com/documentation/storekit/testing-an-interrupted-purchase)). The plugin sends "cancelled/pending/unverified results to `purchaseStream`" (storekit changelog).
- **Unfinished transactions (both).** Plugin README: Android refunds anything not completed "within 3 days". On iOS, unfinished transactions "will be repeatedly re-delivered … on every app launch", and "Any subsequent attempt to purchase the same product ID will immediately fail".

#### 6.2 Android: pending purchases and the auto-consume gap

In `in_app_purchase_android` 0.5.5, `buyConsumable(autoConsume: true)` adds the product ID to `static final Set<String> _productIdsToConsume` (`in_app_purchase_android_platform.dart:67`, `:185`). `_maybeAutoConsumePurchase` consumes only purchases whose status is `purchased` **and** whose ID is in that set (`:249–268`). `restorePurchases()` marks everything it returns as `PurchaseStatus.restored` (`:235`).

So a tip that turns `PURCHASED` after a process restart is never auto-consumed: the set is empty and the status is `restored`. That happens with a slow payment method, or when the app is killed between paying and the callback. Google's rule then applies: the item stays owned, so the same tip can't be bought again, and it is "automatically refunded" after three days. The fix is the startup `restorePurchases()` + `consumePurchase()` step in checklist C.

#### 6.3 Builds without store access

| Build | Expected behaviour | Basis |
| --- | --- | --- |
| Android `develop` flavour (`.develop` application ID) | Products not found | Play only knows `com.opennutritracker.ont.opennutritracker`. License-tester sideloads need "the package name [to] match" ([test](https://developer.android.com/google/play/billing/test)) |
| Android `full` sideloaded (GitHub release APK) | Billing blocked for non-testers | "the Google Play Billing Library is blocked for apps that aren't signed and uploaded to Google Play. License testers can bypass this check" |
| Android without the Play Store / Play blocked | `isAvailable()` false or `billingUnavailable` | `in_app_purchase_android` 0.5.5 changelog; plugin README "The store cannot be reached or accessed" |
| iOS `develop` scheme (`.develop` bundle ID) | Products not found | No products configured for that bundle ID |
| iOS TestFlight | Works, sandbox, no charge | "Apps that you download from TestFlight always run in the sandbox environment"; sandbox transactions "don't incur charges" ([sandbox](https://developer.apple.com/documentation/storekit/testing-in-app-purchases-with-sandbox)) |
| iOS sandbox before the agreement | Not testable | Sandbox prerequisites include "Your membership Account Holder has signed the Paid Applications Agreement" |

In every "not found" or "unavailable" row the app should hide the tip jar. Never show a broken button or a fake price. On Android the external Sponsors and Ko-fi links remain, so the Donate way never disappears there. On iOS the Donate way simply isn't shown.

#### 6.4 Testing aids

- Android license testers get "Test instrument, always approves / always declines", "Slow test card, approves after a few minutes" and "Slow test card, declines after a few minutes". Unacknowledged license-tester purchases are "refunded after 3 minutes". Draft and internal-track purchases are under spend limits ([test](https://developer.android.com/google/play/billing/test)).
- On Apple, sandbox purchase history can be cleared per tester in App Store Connect or on device, and interrupted purchases are toggled per tester ([sandbox](https://developer.apple.com/documentation/storekit/testing-in-app-purchases-with-sandbox)).

---

## Not verified

- **What Play Billing 9.1.0 sends through its `datatransport` and `play-services-location` dependencies.** No primary page found today documents it. This decides the Data safety and README wording ([5.3](#53-the-dependency-question-left-open)).
- **The exact EEA/UK/US Play service-fee figures.** The Help Center table was read through a flattened page, so confirm in Play Console.
- **Whether the GitHub-release APK and the Play-delivered APK share a signing key.** If they do, billing may still refuse the sideloaded copy for non-testers. The table above records Google's general rule, not a device result.
- **Apple Ask to Buy testing with a Sandbox Test Family.** Only the interrupted-purchase path was read.
- **Xcode StoreKit configuration files** for local testing of the `develop` scheme without App Store Connect. They weren't read today.
- **Whether a German individual developer needs any non-US tax form** in App Store Connect. The page's country list visible today had no Germany section.
- **Whether the Play one-time product icon is really mandatory** in the current console. The help page lists it.

## Sources

All read 2026-11-07.

| Source | URL |
| --- | --- |
| `in_app_purchase` 3.3.1 (archive, README, CHANGELOG, source) | https://pub.dev/packages/in_app_purchase |
| `in_app_purchase_android` 0.5.5 | https://pub.dev/packages/in_app_purchase_android |
| `in_app_purchase_storekit` 0.4.17 | https://pub.dev/packages/in_app_purchase_storekit |
| Play Billing 9.1.0 AAR manifest and POM | https://dl.google.com/dl/android/maven2/com/android/billingclient/billing/9.1.0/billing-9.1.0.pom |
| App Review Guidelines | https://developer.apple.com/app-store/review/guidelines/ |
| App Store Connect: create consumable IAP | https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/create-consumable-or-non-consumable-in-app-purchases |
| App Store Connect: IAP information reference | https://developer.apple.com/help/app-store-connect/reference/in-app-purchases-and-subscriptions/in-app-purchase-information |
| App Store Connect: set a price | https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/set-a-price-for-an-in-app-purchase |
| App Store Connect: submit an IAP | https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase |
| App Store Connect: agreements | https://developer.apple.com/help/app-store-connect/manage-agreements/sign-and-update-agreements |
| App Store Connect: tax information | https://developer.apple.com/help/app-store-connect/manage-tax-information/provide-tax-information |
| App Store Connect: banking | https://developer.apple.com/help/app-store-connect/manage-banking-information/enter-banking-information |
| App Store Connect: DSA trader requirements | https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements |
| App Store Small Business Program | https://developer.apple.com/app-store/small-business-program/ |
| Apple In-App Purchase overview | https://developer.apple.com/in-app-purchase/ |
| App privacy details | https://developer.apple.com/app-store/app-privacy-details/ |
| StoreKit: testing with sandbox | https://developer.apple.com/documentation/storekit/testing-in-app-purchases-with-sandbox |
| StoreKit: testing an interrupted purchase | https://developer.apple.com/documentation/storekit/testing-an-interrupted-purchase |
| StoreKit: `Transaction.finish()` | https://developer.apple.com/documentation/storekit/transaction/finish() |
| StoreKit: `Transaction.all` | https://developer.apple.com/documentation/storekit/transaction/all |
| Play Billing: getting ready | https://developer.android.com/google/play/billing/getting-ready |
| Play Billing: integrate | https://developer.android.com/google/play/billing/integrate |
| Play Billing: test | https://developer.android.com/google/play/billing/test |
| Play Billing: deprecation FAQ | https://developer.android.com/google/play/billing/deprecation-faq |
| Play Console: create an in-app product | https://support.google.com/googleplay/android-developer/answer/1153481?hl=en |
| Play Console: payments profile | https://support.google.com/googleplay/android-developer/answer/7161426?hl=en |
| Play Console: tax rates and VAT | https://support.google.com/googleplay/android-developer/answer/138000?hl=en |
| Play Console: service fees | https://support.google.com/googleplay/android-developer/answer/112622?hl=en |
| Play Console: 15% tier enrolment | https://support.google.com/googleplay/android-developer/answer/10632485?hl=en |
| Play Console: trader status declaration | https://support.google.com/googleplay/android-developer/answer/17594752?hl=en |
| Play Console: Data safety | https://support.google.com/googleplay/android-developer/answer/10787469?hl=en |
| Play Payments policy | https://support.google.com/googleplay/android-developer/answer/9858738?hl=en |

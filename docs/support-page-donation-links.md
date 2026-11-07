# Donation links under Google Play and App Store policy

Research notes for [#1527](https://github.com/simonoppowa/OpenNutriTracker/issues/1527) ("May Play and App Store apps link to donation pages?"), part of the Support page map [#1526](https://github.com/simonoppowa/OpenNutriTracker/issues/1526). The donation targets in question are the ones in `.github/FUNDING.yml`: GitHub Sponsors (`simonoppowa`), Patreon (`SimonOppowa`) and Ko-fi (`simonoppowa`).

All store policy pages were read on **2026-11-07**. Apple's App Review Guidelines carried "Last Updated: October 16, 2026" on that day. Google's help pages show no revision date. Every policy quote below comes from the primary page linked in [Sources](#sources). Rejection reports in section 4 are secondary sources and are marked that way.

## Verdict

| Store | Verdict | The condition that decides it |
| --- | --- | --- |
| **Google Play** | **Allowed with conditions** | The donation must count as a peer-to-peer payment: 100% goes to the developer, and it grants nothing digital (no perks, badges, early builds, unlocked features). Reviewers have still rejected open-source apps for exactly this, as recently as 2026. |
| **App Store, US storefront** | **Allowed with conditions** | The guideline text exempts the US storefront from the ban on external purchase links. In practice App Review has rejected a US-only tip link in August 2026, insisting on In-App Purchase. Expect to argue it. |
| **App Store, every other storefront** | **Not allowed** (as an external link) | Developer tips must go through In-App Purchase. A link or button to GitHub Sponsors, Patreon or Ko-fi inside the app is a "call to action" toward another purchase method. |

**What this means for the Support page.**

1. **Android:** a *Donate* entry linking to GitHub Sponsors is defensible under the written policy. Ko-fi is defensible only if the Ko-fi page sells nothing and offers no membership perks. Patreon is the weakest: its tiers are perk-based and Patreon keeps a platform fee, so it fails both halves of Google's peer-to-peer test.
2. **iOS:** leave the donate entry out of the iOS build, or show it only when the StoreKit storefront is the United States and say so in the App Review notes. The fully compliant iOS alternative is an In-App Purchase "tip" (a consumable that unlocks nothing), which needs the Paid Applications agreement and pays Apple's commission.
3. **Wording does not rescue a link on either store.** "Support" or "Sponsor" is judged by where the link goes, not by the label.
4. **Being an individual rather than a registered non-profit matters on both stores.** It rules out Google's "tax exempt donations" carve-out and Apple's approved-nonprofit route, leaving the narrower peer-to-peer (Google) and US-storefront (Apple) paths.

---

## 1. Google Play

### 1.1 What the Payments policy says

The [Payments policy](https://support.google.com/googleplay/android-developer/answer/9858738?hl=en) is a numbered list. The parts that bite:

- **Section 2** puts in scope apps "requiring or accepting payment for access to in-app features or services, including any app functionality, digital content or goods".
- **Section 3** says Play billing **must not** be used where "payments include peer-to-peer payments, online auctions, and tax exempt donations".
- **Section 4** says that, outside sections 3, 8 and 9, "apps may not lead users to a payment method other than Google Play's billing system", including through "In-app webviews, buttons, links, messaging, advertisements, or other calls to action" and through "An app's listing in Google Play".
- **Sections 8 and 9** cover enrolment programmes (alternative billing, leading users outside the app) for "eligible countries/regions".

So a donation link is fine if the donation falls under section 3, and a violation if it does not.

### 1.2 How Google classifies a donation to an individual developer

An individual developer's donations are not "tax exempt donations". The route that applies is the peer-to-peer one, which the [Payments policy FAQ](https://support.google.com/googleplay/android-developer/answer/10281818?hl=en) spells out under "Do direct tips or contributions from user to creator require Play's billing system?":

> In cases where 100% of the tip or contribution from a user goes to the creator and the payment does not grant access to any digital content or services (including stickers, badges, special emojis etc.), then we regard this as a peer-to-peer payment and use of Google Play's billing system is not required.

It also says what happens otherwise: "If any of these things is not true, then Google Play's billing system must be used". In that case section 4 forbids the link.

The same FAQ shows how wide "leading users" is read: it includes "directly linking to a webpage that could lead to an alternate payment method".

### 1.3 Answers to the sub-questions (Google Play)

- **Free, open-source app, no IAP, individual developer: may it link out?** Yes, under the peer-to-peer reading in 1.2. Two conditions apply: 100% to the creator, and nothing digital in return. Being an individual does not disqualify the app. It only means the "tax exempt donations" line in section 3 is not the one to rely on.
- **Platform fees and "100% to the creator".** GitHub Sponsors states: "GitHub Sponsors does not charge any fees for sponsorships from personal accounts, so 100% of these sponsorships go to the sponsored developer" ([GitHub Docs](https://docs.github.com/en/sponsors/getting-started-with-github-sponsors/about-github-sponsors), read 2026-11-07). Patreon's model is a platform fee on creator earnings, and Ko-fi advertises fee-free donations. I could not confirm either today because both pricing pages were behind a bot check. If a payment processor's card fee counts against "100%", no platform passes, so Google cannot mean it that literally. A platform cut is a different matter, and Patreon is the one exposed to it.
- **Wording.** The policy tests what the payment buys and where it goes, not the label. "Donate", "Support" and "Sponsor" are equivalent. Wording that *promises* something ("Sponsor to unlock…", "supporters get early access") makes it a purchase.
- **Patreon tiers.** Tiers whose perks are digital content or services (early builds, exclusive posts, Discord roles, badges) are "access to any digital content or services". That fails the peer-to-peer test, so Play billing would be required and the link is forbidden. The same applies to GitHub Sponsors tiers or a Ko-fi shop/membership that offers digital rewards. Perk-free tiers, or no tiers, keep it clean.
- **Store-endorsed workarounds.** For a peer-to-peer donation, none are needed. The US and EEA "lead users outside the app" programmes ([US programmes](https://support.google.com/googleplay/android-developer/topic/16787812), [EEA programmes](https://support.google.com/googleplay/android-developer/topic/16470499)) exist for selling digital content and carry fees and enrolment. They are not designed for donations, and using one would turn a donation into a reportable sale. Google's policy says nothing about opening links in the browser versus a webview, but "In-app webviews" is named among the prohibited channels in section 4, so opening the page in the external browser is the conservative choice.

---

## 2. Apple App Store

### 2.1 What the App Review Guidelines say

From the [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) (Last Updated: October 16, 2026):

- **3.1.1 In-App Purchase**: "If you want to unlock features or functionality within your app … you must use in-app purchase." Then, specifically about tips: "Apps may use in-app purchase currencies to enable customers to "tip" the developer or digital content providers in the app."
- **3.1.1(a) Link to Other Purchase Methods**: in storefronts without a regional entitlement, "except for the United States storefront, where this prohibition does not apply, apps and their metadata may not include buttons, external links, or other calls to action that direct customers to purchasing mechanisms other than in-app purchase." It also says entitlements "are not required for developers to include buttons, external links, or other calls to action in their United States storefront apps."
- **3.1.3 Other Purchase Methods**: apps "cannot, within the app, encourage users to use a purchasing method other than in-app purchase, except for apps on the United States storefront". The same clause says developers "can send communications outside of the app to their user base about purchasing methods other than in-app purchase."
- **3.2.1(vi) Acceptable**: "Approved nonprofits may fundraise directly within their own apps or third-party apps", with Apple Pay support, disclosed use of funds and tax receipts.
- **3.2.1(vii) Acceptable**: apps may "enable individual users to give a monetary gift to another individual without using in-app purchase" if it is optional and 100% goes to the receiver, "However, a gift that is connected to or associated at any point in time with receiving digital content or services must use in-app purchase."
- **3.2.2(iv) Unacceptable**: "Unless you are an approved nonprofit … collecting funds within the app for charities and fundraisers." Such apps "may only collect funds outside of the app, such as via Safari or SMS."

### 2.2 How these clauses fit together for this app

- A donation to the app's own developer is a **tip to the developer**, which 3.1.1 names and routes to In-App Purchase. App Review applies this even when the tip unlocks nothing (see 4.1).
- **3.2.1(vii) does not help.** It covers person-to-person gifting between users of an app. App Review has read "associated with receiving digital content or services" to include the app itself (see 4.1).
- **The nonprofit routes (3.2.1(vi), 3.2.2(iv)) are closed.** "Approved nonprofit" means approval through Apple Pay for nonprofits: a Candid Seal of Transparency for US nonprofits, Benevity approval elsewhere ([Apple Pay for nonprofits](https://developer.apple.com/apple-pay/nonprofits/)). An individual maintainer does not qualify. 3.2.2(iv)'s "via Safari or SMS" sentence is about charity fundraising apps, not developer support.
- **Outside the US, an external donation link is a "call to action" toward another purchasing mechanism.** It is prohibited under 3.1.1(a) and 3.1.3, and the prohibition extends to "metadata", meaning the App Store description and screenshots too.
- **On the US storefront that prohibition "does not apply".** By the text, an external donation link is allowed there. App Review's stated position (4.1) is that the 2025 US changes "have not changed the scenarios where In-App Purchase is required". So a US-only link is allowed by the text but can still draw a rejection.

### 2.3 Answers to the sub-questions (App Store)

- **Free, open-source app, no IAP, individual developer: may it link out?** Only on the US storefront. Elsewhere, no. Being an individual removes the approved-nonprofit route, and that route would only allow Apple Pay donations to a charity anyway.
- **Wording.** It doesn't change the outcome. App Review rejected both "Donate to the Project" and "Support the Developer" under 3.1.1 (4.1), and 3.1.1(a) covers "buttons, external links, or other calls to action" whatever they say.
- **Patreon tiers.** Perks that are digital content or services make it a purchase of digital goods, which is squarely 3.1.1. On non-US storefronts it changes nothing, because the link is already out. On the US storefront it removes the "unlocks nothing" argument.
- **Store-endorsed workarounds.**
  - *US storefront only.* The guidelines are written per storefront, so showing the donate entry only when the StoreKit storefront is the United States is consistent with them. Disclose it in the App Review notes, because 2.5.19 forbids "hidden, dormant, or undocumented features".
  - *EU.* Since 2026-10-01, EU storefronts allow "out-of-app offers" with an actionable link ([Payment options on the App Store in the EU](https://developer.apple.com/support/apps-using-alternative-payment-providers-in-the-eu/)). This route requires the StoreKit External Purchases or Offers Entitlement, the `ExternalPurchaseCustomLink` disclosure sheet, parental gates for users under 18, a 12-month lock-in "across all EU storefronts", reporting to Apple, and a store services commission of 15% (10% for Small Business Program members) on resulting sales. It is built for selling digital goods, and using it for donations would mean reporting donations to Apple and paying commission on them. Not recommended.
  - *Safari versus an in-app browser.* No guideline endorses either for developer tips. Safari is mentioned only in 3.2.2(iv), for charities.
  - *Outside the app.* 3.1.3 explicitly allows communication "outside of the app" about other payment methods. The website, README and release notes can carry donation links freely.
  - *In-App Purchase tip jar.* This is the route 3.1.1 names. It works on every storefront. It needs the Paid Applications agreement (banking and tax details), and Apple keeps its commission. The 15% rate for Small Business Program members appears on the EU page above. Program enrolment and worldwide rates were not checked in this note.

---

## 3. Side by side

| Question | Google Play | App Store |
| --- | --- | --- |
| External donation link, free app, no IAP | Allowed if peer-to-peer (100% to creator, nothing digital in return) | US storefront: allowed by text, rejection risk. Elsewhere: not allowed |
| Individual vs registered non-profit | Individual can't use "tax exempt donations", relies on the peer-to-peer FAQ | Individual can't be an "approved nonprofit"; irrelevant for the US route |
| "Donate" vs "Support" vs "Sponsor" | No difference | No difference |
| Patreon-style perk tiers | Makes it a digital purchase: link not allowed | Makes it a digital purchase: In-App Purchase required |
| Mention in store listing | Allowed if the payment is peer-to-peer (section 4 names the listing only for non-exempt payments) | Not allowed outside the US ("apps and their metadata") |
| Endorsed workaround | None needed. US/EEA programmes exist but are for digital sales | US-storefront gating; EU out-of-app offers (heavy); IAP tip jar |

---

## 4. Known rejections of similar apps (secondary sources)

These are developer reports, not store rulings. They show how reviewers apply the text.

### 4.1 App Store

- **"Buy Me a Coffee" link, US-only app, August 2026.** [Apple Developer Forums thread 844046](https://developer.apple.com/forums/thread/844046). A free app distributed only on the US storefront was rejected under 3.1.1 for an optional tip link on its About page that opened the external browser. App Review asked to "revise the app to use in-app purchase to process 'tips'" and said the 2025 changes to 3.1.1, 3.1.1(a), 3.1.3 and 3.1.3(a) "have not changed the scenarios where In-App Purchase is required". The developer appealed citing 3.1.1(a). No outcome was posted.
- **"Donate to the Project" / "Support the Developer", June 2025.** [Thread 791096](https://developer.apple.com/forums/thread/791096). The rejection said the donations "must use in-app purchase since they are associated with receiving digital content or services", which is the 3.2.1(vii) carve-out applied to the app itself. App Review staff would not name an acceptable label and pointed to a one-on-one App Review consultation.
- **Links to the project's GitHub page, June 2025.** [Thread 786489](https://developer.apple.com/forums/thread/786489). An open-source app was rejected under 2.3.10 and 3.1.1 because its links led to a GitHub page that mentioned a donation link and Google Play. No outcome was posted.

### 4.2 Google Play

- **StreetComplete, February 2022.** [streetcomplete/StreetComplete#3768](https://github.com/streetcomplete/StreetComplete/issues/3768). The app showed Patreon, Liberapay and GitHub Sponsors links. It was rejected under the Payments policy, with the reviewer quoting the "tax exempt donations" line. An appeal failed. The Play build was accepted only after the donation links were removed **and** the link to the GitHub project home was removed, because reviewers treated the repo page as an indirect route to payment.
- **AnkiDroid, reported 2026-09-02.** [GIGAZINE report](https://gigazine.net/gsc_news/en/20260902-ankidroid-google-play-policy-violation/). The app was flagged for an in-app donation link to Open Collective. Google treated Open Collective (a 501(c)(6)) as not tax-exempt. The appeal was unresolved after more than a month, and an update was blocked meanwhile. The report does not mention the peer-to-peer FAQ, and Open Collective payouts go to a fiscal host rather than straight to the creator, so this case may not transfer cleanly to GitHub Sponsors.
- **WireGuard, 2020.** Widely reported. The app was removed over an in-app donation link and restored after it was removed. I did not re-read a primary account for this note.

**Pattern.** On both stores, reviewers have read donation links more strictly than the written text. Google reviewers reach for the "tax exempt donations" line and do not cite the peer-to-peer FAQ. App Review reaches for the 3.1.1 tip sentence even on the US storefront.

---

## 5. Inputs for the Support page spec (#1526)

1. **Android donate entry:** link to GitHub Sponsors (and Ko-fi only if its page has no shop or membership perks). Drop Patreon or make every tier perk-free. Open in the external browser. Give the copy no promise of anything in return.
2. **Keep the GitHub tiers perk-free** for as long as the app links there, including the Sponsor button that `FUNDING.yml` puts on the repo page.
3. **iOS:** decide between (a) no donate entry, (b) a US-storefront-only entry with an App Review note, or (c) an In-App Purchase tip jar. Option (a) has zero review risk. Option (b) is allowed by the text but has the August 2026 counter-example. Option (c) is the only one that works worldwide.
4. **Have the appeal text ready** before submitting the Play build. Quote the FAQ's peer-to-peer answer and GitHub's "100% of these sponsorships" line.
5. **Existing exposure, not a change request:** the app already links to the GitHub repo (`AppConst.sourceCodeUrl` in `lib/core/utils/app_const.dart`, shown in the About dialog), and the repo page shows a Sponsor button from `.github/FUNDING.yml`. That is the indirect route that cost StreetComplete a rejection in 2022 and drew a 3.1.1 citation in Apple thread 786489. It has not been flagged for this app so far as I know, but a new donate entry could prompt a reviewer to look closer.

---

## Open questions / unverified

- **Patreon and Ko-fi fees.** Both pricing pages returned a bot check, so the "100% to the creator" status of each is from general knowledge, not read today.
- **Outcome of the August 2026 US-storefront appeal** (thread 844046). If the App Review Board sided with the developer, option 3(b) gets much safer. Worth rechecking before the iOS decision.
- **Whether card-processing fees break Google's "100%".** The FAQ does not say. I read it as excluding platform cuts, not payment processing.
- **Apple worldwide IAP commission and Small Business Program terms** for a tip jar were not read for this note.
- **WireGuard 2020** is cited from memory of contemporary reporting, not re-read.

## Sources

All read 2026-11-07.

| Source | URL |
| --- | --- |
| Apple App Review Guidelines (Last Updated: October 16, 2026), sections 2.5.19, 3.1.1, 3.1.1(a), 3.1.3, 3.2.1, 3.2.2 | https://developer.apple.com/app-store/review/guidelines/ |
| Apple, Payment options on the App Store in the EU | https://developer.apple.com/support/apps-using-alternative-payment-providers-in-the-eu/ |
| Apple, Apple Pay for nonprofits | https://developer.apple.com/apple-pay/nonprofits/ |
| Google Play, Payments policy | https://support.google.com/googleplay/android-developer/answer/9858738?hl=en |
| Google Play, Understanding Google Play's Payments policy (FAQ) | https://support.google.com/googleplay/android-developer/answer/10281818?hl=en |
| Google Play, US programmes / EEA programmes (linked from the policy, not read in full) | https://support.google.com/googleplay/android-developer/topic/16787812, https://support.google.com/googleplay/android-developer/topic/16470499 |
| GitHub Docs, About GitHub Sponsors (fees) | https://docs.github.com/en/sponsors/getting-started-with-github-sponsors/about-github-sponsors |
| Secondary: Apple Developer Forums threads 844046, 791096, 786489 | see section 4.1 |
| Secondary: StreetComplete #3768; GIGAZINE on AnkiDroid | see section 4.2 |

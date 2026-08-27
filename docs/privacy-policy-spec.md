# Correcting the published Data policy — the spec

The locked output of map [#867](https://github.com/simonoppowa/OpenNutriTracker/issues/867), written 2026-08-27 after nineteen tickets. Every statement here is a decision already taken, with the ticket that took it. **Nothing in this document is a fresh judgement call** — where something is genuinely undecided it says so under [Left open](#left-open).

Applying it needs three things: the iubenda dashboard, a PR in this repo, and a release. They are separable; see [Sequencing](#sequencing).

---

## 0. Where the work happens

| | |
| :-- | :-- |
| iubenda project | *OpenNutriTracker*, Pro — flow `2909630`, policy editor `2391506` |
| Documents | **One configuration, two rendered languages** — `EN (US)` public id `53501884`, `DE` public id `53922100` ([#888](https://github.com/simonoppowa/OpenNutriTracker/issues/888)) |
| Baseline audited | `v2.0.2` (released 2026-08-02), plus the unreleased AI work |

**English is the editorial source.** German is derived from it. This is a working rule for the maintainer, **not a governing-language clause** — no such clause appears in either document ([#875](https://github.com/simonoppowa/OpenNutriTracker/issues/875)).

**Catalogue entries propagate across languages; custom clauses do not** ([#871](https://github.com/simonoppowa/OpenNutriTracker/issues/871), seen in the wild by [#888](https://github.com/simonoppowa/OpenNutriTracker/issues/888)). **Every custom clause below must be written twice.**

---

## 1. Services

### 1.1 Remove

**Delete the custom service `Geräteberechtigungen für den Zugriff…`** (group *Device permissions for Person…*).

That single entry is the source of all four permission categories. Deleting it implements [#884](https://github.com/simonoppowa/OpenNutriTracker/issues/884)'s decision in full: a permission is a device *capability*, not personal data, and nothing reaches the controller through one. Declaring capabilities alongside data is what let *Storage* sit there falsely for years and *Reminders* name an API this app has never touched ([#872](https://github.com/simonoppowa/OpenNutriTracker/issues/872)).

Permission purposes are not lost — they live in the iOS usage strings and the store listings, with the merged-manifest inventory recorded on [#872](https://github.com/simonoppowa/OpenNutriTracker/issues/872).

### 1.2 Keep unchanged

`TestFlight`, `Google Play Beta Testing`, `Google Play Store`, `App Store Connect` — all catalogue services, all correct, all **independent controllers** ([#873](https://github.com/simonoppowa/OpenNutriTracker/issues/873)).

### 1.3 Amend

**`Sentry`** — keep the catalogue entry, correct what it says. See [§3.3](#33-sentry).

### 1.4 Add

| Recipient | How | Why not catalogue |
| :-- | :-- | :-- |
| **Supabase** | Catalogue entry — `Supabase (self-hosted)` exists ([#871](https://github.com/simonoppowa/OpenNutriTracker/issues/871)) | — |
| **Open Food Facts** | **Custom service** | Not in the catalogue |
| **AI assistance** | **Custom clause**, not a recipient entry | See [§4](#4-ai-assistance) |

---

## 2. Categories

Declared today: Usage Data, Storage permission, Reminders permission, Camera permission, Diagnostics, Email address, App information, Device logs, Device information, Data communicated while using the Service.

| Action | Entries |
| :-- | :-- |
| **Removed** | Storage permission, Reminders permission, Camera permission — via [§1.1](#11-remove) |
| **Not added** | `CAMERA`, `VIBRATE`, `ACCESS_NETWORK_STATE` — same reasoning |
| **Kept** | Usage Data, Diagnostics, App information, Device logs, Device information |
| **Kept, scoped** | Email address — beta distribution only (TestFlight) |
| **Kept, load-bearing** | Data communicated while using the Service — now carries the **food search term** |
| **Added** | **IP address**, **approximate location**, **connection identifiers** |

**The search term rides the catch-all.** Only catalogue entries reach the categories summary ([#871](https://github.com/simonoppowa/OpenNutriTracker/issues/871)), so a bespoke category naming it may not be expressible. *"Data communicated while using the Service"* literally covers a typed query; the term is **named exactly in the recipient clauses**, where prose is permitted ([#884](https://github.com/simonoppowa/OpenNutriTracker/issues/884)).

**The three additions exist because of the gateway log.** [#873](https://github.com/simonoppowa/OpenNutriTracker/issues/873) made this project the controller of it and [#869](https://github.com/simonoppowa/OpenNutriTracker/issues/869) measured what it holds for 24 hours: the client IP twice, city, region, postal code, country, timezone, ISP by name, and a JA3/JA4 TLS fingerprint. Omitting a postal code and a fingerprint you hold for a day is the under-disclosure this map exists to correct.

---

## 3. What each clause must say

### 3.1 Open Food Facts — custom service

- **Receives:** the search term or barcode, a country tag derived from device locale, and the app's own User-Agent (app name, platform, version).
- **When:** on a food search or barcode scan.
- **Role:** **independent controller** — a separate French non-profit that decides its own purposes, takes no instruction, and is under no contract with this project. The clause **discloses them as a recipient and points at their own policy**. It must not imply a processor relationship or a DPA, because neither exists ([#873](https://github.com/simonoppowa/OpenNutriTracker/issues/873)).
- **Where:** France — measured as Scaleway PAR4, reached directly with no CDN in front ([#869](https://github.com/simonoppowa/OpenNutriTracker/issues/869)). Intra-EU.

### 3.2 Supabase — catalogue entry plus clause

- **Receives:** the search term, in the request URL.
- **Role:** **processor**, with **Cloudflare, Inc.** and **Amazon Web Services, Inc.** as sub-processors ([#873](https://github.com/simonoppowa/OpenNutriTracker/issues/873), [#890](https://github.com/simonoppowa/OpenNutriTracker/issues/890)). **This project is the controller.**
- **Contracting entity:** **`Supabase Pte. Ltd`, Singapore** — not a US or EU entity ([#890](https://github.com/simonoppowa/OpenNutriTracker/issues/890)).
- **Also records, for 24 hours:** client IP, city, region, postal code, country, timezone, ISP name, and a TLS fingerprint of the connection.
- **Residency — word this carefully.** The DPA obliges only that data be *"stored and primarily Processed"* in the directed region, and the Cloudflare edge is chosen by proximity to **the user**. The permitted claim is **"stored and primarily processed in Frankfurt, with transfers covered by standard contractual clauses"**. **No string may say the data stays in the EU** ([#890](https://github.com/simonoppowa/OpenNutriTracker/issues/890)).
- **Sub-processors:** name Cloudflare and AWS; link Supabase's list for the rest. The list carries **no location column**, so a *Place of processing* line cannot be sourced from it.

### 3.3 Sentry

- **Receives:** crash traces, app and OS version, device model. **Not** breadcrumbs carrying diary content — that leak is fixed and merged ([#877](https://github.com/simonoppowa/OpenNutriTracker/issues/877), [PR #879](https://github.com/simonoppowa/OpenNutriTracker/pull/879)).
- **Also receives, and this was measured on a live event** ([#889](https://github.com/simonoppowa/OpenNutriTracker/issues/889)):
  - **`user.geo` — country, region and city of every crash.** Relay resolves this from the *connection* IP before filtering, so it is stored even though `user.ip_address` is `null`, on both platforms. The org's *Prevent Storing of IP Addresses* setting does **not** cover it.
  - **`user.id` — a stable per-install UUID**, set by the native SDKs and **ungated by `sendDefaultPii`**.
- **Does not receive the IP.** `sendDefaultPii` propagates to native correctly; sentry-cocoa 8.56.0 replaced `{{auto}}` with a gated `infer_ip` and the Podfile pins 8.58.1. The Apple documentation suggesting otherwise is stale.
- **Role:** **processor**. Recipient is **Functional Software, Inc.**
- **Country and retention:** **United States**, **30 days** — Developer plan, and the region is fixed at organisation creation and cannot be changed ([#878](https://github.com/simonoppowa/OpenNutriTracker/issues/878)).
- **Transfer mechanism:** Data Privacy Framework with SCCs as fallback.
- **Basis:** **consent** — see [§5](#5-legal-bases). The clause must name the **withdrawal path**: the Settings switch, which closes the SDK immediately.

> **⚠ The word "anonymous" is under review.** The consent label calls these *anonymous* crash reports, and a persistent identifier bound to a city is not obviously that. [#894](https://github.com/simonoppowa/OpenNutriTracker/issues/894) decides whether the label changes, the behaviour changes, or both — a `beforeSend` hook could strip both fields. **This clause is accurate as written either way**; only the *label* and possibly the payload are in question, so this does not block applying the spec.

### 3.4 Stores and beta distribution

Unchanged. Independent controllers. `Google Play Beta Testing` is Ireland; `TestFlight`, `App Store Connect` and `Google Play Store` are the US.

---

## 4. AI assistance

**Explanatory prose, not a recipient entry.** The user contracts with the vendor, pays, holds the key, chooses provider and model, and on the fourth provider names an address this project never sees — so **the user is the controller** of those transfers ([#876](https://github.com/simonoppowa/OpenNutriTracker/issues/876)).

This dissolves what looked like the hardest constraint. [#871](https://github.com/simonoppowa/OpenNutriTracker/issues/871) found iubenda **cannot express a conditional recipient at all** — no toggle, no "if enabled" slot. With no Art.13 recipient duty toward these vendors there is nothing to put in the recipients list, and prose has no conditionality machinery to lack.

**The passage goes in now, ahead of the feature shipping** — a knowing amendment to the map's baseline, on the grounds that it describes a conditional capability and who is responsible for it rather than asserting that processing occurs, and that it aligns the policy with the README.

It must carry:

- Only **the line you typed or a photo you chose** is sent. Never the diary, profile, or history.
- The destination is **the vendor you selected**, under **your** relationship with them; their handling is governed by their policy, not this one.
- **OpenRouter is a broker** — a request reaches OpenRouter **and** the vendor serving the chosen model, **two recipients, not one** — and an account-level identity is forwarded to that vendor and **cannot be switched off**. This is the one asymmetry a user cannot discover from the provider list.
- For the user-run endpoint: the destination is **an address you entered** and the project cannot know it. The truthful claim is **"no third party receives it"** and never **"it never leaves the device"** (map [#732](https://github.com/simonoppowa/OpenNutriTracker/issues/732)). No shipped string may blur the two.

---

## 5. Legal bases

| Purpose | Basis | Obligations it brings |
| :-- | :-- | :-- |
| Food lookups (Open Food Facts, Supabase) | **Art.6(1)(f)** legitimate interest | A **documented balancing assessment**, and the **Art.21 right to object** stated rather than implied |
| Crash reporting (Sentry) | **Art.6(1)(a)** consent | The **withdrawal path** named |
| Store and beta distribution | Their own, as independent controllers | — |

**Art.6(1)(b) was rejected for the lookups.** It needs a contract this project has deliberately never created — no account, no sign-in, and **no terms of service anywhere in the tree** (confirmed again in the iubenda dashboard, where Terms & Conditions is un-generated). Claiming one to reach an easier basis is the convenient fiction this map exists to remove ([#874](https://github.com/simonoppowa/OpenNutriTracker/issues/874)).

The objection right is already satisfied in substance — decline to search, or use saved entries offline — but must be **said**.

---

## 6. The onboarding checkbox

**It is an acknowledgement. No legal basis rests on it** ([#874](https://github.com/simonoppowa/OpenNutriTracker/issues/874)).

A privacy policy is Art.13 *information*, not something a person can consent to. And a gate you must pass to use the app at all — and there is no unpolicy-gated path in, the demo included ([#875](https://github.com/simonoppowa/OpenNutriTracker/issues/875)) — is the textbook shape of consent that is not freely given. **If it were consent it would be invalid consent, collapsing exactly when it was needed.**

Reframed as acknowledgement it is honest and harmless. The cost is a **string change, not a flow change**: the strings that say *"Accept the privacy policy"* become acknowledgement wording.

---

## 7. Local storage

A scoped section — **what stays on the device, where credentials live, and what erasure actually clears**. Cryptographic specifics stay in the README, beside their source links, which is what makes them checkable ([#885](https://github.com/simonoppowa/OpenNutriTracker/issues/885)).

- The profile, diary, activities, weight, water and fasting history, custom meals and recipes are **held on the device** and not transmitted to the project.
- **AI credentials**, where configured, sit in the platform's own secure credential store and leave only as the header authenticating the user's own request.
- **Settings → Delete all my data** — and **its real scope**. It wipes the **active profile**; other profiles, the shared Open Food Facts cache and the shared content libraries are deliberately excluded. **The policy must not overstate this into "deletes everything."**

> **⚠ Blocked sentence.** The erasure clause cannot be written truthfully until [#892](https://github.com/simonoppowa/OpenNutriTracker/issues/892) lands — today `deleteAll()` leaves the AI API keys and endpoint URL in the Keychain. Either ship #892 first, or word the clause to exclude credentials.

---

## 8. The owner block

**Name plus email. No postal address.**

Art.13(1)(a) requires *"the identity and the contact details of the controller"*, and an email supplies a working route to exercise rights. iubenda's own guidance asks only that the field *"contain identification and contact details"* — naming no postal address despite the field being labelled `NAME/COMPANY AND FULL ADDRESS` — and it is a free-text textarea with no validation ([#886](https://github.com/simonoppowa/OpenNutriTracker/issues/886), [#888](https://github.com/simonoppowa/OpenNutriTracker/issues/888)).

Leave **"Same for all languages"** set, so this propagates.

> **Out of scope, and important.** Whether an **Impressum** is owed under §5 DDG is a separate obligation with its own rules, concerning the maintainer's personal exposure, and needs qualified advice. If one is owed, the postal address belongs **there, once** — not duplicated into two privacy policies that never required it. If an address must appear anywhere, prefer a **c/o or service address** over the residential one.

---

## 9. Repo and app changes

These are part of the correction, not separate wishes.

| # | Change | Ticket |
| :-- | :-- | :-- |
| 1 | **Serve the right document.** `privacyPolicyURLDe` is defined and never opened — both call sites use the English URL. Select by the app's own resolved locale (`getSelectedLocale()` else platform locale, the value [`main.dart:97`](../lib/main.dart) already computes). German → German; the other eight UI locales → English. Both call sites. No notice explaining the fallback. | [#875](https://github.com/simonoppowa/OpenNutriTracker/issues/875) |
| 2 | **Acknowledgement wording** in the onboarding strings. | [#874](https://github.com/simonoppowa/OpenNutriTracker/issues/874) |
| 3 | **A one-time, non-blocking in-app notice** that the policy changed, pointing at it and at the change record. **It must not gate** — re-gating would rebuild the consent-shaped problem #874 removed — and `hasAcceptedPolicy` is an unversioned bool, so a re-prompt would need a Hive migration. | [#887](https://github.com/simonoppowa/OpenNutriTracker/issues/887) |
| 4 | **CI job: fetch both documents** through iubenda's public read API, **fail if their service and category sets diverge**, and **commit what it fetched.** The diff check replaces the governing-language clause; the commit gives version history iubenda does not provide. | [#875](https://github.com/simonoppowa/OpenNutriTracker/issues/875), [#887](https://github.com/simonoppowa/OpenNutriTracker/issues/887) |
| 5 | **README:** correct the wire claims. | [PR #891](https://github.com/simonoppowa/OpenNutriTracker/pull/891) |

Item 4 is the load-bearing one. The drift hazard is **untranslated custom clauses inside one project** ([#888](https://github.com/simonoppowa/OpenNutriTracker/issues/888)), and every clause in §3 and §4 is custom. A check that needs no discipline beats one that relies on someone being conscientious — this map found prose drifting from code four times.

---

## 10. Sequencing

```
iubenda edits (§1, §2, §3, §5, §8)   ──┐
                                        ├─→  release with notice (§9.3)
repo PR (§9.1, §9.2, §9.4, §9.5)     ──┘

#892 ──→ §7 erasure sentence            (else word around it)
#894 ──→ consent label wording only     (§3.3 is accurate regardless)
AI ships ──→ §4 already in place
```

Nothing here blocks on the AI feature: §4 is written now by decision.

---

## 11. Verification

- [ ] The rendered English and German policies name the same services and categories.
- [ ] No permission appears as a data category in either.
- [ ] `Storage` and `Reminders` are gone.
- [ ] Neither document says data stays in the EU.
- [ ] Neither contains a governing-language clause.
- [ ] The owner block shows no postal address.
- [ ] A German device opens the German document; a Czech device opens the English one.
- [ ] Nothing in either policy contradicts the README — **and where they disagree, measure** rather than prefer ([#883](https://github.com/simonoppowa/OpenNutriTracker/issues/883)).
- [ ] The CI diff job fails when the two documents are made to diverge deliberately.
- [ ] The Sentry clause mentions coarse geolocation and the per-install identifier.
- [ ] No policy or in-app string calls crash reporting *anonymous* unless #894 has confirmed it may.

---

## Left open

Genuinely undecided, and deliberately not guessed at:

1. **Which catalogue entries exist** for *IP address*, *approximate location* and *connection identifiers*. [#871](https://github.com/simonoppowa/OpenNutriTracker/issues/871) enumerated the service catalogue, never the category one. If the vocabulary is thinner, use the closest catalogue category and carry the specifics in prose — the same shape as the search-term decision.
2. **Whether the 90-day search cache** appears in §7. Local, with a stated retention; a paragraph-level call.
3. **Whether Cloudflare Regional Services** applies to `*.supabase.co` for EU projects. Decides how strongly §3.2's residency sentence can be worded. Needs a written question to Supabase.
4. **Whether an Impressum is owed** — see §8. Not this document's to answer.
5. **Whether "anonymous" survives** in the crash-reporting consent label, now that a stable per-install UUID and a city are known to accompany every event ([#894](https://github.com/simonoppowa/OpenNutriTracker/issues/894)). Affects the label and possibly the payload, not §3.3's accuracy.
6. **Whether the README needs a third correction.** [PR #891](https://github.com/simonoppowa/OpenNutriTracker/pull/891) fixed *"no user or device identifier"* for the Supabase path; #889 found a persistent UUID going to Sentry, which is an identifier plainly rather than one a recipient derives. Folded into #894.

---

## Where the reasoning lives

This spec states conclusions. Every one has a ticket carrying the argument, the evidence, and what was **rejected** — which a spec cannot show, and which is half the value of an audit. Start from **Decisions so far** on [#867](https://github.com/simonoppowa/OpenNutriTracker/issues/867), or go straight to the investigation you want:

| Question | Ticket |
| :-- | :-- |
| Does the app still call the USDA FoodData Central API? | [#868](https://github.com/simonoppowa/OpenNutriTracker/issues/868) |
| What does Sentry receive at `tracesSampleRate = 1.0`? | [#870](https://github.com/simonoppowa/OpenNutriTracker/issues/870) |
| What can iubenda be made to express? | [#871](https://github.com/simonoppowa/OpenNutriTracker/issues/871) |
| Which permissions does the released build actually request? | [#872](https://github.com/simonoppowa/OpenNutriTracker/issues/872) |
| Where does the Supabase backend run, and what does it log? | [#869](https://github.com/simonoppowa/OpenNutriTracker/issues/869) |
| Is Cloudflare a named sub-processor under a Supabase DPA? | [#890](https://github.com/simonoppowa/OpenNutriTracker/issues/890) |
| Does Sentry attach the client IP on iOS? | [#889](https://github.com/simonoppowa/OpenNutriTracker/issues/889) |

Each ticket's resolution comment carries the verdict and the decisive evidence, quoted with a `file:line` or a URL. Fuller working — the sources that led nowhere, the alternate readings — is on throwaway `research/*` branches, following the same practice as earlier maps.

**Those branches are working notes and will go stale**, which is why nothing here depends on them: `privacy-supabase-subprocessors.md` describes a sub-processor list dated 1 June 2026, and `privacy-iubenda-expressiveness.md` describes a generator UI that will change. One of them had to be annotated as partly wrong within hours of being written, when [#889](https://github.com/simonoppowa/OpenNutriTracker/issues/889) disproved [#870](https://github.com/simonoppowa/OpenNutriTracker/issues/870)'s geolocation conclusion. Prefer the tickets.

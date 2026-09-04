# Store metadata editability: what needs a new version

Which App Store and Google Play listing fields can be changed without
shipping a new app version, and what "version-gated" actually means.
Compiled 2026-09-04 for [#1067](https://github.com/simonoppowa/OpenNutriTracker/issues/1067),
a child of map [#1062](https://github.com/simonoppowa/OpenNutriTracker/issues/1062).

## Research overview

**Question:** which App Store Connect listing fields can change without
submitting a new version, and what are Google Play's equivalent rules?

This is a fact, not a preference, and it decides the shape of map #1062's
endgame — whether the listing refresh rides 2.2.0, needs a 2.2.1 build, or
can reach the live page on its own.

**Sources (primary first):**

| Source | What it gives | Limits |
| :-- | :-- | :-- |
| App Store Connect Help — *Required, localizable, and editable properties*; *App and submission statuses*; *App information*; *Platform version information* | Apple's own per-property tables and the definition of "editable" | The tables give a bare ✓/✗ and defer the *when* to app status; several fields the ASO industry treats as settled are simply not addressed |
| App Store Connect Help — *Create a new version*; *Choose a build to submit*; *Submit an app*; *Overview of submitting for review* | The submission mechanics, including the build-selection rule that settles the metadata-only question | Written as procedures, so constraints appear as steps rather than as stated rules |
| App Store Connect Help — *Custom product pages*, *Product page optimization* (overview, configure treatments, apply a treatment) | The documented routes to changing live page assets without an app version | Both are marketing surfaces; neither Apple page frames them as a metadata workaround, which is how this doc uses them |
| developer.apple.com — *Creating Your Product Page*, *App Review* | The clearest plain-English statements Apple makes about update timing, plus the review-time figure | Marketing pages, not reference docs; they cover some fields and silently skip others |
| Play Console Help — *Create and set up your app*; *Prepare and roll out a release*; *Control when app changes are reviewed and published*; *Publish your app*; *Release app updates with staged rollouts*; *Run A/B tests on your store listing* | Play's listing model, review timing, and the managed-publishing hold/no-hold lists | Google documents behaviour by exception lists rather than by rule; the absence of a field from a list is weak evidence |
| Google Play Developer API — `edits.tracks` reference | The `TrackRelease` schema, relevant to editing release notes without a new bundle | A schema, not a behaviour contract; used here only as corroboration |
| Apple Developer News, 7 December 2010 — *Editing Metadata Once You've Submitted an App for Review* | Still the top search hit for this question | **Stale and contradicted by current docs.** Flagged below rather than relied on |

**No console access was available for this research.** Everything below is
from published documentation. Nothing here was verified against
OpenNutriTracker's own App Store Connect or Play Console records — see
*Still open* at the end, which is the other half of #1067.

**A note on how the confidence labels are used.** Apple documents this
subject unevenly. Some rules are stated in a sentence you can quote; others
exist only as a consequence of a procedure; and a few widely-known "rules"
are not in Apple's documentation at all. The labels distinguish those three
cases, because for this map the difference matters more than the answer.

---

## The short answer

**The working hypothesis mostly holds, with one consequential exception.**

| Field | Editable without a new app version? | Confidence |
| :-- | :-- | :-- |
| Promotional text | **Yes**, explicitly | High — stated |
| Description | No | High — stated |
| Subtitle | No | High — stated |
| App name | No | High — stated |
| Keywords | No | Medium — inferred |
| Screenshots | **Yes, via product page optimization** | Medium-high — stated for the mechanism, not for the field |
| App previews | **Yes, via product page optimization** | Medium-high — same |
| What's New | No (it *is* the version's release note) | High — structural |
| Support URL, marketing URL, privacy policy URL | Yes | High — stated |
| App icon | No | High — stated |

The exception is screenshots and app previews. The hypothesis says they are
version-gated; the direct route is, but Apple documents an indirect route
that puts new screenshots on the live default product page with no app
version involved. That is the single most important finding in this
document, and section 4 covers it.

**Play is not version-gated at all.** The store listing is a separate object
from the release, shared across every track, editable at any time. Its own
wrinkle is that release notes work the opposite way from Apple's.

---

## 1. Apple: what "editable" means, and why the tables under-answer

Apple's per-property tables mark fields with a bare ✓ in an *Editable*
column. The definition of that column lives on a different page:

> "If an app status indicates as editable below, you can edit app metadata
> when the app has this status."
> — *App and submission statuses*

So ✓ does not mean "at any time". It means "subject to app status", and the
status page then lists which statuses qualify. The statuses that permit
editing include **Prepare for Submission**, **Ready for Distribution**,
**Pending Developer Release**, **Rejected**, **Metadata Rejected**, and
**Developer Rejected**. **In Review** does not. Two statuses are partial and
both are called out specifically for images:

> "**Ready for Review** — [...] Note: Images and videos aren't editable in
> this state."

> "**Waiting for Review** — [...] While you're waiting for the review, you
> can edit certain app information and remove the build from review.
> However, you can't upload or edit screenshots or app previews."

**This is the practical answer to "can I edit while in review".** Between
hitting submit and the review starting, text metadata is still editable and
images are frozen. Once the status reaches In Review, nothing is editable —
though the build can still be pulled from review, which moves the app to
Developer Rejected and makes everything editable again at the cost of
restarting the queue.

**Confidence: high.** All of it is quoted from the status reference.

**The trap.** *Ready for Distribution is an editable status.* Read the
tables alone and you would conclude that a live app's description can be
rewritten in place. It cannot, and the reason is not on that page — it is
that "editable" is a property of the **version record**, and a released
version's editable fields are the ones listed in section 2. The tables
answer "is this field ever editable", not "does changing it reach users".
Anyone re-deriving this from Apple's tables will get it wrong the same way.

---

## 2. Apple: field by field

### Editable at any time, no version involved

**Promotional text.** The one field Apple states plainly, and it says so
twice:

> "Promotional text lets you inform your App Store visitors of any current
> app features without requiring an updated submission. This text will
> appear above your description on the App Store for customers with devices
> running iOS 11 or later. This property can't be longer than 170
> characters."
> — *Platform version information*

> "You can update promotional text at any time without having to submit a
> new version of your app."
> — *Creating Your Product Page*

**Confidence: high.** Hypothesis confirmed, in Apple's own words.

**Support URL, marketing URL, copyright, app review information, version
release settings.** All carry ✓ in the *Platform Version Information*
editable table, and App Review information is the one Apple explicitly
annotates: "It isn't visible to customers and can be edited at any time."

**Privacy policy URL, privacy choices URL, data types, pricing,
availability, secondary category.** All ✓. Note that pricing and territory
changes are documented as reaching the store without waiting for a version —
a different mechanism from the listing copy and not useful to this map, but
it explains why some console changes appear to go live instantly and others
do not.

### Version-gated

**App name.** The clearest statement Apple makes on the gated side:

> "You can edit it until you submit the app to App Review. Later, you can
> change the name when you create a new version or the status of the app
> version permits editing this property."
> — *App information*, Name

**Confidence: high.** Hypothesis confirmed.

**Description.**

> "You can update your app's description when you submit a new version of
> your app. If you want to share important updates more frequently, consider
> using your promotional text instead."
> — *Creating Your Product Page*

**Confidence: high.** Hypothesis confirmed. Note the second sentence — Apple
is explicitly positioning promotional text as the pressure valve for exactly
the situation this map is in.

**Subtitle.**

> "You can update your subtitle when submitting a new version of your app to
> help you determine the subtitle that's most effective for engaging users."
> — *Creating Your Product Page*

**Confidence: high.** Hypothesis confirmed.

**What's New.** Structurally version-scoped — Apple defines it as "A
description of the changes in this version of the app" and notes it "isn't
available for the first version of the app but required for all subsequent
versions". There is no "What's New" that exists apart from a version, so the
question of editing it independently does not arise.

**Confidence: high.**

**App icon.** Version-gated even through the optimization route, which is
the one place Apple draws the line explicitly. See section 4.

### Version-gated, but Apple never says so

**Keywords.** This is the field to be careful about. Apple's reference entry
for Keywords describes the format and the 100-byte limit and says "This
property is required and can be localized" — and stops. It does not say
keywords require a new version. The *Creating Your Product Page* marketing
page, which volunteers update timing for promotional text, description and
subtitle, is silent on keywords.

The conclusion that keywords are version-gated rests on indirect evidence:

- Keywords are version-level metadata, not app-level, so they live on a
  version record and inherit that record's editability.
- Apple's custom-product-page docs list "screenshots, previews, promotional
  text, or keywords" as the metadata a custom page carries, and require that
  metadata be submitted for review — establishing that keywords are a
  reviewed field, not a free-text one.
- The 2010 news item below asserts the opposite of free editing for
  keywords, and while it is stale in other respects, nothing has since
  reversed it.

**Confidence: medium.** The conclusion is very probably right and matches
universal industry practice, but **it is not documented by Apple**, and this
doc should not be cited as if it were. If the map ever depends on the
keyword timing specifically — for instance to justify a 2.2.1 that exists
only to change keywords — verify it in the console first, where the field
will simply be greyed out or not.

**Screenshots and app previews.** Same documentary gap: Apple's reference
entries describe the specs and say nothing about update timing, and
*Creating Your Product Page* skips them. The *direct* route is gated — the
status page's explicit "you can't upload or edit screenshots or app
previews" during Waiting for Review only makes sense if they belong to the
version. But unlike keywords, there is a documented way around it, which is
section 4.

---

## 3. Apple: can a version be submitted for a metadata-only change?

**This was the crux, and the answer is no — not without a new build.**

Apple's procedure for a new version has the build upload as a required step,
not an optional one:

> "6. Upload your new build to App Store Connect. In Xcode, increment the
> build string before you upload your build to App Store Connect [...]
> 7. When you're ready to submit your build, add it to your latest version,
> then submit your app to App Review."
> — *Create a new version*

The submission page states the prerequisite directly:

> "Before submitting an app version for review, provide required metadata
> and choose the build for the version."
> — *Submit an app*

And the rule that closes the last loophole — reusing the build already
shipped as 2.2.0 for a 2.2.1 metadata-only version:

> "If an earlier version of your app is Ready for Distribution, the list
> only includes builds you have uploaded since that version was released on
> the App Store."
> — *Choose a build to submit*

Once 2.2.0 is live, the build picker for 2.2.1 will not offer 2.2.0's
binary. A metadata-only App Store version therefore requires **uploading a
new build**, even if that build is byte-for-byte equivalent apart from the
version and build strings.

**Confidence: high** on the mechanism, **medium-high** on the phrasing of
the conclusion — Apple never writes the sentence "a metadata change requires
a new binary", but the three quotes above leave no room for another reading.

**Consequence for map #1062.** If the App Store description, subtitle, name
or keywords are to change and 2.2.0 has already been released, the map needs
a 2.2.1 build. Not a 2.2.1 *feature release* — a version bump and an
otherwise unchanged binary is sufficient and is a routine thing to submit —
but a build, a tag, a release pipeline run, and a full App Review pass.

**If 2.2.0 is still in Prepare for Submission, all of this is free.** The
listing changes go in the version record that is already there. That is why
the second half of #1067 is worth someone's console time before any of this
is scheduled.

---

## 4. Apple: the exception that changes the endgame

Screenshots and app previews have a documented route to the **live default
product page** with no app version involved.

Apple's App Review page lists what can be submitted on its own:

> Items submittable without a new app version: in-app events, custom product
> pages, and product page optimization tests.

And the submission overview confirms the model and its ceiling:

> "You can choose to submit items for review together with, or separately
> from, an app version."

> "A platform can have a maximum of two submissions under review at a time:
> one that includes an app version and one that includes items, like In-App
> Events or custom product pages, without an app version."

**Custom product pages** carry their own screenshots, app previews and
promotional text, are submitted independently once the app is approved
("If your app is already approved, you can choose to submit a custom product
page with or without an iOS app version"), and go live when approved. But
they are reachable only by their own URL — they do not change what a user
sees searching the App Store. Useful to the map later, as #1062 already
notes, not a route to fixing the default page.

**Product page optimization is the route.** Treatments vary the app icon,
screenshots and app previews. Two things Apple states make this work:

> "Before testing, ensure all metadata in your test treatments is approved.
> You can submit this metadata without submitting a new version of your
> app."
> — *Configure test treatments*

> "You can apply any of the treatments to your original product page on the
> App Store, as well as to versions in the Ready for Distribution or Prepare
> for Submission states, at any time."
> — *Apply a test treatment to your product page*

Together: upload the new screenshots as a treatment, submit that treatment
for review on its own, and once approved apply it to the original product
page. **New screenshots reach the live App Store listing without a new
build.** Applying does not require the test to have run to significance —
Apple's wording is "at any time".

Three constraints Apple states:

- **Icons don't come along.** "Keep in mind that only the app previews and
  screenshots from the treatment will be applied [...] To apply changes to
  the app icon, set it as the default icon in your next app version."
- **One treatment per test, and applying is irreversible** — "the action
  can't be undone".
- **Applying stops the test.** "If you apply a treatment while a test is
  still running, the test will automatically stop."

**Confidence: medium-high.** Every quote is Apple's, and they compose
cleanly. It is medium-high rather than high because Apple documents this as
a testing feature and nowhere endorses it as a screenshot-update mechanism,
so there may be console-side friction — eligibility conditions, or a
requirement that a test be configured and started before a treatment can be
applied — that the help pages do not describe. Worth confirming in the
console before the map commits to it.

**Why this matters beyond convenience.** Map #1062's first standing hazard
is that 2.2.0's rollout confounds any before/after read of the listing
change. Product page optimization does not merely dodge the need for a
build — it is a randomised concurrent test, which is the clean answer to
that confound rather than a workaround for it. The map already lists PPO
under "not yet specified", gated on whether traffic reaches significance.
This finding says the *asset delivery* half of PPO is useful to the map even
at traffic too low to ever reach significance, because applying a treatment
is unconditional.

---

## 5. Google Play: not version-gated

**The store listing is a separate object from the release.** Play Console
Help states it in one line:

> "Your app's store listing is shared across tracks, including testing
> tracks."
> — *Create and set up your app*

The main store listing holds app name (30 characters), short description
(80) and full description (4000), plus the graphics assets, and is edited at
*Grow users → Store presence → Main store listing*. Nothing about it is
attached to a version code or an app bundle. There is no Play equivalent of
Apple's version record, and therefore no Play equivalent of the
version-gating question.

**Confidence: high.** The absence of a gate is visible in the console's
information architecture as well as in the docs; no Play documentation
anywhere describes a listing field as requiring a release.

**Listing edits do go through review.** Play documents this by implication
rather than by statement. The managed-publishing page lists what is held
back pending your decision to publish:

> Held back: "Full and staged roll-outs of your releases"; "Launching and
> updating pre-registration"; "**Store listing changes, including changes
> made to custom store listings and live store listing experiments**"; "App
> content changes"; "Changes to your app category"; "Managed Play settings";
> "Changes to how testers are configured for a track".

Managed publishing holds *approved* changes until you release them, so a
listing change being on that list means it passes through review first.

> Not held back: "Increasing an existing staged roll-out to 100%";
> "**Updating your app's 'Release notes' section**"; "Changes to device
> exclusion rules"; "Changes to the membership of an email list or Google
> group used by a testing track"; "Unpublishing your app"; "Changes to your
> app's In-app products page"; "Price changes"; "Stopping store listing
> experiments".

**Confidence: medium-high** that listing edits are reviewed — the inference
from the hold list is sound and matches the console's "Changes not yet sent
for review" flow, but Google never writes "store listing changes are
reviewed" in as many words.

**Review time.** Play states a ceiling, not an average:

> "certain apps may be subject to extended reviews which may result in
> review times of up to 7 days or longer in exceptional cases"

For comparison, Apple publishes an average: "On average, 90% of submissions
are reviewed in less than 24 hours." Two things follow for sequencing.
First, **Play is the slower and less predictable of the two for a listing
change**, which inverts the usual assumption. Second, Apple's figure covers
all submissions including binaries, so it is not a metadata-only figure and
should not be quoted as one.

**Confidence: high** on both quotes; **medium** on the "Play is slower"
reading, since Google's number is a worst case and Apple's is an average.
They are not comparable statistics and this doc is deliberately not turning
them into a comparison table.

---

## 6. Google Play: "What's new", and the staged-rollout interaction

**Release notes are per-release, not part of the listing.** Up to 500
Unicode characters per language, entered when preparing a release, with a
"Copy from a previous release" affordance. They belong to the release, not
to the main store listing — which is why `changelogs/63.txt` in this repo is
keyed by version code.

**They can be updated after the fact, and updating them is not held.** The
managed-publishing exception list contains "Updating your app's 'Release
notes' section" among the changes that publish immediately. A thing that can
be *updated* and that publishes *immediately* is not a thing frozen at
release time.

Corroborating from the Play Developer API: `TrackRelease` carries
`releaseNotes` and `versionCodes` as independent fields, and `versionCodes`
is documented as "Version codes of all APKs in the release. Must include
version codes to retain from previous releases" — i.e. a track update
resubmits the existing version codes unchanged while other fields vary. That
is the shape of an API that supports editing notes in place.

**Confidence: medium-high.** Google does not state anywhere "you can edit
release notes of a live release", and the two pieces of evidence above are
both indirect. But they point the same way, and the operation is cheap to
attempt and self-verifying in the console. **Flagging this as one of the
places where the documentation does not say what everyone assumes it says** —
in this case the common assumption ("release notes are frozen once live") is
the one contradicted, not confirmed.

This is directly actionable for #1062: `changelogs/63.txt` covers only the
TDEE correction and mentions neither AI meal assistance nor workout import.
If build 63 is already live, the notes very likely can still be corrected
without a new release.

**Staged rollout does not segment the listing.** The listing is a single
global object; the rollout percentage governs who receives the *binary*.
A listing edit therefore reaches 100% of visitors regardless of where the
rollout sits, including users who have not yet been offered the update.

Google's own advice on the sequencing is unambiguous, and it is the sentence
map #1062 should plan around:

> "we recommend updating your store listing after your release rolls out to
> 100% of users"
> — *Release app updates with staged rollouts*

**Confidence: high** on the quote; **medium-high** on the mechanism, which
Google describes only by never suggesting otherwise.

**Store listing experiments**, for completeness: up to 2 variants against
the current listing, a configurable share of visitors split equally across
variants, one default-graphics experiment or up to five localized
experiments per app at a time, and experiments stop automatically after six
months, after which "no variants will be applied, and traffic will revert to
the current listing". The console estimates the traffic needed for
significance at setup time, which is where #1062's open question about
whether experiments are viable at this app's traffic gets answered cheaply,
without running anything.

---

## Claims that are repeated everywhere and are not documented

The most useful output of this research, and the part to carry forward.

**1. "Screenshots and description can be edited at any time."** This traces
to a real Apple source — an Apple Developer News item dated **7 December
2010**:

> "Once you have submitted your app for review, there is certain metadata
> which cannot be edited, such as keywords and the name of your app.
> However, some metadata can be edited at any time, such as screen shots,
> your marketing description, and your support URL."

It is still a top search result and it is **stale**. It refers to iTunes
Connect and points at a developer guide that no longer exists, and current
documentation contradicts it directly: the status reference says screenshots
and previews cannot be edited while Waiting for Review, and *Creating Your
Product Page* says the description updates "when you submit a new version".
Do not cite it. Expect to meet it again — it is the likely origin of the
belief, in this repo and elsewhere, that App Store screenshots are freely
editable.

**2. "Keywords are version-gated."** Almost certainly true, universally
believed, and **not stated in any Apple documentation found**. See section 2.

**3. "Screenshots are version-gated."** The *direct* route is, by
implication. But stated flatly it is now misleading, because product page
optimization is a documented route around it (section 4). Anyone repeating
the flat claim is describing the console's default path, not Apple's rules.

**4. "You can update screenshots without a new build (since 2021)."**
Circulates in ASO vendor content, and there is a real change underneath it —
the January 2022 submission update, which Apple announced as "You'll be able
to submit multiple items, submit without needing a new app version, view
past submissions, and more." But what that change enabled was independent
submission of *in-app events, custom product pages and product page
optimization tests* — not free editing of the default page's screenshots.
The popular form of the claim overstates a real feature. Treated here as
vendor-blog framing, corroborated only in the narrower form section 4 sets
out.

**5. "Play store listing changes are reviewed."** True as far as can be
determined, and inferred from the managed-publishing hold list rather than
stated. See section 5.

**6. "Play release notes are frozen once a release is live."** Contradicted,
not confirmed, by the evidence available. See section 6.

---

## What this means for map #1062

1. **The map's hypothesis holds for the copy fields.** Description,
   subtitle, name and (very probably) keywords cannot reach the live App
   Store listing without a version submission. If 2.2.0 has shipped, that
   means a 2.2.1 build exists in the map's future — a version bump on an
   unchanged binary, but a full release-pipeline run and App Review pass.

2. **Screenshots are the exception and should be planned separately from
   the copy.** Product page optimization delivers them to the live default
   page with no build, and doing so is a randomised concurrent test rather
   than a before/after — which is a real answer to the map's first standing
   hazard, not a dodge around it. This is worth a decision ticket of its own.

3. **Promotional text is the free lever, and Apple says so.** 170
   characters, editable whenever, above the description. It is the only App
   Store copy this map can change today irrespective of where 2.2.0 sits.

4. **Play needs no version at all,** but sequence the listing paste *after*
   the rollout reaches 100%, per Google's own recommendation, and budget up
   to 7 days for review rather than assuming it is instant.

5. **The Play changelog gap is probably still fixable in place.** Release
   notes appear to be editable after release and publish without being held.
   Cheap to attempt, self-verifying, and it closes the `changelogs/63.txt`
   gap without a new build.

6. **The console check is now high-value, not housekeeping.** The entire
   difference between "free" and "a 2.2.1 build" is one fact: whether 2.2.0
   is still in Prepare for Submission. That is the other half of #1067.

---

## Still open — needs console access

**Everything in this document is from published documentation. None of it
was checked against this app's actual console state, because that requires
credentials this research did not have.** The second half of #1067 remains
open and needs a human signed in to both consoles:

- **Where 2.2.0 sits in App Store Connect** — Prepare for Submission,
  Waiting for Review, In Review, Pending Developer Release, or Ready for
  Distribution. This single fact decides whether the App Store copy changes
  are free or cost a 2.2.1 build. Do not assume it from the tag date.
- **Which Play track holds build 63, and at what rollout percentage.**
  Google's advice is to update the listing after 100%, so the percentage is
  a scheduling input.
- **What the live Play "What's new" actually says** — whether it matches
  `fastlane/metadata/android/en-US/changelogs/63.txt` or something pasted by
  hand, and whether it is editable in place as section 6 predicts.
- **What the live App Store listing currently says at all.** The App Store
  metadata exists nowhere in this repo, so subtitle, keywords, promotional
  text and description are unknown to everyone reading this.
- **Whether product page optimization is available and startable for this
  app,** which is the console-side confirmation section 4 asks for before
  the map relies on the screenshot route.
- **Whether keywords are in fact greyed out** for a released version. Two
  seconds in the console settles what Apple's documentation does not say.

# #937 — Does Play's Data safety form require declaring health data that is read but never transmitted?

Research for map [#935](https://github.com/simonoppowa/OpenNutriTracker/issues/935). Sources are Google-owned only
(support.google.com, developer.android.com). Fetched 2026-08-28.

## Verdict (question 5)

**(a) No entry.** For Health and fitness, OpenNutriTracker 2.1.0's Data safety form should carry no
data type at all — not an entry marked collected, and not an entry marked ephemeral.

Reasoning in one line: the form's scope is *collection and sharing*, "collect" means transmitting off
device, and Google states in terms that locally-processed data "does not need to be disclosed"; the
ephemeral option is not an alternative to that, it is a narrower carve-out **for data that does leave
the device**, so it does not apply to data that never leaves.

The broader "accesses" standard is real, but it is discharged by the **privacy policy, in-app
disclosure, and the Health apps declaration** — not by the Data safety form.

---

## 1. Does the form require an entry for health data accessed but never transmitted?

**No.** Two rules, both on the Data safety help page
(<https://support.google.com/googleplay/android-developer/answer/10787469>):

- Definition: *"'Collect' means transmitting data from your app off a user's device."*
- Carve-out: *"User data accessed by your app that is only processed locally on the user's device and
  not sent off device does not need to be disclosed."* The same page gives the worked example — an app
  granted location permission that uses it only for on-device functionality and never sends it to a
  server does not disclose location as collected.

The carve-out is phrased in exactly the terms of this question: **accessed** by the app, **not sent off
device**, therefore **not disclosed**. Note the word "accessed" in Google's own sentence — Google
anticipated the access/collect gap here and resolved it in favour of non-disclosure.

The form is scoped the same way in policy: *"All developers must complete a clear and accurate Data
safety section for every app detailing collection, use, and sharing of user data"*
(<https://support.google.com/googleplay/android-developer/answer/10144311>). Collection, use, sharing —
not access.

Secondary confirmation from the user-facing page
(<https://support.google.com/googleplay/answer/11416267>): data is *"generally considered 'collected'
when the developer uses their app to retrieve data off your device"*, and *"shared"* when *"accessed by
the app and transferred to a third party"*. Both hinge on the data moving.

## 2. Does the User Data policy's broader "accesses" standard bite on the Data safety form?

**No — it lands on the privacy policy and in-app disclosure instead.** This is settled by a single
sentence in the User Data policy
(<https://support.google.com/googleplay/android-developer/answer/10144311>):

> "The privacy policy must, together with any in-app disclosures, comprehensively disclose how your app
> accesses, collects, uses, and shares user data, **not limited by the data disclosed in the Data safety
> section**."

That clause does the whole job. Google explicitly contemplates that the privacy policy covers *more*
than the Data safety section, and names *access* as one of the things the policy — not the form — must
cover. The two artifacts have deliberately different scopes: the form is a collection/sharing label,
the privacy policy is the comprehensive disclosure. The same construction is repeated in the Health
Content and Services policy
(<https://support.google.com/googleplay/android-developer/answer/16679511>).

The other place the "access" standard bites is **prominent disclosure and consent**: where access,
collection, use or sharing falls outside a user's reasonable expectation, an in-app disclosure is
required (<https://support.google.com/googleplay/android-developer/answer/11150561>). That is a runtime
UI obligation, again not a Data safety form entry.

One genuine complication, worth recording because it looks like a counter-example and is not one.
Android's *Declare your app's data use* guidance
(<https://developer.android.com/privacy-and-security/declare-data-use>) lists Health Connect,
Google Fit, `ACTIVITY_RECOGNITION` and `BODY_SENSORS` under Health and fitness. But its framing sentence
is: *"There are different ways that your app, or a library included in your app, **may access** user data
related to health & fitness. The following list provides several examples but isn't exhaustive."* It is
a checklist for *finding* candidate data types, not a rule that using the API forces a declaration. The
collect/share test still decides whether each candidate ends up on the form. Same page also confirms
Health Connect access maps to the **Health info** / **Fitness info** types, which is what the entry
*would* be called if one were required.

## 3. What "ephemeral processing" actually means — and why it does not apply

Google's definition, on the Data safety page: *"Processing data 'ephemerally' means accessing and using
it while the data is only stored in memory and retained for no longer than necessary to service the
specific request in real-time."*

The decisive part is the sentence that frames it: *"User data transmitted off device that is processed
ephemerally needs to be included in your form response, but if it meets the standard below, it will not
be disclosed in your app's Data safety section on Google Play."*

So ephemeral processing is a property of **data that has already left the device**. The user-facing page
says the same thing from the other side: developers need not disclose data as collected *"when your data
is sent off the device but only processed ephemerally"*, with the canonical example being a weather app
that sends location to a server, uses it in memory to answer one request, and retains nothing
(<https://support.google.com/googleplay/answer/11416267>).

Two consequences for this ticket:

1. **"Read into memory and written to local storage" does not qualify** — as the ticket suspected, but
   the reason is not primarily the disk write. It is that ephemeral processing presupposes transmission.
   Data that is never transmitted never enters the ephemeral question's domain. The AES-encrypted Hive
   box would *additionally* fail the "only stored in memory / retained no longer than the request"
   standard, so it fails on both counts.
2. **The form will not even offer the option.** "Is this data processed ephemerally?" is a per-data-type
   question inside the *Data usage and handling* step, reached only after a type has been marked
   collected or shared. There is no way to answer "ephemeral" without first asserting collection — which
   for this data would be a false statement.

So option (c) is not a cautious middle path. Marking health data ephemeral would assert that the app
transmits it off device and discards it, which is factually wrong in the opposite direction.

## 4. Does the Health apps declaration carry the disclosure instead?

**Yes, and they are not in contradiction — they answer different questions.**

- The **Health apps declaration** (<https://support.google.com/googleplay/android-developer/answer/14738291>)
  asks *which health features the app offers* and *which Health Connect data types it accesses*, with a
  written justification per permission. It is an access-and-purpose declaration. Every published app must
  complete it, including apps on closed and open testing, and apps with no health features at all (which
  tick "My app does not have any health features"). It does **not** ask how the data is stored,
  transmitted, or shared.
- The **Data safety form** asks what the app *transmits off device* and to whom.

Android's own publishing guide presents them as two separate steps in the release checklist
(<https://developer.android.com/health-and-fitness/health-connect/publish> and
<https://developer.android.com/health-and-fitness/guides/health-connect/publish/declare-access>): provide
information for the Data safety section, *and* fill out the Health apps form on the App content page.
Neither page says the Health apps declaration forces a matching Data safety entry, and neither says a
Health Connect app must declare health data as collected.

So the correct 2.1.0 posture is not "silence": it is a **Health apps declaration naming Activity /
Nutrition and the specific Health Connect types read (workouts, body fat percentage), a privacy policy
that describes reading and on-device storage of that data** — which #933 landed on 2026-08-27 — **and a
Data safety form with no Health and fitness entry.** Each artifact answers its own question truthfully.
A reviewer comparing them sees access declared where access is asked about, and no transmission claimed
where transmission is asked about.

Note also that the app still has a non-empty Data safety form overall — Open Food Facts, the Supabase
backend and Sentry are real egress paths, so "My app doesn't collect or share any user data" is *not*
the answer at the top level. Only the Health and fitness category is empty.

---

## Where the evidence is weaker than I would like

1. **No Google page answers this exact fact pattern in its own words.** There is no sentence reading
   "health data read from Health Connect and stored only on device need not be declared." The verdict is
   an application of the general on-device carve-out to health data. The carve-out's own worked example
   is *location*, not health, and health data gets extra scrutiny elsewhere in Play policy. The inference
   is sound and the carve-out is unqualified by data type, but it is an inference.
2. **The on-device carve-out's placement.** It sits in the collection discussion on the Data safety help
   page as a not-in-scope item. I am confident of the sentence's wording (it appears identically across
   two independent fetches and a search summary); I am less confident of the exact heading it sits under,
   which matters only if someone argues about its precedence.
3. **Reviewer behaviour is not documentation.** Play reviewers are known to bounce Health Connect apps
   that declare nothing under Health and fitness, on the theory that the permission implies collection.
   That is not a documented rule and nothing found here supports it, but it is a practical risk. The
   mitigation is not to over-declare — a false "collected" claim is itself an inaccurate label, and
   inaccuracy is the thing the User Data policy actually penalises — but to keep the justification text
   in the Health apps declaration explicit that access is read-only and storage is local, so the
   reviewer has the answer in front of them.
4. **The verdict is conditional on egress staying clean.** "No entry" holds only while *nothing derived
   from* health data leaves the device. Worth a specific check that Sentry breadcrumbs, crash payloads
   and any analytics cannot carry workout or body-fat values, since Google's test is about the data
   leaving, not about which subsystem sends it. If any derived value escapes, Health and fitness becomes
   a collected entry.
5. **The AI feature will reopen this.** Out of scope per #935, but a model call that includes health
   context in a prompt is transmission, and would flip this answer — and *that* is the case where the
   ephemeral option becomes the live question rather than a category error.

# How finely can Play's "Encryption in transit" declaration be scoped?

Research for [#751](https://github.com/simonoppowa/OpenNutriTracker/issues/751), on
map [#732](https://github.com/simonoppowa/OpenNutriTracker/issues/732). Researched
2026-08-22 against Google's and Apple's own documentation, plus a live Data safety
listing.

**The short answer: it cannot be scoped at all.** It is one app-wide yes/no, it may
only be answered *yes* if it holds for every byte the app sends off-device, there is
no way to express "encrypted unless the user configures otherwise", and the
prominent-disclosure exception does not reach it.

---

## 1. Per data type, per purpose, or once for the app?

**Once for the app.** Three independent confirmations:

The form asks it a single time, in the *Data collection and security* step, phrased as
one question about the app as a whole:

> Is data collected or shared by your app using encryption in transit to protect the
> flow of user data from the end user's device to the server.

The user-facing help describes it as one of several *Security practices*, not as a
column in the data table — developers "can describe certain security practices they
use", including that the app
> Encrypts data that it collects or shares while it's in transit.

And a live listing renders it exactly that way. On the Play Console app's own Data
safety page the sections are **Data shared**, **Data collected**, **Security
practices** — with the per-type list carrying only category and purpose ("App
functionality", "Analytics", "Account management"), and the encryption statement
appearing once, in its own section, as:

> Your data is transferred over a secure connection

**A search summary claimed this is declared "per data type". It is not, and no
primary source says so.** Recorded here because it is the plausible-sounding wrong
answer, and because it would have made the rest of this ticket look tractable.

## 2. So: do Photos and Health and fitness reach other destinations?

**The question dissolves.** It only mattered if the declaration were per data type. It
is not, so which categories the AI feature touches has no bearing on the answer.

For completeness, the app's compiled-in destinations are all HTTPS — Open Food Facts,
USDA FDC, the Supabase reference backend, Sentry, Unsplash, and the three hosted AI
providers. `grep` finds **no `http://` request URL anywhere in `lib/`**. There is no
Health Connect or HealthKit integration. So today the declaration is honest, and a
user-typed `http://` address under [#758](https://github.com/simonoppowa/OpenNutriTracker/issues/758)
would be the app's only plaintext path.

> **Update, 2026-09-04.** Two facts in the paragraph above have expired, and the
> findings are left as read on 2026-08-22 rather than rewritten. **#758 shipped**,
> so the conditional in the last sentence is no longer conditional: the app permits
> plaintext to a private address, which is the only plaintext path and it now
> exists. *"Today the declaration is honest"* should not be carried forward — the
> live form still answers **Yes**, and reconciling that is an acceptance criterion
> on [#1050](https://github.com/simonoppowa/OpenNutriTracker/issues/1050). Section 3
> below is the part that still holds and is the reason it needs a decision rather
> than an edit. Separately, **2.2.0 added workout import**, so "there is no Health
> Connect or HealthKit integration" is out of date; it does not change this
> question, and what it does change for the Data safety form is
> [#937](https://github.com/simonoppowa/OpenNutriTracker/issues/937).

## 3. Can a conditional truth be expressed?

**No.** Google is explicit that the declaration is all-or-nothing:

> In Play's Data safety section, developers can only declare encryption in transit if
> it applies to **all** user data that their app (including all its SDKs and
> libraries) collects and transmits off the user's device.

And the form is scoped to the union of behaviour, not the common case:

> Your Data safety section describes the sum of your app's data collection and sharing
> across all its versions currently distributed on Google Play.

> If any of the collection, uses, or linkages are present in **any** version of the app
> presently distributed on Google Play, anywhere in the world, you must indicate such
> on the form.

There is no documented exception for a path that is optional, off by default, or
reachable only after the user types an address. "Encrypted unless the user chooses
otherwise" has nowhere to go on this form.

## 4. Does the prominent-disclosure exception help?

**No — it is about sharing, not about encryption.** `docs/ai-legal-constraints.md`
quotes the exception in its *sharing* context, and that is the only place it applies:

> Transferring user data to a third party based on a specific user-initiated action,
> where the user reasonably expects the data to be shared, or based on a prominent
> in-app disclosure and consent.

That exempts a *disclosure of sharing*. It says nothing about the security-practices
question, and Google documents no equivalent carve-out for it. An in-app disclosure —
however prominent, however clearly the user opted in — does not let the box stay
ticked.

## 5. What a browsing user sees when it is unchecked

**Not established, and I could not settle it from documentation.** The help page
describes what a developer *can* declare and never states how the absence renders.

The live listing above shows the line present. What is not confirmed is whether an
app without the declaration shows **nothing** in that position or an explicit negative
("Data isn't encrypted"). The difference matters: silent absence is a badge not earned,
an explicit negative is a warning shown next to a nutrition app handling health data.

**A build ticket must not guess this.** It is one lookup on any listed app known not to
declare encryption — cheap to settle, and worth settling before the form is submitted
rather than after.

## 6. Apple

**There is no equivalent field, so iOS is unaffected.** App Privacy asks four things —
data types collected, how each is used, whether each is linked to identity, and whether
any is used for tracking. It asks nothing about transport security, TLS, or ATS.

This is a real asymmetry rather than a gap in the research: the same feature costs
something on Play and nothing on the App Store. #736 considered only Play, and that
turns out to have been the right place to look.

---

## What this means for #736

**It is worse than #736 assumed.** That decision recorded:

> The "Encryption in transit" declaration remains true — HTTPS to whatever endpoint.

That sentence is now false, and `docs/ai-legal-constraints.md:817` should be corrected
rather than defended — which #736 already anticipated. What it did not anticipate is
the *scope* of the correction: because the declaration is app-wide and all-or-nothing,
permitting one plaintext path to a private address means the entire app stops being
able to claim "Your data is transferred over a secure connection" — for the diary, the
weight log, the food searches, the crash reports, everything, for every user, including
the overwhelming majority who never enable the AI feature at all.

**One question could overturn this, and it is not settled.** Play defines collection as

> "Collect" means transmitting data from your app off a user's device

which reads as destination-agnostic, and it confirms that

> User data accessed by your app that is only processed locally on the user's device
> and not sent off device does not need to be disclosed.

Neither passage addresses a server the **end user** operates — not the developer, not a
third party, receiving data the developer never sees. Every worked example in the
documentation assumes the recipient is one of those two parties. If a user-run endpoint
is outside "collection" and "sharing", the encryption declaration never covered that
traffic and nothing needs to change. If it is inside, the badge is forfeit app-wide.

**That is the decision-grade question, and documentation cannot answer it.** It wants
Play Developer Support in writing, which is slow but definitive, and it should be asked
before a form is submitted on a guess. Until then the honest reading is the
conservative one: assume the traffic counts.

If it does count, that is grounds to revisit the private-addresses-only decision in
#736 — for example requiring `https://` for every user-supplied endpoint, which would
keep the declaration intact at the cost of a reverse proxy in front of Ollama and,
per #736's own reasoning, "a feature nobody could use". That trade is a decision, not a
research finding, and it belongs back on the map rather than here.

---

## What the listing shows when the box is **not** ticked

Read on **2026-08-24**, from live public listings, on the **web surface**. Google's
own help page does not state the user-facing wording for the negative case, so
this had to come from a real listing. #817.

**It is an explicit negative, not a silent omission.**
[SHAREit](https://play.google.com/store/apps/datasafety?id=com.lenovo.anyshare.gps)
(`com.lenovo.anyshare.gps`) renders, verbatim:

> **Security practices**
>
> **Data isn't encrypted**
> Your data isn't transferred over a secure connection
>
> **Data can't be deleted**
> The developer doesn't provide a way for you to request that your data be deleted

Compare the same section on
[OpenNutriTracker's own listing](https://play.google.com/store/apps/datasafety?id=com.opennutritracker.ont.opennutritracker),
which does declare it:

> **Data is encrypted in transit**
> Your data is transferred over a secure connection

So the two states are symmetrical sentences in the same block, and dropping the
declaration replaces a reassurance with a warning rather than removing a line.
Note that OpenNutriTracker already carries one negative there — *"Data can't be
deleted"* — which is what confirmed the block renders negatives at all.

**The Security practices block disappears entirely when nothing is collected or
shared.** [VLC](https://play.google.com/store/apps/datasafety?id=org.videolan.vlc)
and [Kodi](https://play.google.com/store/apps/datasafety?id=org.xbmc.kodi) both
declare *"doesn't collect or share any user data"* and show no encryption row at
all. That is a third state, and it bears on #816 rather than on this question —
see below.

**Not checked: the Play Store app surface.** #751 found one Play surface
rendering a populated field as empty, so the two are worth comparing. The
device was locked at the time and unlocking someone's phone is not a research
step.

### Incidental, and it bears on #816

VLC and Kodi both stream from servers the user runs, over plain HTTP on a local
network, and both declare **no collection at all**. Two large, long-established
open-source projects in the same shape as this app have therefore answered
#816's question in practice: a machine the user operates is not treated as
collection. That is precedent, not authority — the form runs on the honour
system and neither project's reasoning is published — but it is the closest
real-world reading available, and it points the opposite way from the
conservative assumption.

---

## Sources

- [Provide information for Google Play's Data safety section — Play Console Help](https://support.google.com/googleplay/android-developer/answer/10787469)
- [Understand app privacy & security practices with Google Play's Data safety section — Google Play Help](https://support.google.com/googleplay/answer/11416267)
- [Data safety listing for Google Play Console (live example)](https://play.google.com/store/apps/datasafety?id=com.google.android.apps.playconsole)
- [Declare your app's data use — Android Developers](https://developer.android.com/privacy-and-security/declare-data-use)
- [App Privacy Details — Apple Developer](https://developer.apple.com/app-store/app-privacy-details/)

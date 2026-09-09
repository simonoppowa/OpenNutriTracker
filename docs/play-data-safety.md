# Play Data safety: what is declared, and what the app does

The Data safety form is answered in the Play Console and uploaded by nobody —
both Play lanes set `skip_upload_metadata`, so nothing in this repo can change
it. This file is the record of what the answers *should* be, so the next person
to open the form is not re-deriving it from the code.

**Read this with [RELEASING.md](RELEASING.md)'s "Check the Play data-safety
declaration still matches what the app does" step.** That step is the one whose
failure mode is the app being pulled rather than a bad release.

## What is live today

Read off the public listing on 2026-09-08
(`play.google.com/store/apps/datasafety?id=com.opennutritracker.ont.opennutritracker`):

| | |
|---|---|
| **Shared** | App activity → In-app search history |
| **Collected** | App info and performance → Crash logs, Diagnostics<br>Location → Approximate location |
| **Security** | Data is encrypted in transit · **Data can't be deleted** |

## The four things that are wrong

### 1. In-app search history is shared but not collected

This is the one a reviewer can spot without reading any code, because the
framework has no such state: sharing is defined as transferring data you
collected, so a type that is shared and not collected is a contradiction on the
face of the form. Tracked as
[#1094](https://github.com/simonoppowa/OpenNutriTracker/issues/1094).

The search term is transmitted — to Open Food Facts, an independent third
party, and to the Supabase food backend.

> **Set:** App activity → In-app search history → Collected = **Yes**,
> Required, Purpose = App functionality. Keep Shared = Yes. Do **not** mark it
> *Processed ephemerally* — Open Food Facts' retention is not this project's to
> warrant, and the privacy policy already says so.

### 2. Photos are not declared, and the app sends them to a third party

Verified in the shipped code, not inferred: the AI meal-photo path
base64-encodes the photo and POSTs it to whichever provider the user
configured.

- `lib/features/add_meal/data/model_meal_photo_interpreter.dart:63` —
  `base64Data: base64Encode(photo.bytes)`
- destinations: `https://api.openai.com/v1/responses`
  (`openai_meal_items_api.dart:27`), `https://api.anthropic.com/v1/messages`
  (`anthropic_meal_items_api.dart:16`),
  `https://openrouter.ai/api/v1/chat/completions`
  (`openai_compatible_meal_items_api.dart:83`), or a user-supplied address.

There is no Photos entry on the live record at all. Tracked as
[#1050](https://github.com/simonoppowa/OpenNutriTracker/issues/1050).

> **Set:** Photos and videos → Photos → Collected = **Yes**, Shared = **Yes**,
> Processed ephemerally = No, **Optional** (the feature is inert until the user
> saves a credential), Purpose = App functionality.

### 3. The typed meal line is not declared under any type

The free-text meal description from the multi-item add screen goes to the same
providers. Data safety is answered per data *type*, so the existing App
activity entry does not cover it.

> **Set:** App activity → Other user-generated content → Collected = **Yes**,
> Shared = **Yes**, Optional, Purpose = App functionality.

A meal description is not Health and fitness data — that category is medical
records, symptoms and exercise, not what someone ate.

### 4. "Data can't be deleted" — and what the in-app path really deletes

The app has a delete-all-user-data path (Settings → delete all data), but it
is narrower than "everything", and the answer on the form has to match what
it does rather than what its name suggests.

`DeleteAllUserDataUsecase.deleteAll()` clears the **active profile's** boxes —
config, intake, user activities, user, tracked days, weight log, water and
fasting — plus the device-wide AI credential store. It deliberately leaves
alone the shared content libraries (custom meals, recipes, activity
templates), the shared app settings and every other profile, because those
belong to all profiles and wiping them here would take them from the others
too. Its own comment says so.

It also contacts nobody. Search terms already sent to Open Food Facts or the
backend, and anything sent to an AI provider under the user's own key, are
outside its reach — so it cannot delete the off-device data this same form
declares as collected.

> **Set:** the deletion answer to say an in-app path exists for the profile's
> own on-device data. Do not let it imply deletion of the data declared as
> leaving the device, and do not describe it as wiping everything the app
> holds — shared libraries and other profiles survive it.

## Health and fitness: unchanged, and deliberately

Health Connect data is read and kept on the device — it is never transmitted —
so under Play's definition ("collect" means transmitting off the device) it is
not collected and stays undeclared. That reasoning was settled in
[#937](https://github.com/simonoppowa/OpenNutriTracker/issues/937); this file
records it so it is not reopened every release.

What *did* change on 2026-09-08 is the permission set behind it. Play's Health
Connect permissions policy enforced against `READ_BODY_FAT`, `READ_DISTANCE`
and `READ_STEPS` as excessive, and the app now declares only `READ_EXERCISE`
and `READ_TOTAL_CALORIES_BURNED`. The **Health apps declaration** (Play Console
→ App content) has to be brought in line with that in the same pass — it was
last edited before any health permission existed in the app.

## Still open, needing a decision rather than a lookup

- **Approximate location.** It is declared as collected. Whatever justified it
  should be written down here, or the entry removed.
- **"Encrypted in transit" vs the own-server AI provider.** The own-server
  provider accepts an `http://` address for private/loopback destinations. The
  form's answer is app-wide with no conditional, so either that carve-out goes
  (`lib/core/utils/plaintext_destination_guard.dart`) or the answer becomes No.
  See [#816](https://github.com/simonoppowa/OpenNutriTracker/issues/816).
- **The provider API key as a user identifier.** It travels on every AI request
  and works as a stable per-user handle at the vendor. Whether that is a
  "User ID" the app collects is a genuine judgment call — the argument against
  is that it is the user's own account at a counterparty they chose. Decide it
  once and record the answer beside #1050 so it is not re-derived.

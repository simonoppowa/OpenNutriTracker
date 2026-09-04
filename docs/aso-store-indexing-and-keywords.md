# Store indexing and the calorie-tracker keyword landscape

Which listing text each store actually searches, and which terms
OpenNutriTracker could realistically rank on. Compiled 2026-09-04 for
[#1065](https://github.com/simonoppowa/OpenNutriTracker/issues/1065), a child
of the 2.2.0 store-listing map
[#1062](https://github.com/simonoppowa/OpenNutriTracker/issues/1062).

## Research overview

**Question:** how does each store index a listing for search, and what is the
keyword landscape for a calorie tracker?

The point is not a keyword list to stuff. It is knowing which 30-character
and 100-character slots are load-bearing on each store *before* anyone drafts
copy for them — and knowing which widely-repeated ASO claims the platforms
do not actually document.

**Sources (triangulated):**

| Source | What it gives | Limits |
| :-- | :-- | :-- |
| Apple, [App Store search](https://developer.apple.com/app-store/search/) and [App Store product page](https://developer.apple.com/app-store/product-page/) | The only place Apple enumerates its text-relevance inputs, and its keyword-field rules | Marketing guidance, not a spec; no weights, no algorithm detail |
| Apple, App Store Connect Help — [App information](https://developer.apple.com/help/app-store-connect/reference/app-information/), [Platform version information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information), [Set your developer name](https://developer.apple.com/help/app-store-connect/create-an-app-record/set-your-developer-name) | Authoritative field limits and field semantics | Contradicts the marketing pages on one limit (see below) |
| Apple, [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) §2.3.7 | What gets a listing rejected | Enforcement rules, not ranking rules |
| Google, Play Console Help — [Best practices for your store listing](https://support.google.com/googleplay/android-developer/answer/13393723), [Get discovered on Google Play search](https://support.google.com/googleplay/android-developer/answer/4448378), [App visibility and discovery issues](https://support.google.com/googleplay/android-developer/answer/9042516) | Field limits, and the only sentence naming Play's search inputs | Google never publishes an indexed-field list; the pages disagree with each other on field *names* |
| Google, [Metadata policy](https://support.google.com/googleplay/android-developer/answer/9898842) and [App Discovery and Ranking](https://support.google.com/googleplay/android-developer/answer/9958766) | The repetition rule, and the ranking-factor taxonomy | Policy language ("violation"), deliberately vague on ranking |
| [iTunes Search API](https://itunes.apple.com/search?term=calorie+counter&entity=software&country=us) — 17 queries run 2026-09-04, `country=us`, `entity=software` | Apple-operated, reproducible, unauthenticated. Shows *who ranks* and what competitors put in their 30-char name | Not documented to match on-device App Store search ranking. Returns no subtitle and no keyword field. Treat ordering as directional |
| `play.google.com/store/search` — 7 queries run 2026-09-04, `hl=en_US&gl=US`, unauthenticated | Real Play web search. Shows who ranks and the exact 30-char titles | Web results need not match on-device Play results; Play personalises. Treat ordering as directional |
| Live listing records — [iTunes Lookup for id6451490901](https://itunes.apple.com/lookup?id=6451490901) and the Play listing page | Ground truth on what the two live pages currently say | Point-in-time snapshot |
| ASO-vendor guides (AppFollow, App Radar, AppTweak, Phiture, and others) | Consensus practitioner lore | **Corroboration only.** Much of this genre is SEO content selling ASO tooling. Every vendor claim below is labelled as vendor lore and separated from what the platform documents |

**There is no search-volume or keyword-difficulty data in this document, and
none was invented.** Apple's search-term report lives in App Store Connect
and arrives with the baseline ticket
([#1064](https://github.com/simonoppowa/OpenNutriTracker/issues/1064)); Play
does not expose per-term volume at all outside its own console. Every
statement about a term's competitiveness below is grounded in an *observed
result set* — who actually ranks for the query today — not in a number.
Where a claim is intuition, it says so.

**Two conventions used throughout:**

- **Documented** means a platform primary source states it in words. Quoted.
- **Inferred** means the primary sources imply it but never say it. These are
  called out deliberately, because the most valuable output of this ticket is
  the boundary between the two — several universally-repeated ASO claims sit
  on the inferred side.

---

## Part 1 — How each store indexes

### The field inventory

| Field | Apple limit | Apple: documented as a search input? | Play limit | Play: documented as a search input? |
| :-- | :-- | :-- | :-- | :-- |
| App name / title | 2–30 chars | **Yes** — "title" | ≤ 30 chars | **Yes** — "app titles" |
| Subtitle | ≤ 30 chars | **Yes** | *(no equivalent field)* | — |
| Keyword field | 100 chars *or* 100 bytes (sources disagree) | **Yes** | *(no equivalent field)* | — |
| Short description | *(no equivalent field)* | — | ≤ 80 chars | **No — never stated** |
| Full description | 4000 chars | **No — and see below** | 4000 chars | **Yes** — "app descriptions" |
| Promotional text | ≤ 170 chars | **Explicitly not** | *(no equivalent field)* | — |
| Category | primary + secondary | **Yes**, both | one category | **Yes** — "category" |
| Developer name | set once, immutable | **Yes** — "company name" | editable | **Yes** — "developer names" |
| What's New / changelog | 4000 chars | Not mentioned | 500 chars — widely reported, not confirmed from a Play primary page here | Not mentioned |

Every limit in this table is quoted from a platform primary source in the
sections below. **Confidence: high** for every limit except the Apple keyword
field, which is genuinely ambiguous.

---

### Apple: what is documented

**The text-relevance inputs are enumerated, once.** From
[App Store search](https://developer.apple.com/app-store/search/):

> "Search results are based on a number of factors, including text relevance
> (matches for your app's title, subtitle, keywords, and primary category),
> as well as user behavior (downloads, ratings and reviews, and more)."

That sentence is the whole documented basis for "Apple indexes name +
subtitle + keywords". It holds. **Confidence: high.**

**Both categories are indexed, not just the primary.** The same page, in a
later section, contradicts its own summary sentence:

> "Your primary category and optional secondary category are indexed by our
> search algorithm."

OpenNutriTracker's App Store record carries `Health & Fitness` (primary) and
`Food & Drink` (secondary) — so the secondary category is already doing
indexing work, and per Apple's own keyword rule those words should not be
spent again in the keyword field. **Confidence: high** (both quotes are
Apple's; the second is the more specific and more recent-sounding).

**Field limits.** From App Store Connect Help, [App
information](https://developer.apple.com/help/app-store-connect/reference/app-information/):

> Name — "The name must be at least two characters and no more than 30
> characters."
> Subtitle — "This can't be longer than 30 characters."

App Review Guidelines §2.3.7 independently confirms: "App names must be
limited to 30 characters."

From [Platform version
information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information):

> Promotional Text — "This property can't be longer than 170 characters."
> Description — "Limited to 4000 characters."
> Keywords — "One or more keywords (each greater than two characters)
> describing your app. **You can provide up to 100 bytes of content.**"

**Promotional text is explicitly excluded from ranking.** Apple says so twice,
in identical words on both marketing pages:

> "keep in mind that promotional text doesn't affect your app's search
> ranking so it should not be used to display keywords."

This is the *only* field Apple explicitly rules out. It matters here: the
170-char promotional text is the one Apple field editable without a new
binary submission, which makes it tempting as a keyword slot. It isn't one.
**Confidence: high.**

**The keyword field's stated rules.** From
[App Store search](https://developer.apple.com/app-store/search/):

> "Keywords are limited to 100 characters total, with terms separated by
> commas and no spaces. You can use spaces to separate words within keyword
> phrases. For example: Property,House,Real Estate. Don't repeat any words
> any words included in your app name, subtitle, or category." *(the doubled
> "any words" is Apple's own typo, quoted verbatim)*

Then, to maximise coverage, avoid:

> - "Plurals of words you've already included, such as 'climbs' and 'climb,'
>   as these are considered duplicates."
> - "Generic terms that are too broad for your app or category, such as 'app'
>   or 'game.'"
> - "Filler words like 'the' and 'to,' as these don't add any additional
>   value."
> - "Special characters, such as (such as # or @), unless they're part of
>   your brand identity."

And, as grounds for rejection:

> "Improper use of keywords is a common reason for App Store rejections.
> Don't include: Unauthorized use of trademarked terms, celebrity names, or
> other protected words and phrases. Terms that are not relevant to the app.
> **Competing app names.** Inappropriate, offensive, or objectionable terms."

The Platform version information page adds: "**Names of other apps or
companies aren't allowed.**"

---

### Apple: what is *not* documented

These are the flags. Each is a claim repeated as fact across the ASO industry
that Apple's own sources do not actually make.

**1. "The description is not indexed" — not stated anywhere by Apple.**

This is the single most-repeated claim in iOS ASO, and Apple never says it.
What Apple actually does is three things, none of which is that sentence:

- It enumerates text-relevance factors and the description is absent from the
  list. Absence from an enumeration prefixed with "including" is weak.
- It discourages the practice, on the [product
  page](https://developer.apple.com/app-store/product-page/) guidance:
  "Don't add unnecessary keywords to your description in an attempt to
  improve search results."
- It redirects the description to a *different* search system entirely. From
  Platform version information: the description "appears on your app's
  product page, when users install your app, and **will be used for web
  engine search results** once you release your app."

That last quote is the strongest primary evidence available and it is better
than the folk claim, because it is positive rather than negative: Apple
assigns the description a documented job, and that job is web search (Google
indexing `apps.apple.com`), not App Store search.

**Practical consequence, and it is not "ignore the description":** the App
Store description is the field that determines whether the app is findable
*from the open web*. For a project whose audience discovers it through
GitHub, Reddit, Mastodon and F-Droid write-ups, that is arguably the more
valuable channel, and it is the one channel where a 4000-character
description does real work on iOS.

**Confidence: high** that the description is not among Apple's stated
in-store text-relevance factors. **Confidence: low** in the flat assertion
"Apple does not index the description at all" — Apple has never said it, and
nobody outside Apple can test it.

**2. Apple's keyword field: 100 characters or 100 bytes?**

Two Apple primary sources disagree, in the same week:

- [App Store search](https://developer.apple.com/app-store/search/) and
  [App Store product page](https://developer.apple.com/app-store/product-page/):
  "Keywords are limited to **100 characters** total."
- App Store Connect Help, Platform version information: "You can provide up
  to **100 bytes** of content."

For en-US ASCII copy the two are identical, so this map is unaffected — but
it would bite hard on the nine app locales if localisation ever comes back
into scope, where a German umlaut or a Chinese character costs 2–3 bytes and
one character. Worth carrying forward into any future localisation effort,
not worth resolving now. **Confidence: high** that the contradiction exists;
**unresolved** as to which governs.

**3. Apple does not document a repetition *penalty*.**

The rule is "don't repeat any words included in your app name, subtitle, or
category", and Apple's stated reason is efficiency — the bullets that follow
are all framed as ways to "maximize the number of words that fit in this
character limit". Repetition is documented as *wasted characters*, not as a
ranking demerit. The only documented downside with teeth is §2.3.7's ban on
packing metadata "with trademarked terms, popular app names, pricing
information, or other irrelevant phrases just to game the system", plus
"Apple may modify inappropriate keywords at any time" — which is a rejection
and moderation risk, not a ranking penalty.

So: **"Apple penalises keyword repetition" is vendor lore.** "Apple gains you
nothing for keyword repetition, and repetition in the keyword field wastes a
scarce 100 characters" is documented. The practical advice is the same; the
reasoning is not, and the difference matters when deciding whether a
deliberate repeat (e.g. "calorie" in both name and subtitle, for human
readability) is a risk. It is not. **Confidence: high.**

**4. Keyword *combination* across fields is undocumented.**

Vendor consensus — App Radar, AppFollow and others, cited here as
corroboration only — holds that Apple builds a phrase index by combining
tokens across name, subtitle and keyword field, so that an app with "Fitness"
in the name and `tracker,women` in keywords can surface for "fitness tracker
for women" though that phrase appears nowhere. Apple's own pages say nothing
about combination, only that keywords should be "separated by commas and no
spaces" with spaces permitted "to separate words within keyword phrases".

The vendor claim is plausible and universally held, and this document does
not dispute it — but it is **not documented**, and a copy decision should not
rest on it alone. **Confidence: low (vendor lore).**

**5. The developer name is an indexed field — and it is frozen.**

Apple documents indexing plainly, in the keyword-field description: "Your app
is searchable by app name **and company name**, so you shouldn't duplicate
these values in the keyword list."

But [Set your developer
name](https://developer.apple.com/help/app-store-connect/create-an-app-record/set-your-developer-name):

> "You can set your developer name only when adding an app to your account
> for the first time. You can't edit or update this name later, so it's
> important to enter it correctly."

The live App Store record shows `sellerName: Simon Oppowa`. So on Apple the
developer name is an indexed slot that carries zero category relevance and
**cannot be changed** — one indexed field is permanently spent on a personal
name. There is no action here; there is only the fact that this lever does
not exist on iOS. **Confidence: high.**

---

### Google Play: what is documented

**The search inputs are named in exactly one sentence,** on [App visibility
and discovery
issues](https://support.google.com/googleplay/android-developer/answer/9042516):

> "Similar to a search on Google, Google Play search takes multiple factors
> into account, such as **app titles, developer names, and app
> descriptions**."

And, more abstractly, on [App Discovery and
Ranking](https://support.google.com/googleplay/android-developer/answer/9958766):

> "Once we establish intent, metadata (for example, title, description,
> category) and other signals are used to determine which apps best address
> the user's query."

Note what those two sentences do *not* contain: any mention of the short
description as a distinct field. More on that below.

**Field limits.** From [Best practices for your store
listing](https://support.google.com/googleplay/android-developer/answer/13393723):

> "A full description allows for 4,000 characters. A short description should
> convey your app or game's message in 80 characters or less."
> "Your app title must be 30 characters or less."

The [Metadata policy](https://support.google.com/googleplay/android-developer/answer/9898842)
independently confirms the title limit: "Your app title must be 30 characters
or less." **Confidence: high.**

**Repetition is a policy violation on Play, with an enforcement consequence.**
This is the sharpest divergence from Apple. The Metadata policy:

> "We don't allow apps with misleading, improperly formatted,
> non-descriptive, irrelevant, excessive, or inappropriate metadata…"
> "Avoid using repetitive or unrelated keywords or references."
> "**Excessive length, detail, improper formatting, or repetition can result
> in a violation of this policy.**"
> "Don't use special characters or all caps to manipulate search ranking."

The best-practices page gives the worked example:

> "Avoid excessive length, detail, improper formatting, and repetition of
> words. For example, don't use this kind of repetition and detail in your
> description: 'Car racing, car driving, race cars, car races, race track,
> driving, drive, race, cars, vehicles, automobiles, trucks'"

And, specifically across the two description fields:

> "**Don't repeat your short description in your full description.**"

**Confidence: high.** Play documents a repetition rule that Apple does not,
and Play's is backed by takedown risk rather than by ranking loss.

**The developer name is both indexed and policy-governed.** The Metadata
policy scopes itself to "the app's description, **developer name**, title,
icon, screenshots, and promotional images", and the best-practices page adds
that "Your app title, icon, and developer name are particularly helpful for
users to find and learn about your app."

Unlike Apple's, Play's developer name is editable. The live Play listing shows
the developer as **`simonO`** — a five-character handle in an indexed field.
Apple's equivalent is `Simon Oppowa`. The two stores do not agree on the
developer's own name, and on Play that field is both changeable and indexed.
Whether to use it is a copy decision for the drafting ticket, and it is
constrained: see the "No Ads" rule below. **Confidence: high** on the facts;
this document takes no position on the decision.

---

### Google Play: what is *not* documented

**6. Nothing states that the short description is indexed.**

"Play indexes title + short description + full description" is repeated by
every ASO vendor and is the premise the map is built on. Google's primary
sources name **title, developer name, description, category**. They never
name the short description as a search input. What they say about it is:

- [Best practices](https://support.google.com/googleplay/android-developer/answer/13393723),
  under the heading *Promotional description*: "This short text is key for
  attracting users. It **appears in places like search results** and helps
  users quickly understand your app's value."

That is a statement about *where it is displayed*, not about whether it is
*matched against a query*. Those are different claims and the ASO industry
routinely conflates them.

Two mitigating points, both real:

- Google's phrase is "app descriptions", plural and unqualified. It is at
  least as natural to read that as covering both description fields as to
  read it as covering only the long one.
- The `Get discovered` page says of the (long) Description: "using a
  professional translation service for your 'Description' can lead to
  **better search results and discoverability**" — the closest Google comes
  to confirming that description text feeds retrieval at all, and it is about
  the long field.

**Verdict:** the full description being indexed is documented well enough to
act on (**confidence: high**). The short description being *separately
indexed* is **vendor lore with a plausible reading of Google's wording behind
it** (**confidence: medium**). Practically this changes nothing — the 80-char
slot is the highest-visibility text on the listing and must be written for
humans regardless — but it should stop anyone treating those 80 characters as
a keyword slot at the cost of readability, on the strength of a claim Google
never made.

**7. Google's own docs disagree on what the 80-character field is called.**

The console calls it **Short description**. [Get
discovered](https://support.google.com/googleplay/android-developer/answer/4448378)
calls it **Promo Text** and gives it one line of guidance. [Best
practices](https://support.google.com/googleplay/android-developer/answer/13393723)
calls it **Promotional description** in a heading and **short description**
three paragraphs earlier — in the same article. This is a live signal about
how much weight any single Play help page can bear, and a reason to prefer
the Metadata policy and the best-practices article (both maintained) over
`Get discovered` (visibly stale). **Confidence: high** that the inconsistency
exists.

**8. No repetition *count* is documented, and the vendor consensus is
self-contradictory.**

Vendor guidance (corroboration only) variously advises "roughly one exact
match per 250 characters", "repeat your main term a handful of times", and
"Google's algorithm favours relevance and clarity over repetition". These
cannot all be true. Google documents only the negative: repetition "can
result in a violation". There is no documented optimal density and this
document declines to invent one. **Confidence: low (vendor lore, internally
inconsistent).**

---

### Where the two stores genuinely diverge

Five differences that change what the same words are worth:

1. **Apple has a hidden 100-character slot; Play has none.** Every keyword
   Play sees must survive being read by a human. Every Apple keyword can be
   invisible. This is the single biggest structural difference and it means
   the two listings should *not* be the same copy.
2. **Apple's long description does nothing for in-store search; Play's is a
   primary input.** The repo's `full_description.txt` is a Play asset that
   happens to be reusable as an Apple asset, not one asset for two stores.
3. **Apple's 60 visible characters (name + subtitle) carry the whole visible
   keyword burden; Play's 110 (title + short description) carry less of it,**
   because Play has 4000 more indexed characters behind them.
4. **Repetition is a wasted opportunity on Apple and a policy risk on Play.**
5. **The developer name is indexed on both; editable on only one.**

---

## Part 2 — The keyword landscape

### What the evidence is, and what it is not

No volume figures. No difficulty scores. What follows is grounded in 24
result sets pulled on 2026-09-04 — 17 from Apple's public search endpoint,
7 from Play web search — plus the two live listing records. A result set
answers *"who ranks for this today"*, which is a weaker question than "how
many people search this", but it is a real answer rather than a guess.

Both endpoints carry the caveat in the source table: neither is documented to
reproduce on-device store ranking. Treat every ordering below as directional.
The one thing result sets establish robustly is **presence or absence**, and
absence from the top 10–18 for a query is a strong negative signal regardless
of how the ordering is computed.

### Where the app stands today — measured, not assumed

| Query | Apple result set | Play result set |
| :-- | :-- | :-- |
| `opennutritracker` | **#1** | (brand; not re-tested) |
| `open source calorie tracker` | absent from 15 | **#1** |
| `open source nutrition` | **#4** of 14 | not tested |
| `calorie counter` | absent from 17 | absent from 18 |
| `calorie tracker` | absent from 12 | — |
| `food diary` | absent from 13 | — |
| `macro tracker` | absent from 13 | — |
| `nutrition tracker` | absent from 14 | — |
| `offline food diary` | absent from 15 | absent from 28 |
| `offline calorie counter` | absent from 12 | — |
| `privacy calorie tracker` | absent from 15 | absent from 10 |
| `no account calorie tracker` | — | absent from 12 |
| `no ads calorie counter` | absent from 15 | — |
| `barcode calorie scanner` | — | absent from 12 |
| `open food facts` | absent from 12 | absent from 20 |

**The headline finding is the first two rows.** The same query —
`open source calorie tracker` — returns the app **first on Play** and **not
at all on Apple**. That is Part 1's structural difference showing up as an
observable outcome: the phrase "open-source" appears in the first sentence of
the full description on both stores, and only Play searches that text.

**Second finding: the app is absent for every generic term on both stores.**
It does not currently compete for `calorie counter`, `calorie tracker`,
`food diary`, `macro tracker` or `nutrition tracker` anywhere.

**Third: the differentiator terms other than "open source" do not currently
retrieve it either** — `privacy`, `no account`, `offline`, `barcode`,
`Open Food Facts` all return nothing, on both stores, despite `privacy`,
`barcode` and `Open Food Facts` all appearing in the live copy. Being in the
description is not sufficient to rank.

**Confidence: high** on presence/absence; **medium** on the ordering.

### The generic tier — high volume, and effectively closed

Apple result set for `calorie counter`, in order: MyNetDiary, MyFitnessPal,
Numify, Cal AI, Lose It!, Cronometer, Nutracheck, Foodvisor, Calo, fatsecret,
BitePal, Calory AI, Lifesum, Appediet, Yazio, EasyFit, Scanfood. Play's for
the same term is near-identical in its top six.

Three things are visible in that list and none of them are guesses:

1. **Every incumbent spends its 30-character name on the generic term.**
   "MyFitnessPal: Calorie Counter". "Cronometer: Calorie Counter". "Calorie
   Counter by Lose It!". "Calorie Counter - MyNetDiary". The market
   convention is `Brand` + separator + `Calorie Counter`, and it is close to
   universal. OpenNutriTracker's name is `OpenNutriTracker` — 16 of 30
   characters, with **no descriptive term at all**, on both stores. That is
   14 unused characters in the highest-weighted indexed field on either
   platform, and it is the clearest single gap this research found.
2. **The category is now saturated with AI.** Of the 17 Apple results for
   `calorie counter`, 8 carry "AI" in the name; Play's top 15 has 7. Yazio
   and Lifesum have both renamed themselves to lead with "AI Calorie
   Tracker". Competing on `AI calorie counter` would mean entering the single
   most contested phrase in the category from zero, with a feature that is
   experimental, off by default and bring-your-own-key — and would sit badly
   with the settled position that a model may never emit nutrition values.
   **This corroborates the map's decision to keep AI mid-list.** It also
   suggests the AI wave has left the *non*-AI positioning comparatively
   uncrowded, which is where this app's differentiators live.
3. **Apple's endpoint returns 12–17 results for these queries, not
   hundreds.** Ranking 18th is functionally identical to ranking 400th.
   Chasing `calorie counter` head-on is not a strategy for an app with 14
   iOS ratings.

**Recommendation for the drafting ticket, stated as a finding not a mandate:**
the generic terms belong in the listing — a listing that never says "calorie"
cannot rank for anything — but as the *supporting* half of a compound, not as
the term to win outright. **Confidence: high** on the observation;
**medium** on the strategic read, which is judgement.

### The differentiator tier — where this app can actually rank

Only one differentiator is currently earning anything, and the evidence for
it is unusually clean.

**`open source` and its compounds — the strongest position the app has.**

- Play ranks it **#1** for `open source calorie tracker`, ahead of
  MyFitnessPal, MyNetDiary, Lose It! and Cronometer. That is a first
  position, today, with no ASO work ever having been done.
- No competitor in any result set has "open source" in its name.
- Play reviews on the live listing name the property unprompted: *"I love it
  is open source and no account is needed"*; *"I was so happy to find an app
  focused on privacy and that its open source"*. Users are describing the app
  in exactly these words — which is the best available proxy for the words
  they would search.
- On Apple the term is *not* free: `open source` alone returns GitHub,
  Joplin, OsmAnd, Jellyfin — the token is owned by developer tooling. The
  winnable Apple target is the **compound** (`open source` + `calorie` /
  `nutrition` / `food diary`), not the bare phrase. The app already reaches
  #4 for `open source nutrition` on Apple but nothing for
  `open source calorie tracker`, which points at the keyword field as the
  place that gap gets closed.

**Confidence: high.** This is the one term where a measured #1 exists.

**`no account`, `offline`, `privacy`, `no ads` — real product truths, no
current retrieval, and each has a store-specific catch.**

These are the differentiators the ticket asked about, and the honest answer is
that none of them currently retrieves the app on either store, even though
the words are in the live copy. Each is worth pursuing, and each has a
constraint that must be checked before it is drafted:

- **`no ads` is banned from the Play title and developer name, by name.**
  Best practices, verbatim: "Don't use text elements to promote deals. Words
  like **'Free' and 'No Ads'** promote deals and don't belong in app titles
  or developer names." It is *not* prohibited in the description. On Apple
  there is no such rule and the market reflects it — the Apple result set for
  `no ads calorie counter` contains an app literally named "Calorie Counter -
  No Ads". **A genuine cross-store asymmetry: the same three characters are
  permitted in an Apple name and forbidden in a Play title.**
  **Confidence: high.**
- **`free` carries the same warning on Play's 80-character field.** Best
  practices, on the promotional/short description: "No pricing or ranking:
  Don't include promotional offers (like **'free'** or 'discount')…". The
  current `short_description.txt` opens *"A free and open source calorie
  tracker…"*. Google's policy examples are all limited-time-offer framed
  ("free for a limited time only"), so a permanent statement of price is very
  unlikely to be enforced against — but the guidance names the word, and the
  drafting ticket should decide this consciously rather than inherit it.
  **Confidence: medium** — the guidance is unambiguous, its applicability to
  a permanently-free app is not.
- **`Open Food Facts` should not go in Apple's keyword field.** Apple:
  "Names of other apps or companies aren't allowed", and "Don't include:
  … Competing app names." Open Food Facts is a real organisation with a
  ranking App Store app (`Open Food Facts - Product Scan`, #1 for its own
  name). Naming it in the *description* is fine and accurate; naming it in
  the 100-character keyword field is against Apple's stated rule.
  **Confidence: high.**
- **`privacy`, `no account`, `offline` are unconstrained on both stores** and
  currently return nothing for this app. They are the cleanest available
  targets for Apple's keyword field specifically, since they are exactly the
  kind of term that costs visible characters on Play but costs nothing
  visible on Apple.

**A name-collision hazard, found incidentally:** Apple's result set for
`opennutritracker` returns `OpenNutrition Macro Tracker` (Snackbar Apps, LLC)
at #14. A competitor whose name is one character from the brand, in the same
category, on the same store. Not actionable in this ticket, but the drafting
and measurement tickets should both know it exists. **Confidence: high** on
the observation; no assessment of trademark implications is offered here.

### Terms the product cannot honestly claim

Worth stating explicitly, because ASO pressure runs the other way. The live
Play `full_description.txt` does not mention **Health Connect import** or
**AI meal assistance** at all, and the live App Store description is far older
still — it predates micronutrients, recipes, trends, water, fasting, weight
history and export. Adding terms for features that exist is legitimate;
Apple's §2.3.7 "Terms that are not relevant to the app" and Play's
"non-descriptive, irrelevant" both bite the other way. No keyword in this
document should reach a listing for a feature the shipped build lacks.

---

## Two things this research found that the map should absorb

**1. The live listings are further behind than "the paste is unticked"
suggests.** The map records that CI never pushes metadata and the
`RELEASING.md` checklist item is unticked. Confirmed, and worse on iOS: the
App Store record returns `version: v2.0.2`, released **2026-08-05**, with a
description that predates most of the feature set. The Play listing's live
full description is likewise the old pre-2.2.0 copy — the 3952-character
rewrite from [#1049](https://github.com/simonoppowa/OpenNutriTracker/issues/1049)
exists only in the repo — and its What's New still reads "Version 2.0 is the
biggest update yet". Establishing exactly where 2.2.0 sits in each console
remains
[#1063](https://github.com/simonoppowa/OpenNutriTracker/issues/1063)'s job;
this is a partial early read, not that ticket's answer.

**2. Play's policy actively discourages the length the repo's full
description is optimised toward.** The map frames
`full_description.txt` at 3952 of 4000 characters as the freshest and
strongest asset. It is fresh. But Play's Metadata policy says "Keep your
app's description succinct and straightforward. Shorter descriptions tend to
result in a better user experience… **Excessive length**, detail, improper
formatting, or repetition can result in a violation of this policy", and the
`Get discovered` page adds "Avoid using excessive emoji or ascii characters
in your description. Users of programs like screen readers or voice control
software will encounter issues when excessive emoji or ascii text is used."
The current draft is 16 emoji-led bullets running to 99% of the ceiling.

This is a **tension, not a violation** — the policy targets keyword-stuffed
word salad, and the current draft is well-written prose about real features.
But "we filled 3952 of 4000 characters" is not self-evidently a good thing on
Play, and the drafting ticket should not treat the ceiling as a target.
**Confidence: medium** — the policy language is clear, its enforcement
threshold is not, and no enforcement action against this listing is known.

---

## Open questions this ticket could not close

- **What is currently in Apple's 100-character keyword field, and in the
  subtitle?** Both are console-only and unversioned; neither the iTunes
  Lookup API nor the web product page exposes them. Nobody can draft against
  the Apple keyword field without first reading what is in it. This is a
  console-read task, and it pairs naturally with the baseline ticket.
- **Actual search volume for any term here.** Blocked on
  [#1064](https://github.com/simonoppowa/OpenNutriTracker/issues/1064)'s
  App Store Connect search-term report. Nothing in this document should be
  read as a volume estimate.
- **Whether Apple combines tokens across name, subtitle and keyword field.**
  Undocumented (flag 4). If it does, the three fields can be written as a
  set; if it does not, each must stand alone. Not resolvable from outside
  Apple, and not resolvable by experiment at this app's traffic.
- **Whether Play indexes the short description separately** (flag 6). Same
  shape of problem, same lack of a decisive source.

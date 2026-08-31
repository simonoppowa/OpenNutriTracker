# Does the app's TDEE match the IOM 2005 equation it cites

Research notes gathered 2026-08-31 against the issuing bodies' own text only.
The IOM 2005 equations were read off the scanned page images the National
Academies Press serves for record 10490 (`https://nap.nationalacademies.org/books/10490/gif/<page>.gif`),
which are photographs of the printed pages, so every equation below is quoted
from the book itself with its printed page number. The FAO/WHO/UNU 2001 report
was read from FAO's own HTML edition of *Human energy requirements*. The Brooks
et al. 2004 abstract was retrieved from NCBI's E-utilities. Nothing here rests
on a calculator site, a blog, a wiki or any other secondary write-up; where a
page could not be read first-hand it is in [Not verified](#not-verified).

Written to answer [#987](https://github.com/simonoppowa/OpenNutriTracker/issues/987):
**the app's TDEE calculation does not match its cited source.** The code under
examination is [`lib/core/utils/calc/tdee_calc.dart`](../lib/core/utils/calc/tdee_calc.dart),
[`lib/core/utils/calc/pal_calc.dart`](../lib/core/utils/calc/pal_calc.dart),
[`lib/core/utils/calc/bmr_calc.dart`](../lib/core/utils/calc/bmr_calc.dart) and
[`lib/core/utils/calc/calorie_goal_calc.dart`](../lib/core/utils/calc/calorie_goal_calc.dart).

## Bottom line up front

1. **The issue is correct, and it is a real bug.** IOM 2005 p. 204 groups the
   weight *and* height terms inside the PA multiplier. The app multiplies PA
   into the weight term only, leaving the height term unscaled. Every user
   above the sedentary PAL category gets a TDEE that is too low, by
   `(PA − 1) × 503 × height[m]` for the male reference and
   `(PA − 1) × 660.7 × height[m]` for the female one — **109 to 489 kcal/day**
   over realistic adult inputs, growing with height and with activity level.
   Sedentary users are unaffected, because PA = 1.00 there.
2. **The intercepts and coefficients are from the right equation set, and the
   PA table matches that same set.** `864 / 9.72 / 14.2 / 503` and
   `387 / 7.31 / 10.9 / 660.7` are the *normal-weight, overweight, and obese
   adults ages 19 years and older* TEE equations on p. 204, and the app's PA
   values (male `1.00 / 1.12 / 1.27 / 1.54`, female `1.00 / 1.14 / 1.27 / 1.45`)
   are exactly the ones printed under those two equations. **There is no second
   bug here** — the feared PA-table mismatch does not exist. This matters,
   because the neighbouring sets on pp. 185 and 202–203 carry *different* PA
   values, and picking the wrong table would have been easy.
3. **The wrong grouping is also shown to the user.** The transparency screen in
   [`lib/features/settings/presentation/widgets/kcal_goal_info_screen.dart`](../lib/features/settings/presentation/widgets/kcal_goal_info_screen.dart)
   renders the formula as a string with the same missing parentheses, so fixing
   only `tdee_calc.dart` would leave the app displaying an equation that does
   not match the source *or* its own output.
4. **The WHO/Schofield branch's BMR coefficients are exactly right; its PAL
   values are not the ones that report publishes.** All twelve Schofield 1985
   kcal/day coefficients in `bmr_calc.dart` reproduce FAO/WHO/UNU 2001
   Table 5.2 digit for digit. But that report classifies lifestyles into
   **three** PAL bands (1.40–1.69, 1.70–1.99, 2.00–2.40) and states the
   sustainable range starts at 1.40; the app's four values include **1.25 for
   sedentary, below the report's own floor.** This branch is currently dead
   code — nothing calls `getTDEEKcalWHO2001`.
5. **`pal_calc.dart` cites the wrong paper for its PAL mapping.** Brooks et al.
   2004 is the chronicle of how the *60 minutes a day* activity recommendation
   came to be. It does not publish an activity-category → PAL-value table. The
   actual source for the four categories and their ranges is IOM 2005 itself,
   on the same pages as the equations.
6. **Age applicability is handled better than the issue implies, but not
   completely.** The equations are labelled "Ages 19 Years and Older"; the app
   accepts ages 13+ and shows an adult-equations notice below 18
   ([`lib/core/utils/bounds/ranges_const.dart`](../lib/core/utils/bounds/ranges_const.dart),
   [`lib/core/utils/bounds/validator.dart`](../lib/core/utils/bounds/validator.dart)).
   So 13–17 is disclosed rather than silently wrong. 18-year-olds get the adult
   equations with no notice at all, and the book's 9-through-18 equations
   (p. 182) have a different shape entirely.

## A. What page 204 actually says

The page cited by the code comment and by the project wiki. Quoted verbatim
from the printed page (Institute of Medicine, *Dietary Reference Intakes for
Energy, Carbohydrate, Fiber, Fat, Fatty Acids, Cholesterol, Protein, and Amino
Acids*, The National Academies Press, 2005, [doi:10.17226/10490](https://doi.org/10.17226/10490),
p. 204):

> **Normal-weight, Overweight, and Obese Men Ages 19 Years and Older**
> **TEE = 864 – (9.72 × age [y]) + PA × (14.2 × weight [kg] + 503 × height [m])**
>
> Where PA is the physical activity coefficient:
> PA = 1.00 if PAL is estimated to be ≥ 1.0 < 1.4 (sedentary)
> PA = 1.12 if PAL is estimated to be ≥ 1.4 < 1.6 (low active)
> PA = 1.27 if PAL is estimated to be ≥ 1.6 < 1.9 (active)
> PA = 1.54 if PAL is estimated to be ≥ 1.9 < 2.5 (very active)
>
> **Normal-weight, Overweight, and Obese Women Ages 19 Years and Older**
> **TEE = 387 – (7.31 × age [y]) + PA × (10.9 × weight [kg] + 660.7 × height [m])**
>
> Where PA is the physical activity coefficient:
> PA = 1.00 if PAL is estimated to be ≥ 1.0 < 1.4 (sedentary)
> PA = 1.14 if PAL is estimated to be ≥ 1.4 < 1.6 (low active)
> PA = 1.27 if PAL is estimated to be ≥ 1.6 < 1.9 (active)
> PA = 1.45 if PAL is estimated to be ≥ 1.9 < 2.5 (very active)

The parenthesis is unambiguous on the page: `PA ×` is followed by an opening
bracket, the weight term, a line break, the height term, and a closing bracket.
The same grouping appears on every one of the six adult equations and both
child equations in the chapter (pp. 182, 185, 202, 203, 204), which is a strong
internal check that it is not a typesetting artefact of one page.

What the app computes, from [`lib/core/utils/calc/tdee_calc.dart`](../lib/core/utils/calc/tdee_calc.dart):

```dart
return 864 -
    9.72 * userEntity.age +
    paValue * 14.2 * userEntity.weightKG +
    503 * (userEntity.heightCM / 100);
```

`503 × height` sits outside the PA product. Same shape in
`iom2005FemaleReferenceKcal` for the `660.7 × height` term. **The issue's claim
is confirmed.**

### How much it costs

The difference is exactly `(PA − 1) × height_coefficient × height[m]`. It does
not depend on weight or age at all.

| Reference | Inputs | PA | App today | Source | Shortfall |
| --- | --- | --- | --- | --- | --- |
| Male | 30 y, 80 kg, 180 cm | 1.00 sedentary | 2614 | 2614 | **0** |
| Male | 30 y, 80 kg, 180 cm | 1.12 low active | 2750 | 2859 | **109** |
| Male | 30 y, 80 kg, 180 cm | 1.27 active | 2921 | 3165 | **244** |
| Male | 30 y, 80 kg, 180 cm | 1.54 very active | 3227 | 3716 | **489** |
| Female | 30 y, 65 kg, 165 cm | 1.00 sedentary | 1966 | 1966 | **0** |
| Female | 30 y, 65 kg, 165 cm | 1.14 low active | 2066 | 2218 | **153** |
| Female | 30 y, 65 kg, 165 cm | 1.27 active | 2158 | 2452 | **294** |
| Female | 30 y, 65 kg, 165 cm | 1.45 very active | 2285 | 2776 | **491** |

A 190 cm very-active man is short by 516 kcal/day; a 155 cm very-active woman
by 461. For context, [`CalorieGoalCalc.loseWeightKcalAdjustment`](../lib/core/utils/calc/calorie_goal_calc.dart)
is −500 kcal — so at the top of the activity range the bug is roughly a second,
undeclared weight-loss deficit stacked on top of whatever goal the user chose.
Because `getTdee` feeds `getTotalKcalGoal` directly, the error propagates
straight into the daily goal, the remaining-kcal figure and the macro split.

## B. Which equation set the constants come from, and whether the PA table agrees

IOM 2005 publishes **three** distinct adult sets, each with its own intercept,
its own coefficients **and its own PA values**. All three were read off the
page images:

| Set | Page | Men | Women |
| --- | --- | --- | --- |
| EER, normal-weight adults 19+ (BMI 18.5–25) | 185 | `EER = 662 – (9.53 × age) + PA × (15.91 × weight + 539.6 × height)` | `EER = 354 – (6.91 × age) + PA × (9.36 × weight + 726 × height)` |
| TEE, overweight and obese adults 19+ (BMI ≥ 25) | 202–203 | `TEE = 1086 – (10.1 × age) + PA × (13.7 × weight + 416 × height)` | `TEE = 448 – (7.95 × age) + PA × (11.4 × weight + 619 × height)` |
| **TEE, normal-weight, overweight and obese adults 19+ (BMI ≥ 18.5)** | **204** | `TEE = 864 – (9.72 × age) + PA × (14.2 × weight + 503 × height)` | `TEE = 387 – (7.31 × age) + PA × (10.9 × weight + 660.7 × height)` |

And their PA tables, which are *not* interchangeable:

| Set | Men: sed / low / act / very | Women: sed / low / act / very |
| --- | --- | --- |
| Normal-weight EER (p. 185) | 1.00 / **1.11** / **1.25** / **1.48** | 1.00 / **1.12** / 1.27 / 1.45 |
| Overweight & obese TEE (pp. 202–203) | 1.00 / 1.12 / **1.29** / **1.59** | 1.00 / **1.16** / 1.27 / **1.44** |
| **Combined TEE (p. 204)** | **1.00 / 1.12 / 1.27 / 1.54** | **1.00 / 1.14 / 1.27 / 1.45** |

`PalCalc.getPAValueForFormula` returns `1.0 / 1.12 / 1.27 / 1.54` for the male
formula and `1.0 / 1.14 / 1.27 / 1.45` for the female one. **That is the p. 204
row, matching the p. 204 intercepts.** The coefficients and the PA table are
internally consistent; the only defect in the IOM branch is the parenthesis.

Note also that the bucket boundaries in `getPAValueForFormula`
(`< 1.4`, `< 1.6`, `< 1.9`, else) reproduce the book's `≥ 1.0 < 1.4`,
`≥ 1.4 < 1.6`, `≥ 1.6 < 1.9`, `≥ 1.9 < 2.5` bands exactly, and the PAL point
values `getPALValueFromActivityCategory` emits (1.25, 1.5, 1.75, 2.2) each fall
inside the intended band, so the PAL→PA round trip is lossless for the IOM
branch.

### Choosing the p. 204 set was defensible

The book explains why the combined set exists, and the reasoning applies
directly to a general-audience tracker (p. 202):

> Since Dietary Reference Intakes are designed to apply to apparently health
> individuals, the EERs are defined as values appropriate for maintenance of
> long-term good health. Overweight and obese individuals have greater weight
> than is consistent with long-term good health, thus EER values given in
> previous sections are not intended for overweight or obese individuals or for
> those who desire to lose weight. Instead, weight maintenance TEE values are
> discussed […]

and (p. 203):

> […] the combined data from normal-weight and overweight and obese individuals
> were used to develop equations to predict TEE in overweight and obese adults.
> The resulting equations, described in the following sections, are accurate for
> use in both normal-weight and overweight and obese adults, and are thus
> suitable for prediction of energy requirements both in overweight and obese
> groups and in mixed groups containing normal-weight and overweight adults.

An app that does not know the user's BMI category in advance, and whose users
frequently *do* want to lose weight, is precisely the "mixed group" case. The
p. 204 choice is better than the p. 185 EER set the wiki's "EER" framing
implies. What the app returns is a **TEE**, not an EER; the code and comments
call it TDEE, which is the same quantity under a different name, so no harm —
but the doc comment's "IOM equation (p.204)" should say *TEE for normal-weight,
overweight and obese adults ages 19 and older* if it is going to name a page.

## C. Units, population and stated accuracy

- **Units.** The book writes `age [y]`, `weight [kg]`, `height [m]`. The app
  passes years, kilograms, and `heightCM / 100`. **Correct.**
- **Age.** Both p. 204 headings say "Ages 19 Years and Older". The app's floor
  is 13 (`Ranges.minAgeYears`) with a disclosure below 18
  (`Ranges.adultAgeYears`, `Validator.isUnderAdultAge`), so 13–17 is a
  documented approximation rather than a hidden one. **18-year-olds fall in a
  gap**: the app treats them as adults with no notice, while the book gives
  them the 9-through-18 equations (p. 182), which have different coefficients,
  different PA values (boys 1.00 / 1.13 / 1.26 / 1.42; girls 1.00 / 1.16 /
  1.31 / 1.56) *and* a `+ 25 kcal` energy-deposition term for growth that the
  adult equations do not have.
- **Population.** Fitted on the doubly labeled water database. Data were
  excluded where PAL was outside 1.0–2.5 (pp. 184, 202): *"Data were not used in
  the derivation of the TEE equations if the PAL value was less than 1.0 or
  greater than 2.5."* The app never produces a PAL outside 1.25–2.2, so it stays
  inside that window.
- **Accuracy, in the book's own words.** For the combined equations (p. 203):
  *"For the combined data sets, the standard deviations of the residuals ranged
  from 182 to 321."* For the overweight/obese equations (p. 202): *"the standard
  deviations of the residuals ranged from 190 to 331, with the highest value in
  the very active PAL category."* The underlying BEE fits are weaker still —
  p. 205 gives R² = 0.46 for normal-weight men and R² = 0.39 for normal-weight
  women. **The app surfaces no uncertainty at all**; it presents a single kcal
  figure to the unit. A ±200–300 kcal one-sigma band is larger than the entire
  −500 kcal weight-loss adjustment is meant to be precise to, and larger than
  the bug found here at low activity levels. Worth stating somewhere in the
  transparency screen.

## D. The FAO/WHO/UNU 2001 branch

`TDEECalc.getTDEEKcalWHO2001` = `BMRCalc.getBMRSchofield11985` × PAL. Checked
against FAO/WHO/UNU, *Human energy requirements: Report of a Joint FAO/WHO/UNU
Expert Consultation, Rome, 17–24 October 2001* (FAO Food and Nutrition
Technical Report Series 1, Rome, 2004, ISBN 92-5-105212-3), chapter 5,
[section 5.2](https://www.fao.org/4/y5686e/y5686e07.htm).

**BMR: exact match.** Table 5.2 ("Equations for estimating BMR from body
weight", source: Schofield, 1985), kcal/day column:

| Age (y) | Males | App | Females | App |
| --- | --- | --- | --- | --- |
| < 3 | 59.512 kg − 30.4 | ✔ | 58.317 kg − 31.1 | ✔ |
| 3–10 | 22.706 kg + 504.3 | ✔ | 20.315 kg + 485.9 | ✔ |
| 10–18 | 17.686 kg + 658.2 | ✔ | 13.384 kg + 692.6 | ✔ |
| 18–30 | 15.057 kg + 692.2 | ✔ | 14.818 kg + 486.6 | ✔ |
| 30–60 | 11.472 kg + 873.1 | ✔ | 8.126 kg + 845.6 | ✔ |
| ≥ 60 | 11.711 kg + 587.7 | ✔ | 9.082 kg + 658.5 | ✔ |

All twelve coefficients and all six band boundaries are right, including the
`age < 18` / `age < 30` split that puts an 18-year-old in the 18–30 band. The
report also notes the consultation *chose* to keep the 1985 equations after
considering newer ones: *"this consultation concluded that these were not robust
enough to justify their adoption at present. For the time being, it was decided
to retain the equations proposed in 1985 by Schofield (Table 5.2)"*, and flags
the known sampling weakness — a large share of the Schofield database is
1930s–40s data on Italian men with relatively high BMR.

**PAL: does not match what the report publishes.** Table 5.3, "Classification of
lifestyles in relation to the intensity of habitual physical activity, or PAL":

| Category | PAL value |
| --- | --- |
| Sedentary or light activity lifestyle | 1.40–1.69 |
| Active or moderately active lifestyle | 1.70–1.99 |
| Vigorous or vigorously active lifestyle | 2.00–2.40 \* |

\* *"PAL values > 2.40 are difficult to maintain over a long period of time."*

Three categories, not four, and the report is explicit about the floor: *"The
PAL values that can be sustained for a long period of time by free-living adult
populations range from about 1.40 to 2.40"*, and later *"a PAL of 1.40, which
represents the lower limit of the sedentary lifestyle range shown in Table 5.3"*.
Against that:

- `sedentary → 1.25` is **below the published range entirely**. The report
  discusses 1.21 only as a survival figure for *"totally inactive dependent
  people in conditions of crisis"*, and says even that *"is too low and should
  not be used"*.
- `lowActive → 1.5` and `sedentary → 1.25` both land in (or below) the single
  FAO sedentary/light band, so the app's two lowest categories are not
  distinguishable in that report's scheme.
- `active → 1.75` sits correctly in 1.70–1.99, and the report uses 1.75 as its
  own worked example (*"a male with a PAL of 1.75"*), and again as the level
  reached by adding an hour of moderate-to-vigorous exercise to a 1.55 baseline.
- `veryActive → 2.2` sits correctly in 2.00–2.40.

Because the WHO branch multiplies the PAL value straight into BMR, a sedentary
adult would come out at 1.25 × BMR — around 11 percent below what the FAO
scheme's own floor would give. **This is latent, not live: `getTDEEKcalWHO2001`
has no callers anywhere in `lib/`.** It is either dead code to delete or a
second estimator to fix before it is ever wired up.

## E. Brooks et al. 2004 does not support the PAL mapping cited to it

[`lib/core/utils/calc/pal_calc.dart`](../lib/core/utils/calc/pal_calc.dart)
attributes `getPALValueFromActivityCategory` to Brooks et al. via
`https://pubmed.ncbi.nlm.nih.gov/15113740/`. The record (Am J Clin Nutr. 2004
May;79(5):921S-930S, doi 10.1093/ajcn/79.5.921S) is *"Chronicle of the Institute
of Medicine physical activity recommendation: how a physical activity
recommendation came to be among dietary recommendations"*. Its abstract is about
how the panel arrived at a **60 minutes per day** activity recommendation:

> TEE was based on the results of doubly labeled water studies, and the TEE
> results were presented in units of physical activity level (PAL = TEE/BEE) and
> DeltaPAL […] Most adults (66%) maintaining a BMI in the healthful range had PAL
> values >1.6, or the equivalent of ≥60 min of physical activity of moderate
> intensity each day. Hence, on the basis of the doubly labeled water data and
> the results of epidemiologic studies, the physical activity recommendation for
> adults was judged to be 60 min/d.

It defines PAL and reports a threshold; it does not publish
sedentary/low-active/active/very-active → 1.25/1.5/1.75/2.2. The four categories
and their `≥1.0<1.4 / ≥1.4<1.6 / ≥1.6<1.9 / ≥1.9<2.5` ranges come from IOM 2005
itself (pp. 185, 204). The specific *point* values the app picks inside those
ranges are the app's own choice — see [Not verified](#not-verified). The
citation should point at the DRI book, and the point values should be labelled
as representative midpoints chosen by the project rather than attributed to
anyone.

## F. Other things the sources say that the app omits

- **The 2005 edition has been superseded.** NASEM, *Dietary Reference Intakes
  for Energy* (2023) states: *"The need to reexamine the DRIs for energy, last
  updated in 2005, stemmed from two key factors"*, redefines the DRI population
  as *"the general population, including those with overweight, obesity, and
  chronic diseases, rather than the previous 'generally healthy' population"*,
  renames the lowest PAL category from "sedentary" to "inactive", and publishes
  new TEE/EER equations in cm rather than m — its worked adult-woman example is
  `EER = 575.77 – (7.01 × age in years) + (6.60 × height in cm) + (12.14 ×
  weight in kg)`. The report also explains why the 2005 PA-coefficient approach
  was dropped: *"recent evidence indicates that the physical activity level
  coefficient is not constant but varies significantly across age groups"*. This
  does not make the app wrong — citing the 2005 edition and implementing it
  faithfully is a coherent position — but the 2005 attribution should not be
  described as current.
- **The p. 204 equations have no BMI gate, but the p. 185 ones do**, and the
  app's low-kcal warning floors (1500 / 1200) come from a Harvard Health page,
  not from either DRI report. Not a defect, just a different provenance than the
  TDEE numbers around it.
- **The transparency screen repeats the error.** `_maleFormulaText` and
  `_femaleFormulaText` in `kcal_goal_info_screen.dart` build the displayed
  equation as `864 − 9.72 × age + PA × 14.2 × weight + 503 × height`, i.e. the
  buggy grouping written out in full. Any fix has to touch both files, and the
  displayed string should carry the brackets the book prints.

## G. Values the book prints itself, and the fixtures built from them

Added 2026-08-31, after the sections above, by a second pass whose only job was
to find numbers *the source itself publishes* — so that the regression test for
[#987](https://github.com/simonoppowa/OpenNutriTracker/issues/987) could not be
written by the same reasoning that produced the bug.

**They exist.** p. 205 points to Tables 5-29 and 5-30, which tabulate 24-hour
BEE and TEE for 30-year-old men and women across 11 heights (1.45–1.95 m) and 7
BMI columns, five rows each (BEE, sedentary, low active, active, very active).
Men: inputs p. 206 / results p. 207, continued p. 208 / p. 209. Women: inputs
p. 210 / results p. 211, continued p. 212 / p. 213.

**But the tables are mixed, and using them naively would be wrong.** p. 208
states that the normal-weight columns were computed with the p. 185 EER
equations, while "for overweight and obese adults with BMIs from 25 up to 40"
the p. 204 combined equations were used. This was verified numerically rather
than taken on trust: at h = 1.45 m, BMI 18.5, the printed 1,777 / 1,931 / 2,128
/ 2,450 reproduce the p. 185 set exactly and do not match p. 204; at BMI 25 the
printed 2,048 / 2,225 / 2,447 / 2,845 reproduce p. 204 exactly and do not match
the pp. 202–203 overweight-only set. **Only the BMI 25, 30, 35 and 40 columns
belong to the equations this app implements.**

26 cells from those columns are frozen as fixtures in
[`test/unit_test/tdee_iom2005_published_values_test.dart`](../test/unit_test/tdee_iom2005_published_values_test.dart).
The corrected implementation reproduces all 26 within **0.98 kcal**; the
pre-fix grouping misses 16 of them by 87 to 580 kcal. The residual sub-kcal gap
is not error: the book computed its tables from the unrounded Appendix
Table I-11 intercepts (864.1 men, 386.5 women) while p. 204 prints 864 and 387,
which is what the app implements. Hence a ±1.5 kcal tolerance rather than an
exact match.

Because every cell of those tables is age 30, they cannot exercise the age
coefficient at all. Six further fixtures at ages 19, 25, 35 and 54 come from
three agents that derived them from the p. 204 page image while being denied
access to this repository, reconciled by a fourth that recomputed all of them
independently. All three transcriptions of the bracket placement were
identical, and the reconciler additionally re-derived 176 published table cells
from its own reading of pp. 209 and 211 to confirm the equation set.

Two traps found along the way, both encoded as comments in the fixture file:

- **The p. 185 women's PA table is 1.00 / 1.12 / 1.27 / 1.45** — identical to
  p. 204's except at *low active*, where p. 204 says **1.14**. A codebase that
  shared one PA table across both sexes, or copied the women's row from p. 185,
  would fail on exactly one cell. The female low-active fixture is there to be
  that cell.
- **Erratum in Table 5-30.** The women's column headed "22.5" actually contains
  BMI 21.5 weights (45.2 kg at 1.45 m, where the men's table correctly has
  47.3 kg), confirmed by reproducing the printed 1,623. It is a normal-weight
  column, so it does not touch the fixtures — but do not use it.

## Not verified

- **Where 1.25 / 1.5 / 1.75 / 2.2 come from.** No table in IOM 2005 pp. 182–205
  or in FAO/WHO/UNU 2001 chapter 5 publishes these four numbers as
  representative PAL values for the four categories. They are consistent with
  the IOM bands (each falls inside its band) but I could not find them printed
  as a set in either source, and I did not find them in Brooks et al. 2004's
  abstract. They may appear in an IOM appendix table I did not page through, or
  they may be the project's own midpoints. Treat as unattributed until someone
  finds the page.
- ~~**IOM 2005 Appendix Tables I-9, I-10 and I-11** were not read.~~ Resolved
  in [section G](#g-values-the-book-prints-itself-and-the-fixtures-built-from-them).
  Table I-10 (p. 1201, overweight/obese adults) and Table I-11 (p. 1201, normal
  + overweight/obese, the set this app implements) were both read and confirm
  the p. 204 coefficients exactly, with unrounded intercepts 864.1 and 386.5.
  Those appendix tables print coefficients, standard errors, n and R² only — no
  computed kcal results. Table I-9 was not located separately.
- **The full text of Brooks et al. 2004.** Only the PubMed record and abstract
  were retrieved (via NCBI E-utilities; the PubMed HTML page itself returned a
  cookie-consent interstitial to automated fetching). The paper's body may
  contain a PAL table the abstract does not mention. The conclusion that it is
  the wrong citation for the mapping rests on the abstract's stated scope.
- **NASEM 2023 Tables S-1 through S-6.** Only the report's Summary page was
  read; the full adult TEE/EER equation tables were not retrieved, so the 2023
  equations are described only by the one worked example the Summary prints.
- **The project wiki page** referenced by [#987](https://github.com/simonoppowa/OpenNutriTracker/issues/987)
  was not fetched; the code comments were treated as the statement of what the
  app claims to implement.

---

Primary sources used:
[IOM 2005, *Dietary Reference Intakes for Energy, Carbohydrate, Fiber, Fat, Fatty Acids, Cholesterol, Protein, and Amino Acids*, doi:10.17226/10490](https://doi.org/10.17226/10490) —
pp. 182, 184, 185, 202, 203, 204, 205, read as
[NAP page images](https://nap.nationalacademies.org/books/10490/gif/204.gif) ·
[FAO/WHO/UNU 2001, *Human energy requirements*, chapter 5](https://www.fao.org/4/y5686e/y5686e07.htm) ·
[FAO/WHO/UNU 2001, front matter and contents](https://www.fao.org/4/y5686e/y5686e00.htm) ·
[Brooks et al. 2004, PMID 15113740](https://pubmed.ncbi.nlm.nih.gov/15113740/) ·
[NASEM 2023, *Dietary Reference Intakes for Energy*, Summary](https://www.ncbi.nlm.nih.gov/books/NBK591034/)

In-repo files cited:
[`lib/core/utils/calc/tdee_calc.dart`](../lib/core/utils/calc/tdee_calc.dart) ·
[`lib/core/utils/calc/pal_calc.dart`](../lib/core/utils/calc/pal_calc.dart) ·
[`lib/core/utils/calc/bmr_calc.dart`](../lib/core/utils/calc/bmr_calc.dart) ·
[`lib/core/utils/calc/calorie_goal_calc.dart`](../lib/core/utils/calc/calorie_goal_calc.dart) ·
[`lib/core/utils/bounds/ranges_const.dart`](../lib/core/utils/bounds/ranges_const.dart) ·
[`lib/core/utils/bounds/validator.dart`](../lib/core/utils/bounds/validator.dart) ·
[`lib/core/domain/entity/kcal_goal_breakdown_entity.dart`](../lib/core/domain/entity/kcal_goal_breakdown_entity.dart) ·
[`lib/features/settings/presentation/widgets/kcal_goal_info_screen.dart`](../lib/features/settings/presentation/widgets/kcal_goal_info_screen.dart)

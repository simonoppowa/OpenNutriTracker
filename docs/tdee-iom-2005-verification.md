# Does the app's TDEE match the IOM 2005 equation it cites

## Bottom line

1. **The issue is correct.** p. 204 groups the weight *and* height terms inside
   the PA multiplier; the app multiplied PA into the weight term only. Every
   user above sedentary got a TDEE too low by `(PA − 1) × 503 × height[m]`
   (male) or `× 660.7 × height[m]` (female) — **109 to 489 kcal/day** over
   realistic adult inputs, growing with height and activity. Sedentary users
   were unaffected, because PA = 1.00 there. At the top of the range that is a
   second, undeclared weight-loss deficit stacked on the user's chosen one.
2. **The constants and the PA table were both right, and from the same set.**
   No second bug — see [the three-sets table](#which-set-the-constants-come-from),
   where picking the wrong row would have been easy.
3. **The wrong grouping was also shown to the user**, as a string in
   `kcal_goal_info_screen.dart`. Fixing only `tdee_calc.dart` would have left
   the app displaying an equation matching neither the source nor its own
   output.
4. **The Schofield BMR coefficients were exact; that branch's PAL values were
   not.** FAO/WHO/UNU 2001 publishes three PAL bands starting at 1.40, and the
   app fed 1.25 for sedentary. It was dead code — `getTDEEKcalWHO2001` had no
   callers — and is now deleted along with `BMRCalc`.
5. **`pal_calc.dart` cited the wrong paper.** Brooks et al. 2004 publishes no
   category → PAL table.
6. **18-year-olds fell in a gap**: adult equations, no notice. The equations are
   published for "ages 19 years and older".

## What page 204 says

Institute of Medicine, *Dietary Reference Intakes for Energy, Carbohydrate,
Fiber, Fat, Fatty Acids, Cholesterol, Protein, and Amino Acids*, The National
Academies Press, 2005, [doi:10.17226/10490](https://doi.org/10.17226/10490),
p. 204, verbatim:

> **Normal-weight, Overweight, and Obese Men Ages 19 Years and Older**
> **TEE = 864 – (9.72 × age [y]) + PA × (14.2 × weight [kg] + 503 × height [m])**
>
> PA = 1.00 sedentary (PAL ≥ 1.0 < 1.4) · 1.12 low active (≥ 1.4 < 1.6) ·
> 1.27 active (≥ 1.6 < 1.9) · 1.54 very active (≥ 1.9 < 2.5)
>
> **Normal-weight, Overweight, and Obese Women Ages 19 Years and Older**
> **TEE = 387 – (7.31 × age [y]) + PA × (10.9 × weight [kg] + 660.7 × height [m])**
>
> PA = 1.00 sedentary · **1.14** low active · 1.27 active · 1.45 very active

The bracket after `PA ×` closes only after the height term. The same grouping
appears on all six adult and both child equations in the chapter (pp. 182, 185,
202, 203, 204), so it is not a typesetting artefact of one page.

## Which set the constants come from

IOM 2005 publishes **three** adult sets, each with its own intercept,
coefficients **and PA values**. All three were read off the page images.

| Set | Page | Men | Women |
| --- | --- | --- | --- |
| EER, normal-weight 19+ | 185 | `662 – 9.53·age + PA·(15.91·wt + 539.6·ht)` | `354 – 6.91·age + PA·(9.36·wt + 726·ht)` |
| TEE, overweight/obese 19+ | 202–203 | `1086 – 10.1·age + PA·(13.7·wt + 416·ht)` | `448 – 7.95·age + PA·(11.4·wt + 619·ht)` |
| **TEE, combined, BMI ≥ 18.5** | **204** | `864 – 9.72·age + PA·(14.2·wt + 503·ht)` | `387 – 7.31·age + PA·(10.9·wt + 660.7·ht)` |

Their PA tables are *not* interchangeable:

| Set | Men: sed / low / act / very | Women: sed / low / act / very |
| --- | --- | --- |
| p. 185 | 1.00 / **1.11** / **1.25** / **1.48** | 1.00 / **1.12** / 1.27 / 1.45 |
| pp. 202–203 | 1.00 / 1.12 / **1.29** / **1.59** | 1.00 / **1.16** / 1.27 / **1.44** |
| **p. 204** | **1.00 / 1.12 / 1.27 / 1.54** | **1.00 / 1.14 / 1.27 / 1.45** |

`PalCalc` returns the p. 204 row for both sexes, matching the p. 204
intercepts. Its bucket boundaries reproduce the book's half-open bands exactly.

**Choosing p. 204 was defensible.** The book says the normal-weight EERs are
"not intended for overweight or obese individuals or for those who desire to
lose weight" (p. 202), and that the combined equations "are accurate for use in
both normal-weight and overweight and obese adults […] and in mixed groups"
(p. 203). A tracker that does not know the user's BMI category in advance, and
whose users often want to lose weight, is exactly that mixed group. What it
returns is a **TEE**, not an EER.

## Units, population, accuracy

- **Units correct.** Book: `age [y]`, `weight [kg]`, `height [m]`; app passes
  years, kg, `heightCM / 100`.
- **Age.** Headings say "Ages 19 Years and Older". The floor is 13 with a
  disclosure below 19 (was 18 — that gap is what #987 exposed). The book's
  9-through-18 equations (p. 182) differ in coefficients, in PA values (boys
  1.00/1.13/1.26/1.42; girls 1.00/1.16/1.31/1.56) *and* carry a `+ 25 kcal`
  growth term the adult set has no equivalent for.
- **Population.** Fitted on the doubly labeled water database, excluding PAL
  outside 1.0–2.5 (pp. 184, 202). The app never leaves 1.25–2.2.
- ***Open* — uncertainty is never surfaced.** p. 203: *"For the combined data
  sets, the standard deviations of the residuals ranged from 182 to 321."* The
  app presents a single figure to the unit. A ±200–300 kcal one-sigma band is
  wider than the entire −500 kcal weight-loss adjustment. Worth stating on the
  transparency screen.

## The FAO/WHO/UNU 2001 branch (deleted)

`getTDEEKcalWHO2001` = `BMRCalc.getBMRSchofield11985` × PAL, checked against
FAO/WHO/UNU, *Human energy requirements*, chapter 5,
[section 5.2](https://www.fao.org/4/y5686e/y5686e07.htm).

**BMR was exact.** All twelve Schofield 1985 kcal/day coefficients of Table 5.2
and all six age-band boundaries matched digit for digit, including the
`< 18` / `< 30` split. Recorded here because the code is now gone:

| Age (y) | Males | Females |
| --- | --- | --- |
| < 3 | 59.512·kg − 30.4 | 58.317·kg − 31.1 |
| 3–10 | 22.706·kg + 504.3 | 20.315·kg + 485.9 |
| 10–18 | 17.686·kg + 658.2 | 13.384·kg + 692.6 |
| 18–30 | 15.057·kg + 692.2 | 14.818·kg + 486.6 |
| 30–60 | 11.472·kg + 873.1 | 8.126·kg + 845.6 |
| ≥ 60 | 11.711·kg + 587.7 | 9.082·kg + 658.5 |

**PAL did not match.** Table 5.3 gives three bands — sedentary/light 1.40–1.69,
active 1.70–1.99, vigorous 2.00–2.40 — and states the sustainable range starts
at 1.40. The app's `sedentary → 1.25` sat below the published range entirely
(the report mentions 1.21 only for *"totally inactive dependent people in
conditions of crisis"* and says it *"is too low and should not be used"*).
`active → 1.75` and `veryActive → 2.2` were correctly placed.

## Brooks et al. 2004 was the wrong citation

[PMID 15113740](https://pubmed.ncbi.nlm.nih.gov/15113740/) is *"Chronicle of
the Institute of Medicine physical activity recommendation"* — how the panel
arrived at **60 minutes per day**. It defines PAL and reports a threshold; it
publishes no category → PAL table. The four categories and their ranges come
from IOM 2005 itself (pp. 185, 204). The point values 1.25 / 1.5 / 1.75 / 2.2
are the project's own — see [Not verified](#not-verified).

## The 2005 edition has been superseded

NASEM, *Dietary Reference Intakes for Energy* (2023) redefines the population as
*"the general population, including those with overweight, obesity, and chronic
diseases"*, renames "sedentary" to "inactive", and publishes equations in cm
rather than m — its worked adult-woman example is `EER = 575.77 – (7.01 × age)
+ (6.60 × height in cm) + (12.14 × weight in kg)`. It dropped the PA-coefficient
approach because *"recent evidence indicates that the physical activity level
coefficient is not constant but varies significantly across age groups"*.
Citing 2005 and implementing it faithfully is coherent; describing it as current
is not. ***Open*** — a migration is not scheduled.

## Values the book prints itself

The fixtures in
[`test/unit_test/tdee_iom2005_published_values_test.dart`](../test/unit_test/tdee_iom2005_published_values_test.dart)
deliberately compute nothing. p. 205 points to Tables 5-29 and 5-30, which
tabulate 24-hour TEE for 30-year-old men and women across 11 heights and 7 BMI
columns (men: inputs p. 206 / results p. 207, continued p. 208 / p. 209; women:
p. 210 / p. 211, continued p. 212 / p. 213).

**The tables are mixed.** p. 208 states the normal-weight columns were computed
with the p. 185 EER equations, and only BMI 25–40 with the p. 204 set. Verified
numerically: at h = 1.45 m the BMI 18.5 cells reproduce p. 185 exactly and not
p. 204, while the BMI 25 cells reproduce p. 204 exactly and not pp. 202–203.
**Only the BMI ≥ 25 columns are usable here.**

26 such cells are frozen as fixtures. The corrected code reproduces all 26
within **0.98 kcal**; the pre-fix grouping misses 16 of them by 87–580 kcal. The
sub-kcal residue is not error — the book computed its tables from the unrounded
Appendix Table I-11 intercepts (864.1 men, 386.5 women) while p. 204 prints 864
and 387, which is what the app implements. Hence a ±1.5 kcal tolerance.

Every cell of those tables is age 30, so they cannot exercise the age
coefficient. Six further fixtures at ages 19, 25, 35 and 54 were derived from
the p. 204 page image by three agents denied access to this repository and
reconciled by a fourth that recomputed them independently and re-transcribed 176
published cells to confirm the equation set.

Two traps, both encoded in the fixture file:

- **The p. 185 women's PA table is 1.00 / 1.12 / 1.27 / 1.45** — identical to
  p. 204's except at low active, where p. 204 says **1.14**. Sharing one PA
  table across both sexes, or copying the women's row from p. 185, fails on
  exactly one cell. The female low-active fixture exists to be that cell.
- **Erratum in Table 5-30.** The women's column headed "22.5" contains BMI 21.5
  weights (45.2 kg at 1.45 m, where the men's table correctly has 47.3 kg),
  confirmed by reproducing the printed 1,623. A normal-weight column, so it does
  not touch the fixtures — but do not use it.

## Not verified

- **Where 1.25 / 1.5 / 1.75 / 2.2 come from.** No table in IOM 2005 pp. 182–205
  or FAO/WHO/UNU 2001 chapter 5 publishes these four numbers as representative
  PAL values, and they are not in the Brooks abstract. Each falls inside its
  band. Treat as unattributed until someone finds the page.
- **Brooks et al. 2004 full text.** Only the PubMed record and abstract were
  retrieved; the body may contain a table the abstract does not mention. The
  conclusion rests on the abstract's stated scope.
- **NASEM 2023 Tables S-1 to S-6.** Only the Summary page was read, so the 2023
  equations are known from one worked example.
- **Appendix Table I-9** was not located separately. I-10 and I-11 (p. 1201)
  were read and confirm the p. 204 coefficients; those appendix tables print
  coefficients, standard errors, n and R² only — no computed kcal.
- **The project wiki page** cited by #987 was not fetched; the code comments
  were treated as the statement of what the app claims to implement.

---

Primary sources:
[IOM 2005, doi:10.17226/10490](https://doi.org/10.17226/10490) — pp. 182, 184,
185, 202–213, 1201, read as
[NAP page images](https://nap.nationalacademies.org/books/10490/gif/204.gif) ·
[FAO/WHO/UNU 2001, chapter 5](https://www.fao.org/4/y5686e/y5686e07.htm) ·
[Brooks et al. 2004, PMID 15113740](https://pubmed.ncbi.nlm.nih.gov/15113740/) ·
[NASEM 2023, Summary](https://www.ncbi.nlm.nih.gov/books/NBK591034/)

In-repo: [`tdee_calc.dart`](../lib/core/utils/calc/tdee_calc.dart) ·
[`pal_calc.dart`](../lib/core/utils/calc/pal_calc.dart) ·
[`calorie_goal_calc.dart`](../lib/core/utils/calc/calorie_goal_calc.dart) ·
[`ranges_const.dart`](../lib/core/utils/bounds/ranges_const.dart) ·
[`kcal_goal_info_screen.dart`](../lib/features/settings/presentation/widgets/kcal_goal_info_screen.dart) ·
[`tdee_iom2005_published_values_test.dart`](../test/unit_test/tdee_iom2005_published_values_test.dart)

#!/usr/bin/env python3
"""Read and compare OpenNutriTracker JSON export zips for the 2.5.0 run.

Stdlib only, laptop only, run with `python3 -I`. The zips hold the test
profile's diary, so the output prints counts, ids, names and numbers, never
whole records.

  compare_exports.py summary ZIP
      Entries per file, intakes per day (count and kcal), tracked days per
      day (consumed kcal against the sum of that day's intakes), recipes,
      weight log, favourites, goal settings.

  compare_exports.py diff BASE.zip NEW.zip
      For intakes, activities, recipes, the weight log and custom activity
      templates: ids in BASE missing from NEW, ids only in NEW, records whose
      content changed, and ids stored more than once. Tracked days are
      compared as numbers, each next to the sum of its own intakes, because
      the candidate's reconciler (#1319) rewrites a day's consumed totals as
      the sum of the entries listed under it.

The last line of `diff` is `VERDICT: identical`, `VERDICT: superset` (NEW
holds everything BASE holds, unchanged, plus more) or `VERDICT: differs`.
Days are read as the calendar date of an intake's `dateTime`, which is the
app's rule while "Day starts at" is 0:00.
"""
import json
import sys
import zipfile
from collections import Counter, defaultdict

FILES = {
    "intakes": "user_intake.json",
    "activities": "user_activity.json",
    "tracked_days": "user_tracked_day.json",
    "recipes": "user_recipes.json",
    "weight_log": "weight_log.json",
    "templates": "custom_activity_templates.json",
    "favourites": "user_favourites.json",
    "goal_settings": "goal_settings.json",
    "boundary": "tracked_day_boundary.json",
}
EPS = 0.01


def load(path):
    out = {}
    with zipfile.ZipFile(path) as z:
        names = set(z.namelist())
        out["_entries"] = sorted(names)
        for key, name in FILES.items():
            out[key] = json.loads(z.read(name)) if name in names else None
    return out


def day_of(iso):
    return iso[:10]


def kcal_of(intake):
    per100 = (intake["meal"].get("nutriments") or {}).get("energyKcal100") or 0
    return intake["amount"] * per100 / 100.0


def intake_sums(intakes):
    sums = defaultdict(float)
    counts = Counter()
    for i in intakes or []:
        d = day_of(i["dateTime"])
        sums[d] += kcal_of(i)
        counts[d] += 1
    return sums, counts


def key_of(kind, rec):
    if kind == "weight_log":
        return day_of(rec["date"])
    if kind == "templates":
        return (rec.get("name") or rec.get("templateName")
                or json.dumps(rec, sort_keys=True))
    return rec.get("id")


def summary(path):
    d = load(path)
    print(f"zip: {path}")
    print("entries:", ", ".join(d["_entries"]))
    for key in FILES:
        v = d[key]
        if isinstance(v, list):
            print(f"{key}: {len(v)}")
        elif v is None:
            print(f"{key}: absent")
    sums, counts = intake_sums(d["intakes"])
    tracked = {day_of(t["day"]): t for t in d["tracked_days"] or []}
    print("day         intakes  intake_kcal  tracked_kcal  goal_kcal")
    for day in sorted(set(sums) | set(tracked)):
        t = tracked.get(day)
        tk = f"{t['caloriesTracked']:.1f}" if t else "-"
        gk = f"{t['calorieGoal']:.1f}" if t else "-"
        flag = ""
        if t and abs(t["caloriesTracked"] - sums.get(day, 0.0)) > EPS:
            flag = "  <- tracked != sum"
        print(f"{day}  {counts.get(day, 0):7d}  {sums.get(day, 0.0):11.1f}"
              f"  {tk:>12}  {gk:>9}{flag}")
    ids = Counter(i["id"] for i in d["intakes"] or [])
    dups = {k: n for k, n in ids.items() if n > 1}
    blank = sum(1 for i in d["intakes"] or [] if not i["id"].strip())
    print(f"intake ids stored twice or more: {len(dups)}; blank ids: {blank}")
    for r in d["recipes"] or []:
        per100 = (r.get("aggregatedNutrimentsPer100") or {}).get("energyKcal100")
        ing = sum(i.get("convertedAmountG") or 0 for i in r.get("ingredients") or [])
        print(f"recipe: {r['name']!r} totalWeightG={r.get('totalWeightG')}"
              f" ingredientSumG={ing:g} kcalPer100={per100}")
    for w in d["weight_log"] or []:
        print(f"weight: {day_of(w['date'])} {w['weightKg']}")
    for f in d["favourites"] or []:
        m = f.get("meal") or {}
        print(f"favourite: {m.get('name')!r} source={m.get('source')}"
              f" code={m.get('code')} addedAt={f.get('addedAt')}")
    if d["goal_settings"] is not None:
        print("goal_settings:", json.dumps(d["goal_settings"], sort_keys=True))
    if d["boundary"] is not None:
        print("tracked_day_boundary:", json.dumps(d["boundary"], sort_keys=True))
    return 0


def diff(base_path, new_path):
    b, n = load(base_path), load(new_path)
    differs = False
    superset = False
    for kind in ("intakes", "activities", "recipes", "weight_log", "templates"):
        bl, nl = b[kind] or [], n[kind] or []
        bk = Counter(key_of(kind, r) for r in bl)
        nk = Counter(key_of(kind, r) for r in nl)
        bmap = {key_of(kind, r): r for r in bl}
        nmap = {key_of(kind, r): r for r in nl}
        missing = sorted(k for k in bmap if k not in nmap)
        extra = sorted(k for k in nmap if k not in bmap)
        changed = sorted(k for k in bmap if k in nmap
                         and json.dumps(bmap[k], sort_keys=True)
                         != json.dumps(nmap[k], sort_keys=True))
        dups = sorted(k for k, c in nk.items() if c > 1)
        print(f"{kind}: base {len(bl)} new {len(nl)} missing {len(missing)}"
              f" extra {len(extra)} changed {len(changed)}"
              f" stored-twice {len(dups)}")
        for label, keys in (("missing", missing), ("changed", changed),
                            ("stored-twice", dups)):
            for k in keys[:20]:
                rec = bmap.get(k) or nmap.get(k) or {}
                name = (rec.get("meal") or {}).get("name") or rec.get("name")
                print(f"  {label}: {k} {name!r}")
        for k in extra[:20]:
            rec = nmap[k]
            name = (rec.get("meal") or {}).get("name") or rec.get("name")
            print(f"  extra: {k} {name!r}")
        if missing or changed or dups:
            differs = True
        if extra:
            superset = True
        if sum(bk.values()) != len(bk):
            print(f"  note: BASE already stores {sum(bk.values()) - len(bk)}"
                  f" duplicate {kind} ids")
    bs, _ = intake_sums(b["intakes"])
    ns, _ = intake_sums(n["intakes"])
    bt = {day_of(t["day"]): t for t in b["tracked_days"] or []}
    nt = {day_of(t["day"]): t for t in n["tracked_days"] or []}
    print("tracked days: day  base_tracked base_sum | new_tracked new_sum"
          " | base_goal new_goal")
    for day in sorted(set(bt) | set(nt) | set(ns)):
        bt_, nt_ = bt.get(day), nt.get(day)
        cols = [
            f"{bt_['caloriesTracked']:.1f}" if bt_ else "-",
            f"{bs.get(day, 0.0):.1f}",
            f"{nt_['caloriesTracked']:.1f}" if nt_ else "-",
            f"{ns.get(day, 0.0):.1f}",
            f"{bt_['calorieGoal']:.1f}" if bt_ else "-",
            f"{nt_['calorieGoal']:.1f}" if nt_ else "-",
        ]
        notes = []
        if nt_ and abs(nt_["caloriesTracked"] - ns.get(day, 0.0)) > EPS:
            notes.append("NEW tracked != NEW sum")
        if bt_ and not nt_ and bs.get(day, 0.0) > EPS:
            notes.append("row lost although BASE lists intakes")
        if not nt_ and ns.get(day, 0.0) > EPS:
            notes.append("no row although NEW lists intakes")
        if bt_ and nt_ and abs(bt_["calorieGoal"] - nt_["calorieGoal"]) > EPS:
            notes.append("goal moved")
        print(f"  {day}  {cols[0]:>8} {cols[1]:>8} | {cols[2]:>8} {cols[3]:>8}"
              f" | {cols[4]:>8} {cols[5]:>8}  {'; '.join(notes)}")
        if any(x.startswith("NEW tracked") or x.startswith("row lost")
               for x in notes):
            differs = True
    for key in ("favourites", "goal_settings", "boundary"):
        print(f"{key}: base {'absent' if b[key] is None else 'present'},"
              f" new {'absent' if n[key] is None else 'present'}")
    verdict = "differs" if differs else ("superset" if superset else "identical")
    print(f"VERDICT: {verdict}")
    return 0


def main(argv):
    if len(argv) == 3 and argv[1] == "summary":
        return summary(argv[2])
    if len(argv) == 4 and argv[1] == "diff":
        return diff(argv[2], argv[3])
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))

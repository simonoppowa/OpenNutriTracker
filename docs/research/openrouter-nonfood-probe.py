"""Wayfinder #669 — does the empty-answer rule survive other providers?

The photo path depends on a model saying honestly that it saw no food.
The direct-Anthropic baseline over this same 15-image non-food slice was
14/15 empty, with the one exception (chair_4) being an office desk that
genuinely has a tomato, bread rolls and drinks on it — i.e. effectively 15/15
correct.

Four configurations, chosen so the variables separate:
  A  claude-haiku PINNED to anthropic   -> like-for-like with the baseline
  B  claude-haiku UNPINNED              -> isolates the serving provider
  C  a Google model                     -> different vendor
  D  an OpenAI model                    -> different vendor

Uses the real photo system prompt and the real log_meal_items schema, and
applies the shipping counts-only filter, so this measures the pipeline the
app would actually run.
"""
import base64, json, pathlib, sys, time, urllib.error, urllib.request

S = pathlib.Path(sys.argv[1])
KEY = (S / 'openrouter_key').read_text().strip()
URL = 'https://openrouter.ai/api/v1/chat/completions'

SYSTEM = """You identify the foods visible in a photograph of a meal so they can be
looked up in a food database. You do not estimate nutrition, and you do not
estimate weight or volume.

Rules:
- One entry per distinct food you can see. A composed dish a person would
  log as one thing ("lasagne", "chicken curry") is one entry, not a list of
  its ingredients.
- "query" is the food name alone, with no amount in it, in the user's app
  language. Keep a brand only if it is legible in the photo.
- Only include "quantity" when you can count discrete items: 2 eggs, 3
  sausages, 1 banana. A count has no unit, so never include "unit".
- For anything you cannot count - rice, salad, sauce, soup, a drink - omit
  "quantity". Do not guess grams or millilitres from a photograph. The app
  asks the user for the amount, and a guess they cannot check is worse than
  no answer.
- Only list food you can actually identify. If you cannot tell what a dish
  is, describe it plainly ("meat stew") rather than naming a specific
  recipe you are guessing at.
- If the photo contains no food, return an empty list.
The user's app language is "en"."""

PARAMS = {
    'type': 'object',
    'properties': {'items': {'type': 'array', 'items': {
        'type': 'object',
        'properties': {
            'query': {'type': 'string'},
            'quantity': {'type': 'number'},
            'unit': {'type': 'string',
                     'enum': ['g', 'kg', 'lb', 'ml', 'l', 'g/ml', 'oz', 'fl.oz', 'serving']},
        },
        'required': ['query'], 'additionalProperties': False}}},
    'required': ['items'], 'additionalProperties': False,
}
TOOL = {'type': 'function', 'function': {
    'name': 'log_meal_items', 'description': 'Record the food items found.',
    'parameters': PARAMS}}

CONFIGS = [
    ('A claude pinned',   'anthropic/claude-haiku-4.5', ['anthropic']),
    ('B claude unpinned', 'anthropic/claude-haiku-4.5', None),
    ('C gemini flash',    'google/gemini-3.7-flash',    None),
    ('D gpt nano',        'openai/gpt-5.4-nano',        None),
]


def call(model, only, img_b64, timeout=120):
    prov = {'require_parameters': True, 'data_collection': 'deny'}
    if only:
        prov['only'] = only
        prov['allow_fallbacks'] = False
    body = {
        'model': model, 'max_tokens': 1024,
        'messages': [
            {'role': 'system', 'content': SYSTEM},
            {'role': 'user', 'content': [
                {'type': 'text', 'text': 'List the foods in this photo.'},
                {'type': 'image_url', 'image_url': {'url': 'data:image/jpeg;base64,' + img_b64}},
            ]},
        ],
        'tools': [TOOL],
        'tool_choice': {'type': 'function', 'function': {'name': 'log_meal_items'}},
        'provider': prov,
    }
    req = urllib.request.Request(URL, data=json.dumps(body).encode(), headers={
        'Authorization': f'Bearer {KEY}', 'Content-Type': 'application/json',
        'X-OpenRouter-Metadata': 'enabled', 'User-Agent': 'ONT-wayfinder-probe/1.0'})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status, json.load(r)
    except urllib.error.HTTPError as e:
        try:
            return e.code, json.load(e)
        except Exception:
            return e.code, {}
    except Exception as e:
        return None, {'transport_error': str(e)}


def items_of(status, body):
    """What the shipping pipeline would end up with, counts-only filter applied."""
    if status != 200:
        return None, f'HTTP {status}: ' + str((body.get("error") or {}).get("message", ""))[:80]
    ch = (body.get('choices') or [{}])[0]
    if ch.get('finish_reason') == 'error':
        return None, '200 finish_reason=error'
    calls = (ch.get('message') or {}).get('tool_calls') or []
    if not calls:
        return None, 'PROSE (no tool call)'
    try:
        raw = json.loads(calls[0]['function']['arguments']).get('items') or []
    except Exception as e:
        return None, f'unparseable: {e}'
    out = []
    for it in raw:                       # shipping counts-only rule
        q = it.get('quantity')
        if it.get('unit') is not None or (q is not None and float(q) != int(float(q))):
            out.append({'query': it.get('query')})
        else:
            out.append(it)
    return out, body.get('provider')


imgs = sorted(p for p in (S / 'corpus_ov').glob('*.jpg')
              if p.name.split('_')[0] in ('laptop', 'bicycle', 'chair'))
print(f'non-food images: {len(imgs)}\n')
enc = {p.name: base64.b64encode(p.read_bytes()).decode() for p in imgs}

results = []
for label, model, only in CONFIGS:
    empty = nonempty = failed = 0
    detail = []
    for p in imgs:
        st, body = call(model, only, enc[p.name])
        items, note = items_of(st, body)
        if items is None:
            failed += 1
            detail.append((p.name, 'FAIL', note))
        elif not items:
            empty += 1
        else:
            nonempty += 1
            detail.append((p.name, 'FOOD', [i.get('query') for i in items]))
        results.append({'config': label, 'model': model, 'pinned': only,
                        'image': p.name,
                        'outcome': 'FAIL' if items is None else ('EMPTY' if not items else 'FOOD'),
                        'items': items, 'note': str(note)[:120]})
        time.sleep(0.7)
    print(f'{label:20s} empty {empty:2d}/{len(imgs)}   food {nonempty:2d}   failed {failed:2d}')
    for d in detail:
        print(f'     {d[0]:16s} {d[1]:5s} {d[2]}')
    print()

(S / 'nonfood_results.json').write_text(json.dumps(results, indent=2))
print('written:', S / 'nonfood_results.json')

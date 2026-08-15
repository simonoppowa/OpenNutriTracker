# Probe: is forced tool choice actually honoured on OpenRouter?

Wayfinder ticket #666. Seven live calls with the real `log_meal_items` schema
translated to the OpenAI-compatible function shape. Throwaway probe, not shipping code.
Image case used a 1x1 white WebP so no real content was sent.

```json
[
  {
    "case": "capable + force + require",
    "model": "anthropic/claude-haiku-4.5",
    "outcome": "TOOL_CALL",
    "status": 200,
    "finish_reason": "tool_calls",
    "provider": "Amazon Bedrock",
    "name": "log_meal_items",
    "valid_shape": true,
    "extra_keys": [],
    "items": [
      {
        "query": "eggs",
        "quantity": 2
      },
      {
        "query": "toast",
        "quantity": 100,
        "unit": "g"
      },
      {
        "query": "black coffee"
      }
    ]
  },
  {
    "case": "capable + force, NO require",
    "model": "anthropic/claude-haiku-4.5",
    "outcome": "TOOL_CALL",
    "status": 200,
    "finish_reason": "tool_calls",
    "provider": "Amazon Bedrock",
    "name": "log_meal_items",
    "valid_shape": true,
    "extra_keys": [],
    "items": [
      {
        "query": "eggs",
        "quantity": 2
      },
      {
        "query": "toast",
        "quantity": 100,
        "unit": "g"
      },
      {
        "query": "black coffee"
      }
    ]
  },
  {
    "case": "capable + image + force",
    "model": "anthropic/claude-haiku-4.5",
    "outcome": "TOOL_CALL",
    "status": 200,
    "finish_reason": "tool_calls",
    "provider": "Amazon Bedrock",
    "name": "log_meal_items",
    "valid_shape": true,
    "extra_keys": [],
    "items": [
      {
        "query": "milk"
      },
      {
        "query": "cereal"
      }
    ]
  },
  {
    "case": "NO tool_choice + force + require",
    "model": "amazon/nova-lite-v1",
    "outcome": "HTTP_ERROR",
    "status": 404,
    "code": 404,
    "type": null,
    "message": "No endpoints found that can handle the requested parameters. To learn more about provider routing, visit: https://openrouter.ai/docs/guides/"
  },
  {
    "case": "NO tool_choice + force, NO require",
    "model": "amazon/nova-lite-v1",
    "outcome": "TOOL_CALL",
    "status": 200,
    "finish_reason": "tool_calls",
    "provider": "Amazon Bedrock",
    "name": "log_meal_items",
    "valid_shape": true,
    "extra_keys": [],
    "items": [
      {
        "query": "eggs",
        "quantity": 2
      },
      {
        "query": "toast",
        "unit": "g",
        "quantity": 100
      },
      {
        "query": "black coffee"
      }
    ]
  },
  {
    "case": "text-only model SENT AN IMAGE",
    "model": "deepseek/deepseek-v4-pro-0813",
    "outcome": "HTTP_ERROR",
    "status": 404,
    "code": 404,
    "type": null,
    "message": "No endpoints found that support image input"
  },
  {
    "case": "text-only model, text only",
    "model": "deepseek/deepseek-v4-pro-0813",
    "outcome": "TOOL_CALL",
    "status": 200,
    "finish_reason": "tool_calls",
    "provider": "BaseTen",
    "name": "log_meal_items",
    "valid_shape": true,
    "extra_keys": [],
    "items": [
      {
        "query": "eggs",
        "quantity": 2,
        "unit": "serving"
      },
      {
        "query": "toast",
        "quantity": 100,
        "unit": "g"
      },
      {
        "query": "black coffee"
      }
    ]
  }
]```

## Probe script

```python
"""Throwaway probe for wayfinder ticket #666.

Does OpenRouter actually honour a forced tool call, and does
`provider.require_parameters: true` convert silent degradation into a
refusal? The no-macros guarantee rests on the answer.

Sends the REAL log_meal_items schema from AnthropicMealItemsApi, translated
to the OpenAI-compatible function shape. Key is read from a file; never
printed, never on a command line.
"""
import base64, json, pathlib, sys, time, urllib.error, urllib.request

S = pathlib.Path(sys.argv[1])
KEY = (S / 'openrouter_key').read_text().strip()
URL = 'https://openrouter.ai/api/v1/chat/completions'

# The shipping schema, verbatim in content — note the absence of any
# nutrition field. That absence is the guarantee under test.
PARAMS = {
    'type': 'object',
    'properties': {
        'items': {
            'type': 'array',
            'items': {
                'type': 'object',
                'properties': {
                    'query': {'type': 'string', 'description': "Food name only, no amount, in the user's language."},
                    'quantity': {'type': 'number', 'description': 'Only if the user stated an amount.'},
                    'unit': {'type': 'string',
                             'enum': ['g', 'kg', 'lb', 'ml', 'l', 'g/ml', 'oz', 'fl.oz', 'serving'],
                             'description': 'Only if the user stated a unit, and only one of these.'},
                },
                'required': ['query'],
                'additionalProperties': False,
            },
        }
    },
    'required': ['items'],
    'additionalProperties': False,
}
TOOL = {'type': 'function',
        'function': {'name': 'log_meal_items',
                     'description': 'Record the food items found.',
                     'parameters': PARAMS}}
SYSTEM = ("You extract food items from a meal description so they can be looked up in a "
          "food database. You do not estimate nutrition, and you never invent an amount.")
TEXT = '2 eggs, 100g toast, black coffee'

# 1x1 webp, so an image probe carries no content of anyone's
TINY_WEBP = base64.b64decode(
    'UklGRhoAAABXRUJQVlA4TA0AAAAvAAAAEAcQERGIiP4HAA==')


def call(model, *, force=True, require=True, image=False, timeout=90):
    content = TEXT
    if image:
        content = [
            {'type': 'text', 'text': 'List the foods in this photo.'},
            {'type': 'image_url', 'image_url': {
                'url': 'data:image/webp;base64,' + base64.b64encode(TINY_WEBP).decode()}},
        ]
    body = {
        'model': model,
        'max_tokens': 512,
        'messages': [{'role': 'system', 'content': SYSTEM},
                     {'role': 'user', 'content': content}],
        'tools': [TOOL],
    }
    if force:
        body['tool_choice'] = {'type': 'function', 'function': {'name': 'log_meal_items'}}
    prov = {}
    if require:
        prov['require_parameters'] = True
    prov['data_collection'] = 'deny'
    body['provider'] = prov

    req = urllib.request.Request(
        URL, data=json.dumps(body).encode(),
        headers={'Authorization': f'Bearer {KEY}',
                 'Content-Type': 'application/json',
                 'X-OpenRouter-Metadata': 'enabled',
                 'User-Agent': 'ONT-wayfinder-probe/1.0'})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status, json.load(r)
    except urllib.error.HTTPError as e:
        try:
            return e.code, json.load(e)
        except Exception:
            return e.code, {'raw': e.read()[:400].decode('utf8', 'replace')}
    except Exception as e:
        return None, {'transport_error': str(e)}


def classify(status, body):
    """What the app would actually see."""
    if status != 200:
        err = (body.get('error') or {})
        return {'outcome': 'HTTP_ERROR', 'status': status,
                'code': err.get('code'),
                'type': (err.get('metadata') or {}).get('error_type'),
                'message': str(err.get('message'))[:140]}
    ch = (body.get('choices') or [{}])[0]
    fin = ch.get('finish_reason')
    msg = ch.get('message') or {}
    calls = msg.get('tool_calls') or []
    out = {'outcome': None, 'status': 200, 'finish_reason': fin,
           'provider': body.get('provider')}
    if fin == 'error':
        out['outcome'] = '200_BUT_ERROR'
        out['message'] = str(body.get('error') or msg.get('content'))[:140]
        return out
    if calls:
        try:
            args = json.loads(calls[0]['function']['arguments'])
            items = args.get('items')
            bad = [k for it in (items or []) for k in it
                   if k not in ('query', 'quantity', 'unit')]
            out['outcome'] = 'TOOL_CALL'
            out['name'] = calls[0]['function'].get('name')
            out['valid_shape'] = isinstance(items, list) and not bad
            out['extra_keys'] = sorted(set(bad))
            out['items'] = items
        except Exception as e:
            out['outcome'] = 'TOOL_CALL_UNPARSEABLE'
            out['error'] = str(e)[:120]
        return out
    out['outcome'] = 'PROSE'           # the failure that matters
    out['content'] = str(msg.get('content'))[:200]
    return out


CASES = [
    ('capable + force + require',      dict(model='anthropic/claude-haiku-4.5')),
    ('capable + force, NO require',    dict(model='anthropic/claude-haiku-4.5', require=False)),
    ('capable + image + force',        dict(model='anthropic/claude-haiku-4.5', image=True)),
    ('NO tool_choice + force + require', dict(model='amazon/nova-lite-v1')),
    ('NO tool_choice + force, NO require', dict(model='amazon/nova-lite-v1', require=False)),
    ('text-only model SENT AN IMAGE',  dict(model='deepseek/deepseek-v4-pro-0813', image=True)),
    ('text-only model, text only',     dict(model='deepseek/deepseek-v4-pro-0813')),
]

results = []
for label, kw in CASES:
    status, body = call(**kw)
    c = classify(status, body)
    results.append({'case': label, 'model': kw['model'], **c})
    print(f"{label:38s} -> {c['outcome']:22s} {c.get('provider') or ''} "
          f"{'' if c.get('valid_shape') is None else 'schema_ok=' + str(c['valid_shape'])}")
    time.sleep(1.5)

(S / 'probe_results.json').write_text(json.dumps(results, indent=2))
print('\nwritten:', S / 'probe_results.json')
```

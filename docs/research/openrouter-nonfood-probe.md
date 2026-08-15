# Probe: does the empty-answer rule hold on other providers?

Wayfinder ticket #669. 15 non-food photos x 4 configurations, real prompt,
real schema, shipping counts-only filter. 60 calls, zero failures.

Corrected ground truth: 13 truly empty, 2 contain food —
`chair_4` (desk with tomato/bread/drinks) and `chair_2` (bottled water).

```
non-food images: 15

A claude pinned      empty 13/15   food  2   failed  0
     chair_2.jpg      FOOD  ['water']
     chair_4.jpg      FOOD  ['apple', 'crackers']

B claude unpinned    empty 14/15   food  1   failed  0
     chair_4.jpg      FOOD  ['pretzels', 'apple']

C gemini flash       empty 13/15   food  2   failed  0
     chair_2.jpg      FOOD  ['Dasani bottled water']
     chair_4.jpg      FOOD  ['tomato', 'doughnut holes', 'energy drink', 'drink']

D gpt nano           empty 15/15   food  0   failed  0

written: /tmp/claude-1000/-home-simon-Documents-OpenNutriTracker/0432813e-4e04-4656-9928-de37c0feaf90/scratchpad/nonfood_results.json
```

```json
[
  {
    "config": "A claude pinned",
    "model": "anthropic/claude-haiku-4.5",
    "pinned": [
      "anthropic"
    ],
    "image": "bicycle_0.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Anthropic"
  },
  {
    "config": "A claude pinned",
    "model": "anthropic/claude-haiku-4.5",
    "pinned": [
      "anthropic"
    ],
    "image": "bicycle_1.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Anthropic"
  },
  {
    "config": "A claude pinned",
    "model": "anthropic/claude-haiku-4.5",
    "pinned": [
      "anthropic"
    ],
    "image": "bicycle_2.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Anthropic"
  },
  {
    "config": "A claude pinned",
    "model": "anthropic/claude-haiku-4.5",
    "pinned": [
      "anthropic"
    ],
    "image": "bicycle_3.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Anthropic"
  },
  {
    "config": "A claude pinned",
    "model": "anthropic/claude-haiku-4.5",
    "pinned": [
      "anthropic"
    ],
    "image": "bicycle_4.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Anthropic"
  },
  {
    "config": "A claude pinned",
    "model": "anthropic/claude-haiku-4.5",
    "pinned": [
      "anthropic"
    ],
    "image": "chair_0.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Anthropic"
  },
  {
    "config": "A claude pinned",
    "model": "anthropic/claude-haiku-4.5",
    "pinned": [
      "anthropic"
    ],
    "image": "chair_1.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Anthropic"
  },
  {
    "config": "A claude pinned",
    "model": "anthropic/claude-haiku-4.5",
    "pinned": [
      "anthropic"
    ],
    "image": "chair_2.jpg",
    "outcome": "FOOD",
    "items": [
      {
        "query": "water"
      }
    ],
    "note": "Anthropic"
  },
  {
    "config": "A claude pinned",
    "model": "anthropic/claude-haiku-4.5",
    "pinned": [
      "anthropic"
    ],
    "image": "chair_3.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Anthropic"
  },
  {
    "config": "A claude pinned",
    "model": "anthropic/claude-haiku-4.5",
    "pinned": [
      "anthropic"
    ],
    "image": "chair_4.jpg",
    "outcome": "FOOD",
    "items": [
      {
        "query": "apple"
      },
      {
        "query": "crackers"
      }
    ],
    "note": "Anthropic"
  },
  {
    "config": "A claude pinned",
    "model": "anthropic/claude-haiku-4.5",
    "pinned": [
      "anthropic"
    ],
    "image": "laptop_0.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Anthropic"
  },
  {
    "config": "A claude pinned",
    "model": "anthropic/claude-haiku-4.5",
    "pinned": [
      "anthropic"
    ],
    "image": "laptop_1.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Anthropic"
  },
  {
    "config": "A claude pinned",
    "model": "anthropic/claude-haiku-4.5",
    "pinned": [
      "anthropic"
    ],
    "image": "laptop_2.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Anthropic"
  },
  {
    "config": "A claude pinned",
    "model": "anthropic/claude-haiku-4.5",
    "pinned": [
      "anthropic"
    ],
    "image": "laptop_3.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Anthropic"
  },
  {
    "config": "A claude pinned",
    "model": "anthropic/claude-haiku-4.5",
    "pinned": [
      "anthropic"
    ],
    "image": "laptop_4.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Anthropic"
  },
  {
    "config": "B claude unpinned",
    "model": "anthropic/claude-haiku-4.5",
    "pinned": null,
    "image": "bicycle_0.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Amazon Bedrock"
  },
  {
    "config": "B claude unpinned",
    "model": "anthropic/claude-haiku-4.5",
    "pinned": null,
    "image": "bicycle_1.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Amazon Bedrock"
  },
  {
    "config": "B claude unpinned",
    "model": "anthropic/claude-haiku-4.5",
    "pinned": null,
    "image": "bicycle_2.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Amazon Bedrock"
  },
  {
    "config": "B claude unpinned",
    "model": "anthropic/claude-haiku-4.5",
    "pinned": null,
    "image": "bicycle_3.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Amazon Bedrock"
  },
  {
    "config": "B claude unpinned",
    "model": "anthropic/claude-haiku-4.5",
    "pinned": null,
    "image": "bicycle_4.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Amazon Bedrock"
  },
  {
    "config": "B claude unpinned",
    "model": "anthropic/claude-haiku-4.5",
    "pinned": null,
    "image": "chair_0.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Amazon Bedrock"
  },
  {
    "config": "B claude unpinned",
    "model": "anthropic/claude-haiku-4.5",
    "pinned": null,
    "image": "chair_1.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Amazon Bedrock"
  },
  {
    "config": "B claude unpinned",
    "model": "anthropic/claude-haiku-4.5",
    "pinned": null,
    "image": "chair_2.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Amazon Bedrock"
  },
  {
    "config": "B claude unpinned",
    "model": "anthropic/claude-haiku-4.5",
    "pinned": null,
    "image": "chair_3.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Amazon Bedrock"
  },
  {
    "config": "B claude unpinned",
    "model": "anthropic/claude-haiku-4.5",
    "pinned": null,
    "image": "chair_4.jpg",
    "outcome": "FOOD",
    "items": [
      {
        "query": "pretzels"
      },
      {
        "query": "apple"
      }
    ],
    "note": "Amazon Bedrock"
  },
  {
    "config": "B claude unpinned",
    "model": "anthropic/claude-haiku-4.5",
    "pinned": null,
    "image": "laptop_0.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Amazon Bedrock"
  },
  {
    "config": "B claude unpinned",
    "model": "anthropic/claude-haiku-4.5",
    "pinned": null,
    "image": "laptop_1.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Amazon Bedrock"
  },
  {
    "config": "B claude unpinned",
    "model": "anthropic/claude-haiku-4.5",
    "pinned": null,
    "image": "laptop_2.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Amazon Bedrock"
  },
  {
    "config": "B claude unpinned",
    "model": "anthropic/claude-haiku-4.5",
    "pinned": null,
    "image": "laptop_3.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Amazon Bedrock"
  },
  {
    "config": "B claude unpinned",
    "model": "anthropic/claude-haiku-4.5",
    "pinned": null,
    "image": "laptop_4.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Amazon Bedrock"
  },
  {
    "config": "C gemini flash",
    "model": "google/gemini-3.7-flash",
    "pinned": null,
    "image": "bicycle_0.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Google"
  },
  {
    "config": "C gemini flash",
    "model": "google/gemini-3.7-flash",
    "pinned": null,
    "image": "bicycle_1.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Google"
  },
  {
    "config": "C gemini flash",
    "model": "google/gemini-3.7-flash",
    "pinned": null,
    "image": "bicycle_2.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Google"
  },
  {
    "config": "C gemini flash",
    "model": "google/gemini-3.7-flash",
    "pinned": null,
    "image": "bicycle_3.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Google"
  },
  {
    "config": "C gemini flash",
    "model": "google/gemini-3.7-flash",
    "pinned": null,
    "image": "bicycle_4.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Google"
  },
  {
    "config": "C gemini flash",
    "model": "google/gemini-3.7-flash",
    "pinned": null,
    "image": "chair_0.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Google"
  },
  {
    "config": "C gemini flash",
    "model": "google/gemini-3.7-flash",
    "pinned": null,
    "image": "chair_1.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Google"
  },
  {
    "config": "C gemini flash",
    "model": "google/gemini-3.7-flash",
    "pinned": null,
    "image": "chair_2.jpg",
    "outcome": "FOOD",
    "items": [
      {
        "query": "Dasani bottled water"
      }
    ],
    "note": "Google"
  },
  {
    "config": "C gemini flash",
    "model": "google/gemini-3.7-flash",
    "pinned": null,
    "image": "chair_3.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Google"
  },
  {
    "config": "C gemini flash",
    "model": "google/gemini-3.7-flash",
    "pinned": null,
    "image": "chair_4.jpg",
    "outcome": "FOOD",
    "items": [
      {
        "query": "tomato",
        "quantity": 1
      },
      {
        "query": "doughnut holes",
        "quantity": 5
      },
      {
        "query": "energy drink"
      },
      {
        "query": "drink"
      }
    ],
    "note": "Google"
  },
  {
    "config": "C gemini flash",
    "model": "google/gemini-3.7-flash",
    "pinned": null,
    "image": "laptop_0.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Google"
  },
  {
    "config": "C gemini flash",
    "model": "google/gemini-3.7-flash",
    "pinned": null,
    "image": "laptop_1.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Google"
  },
  {
    "config": "C gemini flash",
    "model": "google/gemini-3.7-flash",
    "pinned": null,
    "image": "laptop_2.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Google"
  },
  {
    "config": "C gemini flash",
    "model": "google/gemini-3.7-flash",
    "pinned": null,
    "image": "laptop_3.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Google"
  },
  {
    "config": "C gemini flash",
    "model": "google/gemini-3.7-flash",
    "pinned": null,
    "image": "laptop_4.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "Google"
  },
  {
    "config": "D gpt nano",
    "model": "openai/gpt-5.4-nano",
    "pinned": null,
    "image": "bicycle_0.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "OpenAI"
  },
  {
    "config": "D gpt nano",
    "model": "openai/gpt-5.4-nano",
    "pinned": null,
    "image": "bicycle_1.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "OpenAI"
  },
  {
    "config": "D gpt nano",
    "model": "openai/gpt-5.4-nano",
    "pinned": null,
    "image": "bicycle_2.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "OpenAI"
  },
  {
    "config": "D gpt nano",
    "model": "openai/gpt-5.4-nano",
    "pinned": null,
    "image": "bicycle_3.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "OpenAI"
  },
  {
    "config": "D gpt nano",
    "model": "openai/gpt-5.4-nano",
    "pinned": null,
    "image": "bicycle_4.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "OpenAI"
  },
  {
    "config": "D gpt nano",
    "model": "openai/gpt-5.4-nano",
    "pinned": null,
    "image": "chair_0.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "OpenAI"
  },
  {
    "config": "D gpt nano",
    "model": "openai/gpt-5.4-nano",
    "pinned": null,
    "image": "chair_1.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "OpenAI"
  },
  {
    "config": "D gpt nano",
    "model": "openai/gpt-5.4-nano",
    "pinned": null,
    "image": "chair_2.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "OpenAI"
  },
  {
    "config": "D gpt nano",
    "model": "openai/gpt-5.4-nano",
    "pinned": null,
    "image": "chair_3.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "OpenAI"
  },
  {
    "config": "D gpt nano",
    "model": "openai/gpt-5.4-nano",
    "pinned": null,
    "image": "chair_4.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "OpenAI"
  },
  {
    "config": "D gpt nano",
    "model": "openai/gpt-5.4-nano",
    "pinned": null,
    "image": "laptop_0.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "OpenAI"
  },
  {
    "config": "D gpt nano",
    "model": "openai/gpt-5.4-nano",
    "pinned": null,
    "image": "laptop_1.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "OpenAI"
  },
  {
    "config": "D gpt nano",
    "model": "openai/gpt-5.4-nano",
    "pinned": null,
    "image": "laptop_2.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "OpenAI"
  },
  {
    "config": "D gpt nano",
    "model": "openai/gpt-5.4-nano",
    "pinned": null,
    "image": "laptop_3.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "OpenAI"
  },
  {
    "config": "D gpt nano",
    "model": "openai/gpt-5.4-nano",
    "pinned": null,
    "image": "laptop_4.jpg",
    "outcome": "EMPTY",
    "items": [],
    "note": "OpenAI"
  }
]```
